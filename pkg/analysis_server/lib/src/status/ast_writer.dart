// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analysis_server.src.status.ast_writer;

import 'dart:convert';

import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/java_engine.dart';

/**
 * A visitor that will produce an HTML representation of an AST structure.
 */
class AstWriter extends UnifyingAstVisitor {
  /**
   * The buffer on which the HTML is to be written.
   */
  final StringBuffer buffer;

  /**
   * The current level of indentation.
   */
  int indentLevel = 0;

  /**
   * A list containing the exceptions that were caught while attempting to write
   * out an AST structure.
   */
  List<CaughtException> exceptions = <CaughtException>[];

  /**
   * Initialize a newly created element writer to write the HTML representation
   * of visited nodes on the given [buffer].
   */
  AstWriter(this.buffer);

  @override
  void visitNode(AstNode node) {
    _writeNode(node);
    indentLevel++;
    try {
      node.visitChildren(this);
    } finally {
      indentLevel--;
    }
  }

  /**
   * Return the name of the given [node], or `null` if the given node is not a
   * declaration.
   */
  String _getName(AstNode node) {
    if (node is ClassTypeAlias) {
      return node.name.name;
    } else if (node is ClassDeclaration) {
      return node.name.name;
    } else if (node is ConstructorDeclaration) {
      if (node.name == null) {
        return node.returnType.name;
      } else {
        return node.returnType.name + '.' + node.name.name;
      }
    } else if (node is ConstructorName) {
      return node.toSource();
    } else if (node is FieldDeclaration) {
      return _getNames(node.fields);
    } else if (node is FunctionDeclaration) {
      SimpleIdentifier nameNode = node.name;
      if (nameNode != null) {
        return nameNode.name;
      }
    } else if (node is FunctionTypeAlias) {
      return node.name.name;
    } else if (node is Identifier) {
      return node.name;
    } else if (node is MethodDeclaration) {
      return node.name.name;
    } else if (node is TopLevelVariableDeclaration) {
      return _getNames(node.variables);
    } else if (node is TypeName) {
      return node.toSource();
    } else if (node is TypeParameter) {
      return node.name.name;
    } else if (node is VariableDeclaration) {
      return node.name.name;
    }
    return null;
  }

  /**
   * Return a string containing a comma-separated list of the names of all of
   * the variables in the given list of [variables].
   */
  String _getNames(VariableDeclarationList variables) {
    StringBuffer buffer = new StringBuffer();
    bool first = true;
    for (VariableDeclaration variable in variables.variables) {
      if (first) {
        first = false;
      } else {
        buffer.write(', ');
      }
      buffer.write(variable.name.name);
    }
    return buffer.toString();
  }

  void _indent([int extra = 0]) {
    for (int i = 0; i < indentLevel; i++) {
      buffer.write('&#x250A;&nbsp;&nbsp;&nbsp;');
    }
    if (extra > 0) {
      buffer.write('&#x250A;&nbsp;&nbsp;&nbsp;');
      for (int i = 1; i < extra; i++) {
        buffer.write('&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;');
      }
    }
  }

  /**
   * Write a representation of the given [node] to the buffer.
   */
  void _writeNode(AstNode node) {
    _indent();
    buffer.write(node.runtimeType);
    buffer.write(' <span style="color:gray">[');
    buffer.write(node.offset);
    buffer.write('..');
    buffer.write(node.offset + node.length - 1);
    buffer.write(']</span>');
    buffer.write('<br>');
    _writeProperty('name', _getName(node));
    if (node is BinaryExpression) {
      _writeProperty('static element', node.staticElement);
      _writeProperty('static type', node.staticType);
      _writeProperty('propagated element', node.propagatedElement);
      _writeProperty('propagated type', node.propagatedType);
    } else if (node is CompilationUnit) {
      _writeProperty("element", node.element);
    } else if (node is ExportDirective) {
      _writeProperty("element", node.element);
    } else if (node is FunctionExpressionInvocation) {
      _writeProperty('static element', node.staticElement);
      _writeProperty('static type', node.staticType);
      _writeProperty('propagated element', node.propagatedElement);
      _writeProperty('propagated type', node.propagatedType);
    } else if (node is ImportDirective) {
      _writeProperty("element", node.element);
    } else if (node is LibraryDirective) {
      _writeProperty("element", node.element);
    } else if (node is PartDirective) {
      _writeProperty("element", node.element);
    } else if (node is PartOfDirective) {
      _writeProperty("element", node.element);
    } else if (node is PostfixExpression) {
      _writeProperty('static element', node.staticElement);
      _writeProperty('static type', node.staticType);
      _writeProperty('propagated element', node.propagatedElement);
      _writeProperty('propagated type', node.propagatedType);
    } else if (node is PrefixExpression) {
      _writeProperty('static element', node.staticElement);
      _writeProperty('static type', node.staticType);
      _writeProperty('propagated element', node.propagatedElement);
      _writeProperty('propagated type', node.propagatedType);
    } else if (node is SimpleIdentifier) {
      _writeProperty('static element', node.staticElement);
      _writeProperty('static type', node.staticType);
      _writeProperty('propagated element', node.propagatedElement);
      _writeProperty('propagated type', node.propagatedType);
    } else if (node is SimpleStringLiteral) {
      _writeProperty("value", node.value);
    } else if (node is Expression) {
      _writeProperty('static type', node.staticType);
      _writeProperty('propagated type', node.propagatedType);
    }
  }

  /**
   * Write the [value] of the property with the given [name].
   */
  void _writeProperty(String name, Object value) {
    if (value != null) {
      String valueString = null;
      try {
        valueString = value.toString();
      } catch (exception, stackTrace) {
        exceptions.add(new CaughtException(exception, stackTrace));
      }
      _indent(2);
      buffer.write('$name = ');
      if (valueString == null) {
        buffer.write('<span style="color: #FF0000">');
        buffer.write(HTML_ESCAPE.convert(value.runtimeType.toString()));
        buffer.write('</span>');
      } else {
        buffer.write(HTML_ESCAPE.convert(valueString));
      }
      buffer.write('<br>');
    }
  }
}
