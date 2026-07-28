// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/parser/formal_parameter_kind.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/type_algebra.dart';

import '../../api_prototype/lowering_predicates.dart';
import '../../base/modifiers.dart';
import '../../builder/declaration_builders.dart';
import '../../builder/formal_parameter_builder.dart';
import '../../builder/function_signature.dart';
import '../../builder/named_type_builder.dart';
import '../../builder/omitted_type_builder.dart';
import '../../builder/type_builder.dart';
import '../../kernel/body_builder_context.dart';
import '../../kernel/constructor_tearoff_lowering.dart';
import '../../kernel/external_ast_helper.dart' as extern;
import '../../kernel/internal_ast.dart';
import '../../kernel/internal_ast_helper.dart' as intern;
import '../../kernel/kernel_helper.dart';
import '../../source/name_scheme.dart';
import '../../source/source_class_builder.dart';
import '../../source/source_constructor_builder.dart';
import '../../source/source_extension_builder.dart';
import '../../source/source_extension_type_declaration_builder.dart';
import '../../source/source_function_builder.dart';
import '../../source/source_library_builder.dart';
import '../../source/source_loader.dart';
import '../../source/source_member_builder.dart';
import '../../source/source_type_parameter_builder.dart';
import '../../source/type_parameter_factory.dart';
import '../../type_inference/type_inferrer.dart';
import '../../type_inference/type_schema.dart';
import '../fragment.dart';
import 'body_builder_context.dart';
import 'declaration.dart';

abstract class ConstructorEncoding {
  FunctionSignature get signature;

  List<Initializer> get initializers;

  void prepareInitializers();

  void prependInitializer(Initializer initializer);

  FunctionParameter? getTearOffParameter(int index);

  InternalVariable? get thisVariable;

  List<TypeParameter>? get thisTypeParameters;

  void registerInitializers(List<Initializer> initializers);

  /// Mark the constructor as erroneous.
  ///
  /// This is used during the compilation phase to set the appropriate flag on
  /// the input AST node. The flag helps the verifier to skip apriori erroneous
  /// members and to avoid reporting cascading errors.
  void markAsErroneous();

  void buildOutlineNodes(
    BuildNodesCallback f, {
    required SourceConstructorBuilder constructorBuilder,
    required SourceLibraryBuilder libraryBuilder,
    required covariant DeclarationBuilder declarationBuilder,
    required String name,
    required NameScheme nameScheme,
    required ConstructorReferences? constructorReferences,
    required Uri fileUri,
    required int startOffset,
    required int fileOffset,
    required int formalsOffset,
    required int endOffset,
    required bool forAbstractClassOrEnumOrMixin,
    required bool isConst,
    required bool isSynthetic,
    required TypeBuilder returnType,
    required List<SourceNominalParameterBuilder>? typeParameters,
    required List<FormalParameterBuilder>? formals,
    required List<DelayedDefaultValueCloner> delayedDefaultValueCloners,
  });

  void buildBody();

  BodyBuilderContext createBodyBuilderContext(
    SourceConstructorBuilder constructorBuilder,
    ConstructorFragmentDeclaration constructorDeclaration,
  );

  void registerFunctionBody({
    required Statement? body,
    Scope? scope,
    required ThisVariable? thisVariable,
  });

  void registerNoBodyConstructor({required ThisVariable? thisVariable});

  void addSuperParameterDefaultValueCloners({
    required List<DelayedDefaultValueCloner> delayedDefaultValueCloners,
    required Member superTarget,
    required List<int?>? positionalSuperParameters,
    required List<String>? namedSuperParameters,
    required SourceLibraryBuilder libraryBuilder,
  });

  void becomeNative(SourceLoader loader, String nativeMethodName);

  Substitution computeFieldTypeSubstitution(
    covariant DeclarationBuilder declarationBuilder,
    List<SourceNominalParameterBuilder>? typeParameters,
  );

  bool get isRedirecting;

  void registerInferredReturnType(DartType type);
}

class RegularConstructorEncoding implements ConstructorEncoding {
  late final Constructor _constructor;

  late final Procedure? _constructorTearOff;

  final bool _isExternal;

  final bool _isEnumConstructor;

  Statement? bodyInternal;

  List<Initializer>? _prependedInitializers;

  new({required bool isExternal, required bool isEnumConstructor})
    : _isExternal = isExternal,
      _isEnumConstructor = isEnumConstructor;

  @override
  void registerFunctionBody({
    required Statement? body,
    Scope? scope,
    required ThisVariable? thisVariable,
  }) {
    if (body != null) {
      _constructor.function.registerFunctionBody(body);
    }
    _constructor.function.scope = scope;
    _constructor.function.thisVariable = thisVariable
      ?..parent = _constructor.function;
  }

  @override
  void registerNoBodyConstructor({required ThisVariable? thisVariable}) {
    if (!_isExternal) {
      registerFunctionBody(
        body: extern.createEmptyStatement(),
        thisVariable: thisVariable,
      );
    }
  }

  @override
  void registerInferredReturnType(DartType type) {
    _constructor.function.returnType = type;
  }

  @override
  FunctionSignature get signature =>
      new FunctionNodeSignature(_constructor.function);

  // Coverage-ignore(suite): Not run.
  Member get constructor => _constructor;

  // Coverage-ignore(suite): Not run.
  Procedure? get constructorTearOff => _constructorTearOff;

