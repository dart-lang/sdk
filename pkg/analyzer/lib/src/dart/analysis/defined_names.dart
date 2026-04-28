// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/src/dart/ast/ast.dart';

/// Compute the [DefinedNames] for the given [unit].
DefinedNames computeDefinedNames(CompilationUnitImpl unit) {
  DefinedNames names = DefinedNames();

  void appendName(Set<String> names, Token? token) {
    var lexeme = token?.lexeme;
    if (lexeme != null && lexeme.isNotEmpty) {
      names.add(lexeme);
    }
  }

  void appendClassMemberName(ClassMemberImpl member) {
    if (member is MethodDeclarationImpl) {
      appendName(names.classMemberNames, member.name);
    } else if (member is FieldDeclarationImpl) {
      for (var field in member.fields.variables) {
        appendName(names.classMemberNames, field.name);
      }
    }
  }

  void appendDeclaringFormalParameterNames(
    PrimaryConstructorDeclarationImpl constructor, {
    bool isExtensionType = false,
  }) {
    var parameters = constructor.formalParameters.parameters;
    for (var i = 0; i < parameters.length; i++) {
      var parameter = parameters[i];
      var isRepresentation =
          isExtensionType && i == 0 && parameter is RegularFormalParameterImpl;
      if (parameter.finalOrVarKeyword != null || isRepresentation) {
        appendName(names.classMemberNames, parameter.name);
      }
    }
  }

  void appendTopLevelName(CompilationUnitMemberImpl member) {
    switch (member) {
      case ClassDeclarationImpl():
        appendName(names.topLevelNames, member.namePart.typeName);
        if (member.namePart
            case PrimaryConstructorDeclarationImpl constructor) {
          appendDeclaringFormalParameterNames(constructor);
        }
        member.body.members.forEach(appendClassMemberName);
      case EnumDeclarationImpl():
        appendName(names.topLevelNames, member.namePart.typeName);
        if (member.namePart
            case PrimaryConstructorDeclarationImpl constructor) {
          appendDeclaringFormalParameterNames(constructor);
        }
        for (var constant in member.body.constants) {
          appendName(names.classMemberNames, constant.name);
        }
        member.body.members.forEach(appendClassMemberName);
      case ExtensionDeclarationImpl():
        appendName(names.topLevelNames, member.name);
        member.body.members.forEach(appendClassMemberName);
      case ExtensionTypeDeclarationImpl():
        appendName(names.topLevelNames, member.primaryConstructor.typeName);
        appendDeclaringFormalParameterNames(
          member.primaryConstructor,
          isExtensionType: true,
        );
        member.body.members.forEach(appendClassMemberName);
      case FunctionDeclarationImpl():
        appendName(names.topLevelNames, member.name);
      case MixinDeclarationImpl():
        appendName(names.topLevelNames, member.name);
        member.body.members.forEach(appendClassMemberName);
      case TopLevelVariableDeclarationImpl():
        for (var variable in member.variables.variables) {
          appendName(names.topLevelNames, variable.name);
        }
      case TypeAliasImpl():
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
