// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_embedder' as embedder;
import 'dart:_internal' show patch;
import 'dart:_js_helper' show jsStringFromDartString, JSExternWrapperExt;
import 'dart:_wasm';
import 'dart:async' show Zone;
import 'dart:isolate';

@patch
bool debugger({bool when = true, String? message}) {
  if (when) {
    embedder.debugger(
      message == null
          ? WasmExternRef.nullRef
          : jsStringFromDartString(message).wrappedExternRef,
    );
  }

  return when;
}

@patch
Object? inspect(Object? object) {
  embedder.inspect(object == null ? null : WasmAnyRef.fromObject(object));
  return object;
}

@patch
void log(
  String message, {
  DateTime? time,
  int? sequenceNumber,
  int level = 0,
  String name = '',
  Zone? zone,
  Object? error,
  StackTrace? stackTrace,
}) {
  // TODO.
}

@patch
int get reachabilityBarrier => 0;

@patch
abstract final class NativeRuntime {
  @patch
  static String? get buildId => null;

  @patch
  static void writeHeapSnapshotToFile(String filepath) =>
      throw UnsupportedError(
        "Generating heap snapshots is not supported for WebAssembly.",
      );

  @patch
  static void streamTimelineTo(
    TimelineRecorder recorder, {
    String? path,
    String streams = "Dart,GC,Compiler",
    bool enableProfiler = false,
    Duration samplingInterval = const Duration(microseconds: 1000),
  }) => throw UnsupportedError(
    "Streaming timelines is not supported for WebAssembly.",
  );

  @patch
  static void stopStreamingTimeline() => throw UnsupportedError(
    "Streaming timelines is not supported for WebAssembly.",
  );
}

@patch
bool get extensionStreamHasListener => false;

final _extensions = <String, ServiceExtensionHandler>{};

@patch
void _postEvent(String eventKind, String eventData) {
  // TODO.
}

@patch
ServiceExtensionHandler? _lookupExtension(String method) {
  return _extensions[method];
}

@patch
_registerExtension(String method, ServiceExtensionHandler handler) {
  _extensions[method] = handler;
}

@patch
void _getServerInfo(SendPort sendPort) {
  sendPort.send(null);
}

@patch
void _webServerControl(SendPort sendPort, bool enable, bool? silenceOutput) {
  sendPort.send(null);
}

@patch
int _getServiceMajorVersion() {
  return 0;
}

@patch
int _getServiceMinorVersion() {
  return 0;
}

@patch
String? _getIsolateIdFromSendPort(SendPort sendPort) {
  return null;
}

@patch
String? _getObjectId(Object object) {
  return null;
}

@patch
class UserTag {
  @patch
  factory UserTag(String label) = _FakeUserTag;

  @patch
  static UserTag get defaultTag => _FakeUserTag._defaultTag;
}

final class _FakeUserTag implements UserTag {
  static final _instances = <String, _FakeUserTag>{};

  _FakeUserTag.real(this.label);

  factory _FakeUserTag(String label) {
    // Canonicalize by name.
    var existingTag = _instances[label];
    if (existingTag != null) {
      return existingTag;
    }
    // Throw an exception if we've reached the maximum number of user tags.
    if (_instances.length == UserTag.maxUserTags) {
      throw UnsupportedError(
        'UserTag instance limit (${UserTag.maxUserTags}) reached.',
      );
    }
    return _instances[label] = _FakeUserTag.real(label);
  }

  final String label;

  UserTag makeCurrent() {
    var old = _currentTag;
    _currentTag = this;
    return old;
  }

  static final UserTag _defaultTag = _FakeUserTag('Default');
}

var _currentTag = _FakeUserTag._defaultTag;

@patch
UserTag getCurrentTag() => _currentTag;

@patch
bool _isDartStreamEnabled() => embedder.dartTimelineStreamEnabled().toBool();

int _taskId = 1;

@patch
int _getNextTaskId() {
  return _taskId++;
}

@patch
int _getTraceClock() => embedder.monotonicClockTicks().toInt();

@patch
void _reportTaskEvent(
  int taskId,
  int flowId,
  int type,
  String name,
  String argumentsAsJson,
) {
  embedder.reportTaskEvent(
    WasmI32.fromInt(taskId),
    WasmI32.fromInt(flowId),
    WasmI32.fromInt(type),
    jsStringFromDartString(name).wrappedExternRef,
    jsStringFromDartString(argumentsAsJson).wrappedExternRef,
  );
}
