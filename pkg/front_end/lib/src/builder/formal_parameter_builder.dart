// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/parser/formal_parameter_kind.dart'
    show FormalParameterKind;
import 'package:_fe_analyzer_shared/src/scanner/scanner.dart' show Token;
import 'package:kernel/ast.dart'
    show DartType, DynamicType, Expression, InvalidExpression;
import 'package:kernel/class_hierarchy.dart';

import '../base/extension_scope.dart';
import '../base/lookup_result.dart';
import '../base/modifiers.dart';
import '../base/scope.dart' show LookupScope;
import '../kernel/body_builder_context.dart';
import '../kernel/external_ast_helper.dart' as extern;
import '../kernel/internal_ast.dart'
    show
        InternalVariable,
        InternalFunctionParameter,
        InternalCatchVariable,
        InternalAnonymousMethodParameter;
import '../kernel/internal_ast_helper.dart' as intern;
import '../kernel/resolver.dart';
import '../kernel/wildcard_lowering.dart';
import '../source/fragment_factory.dart';
import '../source/source_constructor_builder.dart';
import '../source/source_factory_builder.dart';
import '../source/source_library_builder.dart';
import '../source/source_member_builder.dart';
import '../source/source_property_builder.dart';
import '../util/helpers.dart';
import 'builder.dart';
import 'declaration_builders.dart';
import 'metadata_builder.dart';
import 'omitted_type_builder.dart';
import 'property_builder.dart';
import 'type_builder.dart';
import 'variable_builder.dart';

/// A builder for an anonymous method parameter.
class AnonymousMethodParameterBuilder extends NamedBuilderImpl
    with LookupResultMixin
    implements ParameterVariableBuilder, InferredTypeListener {
  @override
  final int fileOffset;

  final Modifiers modifiers;

  @override
  TypeBuilder type;

  @override
  final String name;

  @override
  final Uri fileUri;

  @override
  final FormalParameterKind kind;

  /// The variable declaration created for this parameter.
  InternalAnonymousMethodParameter? _variable;

  /// If this is a wildcard variable, this holds the index used to create a
  /// uniquely named kernel variable for it.
  final int? _wildcardIndex;

  final int? nameOffset;

  new({
    required this.modifiers,
    required this.type,
    required this.name,
    required this.fileOffset,
    required this.fileUri,
    Token? defaultValueToken,
    int? wildcardIndex,
    required this.nameOffset,
    required this.kind,
  }) : this._wildcardIndex = wildcardIndex {
    type.registerInferredTypeListener(this);
  }

  @override
  // Coverage-ignore(suite): Not run.
  String get fullNameForErrors => name;

  @override
  NamedBuilder get getable => this;

  @override
  bool get isAssignable => false;

  @override
  bool get isConst => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isFinal => true;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isLate => false;

  @override
  bool get isPrimaryConstructorParameter => false;

  @override
  bool get isWildcard => _wildcardIndex != null;

  @override
  // Coverage-ignore(suite): Not run.
  Builder? get parent => null;

  @override
  NamedBuilder? get setable => isAssignable ? this : null;

  @override
  InternalAnonymousMethodParameter get variable => _variable!;

  @override
  InternalAnonymousMethodParameter build(SourceLibraryBuilder library) {
    if (_variable == null) {
      bool isTypeOmitted = type is OmittedTypeBuilder;
      DartType? builtType = type.build(library, TypeUse.parameterType);
      String variableName = _wildcardIndex != null
          ?
            // Coverage-ignore(suite): Not run.
            createWildcardFormalParameterName(_wildcardIndex)
          : name;

      _variable = intern.createAnonymousMethodParameter(
        name: variableName,
        type: builtType,
        isWildcard: isWildcard,
        fileOffset: fileOffset,
        isFinal: modifiers.isFinal,
        isSynthesized: false,
        isImplicitlyTyped: isTypeOmitted,
      );
    }
    return _variable!;
  }

  @override
  // Coverage-ignore(suite): Not run.
  void onInferredType(DartType type) {
    if (_variable != null) {
      _variable!.type = type;
    }
  }

  @override
  String toString() => '$runtimeType($name)';
}

