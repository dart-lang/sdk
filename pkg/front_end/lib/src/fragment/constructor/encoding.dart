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
import '../../builder/named_type_builder.dart';
import '../../builder/omitted_type_builder.dart';
import '../../builder/type_builder.dart';
import '../../kernel/body_builder_context.dart';
import '../../kernel/constructor_tearoff_lowering.dart';
import '../../kernel/internal_ast.dart';
import '../../kernel/kernel_helper.dart';
import '../../source/builder_factory.dart';
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
import '../../type_inference/type_schema.dart';
import '../fragment.dart';
import 'body_builder_context.dart';
import 'declaration.dart';

abstract class ConstructorEncoding {
  FunctionNode get function;

  List<Initializer> get initializers;

  void prepareInitializers();

  void prependInitializer(Initializer initializer);

  VariableDeclaration getFormalParameter(int index);

  VariableDeclaration? getTearOffParameter(int index);

  VariableDeclaration? get thisVariable;

  List<TypeParameter>? get thisTypeParameters;

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
      ConstructorFragmentDeclaration constructorDeclaration);

  void registerFunctionBody(Statement value);

  void registerNoBodyConstructor();

  void addSuperParameterDefaultValueCloners(
      {required List<DelayedDefaultValueCloner> delayedDefaultValueCloners,
      required Member superTarget,
      required List<int?>? positionalSuperParameters,
      required List<String>? namedSuperParameters,
      required SourceLibraryBuilder libraryBuilder});

  void becomeNative(SourceLoader loader, String nativeMethodName);

  Substitution computeFieldTypeSubstitution(
      covariant DeclarationBuilder declarationBuilder,
      List<SourceNominalParameterBuilder>? typeParameters);

  bool get isRedirecting;
}

class RegularConstructorEncoding implements ConstructorEncoding {
  late final Constructor _constructor;

  late final Procedure? _constructorTearOff;

  final bool _isExternal;

  final bool _isEnumConstructor;

  Statement? bodyInternal;

  RegularConstructorEncoding(
      {required bool isExternal, required bool isEnumConstructor})
      : _isExternal = isExternal,
        _isEnumConstructor = isEnumConstructor;

  @override
  void registerFunctionBody(Statement value) {
    function.body = value..parent = function;
  }

  @override
  void registerNoBodyConstructor() {
    if (!_isExternal) {
      registerFunctionBody(new EmptyStatement());
    }
  }

  @override
  FunctionNode get function => _constructor.function;

  // Coverage-ignore(suite): Not run.
  Member get constructor => _constructor;

  // Coverage-ignore(suite): Not run.
  Procedure? get constructorTearOff => _constructorTearOff;

  @override
  List<Initializer> get initializers => _constructor.initializers;

  @override
  bool get isRedirecting {
    for (Initializer initializer in initializers) {
      if (initializer is RedirectingInitializer) {
        return true;
      }
    }
    return false;
  }

