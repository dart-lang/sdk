// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(bkonyi): autogenerate from service_extensions.md

import 'dart:collection';

import 'package:meta/meta.dart';
import 'package:vm_service/vm_service.dart';

import 'vm_service.dart';

extension DartIOExtension on VmService {
  static bool _factoriesRegistered = false;
  static Map<String, Version> _isolateVersion = {};

  Future<Version> _version(String isolateId) async {
    if (_isolateVersion[isolateId] == null) {
      _isolateVersion[isolateId] = await getDartIOVersion(isolateId);
    }
    return _isolateVersion[isolateId];
  }

  /// The `getDartIOVersion` RPC returns the available version of the dart:io
  /// service protocol extensions.
  Future<Version> getDartIOVersion(String isolateId) =>
      _callHelper('ext.dart.io.getVersion', isolateId);

  /// Start profiling new socket connections. Statistics for sockets created
  /// before profiling was enabled will not be recorded.
  @Deprecated('Use socketProfilingEnabled instead')
  Future<Success> startSocketProfiling(String isolateId) =>
      _callHelper('ext.dart.io.startSocketProfiling', isolateId);

  /// Pause recording socket statistics. [clearSocketProfile] must be called in
  /// order for collected statistics to be cleared.
  @Deprecated('Use socketProfilingEnabled instead')
  Future<Success> pauseSocketProfiling(String isolateId) =>
      _callHelper('ext.dart.io.pauseSocketProfiling', isolateId);

  /// The _socketProfilingEnabled_ RPC is used to enable/disable the socket profiler
  /// and query its current state. If `enabled` is provided, the profiler state will
  /// be updated to reflect the value of `enabled`.
  ///
  /// If the state of the socket profiler is changed, a `SocketProfilingStateChange`
  /// event will be sent on the `Extension` stream.
  Future<SocketProfilingState> socketProfilingEnabled(String isolateId,
      [bool enabled]) async {
    return _callHelper('ext.dart.io.socketProfilingEnabled', isolateId, args: {
      if (enabled != null) 'enabled': enabled,
    });
  }

  /// Removes all statistics associated with prior and current sockets.
  Future<Success> clearSocketProfile(String isolateId) =>
      _callHelper('ext.dart.io.clearSocketProfile', isolateId);

  /// The `getSocketProfile` RPC is used to retrieve socket statistics collected
  /// by the socket profiler. Only samples collected after the initial
  /// [socketProfilingEnabled] call or the last call to [clearSocketProfile]
  /// will be reported.
  Future<SocketProfile> getSocketProfile(String isolateId) =>
      _callHelper('ext.dart.io.getSocketProfile', isolateId);

  /// Gets the current state of HTTP logging for a given isolate.
  ///
  /// Warning: The returned [Future] will not complete if the target isolate is paused
  /// and will only complete when the isolate is resumed.
  @Deprecated('Use httpEnableTimelineLogging instead.')
  Future<HttpTimelineLoggingState> getHttpEnableTimelineLogging(
          String isolateId) =>
      _callHelper('ext.dart.io.getHttpEnableTimelineLogging', isolateId);

  /// Enables or disables HTTP logging for a given isolate.
  ///
  /// Warning: The returned [Future] will not complete if the target isolate is paused
  /// and will only complete when the isolate is resumed.
  @Deprecated('Use httpEnableTimelineLogging instead.')
  Future<Success> setHttpEnableTimelineLogging(String isolateId, bool enable) =>
      _callHelper('ext.dart.io.setHttpEnableTimelineLogging', isolateId, args: {
        'enable': enable,
      });

