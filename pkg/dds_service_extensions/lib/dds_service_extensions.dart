// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:async/async.dart';
// ignore: implementation_imports
import 'package:vm_service/src/vm_service.dart';

extension DdsExtension on VmService {
  static bool _factoriesRegistered = false;
  static Version? _ddsVersion;

  /// The [getDartDevelopmentServiceVersion] RPC is used to determine what version of
  /// the Dart Development Service Protocol is served by a DDS instance.
  ///
  /// The result of this call is cached for subsequent invocations.
  Future<Version> getDartDevelopmentServiceVersion() async {
    _ddsVersion ??= await _callHelper<Version>(
      'getDartDevelopmentServiceVersion',
    );
    return _ddsVersion!;
  }

  /// The [getCachedCpuSamples] RPC is used to retrieve a cache of CPU samples
  /// collected under a [UserTag] with name `userTag`.
  Future<CachedCpuSamples> getCachedCpuSamples(
      String isolateId, String userTag) async {
    if (!(await _versionCheck(1, 3))) {
      throw UnimplementedError('getCachedCpuSamples requires DDS version 1.3');
    }
    return _callHelper<CachedCpuSamples>('getCachedCpuSamples', args: {
      'isolateId': isolateId,
      'userTag': userTag,
    });
  }

  /// The [getPerfettoVMTimelineWithCpuSamples] RPC functions nearly identically
  /// to [VmService.getPerfettoVMTimeline], except the `trace` field of the
  /// [PerfettoTimeline] response returned by this RPC will be a Base64 string
  /// encoding a Perfetto-format trace that includes not only all timeline
  /// events in the specified time range, but also all CPU samples from all
  /// isolates in the specified time range.
  Future<PerfettoTimeline> getPerfettoVMTimelineWithCpuSamples(
      {int? timeOriginMicros, int? timeExtentMicros}) async {
    if (!(await _versionCheck(1, 5))) {
      throw UnimplementedError(
          'getPerfettoVMTimelineWithCpuSamples requires DDS version 1.5');
    }
    return _callHelper<PerfettoTimeline>('getPerfettoVMTimelineWithCpuSamples',
        args: {
          'timeOriginMicros': timeOriginMicros,
          'timeExtentMicros': timeExtentMicros,
        });
  }

  /// Send an event to the [stream].
  ///
  /// [stream] must be a registered custom stream (i.e., not a stream specified
  /// as part of the VM service protocol).
  ///
  /// If [stream] is not a registered custom stream, an [RPCError] with code
  /// [kCustomStreamDoesNotExist] will be thrown.
  ///
  /// If [stream] is a core stream, an [RPCError] with code
  /// [kCoreStreamNotAllowed] will be thrown.
  Future<void> postEvent(
    String stream,
    String eventKind,
    Map<String, Object?> eventData,
  ) async {
    if (!(await _versionCheck(1, 6))) {
      throw UnimplementedError('postEvent requires DDS version 1.6');
    }
    return _callHelper<void>('postEvent', args: {
      'eventKind': eventKind,
      'eventData': eventData,
      'stream': stream,
    });
  }

  /// The [getAvailableCachedCpuSamples] RPC is used to determine which caches of CPU samples
  /// are available. Caches are associated with individual [UserTag] names and are specified
  /// when DDS is started via the `cachedUserTags` parameter.
  Future<AvailableCachedCpuSamples> getAvailableCachedCpuSamples() async {
    if (!(await _versionCheck(1, 3))) {
      throw UnimplementedError(
        'getAvailableCachedCpuSamples requires DDS version 1.3',
      );
    }
    return _callHelper<AvailableCachedCpuSamples>(
      'getAvailableCachedCpuSamples',
    );
  }

  /// The [getLogHistorySize] RPC is used to retrieve the current size of the
  /// log history buffer.
  ///
  /// If the returned [Size] is zero, then log history is disabled.
  Future<Size> getLogHistorySize(String isolateId) async {
    // No version check needed, present since v1.0 of the protocol.
    return _callHelper<Size>('getLogHistorySize', args: {
      'isolateId': isolateId,
    });
  }

  /// The [setLogHistorySize] RPC is used to set the size of the ring buffer
  /// used for caching a limited set of historical log messages.
  ///
  /// If [size] is 0, logging history will be disabled.
  ///
  /// The maximum history size is 100,000 messages, with the default set to
  /// 10,000 messages.
  Future<Success> setLogHistorySize(String isolateId, int size) async {
    // No version check needed, present since v1.0 of the protocol.
    return _callHelper<Success>('setLogHistorySize', args: {
      'isolateId': isolateId,
      'size': size,
    });
  }