  @override
  VariableDeclaration? get thisVariable => null;

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
        delayedDefaultValueCloners: delayedDefaultValueCloners);
    f(
        member: _constructor,
        tearOff: _constructorTearOff,
        kind: BuiltMemberKind.Constructor);
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
      _constructor = new Constructor(
          new FunctionNode(_isExternal ? null : new EmptyStatement()),
          name: dummyName,
          fileUri: fileUri,
          reference: constructorReferences?.constructorReference,
          isSynthetic: isSynthetic)
        ..startFileOffset = startOffset
        ..fileOffset = fileOffset
        ..fileEndOffset = endOffset;
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
              forAbstractClassOrEnumOrMixin || _isEnumConstructor);

      // According to the specification §9.3 the return type of a constructor
      // function is its enclosing class.
      function.asyncMarker = AsyncMarker.Sync;
      buildTypeParametersAndFormals(
          libraryBuilder, function, typeParameters, formals,
          classTypeParameters: null, supportsTypeParameters: false);
      Class enclosingClass = classBuilder.cls;
      List<DartType> typeParameterTypes = <DartType>[];
      for (int i = 0; i < enclosingClass.typeParameters.length; i++) {
        TypeParameter typeParameter = enclosingClass.typeParameters[i];
        typeParameterTypes
            .add(new TypeParameterType.withDefaultNullability(typeParameter));
      }
      InterfaceType type = new InterfaceType(
          enclosingClass, Nullability.nonNullable, typeParameterTypes);
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
                libraryBuilder: libraryBuilder);
        delayedDefaultValueCloners.add(delayedDefaultValueCloner);
      }

      _hasBeenBuilt = true;
    }
    if (formals != null) {
      bool needsInference = false;
      for (FormalParameterBuilder formal in formals) {
        if (formal.type is InferableTypeBuilder &&
            (formal.isInitializingFormal || formal.isSuperInitializingFormal)) {
          formal.variable!.type = const UnknownType();
          needsInference = true;
        } else if (!formal.hasDeclaredInitializer &&
            formal.isSuperInitializingFormal) {
          needsInference = true;
        }
      }
      if (needsInference) {
        libraryBuilder.loader.registerConstructorToBeInferred(
            new InferableConstructor(_constructor, constructorBuilder));
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
    _constructor.initializers = [];
    // TODO(johnniwinther): Can these be moved here from the
    //  [SourceConstructorBuilder]?
    //redirectingInitializer = null;
    //superInitializer = null;
  }

  @override
  void prependInitializer(Initializer initializer) {
    initializer.parent = _constructor;
    _constructor.initializers.insert(0, initializer);
  }

  @override
  void becomeNative(SourceLoader loader, String nativeMethodName) {
    _constructor.isExternal = true;

    loader.addNativeAnnotation(_constructor, nativeMethodName);
  }

  @override
  VariableDeclaration getFormalParameter(int index) {
    if (_isEnumConstructor) {
      // Skip synthetic parameters for index and name.
      index += 2;
    }
    if (index < function.positionalParameters.length) {
      return function.positionalParameters[index];
    } else {
      index -= function.positionalParameters.length;
      assert(index < function.namedParameters.length);
      return function.namedParameters[index];
    }
  }

  @override
  VariableDeclaration? getTearOffParameter(int index) {
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
  void addSuperParameterDefaultValueCloners(
      {required List<DelayedDefaultValueCloner> delayedDefaultValueCloners,
      required Member superTarget,
      required List<int?>? positionalSuperParameters,
      required List<String>? namedSuperParameters,
      required SourceLibraryBuilder libraryBuilder}) {
    if (!_hasAddedDefaultValueCloners) {
      // If this constructor formals are part of a cyclic dependency this
      // might be called more than once.
      delayedDefaultValueCloners.add(new DelayedDefaultValueCloner(
          superTarget, _constructor,
          positionalSuperParameters: positionalSuperParameters ?? const <int>[],
          namedSuperParameters: namedSuperParameters ?? const <String>[],
          isOutlineNode: true,
          libraryBuilder: libraryBuilder));
      if (_constructorTearOff != null) {
        delayedDefaultValueCloners.add(new DelayedDefaultValueCloner(
            superTarget, _constructorTearOff,
            positionalSuperParameters:
                positionalSuperParameters ?? const <int>[],
            namedSuperParameters: namedSuperParameters ?? const <String>[],
            isOutlineNode: true,
            libraryBuilder: libraryBuilder));
      }
      _hasAddedDefaultValueCloners = true;
    }
  }

  @override
  BodyBuilderContext createBodyBuilderContext(
      SourceConstructorBuilder constructorBuilder,
      ConstructorFragmentDeclaration constructorDeclaration) {
    return new ConstructorBodyBuilderContext(
        constructorBuilder, constructorDeclaration, _constructor);
  }

  @override
  void markAsErroneous() {
    _constructor.isErroneous = true;
  }

  @override
  Substitution computeFieldTypeSubstitution(
      covariant DeclarationBuilder declarationBuilder,
      List<SourceNominalParameterBuilder>? typeParameters) {
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

  /// If this procedure is an extension instance member or extension type
  /// instance member, [_thisVariable] holds the synthetically added `this`
  /// parameter.
  VariableDeclaration? _thisVariable;

  /// If this procedure is an extension instance member or extension type
  /// instance member, [_thisTypeParameters] holds the type parameters copied
  /// from the extension/extension type declaration.
  List<TypeParameter>? _thisTypeParameters;

  List<Initializer> _initializers = [];

  @override
  List<Initializer> get initializers => _initializers;

  @override
  void registerFunctionBody(Statement value) {
    function.body = value..parent = function;
  }

  @override
  void registerNoBodyConstructor() {
    if (!_hasBuiltBody && !_isExternal) {
      registerFunctionBody(new EmptyStatement());
    }
  }

  @override
  FunctionNode get function => _constructor.function;

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
      _constructor = new Procedure(dummyName, ProcedureKind.Method,
          new FunctionNode(_isExternal ? null : new EmptyStatement()),
          fileUri: fileUri,
          reference: constructorReferences?.constructorReference)
        ..fileOffset = fileOffset
        ..fileEndOffset = endOffset;
      nameScheme
          .getConstructorMemberName(name, isTearOff: false)
          .attachMember(_constructor);
      _constructorTearOff = createConstructorTearOffProcedure(
          nameScheme.getConstructorMemberName(name, isTearOff: true),
          libraryBuilder,
          fileUri,
          fileOffset,
          constructorReferences?.tearOffReference,
          forAbstractClassOrEnumOrMixin: forAbstractClassOrEnumOrMixin,
          forceCreateLowering: true)
        ?..isExtensionMember = _isExtensionMember
        ..isExtensionTypeMember = _isExtensionTypeMember;

      // According to the specification §9.3 the return type of a constructor
      // function is its enclosing class.
      function.asyncMarker = AsyncMarker.Sync;
      buildTypeParametersAndFormals(
          libraryBuilder, function, typeParameters, formals,
          classTypeParameters: null, supportsTypeParameters: true);

      if (declarationBuilder.typeParameters != null) {
        int count = declarationBuilder.typeParameters!.length;
        _thisTypeParameters = new List<TypeParameter>.generate(
            count, (int index) => function.typeParameters[index],
            growable: false);
      }
      List<DartType> typeArguments;
      if (_thisTypeParameters != null) {
        typeArguments = [
          for (TypeParameter parameter in _thisTypeParameters!)
            new TypeParameterType.withDefaultNullability(parameter)
        ];
      } else {
        typeArguments = [];
      }

      _thisVariable = new VariableDeclarationImpl(syntheticThisName,
          isFinal: true,
          type: _computeThisType(declarationBuilder, typeArguments))
        ..fileOffset = fileOffset
        ..isLowered = true;

      List<DartType> typeParameterTypes = <DartType>[];
      for (int i = 0; i < function.typeParameters.length; i++) {
        TypeParameter typeParameter = function.typeParameters[i];
        typeParameterTypes
            .add(new TypeParameterType.withDefaultNullability(typeParameter));
      }
      returnType.registerInferredType(
          _computeThisType(declarationBuilder, typeParameterTypes));
      _constructor.function.fileOffset = formalsOffset;
      _constructor.function.fileEndOffset = _constructor.fileEndOffset;
      _constructor.isConst = isConst;
      _constructor.isExternal = _isExternal;
      _constructor.isStatic = true;
      _constructor.isExtensionMember = _isExtensionMember;
      _constructor.isExtensionTypeMember = _isExtensionTypeMember;

      if (_constructorTearOff != null) {
        delayedDefaultValueCloners.add(buildConstructorTearOffProcedure(
            tearOff: _constructorTearOff,
            declarationConstructor: _constructor,
            implementationConstructor: _constructor,
            libraryBuilder: libraryBuilder));
      }

      _hasBeenBuilt = true;
    }
    if (formals != null) {
      bool needsInference = false;
      for (FormalParameterBuilder formal in formals) {
        if (formal.type is InferableTypeBuilder &&
            (formal.isInitializingFormal || formal.isSuperInitializingFormal)) {
          formal.variable!.type = const UnknownType();
          needsInference = true;
        } else if (!formal.hasDeclaredInitializer &&
            formal.isSuperInitializingFormal) {
          needsInference = true;
        }
      }
      if (needsInference) {
        libraryBuilder.loader.registerConstructorToBeInferred(
            new InferableConstructor(_constructor, constructorBuilder));
      }
    }
  }

  @override
  VariableDeclaration? get thisVariable {
    assert(_thisVariable != null,
        "ProcedureBuilder.thisVariable has not been set.");
    return _thisVariable;
  }

  @override
  List<TypeParameter>? get thisTypeParameters {
    // Use [_thisVariable] as marker for whether this type parameters have
    // been computed.
    assert(_thisVariable != null,
        "ProcedureBuilder.thisTypeParameters has not been set.");
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
    _initializers = [];
    // TODO(johnniwinther): Can these be moved here from the
    //  [SourceConstructorBuilder]?
    //redirectingInitializer = null;
    //superInitializer = null;
  }

  @override
  void prependInitializer(Initializer initializer) {
    _initializers.insert(0, initializer);
  }

  @override
  VariableDeclaration getFormalParameter(int index) {
    if (index < function.positionalParameters.length) {
      return function.positionalParameters[index];
    } else {
      index -= function.positionalParameters.length;
      assert(index < function.namedParameters.length);
      return function.namedParameters[index];
    }
  }

  @override
  VariableDeclaration? getTearOffParameter(int index) {
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
      VariableDeclaration thisVariable = this.thisVariable!;
      List<Statement> statements = [thisVariable];
      _ExtensionTypeInitializerToStatementConverter visitor =
          new _ExtensionTypeInitializerToStatementConverter(
              statements, thisVariable);
      for (Initializer initializer in _initializers) {
        initializer.accept(visitor);
      }
      if (function.body != null && function.body is! EmptyStatement) {
        statements.add(function.body!);
      }
      statements.add(new ReturnStatement(new VariableGet(thisVariable)));
      registerFunctionBody(new Block(statements));
    }
    _hasBuiltBody = true;
  }

  @override
  BodyBuilderContext createBodyBuilderContext(
      SourceConstructorBuilder constructorBuilder,
      ConstructorFragmentDeclaration constructorDeclaration) {
    return new ConstructorBodyBuilderContext(
        constructorBuilder, constructorDeclaration, _constructor);
  }

  @override
  void markAsErroneous() {
    _constructor.isErroneous = true;
  }

  @override
  void addSuperParameterDefaultValueCloners(
      {required List<DelayedDefaultValueCloner> delayedDefaultValueCloners,
      required Member superTarget,
      required List<int?>? positionalSuperParameters,
      required List<String>? namedSuperParameters,
      required SourceLibraryBuilder libraryBuilder}) {
    throw new UnsupportedError(
        '$runtimeType.addSuperParameterDefaultValueCloners');
  }

  @override
  void becomeNative(SourceLoader loader, String nativeMethodName) {
    throw new UnsupportedError('$runtimeType.becomeNative');
  }
}

