// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/type_environment.dart';

import '../../base/identifiers.dart';
import '../../base/name_space.dart';
import '../../builder/constructor_reference_builder.dart';
import '../../builder/formal_parameter_builder.dart';
import '../../builder/metadata_builder.dart';
import '../../builder/type_builder.dart';
import '../../fragment/fragment.dart';
import '../../kernel/body_builder_context.dart';
import '../../kernel/kernel_helper.dart';
import '../../kernel/type_algorithms.dart';
import '../../source/name_scheme.dart';
import '../../source/source_factory_builder.dart';
import '../../source/source_function_builder.dart';
import '../../source/source_library_builder.dart' show SourceLibraryBuilder;
import '../../source/source_loader.dart' show SourceLoader;
import '../../source/source_member_builder.dart';
import '../../source/source_type_parameter_builder.dart';
import 'body_builder_context.dart';
import 'encoding.dart';

abstract class FactoryDeclaration {
  Procedure get procedure;

  Procedure? get tearOff;

  FunctionNode get function;

  List<SourceNominalParameterBuilder>? get typeParameters;

  TypeBuilder get returnType;

  void createNode({
    required String name,
    required SourceLibraryBuilder libraryBuilder,
    required NameScheme nameScheme,
    required Reference? procedureReference,
    required Reference? tearOffReference,
  });

  void buildOutlineNodes(
      {required SourceLibraryBuilder libraryBuilder,
      required SourceFactoryBuilder factoryBuilder,
      required BuildNodesCallback f,
      required bool isConst});

  void buildOutlineExpressions(
      {required SourceLibraryBuilder libraryBuilder,
      required SourceFactoryBuilder factoryBuilder,
      required ClassHierarchy classHierarchy,
      required List<DelayedDefaultValueCloner> delayedDefaultValueCloners,
      required bool createFileUriExpression});

  void inferRedirectionTarget(
      {required SourceLibraryBuilder libraryBuilder,
      required SourceFactoryBuilder factoryBuilder,
      required ClassHierarchy classHierarchy,
      required List<DelayedDefaultValueCloner> delayedDefaultValueCloners});

  /// Checks this factory builder if it is for a redirecting factory.
  void checkRedirectingFactory(
      {required SourceLibraryBuilder libraryBuilder,
      required SourceFactoryBuilder factoryBuilder,
      required TypeEnvironment typeEnvironment});

  int computeDefaultTypes(ComputeDefaultTypeContext context,
      {required bool inErrorRecovery});

  void checkTypes(SourceLibraryBuilder library, NameSpace nameSpace,
      TypeEnvironment typeEnvironment);

  void setBody(Statement value);

  void setAsyncModifier(AsyncMarker newModifier);

  FormalParameterBuilder? getFormal(Identifier identifier);

  VariableDeclaration? getTearOffParameter(int index);

  abstract List<DartType>? redirectionTypeArguments;

  bool get isNative;

  bool get isExternal;

  Uri get fileUri;

  int get fileOffset;

  void becomeNative(
      {required SourceLoader loader,
      required Iterable<Annotatable> annotatables});

  void resolveRedirectingFactory(
      {required SourceLibraryBuilder libraryBuilder});

  List<FormalParameterBuilder>? get formals;

  /// Returns the [index]th parameter of this function.
  ///
  /// The index is the syntactical index, including both positional and named
  /// parameter in the order they are declared, and excluding the synthesized
  /// this parameter on extension instance members.
  VariableDeclaration getFormalParameter(int index);

  Iterable<MetadataBuilder>? get metadata;

  ConstructorReferenceBuilder? get redirectionTarget;

  BodyBuilderContext createBodyBuilderContext(
      SourceFactoryBuilder factoryBuilder);
}

class FactoryDeclarationImpl implements FactoryDeclaration {
  final FactoryFragment _fragment;
  @override
  final List<SourceNominalParameterBuilder>? typeParameters;
  @override
  final TypeBuilder returnType;
  final FactoryEncoding _encoding;

  FactoryDeclarationImpl(this._fragment,
      {required this.typeParameters, required this.returnType})
      : _encoding = new FactoryEncoding(_fragment,
            typeParameters: typeParameters,
            returnType: returnType,
            redirectionTarget: _fragment.redirectionTarget) {
    _fragment.declaration = this;
  }

  @override
  Procedure get procedure => _encoding.procedure;

  @override
  Procedure? get tearOff => _encoding.tearOff;

  @override
  FunctionNode get function => _encoding.function;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isNative => _encoding.isNative;

  @override
  bool get isExternal => _fragment.modifiers.isExternal;

  @override
  Uri get fileUri => _fragment.fileUri;

  @override
  int get fileOffset => _fragment.fullNameOffset;

  @override
  void becomeNative(
      {required SourceLoader loader,
      required Iterable<Annotatable> annotatables}) {
    for (Annotatable annotatable in annotatables) {
      loader.addNativeAnnotation(annotatable, _fragment.nativeMethodName!);
    }
    _encoding.becomeNative(loader);
  }

  @override
  void createNode({
    required String name,
    required SourceLibraryBuilder libraryBuilder,
    required NameScheme nameScheme,
    required Reference? procedureReference,
    required Reference? tearOffReference,
  }) {
    _encoding.createNode(
        name: name,
        libraryBuilder: libraryBuilder,
        nameScheme: nameScheme,
        procedureReference: procedureReference,
        tearOffReference: tearOffReference);
  }

  @override
  void buildOutlineNodes(
      {required SourceLibraryBuilder libraryBuilder,
      required SourceFactoryBuilder factoryBuilder,
      required BuildNodesCallback f,
      required bool isConst}) {
    _encoding.buildOutlineNodes(
        libraryBuilder: libraryBuilder,
        factoryBuilder: factoryBuilder,
        f: f,
        isConst: isConst);
  }

