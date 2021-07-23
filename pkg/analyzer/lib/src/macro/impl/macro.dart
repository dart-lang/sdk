// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart' as ast;
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/src/dart/ast/ast.dart' as ast;
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/macro/api/code.dart';
import 'package:analyzer/src/macro/api/macro.dart';

class ClassDeclarationBuilderImpl extends DeclarationBuilderImpl
    implements ClassDeclarationBuilder {
  final DeclarationCollector _collector;
  final ast.ClassDeclarationImpl node;

  ClassDeclarationBuilderImpl(this._collector, this.node);

  @override
  void addToClass(Declaration declaration) {
    // TODO(scheglov) feature set
    // TODO(scheglov) throw if errors?
    var parseResult = parseString(
      content: 'class ${node.name.name} { $declaration }',
    );
    var parsedDeclarations = parseResult.unit.declarations;
    var parsedClass = parsedDeclarations.single as ast.ClassDeclaration;
    var parsedMember = parsedClass.members.single;
    _resetOffsets(parsedMember);

    node.members.add(parsedMember);
    _collector._add(parsedMember, declaration);
  }

  /// We parsed [node] in the context of some synthetic code string, its
  /// current offsets are meaningless. So, we reset them for now.
  static void _resetOffsets(ast.AstNode node) {
    for (Token? t = node.beginToken;
        t != null && t != node.endToken;
        t = t.next) {
      t.offset = -1;
    }
  }
}

class DeclarationBuilderImpl implements DeclarationBuilder {
  @override
  void addToLibrary(Declaration declaration) {
    // TODO: implement addToLibrary
  }

  @override
  Code typeAnnotationCode(ast.TypeAnnotation node) {
    return Fragment(node.toSource());
  }
}

class DeclarationCollector {
  final Map<ast.AstNode, _CollectedDeclaration> _declarations = {};
  int _nextId = 0;

  /// Elements for nodes in [_declarations] were built.
  /// Move information from [_CollectedDeclaration] into elements.
  void updateElements() {
    for (var entry in _declarations.entries) {
      var node = entry.key;
      if (node is ast.Declaration) {
        var element = node.declaredElement;
        if (element is HasElementMacro) {
          (element as HasElementMacro).macro = ElementMacro(
            entry.value.id,
            entry.value.declaration.code,
          );
        }
      }
    }
  }

  void _add(ast.AstNode node, Declaration declaration) {
    _declarations[node] = _CollectedDeclaration(_nextId++, declaration);
  }
}

class _CollectedDeclaration {
  final int id;
  final Declaration declaration;

  _CollectedDeclaration(this.id, this.declaration);
}