/// A builder for a catch block parameter.
class CatchParameterBuilder extends NamedBuilderImpl
    with LookupResultMixin
    implements ParameterVariableBuilder, InferredTypeListener {
  @override
  final int fileOffset;

  final Modifiers modifiers;

  @override
  TypeBuilder type;

  @override
  final String name;

  @override
  final Uri fileUri;

  /// The variable declaration created for this catch parameter.
  InternalCatchVariable? _variable;

  /// If this is a wildcard variable, this holds the index used to create a
  /// uniquely named kernel variable for it.
  final int? _wildcardIndex;

  final int? nameOffset;

  new({
    required this.modifiers,
    required this.type,
    required this.name,
    required this.fileOffset,
    required this.fileUri,
    Token? defaultValueToken,
    int? wildcardIndex,
    required this.nameOffset,
  }) : this._wildcardIndex = wildcardIndex {
    type.registerInferredTypeListener(this);
  }

  @override
  // Coverage-ignore(suite): Not run.
  String get fullNameForErrors => name;

  @override
  NamedBuilder get getable => this;

  @override
  bool get isAssignable => false;

  @override
  bool get isConst => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isFinal => true;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isLate => false;

  @override
  bool get isPrimaryConstructorParameter => false;

  @override
  bool get isWildcard => _wildcardIndex != null;

  @override
  FormalParameterKind get kind {
    throw new UnsupportedError("${this.runtimeType}.kind");
  }

  @override
  // Coverage-ignore(suite): Not run.
  Builder? get parent => null;

  @override
  NamedBuilder? get setable => isAssignable ? this : null;

  @override
  InternalCatchVariable get variable => _variable!;

  @override
  InternalCatchVariable build(SourceLibraryBuilder library) {
    if (_variable == null) {
      bool isTypeOmitted = type is OmittedTypeBuilder;
      DartType? builtType = type.build(library, TypeUse.parameterType);
      String variableName = _wildcardIndex != null
          ? createWildcardFormalParameterName(_wildcardIndex)
          : name;

      _variable = intern.createCatchVariable(
        name: variableName,
        type: isTypeOmitted ? const DynamicType() : builtType,
        isWildcard: isWildcard,
        isImplicitlyTyped: isTypeOmitted,
        fileOffset: fileOffset,
        isFinal: modifiers.isFinal,
      );
    }
    return _variable!;
  }

  @override
  // Coverage-ignore(suite): Not run.
  void onInferredType(DartType type) {
    if (_variable != null) {
      _variable!.type = type;
    }
  }

  @override
  String toString() => '$runtimeType($name)';
}