  @override
  BodyBuilderContext createBodyBuilderContext(
      SourceFactoryBuilder factoryBuilder) {
    return new FactoryBodyBuilderContext(
        factoryBuilder, this, _encoding.procedure);
  }

  @override
  void buildOutlineExpressions(
      {required SourceLibraryBuilder libraryBuilder,
      required SourceFactoryBuilder factoryBuilder,
      required ClassHierarchy classHierarchy,
      required List<DelayedDefaultValueCloner> delayedDefaultValueCloners,
      required bool createFileUriExpression}) {
    _fragment.formals?.infer(classHierarchy);

    BodyBuilderContext bodyBuilderContext =
        createBodyBuilderContext(factoryBuilder);

    for (Annotatable annotatable in factoryBuilder.annotatables) {
      MetadataBuilder.buildAnnotations(
          annotatable,
          _fragment.metadata,
          bodyBuilderContext,
          libraryBuilder,
          _fragment.fileUri,
          _fragment.enclosingScope,
          createFileUriExpression: createFileUriExpression);
    }
    if (typeParameters != null) {
      for (int i = 0; i < typeParameters!.length; i++) {
        typeParameters![i].buildOutlineExpressions(libraryBuilder,
            bodyBuilderContext, classHierarchy, _fragment.typeParameterScope);
      }
    }

    if (_fragment.formals != null) {
      // For const constructors we need to include default parameter values
      // into the outline. For all other formals we need to call
      // buildOutlineExpressions to clear initializerToken to prevent
      // consuming too much memory.
      for (FormalParameterBuilder formal in _fragment.formals!) {
        formal.buildOutlineExpressions(
            libraryBuilder, factoryBuilder.declarationBuilder,
            scope: _fragment.typeParameterScope,
            buildDefaultValue: FormalParameterBuilder
                .needsDefaultValuesBuiltAsOutlineExpressions(factoryBuilder));
      }
    }

    _encoding.buildOutlineExpressions(
        delayedDefaultValueCloners: delayedDefaultValueCloners);
  }

  @override
  void inferRedirectionTarget(
      {required SourceLibraryBuilder libraryBuilder,
      required SourceFactoryBuilder factoryBuilder,
      required ClassHierarchy classHierarchy,
      required List<DelayedDefaultValueCloner> delayedDefaultValueCloners}) {
    BodyBuilderContext bodyBuilderContext =
        createBodyBuilderContext(factoryBuilder);
    _encoding.inferRedirectionTarget(
        libraryBuilder: libraryBuilder,
        declarationBuilder: factoryBuilder.declarationBuilder,
        bodyBuilderContext: bodyBuilderContext,
        classHierarchy: classHierarchy,
        delayedDefaultValueCloners: delayedDefaultValueCloners);
  }

  @override
  void checkRedirectingFactory(
      {required SourceLibraryBuilder libraryBuilder,
      required SourceFactoryBuilder factoryBuilder,
      required TypeEnvironment typeEnvironment}) {
    _encoding.checkRedirectingFactory(
        libraryBuilder: libraryBuilder,
        factoryBuilder: factoryBuilder,
        typeEnvironment: typeEnvironment);
  }

  @override
  int computeDefaultTypes(ComputeDefaultTypeContext context,
      {required bool inErrorRecovery}) {
    int count = context.computeDefaultTypesForVariables(typeParameters,
        // Type parameters are inherited from the enclosing declaration, so if
        // it has issues, so do the constructors.
        inErrorRecovery: inErrorRecovery);
    context.reportGenericFunctionTypesForFormals(_fragment.formals);
    return count;
  }

  @override
  void checkTypes(SourceLibraryBuilder library, NameSpace nameSpace,
      TypeEnvironment typeEnvironment) {
    if (_fragment.redirectionTarget != null) {
      // Default values are not required on redirecting factory constructors so
      // we don't call [checkInitializersInFormals].
    } else {
      library.checkInitializersInFormals(_fragment.formals, typeEnvironment,
          isAbstract: _fragment.modifiers.isAbstract,
          isExternal: _fragment.modifiers.isExternal);
    }
  }

  @override
  void setBody(Statement value) {
    _encoding.setBody(value);
  }

  @override
  void setAsyncModifier(AsyncMarker newModifier) {
    _encoding.asyncModifier = newModifier;
  }

  @override
  FormalParameterBuilder? getFormal(Identifier identifier) {
    return _encoding.getFormal(identifier);
  }

  @override
  VariableDeclaration? getTearOffParameter(int index) {
    return _encoding.getTearOffParameter(index);
  }

  @override
  // Coverage-ignore(suite): Not run.
  List<DartType>? get redirectionTypeArguments =>
      _encoding.redirectionTypeArguments;

  @override
  // Coverage-ignore(suite): Not run.
  void set redirectionTypeArguments(List<DartType>? value) {
    _encoding.redirectionTypeArguments = value;
  }

  @override
  void resolveRedirectingFactory(
      {required SourceLibraryBuilder libraryBuilder}) {
    _encoding.resolveRedirectingFactory(libraryBuilder: libraryBuilder);
  }

  @override
  // Coverage-ignore(suite): Not run.
  List<FormalParameterBuilder>? get formals => _fragment.formals;

  @override
  VariableDeclaration getFormalParameter(int index) =>
      _fragment.formals![index].variable!;

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<MetadataBuilder>? get metadata => _fragment.metadata;

  @override
  ConstructorReferenceBuilder? get redirectionTarget {
    return _fragment.redirectionTarget;
  }
}
