// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'package:collection/collection.dart';

import '../../../utilities/extensions/ast.dart';
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
      // Don't propose an assist for super parameters and super parameters with
      // a default value because they can't be bound to a field.
      await tryReplacingParameter(file, builder, parameter, libraryElement2);
    }
  }

  static Future<void> tryReplacingParameter(
    String file,
    ChangeBuilder builder,
    FormalParameter parameter,
    LibraryElement libraryElement2,
  ) async {
    if (parameter is SuperFormalParameter) {
      return;
    }
    if (parameter is DefaultFormalParameter &&
        parameter.parameter is SuperFormalParameter) {
      return;
    }
    if (parameter is FieldFormalParameter) {
      return;
    }
    await _replaceParameterWithThis(file, builder, parameter, libraryElement2);
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
    var constructor = parameter.thisOrAncestorOfType<ConstructorDeclaration>();
    if (constructor == null) {
      // Not a constructor.
      return;
    }
    if (constructor.childEntities.any(
      (element) => element is RedirectingConstructorInvocation,
    )) {
      // A redirecting constructor.
      return;
    }
    if (constructor.factoryKeyword != null) {
      // A factory constructor.
      return;
    }
    var container = constructor.thisOrAncestorOfType<CompilationUnitMember>();
    if (container == null ||
        (container is! ClassDeclaration && container is! EnumDeclaration)) {
      // Not a class or enum.
      return;
    }
    if (container is ClassDeclaration &&
        container.members2.any(
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
    if (container is EnumDeclaration &&
        container.body.constants.any(
          (constant) => constant.name.lexeme == parameter.name?.lexeme,
        )) {
      // Parameter is already a constant.
      return;
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
        if (fixType != _FixType.noop) {
          builder.addSimpleReplacement(
            _replaceable(parameter),
            'this.${name.lexeme}',
          );
        }
        if (fixType == _FixType.replaceWithThisAndNewField) {
          builder.insertField(container, (builder) {
            var isFinal = constructor.constKeyword != null || parameter.isFinal;
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
      var fieldWithSameName = container.members2
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
        return _FixType.replaceWithThisAndNewField;
      }
    }
    return _FixType.replaceWithThisAndNewField;
  }
}

enum _FixType { replaceWithThis, replaceWithThisAndNewField, noop }