  @override
  List<Initializer> get initializers => _constructor.initializers;

  @override
  void registerInitializers(List<Initializer> initializers) {
    _constructor.initializers.addAll(initializers);
    setParents(initializers, _constructor);
  }

  @override
  bool get isRedirecting {
    for (Initializer initializer in initializers) {
      assert(
        initializer is! AuxiliaryInitializer,
        "Unexpected auxiliary initializer $initializer.",
      );
      if (initializer.isRedirectingInitializer) {
        return true;
      }
    }
    return false;
  }

  @override
  InternalVariable? get thisVariable => null;

  @override
  List<TypeParameter>? get thisTypeParameters => null;

  @override
  void buildOutlineNodes(
    BuildNodesCallback f, {
    required SourceConstructorBuilder constructorBuilder,
    required SourceLibraryBuilder libraryBuilder,
    required SourceClassBuilder declarationBuilder,
    required String name,
    required NameScheme nameScheme,
    required ConstructorReferences? constructorReferences,
    required Uri fileUri,
    required int startOffset,
    required int fileOffset,
    required int formalsOffset,
    required int endOffset,
    required bool isSynthetic,
    required bool forAbstractClassOrEnumOrMixin,
    required bool isConst,
    required TypeBuilder returnType,
    required List<SourceNominalParameterBuilder>? typeParameters,
    required List<FormalParameterBuilder>? formals,
    required List<DelayedDefaultValueCloner> delayedDefaultValueCloners,
  }) {
    _build(
      constructorBuilder: constructorBuilder,
      libraryBuilder: libraryBuilder,
      classBuilder: declarationBuilder,
      name: name,
      nameScheme: nameScheme,
      constructorReferences: constructorReferences,
      fileUri: fileUri,
      startOffset: startOffset,
      fileOffset: fileOffset,
      formalsOffset: formalsOffset,
      endOffset: endOffset,
      forAbstractClassOrEnumOrMixin: forAbstractClassOrEnumOrMixin,
      isSynthetic: isSynthetic,
      isConst: isConst,
      returnType: returnType,
      typeParameters: typeParameters,
      formals: formals,
      delayedDefaultValueCloners: delayedDefaultValueCloners,
    );
    f(
      member: _constructor,
      tearOff: _constructorTearOff,
      kind: BuiltMemberKind.Constructor,
    );
  }

  bool _hasBeenBuilt = false;

  void _build({
    required SourceConstructorBuilder constructorBuilder,
    required SourceLibraryBuilder libraryBuilder,
    required SourceClassBuilder classBuilder,
    required String name,
    required NameScheme nameScheme,
    required ConstructorReferences? constructorReferences,
    required Uri fileUri,
    required int startOffset,
    required int fileOffset,
    required int formalsOffset,
    required int endOffset,
    required bool forAbstractClassOrEnumOrMixin,
    required bool isSynthetic,
    required bool isConst,
    required TypeBuilder returnType,
    required List<SourceNominalParameterBuilder>? typeParameters,
    required List<FormalParameterBuilder>? formals,
    required List<DelayedDefaultValueCloner> delayedDefaultValueCloners,
  }) {
    if (!_hasBeenBuilt) {
      _constructor = extern.createConstructor(
        extern.createFunctionNode(
          _isExternal ? null : extern.createEmptyStatement(),
          fileOffset: fileOffset,
          fileEndOffset: endOffset,
        ),
        name: dummyName,
        fileUri: fileUri,
        reference: constructorReferences?.constructorReference,
        isSynthetic: isSynthetic,
        fileStartOffset: startOffset,
        fileOffset: fileOffset,
        fileEndOffset: endOffset,
      );
      nameScheme
          .getConstructorMemberName(name, isTearOff: false)
          .attachMember(_constructor);
      _constructorTearOff = createConstructorTearOffProcedure(
        nameScheme.getConstructorMemberName(name, isTearOff: true),
        libraryBuilder,
        fileUri,
        fileOffset,
        constructorReferences?.tearOffReference,
        forAbstractClassOrEnumOrMixin:
            forAbstractClassOrEnumOrMixin || _isEnumConstructor,
      );

      // According to the specification §9.3 the return type of a constructor
      // function is its enclosing class.
      _constructor.function.asyncMarker = AsyncMarker.Sync;
      buildTypeParametersAndFormals(
        libraryBuilder,
        _constructor.function,
        typeParameters,
        formals,
        classTypeParameters: null,
        supportsTypeParameters: false,
      );
      Class enclosingClass = classBuilder.cls;
      List<DartType> typeParameterTypes = <DartType>[];
      for (int i = 0; i < enclosingClass.typeParameters.length; i++) {
        TypeParameter typeParameter = enclosingClass.typeParameters[i];
        typeParameterTypes.add(
          new TypeParameterType.withDefaultNullability(typeParameter),
        );
      }
      InterfaceType type = new InterfaceType(
        enclosingClass,
        Nullability.nonNullable,
        typeParameterTypes,
      );
      returnType.registerInferredType(type);
      _constructor.function.fileOffset = formalsOffset;
      _constructor.function.fileEndOffset = _constructor.fileEndOffset;
      _constructor.function.typeParameters = const <TypeParameter>[];
      _constructor.isConst = isConst;
      _constructor.isExternal = _isExternal;

      if (_constructorTearOff != null) {
        DelayedDefaultValueCloner delayedDefaultValueCloner =
            buildConstructorTearOffProcedure(
              tearOff: _constructorTearOff,
              declarationConstructor: _constructor,
              implementationConstructor: _constructor,
              enclosingDeclarationTypeParameters:
                  classBuilder.cls.typeParameters,
              libraryBuilder: libraryBuilder,
            );
        delayedDefaultValueCloners.add(delayedDefaultValueCloner);
      }

      _hasBeenBuilt = true;
    }
    if (formals != null) {
      bool needsInference = false;
      for (FormalParameterBuilder formal in formals) {
        if (formal.type is InferableTypeBuilder &&
            (formal.isInitializingFormal || formal.isSuperInitializingFormal)) {
          formal.variable.type = const UnknownType();
          needsInference = true;
        } else if (!formal.hasDeclaredDefaultValue &&
            formal.isSuperInitializingFormal) {
          needsInference = true;
        }
      }
      if (needsInference) {
        libraryBuilder.loader.registerConstructorToBeInferred(
          new InferableConstructor(_constructor, constructorBuilder),
        );
      }
    }
  }

