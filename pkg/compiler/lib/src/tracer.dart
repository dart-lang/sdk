// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library tracer;

import '../compiler_new.dart' as api;
import 'options.dart' show CompilerOptions;
import 'ssa/nodes.dart' as ssa show HGraph;
import 'ssa/ssa_tracer.dart' show HTracer;
import 'util/util.dart' show Indentation;
import 'world.dart' show JClosedWorld;

String TRACE_FILTER_PATTERN_FOR_TEST;

/// Dumps the intermediate representation after each phase in a format
/// readable by IR Hydra.
class Tracer extends TracerUtil {
  final JClosedWorld closedWorld;
  bool traceActive = false;
  @override
  final api.OutputSink output;
  final RegExp traceFilter;

  Tracer._(this.closedWorld, this.traceFilter, this.output);

  factory Tracer(JClosedWorld closedWorld, CompilerOptions options,
      api.CompilerOutput compilerOutput) {
    String pattern = options.dumpSsaPattern ?? TRACE_FILTER_PATTERN_FOR_TEST;
    if (pattern == null) return Tracer._(closedWorld, null, null);
    var traceFilter = RegExp(pattern);
    var output =
        compilerOutput.createOutputSink('', 'cfg', api.OutputType.debug);
    return Tracer._(closedWorld, traceFilter, output);
  }

  bool get isEnabled => traceFilter != null;

  void traceCompilation(String methodName) {
    if (!isEnabled) return;
    traceActive = traceFilter.hasMatch(methodName);
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
      new HTracer(output, closedWorld).traceGraph(name, irObject);
    }
  }

  void close() {
    if (output != null) {
      output.close();
    }
  }
}

abstract class TracerUtil {
  api.OutputSink get output;
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
