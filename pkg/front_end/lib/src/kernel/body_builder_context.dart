// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/transformations/flags.dart';

import '../base/constant_context.dart' show ConstantContext;
import '../base/local_scope.dart';
import '../base/lookup_result.dart';
import '../builder/builder.dart';
import '../builder/declaration_builders.dart';
import '../builder/formal_parameter_builder.dart';
import '../builder/library_builder.dart';
import '../builder/named_type_builder.dart';
import '../builder/type_builder.dart';
import '../dill/dill_class_builder.dart';
import '../source/source_class_builder.dart';
import '../source/source_constructor_builder.dart';
import '../source/source_enum_builder.dart';
import '../source/source_extension_builder.dart';
import '../source/source_extension_type_declaration_builder.dart';
import '../source/source_library_builder.dart';
import '../source/source_member_builder.dart';
import '../source/source_property_builder.dart';
import '../source/source_type_alias_builder.dart';
import '../type_inference/context_allocation_strategy.dart';
import '../type_inference/inference_results.dart'
    show InitializerInferenceResult;
import '../type_inference/type_inferrer.dart' show TypeInferrer;
import 'internal_ast.dart';

/// Interface that defines the interface between the [BodyBuilder] and the
/// member/declaration whose AST is being built.
abstract class BodyBuilderContext {
  final BodyBuilderDeclarationContext declarationContext;

  final bool _isDeclarationInstanceMember;

  BodyBuilderContext(
    LibraryBuilder libraryBuilder,
    DeclarationBuilder? declarationBuilder, {
    required bool isDeclarationInstanceMember,
  }) : _isDeclarationInstanceMember = isDeclarationInstanceMember,
       declarationContext = new BodyBuilderDeclarationContext(
         libraryBuilder,
         declarationBuilder,
       );

  /// Returns `true` if the enclosing declaration declares a const constructor.
  bool get declarationDeclaresConstConstructor =>
      declarationContext.declaresConstConstructor;

  /// Returns the file offset of the name of the member whose body is being
  /// built.
  ///
  /// For an unnamed constructor this is offset of the class name.
  ///
  /// This is used for error reporting.
  // TODO(johnniwinther): Replaces this with something better. It is not only
  // used for error reporting.
  int get memberNameOffset {
    throw new UnsupportedError("${runtimeType}.memberNameOffset");
  }

  /// Returns the length of the name of the member whose body is being built.
  ///
  /// For an unnamed constructor this is 0.
  ///
  /// This is used for error reporting.
  // TODO(johnniwinther): Replaces this with something better.
  int get memberNameLength {
    throw new UnsupportedError('${runtimeType}.memberNameLength');
  }

  /// Looks up the member by the given [name] in the superclass of the enclosing
  /// class.
  ///
  /// If [isSetter] is `true`, a setable is returned, otherwise a getable is
  /// returned.
  Member? lookupSuperMember(
    ClassHierarchy hierarchy,
    Name name, {
    bool isSetter = false,
  }) {
    return declarationContext.lookupSuperMember(
      hierarchy,
      name,
      isSetter: isSetter,
    );
  }

  /// Looks up the constructor by the given [name] in the enclosing declaration.
  Builder? lookupConstructor(Name name) {
    return declarationContext.lookupConstructor(name);
  }

  /// Creates an [Initializer] for a redirecting initializer call to
  /// [constructorBuilder] with the given [arguments] from within a constructor
  /// in the same class.
  Initializer buildRedirectingInitializer(
    Builder constructorBuilder,
    ActualArguments arguments, {
    required int fileOffset,
  }) {
    return declarationContext.buildRedirectingInitializer(
      constructorBuilder,
      arguments,
      fileOffset: fileOffset,
    );
  }

  /// Looks up the constructor by the given [name] in the superclass of the
  /// enclosing class.
  MemberLookupResult? lookupSuperConstructor(
    String name,
    LibraryBuilder accessingLibrary,
  ) {
    return declarationContext.lookupSuperConstructor(name, accessingLibrary);
  }

