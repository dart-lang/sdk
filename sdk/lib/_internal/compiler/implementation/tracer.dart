// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library tracer;

import '../compiler.dart' as api;
import 'dart:async' show EventSink;
import 'ssa/ssa.dart' as ssa;
import 'ssa/ssa_tracer.dart' show HTracer;
import 'ir/ir_nodes.dart' as ir;
import 'ir/ir_tracer.dart' show IRTracer;
import 'dart_backend/dart_tree.dart' as tree;
import 'dart_backend/tree_tracer.dart' show TreeTracer;
import 'dart2jslib.dart';

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
  Compiler compiler;
  ItemCompilationContext context;
  bool traceActive = false;
  final EventSink<String> output;
  final bool isEnabled = TRACE_FILTER != null;

  Tracer(api.CompilerOutputProvider outputProvider) :
    output = TRACE_FILTER != null ? outputProvider('dart', 'cfg') : null;

  void traceCompilation(String methodName,
                        ItemCompilationContext compilationContext,
                        Compiler compiler) {
    if (!isEnabled) return;
    if (!TRACE_FILTER.hasMatch(methodName)) return;
    this.context = compilationContext;
    this.compiler = compiler;
    tag("compilation", () {
      printProperty("name", methodName);
      printProperty("method", methodName);
      printProperty("date", new DateTime.now().millisecondsSinceEpoch);
    });
  }

  void traceGraph(String name, var irObject) {
    if (!traceActive) return;
    if (irObject is ssa.HGraph) {
      new HTracer(output, compiler, context).traceGraph(name, irObject);
    }
    else if (irObject is ir.FunctionDefinition) {
      new IRTracer(output).traceGraph(name, irObject);
    }
    else if (irObject is tree.FunctionDefinition) {
      new TreeTracer(output).traceGraph(name, irObject);
    }
  }

  void close() {
    if (output != null) {
      output.close();
    }
  }
}


abstract class TracerUtil {
  int indent = 0;
  EventSink<String> get output;


  void tag(String tagName, Function f) {
    println("begin_$tagName");
    indent++;
    f();
    indent--;
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
    for (int i = 0; i < indent; i++) {
      add("  ");
    }
  }
}
