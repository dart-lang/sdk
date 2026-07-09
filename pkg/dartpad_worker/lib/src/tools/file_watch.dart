// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/file_system/file_system.dart' show ResourceProvider;
import 'package:watcher/watcher.dart' show ChangeType, WatchEvent;

/// Watches a file or folder for changes.
final class FileWatch {
  late final StreamSubscription<WatchEvent> _subscription;
  final ResourceProvider _rp;
  final void Function(List<({String event, Uri uri})>) _sendEvents;

  final List<WatchEvent> _buffer = [];
  bool _flushScheduled = false;

  FileWatch._(this._rp, Stream<WatchEvent> changes, this._sendEvents) {
    _subscription = changes.listen(_onEvent);
  }

  static Future<FileWatch> create(
    ResourceProvider rp,
    String path,
    void Function(List<({String event, Uri uri})>) sendEvents,
  ) async {
    final watcher = rp.getResource(path).watch();
    final fw = FileWatch._(rp, watcher.changes, sendEvents);
    try {
      await watcher.ready;
    } catch (_) {
      await fw.stop();
      rethrow;
    }
    return fw;
  }

  void _onEvent(WatchEvent event) {
    _buffer.add(event);
    if (!_flushScheduled) {
      _flushScheduled = true;
      scheduleMicrotask(_flush);
    }
  }

  void _flush() {
    _flushScheduled = false;
    if (_buffer.isEmpty) return;

    final events = _buffer.map((e) {
      final type = switch (e.type) {
        ChangeType.ADD => 'add',
        ChangeType.MODIFY => 'modify',
        ChangeType.REMOVE => 'remove',
        _ => 'modify',
      };
      return (event: type, uri: _rp.pathContext.toUri(e.path));
    }).toList();
    _buffer.clear();

    _sendEvents(events);
  }

  Future<void> stop() async {
    await _subscription.cancel();
    if (_buffer.isNotEmpty) {
      _flush();
    }
  }
}
