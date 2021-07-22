// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart' as ast;
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/src/dart/ast/ast.dart' as ast;
import 'package:analyzer/src/macro/api/code.dart';
import 'package:analyzer/src/macro/api/macro.dart';

class ClassDeclarationBuilderImpl extends DeclarationBuilderImpl
    implements ClassDeclarationBuilder {
  final ast.ClassDeclarationImpl node;

  ClassDeclarationBuilderImpl(this.node);

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
