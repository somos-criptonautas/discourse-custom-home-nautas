import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import { fn } from "@ember/helper";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { block } from "discourse/blocks";
import BasicTopicList from "discourse/components/basic-topic-list";
import DropdownMenu from "discourse/components/dropdown-menu";
import DMenu from "discourse/float-kit/components/d-menu";
import { bind } from "discourse/lib/decorators";
import getURL from "discourse/lib/get-url";
import KeyValueStore from "discourse/lib/key-value-store";
import { eq } from "discourse/truth-helpers";
import DAsyncContent from "discourse/ui-kit/d-async-content";
import DButton from "discourse/ui-kit/d-button";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";

// localStorage, so a member's pick survives the session and the next visit.
// Prefix kept from the theme's old name: renaming it would discard every
// member's saved picks for nothing.
const preferences = new KeyValueStore("branded_custom_homepage_");
const VIEW_KEY = "topics_view";

// Only Top takes a period: Latest orders by last activity and Hot bakes its own
// decay into the score. The labels say "now" against "best of X" because "hot"
// and "top" do not read as different things to anyone who has not read the
// Discourse docs.

// Pages the sentinel will append before it gives up and leaves the "view all"
// link to do the rest. The homepage is a doorway, not an endless feed.
const MAX_PAGES = 3;
const VIEWS = [
  { key: "latest", labelKey: "homepage.topics.view.latest", filter: "latest" },
  { key: "hot", labelKey: "homepage.topics.view.hot", filter: "hot" },
  {
    key: "weekly",
    labelKey: "homepage.topics.view.weekly",
    filter: "top",
    period: "weekly",
  },
  {
    key: "monthly",
    labelKey: "homepage.topics.view.monthly",
    filter: "top",
    period: "monthly",
  },
  {
    key: "all",
    labelKey: "homepage.topics.view.all",
    filter: "top",
    period: "all",
  },
];

@block("theme:custom-home:featured-list", {
  description: "Topic list switchable between trending and top of a period",
  args: {
    linkText: { type: "string" },
    count: { type: "number", default: 10 },
    defaultView: { type: "string", default: "latest" },
    emptyMessage: { type: "string" },
    listContext: { type: "string", default: "discovery" },
  },
})
export default class BlockFeaturedList extends Component {
  @service store;

  @tracked selectedKey = preferences.get(VIEW_KEY);
  @tracked topics = [];

  #list = null;
  #observer = null;
  #loading = false;
  #pages = 1;
  #exhausted = false;

  get selected() {
    return (
      VIEWS.find((v) => v.key === this.selectedKey) ??
      VIEWS.find((v) => v.key === (this.args.defaultView || "hot")) ??
      VIEWS[0]
    );
  }

  get linkUrl() {
    const { filter, period } = this.selected;
    return getURL(period ? `/${filter}?period=${period}` : `/${filter}`);
  }

  @action
  select(key, close) {
    this.selectedKey = key;
    preferences.set({ key: VIEW_KEY, value: key });
    close?.();
  }

  @bind
  async fetchTopics(viewKey) {
    const view = VIEWS.find((v) => v.key === viewKey) ?? VIEWS[0];
    const count = this.args.count || 10;
    let list = await this.#load(view.filter, view.period, count);

    // Hot is empty until Discourse's scheduled job has scored topics, and a
    // quiet period can leave Top empty too. An empty homepage is worse than a
    // less precise one, so fall back to latest rather than render nothing.
    if (!list?.topics?.length && view.filter !== "latest") {
      list = await this.#load("latest", null, count);
    }

    // Every assignment happens after an await, so none of it lands mid-render.
    this.#list = list;
    this.#pages = 1;
    this.#exhausted = false;
    this.topics = list?.topics?.slice(0, count) ?? [];

    return this.topics.length ? this.topics : null;
  }

  // per_page keeps the server from serializing a full page of 30 topics that
  // we would only throw away client-side.
  async #load(filter, period, count) {
    const params = { per_page: count };
    if (period) {
      params.period = period;
    }

