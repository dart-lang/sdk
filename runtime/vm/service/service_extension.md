# Dart VM Service Protocol Extension 1.5

This protocol describes service extensions that are made available through
the Dart core libraries, but are not part of the core
[Dart VM Service Protocol](service.md). Service extension methods are
invoked by prepending the service extension name (e.g.,
"ext.dart.libraryName") to the RPC to be invoked. For example, the
`getSocketProfile` RPC exposed through dart:io can be executed by invoking
`ext.dart.io.getSocketProfile`.

## dart:io Extensions

This section describes _version 1.5_ of the dart:io service protocol extensions.

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

### startSocketProfiling

```
@Deprecated
Success startSocketProfiling(string isolateId)
```

Start profiling new socket connections. Statistics for sockets created before profiling was enabled will not be recorded.

See [Success](#success).

### pauseSocketProfiling

```
@Deprecated
Success pauseSocketProfiling(string isolateId)
```

Pause recording socket statistics. [clearSocketProfile](#clearsocketprofile) must be called in order for collected statistics to be cleared.

See [Success](#success).

### clearSocketProfile

```
Success clearSocketProfile(string isolateId)
```

Removes all statistics associated with prior and current sockets.

See [Success](#success).

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

### getSocketProfile

```
SocketProfile getSocketProfile(string isolateId)
```

The _getSocketProfile_ RPC is used to retrieve socket statistics collected by
the socket profiler. Only samples collected after the initial [startSocketProfiling](#startsocketprofiling) or the last call to [clearSocketProfile](#clearsocketprofile) will be reported.

### getHttpEnableTimelineLogging

```
@Deprecated
HttpTimelineLoggingState getHttpEnableTimelineLogging(string isolateId)
```

The _getHttpEnableTimelineLogging_ RPC is used to remotely inspect the value of
`HttpClient.enableTimelineLogging`, which determines if HTTP client requests
should be logged to the timeline.

See [HttpTimelineLoggingState](#httptimelineloggingstate).

### setHttpEnableTimelineLogging

```
@Deprecated
Success setHttpEnableTimelineLogging(string isolateId, bool enable)
```

The _setHttpEnableTimelineLogging_ RPC is used to remotely set the value of
`HttpClient.enableTimelineLogging`, which determines if HTTP client requests
should be logged to the timeline. Note: this will only change the state of HTTP
timeline logging for the isolate specified by `isolateId`.

See [Success](#success).

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

## Public Types

### File

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

### HttpTimelineLoggingState

```
class HttpTimelineLoggingState extends Response {
  // Whether Http timeline logging is enabled.
  bool enabled;
}
```

See [httpEnableTimelineLogging](#httpenabletimelinelogging).

### OpenFileList

```
class OpenFileList extends Response {
  // A list of all files opened through dart:io.
  @OpenFile[] files;
}
```

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
