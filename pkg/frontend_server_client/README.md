[![pub package](https://img.shields.io/pub/v/frontend_server_client.svg)](https://pub.dev/packages/frontend_server_client)
[![package publisher](https://img.shields.io/pub/publisher/frontend_server_client.svg)](https://pub.dev/packages/frontend_server_client/publisher)

This package provides a client interface around the frontend_server compiler
which ships with the Dart SDK. It is highly dependent on the SDK's version and
thus should only be used within the SDK or for specific tools that need to
interact with our compilers.

## Version restrictions

Every SDK artifact discovered by or passed to `package:frontend_server_client`
needs to have come from the same build, and the version of
`package:frontend_server_client` being used must support that SDK version.

## Serving DDC apps

To serve an app compiled by DDC in its library bundle format, use
`DartDevcFrontendServerClient`, `DdcLibraryBundleSdkAssets`, and
`generateDdcLibraryBundle*`:

- Start `DartDevcFrontendServerClient` with `dartdevcModuleFormat: 'ddc'` and
  `canaryFeatures: true`.
- `sdkRoot` in both `DartDevcFrontendServerClient.start` and
  `DdcLibraryBundleSdkAssets.load` default to the running SDK's directory but
  must be overridden for AoT-compiled apps.
- Call `DdcLibraryBundleSdkAssets.load` from your package root. `dart_sdk.js` is
  compiled on first use and cached in `.dart_tool/frontend_server_client`.
- To use a prebuilt `dart_sdk.js` instead, pass its path to
  `DdcLibraryBundleSdkAssets.load` via `sdkJsPath`. Compile it with `sdkRoot`'s
  DDC using `--modules=ddc --canary`, and place its source map at
  `<sdkJsPath>.map`.