  @override
  void buildBody() {}

  @override
  void prepareInitializers() {
    // For const constructors we parse initializers already at the outlining
    // stage, there is no easy way to make body building stage skip initializer
    // parsing, so we simply clear parsed initializers and rebuild them
    // again.
    // For when doing an experimental incremental compilation they are also
    // potentially done more than once (because it rebuilds the bodies of an old
    // compile), and so we also clear them.
    // Note: this method clears both initializers from the target Kernel node
    // and internal state associated with parsing initializers.
    if (_prependedInitializers != null) {
      _constructor.initializers = [..._prependedInitializers!.reversed];
    } else {
      _constructor.initializers = [];
    }
  }

  @override
  void prependInitializer(Initializer initializer) {
    initializer.parent = _constructor;
    (_prependedInitializers ??= []).add(initializer);
    _constructor.initializers.insert(0, initializer);
  }

  @override
  void becomeNative(SourceLoader loader, String nativeMethodName) {
    _constructor.isExternal = true;

    loader.addNativeAnnotation(_constructor, nativeMethodName);
  }

  @override
  FunctionParameter? getTearOffParameter(int index) {
    Procedure? constructorTearOff = _constructorTearOff;
    if (constructorTearOff != null) {
      if (index < constructorTearOff.function.positionalParameters.length) {
        return constructorTearOff.function.positionalParameters[index];
      } else {
        index -= constructorTearOff.function.positionalParameters.length;
        if (index < constructorTearOff.function.namedParameters.length) {
          return constructorTearOff.function.namedParameters[index];
        }
      }
    }
    return null;
  }

  bool _hasAddedDefaultValueCloners = false;

  @override
  void addSuperParameterDefaultValueCloners({
    required List<DelayedDefaultValueCloner> delayedDefaultValueCloners,
    required Member superTarget,
    required List<int?>? positionalSuperParameters,
    required List<String>? namedSuperParameters,
    required SourceLibraryBuilder libraryBuilder,
  }) {
    if (!_hasAddedDefaultValueCloners) {
      // If this constructor formals are part of a cyclic dependency this
      // might be called more than once.
      delayedDefaultValueCloners.add(
        new DelayedDefaultValueCloner(
          superTarget,
          _constructor,
          positionalSuperParameters: positionalSuperParameters ?? const <int>[],
          namedSuperParameters: namedSuperParameters ?? const <String>[],
          isOutlineNode: true,
          libraryBuilder: libraryBuilder,
        ),
      );
      if (_constructorTearOff != null) {
        delayedDefaultValueCloners.add(
          new DelayedDefaultValueCloner(
            superTarget,
            _constructorTearOff,
            positionalSuperParameters:
                positionalSuperParameters ?? const <int>[],
            namedSuperParameters: namedSuperParameters ?? const <String>[],
            isOutlineNode: true,
            libraryBuilder: libraryBuilder,
          ),
        );
      }
      _hasAddedDefaultValueCloners = true;
    }
  }

  @override
  BodyBuilderContext createBodyBuilderContext(
    SourceConstructorBuilder constructorBuilder,
    ConstructorFragmentDeclaration constructorDeclaration,
  ) {
    return new ConstructorBodyBuilderContext(
      constructorBuilder,
      constructorDeclaration,
      _constructor,
      new _RegularConstructorContext(constructorBuilder),
    );
  }

  @override
  void markAsErroneous() {
    _constructor.isErroneous = true;
  }

  @override
  Substitution computeFieldTypeSubstitution(
    covariant DeclarationBuilder declarationBuilder,
    List<SourceNominalParameterBuilder>? typeParameters,
  ) {
    // Nothing to substitute. Regular generative constructors don't have their
    // own type parameters.
    return Substitution.empty;
  }
}

