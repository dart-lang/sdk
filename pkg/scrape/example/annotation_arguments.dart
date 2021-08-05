// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:analyzer/dart/ast/ast.dart';
import 'package:scrape/scrape.dart';

void main(List<String> arguments) {
  Scrape()
    ..addHistogram('Has argument list?')
    ..addHistogram('Arguments', order: SortOrder.numeric)
    ..addHistogram('Argument type')
    ..addHistogram('Argument identifier')
    ..addHistogram('Annotation')
    ..addVisitor(() => AnnotationVisitor())
    ..runCommandLine(arguments);
}

class AnnotationVisitor extends ScrapeVisitor {
  @override
  void visitAnnotation(Annotation node) {
    record('Annotation', node.name.name);

    var arguments = node.arguments;
    if (arguments != null) {
      record('Has argument list?', 'yes');
      record('Arguments', arguments.arguments.length);
      arguments.arguments.forEach(_recordArgument);
    } else {
      record('Has argument list?', 'no');
    }

    super.visitAnnotation(node);
  }

  void _recordArgument(AstNode? node) {
    if (node is NamedExpression) {
      _recordArgument(node.expression);
    } else if (node is IfElement) {
      _recordArgument(node.thenElement);
      _recordArgument(node.elseElement);
    } else if (node is ForElement) {
      _recordArgument(node.body);
    } else if (node is SpreadElement) {
      _recordArgument(node.expression);
    } else if (node is MapLiteralEntry) {
      _recordArgument(node.key);
      _recordArgument(node.value);
    } else if (node is SimpleIdentifier || node is PrefixedIdentifier) {
      record('Argument identifier', node.toString());
      record('Argument type', 'identifier');
    } else if (node is PrefixExpression) {
      record('Argument type', 'unary operator');
    } else if (node is BinaryExpression) {
      record('Argument type', 'binary operator');
    } else if (node is BooleanLiteral) {
      record('Argument type', 'bool');
    } else if (node is DoubleLiteral) {
      record('Argument type', 'double');
    } else if (node is IntegerLiteral) {
      record('Argument type', 'int');
    } else if (node is ListLiteral) {
      record('Argument type', 'list');
      node.elements.forEach(_recordArgument);
    } else if (node is MethodInvocation) {
      record('Argument type', 'method call');
    } else if (node is NullLiteral) {
      record('Argument type', 'null');
    } else if (node is SetOrMapLiteral) {
      record('Argument type', 'set or map');
      node.elements.forEach(_recordArgument);
    } else if (node is StringLiteral) {
      record('Argument type', 'string');
    } else if (node is SymbolLiteral) {
      record('Argument type', 'symbol');
    } else if (node == null) {
      // Do nothing. Only happens for null else elements.
    } else {
      record('Argument type', node.runtimeType.toString());
    }
  }
}
