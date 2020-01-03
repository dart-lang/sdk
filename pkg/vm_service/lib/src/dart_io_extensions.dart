// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(bkonyi): autogenerate from service_extensions.md

import 'dart:async';

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
    addTypeFactory('SocketStatistic', SocketStatistic.parse);
    addTypeFactory('SocketProfile', SocketProfile.parse);
    addTypeFactory('HttpTimelineLoggingState', HttpTimelineLoggingState.parse);
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
