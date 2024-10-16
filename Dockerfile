# Build stage
FROM node:alpine3.16 AS build
WORKDIR /build

# Install OpenSSL for build stage
RUN apk add --update --no-cache openssl1.1-compat

# Install modules with dev dependencies
COPY package.json yarn.lock /build/
RUN yarn install

# Build
COPY . /build
RUN yarn db:generate
RUN yarn build

# Regenerate node modules as production
RUN rm -rf ./node_modules
RUN yarn install --production

# Bundle stage
FROM node:18-alpine AS production

WORKDIR /app

# Copy from build stage
COPY --from=build /build/node_modules ./node_modules
COPY --from=build /build/yarn.lock /build/package.json ./
COPY --from=build /build/public ./public
COPY --from=build /build/prisma ./prisma
COPY --from=build /build/.next ./.next

# Start script
USER node
EXPOSE 3000
CMD ["yarn", "start:prod"]