  /// Retrieve the event history for `stream`.
  ///
  /// If `stream` does not have event history collected, a parameter error is
  /// returned.
  Future<StreamHistory> getStreamHistory(String stream) async {
    if (!(await _versionCheck(1, 2))) {
      throw UnimplementedError('getStreamHistory requires DDS version 1.2');
    }
    return _callHelper<StreamHistory>('getStreamHistory', args: {
      'stream': stream,
    });
  }

  /// Returns the stream for a given stream id which includes historical
  /// events.
  ///
  /// If `stream` does not have event history collected, a parameter error is
  /// sent over the returned [Stream].
  Stream<Event> onEventWithHistory(String stream) {
    late StreamController<Event> controller;
    late StreamQueue<Event> streamEvents;

    controller = StreamController<Event>(onListen: () async {
      streamEvents = StreamQueue<Event>(onEvent(stream));
      final history = (await getStreamHistory(stream)).history;
      Event? firstStreamEvent;
      unawaited(streamEvents.peek.then((e) {
        firstStreamEvent = e;
      }));
      for (final event in history) {
        if (firstStreamEvent != null &&
            event.timestamp! > firstStreamEvent!.timestamp!) {
          break;
        }
        controller.sink.add(event);
      }
      unawaited(controller.sink.addStream(streamEvents.rest));
    }, onCancel: () {
      try {
        streamEvents.cancel();
      } on StateError {
        // Underlying stream may have already been cancelled.
      }
    });

    return controller.stream;
  }

  /// Returns a new [Stream<Event>] of `Logging` events which outputs
  /// historical events before streaming real-time events.
  ///
  /// Note: unlike [onLoggingEvent], the returned stream is a single
  /// subscription stream and a new stream is created for each invocation of
  /// this getter.
  Stream<Event> get onLoggingEventWithHistory => onEventWithHistory('Logging');

  /// Returns a new [Stream<Event>] of `Stdout` events which outputs
  /// historical events before streaming real-time events.
  ///
  /// Note: unlike [onStdoutEvent], the returned stream is a single
  /// subscription stream and a new stream is created for each invocation of
  /// this getter.
  Stream<Event> get onStdoutEventWithHistory => onEventWithHistory('Stdout');

  /// Returns a new [Stream<Event>] of `Stderr` events which outputs
  /// historical events before streaming real-time events.
  ///
  /// Note: unlike [onStderrEvent], the returned stream is a single
  /// subscription stream and a new stream is created for each invocation of
  /// this getter.
  Stream<Event> get onStderrEventWithHistory => onEventWithHistory('Stderr');

  /// Returns a new [Stream<Event>] of `Extension` events which outputs
  /// historical events before streaming real-time events.
  ///
  /// Note: unlike [onExtensionEvent], the returned stream is a single
  /// subscription stream and a new stream is created for each invocation of
  /// this getter.
  Stream<Event> get onExtensionEventWithHistory =>
      onEventWithHistory('Extension');

  /// The [getClientName] RPC is used to retrieve the name associated with the
  /// currently connected VM service client.
  ///
  /// If no name was previously set through the [setClientName] RPC, a default
  /// name will be returned.
  Future<ClientName> getClientName() async {
    // No version check needed, present since v1.0 of the protocol.
    return _callHelper<ClientName>(
      'getClientName',
    );
  }

  /// The [setClientName] RPC is used to set a name to be associated with the
  /// currently connected VM service client.
  ///
  /// If the [name] parameter is a non-empty string, [name] will become the new
  /// name associated with the client. If [name] is an empty string, the
  /// client's name will be reset to its default name.
  Future<Success> setClientName([String name = '']) async {
    // No version check needed, present since v1.0 of the protocol.
    return _callHelper<Success>(
      'setClientName',
      args: {
        'name': name,
      },
    );
  }

