// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.10

import 'dart:async';
import 'dart:collection';

import 'package:async/async.dart';
import 'package:meta/meta.dart';
import 'package:pedantic/pedantic.dart';
import 'package:vm_service/src/vm_service.dart';

extension DdsExtension on VmService {
  static bool _factoriesRegistered = false;
  static Version _ddsVersion;

  /// The _getDartDevelopmentServiceVersion_ RPC is used to determine what version of
  /// the Dart Development Service Protocol is served by a DDS instance.
  ///
  /// The result of this call is cached for subsequent invocations.
  Future<Version> getDartDevelopmentServiceVersion() async {
    if (_ddsVersion == null) {
      _ddsVersion =
          await _callHelper<Version>('getDartDevelopmentServiceVersion');
    }
    return _ddsVersion;
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
    StreamController<Event> controller;
    StreamQueue<Event> streamEvents;

    controller = StreamController<Event>(onListen: () async {
      streamEvents = StreamQueue<Event>(onEvent(stream));
      final history = (await getStreamHistory(stream)).history;
      Event firstStreamEvent;
      unawaited(streamEvents.peek.then((e) {
        firstStreamEvent = e;
      }));
      for (final event in history) {
        if (firstStreamEvent != null &&
            event.timestamp > firstStreamEvent.timestamp) {
          break;
        }
        controller.sink.add(event);
      }
      unawaited(controller.sink.addStream(streamEvents.rest));
    }, onCancel: () {
      streamEvents.cancel();
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

  Future<bool> _versionCheck(int major, int minor) async {
    if (_ddsVersion == null) {
      _ddsVersion = await getDartDevelopmentServiceVersion();
    }
    return ((_ddsVersion.major == major && _ddsVersion.minor >= minor) ||
        (_ddsVersion.major > major));
  }

  Future<T> _callHelper<T>(String method,
      {String isolateId, Map args = const {}}) {
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
    _factoriesRegistered = true;
  }
}

/// A collection of historical [Event]s from some stream.
class StreamHistory extends Response {
  static StreamHistory parse(Map<String, dynamic> json) =>
      json == null ? null : StreamHistory._fromJson(json);

  StreamHistory({@required List<Event> history}) : _history = history;

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
