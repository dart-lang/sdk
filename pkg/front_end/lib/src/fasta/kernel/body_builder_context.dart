// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/transformations/flags.dart';

import '../builder/builder.dart';
import '../builder/declaration_builders.dart';
import '../builder/formal_parameter_builder.dart';
import '../builder/library_builder.dart';
import '../builder/named_type_builder.dart';
import '../builder/type_builder.dart';
import '../constant_context.dart' show ConstantContext;
import '../dill/dill_class_builder.dart';
import '../identifiers.dart' show Identifier;
import '../scope.dart';
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

abstract class BodyBuilderContext {
  final BodyBuilderDeclarationContext _declarationContext;

  final bool isDeclarationInstanceMember;

  BodyBuilderContext(
      LibraryBuilder libraryBuilder, DeclarationBuilder? declarationBuilder,
      {required this.isDeclarationInstanceMember})
      : _declarationContext = new BodyBuilderDeclarationContext(
            libraryBuilder, declarationBuilder);

  String get memberName {
    throw new UnsupportedError('${runtimeType}.memberName');
  }

  Member? lookupSuperMember(ClassHierarchy hierarchy, Name name,
      {bool isSetter = false}) {
    return _declarationContext.lookupSuperMember(hierarchy, name,
        isSetter: isSetter);
  }

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

  Constructor? lookupSuperConstructor(Name name) {
    return _declarationContext.lookupSuperConstructor(name);
  }

  Builder? lookupLocalMember(String name, {bool required = false}) {
    return _declarationContext.lookupLocalMember(name, required: required);
  }

  bool get isPatchClass => _declarationContext.isPatchClass;

  Builder? lookupStaticOriginMember(String name, int charOffset, Uri uri) {
    return _declarationContext.lookupStaticOriginMember(name, charOffset, uri);
  }

  FormalParameterBuilder? getFormalParameterByName(Identifier name) {
    throw new UnsupportedError('${runtimeType}.getFormalParameterByName');
  }

  FunctionNode get function {
    throw new UnsupportedError('${runtimeType}.function');
  }

  bool get isConstructor => false;

  bool get isExternalConstructor => false;

  bool get isExternalFunction => false;

  bool get isSetter => false;

  bool get isConstConstructor => false;

  bool get isFactory => false;

  bool get isNativeMethod => false;

  bool get isDeclarationInstanceContext {
    return isDeclarationInstanceMember || isConstructor;
  }

  bool get isRedirectingFactory => false;

  String get redirectingFactoryTargetName {
    throw new UnsupportedError('${runtimeType}.redirectingFactoryTargetName');
  }

  InstanceTypeVariableAccessState get instanceTypeVariableAccessState {
    if (isDeclarationInstanceContext) {
      return InstanceTypeVariableAccessState.Allowed;
    } else {
      return InstanceTypeVariableAccessState.Disallowed;
    }
  }

  bool needsImplicitSuperInitializer(CoreTypes coreTypes) => false;

  void registerSuperCall() {
    throw new UnsupportedError('${runtimeType}.registerSuperCall');
  }

  bool isConstructorCyclic(String name) {
    throw new UnsupportedError('${runtimeType}.isConstructorCyclic');
  }

  ConstantContext get constantContext => ConstantContext.none;

  bool get isLateField => false;

  bool get isAbstractField => false;

  bool get isExternalField => false;

  bool get isMixinClass => _declarationContext.isMixinClass;

  bool get isEnumClass => _declarationContext.isEnumClass;

  String get className => _declarationContext.className;

  String get superClassName => _declarationContext.superClassName;

  DartType substituteFieldType(DartType fieldType) {
    throw new UnsupportedError('${runtimeType}.substituteFieldType');
  }

  void registerInitializedField(SourceFieldBuilder builder) {
    throw new UnsupportedError('${runtimeType}.registerInitializedField');
  }

  VariableDeclaration getFormalParameter(int index) {
    throw new UnsupportedError('${runtimeType}.getFormalParameter');
  }

