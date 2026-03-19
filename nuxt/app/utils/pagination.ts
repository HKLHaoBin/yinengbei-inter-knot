import type { Pagination } from "~/types/api";

export const DEFAULT_PAGE_SIZE = 20;

export function parseStart(endCursor: string): number {
  return Number.parseInt(endCursor || "0", 10) || 0;
}

export function buildPagination<T>(nodes: T[], start: number): Pagination<T> {
  return {
    nodes,
    endCursor: String(start + DEFAULT_PAGE_SIZE),
    hasNextPage: nodes.length >= DEFAULT_PAGE_SIZE,
  };
}
