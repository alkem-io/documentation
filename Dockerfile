# Stage 1: Build the Next.js app
FROM node:20-alpine AS build

# Set working directory inside the container
WORKDIR /app

# Copy package.json and package-lock.json (or yarn.lock if you use Yarn)
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy the rest of the application files
COPY . .

# Build the Next.js application (creates the `.next` directory)
RUN npm run build

# Stage 2: Serve the Next.js app
FROM node:20-alpine AS production

# Set working directory inside the container
WORKDIR /app

# Copy only the necessary files from the build stage (to keep image size small)
COPY --from=build /app/package*.json ./
COPY --from=build /app/.next ./.next
COPY --from=build /app/public ./public
COPY --from=build /app/next.config.js ./next.config.js
COPY --from=build /app/theme.config.jsx ./theme.config.jsx

COPY --from=build /app/pages ./pages 

# Install only production dependencies
RUN npm install --only=production

# Expose port 3010 for the application
EXPOSE 3010

# Start the Next.js app in production mode
CMD ["npm", "run", "start"]