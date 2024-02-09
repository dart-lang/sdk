# Dart VM Service Protocol Extension 1.6

This protocol describes service extensions that are made available through
the Dart core libraries, but are not part of the core
[Dart VM Service Protocol](service.md). Service extension methods are
invoked by prepending the service extension name (e.g.,
"ext.dart.libraryName") to the RPC to be invoked. For example, the
`getSocketProfile` RPC exposed through dart:io can be executed by invoking
`ext.dart.io.getSocketProfile`.

## dart:io Extensions

This section describes _version 1.6_ of the dart:io service protocol extensions.

### getVersion

```
Version getVersion(string isolateId)
```

The _getVersion_ RPC returns the available version of the dart:io service protocol extensions.

See [Version](#version).

### socketProfilingEnabled

```
SocketProfilingState socketProfilingEnabled(string isolateId, bool enabled [optional])
```

The _socketProfilingEnabled_ RPC is used to enable/disable the socket profiler
and query its current state. If `enabled` is provided, the profiler state will
be updated to reflect the value of `enabled`.

If the state of the socket profiler is changed, a `SocketProfilingStateChange`
event will be sent on the `Extension` stream.

See [SocketProfilingState](#socketprofilingstate).

### clearSocketProfile

```
Success clearSocketProfile(string isolateId)
```

Removes all statistics associated with prior and current sockets.

See [Success](#success).

### getSocketProfile

```
SocketProfile getSocketProfile(string isolateId)
```

The _getSocketProfile_ RPC is used to retrieve socket statistics collected by the socket profiler.
Only samples collected after socket profiling was enabled by calling [socketProfilingEnabled](#socketProfilingEnabled)
or after the last call to [clearSocketProfile](#clearsocketprofile) will be reported.

### getOpenFileById

```
OpenFile getOpenFileById(string isolateId, int id);
```

The _getOpenFileById_ RPC is used to retrieve information about files currently
opened by `dart:io` from a given isolate.

See [getOpenFiles](#getopenfiles) and [File](#file).

### getOpenFiles

```
FileList getOpenFiles(string isolateId);
```

The _getOpenFiles_ RPC is used to retrieve the list of files currently opened
files by `dart:io` from a given isolate.

See [FileList](#filelist) and [File](#file).

### getSpawnedProcessById

```
SpawnedProcess getSpawnedProcessById(string isolateId, int id);
```

The _getSpawnedProcessById_ RPC is used to retrieve information about a process spawned
by `dart:io` from a given isolate.

See [getSpawnedProcesses](#getspawnedprocesses) and [SpawnedProcess](#spawnedprocess).

### getSpawnedProcesses

```
SpawnedProcessList getSpawnedProcesses(string isolateId);
```

The _getSpawnedProcesses_ RPC is used to retrieve the list of processed opened by
`dart:io` from a given isolate.

See [SpawnedProcessList](#spawnedprocesslist) and [SpawnedProcess](#spawnedprocess).

### httpEnableTimelineLogging

```
HttpTimelineLoggingState httpEnableTimelineLogging(string isolateId, bool enabled [optional])
```

The _httpEnableTimelineLogging_ RPC is used to set and inspect the value of
`HttpClient.enableTimelineLogging`, which determines if HTTP client requests
should be logged to the timeline. If `enabled` is provided, the state of
`HttpClient.enableTimelineLogging` will be updated to the value of `enabled`.

If the value of `HttpClient.enableTimelineLogging` is changed, a
`HttpTimelineLoggingStateChange` event will be sent on the `Extension` stream.

See [HttpTimelineLoggingState](#httptimelineloggingstate).

### getHttpProfile

```
HttpProfile getHttpProfile(string isolateId, int updatedSince [optional])
```

The `getHttpProfile` RPC is used to retrieve HTTP profiling information
for requests made via `dart:io`'s `HttpClient`.

The returned `HttpProfile` will only include requests issued after
`httpTimelineLogging` has been enabled or after the last
`clearHttpProfile` invocation.

If `updatedSince` is provided, only requests started or updated since
the specified time will be reported.

See [HttpProfile](#httpprofile).

### getHttpProfileRequest

```
HttpProfileRequest getHttpProfileRequest(string isolateId, int id)
```

The `getHttpProfileRequest` RPC is used to retrieve an instance of `HttpProfileRequest`,
which includes request and response body data.

See [HttpProfileRequest](#httprofilerequest).

### clearHttpProfile

```
Success clearHttpProfile(string isolateId)
```

The `clearHttpProfile` RPC is used to clear previously recorded HTTP
requests from the HTTP profiler state. Requests still in-flight after
clearing the profiler state will be ignored by the profiler.

See [Success](#success).

## Public Types

### OpenFile

```
class @OpenFile extends Response {
  // The unique ID associated with this file.
  int id;

  // The path of the file.
  string name;
}
```

_@File_ is a reference to a _File_.

```
class OpenFile extends Response {
  // The unique ID associated with this file.
  int id;

  // The path of the file.
  string name;

  // The total number of bytes read from this file.
  int readBytes;

  // The total number of bytes written to this file.
  int writeBytes;

  // The number of reads made from this file.
  int readCount;

  // The number of writes made to this file.
  int writeCount;

  // The time at which this file was last read by this process in milliseconds
  // since epoch.
  int lastReadTime;

  // The time at which this file was last written to by this process in
  // milliseconds since epoch.
  int lastWriteTime;
}
```

A _OpenFile_ contains information about reads and writes to a currently opened file.

### OpenFileList

```
class OpenFileList extends Response {
  // A list of all files opened through dart:io.
  @OpenFile[] files;
}
```

### HttpTimelineLoggingState

```
class HttpTimelineLoggingState extends Response {
  // Whether Http timeline logging is enabled.
  bool enabled;
}
```

See [httpEnableTimelineLogging](#httpenabletimelinelogging).

### HttpProfile

```
class HttpProfile extends Response {
  // The time at which this HTTP profile was built, in microseconds.
  int timestamp;

  // The set of recorded HTTP requests.
  @HttpProfileRequest[] requests;
}
```

A collection of HTTP request data collected by the profiler.

See [getHttpProfile](#gethttpprofile).

### HttpProfileRequest

```
class @HttpProfileRequest extends Response {
  // The ID associated with this request.
  //
  // This ID corresponds to the ID of the timeline event for this request.
  int id;

  // The ID of the isolate this request was issued from.
  string isolateId;

  // The HTTP request method associated with this request.
  string method;

  // The URI for this HTTP request.
  string uri;

  // The time at which this request was initiated, in microseconds.
  final int startTime;

  // The time at which this request was completed, in microseconds.
  int endTime [optional];

  // Information sent as part of the initial HTTP request.
  //
  // Will not be provided if the initial request has not yet completed.
  HttpProfileRequestData request [optional];

  // Information received in response to the initial HTTP request.
  //
  // Will not be provided if the request has not yet been responded to.
  HttpProfileResponseData response [optional];
}
```

```
class HttpProfileRequest extends @HttpProfileRequest {
  // The body sent as part of this request.
  //
  // Data written to a request body before encountering an error will be
  // reported.
  int[] requestBody [optional];

  // The body received in response to the request.
  int[] responseBody [optional];
}
```

Profiling information for a single HTTP request.

See [HttpProfile](#httpprofile).

### HttpProfileRequestData

```
class HttpProfileRequestData {
  // Information about the client connection.
  //
  // This property can be null, regardless of error state.
  map<string, dynamic> connectionInfo [optional];

  // The content length of the request, in bytes.
  int contentLength [optional];

  // Cookies presented to the server (in the 'cookie' header).
  string[] cookies;

  // Events that has occurred while issuing this HTTP request.
  //
  // Events which occurred before encountering an error will be reported.
  HttpProfileRequestEvent[] events;

  // The error associated with the failed request.
  string error [optional];

  // Whether to redirects are followed automatically.
  bool followRedirects [optional];

  // Returns the client request headers.
  map<string, dynamic> headers [optional];

  // The maximum number of redirects to follow when `followRedirects` is true.
  int maxRedirects [optional];

  // The method of the request.
  string method [optional];

  // The requested persistent connection state.
  bool persistentConnection [optional];

  // Proxy authentication details for this request.
  HttpProfileProxyData proxyDetails [optional];
}
```

Information sent as part of the initial HTTP request. If `error` is present,
other properties will be null. If `error` is not present, all other properties
will be provided unless otherwise specified.

See [HttpProfileRequest](#httpprofilerequest).

### HttpProfileResponseData

```
class HttpProfileResponseData {
  // Returns the series of redirects this connection has been through.
  //
  // The list will be empty if no redirects were followed. redirects will be
  // updated both in the case of an automatic and a manual redirect.
  map<string, dynamic>[] redirects;

  // Cookies set by the server (from the 'set-cookie' header).
  string[] cookies;

  // Information about the client connection.
  map<string, dynamic> connectionInfo [optional];

  // Returns the client response headers.
  map<string, dynamic> headers;

  // The compression state of the response.
  //
  // This specifies whether the response bytes were compressed when they were
  // received across the wire and whether callers will receive compressed or
  // uncompressed bytes when they listed to this response's byte stream.
  string compressionState;

  // Returns the reason phrase associated with the status code.
  string reasonPhrase;

  // Returns whether the status code is one of the normal redirect codes.
  bool isRedirect;

  // The persistent connection state returned by the server.
  bool persistentConnection;

  // Returns the content length of the response body.
  //
  // Returns -1 if the size of the response body is not known in advance.
  int contentLength;

  // Returns the status code.
  int statusCode;

  // The time at which the initial response was received, in microseconds.
  int startTime;

  // The time at which the response was completed, in microseconds.
  int endTime [optional];

  // The error associated with the failed request.
  string error [optional];
}
```

Information received in response to an initial HTTP request.

See [HttpProfileRequest](#httpprofilerequest).

### HttpProfileProxyData

```
class HttpProfileProxyData {
  string host [optional];
  string username [optional];
  bool isDirect;
  int port [optional];
}
```

Proxy authentication details associated with a HTTP request.

See [HttpProfileRequestData](#httpprofilerequestdata).

### HttpProfileRequestEvent

```
class HttpProfileRequestEvent {
  // The title of the recorded event.
  string event;

  // The time at which the event occurred, in microseconds.
  int timestamp;

  // Any arguments recorded for the event.
  map<string, dynamic> arguments [optional];
}
```

Describes an event that has occurred while issuing a HTTP request.

See [HttpProfileRequestData](#httpprofilerequestdata).

### SocketProfilingState

```
class SocketProfilingState extends Response {
  // Whether socket profiling is enabled.
  bool enabled;
}
```

See [socketProfilingEnabled](#socketProfilingEnabled).

### SpawnedProcess

```
class @SpawnedProcess {
  // The unique ID associated with this process.
  int id;

  // The name of the executable.
  string name;
}
```

_@SpawnedProcess_ is a reference to a _SpawnedProcess_.

```
class SpawnedProcess extends Response {
  // The unique ID associated with this process.
  int id;

  // The name of the executable.
  string name;

  // The process ID associated with the process.
  int pid;

  // The time the process was started in milliseconds since epoch.
  int startedAt;

  // The list of arguments provided to the process at launch.
  string[] arguments;

  // The working directory of the process at launch.
  string workingDirectory;
}
```

A _Process_ contains startup information of a spawned process.

### SpawnedProcessList

```
class SpawnedProcessList extends Response {
  // A list of processes spawned through dart:io on a given isolate.
  @SpawnedProcess[] processes;
}
```

### Response

```
class Response {
  // Every response returned by the VM Service has the
  // type property. This allows the client distinguish
  // between different kinds of responses.
  string type;
}
```

### SocketProfile

```
class SocketProfile extends Response {
  // List of socket statistics
  SocketStatistic[] sockets;
}
```

A _SocketProfile_ provides information about statistics of sockets.
See [getSocketProfile](#getSocketProfile) and
[SocketStatistic](#SocketStatistic).

### SocketStatistic

```
class SocketStatistic {
  // The unique ID associated with this socket.
  int id;

  // The time, in microseconds, that this socket was created.
  int startTime;

  // The time, in microseconds, that this socket was closed.
  int endTime [optional];

  // The time, in microseconds, that this socket was last read from.
  int lastReadTime [optional];

  // The time, in microseconds, that this socket was last written to.
  int lastWriteTime [optional];

  // The address of socket.
  string address;

  // The port of socket.
  int port;

  // The type of socket. The value is `tcp` or `udp`.
  string socketType;

  // The number of bytes read from this socket.
  int readBytes;

  // The number of bytes written to this socket.
  int writeBytes;
}
```

See [SocketProfile](#SocketProfile) and [getSocketProfile](#getSocketProfile).

### Success

```
class Success extends Response {
}
```

The _Success_ type is used to indicate that an operation completed successfully.

### Version

```
class Version extends Response {
  // The major version number is incremented when the protocol is changed
  // in a potentially incompatible way.
  int major;

  // The minor version number is incremented when the protocol is changed
  // in a backwards compatible way.
  int minor;
}
```

## Revision History
version | comments
------- | --------
1.0 | Initial revision.
1.1 | Added `lastReadTime` and `lastWriteTime` properties to `SocketStatistic`.
1.2 | Added `getOpenFiles`, `getOpenFileById`, `getSpawnedProcesses`, and `getSpawnedProcessById` RPCs and added `OpenFile` and `SpawnedProcess` objects.
1.3 | Added `httpEnableTimelineLogging` RPC and `HttpTimelineLoggingStateChange` event, deprecated `getHttpEnableTimelineLogging` and `setHttpEnableTimelineLogging`.
1.4 | Updated `httpEnableTimelineLogging` parameter `enable` to `enabled`. `enable` will continue to be accepted.
1.5 | Added `socketProfilingEnabled` RPC and `SocketProfilingStateChanged` event, deprecated `startSocketProfiling` and `pauseSocketProfiling`.
1.6 | Added `isSocketProfilingAvailable`, `isHttpTimelineLoggingAvailable`, `isHttpProfilingAvailable`, removed deprecated RPCs `startSocketProfiling`,
`pauseSocketProfiling`, `getHttpEnableTimelineLogging`, and `setHttpEnableTimelineLogging`.