  /// The _httpEnableTimelineLogging_ RPC is used to set and inspect the value of
  /// `HttpClient.enableTimelineLogging`, which determines if HTTP client requests
  /// should be logged to the timeline. If `enabled` is provided, the state of
  /// `HttpClient.enableTimelineLogging` will be updated to the value of `enabled`.
  ///
  /// If the value of `HttpClient.enableTimelineLogging` is changed, a
  /// `HttpTimelineLoggingStateChange` event will be sent on the `Extension` stream.
  Future<HttpTimelineLoggingState> httpEnableTimelineLogging(String isolateId,
      [bool enabled]) async {
    final version = await _version(isolateId);
    // Parameter name changed in version 1.4.
    final enableKey =
        ((version.major == 1 && version.minor > 3) || version.major >= 2)
            ? 'enabled'
            : 'enable';
    return _callHelper('ext.dart.io.httpEnableTimelineLogging', isolateId,
        args: {
          if (enabled != null) enableKey: enabled,
        });
  }

  /// The `getOpenFiles` RPC is used to retrieve the list of files currently
  /// opened files by `dart:io` from a given isolate.
  Future<OpenFileList> getOpenFiles(String isolateId) => _callHelper(
        'ext.dart.io.getOpenFiles',
        isolateId,
      );

  /// The `getOpenFileById` RPC is used to retrieve information about files
  /// currently opened by `dart:io` from a given isolate.
  Future<OpenFile> getOpenFileById(String isolateId, int id) => _callHelper(
        'ext.dart.io.getOpenFileById',
        isolateId,
        args: {
          'id': id,
        },
      );

  /// The `getSpawnedProcesses` RPC is used to retrieve the list of processed opened
  /// by `dart:io` from a given isolate
  Future<SpawnedProcessList> getSpawnedProcesses(String isolateId) =>
      _callHelper(
        'ext.dart.io.getSpawnedProcesses',
        isolateId,
      );

  /// The `getSpawnedProcessById` RPC is used to retrieve information about a process
  /// spawned by `dart:io` from a given isolate.
  Future<SpawnedProcess> getSpawnedProcessById(String isolateId, int id) =>
      _callHelper(
        'ext.dart.io.getSpawnedProcessById',
        isolateId,
        args: {
          'id': id,
        },
      );

  Future<T> _callHelper<T>(String method, String isolateId,
      {Map args = const {}}) {
    if (!_factoriesRegistered) {
      _registerFactories();
    }
    return extensionCallHelper(
      this,
      method,
      {
        if (isolateId != null) 'isolateId': isolateId,
        ...args,
      },
    );
  }

  static void _registerFactories() {
    addTypeFactory('OpenFile', OpenFile.parse);
    addTypeFactory('OpenFileList', OpenFileList.parse);
    addTypeFactory('@OpenFile', OpenFileRef.parse);
    addTypeFactory('HttpTimelineLoggingState', HttpTimelineLoggingState.parse);
    addTypeFactory('SpawnedProcess', SpawnedProcess.parse);
    addTypeFactory('SpawnedProcessList', SpawnedProcessList.parse);
    addTypeFactory('@SpawnedProcess', SpawnedProcessRef.parse);
    addTypeFactory('SocketProfile', SocketProfile.parse);
    addTypeFactory('SocketStatistic', SocketStatistic.parse);
    addTypeFactory('SocketProfilingState', SocketProfilingState.parse);
    _factoriesRegistered = true;
  }
}

class SocketStatistic {
  static SocketStatistic parse(Map json) =>
      json == null ? null : SocketStatistic._fromJson(json);

  /// The unique ID associated with this socket.
  final int id;

  /// The time, in microseconds, that this socket was created.
  final int startTime;

  /// The time, in microseconds, that this socket was closed.
  @optional
  final int endTime;

  /// The time, in microseconds, that this socket was last read from.
  final int lastReadTime;

  /// The time, in microseconds, that this socket was last written to.
  final int lastWriteTime;

  /// The address of the socket.
  final String address;

  /// The port of the socket.
  final int port;

  /// The type of socket. The value is either `tcp` or `udp`.
  final String socketType;

  /// The number of bytes read from this socket.
  final int readBytes;

  /// The number of bytes written to this socket.
  final int writeBytes;

