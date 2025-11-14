# Use official Dart runtime as base image
FROM dart:3.9.2  AS build

WORKDIR /app
COPY pubspec.yaml  ./
RUN dart pub get
COPY . .
RUN dart pub get --offline
RUN dart compile exe bin/server.dart -o bin/server

FROM debian:bookworm-slim

# Install SQLite3 library and create symlink
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates libsqlite3-0 libsqlite3-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
RUN mkdir -p /app/backend/data

COPY --from=build /app/bin/server /app/bin/server
COPY --from=build /app/backend/data/ /app/backend/data/

# Set executable permissions
RUN chmod +x /app/bin/server

EXPOSE 8080

CMD ["/app/bin/server"]