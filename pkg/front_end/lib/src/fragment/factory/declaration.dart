// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/type_environment.dart';

import '../../base/identifiers.dart';
import '../../base/messages.dart';
import '../../base/name_space.dart';
import '../../builder/constructor_reference_builder.dart';
import '../../builder/declaration_builders.dart';
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
import '../../source/type_parameter_factory.dart';
import 'body_builder_context.dart';
import 'encoding.dart';

/// Interface for the factory declaration aspect of a [SourceFactoryBuilder].
///
/// If a factory is augmented, it will have multiple
/// [FactoryDeclaration]s on a single [SourceFactoryBuilder].
abstract class FactoryDeclaration {
  Uri get fileUri;

  FunctionNode get function;

  Iterable<MetadataBuilder>? get metadata;

  Procedure get procedure;

  ConstructorReferenceBuilder? get redirectionTarget;

  void createEncoding({
    required ProblemReporting problemReporting,
    required DeclarationBuilder declarationBuilder,
    required SourceFactoryBuilder factoryBuilder,
    required TypeParameterFactory typeParameterFactory,
    required FactoryEncodingStrategy encodingStrategy,
  });

  void buildOutlineExpressions({
    required Iterable<Annotatable> annotatables,
    required Uri annotatablesFileUri,
    required SourceLibraryBuilder libraryBuilder,
    required SourceFactoryBuilder factoryBuilder,
    required ClassHierarchy classHierarchy,
    required List<DelayedDefaultValueCloner> delayedDefaultValueCloners,
  });

  void buildOutlineNodes({
    required SourceLibraryBuilder libraryBuilder,
    required SourceFactoryBuilder factoryBuilder,
    required BuildNodesCallback f,
    required NameScheme nameScheme,
    required FactoryReferences? factoryReferences,
    required bool isConst,
  });

  /// Checks this factory builder if it is for a redirecting factory.
  void checkRedirectingFactory({
    required SourceLibraryBuilder libraryBuilder,
    required SourceFactoryBuilder factoryBuilder,
    required TypeEnvironment typeEnvironment,
  });

  void checkTypes(
    SourceLibraryBuilder library,
    NameSpace nameSpace,
    TypeEnvironment typeEnvironment,
  );

  int computeDefaultTypes(
    ComputeDefaultTypeContext context, {
    required bool inErrorRecovery,
  });

  void inferRedirectionTarget({
    required SourceLibraryBuilder libraryBuilder,
    required SourceFactoryBuilder factoryBuilder,
    required ClassHierarchy classHierarchy,
    required List<DelayedDefaultValueCloner> delayedDefaultValueCloners,
  });

  void resolveRedirectingFactory({
    required SourceLibraryBuilder libraryBuilder,
  });

  bool get isRedirectingFactory;
}

