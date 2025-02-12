# Use an official Nginx image as the base image
FROM nginx:alpine

# Remove the default Nginx index.html page (optional, just to be sure)
RUN rm /usr/share/nginx/html/*

# Copy the custom hello.html file to the correct Nginx directory
COPY hello.html /usr/share/nginx/html/index.html

# Expose port 80 for web traffic
EXPOSE 80

# Run nginx in the foreground
CMD ["nginx", "-g", "daemon off;"]
