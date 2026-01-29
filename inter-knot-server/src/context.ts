import { PrismaClient } from '@prisma/client';
import { Request } from 'express';
import jwt from 'jsonwebtoken';

export const prisma = new PrismaClient();
export const APP_SECRET = 'your-secret-key-change-me';

export interface Context {
  prisma: PrismaClient;
  userId: number | null;
}

export const getContext = async ({ req }: { req: Request }): Promise<Context> => {
  const token = req.headers.authorization || '';
  let userId = null;
  if (token) {
    try {
      const cleanToken = token.replace('Bearer ', '');
      if (cleanToken) {
        const decoded = jwt.verify(cleanToken, APP_SECRET) as { userId: number };
        userId = decoded.userId;
      }
    } catch (e) {
      // invalid token
    }
  }
  return { prisma, userId };
};

