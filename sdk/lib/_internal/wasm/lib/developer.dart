// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This is a stub implementation of `dart:developer`.

import "dart:_internal" show patch;

import "dart:async" show Zone;

// Stubs for `developer.dart`.

@patch
bool debugger({bool when = true, String? message}) => when;

@patch
Object? inspect(Object? object) => object;

@patch
void log(String message,
    {DateTime? time,
    int? sequenceNumber,
    int level = 0,
    String name = '',
    Zone? zone,
    Object? error,
    StackTrace? stackTrace}) {}

@patch
int get reachabilityBarrier => 0;

@patch
bool get extensionStreamHasListener => false;

@patch
void _postEvent(String eventKind, String eventData) {}

@patch
ServiceExtensionHandler? _lookupExtension(String method) => null;

@patch
_registerExtension(String method, ServiceExtensionHandler handler) {}

// Stubs for `timeline.dart`.

@patch
bool _isDartStreamEnabled() => false;

@patch
int _getTraceClock() => _traceClock++;

int _traceClock = 0;

@patch
int _getNextTaskId() => 0;

@patch
void _reportTaskEvent(
    int taskId, int type, String name, String argumentsAsJson) {}

@patch
abstract final class NativeRuntime {
  @patch
  static void writeHeapSnapshotToFile(String filepath) =>
      throw UnsupportedError(
          "Generating heap snapshots is not supported on the wasm.");
}
