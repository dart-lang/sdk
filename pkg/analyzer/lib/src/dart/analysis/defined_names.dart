// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/src/dart/ast/ast.dart';

/// Compute the [DefinedNames] for the given [unit].
DefinedNames computeDefinedNames(CompilationUnit unit) {
  DefinedNames names = DefinedNames();

  void appendName(Set<String> names, Token? token) {
    var lexeme = token?.lexeme;
    if (lexeme != null && lexeme.isNotEmpty) {
      names.add(lexeme);
    }
  }

  void appendClassMemberName(ClassMember member) {
    if (member is MethodDeclaration) {
      appendName(names.classMemberNames, member.name);
    } else if (member is FieldDeclaration) {
      for (VariableDeclaration field in member.fields.variables) {
        appendName(names.classMemberNames, field.name);
      }
    }
  }

  void appendTopLevelName(CompilationUnitMember member) {
    switch (member) {
      case ClassDeclaration():
        appendName(names.topLevelNames, member.namePart.typeName);
        if (member.body case BlockClassBody body) {
          body.members.forEach(appendClassMemberName);
        }
      case EnumDeclaration():
        appendName(names.topLevelNames, member.namePart.typeName);
        for (var constant in member.body.constants) {
          appendName(names.classMemberNames, constant.name);
        }
        member.body.members.forEach(appendClassMemberName);
      case ExtensionDeclaration():
        appendName(names.topLevelNames, member.name);
        member.body.members.forEach(appendClassMemberName);
      case ExtensionTypeDeclaration():
        appendName(names.topLevelNames, member.primaryConstructor.typeName);
        if (member.body case BlockClassBody body) {
          body.members.forEach(appendClassMemberName);
        }
      case FunctionDeclaration():
        appendName(names.topLevelNames, member.name);
      case MixinDeclaration():
        appendName(names.topLevelNames, member.name);
        member.body.members.forEach(appendClassMemberName);
      case TopLevelVariableDeclaration():
        for (VariableDeclaration variable in member.variables.variables) {
          appendName(names.topLevelNames, variable.name);
        }
      case TypeAlias():
        appendName(names.topLevelNames, member.name);
    }
  }

  unit.declarations.forEach(appendTopLevelName);
  return names;
}

/// Defined top-level and class member names.
class DefinedNames {
  final Set<String> topLevelNames = <String>{};
  final Set<String> classMemberNames = <String>{};
}
