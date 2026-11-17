# Self-hosted image for Pages CMS (agence-binom fork).
# Migrations are NOT run at build time: run `npm run db:migrate` as the
# pre-deployment command (node_modules incl. drizzle-kit is kept in the image).

FROM node:22-alpine AS deps
WORKDIR /app
RUN apk add --no-cache libc6-compat
COPY package.json package-lock.json ./
RUN npm ci

FROM node:22-alpine AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
ARG BASE_URL
ENV BASE_URL=$BASE_URL
ENV NEXT_TELEMETRY_DISABLED=1
# Call next directly to skip the "postbuild" migrate hook (no DB at build time).
RUN npx next build

FROM node:22-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
ENV PORT=3000
ENV HOSTNAME=0.0.0.0
RUN addgroup -S -g 1001 nodejs && adduser -S -u 1001 -G nodejs nextjs
COPY --from=builder --chown=nextjs:nodejs /app ./
USER nextjs
EXPOSE 3000
CMD ["npx", "next", "start", "-H", "0.0.0.0", "-p", "3000"]
