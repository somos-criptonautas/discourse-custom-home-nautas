import BlockHead from "discourse/blocks/builtin/block-head";
import { apiInitializer } from "discourse/lib/api";
import getURL from "discourse/lib/get-url";
import BlockHero from "../blocks/block-hero";

// List settings arrive as a pipe-separated string of group names, which is what
// the user condition matches on.
const heroGroups = (settings.hero_groups || "").split("|").filter(Boolean);

// Shared hero args; the signup button is added only for signed-out visitors.
const heroArgs = {
  title: "hero.title",
  subtitle: "hero.subtitle",
  icon: settings.hero_icon,
  // An unset upload setting is null, and the block args are typed as
  // strings. Empty string is falsy in the template, so no image renders.
  image: settings.hero_image || "",
};

export default apiInitializer((api) => {
  api.renderBlocks("main-outlet-blocks", [
    {
      block: BlockHead,
      id: "homepage-hero",
      conditions: { type: "route", pages: ["HOMEPAGE"] },
      children: [
        {
          block: BlockHero,
          id: "homepage-hero-anon",
          args: {
            ...heroArgs,
            buttonLabel: "hero.button_label",
            buttonLink: getURL("/signup"),
          },
          conditions: { type: "user", loggedIn: false },
        },
        // Signed in: the hero is a banner for the groups named in
        // hero_groups only — for everyone else it is a pitch they have already
        // accepted. An empty setting hides it from every member.
        ...(heroGroups.length
          ? [
              {
                block: BlockHero,
                id: "homepage-hero-user",
                args: heroArgs,
                conditions: { type: "user", groups: heroGroups },
              },
            ]
          : []),
      ],
    },
  ]);
});
