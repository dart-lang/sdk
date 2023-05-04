// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/transformations/flags.dart';

import '../builder/builder.dart';
import '../builder/class_builder.dart';
import '../builder/declaration_builder.dart';
import '../builder/formal_parameter_builder.dart';
import '../builder/invalid_type_declaration_builder.dart';
import '../builder/library_builder.dart';
import '../builder/member_builder.dart';
import '../builder/modifier_builder.dart';
import '../builder/named_type_builder.dart';
import '../builder/omitted_type_builder.dart';
import '../builder/type_builder.dart';
import '../constant_context.dart' show ConstantContext;
import '../identifiers.dart' show Identifier;
import '../problems.dart' show unhandled;
import '../scope.dart';
import '../source/constructor_declaration.dart';
import '../source/diet_listener.dart';
import '../source/source_class_builder.dart';
import '../source/source_constructor_builder.dart';
import '../source/source_enum_builder.dart';
import '../source/source_extension_builder.dart';
import '../source/source_factory_builder.dart';
import '../source/source_field_builder.dart';
import '../source/source_function_builder.dart';
import '../source/source_inline_class_builder.dart';
import '../source/source_library_builder.dart';
import '../source/source_member_builder.dart';
import '../source/source_procedure_builder.dart';
import '../source/source_type_alias_builder.dart';
import '../type_inference/inference_results.dart'
    show InitializerInferenceResult;
import '../type_inference/type_inferrer.dart' show TypeInferrer;
import '../type_inference/type_schema.dart' show UnknownType;
import 'expression_generator_helper.dart';

class BodyBuilderContext {
  final LibraryBuilder _libraryBuilder;

  /// The source class or mixin declaration in which [_member] is declared, if
  /// any.
  ///
  /// If [_member] is a synthesized member for expression evaluation the
  /// enclosing declaration might be a [DillClassBuilder]. This can be accessed
  /// through [_declarationBuilder].
  final SourceClassBuilder? _sourceClassBuilder;

  /// The class, mixin or extension declaration in which [_member] is declared,
  /// if any.
  final DeclarationBuilder? _declarationBuilder;

  final ModifierBuilder _member;

  final bool isDeclarationInstanceMember;

  BodyBuilderContext(
      this._libraryBuilder, this._declarationBuilder, this._member,
      {required this.isDeclarationInstanceMember})
      : _sourceClassBuilder = _declarationBuilder is SourceClassBuilder
            ? _declarationBuilder
            : null;

  String? get memberName => _member.name;

  Member? lookupSuperMember(ClassHierarchy hierarchy, Name name,
      {bool isSetter = false}) {
    return (_declarationBuilder as ClassBuilder).lookupInstanceMember(
        hierarchy, name,
        isSetter: isSetter, isSuper: true);
  }

  Constructor? lookupConstructor(Name name) {
    return _sourceClassBuilder!.lookupConstructor(name, isSuper: false);
  }

  Constructor? lookupSuperConstructor(Name name) {
    return _sourceClassBuilder!.lookupConstructor(name, isSuper: true);
  }

  Builder? lookupLocalMember(String name, {bool required = false}) {
    if (_declarationBuilder != null) {
      return _declarationBuilder!.lookupLocalMember(name, required: required);
    } else {
      return _libraryBuilder.lookupLocalMember(name, required: required);
    }
  }

  bool get isPatchClass => _sourceClassBuilder?.isPatch ?? false;

  Builder? lookupStaticOriginMember(String name, int charOffset, Uri uri) {
    // The scope of a patched method includes the origin class.
    return _sourceClassBuilder!.origin
        .findStaticBuilder(name, charOffset, uri, _libraryBuilder);
  }

  FormalParameterBuilder? getFormalParameterByName(Identifier name) {
    SourceFunctionBuilder member = this._member as SourceFunctionBuilder;
    return member.getFormal(name);
  }

  FunctionNode get function {
    return (_member as SourceFunctionBuilder).function;
  }

