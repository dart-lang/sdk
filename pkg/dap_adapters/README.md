# package:dap_adapters

Dart Debug Adapter Protocol (DAP) adapters.

This package contains implementations of the Debug Adapter Protocol (DAP) for Dart. These adapters translate DAP requests from an IDE (or other client) into the Dart VM Service protocol, enabling debugging of Dart applications.

## Functionality

This package provides:

*   **Dart CLI Debug Adapter**: For debugging command-line Dart applications.
*   **Dart Test Debug Adapter**: For debugging Dart tests (running via `package:test`).

These adapters were previously shipped as part of `package:dds`.

## Usage

Typically, you do not need to use this package directly. It is used by IDE extensions (such as Dart Code for VS Code) to manage debugging sessions.
