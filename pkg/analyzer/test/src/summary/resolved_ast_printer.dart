// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

/// Prints AST as a tree, with properties and children.
class ResolvedAstPrinter extends ThrowingAstVisitor<void> {
  StringSink _sink;
  String _indent = '';

  ResolvedAstPrinter(StringSink sink, String indent)
      : _sink = sink,
        _indent = indent;

  @override
  void visitCompilationUnit(CompilationUnit node) {
    super.visitCompilationUnit(node);
  }

  @override
  void visitIntegerLiteral(IntegerLiteral node) {
    _writeln('IntegerLiteral(${node.literal.lexeme})');
    _withIndent(() {
      _writeln2('staticType: ', node.staticType);
    });
  }

  @override
  void visitListLiteral(ListLiteral node) {
    _writeln('ListLiteral');
    _withIndent(() {
      _writeln2('isConst: ', node.isConst);
      _writeln2('staticType: ', node.staticType);
      _writeTypeArgumentList('typeArguments', node.typeArguments);
      _writeNodeList('elements', node.elements);
    });
  }

  void _withIndent(void Function() f) {
    var indent = _indent;
    _indent = '$_indent  ';
    f();
    _indent = indent;
  }

  void _writeln(String line) {
    _sink.write('$_indent');
    _sink.writeln(line);
  }

  void _writeln2(String prefix, Object o) {
    _sink.write('$_indent');
    _sink.write(prefix);
    _sink.writeln(o);
  }

  void _writeNodeList(String name, NodeList nodeList) {
    if (nodeList.isNotEmpty) {
      _writeln(name);
      _withIndent(() {
        nodeList.accept(this);
      });
    }
  }

  void _writeTypeArgumentList(String name, TypeArgumentList node) {
    if (node != null) {
      _writeln(name);
      _withIndent(() {
        node.arguments?.accept(this);
      });
    }
  }
}
