import Component from "@glimmer/component";
import { block } from "discourse/blocks";
import CookText from "discourse/components/cook-text";
import DButton from "discourse/ui-kit/d-button";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { and } from "discourse/truth-helpers";
import { i18n } from "discourse-i18n";

@block("theme:custom-home:cta", {
  description: "Call-to-action banner with title, description, and button",
  args: {
    title: { type: "string", required: true },
    description: { type: "string" },
    buttonLabel: { type: "string" },
    buttonLink: { type: "string" },
    icon: { type: "string" },
  },
})
export default class BlockCta extends Component {
  <template>
    <div class="block-cta__layout">
      {{#if @icon}}
        <span class="block-cta__icon">{{dIcon @icon}}</span>
      {{/if}}
      <h2 class="block-cta__title">
        {{i18n (themePrefix @title)}}
      </h2>
      {{#if @description}}
        <div class="block-cta__description">
          <CookText @rawText={{i18n (themePrefix @description)}} />
        </div>
      {{/if}}
      {{#if (and @buttonLink @buttonLabel)}}
        <DButton
          class="btn-primary block-cta__button"
          @href={{@buttonLink}}
          @translatedLabel={{i18n (themePrefix @buttonLabel)}}
        />
      {{/if}}
    </div>
  </template>
}