  /// Looks up the member by the given [name] declared in the enclosing
  /// declaration or library.
  LookupResult? lookupLocalMember(String name) {
    return declarationContext.lookupLocalMember(name);
  }

  /// Returns `true` if the enclosing entity is an extension type.
  bool get isExtensionTypeDeclaration =>
      declarationContext.isExtensionTypeDeclaration;

  /// Returns `true` if the enclosing entity is an extension.
  bool get isExtensionDeclaration => declarationContext.isExtensionDeclaration;

  /// Returns the [FormalParameterBuilder] by the given [nameOffset] declared in
  /// the member whose body is being built.
  FormalParameterBuilder? getFormalParameterByNameOffset(int nameOffset) {
    if (formals != null) {
      List<FormalParameterBuilder> formals = this.formals!;
      for (int i = 0; i < formals.length; i++) {
        FormalParameterBuilder formal = formals[i];
        if (formal.nameOffset == nameOffset) {
          return formal;
        }
      }
      // Coverage-ignore(suite): Not run.
      // If we have any formals we should find the one we're looking for.
      assert(false, "Formal @ $nameOffset not found in $formals");
    }
    return null;
  }

  /// Returns `true` if the member whose body is being built is a non-factory
  /// constructor declaration.
  bool get isConstructor => false;

  // Coverage-ignore(suite): Not run.
  /// Returns `true` if the member whose body is being built is a non-factory
  /// constructor declaration marked as `external`.
  bool get isExternalConstructor => false;

  // Coverage-ignore(suite): Not run.
  /// Returns `true` if the member whose body is being built is a constructor,
  /// factory, method, getter, or setter marked as `external`.
  bool get isExternalFunction => false;

  // Coverage-ignore(suite): Not run.
  /// Returns `true` if the member whose body is being built is a non-factory
  /// constructor declaration marked as `const`.
  bool get isConstConstructor => false;

  // Coverage-ignore(suite): Not run.
  /// Returns `true` if the member whose body is being built is a (redirecting)
  /// factory declaration.
  bool get isFactory => false;

  /// Returns `true` if the member whose body is being built is marked as
  /// native.
  bool get isNativeMethod => false;

  /// Returns `true` if the member whose body is built is an instance member
  /// or a non-factory constructor.
  bool get isDeclarationInstanceContext {
    return _isDeclarationInstanceMember || isConstructor;
  }

  /// Returns `true` if the member whose body is being built is a redirecting
  /// factory declaration.
  bool get isRedirectingFactory => false;

  /// Returns the constructor name, including the class name, of the immediate
  /// target of a redirecting factory constructor.
  ///
  /// This is only supported if [isRedirectingFactory] is `true`.
  ///
  /// This is used for error reporting.
  String get redirectingFactoryTargetName {
    throw new UnsupportedError('${runtimeType}.redirectingFactoryTargetName');
  }

  /// Returns the [InstanceTypeParameterAccessState] for the member whose body
  /// is begin built.
  ///
  /// This is used to determine whether access to instance type parameters is
  /// allowed.
  InstanceTypeParameterAccessState get instanceTypeParameterAccessState {
    if (isDeclarationInstanceContext) {
      return InstanceTypeParameterAccessState.Allowed;
    } else {
      return InstanceTypeParameterAccessState.Disallowed;
    }
  }

  // Coverage-ignore(suite): Not run.
  /// Returns `true` if the constructor whose initializers is being built, needs
  /// to include an implicit super initializer.
  bool needsImplicitSuperInitializer(CoreTypes coreTypes) => false;

  /// Registers that a `super` call has occurred in the body currently being
  /// built.
  ///
  /// This is used to mark the enclosing member node as having a super call.
  void registerSuperCall() {
    throw new UnsupportedError('${runtimeType}.registerSuperCall');
  }

