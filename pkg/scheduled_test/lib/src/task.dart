// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library task;

import 'dart:async';

import 'schedule.dart';
import 'utils.dart';

typedef Future TaskBody();

/// A single task to be run as part of a [TaskQueue].
class Task {
  /// The queue to which this [Task] belongs.
  final TaskQueue queue;

  /// A description of this task. Used for debugging. May be `null`.
  final String description;

  /// The body of the task.
  TaskBody fn;

  /// The identifier of the task. This is unique within [queue]. It's used for
  /// debugging when [description] isn't provided.
  int _id;

  /// A Future that will complete to the return value of [fn] once this task
  /// finishes running.
  Future get result => _resultCompleter.future;
  final _resultCompleter = new Completer();

  Task(fn(), this.queue, this.description) {
    _id = this.queue.contents.length;
    this.fn = () {
      var future = new Future.immediate(null).then((_) => fn());
      chainToCompleter(future, _resultCompleter);
      return future;
    };

    // Make sure any error thrown by fn isn't top-leveled by virtue of being
    // passed to the result future.
    result.catchError((_) {});
  }

  String toString() => description == null ? "#$_id" : description;

  /// Returns a detailed representation of [queue] with this task highlighted.
  String generateTree() => queue.generateTree(this);
}
