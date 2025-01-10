// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/token.dart' show Token;
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/src/assumptions.dart';
import 'package:kernel/src/printer.dart';

import '../base/constant_context.dart';
import '../base/problems.dart' show unsupported;
import '../builder/builder.dart';
import '../builder/declaration_builders.dart';
import '../builder/inferable_type_builder.dart';
import '../codes/cfe_codes.dart';
import '../fragment/fragment.dart';
import '../source/source_class_builder.dart';
import '../source/source_enum_builder.dart';
import '../source/source_field_builder.dart';
import '../source/source_library_builder.dart';
import '../type_inference/type_inferrer.dart';
import 'body_builder.dart';
import 'body_builder_context.dart';

abstract class InferredType extends AuxiliaryType {
  Uri? get fileUri;
  int? get charOffset;

  InferredType._();

  factory InferredType.fromFieldInitializer(
          SourceFieldBuilder fieldBuilder, Token? initializerToken) =
      _ImplicitFieldTypeRoot;

  factory InferredType.fromFieldFragmentInitializer(
          FieldFragment fieldFragment, Token? initializerToken) =
      _ImplicitFieldFragmentTypeRoot;

  factory InferredType.fromInferableTypeUse(InferableTypeUse inferableTypeUse) =
      _InferredTypeUse;

  @override
  // Coverage-ignore(suite): Not run.
  Nullability get declaredNullability =>
      unsupported("declaredNullability", charOffset ?? -1, fileUri);

  @override
  // Coverage-ignore(suite): Not run.
  Nullability get nullability {
    unsupported("nullability", charOffset ?? -1, fileUri);
  }

  @override
  // Coverage-ignore(suite): Not run.
  DartType get nonTypeParameterBound {
    throw unsupported("nonTypeParameterBound", charOffset ?? -1, fileUri);
  }

  @override
  // Coverage-ignore(suite): Not run.
  bool get hasNonObjectMemberAccess {
    throw unsupported("hasNonObjectMemberAccess", charOffset ?? -1, fileUri);
  }

  @override
  // Coverage-ignore(suite): Not run.
  R accept<R>(DartTypeVisitor<R> v) {
    throw unsupported("accept", charOffset ?? -1, fileUri);
  }

  @override
  // Coverage-ignore(suite): Not run.
  R accept1<R, A>(DartTypeVisitor1<R, A> v, arg) {
    throw unsupported("accept1", charOffset ?? -1, fileUri);
  }

  @override
  // Coverage-ignore(suite): Not run.
  Never visitChildren(Visitor<dynamic> v) {
    unsupported("visitChildren", charOffset ?? -1, fileUri);
  }

  @override
  // Coverage-ignore(suite): Not run.
  InferredType withDeclaredNullability(Nullability nullability) {
    return unsupported("withNullability", charOffset ?? -1, fileUri);
  }

  @override
  // Coverage-ignore(suite): Not run.
  InferredType toNonNull() {
    return unsupported("toNonNullable", charOffset ?? -1, fileUri);
  }

  DartType inferType(ClassHierarchyBase hierarchy);

  DartType computeType(ClassHierarchyBase hierarchy);
}

class _ImplicitFieldTypeRoot extends InferredType {
  final SourceFieldBuilder fieldBuilder;

  Token? initializerToken;
  bool isStarted = false;

  _ImplicitFieldTypeRoot(this.fieldBuilder, this.initializerToken) : super._();

  @override
  // Coverage-ignore(suite): Not run.
  Uri get fileUri => fieldBuilder.fileUri;

  @override
  // Coverage-ignore(suite): Not run.
  int get charOffset => fieldBuilder.fileOffset;

  @override
  DartType inferType(ClassHierarchyBase hierarchy) {
    return fieldBuilder.inferType(hierarchy);
  }