class FactoryDeclarationImpl
    implements FactoryDeclaration, FactoryFragmentDeclaration {
  final FactoryFragment _fragment;
  late final List<SourceNominalParameterBuilder>? _typeParameters;
  late final TypeBuilder _returnType;
  late final FactoryEncoding _encoding;

  FactoryDeclarationImpl(this._fragment) {
    _fragment.declaration = this;
  }

  @override
  void createEncoding({
    required ProblemReporting problemReporting,
    required DeclarationBuilder declarationBuilder,
    required SourceFactoryBuilder factoryBuilder,
    required TypeParameterFactory typeParameterFactory,
    required FactoryEncodingStrategy encodingStrategy,
  }) {
    _fragment.builder = factoryBuilder;
    var (typeParameters, returnType) = encodingStrategy
        .createTypeParametersAndReturnType(
          declarationBuilder: declarationBuilder,
          declarationTypeParameterFragments:
              _fragment.enclosingDeclaration.typeParameters,
          typeParameterFactory: typeParameterFactory,
          fullName: _fragment.constructorName.fullName,
          fileUri: _fragment.fileUri,
          fullNameOffset: _fragment.constructorName.fullNameOffset,
          fullNameLength: _fragment.constructorName.fullNameLength,
        );
    _typeParameters = typeParameters;
    _returnType = returnType;
    _fragment.typeParameterNameSpace.addTypeParameters(
      problemReporting,
      typeParameters,
      ownerName: _fragment.name,
      allowNameConflict: true,
    );
    _encoding = new FactoryEncoding(
      _fragment,
      typeParameters: typeParameters,
      returnType: returnType,
      redirectionTarget: _fragment.redirectionTarget,
    );
  }

  @override
  TypeBuilder get returnType => _returnType;

  @override
  int get fileOffset => _fragment.fullNameOffset;

  @override
  // Coverage-ignore(suite): Not run.
  Uri get fileUri => _fragment.fileUri;

  @override
  bool get isRedirectingFactory => _fragment.redirectionTarget != null;

  @override
  List<FormalParameterBuilder>? get formals => _fragment.formals;

  @override
  FunctionNode get function => _encoding.function;

  @override
  bool get isExternal => _fragment.modifiers.isExternal;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isNative => _encoding.isNative;

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<MetadataBuilder>? get metadata => _fragment.metadata;

  @override
  Procedure get procedure => _encoding.procedure;

  @override
  ConstructorReferenceBuilder? get redirectionTarget {
    return _fragment.redirectionTarget;
  }

  @override
  void becomeNative(SourceLoader loader) {
    loader.addNativeAnnotation(procedure, _fragment.nativeMethodName!);
    _encoding.becomeNative(loader);
  }

  @override
  void buildOutlineExpressions({
    required Iterable<Annotatable> annotatables,
    required Uri annotatablesFileUri,
    required SourceLibraryBuilder libraryBuilder,
    required SourceFactoryBuilder factoryBuilder,
    required ClassHierarchy classHierarchy,
    required List<DelayedDefaultValueCloner> delayedDefaultValueCloners,
  }) {
    _fragment.formals?.infer(classHierarchy);

    BodyBuilderContext bodyBuilderContext = createBodyBuilderContext(
      factoryBuilder,
    );

    for (Annotatable annotatable in annotatables) {
      MetadataBuilder.buildAnnotations(
        annotatable: annotatable,
        annotatableFileUri: annotatablesFileUri,
        metadata: _fragment.metadata,
        bodyBuilderContext: bodyBuilderContext,
        libraryBuilder: libraryBuilder,
        scope: _fragment.enclosingScope,
      );
    }
    if (_typeParameters != null) {
      for (int i = 0; i < _typeParameters.length; i++) {
        _typeParameters[i].buildOutlineExpressions(
          libraryBuilder,
          bodyBuilderContext,
          classHierarchy,
        );
      }
    }

    if (_fragment.formals != null) {
      // For const constructors we need to include default parameter values
      // into the outline. For all other formals we need to call
      // buildOutlineExpressions to clear initializerToken to prevent
      // consuming too much memory.
      for (FormalParameterBuilder formal in _fragment.formals!) {
        formal.buildOutlineExpressions(
          libraryBuilder,
          factoryBuilder.declarationBuilder,
          scope: _fragment.typeParameterScope,
          buildDefaultValue:
              FormalParameterBuilder // force line break
              .needsDefaultValuesBuiltAsOutlineExpressions(factoryBuilder),
        );
      }
    }

    _encoding.buildOutlineExpressions(
      delayedDefaultValueCloners: delayedDefaultValueCloners,
    );
  }

  @override
  void buildOutlineNodes({
    required SourceLibraryBuilder libraryBuilder,
    required SourceFactoryBuilder factoryBuilder,
    required BuildNodesCallback f,
    required NameScheme nameScheme,
    required FactoryReferences? factoryReferences,
    required bool isConst,
  }) {
    _encoding.buildOutlineNodes(
      libraryBuilder: libraryBuilder,
      factoryBuilder: factoryBuilder,
      f: f,
      name: _fragment.name,
      nameScheme: nameScheme,
      factoryReferences: factoryReferences,
      isConst: isConst,
    );
  }

  @override
  void checkRedirectingFactory({
    required SourceLibraryBuilder libraryBuilder,
    required SourceFactoryBuilder factoryBuilder,
    required TypeEnvironment typeEnvironment,
  }) {
    _encoding.checkRedirectingFactory(
      libraryBuilder: libraryBuilder,
      factoryBuilder: factoryBuilder,
      typeEnvironment: typeEnvironment,
    );
  }

  @override
  void checkTypes(
    SourceLibraryBuilder library,
    NameSpace nameSpace,
    TypeEnvironment typeEnvironment,
  ) {
    if (_fragment.redirectionTarget != null) {
      // Default values are not required on redirecting factory constructors so
      // we don't call [checkInitializersInFormals].
    } else {
      library.checkInitializersInFormals(
        _fragment.formals,
        typeEnvironment,
        isAbstract: _fragment.modifiers.isAbstract,
        isExternal: _fragment.modifiers.isExternal,
      );
    }
  }

  @override
  int computeDefaultTypes(
    ComputeDefaultTypeContext context, {
    required bool inErrorRecovery,
  }) {
    int count = context.computeDefaultTypesForVariables(
      _typeParameters,
      // Type parameters are inherited from the enclosing declaration, so if
      // it has issues, so do the constructors.
      inErrorRecovery: inErrorRecovery,
    );
    context.reportGenericFunctionTypesForFormals(_fragment.formals);
    return count;
  }

  @override
  BodyBuilderContext createBodyBuilderContext(
    SourceFactoryBuilder factoryBuilder,
  ) {
    return new FactoryBodyBuilderContext(
      factoryBuilder,
      this,
      _encoding.procedure,
    );
  }

  @override
  FormalParameterBuilder? getFormal(Identifier identifier) {
    return _encoding.getFormal(identifier);
  }

  @override
  VariableDeclaration getFormalParameter(int index) =>
      _fragment.formals![index].variable!;

  @override
  VariableDeclaration? getTearOffParameter(int index) {
    return _encoding.getTearOffParameter(index);
  }

  @override
  void inferRedirectionTarget({
    required SourceLibraryBuilder libraryBuilder,
    required SourceFactoryBuilder factoryBuilder,
    required ClassHierarchy classHierarchy,
    required List<DelayedDefaultValueCloner> delayedDefaultValueCloners,
  }) {
    BodyBuilderContext bodyBuilderContext = createBodyBuilderContext(
      factoryBuilder,
    );
    _encoding.inferRedirectionTarget(
      libraryBuilder: libraryBuilder,
      declarationBuilder: factoryBuilder.declarationBuilder,
      bodyBuilderContext: bodyBuilderContext,
      classHierarchy: classHierarchy,
      delayedDefaultValueCloners: delayedDefaultValueCloners,
    );
  }

  @override
  void resolveRedirectingFactory({
    required SourceLibraryBuilder libraryBuilder,
  }) {
    _encoding.resolveRedirectingFactory(libraryBuilder: libraryBuilder);
  }

  @override
  void setAsyncModifier(AsyncMarker newModifier) {
    _encoding.asyncModifier = newModifier;
  }

  @override
  void setBody(Statement value) {
    _encoding.setBody(value);
  }
}

/// Interface for using a [FactoryFragment] to create a [BodyBuilderContext].
abstract class FactoryFragmentDeclaration {
  int get fileOffset;

  List<FormalParameterBuilder>? get formals;

  FunctionNode get function;

  bool get isExternal;

  bool get isNative;

  ConstructorReferenceBuilder? get redirectionTarget;

  TypeBuilder get returnType;

  void becomeNative(SourceLoader loader);

  BodyBuilderContext createBodyBuilderContext(
    SourceFactoryBuilder factoryBuilder,
  );

  FormalParameterBuilder? getFormal(Identifier identifier);

  /// Returns the [index]th parameter of this function.
  ///
  /// The index is the syntactical index, including both positional and named
  /// parameter in the order they are declared, and excluding the synthesized
  /// this parameter on extension instance members.
  VariableDeclaration getFormalParameter(int index);

  /// If this is an extension instance method or constructor with lowering
  /// enabled, the tear off parameter corresponding to the [index]th parameter
  /// on the instance method or constructor is returned.
  ///
  /// This is used to update the default value for the closure parameter when
  /// it has been computed for the original parameter.
  VariableDeclaration? getTearOffParameter(int index);

  void setAsyncModifier(AsyncMarker newModifier);

  void setBody(Statement value);
}
