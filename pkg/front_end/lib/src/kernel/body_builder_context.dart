// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/transformations/flags.dart';

import '../base/constant_context.dart' show ConstantContext;
import '../base/identifiers.dart' show Identifier;
import '../base/local_scope.dart';
import '../builder/builder.dart';
import '../builder/declaration_builders.dart';
import '../builder/formal_parameter_builder.dart';
import '../builder/library_builder.dart';
import '../builder/named_type_builder.dart';
import '../builder/type_builder.dart';
import '../dill/dill_class_builder.dart';
import '../source/constructor_declaration.dart';
import '../source/diet_listener.dart';
import '../source/source_class_builder.dart';
import '../source/source_constructor_builder.dart';
import '../source/source_enum_builder.dart';
import '../source/source_extension_builder.dart';
import '../source/source_extension_type_declaration_builder.dart';
import '../source/source_factory_builder.dart';
import '../source/source_field_builder.dart';
import '../source/source_function_builder.dart';
import '../source/source_library_builder.dart';
import '../source/source_member_builder.dart';
import '../source/source_procedure_builder.dart';
import '../source/source_type_alias_builder.dart';
import '../type_inference/inference_results.dart'
    show InitializerInferenceResult;
import '../type_inference/type_inferrer.dart' show TypeInferrer;
import '../type_inference/type_schema.dart' show UnknownType;
import 'expression_generator_helper.dart';
import 'internal_ast.dart';

/// Interface that defines the interface between the [BodyBuilder] and the
/// member/declaration whose AST is being built.
abstract class BodyBuilderContext {
  final BodyBuilderDeclarationContext _declarationContext;

  final bool _isDeclarationInstanceMember;

  BodyBuilderContext(
      LibraryBuilder libraryBuilder, DeclarationBuilder? declarationBuilder,
      {required bool isDeclarationInstanceMember})
      : _isDeclarationInstanceMember = isDeclarationInstanceMember,
        _declarationContext = new BodyBuilderDeclarationContext(
            libraryBuilder, declarationBuilder);

  /// Returns the file offset of the name of the member whose body is being
  /// built.
  ///
  /// For an unnamed constructor this is offset of the class name.
  ///
  /// This is used for error reporting.
  int get memberNameOffset {
    throw new UnsupportedError("${runtimeType}.memberNameOffset");
  }

  /// Returns the length of the name of the member whose body is being built.
  ///
  /// For an unnamed constructor this is 0.
  ///
  /// This is used for error reporting.
  int get memberNameLength {
    throw new UnsupportedError('${runtimeType}.memberNameLength');
  }

  /// Looks up the member by the given [name] in the superclass of the enclosing
  /// class.
  ///
  /// If [isSetter] is `true`, a setable is returned, otherwise a getable is
  /// returned.
  Member? lookupSuperMember(ClassHierarchy hierarchy, Name name,
      {bool isSetter = false}) {
    return _declarationContext.lookupSuperMember(hierarchy, name,
        isSetter: isSetter);
  }

  /// Looks up the constructor by the given [name] in the enclosing declaration.
  Builder? lookupConstructor(Name name) {
    return _declarationContext.lookupConstructor(name);
  }

  /// Creates an [Initializer] for a redirecting initializer call to
  /// [constructorBuilder] with the given [arguments] from within a constructor
  /// in the same class.
  Initializer buildRedirectingInitializer(
      Builder constructorBuilder, Arguments arguments,
      {required int fileOffset}) {
    return _declarationContext.buildRedirectingInitializer(
        constructorBuilder, arguments,
        fileOffset: fileOffset);
  }

  /// Looks up the constructor by the given [name] in the superclass of the
  /// enclosing class.
  Constructor? lookupSuperConstructor(Name name) {
    return _declarationContext.lookupSuperConstructor(name);
  }

  /// Looks up the member by the given [name] declared in the enclosing
  /// declaration or library.
  ///
  /// If [required] is `true`, an error is thrown if the member is not found.
  Builder? lookupLocalMember(String name, {bool required = false}) {
    return _declarationContext.lookupLocalMember(name, required: required);
  }

