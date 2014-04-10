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
 * Set to true to enable tracing.
 */
const bool GENERATE_TRACE = false;

/**
 * If non-null, we only trace methods whose name contains the given substring.
 */
const String TRACE_FILTER = null;

/**
 * Dumps the intermediate representation after each phase in a format
 * readable by IR Hydra.
 */
class Tracer extends TracerUtil {
  Compiler compiler;
  ItemCompilationContext context;
  bool traceActive = false;
  final EventSink<String> output;
  final bool enabled = GENERATE_TRACE;

  Tracer(api.CompilerOutputProvider outputProvider) :
    output = GENERATE_TRACE ? outputProvider('dart', 'cfg') : null;

  void traceCompilation(String methodName,
                        ItemCompilationContext compilationContext,
                        Compiler compiler) {
    if (!enabled) return;
    this.context = compilationContext;
    this.compiler = compiler;
    traceActive =
        TRACE_FILTER == null || methodName.contains(TRACE_FILTER);
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