  /// Returns `true` if the constructor by the given [name] is a cyclic
  /// redirecting generative constructor in the enclosing class or extension
  /// type.
  bool isConstructorCyclic(String name) {
    throw new UnsupportedError('${runtimeType}.isConstructorCyclic');
  }

  /// Returns the [ConstantContext] for the body currently being built.
  ConstantContext get constantContext => ConstantContext.none;

  // Coverage-ignore(suite): Not run.
  /// Returns `true` if the member whose body is being built is a late field
  /// declaration.
  bool get isLateField => false;

  // Coverage-ignore(suite): Not run.
  /// Returns `true` if the member whose body is being built is an abstract
  /// field declaration.
  bool get isAbstractField => false;

  // Coverage-ignore(suite): Not run.
  /// Returns `true` if the member whose body is being built is an external
  /// field declaration.
  bool get isExternalField => false;

  /// Returns `true` if the enclosing class of the member whose body is being
  /// built is marked as a `mixin` class.
  bool get isMixinClass => declarationContext.isMixinClass;

  /// Returns `true` if the enclosing class of the member whose body is being
  /// built is marked as an enum.
  bool get isEnumClass => declarationContext.isEnumClass;

  /// Returns the name of the enclosing class or extension type declaration.
  String get className => declarationContext.className;

  /// Returns the name of the superclass of the enclosing class.
  String get superClassName => declarationContext.superClassName;

  /// Substitute [fieldType] from the context of the enclosing class or
  /// extension type declaration of a generative constructor.
  ///
  /// This is used for generic extension type constructors where the type
  /// variable referring to the class type parameters must be substituted for
  /// the synthesized constructor type parameters.
  DartType substituteFieldType(DartType fieldType) {
    throw new UnsupportedError('${runtimeType}.substituteFieldType');
  }

  /// Registers that the field [builder] has been initialized in generative
  /// constructor whose body is being built.
  void registerInitializedField(SourcePropertyBuilder builder) {
    throw new UnsupportedError('${runtimeType}.registerInitializedField');
  }

  /// Returns the [VariableDeclaration] for the [index]th formal parameter
  /// declared in the constructor, factory, or method tear-off currently being
  /// built.
  VariableDeclaration? getTearOffParameter(int index) {
    throw new UnsupportedError('${runtimeType}.getTearOffParameter');
  }

  /// Returns the type context that should be used for return statement in body
  /// currently being built.
  DartType get returnTypeContext {
    throw new UnsupportedError('${runtimeType}.returnTypeContext');
  }

  /// Returns the return type of the constructor, factory, method, getter or
  /// setter currently being built.
  TypeBuilder get returnTypeBuilder {
    throw new UnsupportedError('${runtimeType}.returnType');
  }

  /// Returns the [FormalParameterBuilder]s for the formals of the member whose
  /// body is currently being built, including synthetically added formal
  /// parameters.
  List<FormalParameterBuilder>? get formals {
    throw new UnsupportedError('${runtimeType}.formals');
  }

  /// Returns `true` if the member whose body is currently being built is a
  /// noSuchMethod forwarder.
  bool get isNoSuchMethodForwarder => false;

  /// Computes the scope containing the initializing formals or super
  /// parameters of the constructor currently being built, using [parent] as
  /// the parent scope.
  ///
  /// If a constructor is not currently being built, [parent] is returned.
  LocalScope computeFormalParameterInitializerScope(LocalScope parent) {
    throw new UnsupportedError(
      '${runtimeType}.computeFormalParameterInitializerScope',
    );
  }

  /// Returns the primary constructor parameters available in the initializer
  /// scope for instance field initializers.
  ///
  /// If a non-late instance field is not currently being built, or if the
  /// enclosing declaration doesn't have any primary constructor with
  /// parameters, `null` is returned.
  List<FormalParameterBuilder>?
  get primaryConstructorInitializerScopeParameters {
    throw new UnsupportedError(
      '${runtimeType}.primaryConstructorInitializerScopeParameters',
    );
  }

