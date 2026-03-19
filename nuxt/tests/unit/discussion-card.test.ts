import { mount } from "@vue/test-utils";
import { describe, expect, it } from "vitest";
import DiscussionCard from "~/components/DiscussionCard.vue";

describe("DiscussionCard", () => {
  it("renders title and excerpt", () => {
    const wrapper = mount(DiscussionCard, {
      props: {
        discussion: {
          id: "a1",
          title: "测试标题",
          bodyText: "测试摘要",
          rawBodyText: "",
          author: { name: "作者甲" },
        },
      },
      global: {
        stubs: {
          "z-card": {
            template: "<div><slot /></div>",
          },
          "z-tag": {
            template: "<span><slot /></span>",
          },
        },
      },
    });

    expect(wrapper.text()).toContain("测试标题");
    expect(wrapper.text()).toContain("测试摘要");
  });
});
