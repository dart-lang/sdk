// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library js;

import 'package:js_ast/js_ast.dart';
export 'package:js_ast/js_ast.dart';

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
  Node rootNode;

  Dart2JSJavaScriptPrintingContext(leg.Compiler this.compiler,
      DumpInfoTask this.monitor);

  @override
  void error(String message) {
    compiler.internalError(NO_LOCATION_SPANNABLE, message);
  }

  @override
  void emit(String string) {
    outBuffer.add(string);
  }

  @override
  void enterNode(Node node, int startPosition) {
    SourceInformation sourceInformation = node.sourceInformation;
    if (sourceInformation != null) {
      if (rootNode == null) {
        rootNode = node;
      }
      if (sourceInformation.startPosition != null) {
        outBuffer.addSourceLocation(
            startPosition, sourceInformation.startPosition);
      }
    }
  }

  void exitNode(Node node,
                int startPosition,
                int endPosition,
                int closingPosition) {
    SourceInformation sourceInformation = node.sourceInformation;
    if (sourceInformation != null) {
      if (closingPosition != null &&
          sourceInformation.closingPosition != null) {
        outBuffer.addSourceLocation(
            closingPosition, sourceInformation.closingPosition);
      }
      if (sourceInformation.endPosition != null) {
        outBuffer.addSourceLocation(endPosition, sourceInformation.endPosition);
      }
      if (rootNode == node) {
        outBuffer.addSourceLocation(endPosition, null);
        rootNode = null;
      }
    }
    if (monitor != null) {
      monitor.recordAstSize(node, endPosition - startPosition);
    }
  }
}
