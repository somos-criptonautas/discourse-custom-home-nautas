import Component from "@glimmer/component";
import { block } from "discourse/blocks";
import CookText from "discourse/components/cook-text";
import DButton from "discourse/ui-kit/d-button";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";

@block("theme:custom-home:hero", {
  description: "Hero banner with title, subtitle, and call-to-action button",
  args: {
    title: { type: "string", required: true },
    subtitle: { type: "string" },
    buttonLabel: { type: "string" },
    buttonLink: { type: "string" },
    icon: { type: "string" },
    image: { type: "string" },
  },
})
export default class BlockHero extends Component {
  <template>
    <div class="block-hero__layout">
      {{#if @image}}
        <div class="block-hero__media">
          <img src={{@image}} alt="" />
        </div>
      {{/if}}
      <div class="block-hero__content">
        <h1 class="block-hero__title">
          {{#if @icon}}{{dIcon @icon}}{{/if}}
          {{i18n (themePrefix @title)}}
        </h1>
        {{#if @subtitle}}
          <div class="block-hero__subtitle">
            <CookText @rawText={{i18n (themePrefix @subtitle)}} />
          </div>
        {{/if}}
        {{#if @buttonLink}}
          <DButton
            class="btn-primary block-hero__button"
            @href={{@buttonLink}}
            @translatedLabel={{i18n (themePrefix @buttonLabel)}}
          />
        {{/if}}
      </div>
    </div>
  </template>
}