  /// This is called before parsing constructor initializers.
  ///
  /// The constructor initializers are parsed both in the outline and in the
  /// body building phases, so this clears the initializer parsed during the
  /// outline phases to avoid duplication.
  void prepareInitializers() {
    throw new UnsupportedError('${runtimeType}.prepareInitializers');
  }

  /// This registers [initializers] as the fully resolved initializers of a
  /// constructor.
  void registerInitializers(
    List<Initializer> initializers, {
    required bool isErroneous,
  }) {
    throw new UnsupportedError('${runtimeType}.initializers');
  }

  /// This marks a constructor as erroneous.
  // TODO(johnniwinther): Avoid this.
  void markAsErroneous() {
    throw new UnsupportedError('${runtimeType}.markAsErroneous');
  }

  /// Infers the [initializer].
  InitializerInferenceResult inferInitializer({
    required TypeInferrer typeInferrer,
    required Uri fileUri,
    required Initializer initializer,
  }) {
    throw new UnsupportedError('${runtimeType}.inferInitializer');
  }

  // Coverage-ignore(suite): Not run.
  /// Returns the target for using the `augmented` expression in an augmenting
  /// member.
  AugmentSuperTarget? get augmentSuperTarget {
    return null;
  }

  /// Registers [body] as the result of the body building.
  void registerFunctionBody({
    required Statement? body,
    required ScopeProviderInfo? scopeProviderInfo,
    required AsyncMarker asyncMarker,
    required DartType? emittedValueType,
  }) {
    throw new UnsupportedError("${runtimeType}.registerFunctionBody");
  }

  /// Registers that the constructor has no body.
  void registerNoBodyConstructor() {
    throw new UnsupportedError("${runtimeType}.registerNoBodyConstructor");
  }

  /// Returns the type of `this` in the body being built.
  ///
  /// This is only used for classes. For extensions and extension types, `this`
  /// is handled via a synthetic this variable.
  InterfaceType? get thisType => declarationContext.thisType;

  /// Variable representing `this` in member bodies of classes and similar.
  ///
  /// Declarations with synthesized `this`, such as extensions and extension
  /// types, don't have an internal [ThisVariable] because `this` is desugared
  /// as a parameter in that case.
  ThisVariable? createInternalThisVariable() {
    return thisType != null ? new ThisVariable(type: thisType!) : null;
  }
}

/// Interface that provides information for a [BodyBuilderContext] from the
/// enclosing class-like declaration or library.
abstract class BodyBuilderDeclarationContext {
  final LibraryBuilder _libraryBuilder;

  factory BodyBuilderDeclarationContext(
    LibraryBuilder libraryBuilder,
    DeclarationBuilder? declarationBuilder,
  ) {
    if (declarationBuilder != null) {
      if (declarationBuilder is SourceClassBuilder) {
        return new _SourceClassBodyBuilderDeclarationContext(
          libraryBuilder,
          declarationBuilder,
        );
      } else if (declarationBuilder is DillClassBuilder) {
        // Coverage-ignore-block(suite): Not run.
        return new _DillClassBodyBuilderDeclarationContext(
          libraryBuilder,
          declarationBuilder,
        );
      } else if (declarationBuilder is SourceExtensionTypeDeclarationBuilder) {
        return new _SourceExtensionTypeDeclarationBodyBuilderDeclarationContext(
          libraryBuilder,
          declarationBuilder,
        );
      } else {
        return new _DeclarationBodyBuilderDeclarationContext(
          libraryBuilder,
          declarationBuilder,
        );
      }
    } else {
      return new _TopLevelBodyBuilderDeclarationContext(libraryBuilder);
    }
  }

  BodyBuilderDeclarationContext._(this._libraryBuilder);

  Member? lookupSuperMember(
    ClassHierarchy hierarchy,
    Name name, {
    bool isSetter = false,
  }) {
    throw new UnsupportedError('${runtimeType}.lookupSuperMember');
  }

  Builder? lookupConstructor(Name name) {
    throw new UnsupportedError('${runtimeType}.lookupConstructor');
  }

