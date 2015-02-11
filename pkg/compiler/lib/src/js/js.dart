// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library js;

// TODO(sra): This will become a package import.
import 'js_ast.dart';
export 'js_ast.dart';

import '../io/code_output.dart' show CodeBuffer;
import '../io/source_information.dart' show SourceInformation;
import '../js_emitter/js_emitter.dart' show USE_NEW_EMITTER;
import '../dart2jslib.dart' as leg;
import '../util/util.dart' show NO_LOCATION_SPANNABLE;
import '../dump_info.dart' show DumpInfoTask;


CodeBuffer prettyPrint(Node node, leg.Compiler compiler,
                       {DumpInfoTask monitor,
                        bool allowVariableMinification: true}) {
  JavaScriptPrintingOptions options = new JavaScriptPrintingOptions(
      shouldCompressOutput: compiler.enableMinification,
      minifyLocalVariables: allowVariableMinification,
      preferSemicolonToNewlineInMinifiedOutput: USE_NEW_EMITTER);
  Dart2JSJavaScriptPrintingContext context =
      new Dart2JSJavaScriptPrintingContext(compiler, monitor);
  Printer printer = new Printer(options, context);
  printer.visit(node);
  return context.outBuffer;
}

class Dart2JSJavaScriptPrintingContext implements JavaScriptPrintingContext {
  final leg.Compiler compiler;
  final DumpInfoTask monitor;
  final CodeBuffer outBuffer = new CodeBuffer();

  Dart2JSJavaScriptPrintingContext(leg.Compiler this.compiler,
      DumpInfoTask this.monitor);

  void error(String message) {
    compiler.internalError(NO_LOCATION_SPANNABLE, message);
  }

  void emit(String string) {
    outBuffer.add(string);
  }

  void enterNode(Node node) {
    SourceInformation sourceInformation = node.sourceInformation;
    if (sourceInformation != null) {
      sourceInformation.beginMapping(outBuffer);
    }
    if (monitor != null) monitor.enteringAst(node, outBuffer.length);
  }

  void exitNode(Node node) {
    if (monitor != null) monitor.exitingAst(node, outBuffer.length);
    SourceInformation sourceInformation = node.sourceInformation;
    if (sourceInformation != null) {
      sourceInformation.endMapping(outBuffer);
    }
  }
}