/// A builder for a formal parameter, i.e. a parameter on a method or
/// constructor.
class FormalParameterBuilder extends NamedBuilderImpl
    with LookupResultMixin
    implements ParameterVariableBuilder, InferredTypeListener {
  static const String noNameSentinel = 'no name sentinel';

  @override
  final int fileOffset;

  List<MetadataBuilder>? _metadata;

  final Modifiers modifiers;

  @override
  TypeBuilder type;

  @override
  final String name;

  /// If this parameter is a private named parameter that refers to an instance
  /// field, then this is the corresponding public name for the parameter.
  ///
  /// For example:
  ///
  ///     class C {
  ///       int? _x;
  ///       C({this._x});
  ///     }
  ///
  /// Here, [publicName] for `_x` will be `x`. If the formal parameter isn't a
  /// private named parameter that refers to a field, then this is `null`.
  final String? publicName;

  @override
  final Uri fileUri;

  @override
  final FormalParameterKind kind;

  /// The variable declaration created for this formal parameter.
  InternalFunctionParameter? _variable;

  /// The first token of the default value, if any.
  ///
  /// This is stored until outlines have been built through
  /// [buildOutlineExpressions].
  Token? _defaultValueToken;

  bool defaultValueWasInferred = false;

  /// True if the default value was declared by the programmer.
  final bool hasImmediatelyDeclaredDefaultValue;

  /// True if the initializer was declared by the programmer, either directly
  /// or inferred from a super parameter.
  bool hasDeclaredDefaultValue;

  final bool isExtensionThis;

  /// If this is a wildcard variable, this holds the index used to create a
  /// uniquely named kernel variable for it.
  final int? _wildcardIndex;

  final int? nameOffset;

  @override
  final bool isPrimaryConstructorParameter;

  new({
    required this.kind,
    this._metadata,
    required this.modifiers,
    required this.type,
    required this.name,
    required this.fileOffset,
    required this.fileUri,
    this.isExtensionThis = false,
    Token? defaultValueToken,
    required this.hasImmediatelyDeclaredDefaultValue,
    int? wildcardIndex,
    this.publicName,
    required this.nameOffset,
    this.isPrimaryConstructorParameter = false,
    InternalFunctionParameter? variable,
  }) : this.hasDeclaredDefaultValue = hasImmediatelyDeclaredDefaultValue,
       this._defaultValueToken = defaultValueToken,
       this._wildcardIndex = wildcardIndex,
       this._variable = variable {
    type.registerInferredTypeListener(this);
  }

  @override
  // Coverage-ignore(suite): Not run.
  String get fullNameForErrors => name;

  /// Returns and removes the metadata from this builder.
  ///
  /// Metadata builders hold tokens, and since metadata is generally not
  /// processed from the builder, but instead from the expressions during body
  /// builder, the responsibility of handling the metadata must be passed on.
  List<MetadataBuilder>? takeMetadata() {
    List<MetadataBuilder>? result = _metadata;
    _metadata = null;
    return result;
  }

  @override
  NamedBuilder get getable => this;

  // An initializing formal parameter might be final without its
  // [Variable] being final. See
  // [ProcedureBuilder.computeFormalParameterInitializerScope]..
  @override
  bool get isAssignable =>
      variable.isAssignable &&
      !isInitializingFormal &&
      !isSuperInitializingFormal;

  @override
  bool get isConst => modifiers.isConst;

  bool get isCovariantByDeclaration => modifiers.isCovariant;

  @override
  bool get isFinal => variable.isFinal;

  bool get isInitializingFormal => modifiers.isInitializingFormal;

  @override
  bool get isLate => variable.isLate;

  bool get isSuperInitializingFormal => modifiers.isSuperInitializingFormal;

  @override
  bool get isWildcard => _wildcardIndex != null;

  @override
  // Coverage-ignore(suite): Not run.
  Builder? get parent => null;

  @override
  NamedBuilder? get setable => isAssignable ? this : null;

  @override
  InternalFunctionParameter get variable => _variable!;

  @override
  InternalFunctionParameter build(SourceLibraryBuilder library) {
    if (_variable == null) {
      bool isTypeOmitted = type is OmittedTypeBuilder;
      DartType? builtType = type.build(library, TypeUse.parameterType);

      String? variableName = switch (name) {
        noNameSentinel => null,
        // If the parameter is a private named parameter, use the public name
        // for the corresponding variable.
        _ when publicName != null => publicName,
        _ when _wildcardIndex != null => createWildcardFormalParameterName(
          _wildcardIndex,
        ),
        _ => name,
      };

      switch (kind) {
        case FormalParameterKind.requiredPositional:
        case FormalParameterKind.optionalPositional:
          _variable = intern.createPositionalParameter(
            cosmeticName: variableName,
            type: isTypeOmitted ? const DynamicType() : builtType,
            defaultValue: null,
            isCovariantByDeclaration: isCovariantByDeclaration,
            isInitializingFormal: isInitializingFormal,
            isSuperInitializingFormal: isSuperInitializingFormal,
            isFinal: modifiers.isFinal,
            hasDeclaredDefaultValue: hasDeclaredDefaultValue,
            isLowered: isExtensionThis,
            isSynthesized: name == noNameSentinel,
            isWildcard: isWildcard,
            fileOffset: fileOffset,
            isImplicitlyTyped: isTypeOmitted,
          );
        case FormalParameterKind.requiredNamed:
        case FormalParameterKind.optionalNamed:
          _variable = intern.createNamedParameter(
            parameterName: variableName!,
            type: isTypeOmitted ? const DynamicType() : builtType,
            defaultValue: null,
            isCovariantByDeclaration: isCovariantByDeclaration,
            isRequired: isRequiredNamed,
            isInitializingFormal: isInitializingFormal,
            isSuperInitializingFormal: isSuperInitializingFormal,
            isFinal: modifiers.isFinal,
            hasDeclaredDefaultValue: hasDeclaredDefaultValue,
            isSynthesized: name == noNameSentinel,
            isWildcard: isWildcard,
            isRenamedPrivateNamedParameter: publicName != null,
            isImplicitlyTyped: isTypeOmitted,
            fileOffset: fileOffset,
          );
      }
    }
    return _variable!;
  }

  /// Builds the default value from this [initializerToken] if this is a
  /// formal parameter on a const constructor or instance method.
  void buildOutlineExpressions({
    required SourceLibraryBuilder libraryBuilder,
    required DeclarationBuilder? declarationBuilder,
    required SourceMemberBuilder memberBuilder,
    required ExtensionScope extensionScope,
    required LookupScope scope,
  }) {
    // Metadata is not processed through the builder, but instead from the
    // expressions during body building, so we discard any metadata here.
    takeMetadata();
    // For const constructors we need to include default parameter values
    // into the outline. For all other formals we need to call
    // buildOutlineExpressions to clear defaultValueToken to prevent
    // consuming too much memory.
    Token? defaultValueToken = _takeDefaultValueToken();
    if (_needsDefaultValuesBuiltAsOutlineExpressions(memberBuilder)) {
      if (defaultValueToken != null) {
        BodyBuilderContext bodyBuilderContext = new ParameterBodyBuilderContext(
          libraryBuilder,
          declarationBuilder,
          this,
        );
        assert(!defaultValueWasInferred);
        Resolver resolver = libraryBuilder.loader.createResolver();
        Expression defaultValue = resolver.buildParameterDefaultValue(
          libraryBuilder: libraryBuilder,
          bodyBuilderContext: bodyBuilderContext,
          extensionScope: extensionScope,
          scope: scope,
          fileUri: fileUri,
          defaultValueToken: defaultValueToken,
          declaredType: variable.type,
          hasDeclaredDefaultValue: hasDeclaredDefaultValue,
        );
        variable.updateDefaultValue(defaultValue);
        if (defaultValue is InvalidExpression) {
          variable.hasErroneousDefaultValue = true;
        }
      } else if (kind.isOptional) {
        // As done by BodyBuilder.endFormalParameter.
        variable.updateDefaultValue(
          extern.createNullLiteral(fileOffset: fileOffset),
        );
      }
      defaultValueWasInferred = true;
    }
  }

  /// Returns the [_defaultValueToken] field and without clearing it.
  ///
  /// This is used to copy ownership of the token to the receiver, such that
  /// both this [FormalParameterBuilder] and the receiver owns a copy. Tokens
  /// need to be cleared during the outline phase to avoid holding the token
  /// stream in memory.
  ///
  /// This is used when creating primary constructor formal parameters, where
  /// the default value should be used both to infer the field type and to
  /// create the default value for the constructor parameter.
  Token? copyDefaultValueToken() => _defaultValueToken;

  void finalizeInitializingFormal(
    DeclarationBuilder declarationBuilder,
    SourceConstructorBuilder constructorBuilder,
    ClassHierarchyBase hierarchy,
  ) {
    String fieldName = isWildcardLoweredFormalParameter(name) ? '_' : name;
    LookupResult? result = declarationBuilder.lookupLocalMember(fieldName);
    Builder? fieldBuilder = result?.getable;
    if (result is DuplicateMemberLookupResult) {
      fieldBuilder = result.declarations.first;
    }
    if (fieldBuilder is SourcePropertyBuilder && fieldBuilder.hasField) {
      DartType fieldType = fieldBuilder.inferFieldType(hierarchy);
      fieldType = constructorBuilder.substituteFieldType(fieldType);
      type.registerInferredType(fieldType);
    } else {
      type.registerInferredType(const DynamicType());
    }
  }

  /// Creates the [FormalParameterBuilder] for a parameter used in the formal
  /// parameters in a primary constructor.
  ///
  /// If [isDeclaring] is `true` the parameter is marked as an initializing
  /// formal whose type is inferred. Otherwise the parameter is marked as
  /// final primary constructor parameter.
  ///
  /// The created parameter replaces the original parameter in the primary
  /// constructor declaration.
  FormalParameterBuilder forPrimaryConstructor(
    FragmentFactory builderFactory, {
    required bool isDeclaring,
  }) {
    assert(_variable == null);
    return new FormalParameterBuilder(
      kind: kind,
      modifiers: isDeclaring
          ? (modifiers | Modifiers.InitializingFormal)
          : modifiers,
      type: isDeclaring
          ? builderFactory.addInferableType(InferenceDefaultType.NullableObject)
          : type,
      name: name,
      fileOffset: fileOffset,
      nameOffset: nameOffset,
      fileUri: fileUri,
      isExtensionThis: isExtensionThis,
      defaultValueToken: copyDefaultValueToken(),
      hasImmediatelyDeclaredDefaultValue: hasImmediatelyDeclaredDefaultValue,
      publicName: publicName,
      wildcardIndex: _wildcardIndex,
      isPrimaryConstructorParameter: !isDeclaring,
    );
  }

  @override
  void onInferredType(DartType type) {
    _variable?.type = type;
  }

  @override
  String toString() => '$runtimeType($name)';

  /// Returns the [_defaultValueToken] field and clears it.
  ///
  /// This is used to transfer ownership of the token to the receiver. Tokens
  /// need to be cleared during the outline phase to avoid holding the token
  /// stream in memory.
  Token? _takeDefaultValueToken() {
    Token? initializerToken = _defaultValueToken;
    _defaultValueToken = null;
    return initializerToken;
  }

  static bool _needsDefaultValuesBuiltAsOutlineExpressions(
    SourceMemberBuilder memberBuilder,
  ) {
    // For modular compilation we need to include default values for optional
    // and named parameters in several cases:
    // * for const constructors to enable constant evaluation,
    // * for instance methods because these might be needed to generated
    //   noSuchMethod forwarders,
    // * for generative constructors to support forwarding constructors
    //   in mixin applications, and
    // * for factories, to uphold the invariant that optional parameters always
    //   have default values, even during modular compilation.
    if (memberBuilder is SourceConstructorBuilder) {
      return true;
    } else if (memberBuilder is SourceFactoryBuilder) {
      return true;
    } else {
      return memberBuilder.isClassInstanceMember;
    }
  }
}