  Initializer buildRedirectingInitializer(
    Builder constructorBuilder,
    ActualArguments arguments, {
    required int fileOffset,
  }) {
    throw new UnsupportedError('${runtimeType}.buildRedirectingInitializer');
  }

  MemberLookupResult? lookupSuperConstructor(
    String name,
    LibraryBuilder accessingLibrary,
  ) {
    throw new UnsupportedError('${runtimeType}.lookupSuperConstructor');
  }

  LookupResult? lookupLocalMember(String name);

  bool get isExtensionTypeDeclaration => false;

  // Coverage-ignore(suite): Not run.
  bool get isExtensionDeclaration => false;

  bool get isMixinClass => false;

  // Coverage-ignore(suite): Not run.
  bool get isEnumClass => false;

  String get className {
    throw new UnsupportedError('${runtimeType}.className');
  }

  String get superClassName {
    throw new UnsupportedError('${runtimeType}.superClassName');
  }

  InterfaceType? get thisType => null;

  bool isConstructorCyclic(String source, String target) {
    throw new UnsupportedError('${runtimeType}.isConstructorCyclic');
  }

  bool get declaresConstConstructor => false;

  // Coverage-ignore(suite): Not run.
  bool isObjectClass(CoreTypes coreTypes) => false;
}

mixin _DeclarationBodyBuilderDeclarationContextMixin
    implements BodyBuilderDeclarationContext {
  DeclarationBuilder get _declarationBuilder;

  @override
  LookupResult? lookupLocalMember(String name) {
    return _declarationBuilder.lookupLocalMember(name, required: false);
  }

  @override
  InterfaceType? get thisType => _declarationBuilder.thisType;

  @override
  bool get isExtensionDeclaration => _declarationBuilder is ExtensionBuilder;
}

class _SourceClassBodyBuilderDeclarationContext
    extends BodyBuilderDeclarationContext
    with _DeclarationBodyBuilderDeclarationContextMixin {
  final SourceClassBuilder _sourceClassBuilder;

  _SourceClassBodyBuilderDeclarationContext(
    LibraryBuilder libraryBuilder,
    this._sourceClassBuilder,
  ) : super._(libraryBuilder);

  @override
  DeclarationBuilder get _declarationBuilder => _sourceClassBuilder;

  @override
  bool isConstructorCyclic(String source, String target) {
    return _sourceClassBuilder.checkConstructorCyclic(source, target);
  }

  @override
  bool get declaresConstConstructor =>
      _sourceClassBuilder.declaresConstConstructor;

  @override
  bool isObjectClass(CoreTypes coreTypes) {
    return coreTypes.objectClass == _sourceClassBuilder.cls;
  }

  @override
  Member? lookupSuperMember(
    ClassHierarchy hierarchy,
    Name name, {
    bool isSetter = false,
  }) {
    return _sourceClassBuilder.lookupInstanceMember(
      hierarchy,
      name,
      isSetter: isSetter,
      isSuper: true,
    );
  }

  @override
  SourceConstructorBuilder? lookupConstructor(Name name) {
    return _sourceClassBuilder.lookupConstructor(name);
  }

  @override
  Initializer buildRedirectingInitializer(
    covariant SourceConstructorBuilder constructorBuilder,
    ActualArguments arguments, {
    required int fileOffset,
  }) {
    return new InternalRedirectingInitializer(
      constructorBuilder.invokeTarget as Constructor,
      arguments,
    )..fileOffset = fileOffset;
  }

  @override
  MemberLookupResult? lookupSuperConstructor(
    String name,
    LibraryBuilder accessingLibrary,
  ) {
    return _sourceClassBuilder.lookupSuperConstructor(name, accessingLibrary);
  }

  @override
  bool get isMixinClass {
    return _sourceClassBuilder.isMixinClass;
  }

  @override
  bool get isEnumClass {
    return _sourceClassBuilder is SourceEnumBuilder;
  }

  @override
  String get className {
    return _sourceClassBuilder.fullNameForErrors;
  }

  @override
  String get superClassName {
    if (_sourceClassBuilder.supertypeBuilder?.declaration is InvalidBuilder) {
      // Coverage-ignore-block(suite): Not run.
      // TODO(johnniwinther): Avoid reporting errors on missing constructors
      // on invalid super types.
      return _sourceClassBuilder.supertypeBuilder!.fullNameForErrors;
    }
    Class cls = _sourceClassBuilder.cls;
    cls = cls.superclass!;
    while (cls.isMixinApplication) {
      cls = cls.superclass!;
    }
    return cls.name;
  }
}

