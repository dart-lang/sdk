// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.implicit_type;

import 'package:_fe_analyzer_shared/src/scanner/token.dart' show Token;

import 'package:kernel/ast.dart' hide MapEntry;

import 'package:kernel/src/assumptions.dart';
import 'package:kernel/src/legacy_erasure.dart';
import 'package:kernel/src/printer.dart';

import '../builder/field_builder.dart';
import '../constant_context.dart';
import '../fasta_codes.dart';
import '../problems.dart' show unsupported;
import '../type_inference/type_inferrer.dart';
import '../type_inference/type_schema.dart';
import 'body_builder.dart';

abstract class ImplicitFieldType extends DartType {
  SourceFieldBuilder get fieldBuilder;

  ImplicitFieldType._();

  factory ImplicitFieldType(
          SourceFieldBuilder fieldBuilder, Token initializerToken) =
      _ImplicitFieldTypeRoot;

  @override
  Nullability get declaredNullability => unsupported(
      "declaredNullability", fieldBuilder.charOffset, fieldBuilder.fileUri);

  @override
  Nullability get nullability =>
      unsupported("nullability", fieldBuilder.charOffset, fieldBuilder.fileUri);

  @override
  R accept<R>(DartTypeVisitor<R> v) {
    throw unsupported("accept", fieldBuilder.charOffset, fieldBuilder.fileUri);
  }

  @override
  R accept1<R, A>(DartTypeVisitor1<R, A> v, arg) {
    throw unsupported("accept1", fieldBuilder.charOffset, fieldBuilder.fileUri);
  }

  @override
  visitChildren(Visitor<Object> v) {
    unsupported("visitChildren", fieldBuilder.charOffset, fieldBuilder.fileUri);
  }

  @override
  ImplicitFieldType withDeclaredNullability(Nullability nullability) {
    return unsupported(
        "withNullability", fieldBuilder.charOffset, fieldBuilder.fileUri);
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('<implicit-field-type:$fieldBuilder>');
  }

  void addOverride(ImplicitFieldType other);

  DartType checkInferred(DartType type);

  @override
  bool operator ==(Object other) => equals(other, null);

  @override
  bool equals(Object other, Assumptions assumptions) {
    if (identical(this, other)) return true;
    return other is ImplicitFieldType && fieldBuilder == other.fieldBuilder;
  }

  @override
  int get hashCode => fieldBuilder.hashCode;

  DartType inferType();

  DartType computeType();
}

class _ImplicitFieldTypeRoot extends ImplicitFieldType {
  final SourceFieldBuilder fieldBuilder;
  List<ImplicitFieldType> _overriddenFields;
  Token initializerToken;
  bool isStarted = false;

  _ImplicitFieldTypeRoot(this.fieldBuilder, this.initializerToken) : super._();

  DartType inferType() {
    return fieldBuilder.inferType();
  }

  DartType computeType() {
    if (isStarted) {
      fieldBuilder.library.addProblem(
          templateCantInferTypeDueToCircularity
              .withArguments(fieldBuilder.name),
          fieldBuilder.charOffset,
          fieldBuilder.name.length,
          fieldBuilder.fileUri);
      return fieldBuilder.fieldType = const InvalidType();
    }
    isStarted = true;
    DartType inferredType;
    if (_overriddenFields != null) {
      for (ImplicitFieldType overridden in _overriddenFields) {
        DartType overriddenType = overridden.inferType();
        if (!fieldBuilder.library.isNonNullableByDefault) {
          overriddenType = legacyErasure(overriddenType);
        }
        if (inferredType == null) {
          inferredType = overriddenType;
        } else if (inferredType != overriddenType) {
          inferredType = const InvalidType();
        }
      }
      return inferredType;
    } else if (initializerToken != null) {
      InterfaceType enclosingClassThisType = fieldBuilder.classBuilder == null
          ? null
          : fieldBuilder.library.loader.typeInferenceEngine.coreTypes
              .thisInterfaceType(fieldBuilder.classBuilder.cls,
                  fieldBuilder.library.library.nonNullable);
      TypeInferrerImpl typeInferrer = fieldBuilder
          .library.loader.typeInferenceEngine
          .createTopLevelTypeInferrer(
              fieldBuilder.fileUri,
              enclosingClassThisType,
              fieldBuilder.library,
              fieldBuilder.dataForTesting?.inferenceData);
      BodyBuilder bodyBuilder = fieldBuilder.library.loader
          .createBodyBuilderForField(fieldBuilder, typeInferrer);
      bodyBuilder.constantContext = fieldBuilder.isConst
          ? ConstantContext.inferred
          : ConstantContext.none;
      bodyBuilder.inFieldInitializer = true;
      bodyBuilder.inLateFieldInitializer = fieldBuilder.isLate;
      Expression initializer =
          bodyBuilder.parseFieldInitializer(initializerToken);
      initializerToken = null;

      ExpressionInferenceResult result = typeInferrer.inferExpression(
          initializer, const UnknownType(), true,
          isVoidAllowed: true);
      inferredType = typeInferrer.inferDeclarationType(result.inferredType);
    } else {
      inferredType = const DynamicType();
    }
    return inferredType;
  }

  void addOverride(ImplicitFieldType other) {
    _overriddenFields ??= [];
    _overriddenFields.add(other);
  }

  DartType checkInferred(DartType type) {
    if (_overriddenFields != null) {
      for (ImplicitFieldType overridden in _overriddenFields) {
        DartType overriddenType = overridden.inferType();
        if (!fieldBuilder.library.isNonNullableByDefault) {
          overriddenType = legacyErasure(overriddenType);
        }
        if (type != overriddenType) {
          String name = fieldBuilder.fullNameForErrors;
          fieldBuilder.classBuilder.addProblem(
              templateCantInferTypeDueToNoCombinedSignature.withArguments(name),
              fieldBuilder.charOffset,
              name.length,
              wasHandled: true);
          return const InvalidType();
        }
      }
    }
    return type;
  }

  @override
  String toString() => 'ImplicitFieldType(${toStringInternal()})';
}