class FunctionTypeParameterBuilder implements ParameterBuilder {
  @override
  final FormalParameterKind kind;

  @override
  final TypeBuilder type;

  @override
  final String? name;

  new(this.kind, this.type, this.name);

  @override
  int get fileOffset {
    throw new UnsupportedError("${this.runtimeType}.fileOffset");
  }

  @override
  // Coverage-ignore(suite): Not run.
  bool get isWildcard => false;

  @override
  InternalVariable build(SourceLibraryBuilder library) {
    throw new UnsupportedError("${this.runtimeType}.build");
  }
}

abstract class ParameterBuilder {
  int get fileOffset;

  /// Whether this formal parameter is a wildcard variable.
  bool get isWildcard;

  /// The kind of this parameter, i.e. if it's required, positional optional,
  /// or named optional.
  FormalParameterKind get kind;

  String? get name;

  TypeBuilder get type;

  InternalVariable build(SourceLibraryBuilder library);
}

abstract class ParameterVariableBuilder
    implements ParameterBuilder, VariableBuilder {}

extension ParameterBuilderExtension on ParameterBuilder {
  bool get isNamed => kind.isNamed;

  bool get isOptional => kind.isOptional;

  // TODO(johnniwinther): This was previously named `isOptional` so we might
  // have some uses that intended to use the now existing `isOptional` method.
  bool get isOptionalPositional => !isRequiredPositional;

  bool get isPositional => kind.isPositional;

  bool get isRequiredNamed => kind.isRequiredNamed;

  bool get isRequiredPositional => kind.isRequiredPositional;
}