// Coverage-ignore(suite): Not run.
class _DillClassBodyBuilderDeclarationContext
    extends BodyBuilderDeclarationContext
    with _DeclarationBodyBuilderDeclarationContextMixin {
  @override
  final DillClassBuilder _declarationBuilder;

  _DillClassBodyBuilderDeclarationContext(
    LibraryBuilder libraryBuilder,
    this._declarationBuilder,
  ) : super._(libraryBuilder);

  @override
  Member? lookupSuperMember(
    ClassHierarchy hierarchy,
    Name name, {
    bool isSetter = false,
  }) {
    return _declarationBuilder.lookupInstanceMember(
      hierarchy,
      name,
      isSetter: isSetter,
      isSuper: true,
    );
  }
}

class _SourceExtensionTypeDeclarationBodyBuilderDeclarationContext
    extends BodyBuilderDeclarationContext
    with _DeclarationBodyBuilderDeclarationContextMixin {
  final SourceExtensionTypeDeclarationBuilder
  _sourceExtensionTypeDeclarationBuilder;

  _SourceExtensionTypeDeclarationBodyBuilderDeclarationContext(
    LibraryBuilder libraryBuilder,
    this._sourceExtensionTypeDeclarationBuilder,
  ) : super._(libraryBuilder);

  @override
  DeclarationBuilder get _declarationBuilder =>
      _sourceExtensionTypeDeclarationBuilder;

  @override
  SourceConstructorBuilder? lookupConstructor(Name name) {
    return _sourceExtensionTypeDeclarationBuilder.lookupConstructor(name);
  }

  @override
  bool isConstructorCyclic(String source, String target) {
    // TODO(johnniwinther): Implement this.
    return false;
  }

  @override
  Initializer buildRedirectingInitializer(
    covariant SourceConstructorBuilder constructorBuilder,
    ActualArguments arguments, {
    required int fileOffset,
  }) {
    return new ExtensionTypeRedirectingInitializer(
      constructorBuilder.invokeTarget as Procedure,
      arguments,
    )..fileOffset = fileOffset;
  }

  @override
  String get className {
    return _sourceExtensionTypeDeclarationBuilder.fullNameForErrors;
  }

  @override
  bool get isExtensionTypeDeclaration => true;
}

class _DeclarationBodyBuilderDeclarationContext
    extends BodyBuilderDeclarationContext
    with _DeclarationBodyBuilderDeclarationContextMixin {
  @override
  final DeclarationBuilder _declarationBuilder;

  _DeclarationBodyBuilderDeclarationContext(
    LibraryBuilder libraryBuilder,
    this._declarationBuilder,
  ) : super._(libraryBuilder);
}

class _TopLevelBodyBuilderDeclarationContext
    extends BodyBuilderDeclarationContext {
  _TopLevelBodyBuilderDeclarationContext(LibraryBuilder libraryBuilder)
    : super._(libraryBuilder);

  @override
  // Coverage-ignore(suite): Not run.
  LookupResult? lookupLocalMember(String name) {
    return _libraryBuilder.lookupLocalMember(name);
  }
}

class LibraryBodyBuilderContext extends BodyBuilderContext {
  LibraryBodyBuilderContext(SourceLibraryBuilder libraryBuilder)
    : super(libraryBuilder, null, isDeclarationInstanceMember: false);
}

