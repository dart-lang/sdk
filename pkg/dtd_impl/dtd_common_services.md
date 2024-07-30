# Common service methods

These are service methods that may be registered to DTD by multiple client types (e.g. multiple IDEs support navigating to a location in code). Other clients can then rely on service methods having a common interface despite being implemented by different client types. For example, DevTools should be able to request navigation to code using the same service method regardless of whether VS Code or IntelliJ registered it.

Notes:

- Though multiple client types may register these methods, a single instance of DTD will accept only one client registering as a particular service. (DTD will throw an error if a second client tries to register as the same service.)
- These methods are not implemented in DTD. Rather, we want any new clients registering methods for a common purpose to follow a shared interface.
- These methods may not be registered at all to DTD, depending on what other tools are connected. Clients hoping to use these methods should use the [`Service` stream](dtd_protocol.md#service-methods) to monitor whether these services are available.

## Navigate to code location

This is a service method that should be registered by a client that displays code (likely an IDE), so that other clients can request showing a specific location in code.

### Registering the method with DTD

This is what the client handling navigate to code requests (i.e. IDE) should send to DTD:

```json
{
  "jsonrpc": "2.0",
  "method": "registerService",
  "params": {
    "service": "Editor",
    "method": "navigateToCode",
    "capabilities": {
      "supportedSchemes": ["file", "dart-macro-file"],
    }
  },
  "id": "0"
}
```

### Request Parameters

These are the parameters a client should send when requesting an editor navigate to code.

- `String uri` - The URI of the location to navigate to. Only `file://` URIs are supported unless the service registration's `capabilities` indicate other schemes are supported (specifics to be defined here in future). Editors should return error code 144 if a caller passes a URI with an unsupported scheme.
- optional `int line` - 1-based line number.
- optional `int column` - 1-based column number.

#### Example

```json
{
  "jsonrpc": "2.0",
  "method": "Editor.navigateToCode",
  "params": {
    "file": "file:///path/to/file.dart",
    "line": 1,
    "column": 2,
  },
  "id": "0"
}
```

### Result

These are the parameters in a result:

- `String type` - one of `Success` or `Failure`.
- optional `String errorCode` - a specific error code for a well-known failure type.

    | Error code    | Description |
    | -------- | ------- |
    | 144  | The URI's scheme is not recognized by the editor. |

- optional `String errorMessage` - a freeform message about the error.

#### Examples

If navigation in the editor is successful, a Success result should be returned.

```json
{
  "jsonrpc": "2.0",
  "result": {"type": "Success"},
  "id": "0"
}
```

Otherwise, the client can return an error code and/or an error message.

```json
{
  "jsonrpc": "2.0",
  "result": {
    "type": "Failure",
    "error": {
      "code": 144,
      "message": "File scheme is not supported",
      "data": {
        "details": "File URI `malformed-file:///file.dart` is not valid.",
        "request": {
          "id": "0",
          "jsonrpc": "2.0",
          "method": "Editor.navigateToCode",
          "params": {
            "file": "malformed-file:///file.dart",
            "line": 1,
            "column": 2,
          }
        }
      }
    }
  },
  "id": "0"
}
```
