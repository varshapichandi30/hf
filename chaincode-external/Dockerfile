FROM golang:1.14.6-alpine AS build

COPY ./ /go/src/github.com/marbles/chaincode-ex
WORKDIR /go/src/github.com/marbles/chaincode-ex

# Build application
RUN go build -o chaincode-ex -v .

# Production ready image
# Pass the binary to the prod image
FROM alpine:3.11 as prod

COPY --from=build /go/src/github.com/marbles/chaincode-ex /app/chaincode-ex

USER 1000

WORKDIR /app
CMD ./chaincode-ex