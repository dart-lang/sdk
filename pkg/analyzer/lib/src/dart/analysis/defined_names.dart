// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
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
    if (member is NamedCompilationUnitMember) {
      switch (member) {
        case ClassDeclarationImpl():
          if (useDeclaringConstructorsAst) {
            appendName(names.topLevelNames, member.namePart.typeName);
            member.body.members.forEach(appendClassMemberName);
          } else {
            appendName(names.topLevelNames, member.name);
            member.members.forEach(appendClassMemberName);
          }
        case EnumDeclaration():
          if (useDeclaringConstructorsAst) {
            appendName(names.topLevelNames, member.namePart.typeName);
            for (var constant in member.body.constants) {
              appendName(names.classMemberNames, constant.name);
            }
            member.body.members.forEach(appendClassMemberName);
          } else {
            appendName(names.topLevelNames, member.name);
            for (var constant in member.constants) {
              appendName(names.classMemberNames, constant.name);
            }
            member.members.forEach(appendClassMemberName);
          }
        case ExtensionTypeDeclarationImpl():
          if (useDeclaringConstructorsAst) {
            appendName(names.topLevelNames, member.primaryConstructor.typeName);
            member.body.members.forEach(appendClassMemberName);
          } else {
            appendName(names.topLevelNames, member.name);
            member.members.forEach(appendClassMemberName);
          }
        case MixinDeclaration():
          appendName(names.topLevelNames, member.name);
          if (useDeclaringConstructorsAst) {
            member.body.members.forEach(appendClassMemberName);
          } else {
            member.members.forEach(appendClassMemberName);
          }
        default:
          appendName(names.topLevelNames, member.name);
      }
    } else if (member is TopLevelVariableDeclaration) {
      for (VariableDeclaration variable in member.variables.variables) {
        appendName(names.topLevelNames, variable.name);
      }
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