  /// The [requirePermissionToResume] RPC is used to change the pause/resume
  /// behavior of isolates.
  ///
  /// This provides a way for the VM service to wait for approval to resume
  /// from some set of clients. This is useful for clients which want to
  /// perform some operation on an isolate after a pause without it being
  /// resumed by another client. These clients should invoke [readyToResume]
  /// instead of [VmService.resume] to indicate to DDS that they have finished
  /// their work and the isolate can be resumed.
  ///
  /// If the [onPauseStart] parameter is `true`, isolates will not resume after
  /// pausing on start until the client sends a `resume` request and all other
  /// clients which need to provide resume approval for this pause type have
  /// done so.
  ///
  /// If the [onPauseReload] parameter is `true`, isolates will not resume
  /// after pausing after a reload until the client sends a `resume` request
  /// and all other clients which need to provide resume approval for this
  /// pause type have done so.
  ///
  /// If the [onPauseExit] parameter is `true`, isolates will not resume after
  /// pausing on exit until the client sends a `resume` request and all other
  /// clients which need to provide resume approval for this pause type have
  /// done so.
  ///
  /// **Important Notes:**
  ///
  /// - All clients with the same client name share resume permissions. Only a
  ///   single client of a given name is required to provide resume approval.
  /// - When a client requiring approval disconnects from the service, a paused
  ///   isolate may resume if all other clients requiring resume approval have
  ///   already given approval. In the case that no other client requires
  ///   resume approval for the current pause event, the isolate will be
  ///   resumed if at least one other client has attempted to resume the
  ///   isolate.
  /// - Resume permission behavior can be bypassed using the [VmService.resume]
  ///   RPC, which is treated as a user-initiated resume that force resumes
  ///   the isolate. Tooling relying on resume permissions should use
  ///   [readyToResume] instead of [VmService.resume] to avoid force resuming
  ///   the isolate.
  Future<Success> requirePermissionToResume({
    bool onPauseStart = false,
    bool onPauseReload = false,
    bool onPauseExit = false,
  }) async {
    // No version check needed, present since v1.0 of the protocol.
    return _callHelper<Success>(
      'requirePermissionToResume',
      args: {
        'onPauseStart': onPauseStart,
        'onPauseReload': onPauseReload,
        'onPauseExit': onPauseExit,
      },
    );
  }

  /// The [readyToResume] RPC indicates to DDS that the current client is ready
  /// to resume the isolate.
  ///
  /// If the current client requires that approval be given before resuming an
  /// isolate, this method will:
  ///
  ///   - Update the approval state for the isolate.
  ///   - Resume the isolate if approval has been given by all clients which
  ///     require approval.
  ///
  /// Throws a [SentinelException] if the isolate no longer exists.
  Future<Success> readyToResume(String isolateId) async {
    if (!(await _versionCheck(2, 0))) {
      throw UnimplementedError('readyToResume requires DDS version 2.0');
    }
    return _callHelper<Success>(
      'readyToResume',
      isolateId: isolateId,
    );
  }

  /// The [requireUserPermissionToResume] RPC notifies DDS if it should wait
  /// for a [VmService.resume] request to resume isolates paused on start or
  /// exit.
  ///
  /// This RPC should only be invoked by tooling which launched the target Dart
  /// process and knows if the user indicated they wanted isolates paused on
  /// start or exit.
  Future<Success> requireUserPermissionToResume({
    bool onPauseStart = false,
    bool onPauseExit = false,
  }) async {
    if (!(await _versionCheck(2, 0))) {
      throw UnimplementedError(
        'requireUserPermissionToResume requires DDS version 2.0',
      );
    }
    return _callHelper<Success>(
      'requireUserPermissionToResume',
      args: {
        'onPauseStart': onPauseStart,
        'onPauseExit': onPauseExit,
      },
    );
  }

  Future<bool> _versionCheck(int major, int minor) async {
    _ddsVersion ??= await getDartDevelopmentServiceVersion();
    return ((_ddsVersion!.major == major && _ddsVersion!.minor! >= minor) ||
        (_ddsVersion!.major! > major));
  }

  Future<T> _callHelper<T>(String method,
      {String? isolateId, Map args = const {}}) {
    if (!_factoriesRegistered) {
      _registerFactories();
    }
    return callMethod(
      method,
      args: {
        if (isolateId != null) 'isolateId': isolateId,
        ...args,
      },
    ).then((e) => e as T);
  }

  static void _registerFactories() {
    addTypeFactory('StreamHistory', StreamHistory.parse);
    addTypeFactory(
      'AvailableCachedCpuSamples',
      AvailableCachedCpuSamples.parse,
    );
    addTypeFactory('CachedCpuSamples', CachedCpuSamples.parse);
    addTypeFactory('Size', Size.parse);
    addTypeFactory('ClientName', ClientName.parse);
    addTypeFactory(
      'ResumePermissionsRequired',
      ResumePermissionsRequired.parse,
    );
    _factoriesRegistered = true;
  }
}