  SocketStatistic._fromJson(Map<String, dynamic> json)
      : id = json['id'],
        startTime = json['startTime'],
        endTime = json['endTime'],
        lastReadTime = json['lastReadTime'],
        lastWriteTime = json['lastWriteTime'],
        address = json['address'],
        port = json['port'],
        socketType = json['socketType'],
        readBytes = json['readBytes'],
        writeBytes = json['writeBytes'];
}

/// A [SocketProfile] provides information about statistics of sockets.
class SocketProfile extends Response {
  static SocketProfile parse(Map json) =>
      json == null ? null : SocketProfile._fromJson(json);

  /// List of socket statistics.
  List<SocketStatistic> sockets;

  SocketProfile({@required this.sockets});

  SocketProfile._fromJson(Map<String, dynamic> json) {
    // TODO(bkonyi): make this part of the vm_service.dart library so we can
    // call super._fromJson.
    type = json['type'];
    sockets = List<SocketStatistic>.from(
        createServiceObject(json['sockets'], const ['SocketStatistic']) ?? []);
  }
}

/// A [Response] containing the enabled state of a service extension.
abstract class _State extends Response {
  _State({@required this.enabled});

  // TODO(bkonyi): make this part of the vm_service.dart library so we can
  // call super._fromJson.
  _State._fromJson(Map<String, dynamic> json) : enabled = json['enabled'] {
    type = json['type'];
  }

  final bool enabled;
}

/// A [HttpTimelineLoggingState] provides information about the current state of HTTP
/// request logging for a given isolate.
class HttpTimelineLoggingState extends _State {
  static HttpTimelineLoggingState parse(Map json) =>
      json == null ? null : HttpTimelineLoggingState._fromJson(json);

  HttpTimelineLoggingState({@required bool enabled}) : super(enabled: enabled);

  HttpTimelineLoggingState._fromJson(Map<String, dynamic> json)
      : super._fromJson(json);
}

/// A [SocketProfilingState] provides information about the current state of
/// socket profiling for a given isolate.
class SocketProfilingState extends _State {
  static SocketProfilingState parse(Map json) =>
      json == null ? null : SocketProfilingState._fromJson(json);

  SocketProfilingState({@required bool enabled}) : super(enabled: enabled);

  SocketProfilingState._fromJson(Map<String, dynamic> json)
      : super._fromJson(json);
}

/// A [SpawnedProcessRef] contains identifying information about a spawned process.
class SpawnedProcessRef {
  static SpawnedProcessRef parse(Map json) =>
      json == null ? null : SpawnedProcessRef._fromJson(json);

  SpawnedProcessRef({
    @required this.id,
    @required this.name,
  });

  SpawnedProcessRef._fromJson(Map<String, dynamic> json)
      :
        // TODO(bkonyi): make this part of the vm_service.dart library so we can
        // call super._fromJson.
        id = json['id'],
        name = json['name'];

  static const String type = 'SpawnedProcessRef';

  /// The unique ID associated with this process.
  final int id;

  /// The name of the executable.
  final String name;
}

/// A [SpawnedProcess] contains startup information of a spawned process.
class SpawnedProcess extends Response implements SpawnedProcessRef {
  static SpawnedProcess parse(Map json) =>
      json == null ? null : SpawnedProcess._fromJson(json);

  SpawnedProcess({
    @required this.id,
    @required this.name,
    @required this.pid,
    @required this.startedAt,
    @required List<String> arguments,
    @required this.workingDirectory,
  }) : _arguments = arguments;

  SpawnedProcess._fromJson(Map<String, dynamic> json)
      :
        // TODO(bkonyi): make this part of the vm_service.dart library so we can
        // call super._fromJson.
        id = json['id'],
        name = json['name'],
        pid = json['pid'],
        startedAt = json['startedAt'],
        _arguments = List<String>.from(
            createServiceObject(json['arguments'], const ['String']) as List ??
                []),
        workingDirectory = json['workingDirectory'] {
    type = json['type'];
  }

  /// The unique ID associated with this process.
  final int id;

  /// The name of the executable.
  final String name;

  /// The process ID associated with the process.
  final int pid;

  /// The time the process was started in milliseconds since epoch.
  final int startedAt;

