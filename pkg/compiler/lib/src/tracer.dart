// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library tracer;

import 'dart:async' show EventSink;

import '../compiler.dart' as api;
import 'compiler.dart' show Compiler;
import 'ssa/nodes.dart' as ssa show HGraph;
import 'ssa/ssa_tracer.dart' show HTracer;
import 'util/util.dart' show Indentation;

/**
 * If non-null, we only trace methods whose name match the regexp defined by the
 * given pattern.
 */
const String TRACE_FILTER_PATTERN = const String.fromEnvironment("DUMP_IR");

final RegExp TRACE_FILTER =
    TRACE_FILTER_PATTERN == null ? null : new RegExp(TRACE_FILTER_PATTERN);

/**
 * Dumps the intermediate representation after each phase in a format
 * readable by IR Hydra.
 */
class Tracer extends TracerUtil {
  final Compiler compiler;
  bool traceActive = false;
  final EventSink<String> output;
  final bool isEnabled = TRACE_FILTER != null;

  Tracer(Compiler compiler, api.CompilerOutputProvider outputProvider)
      : this.compiler = compiler,
        output = TRACE_FILTER != null ? outputProvider('dart', 'cfg') : null;

  void traceCompilation(String methodName) {
    if (!isEnabled) return;
    traceActive = TRACE_FILTER.hasMatch(methodName);
    if (!traceActive) return;
    tag("compilation", () {
      printProperty("name", methodName);
      printProperty("method", methodName);
      printProperty("date", new DateTime.now().millisecondsSinceEpoch);
    });
  }

  void traceGraph(String name, var irObject) {
    if (!traceActive) return;
    if (irObject is ssa.HGraph) {
      new HTracer(output, compiler).traceGraph(name, irObject);
    }
  }

  void close() {
    if (output != null) {
      output.close();
    }
  }
}

abstract class TracerUtil {
  EventSink<String> get output;
  final Indentation _ind = new Indentation();

  void tag(String tagName, Function f) {
    println("begin_$tagName");
    _ind.indentBlock(f);
    println("end_$tagName");
  }

  void println(String string) {
    addIndent();
    add(string);
    add("\n");
  }

  void printEmptyProperty(String propertyName) {
    println(propertyName);
  }

  String formatPrty(x) {
    if (x is num) {
      return '${x}';
    } else if (x is String) {
      return '"${x}"';
    } else if (x is Iterable) {
      return x.map((s) => formatPrty(s)).join(' ');
    } else {
      throw "invalid property type: ${x}";
    }
  }

  void printProperty(String propertyName, value) {
    println("$propertyName ${formatPrty(value)}");
  }

  void add(String string) {
    output.add(string);
  }

  void addIndent() {
    add(_ind.indentation);
  }
}
