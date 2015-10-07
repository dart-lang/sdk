// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.common.tasks;

import 'dart:profiler' show
    UserTag;
import '../compiler.dart' show
    Compiler;
import '../diagnostics/diagnostic_listener.dart' show
    DiagnosticReporter;
import '../elements/elements.dart' show
    Element;

typedef void DeferredAction();

class DeferredTask {
  final Element element;
  final DeferredAction action;

  DeferredTask(this.element, this.action);
}

class CompilerTask {
  final Compiler compiler;
  final Stopwatch watch;
  UserTag profilerTag;
  final Map<String, GenericTask> _subtasks = <String, GenericTask>{};

  CompilerTask(Compiler compiler)
      : this.compiler = compiler,
        watch = (compiler.verbose) ? new Stopwatch() : null;

  DiagnosticReporter get reporter => compiler.reporter;

  String get name => "Unknown task '${this.runtimeType}'";

  int get timing {
    if (watch == null) return 0;
    int total = watch.elapsedMilliseconds;
    for (GenericTask subtask in _subtasks.values) {
      total += subtask.timing;
    }
    return total;
  }

  UserTag getProfilerTag() {
    if (profilerTag == null) profilerTag = new UserTag(name);
    return profilerTag;
  }

  measure(action()) {
    // In verbose mode when watch != null.
    if (watch == null) return action();
    CompilerTask previous = compiler.measuredTask;
    if (identical(this, previous)) return action();
    compiler.measuredTask = this;
    if (previous != null) previous.watch.stop();
    watch.start();
    UserTag oldTag = getProfilerTag().makeCurrent();
    try {
      return action();
    } finally {
      watch.stop();
      oldTag.makeCurrent();
      if (previous != null) previous.watch.start();
      compiler.measuredTask = previous;
    }
  }

  measureElement(Element element, action()) {
    reporter.withCurrentElement(element, () => measure(action));
  }

  /// Measure the time spent in [action] (if in verbose mode) and accumulate it
  /// under a subtask with the given name.
  measureSubtask(String name, action()) {
    if (watch == null) return action();
    // Use a nested CompilerTask for the measurement to ensure nested [measure]
    // calls work correctly. The subtasks will never themselves have nested
    // subtasks because they are not accessible outside.
    GenericTask subtask = _subtasks.putIfAbsent(name,
        () => new GenericTask(name, compiler));
    return subtask.measure(action);
  }

  Iterable<String> get subtasks => _subtasks.keys;

  int getSubtaskTime(String subtask) => _subtasks[subtask].timing;
}

class GenericTask extends CompilerTask {
  final String name;

  GenericTask(this.name, Compiler compiler)
      : super(compiler);
}