  /// Returns `true` if the enclosing class in an augmenting class.
  bool get isAugmentationClass => _declarationContext.isAugmentationClass;

  /// Returns `true` if the enclosing entity is an extension type.
  bool get isExtensionTypeDeclaration =>
      _declarationContext.isExtensionTypeDeclaration;

  /// Returns `true` if the enclosing entity is an extension.
  bool get isExtensionDeclaration => _declarationContext.isExtensionDeclaration;

  /// Looks up the static member by the given [name] in the origin of the
  /// enclosing declaration.
  Builder? lookupStaticOriginMember(String name, int fileOffset, Uri fileUri) {
    return _declarationContext.lookupStaticOriginMember(
        name, fileOffset, fileUri);
  }

  /// Returns the [FormalParameterBuilder] by the given [name] declared in the
  /// member whose body is being built.
  FormalParameterBuilder? getFormalParameterByName(Identifier identifier) {
    if (formals != null) {
      for (FormalParameterBuilder formal in formals!) {
        if (formal.isWildcard &&
            identifier.name == '_' &&
            formal.fileOffset == identifier.nameOffset) {
          return formal;
        }
        if (formal.name == identifier.name &&
            formal.fileOffset == identifier.nameOffset) {
          return formal;
        }
      }
      // Coverage-ignore(suite): Not run.
      // If we have any formals we should find the one we're looking for.
      assert(false, "$identifier not found in $formals");
    }
    return null;
  }

  /// Returns the [FunctionNode] for the function body currently being built.
  FunctionNode get function {
    throw new UnsupportedError('${runtimeType}.function');
  }

  /// Returns `true` if the member whose body is being built is a non-factory
  /// constructor declaration.
  bool get isConstructor => false;

  // Coverage-ignore(suite): Not run.
  /// Returns `true` if the member whose body is being built is a non-factory
  /// constructor declaration marked as `external`.
  bool get isExternalConstructor => false;

  /// Returns `true` if the member whose body is being built is a constructor,
  /// factory, method, getter, or setter marked as `external`.
  bool get isExternalFunction => false;

  /// Returns `true` if the member whose body is being built is a setter
  /// declaration.
  bool get isSetter => false;

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
  bool get isMixinClass => _declarationContext.isMixinClass;

  /// Returns `true` if the enclosing class of the member whose body is being
  /// built is marked as an enum.
  bool get isEnumClass => _declarationContext.isEnumClass;

  /// Returns the name of the enclosing class or extension type declaration.
  String get className => _declarationContext.className;

  /// Returns the name of the superclass of the enclosing class.
  String get superClassName => _declarationContext.superClassName;

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
  void registerInitializedField(SourceFieldBuilder builder) {
    throw new UnsupportedError('${runtimeType}.registerInitializedField');
  }

