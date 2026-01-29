"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.getContext = exports.APP_SECRET = exports.prisma = void 0;
const client_1 = require("@prisma/client");
const jsonwebtoken_1 = __importDefault(require("jsonwebtoken"));
exports.prisma = new client_1.PrismaClient();
exports.APP_SECRET = 'your-secret-key-change-me';
const getContext = async ({ req }) => {
    const token = req.headers.authorization || '';
    let userId = null;
    if (token) {
        try {
            const cleanToken = token.replace('Bearer ', '');
            if (cleanToken) {
                const decoded = jsonwebtoken_1.default.verify(cleanToken, exports.APP_SECRET);
                userId = decoded.userId;
            }
        }
        catch (e) {
            // invalid token
        }
    }
    return { prisma: exports.prisma, userId };
};
exports.getContext = getContext;
