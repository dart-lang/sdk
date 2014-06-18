// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.barback.cycle_exception;

import 'package:stack_trace/stack_trace.dart';

import '../utils.dart';

/// An exception thrown when a transformer dependency cycle is detected.
///
/// A cycle exception is usually produced within a deeply-nested series of
/// calls. The API is designed to make it easy for each of these calls to add to
/// the message so that the full reasoning for the cycle is made visible to the
/// user.
///
/// Each call's individual message is called a "step". A [CycleException] is
/// represented internally as a linked list of steps.
class CycleException implements ApplicationException {
  final innerError = null;
  final Trace innerTrace = null;

  /// The step for this exception.
  final String _step;

  /// The next exception in the linked list.
  ///
  /// [_next]'s steps come after [_step].
  final CycleException _next;

  /// A list of all steps in the cycle.
  List<String> get steps {
    if (_step == null) return [];

    var exception = this;
    var steps = [];
    while (exception != null) {
      steps.add(exception._step);
      exception = exception._next;
    }
    return steps;
  }

  String get message {
    var steps = this.steps;
    if (steps.isEmpty) return "Transformer cycle detected.";
    return "Transformer cycle detected:\n" +
        steps.map((step) => "  $step").join("\n");
  }

  /// Creates a new [CycleException] with zero or one steps.
  CycleException([this._step])
      : _next = null;

  CycleException._(this._step, this._next);

  /// Returns a copy of [this] with [step] added to the beginning of [steps].
  CycleException prependStep(String step) {
    if (_step == null) return new CycleException(step);
    return new CycleException._(step, this);
  }

  String toString() => message;
}
