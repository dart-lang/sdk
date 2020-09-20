// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(bkonyi): autogenerate from service_extensions.md

import 'dart:collection';

import 'package:meta/meta.dart';

import 'vm_service.dart';

extension DartIOExtension on VmService {
  static bool _factoriesRegistered = false;

  /// The `getDartIOVersion` RPC returns the available version of the dart:io
  /// service protocol extensions.
  Future<Version> getDartIOVersion(String isolateId) =>
      _callHelper('ext.dart.io.getVersion', isolateId);

  /// Start profiling new socket connections. Statistics for sockets created
  /// before profiling was enabled will not be recorded.
  Future<Success> startSocketProfiling(String isolateId) =>
      _callHelper('ext.dart.io.startSocketProfiling', isolateId);

  /// Pause recording socket statistics. [clearSocketProfile] must be called in
  /// order for collected statistics to be cleared.
  Future<Success> pauseSocketProfiling(String isolateId) =>
      _callHelper('ext.dart.io.pauseSocketProfiling', isolateId);

  /// Removes all statistics associated with prior and current sockets.
  Future<Success> clearSocketProfile(String isolateId) =>
      _callHelper('ext.dart.io.clearSocketProfile', isolateId);

  /// The `getSocketProfile` RPC is used to retrieve socket statistics collected
  /// by the socket profiler. Only samples collected after the initial
  /// [startSocketProfiling] or the last call to [clearSocketProfiling] will be
  /// reported.
  Future<SocketProfile> getSocketProfile(String isolateId) =>
      _callHelper('ext.dart.io.getSocketProfile', isolateId);

  /// Gets the current state of HTTP logging for a given isolate.
  ///
  /// Warning: The returned [Future] will not complete if the target isolate is paused
  /// and will only complete when the isolate is resumed.
  Future<HttpTimelineLoggingState> getHttpEnableTimelineLogging(
          String isolateId) =>
      _callHelper('ext.dart.io.getHttpEnableTimelineLogging', isolateId);

  /// Enables or disables HTTP logging for a given isolate.
  ///
  /// Warning: The returned [Future] will not complete if the target isolate is paused
  /// and will only complete when the isolate is resumed.
  Future<Success> setHttpEnableTimelineLogging(String isolateId, bool enable) =>
      _callHelper('ext.dart.io.setHttpEnableTimelineLogging', isolateId, args: {
        'enable': enable,
      });

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

/// A [HttpTimelineLoggingState] provides information about the current state of HTTP
/// request logging for a given isolate.
class HttpTimelineLoggingState extends Response {
  static HttpTimelineLoggingState parse(Map json) =>
      json == null ? null : HttpTimelineLoggingState._fromJson(json);

  HttpTimelineLoggingState({@required this.enabled});

  // TODO(bkonyi): make this part of the vm_service.dart library so we can
  // call super._fromJson.
  HttpTimelineLoggingState._fromJson(Map<String, dynamic> json)
      : enabled = json['enabled'] {
    type = json['type'];
  }

  /// Whether or not HttpClient.enableTimelineLogging is set to true for a given isolate.
  final bool enabled;
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