  /// The list of arguments provided to the process at launch.
  List<String> get arguments => UnmodifiableListView(_arguments);
  final List<String> _arguments;

  /// The working directory of the process at launch.
  final String workingDirectory;
}

class SpawnedProcessList extends Response {
  static SpawnedProcessList parse(Map json) =>
      json == null ? null : SpawnedProcessList._fromJson(json);

  SpawnedProcessList({@required List<SpawnedProcessRef> processes})
      : _processes = processes;

  SpawnedProcessList._fromJson(Map<String, dynamic> json)
      :
        // TODO(bkonyi): make this part of the vm_service.dart library so we can
        // call super._fromJson.
        _processes = List<SpawnedProcessRef>.from(
            createServiceObject(json['processes'], const ['SpawnedProcessRef'])
                    as List ??
                []) {
    type = json['type'];
  }

  /// A list of processes spawned through dart:io on a given isolate.
  List<SpawnedProcessRef> get processes => UnmodifiableListView(_processes);
  final List<SpawnedProcessRef> _processes;
}

/// A [OpenFileRef] contains identifying information about a currently opened file.
class OpenFileRef {
  static OpenFileRef parse(Map json) =>
      json == null ? null : OpenFileRef._fromJson(json);

  OpenFileRef({
    @required this.id,
    @required this.name,
  });

  OpenFileRef._fromJson(Map<String, dynamic> json)
      :
        // TODO(bkonyi): make this part of the vm_service.dart library so we can
        // call super._fromJson.
        id = json['id'],
        name = json['name'];

  static const String type = 'OpenFileRef';

  /// The unique ID associated with this file.
  final int id;

  /// The path of the file.
  final String name;
}

/// A [File] contains information about reads and writes to a currently opened file.
class OpenFile extends Response implements OpenFileRef {
  static OpenFile parse(Map json) =>
      json == null ? null : OpenFile._fromJson(json);

  OpenFile({
    @required this.id,
    @required this.name,
    @required this.readBytes,
    @required this.writeBytes,
    @required this.readCount,
    @required this.writeCount,
    @required this.lastReadTime,
    @required this.lastWriteTime,
  });

  OpenFile._fromJson(Map<String, dynamic> json)
      :
        // TODO(bkonyi): make this part of the vm_service.dart library so we can
        // call super._fromJson.
        id = json['id'],
        name = json['name'],
        readBytes = json['readBytes'],
        writeBytes = json['writeBytes'],
        readCount = json['readCount'],
        writeCount = json['writeCount'],
        lastReadTime =
            DateTime.fromMillisecondsSinceEpoch(json['lastReadTime']),
        lastWriteTime =
            DateTime.fromMillisecondsSinceEpoch(json['lastWriteTime']) {
    type = json['type'];
  }

  /// The unique ID associated with this file.
  final int id;

  /// The path of the file.
  final String name;

  /// The total number of bytes read from this file.
  final int readBytes;

  /// The total number of bytes written to this file.
  final int writeBytes;

  /// The number of reads made from this file.
  final int readCount;

  /// The number of writes made to this file.
  final int writeCount;

  /// The time at which this file was last read by this process.
  final DateTime lastReadTime;

  /// The time at which this file was last written to by this process.
  final DateTime lastWriteTime;
}

class OpenFileList extends Response {
  static OpenFileList parse(Map json) =>
      json == null ? null : OpenFileList._fromJson(json);

  OpenFileList({@required List<OpenFileRef> files}) : _files = files;

  OpenFileList._fromJson(Map<String, dynamic> json)
      :
        // TODO(bkonyi): make this part of the vm_service.dart library so we can
        // call super._fromJson.
        _files = List<OpenFileRef>.from(
            createServiceObject(json['files'], const ['OpenFileRef']) as List ??
                []) {
    type = json['type'];
  }

  /// A list of all files opened through dart:io on a given isolate.
  List<OpenFileRef> get files => UnmodifiableListView(_files);
  final List<OpenFileRef> _files;
}
