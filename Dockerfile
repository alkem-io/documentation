# Stage 1: Build the Nextra site
FROM node:18-alpine AS build

# Set the working directory inside the container
WORKDIR /app

# Copy package.json and package-lock.json
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy all the project files
COPY . .

# Build the Nextra static site
RUN npm run build

# Stage 2: Serve the built site with a lightweight server
FROM node:18-alpine AS serve

# Install a lightweight HTTP server (such as serve)
RUN npm install -g serve

# Set the working directory inside the container
WORKDIR /app

# Copy the build output from the previous stage
COPY --from=build /app/out ./out

# Expose port 3010 to access the site
EXPOSE 3010

# Serve the built site
CMD ["serve", "-s", "out", "-l", "3010"]