mixin _DeclarationBodyBuilderContext<T extends DeclarationBuilder>
    implements BodyBuilderContext {
  @override
  InstanceTypeParameterAccessState get instanceTypeParameterAccessState {
    return InstanceTypeParameterAccessState.Allowed;
  }
}

class ClassBodyBuilderContext extends BodyBuilderContext
    with _DeclarationBodyBuilderContext<SourceClassBuilder> {
  ClassBodyBuilderContext(SourceClassBuilder sourceClassBuilder)
    : super(
        sourceClassBuilder.libraryBuilder,
        sourceClassBuilder,
        isDeclarationInstanceMember: false,
      );
}

class EnumBodyBuilderContext extends BodyBuilderContext
    with _DeclarationBodyBuilderContext<SourceEnumBuilder> {
  EnumBodyBuilderContext(SourceEnumBuilder sourceEnumBuilder)
    : super(
        sourceEnumBuilder.libraryBuilder,
        sourceEnumBuilder,
        isDeclarationInstanceMember: false,
      );
}

class ExtensionBodyBuilderContext extends BodyBuilderContext
    with _DeclarationBodyBuilderContext<SourceExtensionBuilder> {
  ExtensionBodyBuilderContext(SourceExtensionBuilder sourceExtensionBuilder)
    : super(
        sourceExtensionBuilder.libraryBuilder,
        sourceExtensionBuilder,
        isDeclarationInstanceMember: false,
      );
}

class ExtensionTypeBodyBuilderContext extends BodyBuilderContext
    with _DeclarationBodyBuilderContext<SourceExtensionTypeDeclarationBuilder> {
  ExtensionTypeBodyBuilderContext(
    SourceExtensionTypeDeclarationBuilder sourceExtensionTypeDeclarationBuilder,
  ) : super(
        sourceExtensionTypeDeclarationBuilder.libraryBuilder,
        sourceExtensionTypeDeclarationBuilder,
        isDeclarationInstanceMember: false,
      );
}

class TypedefBodyBuilderContext extends BodyBuilderContext {
  TypedefBodyBuilderContext(SourceTypeAliasBuilder sourceTypeAliasBuilder)
    : super(
        sourceTypeAliasBuilder.libraryBuilder,
        null,
        isDeclarationInstanceMember: false,
      );
}

class ParameterBodyBuilderContext extends BodyBuilderContext {
  factory ParameterBodyBuilderContext(
    LibraryBuilder libraryBuilder,
    DeclarationBuilder? declarationBuilder,
    FormalParameterBuilder formalParameterBuilder,
  ) {
    return new ParameterBodyBuilderContext._(
      libraryBuilder,
      declarationBuilder,
      formalParameterBuilder,
    );
  }

  ParameterBodyBuilderContext._(
    LibraryBuilder libraryBuilder,
    DeclarationBuilder? declarationBuilder,
    FormalParameterBuilder formalParameterBuilder,
  ) : super(
        libraryBuilder,
        declarationBuilder,
        isDeclarationInstanceMember:
            formalParameterBuilder.isDeclarationInstanceMember,
      );
}

// Coverage-ignore(suite): Not run.
class ExpressionCompilerProcedureBodyBuildContext extends BodyBuilderContext {
  final Procedure _procedure;

  ExpressionCompilerProcedureBodyBuildContext(
    this._procedure,
    SourceLibraryBuilder libraryBuilder,
    DeclarationBuilder? declarationBuilder, {
    required bool isDeclarationInstanceMember,
  }) : super(
         libraryBuilder,
         declarationBuilder,
         isDeclarationInstanceMember: isDeclarationInstanceMember,
       );

  @override
  AugmentSuperTarget? get augmentSuperTarget {
    return null;
  }

  @override
  int get memberNameOffset => _procedure.fileOffset;

  @override
  void registerSuperCall() {
    _procedure.transformerFlags |= TransformerFlag.superCalls;
  }
}
