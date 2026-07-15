# DartPad SDK Protocol

This document specifies what a "DartPad SDK" is, how it is instantiated, and how
one interacts with it. `package:dartpad` is the official client for this
protocol.

At a high-level a _DartPad SDK_ provides a worker that a dartpad-like
environment can use to fetch dependencies, analyze, compile and run Dart code.

**Concepts:**
 * _Session_, when a client connects to the worker, a session is created.
  Sessions do share the same file-system and thread. But are otherwise
  independent, and should be using differnet parts of the virtual file-system.
 * _Workspace_, a workspace is a folder and associated resources for
   running language-servers and compiling source code.
 * _Language-server_, a process running within a workspace that provides a
   language-server-protocol server for Dart.
 * _Hot-reload compiler_, a process running with a workspace that faciliates
   incremental compilation of a single entry-point.


## DartPad SDK

A _DartPad SDK_ is an `assetBaseUrl` that points to a directory that hosts:
 * `worker.js`, script for running a dartpad environment in the browser.
 * `sandbox.js`, script for running compiled code in a sandboxed iframe.
 * SDK specific assets referenced by `worker.js` and `sandbox.js`.

The `worker.js` script must export a `Worker` class that can be instantiated as
follows:

```js
import {Worker} from 'worker.js';
const worker = await Worker.create();

// Create a session communicating over workerMessagePort
worker.session(workerMessagePort);
```

Once instantiated, one or more sessions can be created using `worker.session()`,
which will communicate over the given [MessagePort][2] using the protocol
specified in this document.

// TODO(jonasfj): Refactor sandbox.js into this shape later.

The `sandbox.js` script is to be injected into a sandboxed iframe as follows:
```
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <script src="sandbox.js"></script>
</head>
<body></body>
</html>
```

The `sandbox.js` script must use [window.postMessage][4] to send, either:
 * `{action: 'error', message: '...'}`, if loading failed, or,
 * `{action: 'connect'}` with a [MessagePort][2] attached, if loading succeeded.

The attached [MessagePort][2] must be forwarded to the worker as outline in the
protocol below. The communication protocol between `sandbox.js` and `worker.js`
is private, though messages will never carry a `MessagePort`, thus, they can
be serialized (with care taken to wrap `Uint8Array` instances).


## JSON-RPC 2.0 over `MessagePort`

Communication with the worker is conducted over a [MessagePort][2] using an
extension of the [JSON-RPC 2.0][3] protocol.

While the official JSON-RPC 2.0 specification mandates that messages be JSON,
we leverage the browser's [Structured Clone][5] algorithm to transmit JSON-like
JavaScript objects. The message structures conform to JSON-RPC 2.0, with two
extensions:

 * **MessagePort transfer:** `params.port` and `result.port`, if present,
   may be a [MessagePort][2].
 * **Binary data support:** The JSON-like structure may include `Uint8Array`
   objects.

These extensions means that messages cannot be serialized as JSON.

[JSON-RPC 2.0][3] requests are usually on the form:
```js
{
  "jsonrpc": "2.0",
  "method": "<name-of-method>",
  "params": {
    // parameters for the method
    "port": /* [Optional] MessagePort instance */
  },
  "id": 42 // unique ID per request, omitted for notifications!
}
```

If the `id` property is omitted, then the message is said to be a _notification_
and no response will be sent. For _requests_ the `id` must be unique and must
be used by the client to find the matching _response_ for the _request_.

Response objects are usually on the form:
```js
{
  "jsonrpc": "2.0",
  "result": {
    // result values from the method
    "port": /* [Optional] MessagePort instance */
  },
  "id": 42 // ID from the request
}
```

If an error occured when handling a _request_, then an error will be returned.
Errors will never be returned for _notifications_, since notifications don't
carry an `id` property, they never produce a _response_ or an _error_.

