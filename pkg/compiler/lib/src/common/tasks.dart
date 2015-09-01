// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.common.tasks;

import 'dart:profiler' show
    UserTag;
import '../compiler.dart' show
    Compiler;
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

  CompilerTask(Compiler compiler)
      : this.compiler = compiler,
        watch = (compiler.verbose) ? new Stopwatch() : null;

  String get name => "Unknown task '${this.runtimeType}'";
  int get timing => (watch != null) ? watch.elapsedMilliseconds : 0;

  int get timingMicroseconds => (watch != null) ? watch.elapsedMicroseconds : 0;

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
    compiler.withCurrentElement(element, () => measure(action));
  }
}

class GenericTask extends CompilerTask {
  final String name;

  GenericTask(this.name, Compiler compiler)
      : super(compiler);
}
