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
import dIcon from "discourse/ui-kit/helpers/d-icon";
import dNumber from "discourse/ui-kit/helpers/d-number";
import { ajax } from "discourse/lib/ajax";
import { bind } from "discourse/lib/decorators";
import KeyValueStore from "discourse/lib/key-value-store";
import { eq, or } from "discourse/truth-helpers";
import { i18n } from "discourse-i18n";

// localStorage, so a member's pick survives the session and the next visit.
// Prefix kept from the theme's old name: renaming it would discard every
// member's saved picks for nothing.
const preferences = new KeyValueStore("branded_custom_homepage_");
const PERIOD_KEY = "leaderboard_period";

// "all" is the value the leaderboard endpoint expects for the all-time bucket
// (the controller maps it to "all_time"); the member sees "total".
const PERIODS = [
  { key: "weekly", labelKey: "homepage.leaderboard.period.weekly" },
  { key: "monthly", labelKey: "homepage.leaderboard.period.monthly" },
  { key: "all", labelKey: "homepage.leaderboard.period.total" },
];

@block("theme:custom-home:leaderboard", {
  description: "Gamification leaderboard showing top users",
  args: {
    count: { type: "number", default: 8 },
    period: { type: "string", default: "weekly" },
  },
})
export default class BlockLeaderboard extends Component {
  @service siteSettings;

  @tracked selectedKey = preferences.get(PERIOD_KEY);

  get selected() {
    return (
      PERIODS.find((o) => o.key === this.selectedKey) ??
      PERIODS.find((o) => o.key === (this.args.period || "weekly")) ??
      PERIODS[0]
    );
  }

  @action
  select(key, close) {
    this.selectedKey = key;
    preferences.set({ key: PERIOD_KEY, value: key });
    close?.();
  }

  @bind
  async fetchLeaderboard(period) {
    const count = this.args.count || 8;

    // No try/catch: a rejection is handed to AsyncContent, which surfaces it.
    const data = await ajax("/leaderboard", {
      data: { period, user_limit: count },
    });

    const users = (data.users || []).map((user, index) => ({
      ...user,
      isCurrentUser: user.id === data.personal?.user?.id,
      isTopRanked: index === 0,
    }));

    return {
      leaderboard: data.leaderboard,
      users,
      personal: data.personal,
      currentUserNotInTop: data.personal?.position > count,
    };
  }

  <template>
    <div class="block-leaderboard__layout">
      <div class="block-leaderboard__header">
        <h2 class="block-leaderboard__heading">
          <DMenu
            @identifier="leaderboard-period"
            @modalForMobile={{true}}
            @triggerClass="block-leaderboard__picker"
            @ariaLabel={{i18n
              (themePrefix "homepage.leaderboard.change_period")
            }}
          >
            <:trigger>
              {{i18n (themePrefix this.selected.labelKey)}}
              {{dIcon "angle-down"}}
            </:trigger>
            <:content as |menu|>
              <DropdownMenu as |dropdown|>
                {{#each PERIODS as |option|}}
                  <dropdown.item>
                    <DButton
                      class="btn-transparent block-leaderboard__option
                        {{if (eq option.key this.selected.key) '--active'}}"
                      @translatedLabel={{i18n (themePrefix option.labelKey)}}
                      @action={{fn this.select option.key menu.close}}
                    />
                  </dropdown.item>
                {{/each}}
              </DropdownMenu>
            </:content>
          </DMenu>
        </h2>
      </div>

      <DAsyncContent
        @asyncData={{this.fetchLeaderboard}}
        @context={{this.selected.key}}
        @retainWhileReloading={{true}}
      >
        <:loading>
          <div class="block-leaderboard__loading"><div class="spinner" /></div>
        </:loading>

        <:content as |data|>
          <div class="block-leaderboard__list">
            {{#if data.currentUserNotInTop}}
              <div class="block-leaderboard__row --self">
                <span class="block-leaderboard__rank">
                  {{data.personal.position}}
                </span>
                <span class="block-leaderboard__name">
                  {{i18n "gamification.you"}}
                </span>
                <span class="block-leaderboard__score">
                  {{dNumber data.personal.user.total_score}}
                </span>
              </div>
            {{/if}}

            {{#each data.users as |rank|}}
              <div
                class="block-leaderboard__row
                  {{if rank.isCurrentUser '--highlight'}}"
              >
                <div
                  class="block-leaderboard__user"
                  data-user-card={{rank.username}}
                >
                  {{dAvatar rank imageSize="small"}}
                  <span class="block-leaderboard__name">
                    {{#if this.siteSettings.prioritize_username_in_ux}}
                      {{rank.username}}
                    {{else}}
                      {{or rank.name rank.username}}
                    {{/if}}
                  </span>
                </div>
                <span class="block-leaderboard__score">
                  {{dNumber rank.total_score}}
                </span>
              </div>
            {{/each}}
          </div>
        </:content>
      </DAsyncContent>
    </div>
  </template>
}
