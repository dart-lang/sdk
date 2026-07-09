
An unlisted package for sharing code for service events and stream management between Dart SDK internal services.

The Dart Developer Service and Dart Tooling Daemon are the main consumers of this package.

**Expected SLO**: this package is maintained for our own tooling; we may not be able to respond to all issues and may only address the ones that we ourselves encounter.

## Details

This package helps handle some of the plumbing required to setup client communication for a service. The main behavior that it helps with is:
- `StreamManager`
  - allows a client to subscribe/cancel to a stream with `streamListen`/`streamCancel`.
  - allows a client to post a message to a stream with `postEvent`.
- `Client`, an interface that ensures the client is equipped to:
  - handle method requests with `sendRequest`.
  - handle receiving a message sent to a stream with `streamNotify`.
- `ClientManager`, keeps track of clients connected to a service.
  - `addClient` should be called when a client connects to your service.
  - `removeClient` should be called when it disconnects.

## Usage

  To see an example of how `dart_service_protocol_shared` is used see:
  * [Dart Developer Service](https://github.com/dart-lang/sdk/tree/main/pkg/dds)