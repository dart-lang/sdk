// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart' as ast;
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/src/dart/ast/ast.dart' as ast;
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/macro/api/code.dart';
import 'package:analyzer/src/macro/api/macro.dart';
import 'package:analyzer/src/summary2/informative_data.dart';

class ClassDeclarationBuilderImpl extends DeclarationBuilderImpl
    implements ClassDeclarationBuilder {
  final DeclarationCollector _collector;
  final ast.ClassDeclarationImpl node;

  ClassDeclarationBuilderImpl(this._collector, this.node);

  @override
  void addToClass(Declaration declaration) {
    var declarationCode = declaration.code.trim();

    // TODO(scheglov) feature set
    // TODO(scheglov) throw if errors?
    var parseResult = parseString(
      content: 'class ${node.name.name} { $declarationCode }',
    );
    var parsedDeclarations = parseResult.unit.declarations;
    var parsedClass = parsedDeclarations.single as ast.ClassDeclaration;
    var parsedMember = parsedClass.members.single;
    _rebaseOffsets(parsedMember);

    node.members.add(parsedMember);
    _collector._add(parsedMember, declaration);
  }

  /// We parsed [node] in the context of some synthetic code string, its
  /// current offsets only have meaning relative to the begin offset of the
  /// [node]. So, we update offsets accordingly.
  static void _rebaseOffsets(ast.AstNode node) {
    var baseOffset = node.offset;
    for (Token? t = node.beginToken;
        t != null && t != node.endToken;
        t = t.next) {
      t.offset -= baseOffset;
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
        if (element is HasMacroGenerationData) {
          var collectedDeclaration = entry.value;
          (element as HasMacroGenerationData).macro = MacroGenerationData(
            collectedDeclaration.id,
            collectedDeclaration.declaration.code,
            collectedDeclaration.informative,
          );
        }
      }
    }
  }

  void _add(ast.AstNode node, Declaration declaration) {
    _declarations[node] = _CollectedDeclaration(
      _nextId++,
      declaration,
      writeDeclarationInformative(node),
    );
  }
}

class _CollectedDeclaration {
  final int id;
  final Declaration declaration;
  final Uint8List informative;

  _CollectedDeclaration(
    this.id,
    this.declaration,
    this.informative,
  );
}