class _ExtensionTypeInitializerToStatementConverter
    implements InitializerVisitor<void> {
  VariableDeclaration thisVariable;
  final List<Statement> statements;

  _ExtensionTypeInitializerToStatementConverter(
      this.statements, this.thisVariable);

  @override
  void visitAssertInitializer(AssertInitializer node) {
    statements.add(node.statement);
  }

  @override
  void visitAuxiliaryInitializer(AuxiliaryInitializer node) {
    if (node is ExtensionTypeRedirectingInitializer) {
      statements.add(new ExpressionStatement(
          new VariableSet(
              thisVariable,
              new StaticInvocation(node.target, node.arguments)
                ..fileOffset = node.fileOffset)
            ..fileOffset = node.fileOffset)
        ..fileOffset = node.fileOffset);
      return;
    } else if (node is ExtensionTypeRepresentationFieldInitializer) {
      thisVariable
        ..initializer = (node.value..parent = thisVariable)
        ..fileOffset = node.fileOffset;
      return;
    }
    // Coverage-ignore-block(suite): Not run.
    throw new UnsupportedError(
        "Unexpected initializer $node (${node.runtimeType})");
  }

  @override
  // Coverage-ignore(suite): Not run.
  void visitFieldInitializer(FieldInitializer node) {
    thisVariable
      ..initializer = (node.value..parent = thisVariable)
      ..fileOffset = node.fileOffset;
  }

  @override
  // Coverage-ignore(suite): Not run.
  void visitInvalidInitializer(InvalidInitializer node) {
    statements.add(new ExpressionStatement(
        new InvalidExpression(null)..fileOffset = node.fileOffset)
      ..fileOffset);
  }

  @override
  void visitLocalInitializer(LocalInitializer node) {
    statements.add(node.variable);
  }

  @override
  void visitRedirectingInitializer(RedirectingInitializer node) {
    throw new UnsupportedError(
        "Unexpected initializer $node (${node.runtimeType})");
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
            SourceExtensionTypeDeclarationBuilder>
    implements
        ConstructorEncoding {
  @override
  final bool _isExternal;

  ExtensionTypeConstructorEncoding({required bool isExternal})
      : _isExternal = isExternal;

  @override
  DartType _computeThisType(
      SourceExtensionTypeDeclarationBuilder declarationBuilder,
      List<DartType> typeArguments) {
    ExtensionTypeDeclaration extensionTypeDeclaration =
        declarationBuilder.extensionTypeDeclaration;
    return new ExtensionType(
        extensionTypeDeclaration, Nullability.nonNullable, typeArguments);
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
        formalsOffset: formalsOffset,
        endOffset: endOffset,
        forAbstractClassOrEnumOrMixin: forAbstractClassOrEnumOrMixin,
        isConst: isConst,
        returnType: returnType,
        typeParameters: typeParameters,
        formals: formals,
        delayedDefaultValueCloners: delayedDefaultValueCloners);
    f(
        member: _constructor,
        tearOff: _constructorTearOff,
        kind: BuiltMemberKind.ExtensionTypeConstructor);
  }

  @override
  bool get _isExtensionMember => false;

  @override
  bool get _isExtensionTypeMember => true;

  @override
  Substitution computeFieldTypeSubstitution(
      DeclarationBuilder declarationBuilder,
      List<SourceNominalParameterBuilder>? typeParameters) {
    if (typeParameters != null) {
      assert(
          declarationBuilder.typeParameters!.length == typeParameters.length);
      return Substitution.fromPairs(
          (declarationBuilder as SourceExtensionTypeDeclarationBuilder)
              .extensionTypeDeclaration
              .typeParameters,
          new List<DartType>.generate(
              declarationBuilder.typeParameters!.length,
              (int index) => new TypeParameterType.withDefaultNullability(
                  function.typeParameters[index])));
    } else {
      return Substitution.empty;
    }
  }

  @override
  bool get isRedirecting {
    for (Initializer initializer in initializers) {
      if (initializer is ExtensionTypeRedirectingInitializer) {
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

  ExtensionConstructorEncoding({required bool isExternal})
      : _isExternal = isExternal;

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
        formalsOffset: formalsOffset,
        endOffset: endOffset,
        forAbstractClassOrEnumOrMixin: forAbstractClassOrEnumOrMixin,
        isConst: isConst,
        returnType: returnType,
        typeParameters: typeParameters,
        formals: formals,
        delayedDefaultValueCloners: delayedDefaultValueCloners);
    // Extension constructors are erroneous and are therefore not added to the
    // AST.
  }

  @override
  bool get _isExtensionMember => true;

  @override
  bool get _isExtensionTypeMember => false;

  @override
  DartType _computeThisType(
      SourceExtensionBuilder declarationBuilder, List<DartType> typeArguments) {
    Extension extension = declarationBuilder.extension;
    return Substitution.fromPairs(extension.typeParameters, typeArguments)
        .substituteType(extension.onType);
  }

  @override
  // Coverage-ignore(suite): Not run.
  Substitution computeFieldTypeSubstitution(
      SourceExtensionBuilder declarationBuilder,
      List<SourceNominalParameterBuilder>? typeParameters) {
    if (typeParameters != null) {
      assert(
          declarationBuilder.typeParameters!.length == typeParameters.length);
      return Substitution.fromPairs(
          declarationBuilder.extension.typeParameters,
          new List<DartType>.generate(
              declarationBuilder.typeParameters!.length,
              (int index) => new TypeParameterType.withDefaultNullability(
                  function.typeParameters[index])));
    } else {
      return Substitution.empty;
    }
  }

  @override
  // Coverage-ignore(suite): Not run.
  bool get isRedirecting {
    // TODO(johnniwinther): Update this if redirecting extension constructors
    //  are supported.
    return false;
  }
}

abstract class ConstructorEncodingStrategy {
  factory ConstructorEncodingStrategy(DeclarationBuilder declarationBuilder) {
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
    required List<NominalParameterBuilder> unboundNominalParameters,
  });

  ConstructorEncoding createEncoding({required bool isExternal});
}

class RegularConstructorEncodingStrategy
    implements ConstructorEncodingStrategy {
  const RegularConstructorEncodingStrategy();

  @override
  ConstructorEncoding createEncoding({required bool isExternal}) {
    return new RegularConstructorEncoding(
        isExternal: isExternal, isEnumConstructor: false);
  }

  @override
  List<FormalParameterBuilder>? createFormals(
      {required SourceLoader loader,
      required List<FormalParameterBuilder>? formals,
      required Uri fileUri,
      required int fileOffset}) {
    return formals;
  }

  @override
  List<SourceNominalParameterBuilder>? createTypeParameters(
      {required DeclarationBuilder declarationBuilder,
      required List<TypeParameterFragment>? declarationTypeParameterFragments,
      required List<SourceNominalParameterBuilder>? typeParameters,
      required List<NominalParameterBuilder> unboundNominalParameters}) {
    return typeParameters;
  }
}

class EnumConstructorEncodingStrategy implements ConstructorEncodingStrategy {
  const EnumConstructorEncodingStrategy();

  @override
  ConstructorEncoding createEncoding({required bool isExternal}) {
    return new RegularConstructorEncoding(
        isExternal: isExternal, isEnumConstructor: true);
  }

  @override
  List<FormalParameterBuilder>? createFormals({
    required SourceLoader loader,
    required List<FormalParameterBuilder>? formals,
    required Uri fileUri,
    required int fileOffset,
  }) {
    return [
      new FormalParameterBuilder(FormalParameterKind.requiredPositional,
          Modifiers.empty, loader.target.intType, "#index", fileOffset,
          fileUri: fileUri, hasImmediatelyDeclaredInitializer: false),
      new FormalParameterBuilder(FormalParameterKind.requiredPositional,
          Modifiers.empty, loader.target.stringType, "#name", fileOffset,
          fileUri: fileUri, hasImmediatelyDeclaredInitializer: false),
      ...?formals
    ];
  }

  @override
  List<SourceNominalParameterBuilder>? createTypeParameters(
      {required DeclarationBuilder declarationBuilder,
      required List<TypeParameterFragment>? declarationTypeParameterFragments,
      required List<SourceNominalParameterBuilder>? typeParameters,
      required List<NominalParameterBuilder> unboundNominalParameters}) {
    return typeParameters;
  }
}

class ExtensionConstructorEncodingStrategy
    implements ConstructorEncodingStrategy {
  const ExtensionConstructorEncodingStrategy();

  @override
  ConstructorEncoding createEncoding({required bool isExternal}) {
    return new ExtensionConstructorEncoding(isExternal: isExternal);
  }

  @override
  List<FormalParameterBuilder>? createFormals(
      {required SourceLoader loader,
      required List<FormalParameterBuilder>? formals,
      required Uri fileUri,
      required int fileOffset}) {
    return formals;
  }

  @override
  List<SourceNominalParameterBuilder>? createTypeParameters(
      {required DeclarationBuilder declarationBuilder,
      required List<TypeParameterFragment>? declarationTypeParameterFragments,
      required List<SourceNominalParameterBuilder>? typeParameters,
      required List<NominalParameterBuilder> unboundNominalParameters}) {
    NominalParameterCopy? nominalVariableCopy =
        NominalParameterCopy.copyTypeParameters(
            unboundNominalParameters: unboundNominalParameters,
            oldParameterBuilders: declarationBuilder.typeParameters,
            oldParameterFragments: declarationTypeParameterFragments,
            kind: TypeParameterKind.extensionSynthesized,
            instanceTypeParameterAccess:
                InstanceTypeParameterAccessState.Allowed);
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
  const ExtensionTypeConstructorEncodingStrategy();

  @override
  List<FormalParameterBuilder>? createFormals(
      {required SourceLoader loader,
      required List<FormalParameterBuilder>? formals,
      required Uri fileUri,
      required int fileOffset}) {
    return formals;
  }

  @override
  List<SourceNominalParameterBuilder>? createTypeParameters({
    required DeclarationBuilder declarationBuilder,
    required List<TypeParameterFragment>? declarationTypeParameterFragments,
    required List<SourceNominalParameterBuilder>? typeParameters,
    required List<NominalParameterBuilder> unboundNominalParameters,
  }) {
    NominalParameterCopy? nominalVariableCopy =
        NominalParameterCopy.copyTypeParameters(
            unboundNominalParameters: unboundNominalParameters,
            oldParameterBuilders: declarationBuilder.typeParameters,
            oldParameterFragments: declarationTypeParameterFragments,
            kind: TypeParameterKind.extensionSynthesized,
            instanceTypeParameterAccess:
                InstanceTypeParameterAccessState.Allowed);
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
