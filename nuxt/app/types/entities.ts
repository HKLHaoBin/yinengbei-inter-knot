export interface Author {
  id?: string | number;
  documentId?: string;
  authorId?: string;
  username?: string;
  login?: string;
  name?: string;
  email?: string;
  avatar?: string;
  exp?: number;
  level?: number;
}

export interface Discussion {
  id: string;
  title: string;
  body?: string;
  bodyText?: string;
  rawBodyText?: string;
  cover?: string;
  coverWidth?: number;
  coverHeight?: number;
  views?: number;
  likesCount?: number;
  commentsCount?: number;
  isPinned?: boolean;
  isRead?: boolean;
  liked?: boolean;
  createdAt?: string;
  updatedAt?: string;
  author: Author;
}

export interface CommentReply {
  id: string;
  content: string;
  liked?: boolean;
  likesCount?: number;
  createdAt?: string;
  author: Author;
}

export interface Comment {
  id: string;
  content: string;
  liked?: boolean;
  likesCount?: number;
  createdAt?: string;
  author: Author;
  replies: CommentReply[];
}

export interface Profile {
  documentId: string;
  login?: string;
  name?: string;
  bio?: string;
  avatar?: string;
  level?: number;
  exp?: number;
}

export interface LikeToggleResult {
  liked: boolean;
  likesCount: number;
}
