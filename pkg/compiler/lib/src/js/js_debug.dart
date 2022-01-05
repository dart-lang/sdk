// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Helper for debug JS nodes.

library js.debug;

import 'package:js_ast/js_ast.dart';
import 'package:kernel/text/indentation.dart' show Indentation, Tagging;

import '../io/code_output.dart' show BufferedCodeOutput;

/// Unparse the JavaScript [node].
String nodeToString(Node node, {bool pretty = false}) {
  JavaScriptPrintingOptions options = JavaScriptPrintingOptions(
      shouldCompressOutput: !pretty,
      preferSemicolonToNewlineInMinifiedOutput: !pretty);
  LenientPrintingContext printingContext = LenientPrintingContext();
  Printer(options, printingContext).visit(node);
  return printingContext.getText();
}

/// Visitor that creates an XML-like representation of the structure of a
/// JavaScript [Node].
class DebugPrinter extends BaseVisitorVoid with Indentation, Tagging<Node> {
  @override
  StringBuffer sb = StringBuffer();

  void visitNodeWithChildren(Node node, String type, [Map params]) {
    openNode(node, type, params);
    node.visitChildren(this);
    closeNode();
  }

  @override
  void visitNode(Node node) {
    visitNodeWithChildren(node, '${node.runtimeType}');
  }

  @override
  void visitName(Name node) {
    openAndCloseNode(node, '${node.runtimeType}', {'name': node.name});
  }

  @override
  void visitBinary(Binary node) {
    visitNodeWithChildren(node, '${node.runtimeType}', {'op': node.op});
  }

  @override
  void visitLiteralString(LiteralString node) {
    openAndCloseNode(node, '${node.runtimeType}', {'value': node.value});
  }

  /// Pretty-prints given node tree into string.
  static String prettyPrint(Node node) {
    var p = DebugPrinter();
    node.accept(p);
    return p.sb.toString();
  }
}

/// Simple printing context that doesn't throw on errors.
class LenientPrintingContext extends SimpleJavaScriptPrintingContext
    implements BufferedCodeOutput {
  @override
  void error(String message) {
    buffer.write('>>$message<<');
  }
}
