import { describe, expect, it } from "vitest";
import { buildPagination, parseStart } from "~/utils/pagination";

describe("pagination utils", () => {
  it("parses end cursor to numeric start", () => {
    expect(parseStart("40")).toBe(40);
    expect(parseStart("")).toBe(0);
    expect(parseStart("abc")).toBe(0);
  });

  it("builds pagination with fixed page size", () => {
    const page = buildPagination([1, 2, 3], 20);
    expect(page.nodes).toEqual([1, 2, 3]);
    expect(page.endCursor).toBe("40");
    expect(page.hasNextPage).toBe(false);
  });
});