  bool get isConstructor {
    return _member is ConstructorDeclaration;
  }

  bool get isExternalConstructor {
    return _member.isExternal;
  }

  bool get isExternalFunction {
    return _member.isExternal;
  }

  bool get isSetter {
    return _member.isSetter;
  }

  bool get isConstConstructor {
    return _member.isConst;
  }

  bool get isFactory {
    return _member.isFactory;
  }

  bool get isNativeMethod {
    return _member.isNative;
  }

  bool get isDeclarationInstanceContext {
    return isDeclarationInstanceMember || isConstructor;
  }

  bool get isRedirectingFactory {
    return _member is RedirectingFactoryBuilder;
  }

  String get redirectingFactoryTargetName {
    RedirectingFactoryBuilder factory = _member as RedirectingFactoryBuilder;
    return factory.redirectionTarget.fullNameForErrors;
  }

  InstanceTypeVariableAccessState get instanceTypeVariableAccessState {
    if (_member.isExtensionMember && _member.isField && !_member.isExternal) {
      return InstanceTypeVariableAccessState.Invalid;
    } else if (isDeclarationInstanceContext || _member is DeclarationBuilder) {
      return InstanceTypeVariableAccessState.Allowed;
    } else {
      return InstanceTypeVariableAccessState.Disallowed;
    }
  }

  bool needsImplicitSuperInitializer(CoreTypes coreTypes) {
    return _declarationBuilder is SourceClassBuilder &&
        coreTypes.objectClass !=
            (_declarationBuilder as SourceClassBuilder).cls &&
        !_member.isExternal;
  }

  void registerSuperCall() {
    MemberBuilder memberBuilder = _member as MemberBuilder;
    memberBuilder.member.transformerFlags |= TransformerFlag.superCalls;
  }

  bool isConstructorCyclic(String name) {
    return _sourceClassBuilder!.checkConstructorCyclic(_member.name!, name);
  }

  ConstantContext get constantContext {
    return _member.isConst
        ? ConstantContext.inferred
        : !_member.isStatic &&
                _sourceClassBuilder != null &&
                _sourceClassBuilder!.declaresConstConstructor
            ? ConstantContext.required
            : ConstantContext.none;
  }

  bool get isLateField =>
      _member is SourceFieldBuilder && (_member as SourceFieldBuilder).isLate;

  bool get isAbstractField =>
      _member is SourceFieldBuilder &&
      (_member as SourceFieldBuilder).isAbstract;

  bool get isExternalField =>
      _member is SourceFieldBuilder &&
      (_member as SourceFieldBuilder).isExternal;

  bool get isMixinClass {
    return _sourceClassBuilder != null && _sourceClassBuilder!.isMixinClass;
  }

  bool get isEnumClass {
    return _sourceClassBuilder is SourceEnumBuilder;
  }

  String get className {
    return _sourceClassBuilder!.fullNameForErrors;
  }

  String get superClassName {
    if (_sourceClassBuilder!.supertypeBuilder?.declaration
        is InvalidTypeDeclarationBuilder) {
      // TODO(johnniwinther): Avoid reporting errors on missing constructors
      // on invalid super types.
      return _sourceClassBuilder!.supertypeBuilder!.fullNameForErrors;
    }
    Class cls = _sourceClassBuilder!.cls;
    cls = cls.superclass!;
    while (cls.isMixinApplication) {
      cls = cls.superclass!;
    }
    return cls.name;
  }

  DartType substituteFieldType(DartType fieldType) {
    return (_member as ConstructorDeclaration).substituteFieldType(fieldType);
  }

  void registerInitializedField(SourceFieldBuilder builder) {
    (_member as ConstructorDeclaration).registerInitializedField(builder);
  }

  VariableDeclaration getFormalParameter(int index) {
    return (_member as SourceFunctionBuilder).getFormalParameter(index);
  }

  VariableDeclaration? getTearOffParameter(int index) {
    return (_member as SourceFunctionBuilder).getTearOffParameter(index);
  }