/// A simple object representing the name of a DDS client.
///
/// See [DdsExtension.getClientName] and [DdsExtension.setClientName].
class ClientName extends Response {
  static ClientName? parse(Map<String, dynamic>? json) =>
      json == null ? null : ClientName._fromJson(json);

  ClientName({required this.name});

  ClientName._fromJson(Map<String, dynamic> json) : name = json['name'];

  final String name;
}

/// A simple object representing a size response.
class Size extends Response {
  static Size? parse(Map<String, dynamic>? json) =>
      json == null ? null : Size._fromJson(json);

  Size({required this.size});

  Size._fromJson(Map<String, dynamic> json) : size = json['size'];

  final int size;
}

/// A collection of historical [Event]s from some stream.
class StreamHistory extends Response {
  static StreamHistory? parse(Map<String, dynamic>? json) =>
      json == null ? null : StreamHistory._fromJson(json);

  StreamHistory({required List<Event> history}) : _history = history;

  StreamHistory._fromJson(Map<String, dynamic> json)
      : _history = json['history']
            .map(
              (e) => Event.parse(e),
            )
            .toList()
            .cast<Event>() {
    this.json = json;
  }

  @override
  String get type => 'StreamHistory';

  /// Historical [Event]s for a stream.
  List<Event> get history => UnmodifiableListView(_history);
  final List<Event> _history;
}

/// An extension of [CpuSamples] which represents a set of cached samples,
/// associated with a particular [UserTag] name.
class CachedCpuSamples extends CpuSamples {
  static CachedCpuSamples? parse(Map<String, dynamic>? json) =>
      json == null ? null : CachedCpuSamples._fromJson(json);

  CachedCpuSamples({
    required this.userTag,
    this.truncated,
    required int? samplePeriod,
    required int? maxStackDepth,
    required int? sampleCount,
    required int? timeOriginMicros,
    required int? timeExtentMicros,
    required int? pid,
    required List<ProfileFunction>? functions,
    required List<CpuSample>? samples,
  }) : super(
          samplePeriod: samplePeriod,
          maxStackDepth: maxStackDepth,
          sampleCount: sampleCount,
          timeOriginMicros: timeOriginMicros,
          timeExtentMicros: timeExtentMicros,
          pid: pid,
          functions: functions,
          samples: samples,
        );

  CachedCpuSamples._fromJson(Map<String, dynamic> json)
      : userTag = json['userTag']!,
        truncated = json['truncated'],
        super(
          samplePeriod: json['samplePeriod'] ?? -1,
          maxStackDepth: json['maxStackDepth'] ?? -1,
          sampleCount: json['sampleCount'] ?? -1,
          timeOriginMicros: json['timeOriginMicros'] ?? -1,
          timeExtentMicros: json['timeExtentMicros'] ?? -1,
          pid: json['pid'] ?? -1,
          functions: List<ProfileFunction>.from(
            createServiceObject(json['functions'], const ['ProfileFunction'])
                    as List? ??
                [],
          ),
          samples: List<CpuSample>.from(
            createServiceObject(json['samples'], const ['CpuSample'])
                    as List? ??
                [],
          ),
        );

  @override
  String get type => 'CachedCpuSamples';

  /// The name of the [UserTag] associated with this cache of [CpuSamples].
  final String userTag;

  /// Provided if the CPU sample cache has filled and older samples have been
  /// dropped.
  final bool? truncated;
}

/// A collection of [UserTag] names associated with caches of CPU samples.
class AvailableCachedCpuSamples extends Response {
  static AvailableCachedCpuSamples? parse(Map<String, dynamic>? json) =>
      json == null ? null : AvailableCachedCpuSamples._fromJson(json);

  AvailableCachedCpuSamples({
    required this.cacheNames,
  });

  AvailableCachedCpuSamples._fromJson(Map<String, dynamic> json)
      : cacheNames = List<String>.from(json['cacheNames']);

  @override
  String get type => 'AvailableCachedUserTagCpuSamples';

  /// A [List] of [UserTag] names associated with CPU sample caches.
  final List<String> cacheNames;
}

class ResumePermissionsRequired extends Response {
  static ResumePermissionsRequired? parse(Map<String, dynamic>? json) =>
      json == null ? null : ResumePermissionsRequired._fromJson(json);

  ResumePermissionsRequired({
    required this.onPauseStart,
    required this.onPauseExit,
  });

  ResumePermissionsRequired._fromJson(Map<String, dynamic> json)
      : onPauseStart = json['onPauseStart'],
        onPauseExit = json['onPauseExit'];

  final bool onPauseStart;
  final bool onPauseExit;
}