  VariableDeclaration? getTearOffParameter(int index) {
    throw new UnsupportedError('${runtimeType}.getTearOffParameter');
  }

  DartType get returnTypeContext {
    throw new UnsupportedError('${runtimeType}.returnTypeContext');
  }

  TypeBuilder get returnType {
    throw new UnsupportedError('${runtimeType}.returnType');
  }

  List<FormalParameterBuilder>? get formals {
    throw new UnsupportedError('${runtimeType}.formals');
  }

  Scope computeFormalParameterInitializerScope(Scope parent) {
    throw new UnsupportedError(
        '${runtimeType}.computeFormalParameterInitializerScope');
  }

  void prepareInitializers() {
    throw new UnsupportedError('${runtimeType}.prepareInitializers');
  }

  void addInitializer(Initializer initializer, ExpressionGeneratorHelper helper,
      {required InitializerInferenceResult? inferenceResult}) {
    throw new UnsupportedError('${runtimeType}.addInitializer');
  }

  InitializerInferenceResult inferInitializer(Initializer initializer,
      ExpressionGeneratorHelper helper, TypeInferrer typeInferrer) {
    throw new UnsupportedError('${runtimeType}.inferInitializer');
  }

  int get memberCharOffset {
    throw new UnsupportedError("${runtimeType}.memberCharOffset");
  }

  AugmentSuperTarget? get augmentSuperTarget {
    return null;
  }

  void setAsyncModifier(AsyncMarker asyncModifier) {
    throw new UnsupportedError("${runtimeType}.setAsyncModifier");
  }

  void setBody(Statement body) {
    throw new UnsupportedError("${runtimeType}.setBody");
  }

  InterfaceType? get thisType => _declarationContext.thisType;
}

abstract class BodyBuilderDeclarationContext {
  final LibraryBuilder _libraryBuilder;