Errors are usually on the form:
```js
{
  "jsonrpc": "2.0",
  "error": {
    "code": 1000, // Integer error code (negative numbers are reserved)
    "message": "<human readable message>",
    "data": {
      // Arbitrary data associated from the error handler.
    }
  },
  "id": 42 // ID from the request
}
```

When sending requests and notifications is possible to batch multiple messages
into a single message by sending an array of requests and notifications.

For further details about JSON-RPC 2.0, refer to the [specification][3].


## Server Methods and Notifications

Methods are prefixed based on what objects they operate on. Thus, all methods
prefixed `workspace/` require a `workspaceId` parameter.


| **Method Prefix** | **Required identifiers** |
| :--- | :--- |
| `workspace/` | `workspaceId` |
| `workspace/languageServer/` | `workspaceId` and `languageServerId` |
| `workspace/watcher/` | `workspaceId` and `watcherId` |
| `workspace/hotReloadCompiler/` | `workspaceId` and `hotReloadCompilerId` |


### Method `createWorkspace`

Creates workspace with a dedicated `workspaceFolder`.

**Params:**
```js
{} // No parameters!
```

**Result:**
```js
{
  // The workspaceId is a unique number identifying the workspace created
  "workspaceId": 42,
  // Folder on the shared file-system dedicated to this workspace
  "workspaceFolder": "file:///workspace/pad_42/",
}
```

### Method `workspace/dispose`
Deletes the workspace and all associated resources.

**Params:**
```js
{
  "workspaceId": 42,
}
```

**Result:**
```js
{} // empty result
```

### Method `workspace/writeFileFromText`
Write a `text` string to a file as UTF-8.
Parent directories will be automatically created.

**Params:**
```js
{
  "workspaceId": 42,
  // URI of the file that you want to write.
  // Can be absolute file:// or relative to workspaceFolder
  "uri": "bin/hello.dart",
  // Text that should be written to the file.
  // This will be written as UTF-8.
  "text": "void main() => print('hello world');",
}
```

**Result:**
```js
{} // empty result
```

### Method `workspace/writeFileFromBytes`

**Params:**
```js
{
  "workspaceId": 42,
  "uri": "bin/hello.dart",
  // Bytes that should be written to the file as base64
  "base64": "<base64-encoded bytes>",
}
```

**Result:**
```js
{} // empty result
```

### Method `workspace/readFileAsText`

**Params:**
```js
{
  "workspaceId": 42,
  "uri": "bin/hello.dart",
}
```

**Result:**
```js
{
  "text": "<contents of the file as UTF-8>"
}
```

### Method `workspace/readFileAsBytes`

**Params:**
```js
{
  "workspaceId": 42,
  "uri": "bin/hello.dart",
}
```

**Result:**
```js
{
  "base64": "<bytes from the file encoded as base64>"
}
```

### Method `workspace/deleteFileSystemEntity`

**Params:**
```js
{
  "workspaceId": 42,
  // URI of the file or folder that you want to delete.
  "uri": "bin/hello.dart",
}
```

**Result:**
```js
{} // empty result
```

### Method `workspace/stat`
Get information about a file or folder.

**Params:**
```js
{
  "workspaceId": 42,
  "uri": "bin/hello.dart",
}
```

**Result:**
```js
{
  // Type of the entity: "file", "folder" or "other"
  "type": "file" | "folder" | "other",
  // Size in bytes (only for files)
  "size": 1024
}
```

### Method `workspace/createFolder`

**Params:**
```js
{
  "workspaceId": 42,
  "uri": "lib",
}
```

**Result:**
```js
{} // empty result
```

### Method `workspace/listDirectory`

**Params:**
```js
{
  "workspaceId": 42,
  "uri": "lib",
  // Whether to list recursively (default: false)
  "recursive": true,
  // Whether to ignore hidden files (starting with .) (default: false)
  "ignoreHidden": true
}
```

