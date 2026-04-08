// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'package:collection/collection.dart';

import 'create_constructor.dart';

/// Binds a constructor parameter to a newly created field.
///
/// This assist is useful for simplifying constructor declarations by
/// automatically converting a regular parameter into a `this.` field formal
/// parameter and declaring the corresponding field. This matches a workflow
/// with the [CreateConstructor] assist.
class BindToField extends ResolvedCorrectionProducer {
  BindToField({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  AssistKind get assistKind => DartAssistKind.bindToField;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var parameter = node.thisOrAncestorOfType<FormalParameter>();
    if (parameter != null) {
      if (parameter is DefaultFormalParameter) {
        var separator = parameter.separator;
        if (separator != null && node.offset >= separator.offset) {
          // Don't propose the assist if the selection is inside the default
          // value.
          return;
        }
      }
      await tryReplacingParameter(file, builder, parameter, libraryElement2);
    }
  }

  static Future<void> tryReplacingParameter(
    String file,
    ChangeBuilder builder,
    FormalParameter parameter,
    LibraryElement libraryElement2,
  ) async {
    if (parameter is SuperFormalParameter ||
        (parameter is DefaultFormalParameter &&
            parameter.parameter is SuperFormalParameter)) {
      // Don't propose the assist for super parameters because they can't be
      // bound to a field.
      return;
    }
    if (parameter is FieldFormalParameter) {
      // Don't propose the assist if the parameter is already a field formal
      // parameter.
      return;
    }
    await _replaceParameterWithThis(file, builder, parameter, libraryElement2);
  }

  static (
    List<ConstructorInitializer> initializers,
    Token? factoryKeyword,
    Token? constKeyword,
    CompilationUnitMember? container,
  )?
  _constructorParts(FormalParameter parameter) {
    var constructor = parameter.thisOrAncestorOfType<ConstructorDeclaration>();
    if (constructor != null) {
      var container = constructor.thisOrAncestorOfType<CompilationUnitMember>();
      return (
        constructor.initializers,
        constructor.factoryKeyword,
        constructor.constKeyword,
        container,
      );
    }
    var primaryConstructor = parameter
        .thisOrAncestorOfType<PrimaryConstructorDeclaration>();
    if (primaryConstructor != null) {
      var body = primaryConstructor.body;
      var container = primaryConstructor
          .thisOrAncestorOfType<CompilationUnitMember>();
      return (
        body?.initializers ?? [],
        null as Token?,
        primaryConstructor.constKeyword,
        container,
      );
    }
    return null;
  }

  static SourceRange _replaceable(FormalParameter parameter) {
    return switch (parameter) {
      SimpleFormalParameter() => range.startEnd(
        parameter.type ?? parameter.keyword ?? parameter.name!,
        parameter,
      ),
      DefaultFormalParameter() => _replaceable(parameter.parameter),
      FunctionTypedFormalParameter() => range.node(parameter),
      // Should not happen, as these are excluded, but better to not crash.
      FieldFormalParameter() || SuperFormalParameter() => range.node(parameter),
    };
  }

  static Future<void> _replaceParameterWithThis(
    String file,
    ChangeBuilder builder,
    FormalParameter parameter,
    LibraryElement libraryElement2,
  ) async {
    var constructorParts = _constructorParts(parameter);
    if (constructorParts == null) {
      return;
    }
    var (initializers, factoryKeyword, constKeyword, container) =
        constructorParts;
    if (initializers.any(
      (element) => element is RedirectingConstructorInvocation,
    )) {
      // A redirecting constructor.
      return;
    }
    if (factoryKeyword != null) {
      // A factory constructor.
      return;
    }
    if (container == null ||
        (container is! ClassDeclaration && container is! EnumDeclaration)) {
      // Not a class or enum.
      return;
    }
    if (container is ClassDeclaration &&
        container.body.members.any(
          (member) => switch (member) {
            ConstructorDeclaration() => false,
            // Bind the parameter to the existing field
            FieldDeclaration() => false,
            MethodDeclaration() => member.name.lexeme == parameter.name?.lexeme,
            PrimaryConstructorBody() => false,
          },
        )) {
      // Parameter is already a method.
      return;
    }
    if (container is EnumDeclaration) {
      if (container.body.constants.any(
        (constant) => constant.name.lexeme == parameter.name?.lexeme,
      )) {
        // Parameter is already a constant.
        return;
      }
    }

    await builder.addDartFileEdit(file, (builder) {
      var name = parameter.name;
      if (name != null) {
        DartType? type = parameter.declaredFragment?.element.type;
        var fixType = _whetherToCreateNewField(
          container,
          parameter,
          type,
          libraryElement2,
        );
        if (fixType == _FixType.addVar) {
          builder.addSimpleInsertion(parameter.offset, 'var ');
          return;
        }
        if (fixType != _FixType.noop) {
          builder.addSimpleReplacement(
            _replaceable(parameter),
            'this.${name.lexeme}',
          );
        }
        if (fixType == _FixType.replaceWithThisAndNewField) {
          builder.insertField(container, (builder) {
            var isFinal = constKeyword != null || parameter.isFinal;
            builder.writeFieldDeclaration(
              name.lexeme,
              isFinal: isFinal,
              nameGroupName: 'NAME',
              type: isFinal && type is DynamicType ? null : type,
              typeGroupName: 'TYPE',
            );
          });
        }
      }
    });
  }

  static _FixType _whetherToCreateNewField(
    CompilationUnitMember container,
    FormalParameter parameter,
    DartType? type,
    LibraryElement libraryElement2,
  ) {
    if (container is ClassDeclaration) {
      var fieldWithSameName = container.body.members
          .whereType<FieldDeclaration>()
          .map(
            (member) => member.fields.variables.firstWhereOrNull(
              (variable) => variable.name.lexeme == parameter.name?.lexeme,
            ),
          )
          .firstOrNull;
      if (fieldWithSameName != null) {
        var fieldType = fieldWithSameName.declaredFragment?.element.type;
        if (type != null && fieldType != null) {
          if (libraryElement2.typeSystem.isAssignableTo(type, fieldType)) {
            return _FixType.replaceWithThis;
          } else {
            return _FixType.noop;
          }
        } else {
          return _FixType.replaceWithThis;
        }
      } else {
        var declaration = parameter
            .thisOrAncestorOfType<PrimaryConstructorDeclaration>();
        if (declaration != null) {
          return _FixType.addVar;
        }
        return _FixType.replaceWithThisAndNewField;
      }
    }
    return _FixType.replaceWithThisAndNewField;
  }
}

enum _FixType { replaceWithThis, replaceWithThisAndNewField, addVar, noop }