  DartType get returnTypeContext {
    ModifierBuilder member = _member;
    if (member is SourceProcedureBuilder) {
      final bool isReturnTypeUndeclared =
          member.returnType is OmittedTypeBuilder &&
              member.function.returnType is DynamicType;
      return isReturnTypeUndeclared && _libraryBuilder.isNonNullableByDefault
          ? const UnknownType()
          : member.function.returnType;
    } else if (member is SourceFactoryBuilder) {
      return member.function.returnType;
    } else {
      assert(member is ConstructorDeclaration);
      return const DynamicType();
    }
  }

  TypeBuilder get returnType => (_member as SourceFunctionBuilder).returnType;

  List<FormalParameterBuilder>? get formals =>
      (_member as SourceFunctionBuilder).formals;

  Scope computeFormalParameterInitializerScope(Scope parent) {
    return (_member as SourceFunctionBuilder)
        .computeFormalParameterInitializerScope(parent);
  }

  void prepareInitializers() {
    (_member as ConstructorDeclaration).prepareInitializers();
  }

  void addInitializer(Initializer initializer, ExpressionGeneratorHelper helper,
      {required InitializerInferenceResult? inferenceResult}) {
    (_member as ConstructorDeclaration)
        .addInitializer(initializer, helper, inferenceResult: inferenceResult);
  }

  InitializerInferenceResult inferInitializer(Initializer initializer,
      ExpressionGeneratorHelper helper, TypeInferrer typeInferrer) {
    return typeInferrer.inferInitializer(
        helper, _member as ConstructorDeclaration, initializer);
  }

  int get charOffset => _member.charOffset;

  AugmentSuperTarget? get augmentSuperTarget {
    Builder member = _member;
    if (member is SourceMemberBuilder && member.isAugmentation) {
      return member.augmentSuperTarget;
    }
    return null;
  }

  void setAsyncModifier(AsyncMarker asyncModifier) {
    Builder member = _member;
    if (member is ConstructorDeclaration) {
      throw new UnsupportedError(
          "Unexpected member $member in BodyBuilderContext.asyncModifier=");
    } else if (member is SourceProcedureBuilder) {
      member.asyncModifier = asyncModifier;
    } else if (member is SourceFactoryBuilder) {
      member.asyncModifier = asyncModifier;
    } else {
      unhandled("${member.runtimeType}", "finishFunction", member.charOffset,
          member.fileUri);
    }
  }

  void setBody(Statement body) {
    (_member as SourceFunctionBuilder).body = body;
  }

  InterfaceType? get thisType => _declarationBuilder?.thisType;
}

class LibraryBodyBuilderContext extends BodyBuilderContext {
  LibraryBodyBuilderContext(SourceLibraryBuilder sourceLibraryBuilder)
      : super(sourceLibraryBuilder, null, sourceLibraryBuilder,
            isDeclarationInstanceMember: false);
}

class ClassBodyBuilderContext extends BodyBuilderContext {
  ClassBodyBuilderContext(SourceClassBuilder sourceClassBuilder)
      : super(sourceClassBuilder.libraryBuilder, sourceClassBuilder,
            sourceClassBuilder,
            isDeclarationInstanceMember: false);
}

class EnumBodyBuilderContext extends BodyBuilderContext {
  EnumBodyBuilderContext(SourceEnumBuilder sourceEnumBuilder)
      : super(sourceEnumBuilder.libraryBuilder, sourceEnumBuilder,
            sourceEnumBuilder,
            isDeclarationInstanceMember: false);
}

class ExtensionBodyBuilderContext extends BodyBuilderContext {
  ExtensionBodyBuilderContext(SourceExtensionBuilder sourceExtensionBuilder)
      : super(sourceExtensionBuilder.libraryBuilder, sourceExtensionBuilder,
            sourceExtensionBuilder,
            isDeclarationInstanceMember: false);
}