mixin _ExtensionTypeConstructorEncodingMixin<T extends DeclarationBuilder>
    implements ConstructorEncoding {
  late final Procedure _constructor;

  late final Procedure? _constructorTearOff;

  bool get _isExternal;

  bool get _isExtensionMember;

  bool get _isExtensionTypeMember;

  Statement? bodyInternal;

  List<Initializer>? _prependedInitializers;

  /// If this procedure is an extension instance member or extension type
  /// instance member, [_thisVariable] holds the synthetically added `this`
  /// parameter.
  InternalDeclaredVariable? _thisVariable;

  /// If this procedure is an extension instance member or extension type
  /// instance member, [_thisTypeParameters] holds the type parameters copied
  /// from the extension/extension type declaration.
  List<TypeParameter>? _thisTypeParameters;

  List<Initializer> _initializers = [];

  @override
  List<Initializer> get initializers => _initializers;

  @override
  FunctionSignature get signature =>
      new FunctionNodeSignature(_constructor.function);

  @override
  void registerInitializers(List<Initializer> initializers) {
    this.initializers.addAll(initializers);
  }

  @override
  void registerFunctionBody({
    required Statement? body,
    Scope? scope,
    required ThisVariable? thisVariable,
  }) {
    if (body != null) {
      _constructor.function.registerFunctionBody(body);
    }
    _constructor.function.scope = scope;
    _constructor.function.thisVariable =
        // Coverage-ignore(suite): Not run.
        thisVariable?..parent = _constructor.function;
  }

  @override
  void registerNoBodyConstructor({required ThisVariable? thisVariable}) {
    if (!_hasBuiltBody && !_isExternal) {
      registerFunctionBody(
        body: extern.createEmptyStatement(),
        thisVariable: thisVariable,
      );
    }
  }

  @override
  void registerInferredReturnType(DartType type) {
    _constructor.function.returnType = type;
  }

  bool _hasBeenBuilt = false;

  DartType _computeThisType(T declarationBuilder, List<DartType> typeArguments);

  void _build({
    required SourceConstructorBuilder constructorBuilder,
    required SourceLibraryBuilder libraryBuilder,
    required T declarationBuilder,
    required String name,
    required NameScheme nameScheme,
    required ConstructorReferences? constructorReferences,
    required Uri fileUri,
    required int startOffset,
    required int fileOffset,
    required int formalsOffset,
    required int endOffset,
    required bool forAbstractClassOrEnumOrMixin,
    required bool isConst,
    required TypeBuilder returnType,
    required List<SourceNominalParameterBuilder>? typeParameters,
    required List<FormalParameterBuilder>? formals,
    required List<DelayedDefaultValueCloner> delayedDefaultValueCloners,
  }) {
    if (!_hasBeenBuilt) {
      _constructor = extern.createProcedure(
        dummyName,
        ProcedureKind.Method,
        extern.createFunctionNode(
          _isExternal ? null : extern.createEmptyStatement(),
          fileOffset: fileOffset,
          fileEndOffset: endOffset,
        ),
        fileUri: fileUri,
        reference: constructorReferences?.constructorReference,
        fileStartOffset: startOffset,
        fileOffset: fileOffset,
        fileEndOffset: endOffset,
      );
      nameScheme
          .getConstructorMemberName(name, isTearOff: false)
          .attachMember(_constructor);
      _constructorTearOff =
          createConstructorTearOffProcedure(
              nameScheme.getConstructorMemberName(name, isTearOff: true),
              libraryBuilder,
              fileUri,
              fileOffset,
              constructorReferences?.tearOffReference,
              forAbstractClassOrEnumOrMixin: forAbstractClassOrEnumOrMixin,
              forceCreateLowering: true,
            )
            ?..isExtensionMember = _isExtensionMember
            ..isExtensionTypeMember = _isExtensionTypeMember;

      // According to the specification §9.3 the return type of a constructor
      // function is its enclosing class.
      _constructor.function.asyncMarker = AsyncMarker.Sync;
      buildTypeParametersAndFormals(
        libraryBuilder,
        _constructor.function,
        typeParameters,
        formals,
        classTypeParameters: null,
        supportsTypeParameters: true,
      );

      if (declarationBuilder.typeParameters != null) {
        int count = declarationBuilder.typeParameters!.length;
        _thisTypeParameters = new List<TypeParameter>.generate(
          count,
          (int index) => _constructor.function.typeParameters[index],
          growable: false,
        );
      }
      List<DartType> typeArguments;
      if (_thisTypeParameters != null) {
        typeArguments = [
          for (TypeParameter parameter in _thisTypeParameters!)
            new TypeParameterType.withDefaultNullability(parameter),
        ];
      } else {
        typeArguments = [];
      }

      _thisVariable = intern.createSyntheticVariable(
        name: syntheticThisName,
        type: _computeThisType(declarationBuilder, typeArguments),
        isFinal: true,
        isLowered: true,
        isSynthesized: false,
        fileOffset: fileOffset,
      );

      List<DartType> typeParameterTypes = <DartType>[];
      for (int i = 0; i < _constructor.function.typeParameters.length; i++) {
        TypeParameter typeParameter = _constructor.function.typeParameters[i];
        typeParameterTypes.add(
          new TypeParameterType.withDefaultNullability(typeParameter),
        );
      }
      returnType.registerInferredType(
        _computeThisType(declarationBuilder, typeParameterTypes),
      );
      _constructor.function.fileOffset = formalsOffset;
      _constructor.function.fileEndOffset = _constructor.fileEndOffset;
      _constructor.isConst = isConst;
      _constructor.isExternal = _isExternal;
      _constructor.isStatic = true;
      _constructor.isExtensionMember = _isExtensionMember;
      _constructor.isExtensionTypeMember = _isExtensionTypeMember;

      if (_constructorTearOff != null) {
        delayedDefaultValueCloners.add(
          buildConstructorTearOffProcedure(
            tearOff: _constructorTearOff,
            declarationConstructor: _constructor,
            implementationConstructor: _constructor,
            libraryBuilder: libraryBuilder,
          ),
        );
      }

      _hasBeenBuilt = true;
    }
    if (formals != null) {
      bool needsInference = false;
      for (FormalParameterBuilder formal in formals) {
        if (formal.type is InferableTypeBuilder &&
            (formal.isInitializingFormal || formal.isSuperInitializingFormal)) {
          formal.variable.type = const UnknownType();
          needsInference = true;
        } else if (!formal.hasDeclaredDefaultValue &&
            formal.isSuperInitializingFormal) {
          needsInference = true;
        }
      }
      if (needsInference) {
        libraryBuilder.loader.registerConstructorToBeInferred(
          new InferableConstructor(_constructor, constructorBuilder),
        );
      }
    }
  }

  @override
  InternalDeclaredVariable? get thisVariable {
    assert(
      _thisVariable != null,
      "ProcedureBuilder.thisVariable has not been set.",
    );
    return _thisVariable;
  }

  @override
  List<TypeParameter>? get thisTypeParameters {
    // Use [_thisVariable] as marker for whether this type parameters have
    // been computed.
    assert(
      _thisVariable != null,
      "ProcedureBuilder.thisTypeParameters has not been set.",
    );
    return _thisTypeParameters;
  }

  @override
  void prepareInitializers() {
    // For const constructors we parse initializers already at the outlining
    // stage, there is no easy way to make body building stage skip initializer
    // parsing, so we simply clear parsed initializers and rebuild them
    // again.
    // For when doing an experimental incremental compilation they are also
    // potentially done more than once (because it rebuilds the bodies of an old
    // compile), and so we also clear them.
    // Note: this method clears both initializers from the target Kernel node
    // and internal state associated with parsing initializers.
    if (_prependedInitializers != null) {
      // Coverage-ignore-block(suite): Not run.
      _initializers = [..._prependedInitializers!.reversed];
    } else {
      _initializers = [];
    }
  }

  @override
  void prependInitializer(Initializer initializer) {
    (_prependedInitializers ??= []).add(initializer);
    _initializers.insert(0, initializer);
  }

  @override
  FunctionParameter? getTearOffParameter(int index) {
    Procedure? constructorTearOff = _constructorTearOff;
    if (constructorTearOff != null) {
      if (index < constructorTearOff.function.positionalParameters.length) {
        return constructorTearOff.function.positionalParameters[index];
      } else {
        index -= constructorTearOff.function.positionalParameters.length;
        if (index < constructorTearOff.function.namedParameters.length) {
          return constructorTearOff.function.namedParameters[index];
        }
      }
    }
    return null;
  }

  bool _hasBuiltBody = false;

  @override
  void buildBody() {
    if (_hasBuiltBody) {
      return;
    }
    if (!_isExternal) {
      InternalDeclaredVariable thisVariable = this.thisVariable!;
      VariableStatement thisVariableStatement = extern.createVariableStatement(
        extern.createVariableDeclaration(thisVariable.astVariable),
      );
      List<Statement> statements = [thisVariableStatement];
      _ExtensionTypeInitializerToStatementConverter visitor =
          new _ExtensionTypeInitializerToStatementConverter(
            statements,
            thisVariableStatement,
          );
      for (Initializer initializer in _initializers) {
        initializer.accept(visitor);
      }
      int fileOffset = _constructor.fileOffset;
      int endOffset = _constructor.fileEndOffset;
      if (_constructor.function.body case Statement body
          when body is! EmptyStatement) {
        statements.add(body);
      }
      statements.add(
        extern.createReturnStatement(
          extern.createVariableGet(thisVariable.astVariable),
        ),
      );
      // TODO(cstefantsova): Provide a scope here.
      registerFunctionBody(
        body: extern.createBlock(
          statements,
          fileOffset: fileOffset,
          fileEndOffset: endOffset,
        ),
        thisVariable: null,
      );
    }
    _hasBuiltBody = true;
  }

  @override
  BodyBuilderContext createBodyBuilderContext(
    SourceConstructorBuilder constructorBuilder,
    ConstructorFragmentDeclaration constructorDeclaration,
  ) {
    return new ConstructorBodyBuilderContext(
      constructorBuilder,
      constructorDeclaration,
      _constructor,
      new _ExtensionTypeConstructorContext(
        constructorBuilder,
        thisVariable!.astVariable,
      ),
    );
  }

  @override
  void markAsErroneous() {
    _constructor.isErroneous = true;
  }

  @override
  void addSuperParameterDefaultValueCloners({
    required List<DelayedDefaultValueCloner> delayedDefaultValueCloners,
    required Member superTarget,
    required List<int?>? positionalSuperParameters,
    required List<String>? namedSuperParameters,
    required SourceLibraryBuilder libraryBuilder,
  }) {
    throw new UnsupportedError(
      '$runtimeType.addSuperParameterDefaultValueCloners',
    );
  }

  @override
  void becomeNative(SourceLoader loader, String nativeMethodName) {
    throw new UnsupportedError('$runtimeType.becomeNative');
  }
}

