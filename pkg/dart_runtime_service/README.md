# Dart Runtime Services

Implementations of various Dart developer services based on `package:dart_runtime_service`.

## Shared frontend, pluggable backend

`package:dart_runtime_service` provides a simple interface to create Dart services with common platform-agnostic features and behaviors, while also allowing for configuration of custom service backends. This removes the need for individual services to implement functionality common to most services, including:

- Launching and advertising a server
- Handling connections via various protocols (web sockets, SSE, HTTP)
- Authentication code verification
- Notification routing via stream subscriptions
- Client-registered service extension routing
- DevTools hosting

## Roadmap

There are currently two planned runtime service implementations, with a focus on replacing `dart:_vmservice` and `package:dwds`:

- `package:dart_runtime_service_vm`: an implementation of the Dart VM service protocol which can interact with the native runtimes. To be launched directly as an isolate by `dart` and `dartaotruntime`.

- `package:dart_runtime_service_web`: an implementation of the Dart VM service protocol which serves as a proxy to interact with a running web application. To eventually be launched using `dart web-development-service` by developer tooling responsible for launching and managing DDC-based applications.

Future candidates for migration include:

- `package:dtd_impl`: the implementation of the Dart Tooling Daemon (DTD), which implements a similar protocol to the VM service protocol.

- `package:dds`: the implementation of the Dart Development Service (DDS), which provides extensions to the VM service protocol. DDS reimplements much of the common functionality provided by `package:dart_runtime_service`, particularly around client management, stream subscriptions, and service extension routing.
