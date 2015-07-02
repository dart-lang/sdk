// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library js;

import 'package:js_ast/js_ast.dart';
export 'package:js_ast/js_ast.dart';

import '../io/code_output.dart' show CodeOutput, CodeBuffer;
import '../js_emitter/js_emitter.dart' show USE_NEW_EMITTER;
import '../dart2jslib.dart' as leg;
import '../util/util.dart' show NO_LOCATION_SPANNABLE, Indentation, Tagging;
import '../dump_info.dart' show DumpInfoTask;
import 'js_source_mapping.dart';

CodeBuffer prettyPrint(Node node,
                       leg.Compiler compiler,
                       {DumpInfoTask monitor,
                        bool allowVariableMinification: true}) {
  JavaScriptSourceInformationStrategy sourceInformationFactory =
      compiler.backend.sourceInformationStrategy;
  JavaScriptPrintingOptions options = new JavaScriptPrintingOptions(
      shouldCompressOutput: compiler.enableMinification,
      minifyLocalVariables: allowVariableMinification,
      preferSemicolonToNewlineInMinifiedOutput: USE_NEW_EMITTER);
  CodeBuffer outBuffer = new CodeBuffer();
  SourceInformationProcessor sourceInformationProcessor =
      sourceInformationFactory.createProcessor(
          new SourceLocationsMapper(outBuffer));
  Dart2JSJavaScriptPrintingContext context =
      new Dart2JSJavaScriptPrintingContext(
          compiler, monitor, outBuffer, sourceInformationProcessor);
  Printer printer = new Printer(options, context);
  printer.visit(node);
  sourceInformationProcessor.process(node);
  return outBuffer;
}

class Dart2JSJavaScriptPrintingContext implements JavaScriptPrintingContext {
  final leg.Compiler compiler;
  final DumpInfoTask monitor;
  final CodeBuffer outBuffer;
  final CodePositionListener codePositionListener;

  Dart2JSJavaScriptPrintingContext(
      this.compiler,
      this.monitor,
      this.outBuffer,
      this.codePositionListener);

  @override
  void error(String message) {
    compiler.internalError(NO_LOCATION_SPANNABLE, message);
  }

  @override
  void emit(String string) {
    outBuffer.add(string);
  }

  @override
  void enterNode(Node, int startPosition) {}

  @override
  void exitNode(Node node,
                int startPosition,
                int endPosition,
                int closingPosition) {
    if (monitor != null) {
      monitor.recordAstSize(node, endPosition - startPosition);
    }
    codePositionListener.onPositions(
        node, startPosition, endPosition, closingPosition);
  }
}
