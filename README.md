# Custom Home

Discourse theme component with Meta-style homepage blocks. Adapted from
[discourse/discourse-theme-skills](https://github.com/discourse/discourse-theme-skills).

## Where it lives

The `custom_homepage` modifier gives Discourse a custom homepage route:

- Set it as the site homepage and it is served at **`/`**.
- Keep **Latest** as the default view and it stays reachable at **`/custom`**.

The path is core's, so a theme cannot move it (e.g. to `/home`): a direct visit to
any other path hits Discourse's server router, which only knows `/custom`.

## Blocks

- **Hero** — title, subtitle, optional icon (`hero_icon`) and image (`hero_image`,
  beside the text on wide screens, above it on narrow ones). Signed-out visitors
  always see it, and get a "Get started" button to `/signup`; signed-in members
  see it only if they are in a group picked in `hero_groups`, so it can run as a
  banner aimed at new members.
- **Featured topics** — horizontal card scroller (CSS scroll-snap, no JS). Shown
  only when `featured_topics_tags` or `featured_topics_categories` is set. Members
  pick the source from a dropdown and the choice is remembered per browser;
  signed-out visitors always see the first one. Categories the viewer cannot
  access are dropped. Cards show the topic's **AI gist** instead of its excerpt
  when one exists, unless the viewer picked Compact or Excerpts on the
  excerpts/gists button.
- **Topic list** — one list, switchable from a dropdown between *Latest*,
  *Trending now* (`hot`) and *Best of* the week, month or all time (`top` with a
  period), opening on `topics_default_view` and remembered per browser. Only Top
  takes a period: Latest orders by last activity, Hot bakes its own decay into
  the score. Falls back to latest when the chosen view is empty, which Hot is
  until Discourse has scored topics. Scrolling to the end appends up to two more
  pages through an IntersectionObserver, then leaves the "view all" link to do
  the rest — nothing loads until the end of the list is actually reached.
  Rendered with Horizon's topic cards when attached to it, so it carries AI gists
  wherever the topic list does (`featured_list_count`).
- **Leaderboard** — weekly, monthly or total karma, switchable from a dropdown and
  remembered per browser. Shows your own position when you are outside the top
  `leaderboard_count`. Needs `discourse_gamification_enabled`.
- **Upcoming events** — from discourse-calendar's post events. Needs
  `calendar_enabled`.
- **Sign-up call to action** — for signed-out visitors (`cta_link`, `cta_icon`).
- **Right-sidebar card treatment**, so
  [discourse-right-sidebar-blocks](https://github.com/discourse/discourse-right-sidebar-blocks)
  matches the homepage.

## AI gists

Gists only appear for viewers discourse-ai lets see them: `ai_summary_gists_enabled`
on, and the agent in `ai_summary_gists_agent` allowing the viewer's group (`everyone`
to include signed-out visitors). Without that, cards fall back to the excerpt.

## Install

Upload in **Admin > Customize > Themes** and attach it to your active theme. Then
either set the homepage to the custom page, or leave Latest as default and link to
`/custom`.