  /// Returns the [VariableDeclaration] for the [index]th formal parameter
  /// declared in the constructor, factory, method, or setter currently being
  /// built.
  VariableDeclaration getFormalParameter(int index) {
    throw new UnsupportedError('${runtimeType}.getFormalParameter');
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
  TypeBuilder get returnType {
    throw new UnsupportedError('${runtimeType}.returnType');
  }

  /// Returns the [FormalParameterBuilder]s for the formals of the member whose
  /// body is currently being built, including synthetically added formal
  /// parameters.
  List<FormalParameterBuilder>? get formals {
    throw new UnsupportedError('${runtimeType}.formals');
  }

  /// Computes the scope containing the initializing formals or super
  /// parameters of the constructor currently being built, using [parent] as
  /// the parent scope.
  ///
  /// If a constructor is not currently being built, [parent] is returned.
  LocalScope computeFormalParameterInitializerScope(LocalScope parent) {
    throw new UnsupportedError(
        '${runtimeType}.computeFormalParameterInitializerScope');
  }

  /// This is called before parsing constructor initializers.
  ///
  /// The constructor initializers are parsed both in the outline and in the
  /// body building phases, so this clears the initializer parsed during the
  /// outline phases to avoid duplication.
  void prepareInitializers() {
    throw new UnsupportedError('${runtimeType}.prepareInitializers');
  }

  /// Adds [initializer] to generative constructor currently being built.
  void addInitializer(Initializer initializer, ExpressionGeneratorHelper helper,
      {required InitializerInferenceResult? inferenceResult}) {
    throw new UnsupportedError('${runtimeType}.addInitializer');
  }

  /// Infers the [initializer].
  InitializerInferenceResult inferInitializer(Initializer initializer,
      ExpressionGeneratorHelper helper, TypeInferrer typeInferrer) {
    throw new UnsupportedError('${runtimeType}.inferInitializer');
  }

  // Coverage-ignore(suite): Not run.
  /// Returns the target for using the `augmented` expression in an augmenting
  /// member.
  AugmentSuperTarget? get augmentSuperTarget {
    return null;
  }

  /// Sets the [asyncModifier] of the function currently being built.
  // TODO(johnniwinther): Do we need this? Isn't this already available from the
  // outline?
  void setAsyncModifier(AsyncMarker asyncModifier) {
    throw new UnsupportedError("${runtimeType}.setAsyncModifier");
  }

  /// Registers [body] as the result of the body building.
  void setBody(Statement body) {
    throw new UnsupportedError("${runtimeType}.setBody");
  }

  /// Returns the type of `this` in the body being built.
  ///
  /// This is only used for classes. For extensions and extension types, `this`
  /// is handled via a synthetic this variable.
  InterfaceType? get thisType => _declarationContext.thisType;
}

/// Interface that provides information for a [BodyBuilderContext] from the
/// enclosing class-like declaration or library.
abstract class BodyBuilderDeclarationContext {
  final LibraryBuilder _libraryBuilder;

  factory BodyBuilderDeclarationContext(
      LibraryBuilder libraryBuilder, DeclarationBuilder? declarationBuilder) {
    if (declarationBuilder != null) {
      if (declarationBuilder is SourceClassBuilder) {
        return new _SourceClassBodyBuilderDeclarationContext(
            libraryBuilder, declarationBuilder);
      } else if (declarationBuilder is DillClassBuilder) {
        // Coverage-ignore-block(suite): Not run.
        return new _DillClassBodyBuilderDeclarationContext(
            libraryBuilder, declarationBuilder);
      } else if (declarationBuilder is SourceExtensionTypeDeclarationBuilder) {
        return new _SourceExtensionTypeDeclarationBodyBuilderDeclarationContext(
            libraryBuilder, declarationBuilder);
      } else {
        return new _DeclarationBodyBuilderDeclarationContext(
            libraryBuilder, declarationBuilder);
      }
    } else {
      return new _TopLevelBodyBuilderDeclarationContext(libraryBuilder);
    }
  }

  BodyBuilderDeclarationContext._(this._libraryBuilder);

  Member? lookupSuperMember(ClassHierarchy hierarchy, Name name,
      {bool isSetter = false}) {
    throw new UnsupportedError('${runtimeType}.lookupSuperMember');
  }

  Builder? lookupConstructor(Name name) {
    throw new UnsupportedError('${runtimeType}.lookupConstructor');
  }

  Initializer buildRedirectingInitializer(
      Builder constructorBuilder, Arguments arguments,
      {required int fileOffset}) {
    throw new UnsupportedError('${runtimeType}.buildRedirectingInitializer');
  }

  Constructor? lookupSuperConstructor(Name name) {
    throw new UnsupportedError('${runtimeType}.lookupSuperConstructor');
  }

  Builder? lookupLocalMember(String name, {bool required = false});

  bool get isAugmentationClass => false;

  bool get isExtensionTypeDeclaration => false;

  // Coverage-ignore(suite): Not run.
  bool get isExtensionDeclaration => false;