  @override
  DartType computeType(ClassHierarchyBase hierarchy) {
    if (isStarted) {
      // Coverage-ignore-block(suite): Not run.
      fieldBuilder.libraryBuilder.addProblem(
          templateCantInferTypeDueToCircularity
              .withArguments(fieldBuilder.name),
          fieldBuilder.fileOffset,
          fieldBuilder.name.length,
          fieldBuilder.fileUri);
      DartType type = const InvalidType();
      fieldBuilder.type.registerInferredType(type);
      return type;
    }
    isStarted = true;
    DartType? inferredType;
    Builder? parent = fieldBuilder.parent;
    if (parent is SourceEnumBuilder &&
        parent.elementBuilders.contains(fieldBuilder)) {
      inferredType = parent.buildElement(
          fieldBuilder, parent.libraryBuilder.loader.coreTypes);
    }
    // Coverage-ignore(suite): Not run.
    else if (initializerToken != null) {
      InterfaceType? enclosingClassThisType = fieldBuilder.classBuilder == null
          ? null
          : fieldBuilder.libraryBuilder.loader.typeInferenceEngine.coreTypes
              .thisInterfaceType(fieldBuilder.classBuilder!.cls,
                  fieldBuilder.libraryBuilder.library.nonNullable);
      TypeInferrer typeInferrer = fieldBuilder
          .libraryBuilder.loader.typeInferenceEngine
          .createTopLevelTypeInferrer(
              fieldBuilder.fileUri,
              enclosingClassThisType,
              fieldBuilder.libraryBuilder,
              fieldBuilder.dataForTesting?.inferenceData);
      BodyBuilderContext bodyBuilderContext =
          fieldBuilder.createBodyBuilderContext();
      BodyBuilder bodyBuilder = fieldBuilder.libraryBuilder.loader
          .createBodyBuilderForField(
              fieldBuilder.libraryBuilder,
              bodyBuilderContext,
              fieldBuilder.declarationBuilder?.scope ??
                  fieldBuilder.libraryBuilder.scope,
              typeInferrer,
              fieldBuilder.fileUri);
      bodyBuilder.constantContext = fieldBuilder.isConst
          ? ConstantContext.inferred
          : ConstantContext.none;
      bodyBuilder.inFieldInitializer = true;
      bodyBuilder.inLateFieldInitializer = fieldBuilder.isLate;
      Expression initializer =
          bodyBuilder.parseFieldInitializer(initializerToken!);
      initializerToken = null;

      inferredType =
          typeInferrer.inferImplicitFieldType(bodyBuilder, initializer);
    } else {
      inferredType = const DynamicType();
    }
    return inferredType;
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('<implicit-field-type:$fieldBuilder>');
  }

  @override
  // Coverage-ignore(suite): Not run.
  bool equals(Object other, Assumptions? assumptions) {
    if (identical(this, other)) return true;
    return other is _ImplicitFieldTypeRoot &&
        fieldBuilder == other.fieldBuilder;
  }

  @override
  int get hashCode => fieldBuilder.hashCode;

  @override
  String toString() => 'ImplicitFieldType(${toStringInternal()})';
}

class _ImplicitFieldFragmentTypeRoot extends InferredType {
  final FieldFragment _fieldFragment;

  Token? initializerToken;
  bool isStarted = false;

  _ImplicitFieldFragmentTypeRoot(this._fieldFragment, this.initializerToken)
      : super._();

  @override
  // Coverage-ignore(suite): Not run.
  Uri get fileUri => _fieldFragment.fileUri;

  @override
  // Coverage-ignore(suite): Not run.
  int get charOffset => _fieldFragment.nameOffset;

  @override
  DartType inferType(ClassHierarchyBase hierarchy) {
    return _fieldFragment.inferType(hierarchy);
  }

