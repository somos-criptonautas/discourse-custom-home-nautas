import Component from "@glimmer/component";
import { block } from "discourse/blocks";
import DAsyncContent from "discourse/ui-kit/d-async-content";
import DButton from "discourse/ui-kit/d-button";
import { ajax } from "discourse/lib/ajax";
import { bind } from "discourse/lib/decorators";
import { longDate, shortDateNoYear } from "discourse/lib/formatter";
import { and, or } from "discourse/truth-helpers";
import { i18n } from "discourse-i18n";

// Module-level, not class methods: a method referenced as `{{this.method arg}}`
// is invoked as a plain function, so `this` would be unbound inside it.
function getShortDate(startsAt) {
  return shortDateNoYear(new Date(startsAt));
}

function getLongDate(startsAt) {
  return longDate(new Date(startsAt));
}

@block("theme:custom-home:upcoming-events", {
  description: "Upcoming events from discourse-post-event plugin",
  args: {
    title: { type: "string" },
    count: { type: "number", default: 5 },
    buttonLabel: { type: "string", required: true },
    linkLabel: { type: "string" },
    linkUrl: { type: "string" },
  },
})
export default class BlockUpcomingEvents extends Component {
  @bind
  async fetchEvents() {
    // Leading slash: without it the path resolves against the current route.
    // `limit` is applied server-side by EventFinder, so no over-fetch.
    const { events } = await ajax("/discourse-post-event/events", {
      data: { limit: this.args.count || 5 },
    });

    // An empty array is truthy, so it would never reach the `:empty` block.
    return events?.length ? events : null;
  }

  <template>
    <DAsyncContent @asyncData={{this.fetchEvents}}>
      <:loading>
        <div class="block-upcoming-events__loading">
          <div class="spinner" />
        </div>
      </:loading>

      <:empty>
        <div class="block-upcoming-events__empty">
          {{i18n "discourse_post_event.events_list.empty"}}
        </div>
      </:empty>

      <:content as |events|>
        <div class="block-upcoming-events__layout">
          {{#if @title}}
            <h2 class="block-upcoming-events__title">
              {{i18n (themePrefix @title)}}
            </h2>
          {{/if}}
          <div class="block-upcoming-events__list">
            {{#each events as |event|}}
              <div class="block-upcoming-events__event">
                <span class="block-upcoming-events__date-badge">
                  {{getShortDate event.starts_at}}
                </span>
                <div class="block-upcoming-events__event-info">
                  <h3 class="block-upcoming-events__event-title">
                    {{or event.name event.post.topic.title}}
                  </h3>
                  <span class="block-upcoming-events__event-long-date">
                    {{getLongDate event.starts_at}}
                  </span>
                </div>
                {{#if @buttonLabel}}
                  <DButton
                    class="btn-flat"
                    @href={{event.post.url}}
                    @translatedLabel={{i18n (themePrefix @buttonLabel)}}
                  />
                {{/if}}
              </div>
            {{/each}}
          </div>
          {{#if (and @linkUrl @linkLabel)}}
            <DButton
              class="btn-default block-upcoming-events__link"
              @href={{@linkUrl}}
              @translatedLabel={{i18n (themePrefix @linkLabel)}}
            />
          {{/if}}
        </div>
      </:content>
    </DAsyncContent>
  </template>
}