class InlineClassBodyBuilderContext extends BodyBuilderContext {
  InlineClassBodyBuilderContext(
      SourceInlineClassBuilder sourceInlineClassBuilder)
      : super(sourceInlineClassBuilder.libraryBuilder, sourceInlineClassBuilder,
            sourceInlineClassBuilder,
            isDeclarationInstanceMember: false);
}

class TypedefBodyBuilderContext extends BodyBuilderContext {
  TypedefBodyBuilderContext(SourceTypeAliasBuilder sourceTypeAliasBuilder)
      : super(
            sourceTypeAliasBuilder.libraryBuilder, null, sourceTypeAliasBuilder,
            isDeclarationInstanceMember: false);
}

class FieldBodyBuilderContext extends BodyBuilderContext {
  FieldBodyBuilderContext(SourceFieldBuilder sourceFieldBuilder)
      : super(sourceFieldBuilder.libraryBuilder,
            sourceFieldBuilder.declarationBuilder, sourceFieldBuilder,
            isDeclarationInstanceMember:
                sourceFieldBuilder.isDeclarationInstanceMember);
}

class ProcedureBodyBuilderContext extends BodyBuilderContext {
  ProcedureBodyBuilderContext(SourceProcedureBuilder sourceProcedureBuilder)
      : super(sourceProcedureBuilder.libraryBuilder,
            sourceProcedureBuilder.declarationBuilder, sourceProcedureBuilder,
            isDeclarationInstanceMember:
                sourceProcedureBuilder.isDeclarationInstanceMember);
}

class ConstructorBodyBuilderContext extends BodyBuilderContext {
  ConstructorBodyBuilderContext(
      DeclaredSourceConstructorBuilder sourceConstructorBuilder)
      : super(
            sourceConstructorBuilder.libraryBuilder,
            sourceConstructorBuilder.declarationBuilder,
            sourceConstructorBuilder,
            isDeclarationInstanceMember:
                sourceConstructorBuilder.isDeclarationInstanceMember);
}

class InlineClassConstructorBodyBuilderContext extends BodyBuilderContext {
  InlineClassConstructorBodyBuilderContext(
      SourceInlineClassConstructorBuilder sourceConstructorBuilder)
      : super(
            sourceConstructorBuilder.libraryBuilder,
            sourceConstructorBuilder.declarationBuilder,
            sourceConstructorBuilder,
            isDeclarationInstanceMember:
                sourceConstructorBuilder.isDeclarationInstanceMember);
}

class FactoryBodyBuilderContext extends BodyBuilderContext {
  FactoryBodyBuilderContext(SourceFactoryBuilder sourceFactoryBuilder)
      : super(sourceFactoryBuilder.libraryBuilder,
            sourceFactoryBuilder.declarationBuilder, sourceFactoryBuilder,
            isDeclarationInstanceMember:
                sourceFactoryBuilder.isDeclarationInstanceMember);
}

class RedirectingFactoryBodyBuilderContext extends BodyBuilderContext {
  RedirectingFactoryBodyBuilderContext(
      RedirectingFactoryBuilder sourceFactoryBuilder)
      : super(sourceFactoryBuilder.libraryBuilder,
            sourceFactoryBuilder.declarationBuilder, sourceFactoryBuilder,
            isDeclarationInstanceMember:
                sourceFactoryBuilder.isDeclarationInstanceMember);
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
      : super(libraryBuilder, declarationBuilder, formalParameterBuilder,
            isDeclarationInstanceMember:
                formalParameterBuilder.isDeclarationInstanceMember);
}

class ExpressionCompilerProcedureBodyBuildContext extends BodyBuilderContext {
  ExpressionCompilerProcedureBodyBuildContext(
      DietListener listener, SourceProcedureBuilder sourceProcedureBuilder,
      {required bool isDeclarationInstanceMember})
      : super(listener.libraryBuilder, listener.currentDeclaration,
            sourceProcedureBuilder,
            isDeclarationInstanceMember: isDeclarationInstanceMember);
}
