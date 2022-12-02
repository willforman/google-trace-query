FROM clickhouse/clickhouse-server:22-alpine

RUN apk --no-cache add curl # Alpine doesn't have curl initially

# Install dbmate so we can migrate the db before adding to it
RUN curl -fsSL -o /usr/local/bin/dbmate https://github.com/amacneil/dbmate/releases/latest/download/dbmate-linux-amd64
RUN chmod +x /usr/local/bin/dbmate

# Install inotify-tools so we can watch the directory for new files
RUN apk add inotify-tools
