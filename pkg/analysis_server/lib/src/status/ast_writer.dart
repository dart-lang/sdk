// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analysis_server/src/status/tree_writer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/src/dart/ast/ast.dart';

/// A visitor that will produce an HTML representation of an AST structure.
class AstWriter extends UnifyingAstVisitor with TreeWriter {
  /// Initialize a newly created element writer to write the HTML representation
  /// of visited nodes on the given [buffer].
  AstWriter(StringBuffer buffer) {
    this.buffer = buffer;
  }

  @override
  void visitNode(AstNode node) {
    _writeNode(node);
    writeProperties(_computeProperties(node));
    indentLevel++;
    try {
      node.visitChildren(this);
    } finally {
      indentLevel--;
    }
  }

  /// Write a representation of the properties of the given [node] to the
  /// buffer.
  Map<String, Object> _computeProperties(AstNode node) {
    Map<String, Object> properties = HashMap<String, Object>();

    properties['name'] = _getName(node);
    if (node is ArgumentListImpl) {
      properties['static parameter types'] = node.correspondingStaticParameters;
    } else if (node is Annotation) {
      properties['element'] = node.element;
      properties['element annotation'] = node.elementAnnotation;
    } else if (node is BinaryExpression) {
      properties['static element'] = node.staticElement;
      properties['static type'] = node.staticType;
    } else if (node is ClassDeclaration) {
      properties['declaredElement'] = node.declaredElement;
      properties['abstract keyword'] = node.abstractKeyword;
    } else if (node is ClassTypeAlias) {
      properties['declaredElement'] = node.declaredElement;
      properties['abstract keyword'] = node.abstractKeyword;
    } else if (node is CompilationUnit) {
      properties['declaredElement'] = node.declaredElement;
    } else if (node is Configuration) {
      properties['uriSource'] = node.uriSource;
    } else if (node is ConstructorName) {
      properties['static element'] = node.staticElement;
    } else if (node is DeclaredIdentifier) {
      properties['element'] = node.declaredElement;
      properties['keyword'] = node.keyword;
    } else if (node is ExportDirective) {
      properties['element'] = node.element;
      properties['selectedSource'] = node.selectedSource;
      properties['uriSource'] = node.uriSource;
    } else if (node is FieldDeclaration) {
      properties['static keyword'] = node.staticKeyword;
    } else if (node is FormalParameter) {
      properties['declaredElement'] = node.declaredElement;
      if (node.isRequiredPositional) {
        properties['kind'] = 'required-positional';
      } else if (node.isRequiredNamed) {
        properties['kind'] = 'required-named';
      } else if (node.isOptionalPositional) {
        properties['kind'] = 'optional-positional';
      } else if (node.isOptionalNamed) {
        properties['kind'] = 'optional-named';
      } else {
        properties['kind'] = 'unknown kind';
      }
    } else if (node is FunctionDeclaration) {
      properties['declaredElement'] = node.declaredElement;
      properties['external keyword'] = node.externalKeyword;
      properties['property keyword'] = node.propertyKeyword;
    } else if (node is FunctionExpressionInvocation) {
      properties['static element'] = node.staticElement;
      properties['static invoke type'] = node.staticInvokeType;
      properties['static type'] = node.staticType;
    } else if (node is GenericFunctionType) {
      properties['type'] = node.type;
    } else if (node is ImportDirective) {
      properties['element'] = node.element;
      properties['selectedSource'] = node.selectedSource;
      properties['uriSource'] = node.uriSource;
    } else if (node is IndexExpression) {
      properties['static element'] = node.staticElement;
      properties['static type'] = node.staticType;
    } else if (node is InstanceCreationExpression) {
      properties['static type'] = node.staticType;
    } else if (node is LibraryDirective) {
      properties['element'] = node.element;
    } else if (node is MethodDeclaration) {
      properties['declaredElement'] = node.declaredElement;
      properties['external keyword'] = node.externalKeyword;
      properties['modifier keyword'] = node.modifierKeyword;
      properties['operator keyword'] = node.operatorKeyword;
      properties['property keyword'] = node.propertyKeyword;
    } else if (node is MethodInvocation) {
      properties['static invoke type'] = node.staticInvokeType;
      properties['static type'] = node.staticType;
    } else if (node is PartDirective) {
      properties['element'] = node.element;
      properties['uriSource'] = node.uriSource;
    } else if (node is PartOfDirective) {
      properties['element'] = node.element;
    } else if (node is PostfixExpression) {
      properties['static element'] = node.staticElement;
      properties['static type'] = node.staticType;
    } else if (node is PrefixExpression) {
      properties['static element'] = node.staticElement;
      properties['static type'] = node.staticType;
    } else if (node is RedirectingConstructorInvocation) {
      properties['static element'] = node.staticElement;
    } else if (node is SimpleIdentifier) {
      properties['static element'] = node.staticElement;
      properties['static type'] = node.staticType;
    } else if (node is SimpleStringLiteral) {
      properties['value'] = node.value;
    } else if (node is SuperConstructorInvocation) {
      properties['static element'] = node.staticElement;
    } else if (node is TypeAnnotation) {
      properties['type'] = node.type;
    } else if (node is VariableDeclarationList) {
      properties['keyword'] = node.keyword;
    } else if (node is Declaration) {
      properties['declaredElement'] = node.declaredElement;
    } else if (node is Expression) {
      properties['static type'] = node.staticType;
    } else if (node is FunctionBody) {
      properties['isAsynchronous'] = node.isAsynchronous;
      properties['isGenerator'] = node.isGenerator;
    } else if (node is Identifier) {
      properties['static element'] = node.staticElement;
      properties['static type'] = node.staticType;
    }

    return properties;
  }

  /// Return the name of the given [node], or `null` if the given node is not a
  /// declaration.
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
      var nameNode = node.name;
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
    } else if (node is TypeAnnotation) {
      return node.toSource();
    } else if (node is TypeParameter) {
      return node.name.name;
    } else if (node is VariableDeclaration) {
      return node.name.name;
    }
    return null;
  }

  /// Return a string containing a comma-separated list of the names of all of
  /// the variables in the given list of [variables].
  String _getNames(VariableDeclarationList variables) {
    var buffer = StringBuffer();
    var first = true;
    for (var variable in variables.variables) {
      if (first) {
        first = false;
      } else {
        buffer.write(', ');
      }
      buffer.write(variable.name.name);
    }
    return buffer.toString();
  }

  /// Write a representation of the given [node] to the buffer.
  void _writeNode(AstNode node) {
    indent();
    buffer.write(node.runtimeType);
    buffer.write(' <span style="color:gray">[');
    buffer.write(node.offset);
    buffer.write('..');
    buffer.write(node.offset + node.length - 1);
    buffer.write(']');
    if (node.isSynthetic) {
      buffer.write(' (synthetic)');
    }
    buffer.write('</span>');
    buffer.write('<br>');
  }
}
