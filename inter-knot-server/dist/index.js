"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const server_1 = require("@apollo/server");
const express4_1 = require("@apollo/server/express4");
const cors_1 = __importDefault(require("cors"));
const schema_1 = require("./schema");
const resolvers_1 = require("./resolvers");
const context_1 = require("./context");
async function startServer() {
    const app = (0, express_1.default)();
    const server = new server_1.ApolloServer({
        typeDefs: schema_1.typeDefs,
        resolvers: resolvers_1.resolvers,
    });
    await server.start();
    app.use('/graphql', (0, cors_1.default)(), express_1.default.json(), 
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    (0, express4_1.expressMiddleware)(server, {
        context: context_1.getContext,
    }));
    const PORT = 4000;
    app.listen(PORT, () => {
        console.log(`🚀 Server ready at http://localhost:${PORT}/graphql`);
    });
}
startServer();
