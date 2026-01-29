"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.resolvers = void 0;
const context_1 = require("./context");
const bcryptjs_1 = __importDefault(require("bcryptjs"));
const jsonwebtoken_1 = __importDefault(require("jsonwebtoken"));
exports.resolvers = {
    Query: {
        me: (_parent, _args, context) => {
            if (!context.userId)
                return null;
            return context.prisma.user.findUnique({ where: { id: context.userId } });
        },
        getDiscussion: async (_parent, args, context) => {
            return context.prisma.discussion.findUnique({
                where: { id: args.number },
                include: { author: true },
            });
        },
        search: async (_parent, args, context) => {
            const take = args.first || 20;
            const skip = args.after ? 1 : 0;
            const cursor = args.after ? { id: parseInt(args.after) } : undefined;
            const where = {
                OR: [
                    { title: { contains: args.query } },
                    { bodyText: { contains: args.query } },
                ],
            };
            const discussions = await context.prisma.discussion.findMany({
                where,
                take: take + 1, // Get one extra to check hasNextPage
                skip,
                cursor,
                orderBy: { createdAt: 'desc' },
                include: { author: true },
            });
            const hasNextPage = discussions.length > take;
            if (hasNextPage) {
                discussions.pop();
            }
            return {
                nodes: discussions,
                pageInfo: {
                    endCursor: discussions.length > 0 ? discussions[discussions.length - 1].id.toString() : null,
                    hasNextPage,
                },
                totalCount: await context.prisma.discussion.count({ where }),
            };
        },
    },
    Mutation: {
        register: async (_parent, args, context) => {
            const password = await bcryptjs_1.default.hash(args.password, 10);
            const user = await context.prisma.user.create({
                data: { ...args, password },
            });
            const token = jsonwebtoken_1.default.sign({ userId: user.id }, context_1.APP_SECRET);
            return { token, user };
        },
        login: async (_parent, args, context) => {
            const user = await context.prisma.user.findUnique({ where: { email: args.email } });
            if (!user)
                throw new Error('No such user found');
            const valid = await bcryptjs_1.default.compare(args.password, user.password);
            if (!valid)
                throw new Error('Invalid password');
            const token = jsonwebtoken_1.default.sign({ userId: user.id }, context_1.APP_SECRET);
            return { token, user };
        },
        createDiscussion: async (_parent, args, context) => {
            if (!context.userId)
                throw new Error('Not authenticated');
            return context.prisma.discussion.create({
                data: {
                    title: args.title,
                    bodyHTML: args.bodyHTML,
                    bodyText: args.bodyText,
                    cover: args.cover,
                    author: { connect: { id: context.userId } },
                },
                include: { author: true },
            });
        },
        addComment: async (_parent, args, context) => {
            if (!context.userId)
                throw new Error('Not authenticated');
            return context.prisma.comment.create({
                data: {
                    bodyHTML: args.bodyHTML,
                    discussion: { connect: { id: args.discussionId } },
                    author: { connect: { id: context.userId } },
                },
                include: { author: true, discussion: true },
            });
        },
    },
    Discussion: {
        number: (parent) => parent.id,
        commentsCount: (parent, _args, context) => {
            return context.prisma.comment.count({ where: { discussionId: parent.id } });
        },
        comments: async (parent, args, context) => {
            const take = args.first || 20;
            const skip = args.after ? 1 : 0;
            const cursor = args.after ? { id: parseInt(args.after) } : undefined;
            const comments = await context.prisma.comment.findMany({
                where: { discussionId: parent.id },
                take: take + 1,
                skip,
                cursor,
                orderBy: { createdAt: 'asc' }, // Comments typically ascending
                include: { author: true },
            });
            const hasNextPage = comments.length > take;
            if (hasNextPage) {
                comments.pop();
            }
            return {
                nodes: comments,
                pageInfo: {
                    endCursor: comments.length > 0 ? comments[comments.length - 1].id.toString() : null,
                    hasNextPage,
                },
                totalCount: await context.prisma.comment.count({ where: { discussionId: parent.id } }),
            };
        },
    },
    Comment: {
        discussion: (parent, _args, context) => {
            // Optimisation: if parent.discussion is loaded use it, otherwise fetch
            if (parent.discussion)
                return parent.discussion;
            return context.prisma.discussion.findUnique({ where: { id: parent.discussionId } });
        },
        author: (parent, _args, context) => {
            if (parent.author)
                return parent.author;
            return context.prisma.user.findUnique({ where: { id: parent.authorId } });
        }
    },
    User: {
        // Date to ISO string
        createdAt: (parent) => new Date(parent.createdAt).toISOString(),
    }
};