    return this.store.findFiltered("topicList", { filter, params });
  }

  get canLoadMore() {
    return !this.#exhausted && this.#pages < MAX_PAGES;
  }

  // The sentinel is an empty div after the list: IntersectionObserver leaves it
  // inert until it is actually scrolled into view, so an unscrolled homepage
  // costs nothing beyond the element itself.
  @action
  watchSentinel(element) {
    this.#observer?.disconnect();
    this.#observer = new IntersectionObserver(
      (entries) => {
        if (entries.some((entry) => entry.isIntersecting)) {
          this.loadMore();
        }
      },
      { rootMargin: "200px" }
    );
    this.#observer.observe(element);
  }

  willDestroy() {
    super.willDestroy(...arguments);
    this.#observer?.disconnect();
  }

  @action
  async loadMore() {
    // The guard is what keeps a fast scroll from firing overlapping requests.
    if (this.#loading || !this.canLoadMore) {
      return;
    }

    if (typeof this.#list?.loadMore !== "function") {
      this.#exhausted = true;
      return;
    }

    this.#loading = true;

    try {
      const before = this.#list.topics?.length ?? 0;
      await this.#list.loadMore();
      const after = this.#list.topics?.length ?? 0;

      // No growth means the server has nothing left; asking again would loop.
      if (after > before) {
        this.topics = [...this.#list.topics];
        this.#pages++;
      } else {
        this.#exhausted = true;
      }
    } catch {
      // A failed page should stop the sentinel, not break the list already on
      // screen. The "view all" link remains the way out.
      this.#exhausted = true;
    } finally {
      this.#loading = false;
    }
  }

  <template>
    <div class="block-featured-list__layout">
      {{! The header sits outside AsyncContent so the picker stays reachable
          when the selected view turns up empty. }}
      <div class="block-featured-list__header">
        <h2 class="block-featured-list__heading">
          <DMenu
            @identifier="topics-view"
            @modalForMobile={{true}}
            @triggerClass="block-featured-list__picker"
            @ariaLabel={{i18n (themePrefix "homepage.topics.change_view")}}
          >
            <:trigger>
              {{i18n (themePrefix this.selected.labelKey)}}
              {{dIcon "angle-down"}}
            </:trigger>
            <:content as |menu|>
              <DropdownMenu as |dropdown|>
                {{#each VIEWS as |view|}}
                  <dropdown.item>
                    <DButton
                      class="btn-transparent block-featured-list__option
                        {{if (eq view.key this.selected.key) '--active'}}"
                      @translatedLabel={{i18n (themePrefix view.labelKey)}}
                      @action={{fn this.select view.key menu.close}}
                    />
                  </dropdown.item>
                {{/each}}
              </DropdownMenu>
            </:content>
          </DMenu>
        </h2>

        {{#if @linkText}}
          <DButton
            class="btn-flat block-featured-list__link"
            @href={{this.linkUrl}}
            @translatedLabel={{i18n (themePrefix @linkText)}}
          />
        {{/if}}
      </div>

      <DAsyncContent
        @asyncData={{this.fetchTopics}}
        @context={{this.selected.key}}
        @retainWhileReloading={{true}}
      >
        <:loading>
          <div class="block-featured-list__loading"><div
              class="spinner"
            /></div>
        </:loading>

        <:empty>
          <div class="block-featured-list__empty">
            {{#if @emptyMessage}}
              {{i18n (themePrefix @emptyMessage)}}
            {{else}}
              {{i18n "topics.none.latest"}}
            {{/if}}
          </div>
        </:empty>

        <:content>
          <div class="block-featured-list__list">
            <BasicTopicList
              @topics={{this.topics}}
              @showPosters={{true}}
              @listContext={{@listContext}}
            />
          </div>

          {{#if this.canLoadMore}}
            <div
              class="block-featured-list__sentinel"
              {{didInsert this.watchSentinel}}
            ></div>
          {{/if}}
        </:content>
      </DAsyncContent>
    </div>
  </template>
}