  Builder? lookupStaticOriginMember(String name, int fileOffset, Uri fileUri) {
    throw new UnsupportedError('${runtimeType}.lookupStaticOriginMember');
  }

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
  Builder? lookupLocalMember(String name, {bool required = false}) {
    return _declarationBuilder.lookupLocalMember(name, required: required);
  }

  @override
  InterfaceType? get thisType => _declarationBuilder.thisType;

  @override
  bool get isExtensionDeclaration => _declarationBuilder.isExtension;
}

class _SourceClassBodyBuilderDeclarationContext
    extends BodyBuilderDeclarationContext
    with _DeclarationBodyBuilderDeclarationContextMixin {
  final SourceClassBuilder _sourceClassBuilder;

  _SourceClassBodyBuilderDeclarationContext(
      LibraryBuilder libraryBuilder, this._sourceClassBuilder)
      : super._(libraryBuilder);

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
  Member? lookupSuperMember(ClassHierarchy hierarchy, Name name,
      {bool isSetter = false}) {
    return _sourceClassBuilder.lookupInstanceMember(hierarchy, name,
        isSetter: isSetter, isSuper: true);
  }

  @override
  SourceConstructorBuilder? lookupConstructor(Name name) {
    return _sourceClassBuilder.lookupConstructor(name);
  }

  @override
  Initializer buildRedirectingInitializer(
      covariant SourceConstructorBuilder constructorBuilder,
      Arguments arguments,
      {required int fileOffset}) {
    return new RedirectingInitializer(
        constructorBuilder.invokeTarget as Constructor, arguments)
      ..fileOffset = fileOffset;
  }

  @override
  Constructor? lookupSuperConstructor(Name name) {
    return _sourceClassBuilder.lookupSuperConstructor(name);
  }

  @override
  bool get isAugmentationClass => _sourceClassBuilder.isAugmenting;

  @override
  Builder? lookupStaticOriginMember(String name, int fileOffset, Uri fileUri) {
    // The scope of an augmented method includes the origin class.
    return _sourceClassBuilder.origin
        .findStaticBuilder(name, fileOffset, fileUri, _libraryBuilder);
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
    if (_sourceClassBuilder.supertypeBuilder?.declaration
        is InvalidTypeDeclarationBuilder) {
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
      LibraryBuilder libraryBuilder, this._declarationBuilder)
      : super._(libraryBuilder);

  @override
  Member? lookupSuperMember(ClassHierarchy hierarchy, Name name,
      {bool isSetter = false}) {
    return _declarationBuilder.lookupInstanceMember(hierarchy, name,
        isSetter: isSetter, isSuper: true);
  }
}

class _SourceExtensionTypeDeclarationBodyBuilderDeclarationContext
    extends BodyBuilderDeclarationContext
    with _DeclarationBodyBuilderDeclarationContextMixin {
  final SourceExtensionTypeDeclarationBuilder
      _sourceExtensionTypeDeclarationBuilder;

  _SourceExtensionTypeDeclarationBodyBuilderDeclarationContext(
      LibraryBuilder libraryBuilder,
      this._sourceExtensionTypeDeclarationBuilder)
      : super._(libraryBuilder);

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
      Arguments arguments,
      {required int fileOffset}) {
    return new ExtensionTypeRedirectingInitializer(
        constructorBuilder.invokeTarget as Procedure, arguments)
      ..fileOffset = fileOffset;
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
      LibraryBuilder libraryBuilder, this._declarationBuilder)
      : super._(libraryBuilder);
}

class _TopLevelBodyBuilderDeclarationContext
    extends BodyBuilderDeclarationContext {
  _TopLevelBodyBuilderDeclarationContext(LibraryBuilder libraryBuilder)
      : super._(libraryBuilder);

  @override
  Builder? lookupLocalMember(String name, {bool required = false}) {
    return _libraryBuilder.lookupLocalMember(name, required: required);
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
      : super(sourceClassBuilder.libraryBuilder, sourceClassBuilder,
            isDeclarationInstanceMember: false);
}

class EnumBodyBuilderContext extends BodyBuilderContext
    with _DeclarationBodyBuilderContext<SourceEnumBuilder> {
  EnumBodyBuilderContext(SourceEnumBuilder sourceEnumBuilder)
      : super(sourceEnumBuilder.libraryBuilder, sourceEnumBuilder,
            isDeclarationInstanceMember: false);
}

class ExtensionBodyBuilderContext extends BodyBuilderContext
    with _DeclarationBodyBuilderContext<SourceExtensionBuilder> {
  ExtensionBodyBuilderContext(SourceExtensionBuilder sourceExtensionBuilder)
      : super(sourceExtensionBuilder.libraryBuilder, sourceExtensionBuilder,
            isDeclarationInstanceMember: false);
}

class ExtensionTypeBodyBuilderContext extends BodyBuilderContext
    with _DeclarationBodyBuilderContext<SourceExtensionTypeDeclarationBuilder> {
  ExtensionTypeBodyBuilderContext(
      SourceExtensionTypeDeclarationBuilder
          sourceExtensionTypeDeclarationBuilder)
      : super(sourceExtensionTypeDeclarationBuilder.libraryBuilder,
            sourceExtensionTypeDeclarationBuilder,
            isDeclarationInstanceMember: false);
}

class TypedefBodyBuilderContext extends BodyBuilderContext {
  TypedefBodyBuilderContext(SourceTypeAliasBuilder sourceTypeAliasBuilder)
      : super(sourceTypeAliasBuilder.libraryBuilder, null,
            isDeclarationInstanceMember: false);
}

mixin _MemberBodyBuilderContext<T extends SourceMemberBuilder>
    implements BodyBuilderContext {
  T get _member;

  Member get _builtMember;

  @override
  AugmentSuperTarget? get augmentSuperTarget {
    if (_member.isAugmentation) {
      return _member.augmentSuperTarget;
    }
    return null;
  }

  @override
  int get memberNameOffset => _member.fileOffset;

  @override
  void registerSuperCall() {
    _builtMember.transformerFlags |= TransformerFlag.superCalls;
  }
}

class FieldBodyBuilderContext extends BodyBuilderContext
    with _MemberBodyBuilderContext<SourceFieldBuilder> {
  @override
  SourceFieldBuilder _member;

  @override
  final Member _builtMember;

  FieldBodyBuilderContext(this._member, this._builtMember)
      : super(_member.libraryBuilder, _member.declarationBuilder,
            isDeclarationInstanceMember: _member.isDeclarationInstanceMember);

  @override
  bool get isLateField => _member.isLate;

  @override
  bool get isAbstractField => _member.isAbstract;

  @override
  bool get isExternalField => _member.isExternal;

  @override
  InstanceTypeParameterAccessState get instanceTypeParameterAccessState {
    if (_member.isExtensionMember && !_member.isExternal) {
      return InstanceTypeParameterAccessState.Invalid;
    } else {
      return super.instanceTypeParameterAccessState;
    }
  }

  @override
  ConstantContext get constantContext {
    return _member.isConst
        ? ConstantContext.inferred
        : !_member.isStatic && _declarationContext.declaresConstConstructor
            ? ConstantContext.required
            : ConstantContext.none;
  }
}

mixin _FunctionBodyBuilderContextMixin<T extends SourceFunctionBuilder>
    implements BodyBuilderContext {
  T get _member;

  @override
  VariableDeclaration getFormalParameter(int index) {
    return _member.getFormalParameter(index);
  }

  @override
  VariableDeclaration? getTearOffParameter(int index) {
    return _member.getTearOffParameter(index);
  }

  @override
  TypeBuilder get returnType => _member.returnType;

  @override
  void setBody(Statement body) {
    _member.body = body;
  }

  @override
  List<FormalParameterBuilder>? get formals => _member.formals;

  @override
  LocalScope computeFormalParameterInitializerScope(LocalScope parent) {
    return _member.computeFormalParameterInitializerScope(parent);
  }

  @override
  FormalParameterBuilder? getFormalParameterByName(Identifier name) {
    return _member.getFormal(name);
  }

  @override
  int get memberNameLength => _member.name.length;

  @override
  FunctionNode get function {
    return _member.function;
  }

  @override
  bool get isFactory {
    return _member.isFactory;
  }

  @override
  // Coverage-ignore(suite): Not run.
  bool get isNativeMethod {
    return _member.isNative;
  }

  @override
  bool get isExternalFunction {
    return _member.isExternal;
  }

  @override
  bool get isSetter {
    return _member.isSetter;
  }
}

mixin _ProcedureBodyBuilderContextMixin<T extends SourceProcedureBuilder>
    implements BodyBuilderContext {
  T get _member;

  @override
  void setAsyncModifier(AsyncMarker asyncModifier) {
    _member.asyncModifier = asyncModifier;
  }

  @override
  DartType get returnTypeContext {
    final bool isReturnTypeUndeclared =
        _member.returnType is OmittedTypeBuilder &&
            _member.function.returnType is DynamicType;
    return isReturnTypeUndeclared
        ? const UnknownType()
        : _member.function.returnType;
  }
}

class ProcedureBodyBuilderContext extends BodyBuilderContext
    with
        _MemberBodyBuilderContext<SourceProcedureBuilder>,
        _FunctionBodyBuilderContextMixin<SourceProcedureBuilder>,
        _ProcedureBodyBuilderContextMixin<SourceProcedureBuilder> {
  @override
  final SourceProcedureBuilder _member;

  @override
  final Member _builtMember;

  ProcedureBodyBuilderContext(this._member, this._builtMember)
      : super(_member.libraryBuilder, _member.declarationBuilder,
            isDeclarationInstanceMember: _member.isDeclarationInstanceMember);
}

mixin _ConstructorBodyBuilderContextMixin<T extends ConstructorDeclaration>
    implements BodyBuilderContext {
  T get _member;

  TreeNode get _initializerParent;

  @override
  DartType substituteFieldType(DartType fieldType) {
    return _member.substituteFieldType(fieldType);
  }

  @override
  void registerInitializedField(SourceFieldBuilder builder) {
    _member.registerInitializedField(builder);
  }

  @override
  void prepareInitializers() {
    _member.prepareInitializers();
  }

  @override
  void addInitializer(Initializer initializer, ExpressionGeneratorHelper helper,
      {required InitializerInferenceResult? inferenceResult}) {
    _member.addInitializer(initializer, helper,
        inferenceResult: inferenceResult, parent: _initializerParent);
  }

  @override
  InitializerInferenceResult inferInitializer(Initializer initializer,
      ExpressionGeneratorHelper helper, TypeInferrer typeInferrer) {
    return typeInferrer.inferInitializer(helper, _member, initializer);
  }

  @override
  DartType get returnTypeContext {
    return const DynamicType();
  }

  @override
  bool get isConstructor => true;

  @override
  bool get isConstConstructor {
    return _member.isConst;
  }

  @override
  bool get isExternalConstructor {
    return _member.isExternal;
  }

  @override
  ConstantContext get constantContext {
    return isConstConstructor ? ConstantContext.required : ConstantContext.none;
  }
}

class ConstructorBodyBuilderContext extends BodyBuilderContext
    with
        _FunctionBodyBuilderContextMixin<DeclaredSourceConstructorBuilder>,
        _ConstructorBodyBuilderContextMixin<DeclaredSourceConstructorBuilder>,
        _MemberBodyBuilderContext<DeclaredSourceConstructorBuilder> {
  @override
  final DeclaredSourceConstructorBuilder _member;

  @override
  final Member _builtMember;

  ConstructorBodyBuilderContext(this._member, this._builtMember)
      : super(_member.libraryBuilder, _member.declarationBuilder,
            isDeclarationInstanceMember: _member.isDeclarationInstanceMember);

  @override
  bool isConstructorCyclic(String name) {
    return _declarationContext.isConstructorCyclic(_member.name, name);
  }

  @override
  bool needsImplicitSuperInitializer(CoreTypes coreTypes) {
    return !_declarationContext.isObjectClass(coreTypes) &&
        !isExternalConstructor;
  }

  @override
  TreeNode get _initializerParent => _member.invokeTarget;
}

class ExtensionTypeConstructorBodyBuilderContext extends BodyBuilderContext
    with
        _FunctionBodyBuilderContextMixin<SourceExtensionTypeConstructorBuilder>,
        _ConstructorBodyBuilderContextMixin<
            SourceExtensionTypeConstructorBuilder>,
        _MemberBodyBuilderContext<SourceExtensionTypeConstructorBuilder> {
  @override
  final SourceExtensionTypeConstructorBuilder _member;
  @override
  final Member _builtMember;

  ExtensionTypeConstructorBodyBuilderContext(this._member, this._builtMember)
      : super(_member.libraryBuilder, _member.declarationBuilder,
            isDeclarationInstanceMember: _member.isDeclarationInstanceMember);

  @override
  bool isConstructorCyclic(String name) {
    return _declarationContext.isConstructorCyclic(_member.name, name);
  }

  @override
  TreeNode get _initializerParent => _member.invokeTarget;
}

class FactoryBodyBuilderContext extends BodyBuilderContext
    with
        _MemberBodyBuilderContext<SourceFactoryBuilder>,
        _FunctionBodyBuilderContextMixin<SourceFactoryBuilder> {
  @override
  final SourceFactoryBuilder _member;

  @override
  final Member _builtMember;

  FactoryBodyBuilderContext(this._member, this._builtMember)
      : super(_member.libraryBuilder, _member.declarationBuilder,
            isDeclarationInstanceMember: _member.isDeclarationInstanceMember);

  @override
  void setAsyncModifier(AsyncMarker asyncModifier) {
    _member.asyncModifier = asyncModifier;
  }

  @override
  DartType get returnTypeContext {
    return _member.function.returnType;
  }
}

class RedirectingFactoryBodyBuilderContext extends BodyBuilderContext
    with
        _MemberBodyBuilderContext<RedirectingFactoryBuilder>,
        _FunctionBodyBuilderContextMixin<RedirectingFactoryBuilder> {
  @override
  final RedirectingFactoryBuilder _member;

  @override
  final Member _builtMember;

  RedirectingFactoryBodyBuilderContext(this._member, this._builtMember)
      : super(_member.libraryBuilder, _member.declarationBuilder,
            isDeclarationInstanceMember: _member.isDeclarationInstanceMember);

  @override
  bool get isRedirectingFactory => true;

  @override
  String get redirectingFactoryTargetName {
    return _member.redirectionTarget.fullNameForErrors;
  }
}

class ParameterBodyBuilderContext extends BodyBuilderContext {
  factory ParameterBodyBuilderContext(
      LibraryBuilder libraryBuilder,
      DeclarationBuilder? declarationBuilder,
      FormalParameterBuilder formalParameterBuilder) {
    return new ParameterBodyBuilderContext._(
        libraryBuilder, declarationBuilder, formalParameterBuilder);
  }

  ParameterBodyBuilderContext._(
      LibraryBuilder libraryBuilder,
      DeclarationBuilder? declarationBuilder,
      FormalParameterBuilder formalParameterBuilder)
      : super(libraryBuilder, declarationBuilder,
            isDeclarationInstanceMember:
                formalParameterBuilder.isDeclarationInstanceMember);
}

// Coverage-ignore(suite): Not run.
class ExpressionCompilerProcedureBodyBuildContext extends BodyBuilderContext
    with _MemberBodyBuilderContext<SourceProcedureBuilder> {
  @override
  final SourceProcedureBuilder _member;

  @override
  final Member _builtMember;

  ExpressionCompilerProcedureBodyBuildContext(
      DietListener listener, this._member, this._builtMember,
      {required bool isDeclarationInstanceMember})
      : super(listener.libraryBuilder, listener.currentDeclaration,
            isDeclarationInstanceMember: isDeclarationInstanceMember);
}
