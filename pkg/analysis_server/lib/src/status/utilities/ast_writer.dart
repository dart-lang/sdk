// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/status/utilities/tree_writer.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/src/dart/ast/ast.dart';

/// A visitor that will produce an HTML representation of an AST structure.
class AstWriter extends UnifyingAstVisitor<void> with TreeWriter {
  @override
  final StringBuffer buffer;

  /// Initialize a newly created element writer to write the HTML representation
  /// of visited nodes on the given [buffer].
  AstWriter(this.buffer);

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
    return {
      'name': ?_getName(node),
      if (node is ArgumentListImpl)
        'corresponding static parameters': ?node.correspondingStaticParameters
      else if (node is Annotation) ...{
        'element': ?node.element,
        'element annotation': ?node.elementAnnotation,
      } else if (node is BinaryExpression) ...{
        'element': ?node.element,
        'static type': ?node.staticType,
      } else if (node is ClassDeclaration) ...{
        'declared fragment': ?node.declaredFragment,
        'abstract keyword': ?node.abstractKeyword,
      } else if (node is ClassTypeAlias) ...{
        'declared fragment': ?node.declaredFragment,
        'abstract keyword': ?node.abstractKeyword,
      } else if (node is CompilationUnit)
        'declared fragment': ?node.declaredFragment
      else if (node is Configuration)
        'uriSource': ?node.resolvedUri
      else if (node is ConstructorName)
        'element': ?node.element
      else if (node is DeclaredIdentifier) ...{
        'element': ?node.declaredFragment?.element,
        'keyword': ?node.keyword,
      } else if (node is ExportDirective)
        'library export': ?node.libraryExport
      else if (node is FieldDeclaration)
        'static keyword': ?node.staticKeyword
      else if (node is FormalParameter) ...{
        'declared fragment': ?node.declaredFragment,
        if (node.isRequiredPositional)
          'kind': 'required-positional'
        else if (node.isRequiredNamed)
          'kind': 'required-named'
        else if (node.isOptionalPositional)
          'kind': 'optional-positional'
        else if (node.isOptionalNamed)
          'kind': 'optional-named'
        else
          'kind': 'unknown kind',
      } else if (node is FunctionDeclaration) ...{
        'declared fragment': ?node.declaredFragment,
        'external keyword': ?node.externalKeyword,
        'property keyword': ?node.propertyKeyword,
      } else if (node is FunctionExpressionInvocation) ...{
        'element': ?node.element,
        'static invoke type': ?node.staticInvokeType,
        'static type': ?node.staticType,
      } else if (node is GenericFunctionType)
        'type': ?node.type
      else if (node is ImportDirective)
        'library import': ?node.libraryImport
      else if (node is IndexExpression) ...{
        'element': ?node.element,
        'static type': ?node.staticType,
      } else if (node is InstanceCreationExpression)
        'static type': ?node.staticType
      else if (node is LibraryDirective)
        'element': ?node.element
      else if (node is MethodDeclaration) ...{
        'declared fragment': ?node.declaredFragment,
        'external keyword': ?node.externalKeyword,
        'modifier keyword': ?node.modifierKeyword,
        'operator keyword': ?node.operatorKeyword,
        'property keyword': ?node.propertyKeyword,
      } else if (node is MethodInvocation) ...{
        'static invoke type': ?node.staticInvokeType,
        'static type': ?node.staticType,
      } else if (node is PartDirective)
        'fragment include': ?node.partInclude
      else if (node is PostfixExpression) ...{
        'element': ?node.element,
        'static type': ?node.staticType,
      } else if (node is PrefixExpression) ...{
        'element': ?node.element,
        'static type': ?node.staticType,
      } else if (node is RedirectingConstructorInvocation)
        'element': ?node.element
      else if (node is SimpleIdentifier) ...{
        'element': ?node.element,
        'static type': ?node.staticType,
      } else if (node is SimpleStringLiteral)
        'value': node.value
      else if (node is SuperConstructorInvocation)
        'element': ?node.element
      else if (node is TypeAnnotation)
        'type': ?node.type
      else if (node is VariableDeclarationList)
        'keyword': ?node.keyword
      else if (node is Declaration)
        'declared fragment': ?node.declaredFragment
      else if (node is Expression)
        'static type': ?node.staticType
      else if (node is FunctionBody) ...{
        'is asynchronous': node.isAsynchronous,
        'is generator': node.isGenerator,
      } else if (node is Identifier) ...{
        'element': ?node.element,
        'static type': ?node.staticType,
      },
    };
  }

  /// Return the name of the given [node], or `null` if the given node is not a
  /// declaration.
  String? _getName(AstNode node) {
    if (node is ClassTypeAlias) {
      return node.name.lexeme;
    } else if (node is ClassDeclaration) {
      return node.namePart.typeName.lexeme;
    } else if (node is ConstructorDeclaration) {
      var name = node.name;
      var typeNameOrNew = node.newKeyword?.lexeme ?? node.typeName!.name;
      if (name == null) {
        return typeNameOrNew;
      } else {
        return '$typeNameOrNew.${name.lexeme}';
      }
    } else if (node is ConstructorName) {
      return node.toSource();
    } else if (node is FieldDeclaration) {
      return _getNames(node.fields);
    } else if (node is FunctionDeclaration) {
      return node.name.lexeme;
    } else if (node is FunctionTypeAlias) {
      return node.name.lexeme;
    } else if (node is Identifier) {
      return node.name;
    } else if (node is MethodDeclaration) {
      return node.name.lexeme;
    } else if (node is TopLevelVariableDeclaration) {
      return _getNames(node.variables);
    } else if (node is TypeAnnotation) {
      return node.toSource();
    } else if (node is TypeParameter) {
      return node.name.lexeme;
    } else if (node is VariableDeclaration) {
      return node.name.lexeme;
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
      buffer.write(variable.name.lexeme);
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
