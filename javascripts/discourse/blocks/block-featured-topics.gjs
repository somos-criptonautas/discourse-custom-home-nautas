import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { block } from "discourse/blocks";
import DAsyncContent from "discourse/ui-kit/d-async-content";
import DButton from "discourse/ui-kit/d-button";
import DropdownMenu from "discourse/components/dropdown-menu";
import DMenu from "discourse/float-kit/components/d-menu";
import dAvatar from "discourse/ui-kit/helpers/d-avatar";
import dCategoryLink from "discourse/ui-kit/helpers/d-category-link";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { bind } from "discourse/lib/decorators";
import getURL from "discourse/lib/get-url";
import KeyValueStore from "discourse/lib/key-value-store";
import Category from "discourse/models/category";
import { eq } from "discourse/truth-helpers";
import { i18n } from "discourse-i18n";

// localStorage, so a member's pick survives the session and the next visit.
// Nothing is written to the user's preferences or to the server.
// Prefix kept from the theme's old name: renaming it would discard every
// member's saved picks for nothing.
const preferences = new KeyValueStore("branded_custom_homepage_");
const SOURCE_KEY = "featured_source";

@block("theme:custom-home:featured-topics", {
  description: "Card grid of topics from a selectable tag or category",
  args: {
    tags: { type: "array", itemType: "string" },
    categoryIds: { type: "array", itemType: "string" },
    linkText: { type: "string" },
    count: { type: "number", default: 6 },
    filter: { type: "string", default: "latest" },
    emptyMessage: { type: "string" },
  },
})
export default class BlockFeaturedTopics extends Component {
  @service store;
  @service site;
  @service currentUser;
  // discourse-ai's layout preference, set by the excerpts/gists button. Optional
  // chaining because the service is absent when discourse-ai is disabled.
  @service gists;

  @tracked selectedKey = this.currentUser ? preferences.get(SOURCE_KEY) : null;

  get options() {
    const filter = this.args.filter || "latest";

    const tags = (this.args.tags ?? []).map((tag) => ({
      key: `t:${tag}`,
      label: tag,
      filter: `tag/${tag}/l/${filter}`,
      url: getURL(`/tag/${tag}`),
    }));

    const categories = (this.args.categoryIds ?? [])
      .map((id) => this.site.categoriesById.get(Number(id)))
      // A category the viewer cannot see is absent from the site's serialized
      // category list, so dropping the misses *is* the access check.
      .filter(Boolean)
      .map((category) => ({
        key: `c:${category.id}`,
        label: category.name,
        filter: `c/${Category.slugFor(category)}/${category.id}/l/${filter}`,
        url: category.url,
      }));

    return [...tags, ...categories];
  }

  // Falls back to the first option when nothing is stored, or when the stored
  // one has since left the setting or the viewer's reach.
  get selected() {
    return (
      this.options.find((o) => o.key === this.selectedKey) ?? this.options[0]
    );
  }

  // The AI gist replaces the excerpt unless the viewer picked Compact or Excerpts
  // ("table"), mirroring the topic list. The attribute only exists when
  // discourse-ai's can_see_gists? passes for this viewer, so no other check is needed.
  @bind
  gistFor(topic) {
    return this.gists?.currentPreference === "table"
      ? null
      : topic.ai_topic_gist;
  }

  // Anonymous visitors always get the first option; only members choose, and
  // only when there is more than one thing to choose between.
  get canSwitch() {
    return !!this.currentUser && this.options.length > 1;
  }

  @action
  select(key, close) {
    this.selectedKey = key;
    preferences.set({ key: SOURCE_KEY, value: key });
    close?.();
  }

  @bind
  async fetchTopics(filter) {
    const count = this.args.count || 6;

    const topicList = await this.store.findFiltered("topicList", {
      filter,
      params: { per_page: count },
    });

    return topicList.topics?.length ? topicList.topics.slice(0, count) : null;
  }

  <template>
    {{#if this.selected}}
      <div class="block-featured-topics__layout">
        {{! The header sits outside AsyncContent so the picker stays reachable
            when the selected source turns up empty. }}
        <div class="block-featured-topics__header">
          <h2 class="block-featured-topics__heading">
            {{#if this.canSwitch}}
              <DMenu
                @identifier="featured-topics-source"
                @modalForMobile={{true}}
                @triggerClass="block-featured-topics__picker"
                @ariaLabel={{i18n
                  (themePrefix "homepage.featured_topics.change_source")
                }}
              >
                <:trigger>
                  {{this.selected.label}}
                  {{dIcon "angle-down"}}
                </:trigger>
                <:content as |menu|>
                  <DropdownMenu as |dropdown|>
                    {{#each this.options as |option|}}
                      <dropdown.item>
                        <DButton
                          class="btn-transparent block-featured-topics__option
                            {{if (eq option.key this.selected.key) '--active'}}"
                          @translatedLabel={{option.label}}
                          @action={{fn this.select option.key menu.close}}
                        />
                      </dropdown.item>
                    {{/each}}
                  </DropdownMenu>
                </:content>
              </DMenu>
            {{else}}
              {{this.selected.label}}
            {{/if}}
          </h2>

          {{#if @linkText}}
            <DButton
              class="btn-flat block-featured-topics__link"
              @href={{this.selected.url}}
              @translatedLabel={{i18n (themePrefix @linkText)}}
            />
          {{/if}}
        </div>

        <DAsyncContent
          @asyncData={{this.fetchTopics}}
          @context={{this.selected.filter}}
          @retainWhileReloading={{true}}
        >
          <:loading>
            <div class="block-featured-topics__loading">
              <div class="spinner" />
            </div>
          </:loading>

          <:empty>
            <div class="block-featured-topics__empty">
              {{#if @emptyMessage}}
                {{i18n (themePrefix @emptyMessage)}}
              {{else}}
                {{i18n "topics.none.latest"}}
              {{/if}}
            </div>
          </:empty>

          <:content as |topics|>
            <div class="block-featured-topics__grid">
              {{#each topics as |topic|}}
                <a
                  href={{topic.url}}
                  class="block-featured-topics__card
                    {{if topic.visited 'visited'}}"
                >
                  <div class="block-featured-topics__card-body">
                    <h3 class="block-featured-topics__card-title">
                      {{topic.title}}
                    </h3>
                    {{#if (this.gistFor topic)}}
                      <p class="block-featured-topics__card-excerpt --ai-gist">
                        {{this.gistFor topic}}
                      </p>
                    {{else if topic.excerpt}}
                      <p class="block-featured-topics__card-excerpt">
                        {{topic.excerpt}}
                      </p>
                    {{/if}}
                  </div>
                  <div class="block-featured-topics__card-meta">
                    <div class="block-featured-topics__card-author">
                      {{dAvatar topic.creator imageSize="tiny"}}
                      <span>{{topic.creator.username}}</span>
                    </div>
                    {{dCategoryLink topic.category}}
                  </div>
                </a>
              {{/each}}
            </div>
          </:content>
        </DAsyncContent>
      </div>
    {{/if}}
  </template>
}
