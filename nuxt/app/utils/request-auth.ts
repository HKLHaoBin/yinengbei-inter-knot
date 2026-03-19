export function isPublicGetEndpoint(path: string, method: string): boolean {
  const upperMethod = method.toUpperCase();
  if (upperMethod !== "GET") return false;

  return (
    (path.startsWith("/api/articles") && !path.includes("/my")) ||
    (path.startsWith("/api/comments") && !path.includes("/likes")) ||
    path.startsWith("/api/authors")
  );
}

export function shouldAttachToken(path: string, method: string, token: string): boolean {
  if (!token) return false;
  return !isPublicGetEndpoint(path, method);
}