  @override
  DartType computeType(ClassHierarchyBase hierarchy) {
    if (isStarted) {
      _fieldFragment.builder.libraryBuilder.addProblem(
          templateCantInferTypeDueToCircularity
              .withArguments(_fieldFragment.name),
          _fieldFragment.nameOffset,
          _fieldFragment.name.length,
          _fieldFragment.fileUri);
      DartType type = const InvalidType();
      _fieldFragment.type.registerInferredType(type);
      return type;
    }
    isStarted = true;
    DartType? inferredType;
    SourceLibraryBuilder libraryBuilder = _fieldFragment.builder.libraryBuilder;
    DeclarationBuilder? declarationBuilder =
        _fieldFragment.builder.declarationBuilder;
    if (declarationBuilder is SourceEnumBuilder &&
        declarationBuilder.elementBuilders.contains(_fieldFragment.builder)) {
      // Coverage-ignore-block(suite): Not run.
      inferredType = declarationBuilder.buildElement(
          // TODO(johnniwinther): Create a EnumElementFragment to avoid this.
          _fieldFragment.builder as SourceFieldBuilder,
          libraryBuilder.loader.coreTypes);
    } else if (initializerToken != null) {
      InterfaceType? enclosingClassThisType = declarationBuilder
              is SourceClassBuilder
          ? libraryBuilder.loader.typeInferenceEngine.coreTypes
              .thisInterfaceType(
                  declarationBuilder.cls, libraryBuilder.library.nonNullable)
          : null;
      TypeInferrer typeInferrer =
          libraryBuilder.loader.typeInferenceEngine.createTopLevelTypeInferrer(
              _fieldFragment.fileUri,
              enclosingClassThisType,
              libraryBuilder,
              _fieldFragment
                  .builder
                  .dataForTesting
                  // Coverage-ignore(suite): Not run.
                  ?.inferenceData);
      BodyBuilderContext bodyBuilderContext =
          _fieldFragment.createBodyBuilderContext();
      BodyBuilder bodyBuilder = libraryBuilder.loader.createBodyBuilderForField(
          libraryBuilder,
          bodyBuilderContext,
          declarationBuilder?.scope ?? libraryBuilder.scope,
          typeInferrer,
          _fieldFragment.fileUri);
      bodyBuilder.constantContext = _fieldFragment.modifiers.isConst
          ? ConstantContext.inferred
          : ConstantContext.none;
      bodyBuilder.inFieldInitializer = true;
      bodyBuilder.inLateFieldInitializer = _fieldFragment.modifiers.isLate;
      Expression initializer =
          bodyBuilder.parseFieldInitializer(initializerToken!);
      initializerToken = null;

      inferredType =
          typeInferrer.inferImplicitFieldType(bodyBuilder, initializer);
    } else {
      inferredType = const DynamicType();
    }
    return inferredType;
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('<implicit-field-type:$_fieldFragment>');
  }

  @override
  // Coverage-ignore(suite): Not run.
  bool equals(Object other, Assumptions? assumptions) {
    if (identical(this, other)) return true;
    return other is _ImplicitFieldFragmentTypeRoot &&
        _fieldFragment == other._fieldFragment;
  }

  @override
  int get hashCode => _fieldFragment.hashCode;

  @override
  String toString() => 'ImplicitFieldType(${toStringInternal()})';
}

class _InferredTypeUse extends InferredType {
  final InferableTypeUse inferableTypeUse;

  _InferredTypeUse(this.inferableTypeUse) : super._();

  @override
  // Coverage-ignore(suite): Not run.
  int? get charOffset => inferableTypeUse.typeBuilder.charOffset;

  @override
  // Coverage-ignore(suite): Not run.
  Uri? get fileUri => inferableTypeUse.typeBuilder.fileUri;

  @override
  // Coverage-ignore(suite): Not run.
  DartType computeType(ClassHierarchyBase hierarchy) {
    return inferType(hierarchy);
  }

  @override
  // Coverage-ignore(suite): Not run.
  DartType inferType(ClassHierarchyBase hierarchy) {
    return inferableTypeUse.inferType(hierarchy);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('<inferred-type:${inferableTypeUse.typeBuilder}>');
  }

  @override
  // Coverage-ignore(suite): Not run.
  bool equals(Object other, Assumptions? assumptions) {
    if (identical(this, other)) return true;
    return other is _InferredTypeUse &&
        inferableTypeUse.typeBuilder == other.inferableTypeUse.typeBuilder;
  }

  @override
  int get hashCode => inferableTypeUse.typeBuilder.hashCode;

  @override
  String toString() => 'InferredTypeUse(${toStringInternal()})';
}