class _ExtensionTypeInitializerToStatementConverter
    implements InitializerVisitor<void> {
  VariableStatement thisVariableStatement;
  final List<Statement> statements;

  new(this.statements, this.thisVariableStatement);

  @override
  void visitAssertInitializer(AssertInitializer node) {
    statements.add(node.statement);
  }

  @override
  void visitAuxiliaryInitializer(AuxiliaryInitializer node) {
    if (node is ExternalExtensionTypeRedirectingInitializer) {
      statements.add(
        extern.createExpressionStatement(
          extern.createVariableSet(
            thisVariableStatement.declaration.variable,
            extern.createStaticInvocation(
              node.target,
              node.arguments,
              fileOffset: node.fileOffset,
            ),
            fileOffset: node.fileOffset,
            // TODO(johnniwinther): Can we avoid this?
            allowFinalAssignment: true,
          ),
        ),
      );
      return;
    } else if (node is ExternalExtensionTypeRepresentationFieldInitializer) {
      thisVariableStatement.declaration.variable
        ..initializer = (node.value
          ..parent = thisVariableStatement.declaration.variable)
        ..fileOffset = node.fileOffset;
      thisVariableStatement.fileOffset = node.fileOffset;
      return;
    }
    // Coverage-ignore-block(suite): Not run.
    throw new UnsupportedError(
      "Unexpected initializer $node (${node.runtimeType})",
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  void visitFieldInitializer(FieldInitializer node) {
    thisVariableStatement.declaration.variable
      ..initializer = (node.value
        ..parent = thisVariableStatement.declaration.variable)
      ..fileOffset = node.fileOffset;
    thisVariableStatement.fileOffset = node.fileOffset;
  }

  @override
  void visitInvalidInitializer(InvalidInitializer node) {
    statements.add(
      extern.createExpressionStatement(
        extern.createInvalidExpression(
          node.message,
          fileOffset: node.fileOffset,
        ),
      ),
    );
  }

  @override
  void visitLocalInitializer(LocalInitializer node) {
    statements.add(
      extern.createVariableStatement(
        extern.createVariableDeclaration(node.variable),
      ),
    );
  }

  @override
  void visitRedirectingInitializer(RedirectingInitializer node) {
    throw new UnsupportedError(
      "Unexpected initializer $node (${node.runtimeType})",
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  void visitSuperInitializer(SuperInitializer node) {
    // TODO(johnniwinther): Report error for this case.
  }
}

class ExtensionTypeConstructorEncoding
    with
        _ExtensionTypeConstructorEncodingMixin<
          SourceExtensionTypeDeclarationBuilder
        >
    implements ConstructorEncoding {
  @override
  final bool _isExternal;

  new({required bool isExternal}) : _isExternal = isExternal;

  @override
  DartType _computeThisType(
    SourceExtensionTypeDeclarationBuilder declarationBuilder,
    List<DartType> typeArguments,
  ) {
    ExtensionTypeDeclaration extensionTypeDeclaration =
        declarationBuilder.extensionTypeDeclaration;
    return new ExtensionType(
      extensionTypeDeclaration,
      Nullability.nonNullable,
      typeArguments,
    );
  }

  @override
  void buildOutlineNodes(
    BuildNodesCallback f, {
    required SourceConstructorBuilder constructorBuilder,
    required SourceLibraryBuilder libraryBuilder,
    required SourceExtensionTypeDeclarationBuilder declarationBuilder,
    required String name,
    required NameScheme nameScheme,
    required ConstructorReferences? constructorReferences,
    required Uri fileUri,
    required int startOffset,
    required int fileOffset,
    required int formalsOffset,
    required int endOffset,
    required bool forAbstractClassOrEnumOrMixin,
    required bool isConst,
    required bool isSynthetic,
    required TypeBuilder returnType,
    required List<SourceNominalParameterBuilder>? typeParameters,
    required List<FormalParameterBuilder>? formals,
    required List<DelayedDefaultValueCloner> delayedDefaultValueCloners,
  }) {
    _build(
      constructorBuilder: constructorBuilder,
      libraryBuilder: libraryBuilder,
      declarationBuilder: declarationBuilder,
      name: name,
      nameScheme: nameScheme,
      constructorReferences: constructorReferences,
      fileUri: fileUri,
      fileOffset: fileOffset,
      startOffset: startOffset,
      formalsOffset: formalsOffset,
      endOffset: endOffset,
      forAbstractClassOrEnumOrMixin: forAbstractClassOrEnumOrMixin,
      isConst: isConst,
      returnType: returnType,
      typeParameters: typeParameters,
      formals: formals,
      delayedDefaultValueCloners: delayedDefaultValueCloners,
    );
    f(
      member: _constructor,
      tearOff: _constructorTearOff,
      kind: BuiltMemberKind.ExtensionTypeConstructor,
    );
  }

  @override
  bool get _isExtensionMember => false;

  @override
  bool get _isExtensionTypeMember => true;

  @override
  Substitution computeFieldTypeSubstitution(
    DeclarationBuilder declarationBuilder,
    List<SourceNominalParameterBuilder>? typeParameters,
  ) {
    if (typeParameters != null) {
      assert(
        declarationBuilder.typeParameters!.length == typeParameters.length,
      );
      return Substitution.fromPairs(
        (declarationBuilder as SourceExtensionTypeDeclarationBuilder)
            .extensionTypeDeclaration
            .typeParameters,
        new List<DartType>.generate(
          declarationBuilder.typeParameters!.length,
          (int index) => new TypeParameterType.withDefaultNullability(
            _constructor.function.typeParameters[index],
          ),
        ),
      );
    } else {
      return Substitution.empty;
    }
  }

  @override
  bool get isRedirecting {
    for (Initializer initializer in initializers) {
      if (initializer.isRedirectingInitializer) {
        return true;
      }
    }
    return false;
  }
}

class ExtensionConstructorEncoding
    with _ExtensionTypeConstructorEncodingMixin<SourceExtensionBuilder>
    implements ConstructorEncoding {
  @override
  final bool _isExternal;

  new({required bool isExternal}) : _isExternal = isExternal;

  @override
  void buildOutlineNodes(
    BuildNodesCallback f, {
    required SourceConstructorBuilder constructorBuilder,
    required SourceLibraryBuilder libraryBuilder,
    required SourceExtensionBuilder declarationBuilder,
    required String name,
    required NameScheme nameScheme,
    required ConstructorReferences? constructorReferences,
    required Uri fileUri,
    required int startOffset,
    required int fileOffset,
    required int formalsOffset,
    required int endOffset,
    required bool forAbstractClassOrEnumOrMixin,
    required bool isConst,
    required bool isSynthetic,
    required TypeBuilder returnType,
    required List<SourceNominalParameterBuilder>? typeParameters,
    required List<FormalParameterBuilder>? formals,
    required List<DelayedDefaultValueCloner> delayedDefaultValueCloners,
  }) {
    _build(
      constructorBuilder: constructorBuilder,
      libraryBuilder: libraryBuilder,
      declarationBuilder: declarationBuilder,
      name: name,
      nameScheme: nameScheme,
      constructorReferences: constructorReferences,
      fileUri: fileUri,
      fileOffset: fileOffset,
      startOffset: startOffset,
      formalsOffset: formalsOffset,
      endOffset: endOffset,
      forAbstractClassOrEnumOrMixin: forAbstractClassOrEnumOrMixin,
      isConst: isConst,
      returnType: returnType,
      typeParameters: typeParameters,
      formals: formals,
      delayedDefaultValueCloners: delayedDefaultValueCloners,
    );
    // Extension constructors are erroneous and are therefore not added to the
    // AST.
  }

  @override
  bool get _isExtensionMember => true;

  @override
  bool get _isExtensionTypeMember => false;

  @override
  DartType _computeThisType(
    SourceExtensionBuilder declarationBuilder,
    List<DartType> typeArguments,
  ) {
    Extension extension = declarationBuilder.extension;
    return Substitution.fromPairs(
      extension.typeParameters,
      typeArguments,
    ).substituteType(extension.onType);
  }

  @override
  // Coverage-ignore(suite): Not run.
  Substitution computeFieldTypeSubstitution(
    SourceExtensionBuilder declarationBuilder,
    List<SourceNominalParameterBuilder>? typeParameters,
  ) {
    if (typeParameters != null) {
      assert(
        declarationBuilder.typeParameters!.length == typeParameters.length,
      );
      return Substitution.fromPairs(
        declarationBuilder.extension.typeParameters,
        new List<DartType>.generate(
          declarationBuilder.typeParameters!.length,
          (int index) => new TypeParameterType.withDefaultNullability(
            _constructor.function.typeParameters[index],
          ),
        ),
      );
    } else {
      return Substitution.empty;
    }
  }

  @override
  bool get isRedirecting {
    // TODO(johnniwinther): Update this if redirecting extension constructors
    //  are supported.
    return false;
  }
}

abstract class ConstructorEncodingStrategy {
  factory(
    DeclarationBuilder declarationBuilder, {
    required bool isClosureContextLoweringEnabled,
  }) {
    switch (declarationBuilder) {
      case ClassBuilder():
        if (declarationBuilder.isEnum) {
          return const EnumConstructorEncodingStrategy();
        } else {
          return const RegularConstructorEncodingStrategy();
        }
      case ExtensionBuilder():
        return const ExtensionConstructorEncodingStrategy();
      case ExtensionTypeDeclarationBuilder():
        return const ExtensionTypeConstructorEncodingStrategy();
    }
  }

  List<FormalParameterBuilder>? createFormals({
    required SourceLoader loader,
    required List<FormalParameterBuilder>? formals,
    required Uri fileUri,
    required int fileOffset,
  });

  List<SourceNominalParameterBuilder>? createTypeParameters({
    required DeclarationBuilder declarationBuilder,
    required List<TypeParameterFragment>? declarationTypeParameterFragments,
    required List<SourceNominalParameterBuilder>? typeParameters,
    required TypeParameterFactory typeParameterFactory,
  });

  ConstructorEncoding createEncoding({required bool isExternal});
}

class RegularConstructorEncodingStrategy
    implements ConstructorEncodingStrategy {
  const new();

  @override
  ConstructorEncoding createEncoding({required bool isExternal}) {
    return new RegularConstructorEncoding(
      isExternal: isExternal,
      isEnumConstructor: false,
    );
  }

  @override
  List<FormalParameterBuilder>? createFormals({
    required SourceLoader loader,
    required List<FormalParameterBuilder>? formals,
    required Uri fileUri,
    required int fileOffset,
  }) {
    return formals;
  }

  @override
  List<SourceNominalParameterBuilder>? createTypeParameters({
    required DeclarationBuilder declarationBuilder,
    required List<TypeParameterFragment>? declarationTypeParameterFragments,
    required List<SourceNominalParameterBuilder>? typeParameters,
    required TypeParameterFactory typeParameterFactory,
  }) {
    return typeParameters;
  }
}

class EnumConstructorEncodingStrategy implements ConstructorEncodingStrategy {
  const new();

  @override
  ConstructorEncoding createEncoding({required bool isExternal}) {
    return new RegularConstructorEncoding(
      isExternal: isExternal,
      isEnumConstructor: true,
    );
  }

  @override
  List<FormalParameterBuilder>? createFormals({
    required SourceLoader loader,
    required List<FormalParameterBuilder>? formals,
    required Uri fileUri,
    required int fileOffset,
  }) {
    return [
      new FormalParameterBuilder(
        kind: FormalParameterKind.requiredPositional,
        modifiers: Modifiers.empty,
        type: loader.target.intType,
        name: "#index",
        fileOffset: fileOffset,
        fileUri: fileUri,
        nameOffset: null,
        hasImmediatelyDeclaredDefaultValue: false,
      ),
      new FormalParameterBuilder(
        kind: FormalParameterKind.requiredPositional,
        modifiers: Modifiers.empty,
        type: loader.target.stringType,
        name: "#name",
        fileOffset: fileOffset,
        fileUri: fileUri,
        nameOffset: null,
        hasImmediatelyDeclaredDefaultValue: false,
      ),
      ...?formals,
    ];
  }

  @override
  List<SourceNominalParameterBuilder>? createTypeParameters({
    required DeclarationBuilder declarationBuilder,
    required List<TypeParameterFragment>? declarationTypeParameterFragments,
    required List<SourceNominalParameterBuilder>? typeParameters,
    required TypeParameterFactory typeParameterFactory,
  }) {
    return typeParameters;
  }
}

class ExtensionConstructorEncodingStrategy
    implements ConstructorEncodingStrategy {
  const new();

  @override
  ConstructorEncoding createEncoding({required bool isExternal}) {
    return new ExtensionConstructorEncoding(isExternal: isExternal);
  }

  @override
  List<FormalParameterBuilder>? createFormals({
    required SourceLoader loader,
    required List<FormalParameterBuilder>? formals,
    required Uri fileUri,
    required int fileOffset,
  }) {
    return formals;
  }

  @override
  List<SourceNominalParameterBuilder>? createTypeParameters({
    required DeclarationBuilder declarationBuilder,
    required List<TypeParameterFragment>? declarationTypeParameterFragments,
    required List<SourceNominalParameterBuilder>? typeParameters,
    required TypeParameterFactory typeParameterFactory,
  }) {
    NominalParameterCopy? nominalVariableCopy = typeParameterFactory
        .copyTypeParameters(
          oldParameterBuilders: declarationBuilder.typeParameters,
          oldParameterFragments: declarationTypeParameterFragments,
          kind: TypeParameterKind.extensionSynthesized,
          instanceTypeParameterAccess: InstanceTypeParameterAccessState.Allowed,
        );
    if (nominalVariableCopy != null) {
      if (typeParameters != null) {
        // Coverage-ignore-block(suite): Not run.
        typeParameters = nominalVariableCopy.newParameterBuilders
          ..addAll(typeParameters);
      } else {
        typeParameters = nominalVariableCopy.newParameterBuilders;
      }
    }
    return typeParameters;
  }
}

class ExtensionTypeConstructorEncodingStrategy
    implements ConstructorEncodingStrategy {
  const new();

  @override
  List<FormalParameterBuilder>? createFormals({
    required SourceLoader loader,
    required List<FormalParameterBuilder>? formals,
    required Uri fileUri,
    required int fileOffset,
  }) {
    return formals;
  }

  @override
  List<SourceNominalParameterBuilder>? createTypeParameters({
    required DeclarationBuilder declarationBuilder,
    required List<TypeParameterFragment>? declarationTypeParameterFragments,
    required List<SourceNominalParameterBuilder>? typeParameters,
    required TypeParameterFactory typeParameterFactory,
  }) {
    NominalParameterCopy? nominalVariableCopy = typeParameterFactory
        .copyTypeParameters(
          oldParameterBuilders: declarationBuilder.typeParameters,
          oldParameterFragments: declarationTypeParameterFragments,
          kind: TypeParameterKind.extensionSynthesized,
          instanceTypeParameterAccess: InstanceTypeParameterAccessState.Allowed,
        );
    if (nominalVariableCopy != null) {
      if (typeParameters != null) {
        // Coverage-ignore-block(suite): Not run.
        typeParameters = nominalVariableCopy.newParameterBuilders
          ..addAll(typeParameters);
      } else {
        typeParameters = nominalVariableCopy.newParameterBuilders;
      }
    }
    return typeParameters;
  }

  @override
  ConstructorEncoding createEncoding({required bool isExternal}) {
    return new ExtensionTypeConstructorEncoding(isExternal: isExternal);
  }
}

class _RegularConstructorContext implements ConstructorContext {
  final SourceConstructorBuilder _builder;

  new(this._builder);

  @override
  // Coverage-ignore(suite): Not run.
  FunctionSignature get signature => _builder.signature;

  @override
  DartType substituteFieldType(DartType fieldType) {
    return _builder.substituteFieldType(fieldType);
  }

  @override
  Variable? get thisVariable => null;
}

class _ExtensionTypeConstructorContext implements ConstructorContext {
  final SourceConstructorBuilder _builder;

  @override
  final Variable thisVariable;

  new(this._builder, this.thisVariable);

  @override
  FunctionSignature get signature => _builder.signature;

  @override
  DartType substituteFieldType(DartType fieldType) {
    return _builder.substituteFieldType(fieldType);
  }
}