**Result:**
```js
{
  // List of entries. Paths are relative to the uri listed.
  "entries": [
    {"path": "main.dart", "type": "file"},
    {"path": "src", "type": "folder"}
  ]
}
```

### Method `workspace/importTarArchive`
Import a tar archive (uncompressed) into the workspace.

**Params:**
```js
{
  "workspaceId": 42,
  // Path where to extract the archive.
  "uri": ".",
  // Base64 encoded tar archive.
  "base64": "<base64-encoded-tar>"
}
```

**Result:**
```js
{} // empty result
```

### Method `workspace/exportTarArchive`
Export a directory as a tar archive (uncompressed).

**Params:**
```js
{
  "workspaceId": 42,
  // Directory to export.
  "uri": "."
}
```

**Result:**
```js
{
  // Base64 encoded tar archive.
  "base64": "<base64-encoded-tar>"
}
```

### Method `workspace/pub`
Runs `pub` in the specified directory.

**Params:**
```js
{
  "workspaceId": 42,
  // Directory to run pub in.
  "uri": ".",
  // Command to run.
  "command": "get" | "add" | "downgrade" | "outdated" | "upgrade" | "remove" | "unpack",
  // Arguments to pass to the pub command (optional)
  "args": ["--dry-run"]
}
```

**Result:**
```js
{
  "log": "<output from pub get>",
}
```

### Method `workspace/startHotReloadCompiler`
Start a hot-reload compiler for `uri`.

**Params:**
```js
{
  "workspaceId": 42,
  "uri": "bin/hello.dart",
}
```

**Result:**
```js
{
  // identifier for the hot-reload compiler just started
  "hotReloadCompilerId": 67,
}
```

### Method `workspace/hotReloadCompiler/compile`
Run the hot-reload compiler for the `uri` it was started with.
Returns `code` and `compiledLibraryUris`, which must be supplied to the
hot-reload method as `librariesToReload` when hot-reloading.

**Params:**
```js
{
  "workspaceId": 42,
  "hotReloadCompilerId": 67,
}
```

**Result:**
```js
{
  // Code is `null` if compilation failed!
  "code": "<javascript code>" || null,
  "compiledLibraryUris": ["package:myapp/myapp.dart", ...],
  "log": "<log lines>",
}
```

### Method `workspace/hotReloadCompiler/close`
Close the hot-reload compiler, releasing resources (memory) held.

**Params:**
```js
{
  "workspaceId": 42,
  "hotReloadCompilerId": 67,
}
```

**Result:**
```js
{} // empty result
```

### Method `workspace/startLanguageServer`
Start a language-server.

**Params:**
```js
{
  "workspaceId": 42,
}
```

**Result:**
```js
{
  "languageServerId": 36, // identifier for the language-server just started
}
```

### Method `workspace/languageServer/message`
Sends an LSP message to a running language server.

**Params:**
```js
{
  "workspaceId": 42,
  "languageServerId": 36,
  "message": {
    // JSON-RPC 2.0 message for the language-server
    "jsonrpc": "2.0",
    "method": "...",
    "params": {...},
    "id": ...,
  },
}
```

**Result:**
```js
{} // empty result
```

### Method `workspace/languageServer/stop`

**Params:**
```js
{
  "workspaceId": 42,
  "languageServerId": 36,
}
```

**Result:**
```js
{} // empty result
```


### Method `workspace/startWatcher`

Initiates a file system watcher for a given URI.

**Params:**
```js
{
  "workspaceId": 42,
  "uri": ".",
}
```

**Result:**
```js
{
  "watcherId": 1
}
```

### Method `workspace/watcher/stop`

Terminates an active watcher.

**Params:**
```js
{
  "workspaceId": 42,
  "watcherId": 1
}
```

**Result:**
```js
{} // empty result
```

## Client Notifications

### Notification `workspace/watcher/events`

Sent when changes occur within the watched paths.

