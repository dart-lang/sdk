// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library future_group;

import 'dart:async';

/// A completer that waits until all added [Future]s complete.
// TODO(rnystrom): Copied from web_components. Remove from here when it gets
// added to dart:core. (See #6626.)
class FutureGroup<T> {
  int _pending = 0;
  Completer<List<T>> _completer = new Completer<List<T>>();
  final List<Future<T>> futures = <Future<T>>[];
  bool completed = false;

  final List<T> _values = <T>[];

  /// Wait for [task] to complete.
  Future<T> add(Future<T> task) {
    if (completed) {
      throw new StateError("The FutureGroup has already completed.");
    }

    _pending++;
    futures.add(task.then((value) {
      if (completed) return;

      _pending--;
      _values.add(value);

      if (_pending <= 0) {
        completed = true;
        _completer.complete(_values);
      }
    }).catchError((error) {
      if (completed) return;

      completed = true;
      _completer.completeError(error);
    }));

    return task;
  }

  Future<List> get future => _completer.future;
}

