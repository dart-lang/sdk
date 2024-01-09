This is a package of classes that are generated from the [DAP specifications](https://microsoft.github.io/debug-adapter-protocol/specification) along with their generating code.

tool/external_dap_spec/debugAdapterProtocol.json is an unmodified copy of the
DAP Specification, downloaded from:

  https://raw.githubusercontent.com/microsoft/debug-adapter-protocol/gh-pages/debugAdapterProtocol.json

This accompanying file is the version of the specification that was used to
generate a portion of the Dart code used to support the protocol.

To regenerate the generated code, run the script in "tool/dap/generate_all.dart"
with no arguments. To download the latest version of the specification before
regenerating the code, run the same script with the "--download" argument.

More information on Dart support for DAP is available [here](https://github.com/dart-lang/sdk/blob/main/pkg/dds/tool/dap/README.md).