  factory BodyBuilderDeclarationContext(
      LibraryBuilder libraryBuilder, DeclarationBuilder? declarationBuilder) {
    if (declarationBuilder != null) {
      if (declarationBuilder is SourceClassBuilder) {
        return new _SourceClassBodyBuilderDeclarationContext(
            libraryBuilder, declarationBuilder);
      } else if (declarationBuilder is DillClassBuilder) {
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

  bool get isPatchClass => false;

  Builder? lookupStaticOriginMember(String name, int charOffset, Uri uri) {
    throw new UnsupportedError('${runtimeType}.lookupStaticOriginMember');
  }

  bool get isMixinClass => false;

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
  bool get isPatchClass => _sourceClassBuilder.isPatch;

  @override
  Builder? lookupStaticOriginMember(String name, int charOffset, Uri uri) {
    // The scope of a patched method includes the origin class.
    return _sourceClassBuilder.origin
        .findStaticBuilder(name, charOffset, uri, _libraryBuilder);
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
  final SourceExtensionTypeDeclarationBuilder _sourceClassBuilder;

  _SourceExtensionTypeDeclarationBodyBuilderDeclarationContext(
      LibraryBuilder libraryBuilder, this._sourceClassBuilder)
      : super._(libraryBuilder);

  @override
  DeclarationBuilder get _declarationBuilder => _sourceClassBuilder;

  @override
  SourceConstructorBuilder? lookupConstructor(Name name) {
    return _sourceClassBuilder.lookupConstructor(name);
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
    return _sourceClassBuilder.fullNameForErrors;
  }
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
  InstanceTypeVariableAccessState get instanceTypeVariableAccessState {
    return InstanceTypeVariableAccessState.Allowed;
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

  @override
  AugmentSuperTarget? get augmentSuperTarget {
    if (_member.isAugmentation) {
      return _member.augmentSuperTarget;
    }
    return null;
  }

  @override
  void registerSuperCall() {
    _member.member.transformerFlags |= TransformerFlag.superCalls;
  }

  @override
  int get memberCharOffset => _member.charOffset;
}

class FieldBodyBuilderContext extends BodyBuilderContext
    with _MemberBodyBuilderContext<SourceFieldBuilder> {
  @override
  SourceFieldBuilder _member;

  FieldBodyBuilderContext(this._member)
      : super(_member.libraryBuilder, _member.declarationBuilder,
            isDeclarationInstanceMember: _member.isDeclarationInstanceMember);

  @override
  bool get isLateField => _member.isLate;

  @override
  bool get isAbstractField => _member.isAbstract;

  @override
  bool get isExternalField => _member.isExternal;

  @override
  InstanceTypeVariableAccessState get instanceTypeVariableAccessState {
    if (_member.isExtensionMember && !_member.isExternal) {
      return InstanceTypeVariableAccessState.Invalid;
    } else {
      return super.instanceTypeVariableAccessState;
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
  Scope computeFormalParameterInitializerScope(Scope parent) {
    return _member.computeFormalParameterInitializerScope(parent);
  }

  @override
  FormalParameterBuilder? getFormalParameterByName(Identifier name) {
    return _member.getFormal(name);
  }

  @override
  String get memberName => _member.name;

  @override
  FunctionNode get function {
    return _member.function;
  }

  @override
  bool get isFactory {
    return _member.isFactory;
  }

  @override
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
    return isReturnTypeUndeclared &&
            _member.libraryBuilder.isNonNullableByDefault
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

  ProcedureBodyBuilderContext(this._member)
      : super(_member.libraryBuilder, _member.declarationBuilder,
            isDeclarationInstanceMember: _member.isDeclarationInstanceMember);
}

mixin _ConstructorBodyBuilderContextMixin<T extends ConstructorDeclaration>
    implements BodyBuilderContext {
  T get _member;

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
        inferenceResult: inferenceResult);
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

  ConstructorBodyBuilderContext(this._member)
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
}

class ExtensionTypeConstructorBodyBuilderContext extends BodyBuilderContext
    with
        _FunctionBodyBuilderContextMixin<SourceExtensionTypeConstructorBuilder>,
        _ConstructorBodyBuilderContextMixin<
            SourceExtensionTypeConstructorBuilder>,
        _MemberBodyBuilderContext<SourceExtensionTypeConstructorBuilder> {
  @override
  final SourceExtensionTypeConstructorBuilder _member;

  ExtensionTypeConstructorBodyBuilderContext(this._member)
      : super(_member.libraryBuilder, _member.declarationBuilder,
            isDeclarationInstanceMember: _member.isDeclarationInstanceMember);

  @override
  bool isConstructorCyclic(String name) {
    return _declarationContext.isConstructorCyclic(_member.name, name);
  }
}

class FactoryBodyBuilderContext extends BodyBuilderContext
    with
        _MemberBodyBuilderContext<SourceFactoryBuilder>,
        _FunctionBodyBuilderContextMixin<SourceFactoryBuilder> {
  @override
  final SourceFactoryBuilder _member;

  FactoryBodyBuilderContext(this._member)
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

  RedirectingFactoryBodyBuilderContext(this._member)
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
      FormalParameterBuilder formalParameterBuilder) {
    final DeclarationBuilder declarationBuilder =
        formalParameterBuilder.parent!.parent as DeclarationBuilder;
    return new ParameterBodyBuilderContext._(declarationBuilder.libraryBuilder,
        declarationBuilder, formalParameterBuilder);
  }

  ParameterBodyBuilderContext._(
      LibraryBuilder libraryBuilder,
      DeclarationBuilder? declarationBuilder,
      FormalParameterBuilder formalParameterBuilder)
      : super(libraryBuilder, declarationBuilder,
            isDeclarationInstanceMember:
                formalParameterBuilder.isDeclarationInstanceMember);
}

class ExpressionCompilerProcedureBodyBuildContext extends BodyBuilderContext
    with _MemberBodyBuilderContext<SourceProcedureBuilder> {
  @override
  final SourceProcedureBuilder _member;

  ExpressionCompilerProcedureBodyBuildContext(
      DietListener listener, this._member,
      {required bool isDeclarationInstanceMember})
      : super(listener.libraryBuilder, listener.currentDeclaration,
            isDeclarationInstanceMember: isDeclarationInstanceMember);
}
