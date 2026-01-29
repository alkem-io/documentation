# Stage 1: Build the Next.js app
FROM node:22-alpine AS build

# Install pnpm globally
RUN npm i -g pnpm@10.17.1

# Set working directory inside the container
WORKDIR /app

# Copy package.json and pnpm-lock.yaml
COPY package.json pnpm-lock.yaml ./

# Install dependencies
RUN pnpm install --frozen-lockfile

# Copy the rest of the application files
COPY . .

# Build the Next.js application (creates the `.next` directory)
# postbuild script runs automatically and generates pagefind search index
RUN pnpm run build

# Stage 2: Serve the Next.js app
FROM node:22-alpine AS production

# Install pnpm globally
RUN npm i -g pnpm@10.17.1

# Set working directory inside the container
WORKDIR /app

# Copy only the necessary files from the build stage (to keep image size small)
COPY --from=build /app/package.json /app/pnpm-lock.yaml ./
COPY --from=build /app/.next ./.next
COPY --from=build /app/public ./public
COPY --from=build /app/next.config.mjs ./next.config.mjs
COPY --from=build /app/mdx-components.js ./mdx-components.js
COPY --from=build /app/proxy.js ./proxy.js
COPY --from=build /app/styles.css ./styles.css

# Copy app router files
COPY --from=build /app/app ./app

# Copy content files
COPY --from=build /app/content ./content

# Copy components
COPY --from=build /app/components ./components

# Install only production dependencies
RUN pnpm install --prod --frozen-lockfile

# Expose port 3010 for the application
EXPOSE 3010

# Start the Next.js app in production mode
CMD ["pnpm", "run", "start"]
