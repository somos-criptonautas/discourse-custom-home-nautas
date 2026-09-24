import BlockGroup from "discourse/blocks/builtin/block-group";
import { apiInitializer } from "discourse/lib/api";
import getURL from "discourse/lib/get-url";
import BlockCta from "../blocks/block-cta";
import BlockFeaturedList from "../blocks/block-featured-list";
import BlockFeaturedTopics from "../blocks/block-featured-topics";
import BlockLeaderboard from "../blocks/block-leaderboard";
import BlockUpcomingEvents from "../blocks/block-upcoming-events";

// List settings arrive as a pipe-separated string.
const asList = (value) => (value || "").split("|").filter(Boolean);

const featuredTags = asList(settings.featured_topics_tags);
const featuredCategoryIds = asList(settings.featured_topics_categories);

export default apiInitializer((api) => {
  api.renderBlocks("homepage-blocks", [
    {
      block: BlockFeaturedTopics,
      id: "featured-topics",
      args: {
        linkText: "homepage.featured_topics.link_text",
        emptyMessage: "homepage.featured_topics.empty",
        tags: featuredTags,
        categoryIds: featuredCategoryIds,
        count: settings.featured_topics_count,
      },
      // The block renders nothing when neither list resolves to anything, so
      // one "is either configured" check is enough here.
      conditions: {
        any: [
          {
            type: "setting",
            source: settings,
            name: "featured_topics_tags",
            enabled: true,
          },
          {
            type: "setting",
            source: settings,
            name: "featured_topics_categories",
            enabled: true,
          },
        ],
      },
    },
    {
      block: BlockFeaturedList,
      id: "featured-list",
      args: {
        linkText: "homepage.topics.link_text",
        count: settings.featured_list_count,
        defaultView: settings.topics_default_view,
        emptyMessage: "homepage.topics.empty",
        listContext: "discovery",
      },
    },
    {
      block: BlockGroup,
      id: "homepage-right",
      children: [
        {
          block: BlockUpcomingEvents,
          id: "homepage-events",
          args: {
            title: "homepage.events.title",
            count: settings.events_count,
            buttonLabel: "homepage.events.button_label",
            linkLabel: "homepage.events.link_label",
            linkUrl: getURL("/upcoming-events"),
          },
          conditions: {
            type: "setting",
            name: "calendar_enabled",
            enabled: true,
          },
        },
        {
          block: BlockLeaderboard,
          id: "homepage-leaderboard",
          args: {
            count: settings.leaderboard_count,
            period: "weekly",
          },
          conditions: {
            type: "setting",
            name: "discourse_gamification_enabled",
            enabled: true,
          },
        },
      ],
    },
    {
      block: BlockCta,
      id: "homepage-cta",
      args: {
        title: "homepage.cta.title",
        description: "homepage.cta.description",
        buttonLabel: "homepage.cta.button_label",
        buttonLink: getURL(settings.cta_link),
        icon: settings.cta_icon,
      },
      conditions: { type: "user", loggedIn: false },
    },
  ]);
});