**Params:**
```js
{
  "workspaceId": 42,
  "watcherId": 1,
  "events": [
    {
      "type": "add" | "modify" | "remove",
      "uri": "file:///workspace/pad_42/lib/main.dart"
    }
  ]
}
```

### Notification `workspace/languageServer/message`
Sent by the worker when the language server produces a message.

**Params:**
```js
{
  "workspaceId": 42,
  "languageServerId": 36,
  "message": {
    // JSON-RPC 2.0 message from the language-server
  }
}
```

### Notification `workspace/languageServer/exited`
Sent by the worker when a language server process terminates.

**Params:**
```js
{
  "workspaceId": 42,
  "languageServerId": 36
}
```

## Error codes
Errors returned by the worker use the following codes.

<!-- BEGIN GENERATED ERROR CODE TABLE -->
| Code | Name | Description |
| :--- | :--- | :--- |
| 2001 | `workspaceNotFound` | The provided `workspaceId` does not exist. |
| 4001 | `fileNotFound` | The requested file or directory does not exist. |
| 4002 | `fileWriteConflict` | Could not write file (e.g. parent is a file). |
| 4003 | `fileDeletionFailed` | Could not delete the requested entity. |
| 5001 | `languageServerNotFound` | The `languageServerId` does not exist in this workspace. |
| 6001 | `compilationFailed` | Failed to compile code, usually due to an issue in the code being compiled. |
| 6020 | `packageConfigNotFound` | Unable to find `.dart_tool/package_config.json` in any parent directory. |
| 6100 | `hotReloadCompilerNotFound` | The `hotReloadCompilerId` does not exist in this workspace. |
| 6101 | `hotReloadRejected` | The hot reload request was rejected by the compiler. |
| 7001 | `pubCommandFailed` | The pub command failed to execute successfully. |
| 7064 | `pubUsage` | The command was used incorrectly. |
| 7065 | `pubData` | The input data was incorrect. |
| 7066 | `pubNoInput` | An input file did not exist or was unreadable. |
| 7067 | `pubNoUser` | The user specified did not exist. |
| 7068 | `pubNoHost` | The host specified did not exist. |
| 7069 | `pubUnavailable` | A service is unavailable. |
| 7070 | `pubSoftware` | An internal software error has been detected. |
| 7071 | `pubOs` | An operating system error has been detected. |
| 7072 | `pubOsFile` | Some system file did not exist or was unreadable. |
| 7073 | `pubCantCreate` | A user-specified output file cannot be created. |
| 7074 | `pubIo` | An error occurred while doing I/O on some file. |
| 7075 | `pubTempFail` | Temporary failure, indicating something that is not really an error. |
| 7076 | `pubProtocol` | The remote system returned something invalid during a protocol exchange. |
| 7077 | `pubNoPerm` | The user did not have sufficient permissions. |
| 7078 | `pubConfig` | Something was unconfigured or mis-configured. |
| 8001 | `moduleLoaderNotAvailable` | The DDC module loader is has not been loaded into the sandbox. |
| 8002 | `flutterLoaderNotAvailable` | The flutter loader has not been loaded into the sandbox. |
| 8100 | `moduleLoadingFailed` | Failed to load module into the sandbox. |
| 8200 | `executionFailed` | Error happened when running `main()` from user-code. |
| 8300 | `hotRestartFailed` | Hot-restart failed. |
| 8400 | `hotReloadFailed` | Hot-reload failed. |

<!-- END GENERATED ERROR CODE TABLE -->

[1]: https://developer.mozilla.org/en-US/docs/Web/API/SharedWorker
[2]: https://developer.mozilla.org/en-US/docs/Web/API/MessagePort
[3]: https://www.jsonrpc.org/specification
[4]: https://developer.mozilla.org/en-US/docs/Web/API/Window/postMessage
[5]: https://developer.mozilla.org/en-US/docs/Web/API/Web_Workers_API/Structured_clone_algorithm
