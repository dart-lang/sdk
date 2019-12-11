# Dart VM Service Protocol Extension

This protocol describes service extensions that are made available through
the Dart core libraries, but are not part of the core
[Dart VM Service Protocol](service.md). Service extension methods are
invoked by prepending the service extension name (e.g.,
"ext.dart.libraryName") to the RPC to be invoked. For example, the
`getSocketProfile` RPC exposed through dart:io can be executed by invoking
`ext.dart.io.getSocketProfile`.

## dart:io Extensions

This section describes _version 1.0_ of the dart:io service protocol extensions.

### getVersion

```
Version getVersion()
```

The _getVersion_ RPC returns the available version of the dart:io service protocol extensions.

See [Version](#version).

### startSocketProfiling

```
Success startSocketProfiling()
```

Start profiling new socket connections. Statistics for sockets created before profiling was enabled will not be recorded.

See [Success](#success).

### pauseSocketProfiling

```
Success pauseSocketProfiling()
```

Pause recording socket statistics. [clearSocketProfile](#clearsocketprofile) must be called in order for collected statistics to be cleared.

See [Success](#success).

### clearSocketProfile

```
Success clearSocketProfile()
```

Removes all statistics associated with prior and current sockets.

See [Success](#success).

### getSocketProfile

```
SocketProfile getSocketProfile()
```

The _getSocketProfile_ RPC is used to retrieve socket statistics collected by
the socket profiler. Only samples collected after the initial [startSocketProfiling](#startsocketprofiling) or the last call to [clearSocketProfile](#clearsocketprofile) will be reported.

## Public Types

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

  // The address of socket.
  String address;

  // The port of socket.
  int port;

  // The type of socket. The value is `tcp` or `udp`.
  String socketType;

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