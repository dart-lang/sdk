# Common Services

These are service methods and events that may be registered to DTD by multiple client types (e.g. multiple IDEs support navigating to a location in code). Other clients can then rely on service methods having a common interface despite being implemented by different client types. For example, DevTools should be able to request navigation to code using the same service method regardless of whether VS Code or IntelliJ registered it.

Notes:

- Though multiple client types may register these methods, a single instance of DTD will accept only one client registering as a particular service. (DTD will throw an error if a second client tries to register as the same service.)
- These methods are not implemented in DTD. Rather, we want any new clients registering methods for a common purpose to follow a shared interface.
- These methods may not be registered at all to DTD, depending on what other tools are connected. Clients hoping to use these methods should use the [`Service` stream](./dtd_protocol.md#service-methods) to monitor whether these services are available.


## Service Definitions

- [Editor Service](./dtd_common_services_editor.md)
  Services provided by an editor or IDE for tools to interact with code, devices and debug sessions.


## Registering a service method with DTD

DTD uses JSON-RPC for communication. Methods can be registered by calling the `registerService` method documented in the [DTD Protocol](./dtd_protocol.md).

### Example

```json
{
  "jsonrpc": "2.0",
  "method": "registerService",
  "params": {
    "service": "Editor",
    "method": "navigateToCode",
    "capabilities": {
      "supportedSchemes": ["file", "dart-macro+file"],
    }
  },
  "id": "0"
}
```

## Calling a service method over DTD

Calling a service method involves a JSON-RPC request to a method name that
combines the service and method name, for example `"Editor.navigateToCode"`.

### Example

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

## Responses

The response will contain a `result` that has a `type` indicating the type of
returned data or `Success` if a successful request has no return value. Errors
will be indicated as JSON-RPC errors with a `code` and `message`.

### Examples

#### Success

If a request is successful but has no specific return value, a `Success` result
is returned.

```json
{
  "jsonrpc": "2.0",
  "result": {"type": "Success"},
  "id": "0"
}
```

#### Error

If an error occurs, there will be no `result` but instead an `error`.

```json
{
  "jsonrpc": "2.0",
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
  "id": "0"
}
```

## Common Error Codes

Below are some common error codes that may be used by all common services.
Individual services may document their own error codes.

| Error code    | Description |
| -------- | ------- |
| 144  | The URI's scheme is not recognized. |
