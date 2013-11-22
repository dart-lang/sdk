// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library watcher.directory_watcher.resubscribable;

import 'dart:async';

import '../directory_watcher.dart';
import '../watch_event.dart';

typedef ManuallyClosedDirectoryWatcher WatcherFactory();

/// A wrapper for [ManuallyClosedDirectoryWatcher] that encapsulates support for
/// closing the watcher when it has no subscribers and re-opening it when it's
/// re-subscribed.
///
/// It's simpler to implement watchers without worrying about this behavior.
/// This class wraps a watcher class which can be written with the simplifying
/// assumption that it can continue emitting events until an explicit `close`
/// method is called, at which point it will cease emitting events entirely. The
/// [ManuallyClosedDirectoryWatcher] interface is used for these watchers.
///
/// This would be more cleanly implemented as a function that takes a class and
/// emits a new class, but Dart doesn't support that sort of thing. Instead it
/// takes a factory function that produces instances of the inner class.
abstract class ResubscribableDirectoryWatcher implements DirectoryWatcher {
  /// The factory function that produces instances of the inner class.
  final WatcherFactory _factory;

  final String directory;

  Stream<WatchEvent> get events => _eventsController.stream;
  StreamController<WatchEvent> _eventsController;

  bool get isReady => _readyCompleter.isCompleted;

  Future get ready => _readyCompleter.future;
  var _readyCompleter = new Completer();

  /// Creates a new [ResubscribableDirectoryWatcher] wrapping the watchers
  /// emitted by [_factory].
  ResubscribableDirectoryWatcher(this.directory, this._factory) {
    var watcher;
    var subscription;

    _eventsController = new StreamController<WatchEvent>.broadcast(
        onListen: () {
      watcher = _factory();
      subscription = watcher.events.listen(_eventsController.add,
          onError: _eventsController.addError,
          onDone: _eventsController.close);

      // It's important that we complete the value of [_readyCompleter] at the
      // time [onListen] is called, as opposed to the value when [watcher.ready]
      // fires. A new completer may be created by that time.
      watcher.ready.then(_readyCompleter.complete);
    }, onCancel: () {
      // Cancel the subscription before closing the watcher so that the
      // watcher's `onDone` event doesn't close [events].
      subscription.cancel();
      watcher.close();
      _readyCompleter = new Completer();
    }, sync: true);
  }
}

/// An interface for watchers with an explicit, manual [close] method.
///
/// See [ResubscribableDirectoryWatcher].
abstract class ManuallyClosedDirectoryWatcher implements DirectoryWatcher {
  /// Closes the watcher.
  ///
  /// Subclasses should close their [events] stream and release any internal
  /// resources.
  void close();
}
