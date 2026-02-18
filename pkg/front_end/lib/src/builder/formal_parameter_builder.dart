// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/parser/formal_parameter_kind.dart'
    show FormalParameterKind;
import 'package:_fe_analyzer_shared/src/scanner/scanner.dart' show Token;
import 'package:kernel/ast.dart'
    show
        DartType,
        DynamicType,
        Expression,
        InvalidExpression,
        NamedParameter,
        NullLiteral,
        PositionalParameter,
        VariableDeclaration;
import 'package:kernel/class_hierarchy.dart';

import '../base/extension_scope.dart';
import '../base/lookup_result.dart';
import '../base/modifiers.dart';
import '../base/scope.dart' show LookupScope;
import '../kernel/body_builder_context.dart';
import '../kernel/internal_ast.dart'
    show
        InternalNamedParameter,
        InternalPositionalParameter,
        VariableDeclarationImpl;
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
import 'omitted_type_builder.dart';
import 'property_builder.dart';
import 'type_builder.dart';
import 'variable_builder.dart';

abstract class ParameterBuilder {
  TypeBuilder get type;

  /// The kind of this parameter, i.e. if it's required, positional optional,
  /// or named optional.
  FormalParameterKind get kind;

  bool get isPositional;

  bool get isRequiredPositional;

  bool get isNamed;

  bool get isRequiredNamed;

  String? get name;
}

/// A builder for a formal parameter, i.e. a parameter on a method or
/// constructor.
class FormalParameterBuilder extends NamedBuilderImpl
    with LookupResultMixin
    implements VariableBuilder, ParameterBuilder, InferredTypeListener {
  static const String noNameSentinel = 'no name sentinel';

  @override
  final int fileOffset;

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
  @override
  VariableDeclaration? variable;

  /// The first token of the default value, if any.
  ///
  /// This is stored until outlines have been built through
  /// [buildOutlineExpressions].
  Token? _defaultValueToken;

  bool initializerWasInferred = false;

  /// True if the initializer was declared by the programmer.
  final bool hasImmediatelyDeclaredInitializer;

  /// True if the initializer was declared by the programmer, either directly
  /// or inferred from a super parameter.
  bool hasDeclaredInitializer;

  final bool isExtensionThis;

  /// Whether this formal parameter is a wildcard variable.
  final bool isWildcard;

  final int? nameOffset;

  final bool isClosureContextLoweringEnabled;

  FormalParameterBuilder({
    required this.kind,
    required this.modifiers,
    required this.type,
    required this.name,
    required this.fileOffset,
    required this.fileUri,
    this.isExtensionThis = false,
    Token? defaultValueToken,
    required this.hasImmediatelyDeclaredInitializer,
    this.isWildcard = false,
    this.publicName,
    required this.nameOffset,
    required this.isClosureContextLoweringEnabled,
  }) : this.hasDeclaredInitializer = hasImmediatelyDeclaredInitializer,
       this._defaultValueToken = defaultValueToken {
    type.registerInferredTypeListener(this);
  }

  @override
  // Coverage-ignore(suite): Not run.
  Builder? get parent => null;

  @override
  bool get isRequiredPositional => kind.isRequiredPositional;

  // TODO(johnniwinther): This was previously named `isOptional` so we might
  // have some uses that intended to use the now existing `isOptional` method.
  bool get isOptionalPositional => !isRequiredPositional;

  @override
  bool get isRequiredNamed => kind.isRequiredNamed;

  @override
  bool get isPositional => kind.isPositional;

  @override
  bool get isNamed => kind.isNamed;

  bool get isOptional => kind.isOptional;

  bool get isInitializingFormal => modifiers.isInitializingFormal;

  bool get isSuperInitializingFormal => modifiers.isSuperInitializingFormal;

  bool get isCovariantByDeclaration => modifiers.isCovariant;

  @override
  bool get isConst => modifiers.isConst;

  // An initializing formal parameter might be final without its
  // VariableDeclaration being final. See
  // [ProcedureBuilder.computeFormalParameterInitializerScope]..
  @override
  bool get isAssignable =>
      variable!.isAssignable &&
      !isInitializingFormal &&
      !isSuperInitializingFormal;

  @override
  NamedBuilder get getable => this;

  @override
  NamedBuilder? get setable => isAssignable ? this : null;

  @override
  // Coverage-ignore(suite): Not run.
  String get fullNameForErrors => name;

  VariableDeclaration build(SourceLibraryBuilder library) {
    if (variable == null) {
      bool isTypeOmitted = type is OmittedTypeBuilder;
      DartType? builtType = type.build(library, TypeUse.parameterType);

      String? variableName = switch (name) {
        noNameSentinel => null,
        // If the parameter is a private named parameter, use the public name
        // for the corresponding variable.
        _ when publicName != null => publicName,
        _ => name,
      };

      if (isClosureContextLoweringEnabled) {
        switch (kind) {
          case FormalParameterKind.requiredPositional:
          case FormalParameterKind.optionalPositional:
            variable = new InternalPositionalParameter(
              astVariable: new PositionalParameter(
                cosmeticName: variableName,
                type: isTypeOmitted ? const DynamicType() : builtType,
                defaultValue: null,
                isCovariantByDeclaration: isCovariantByDeclaration,
                isInitializingFormal: isInitializingFormal,
                isFinal: modifiers.isFinal,
                hasDeclaredDefaultType: hasDeclaredInitializer,
                isLowered: isExtensionThis,
                isSynthesized: name == noNameSentinel,
                isWildcard: isWildcard,
              )..fileOffset = fileOffset,
              isImplicitlyTyped: isTypeOmitted,
            )..fileOffset = fileOffset;
          case FormalParameterKind.requiredNamed:
          // Coverage-ignore(suite): Not run.
          case FormalParameterKind.optionalNamed:
            variable = new InternalNamedParameter(
              astVariable: new NamedParameter(
                parameterName: variableName!,
                type: isTypeOmitted ? const DynamicType() : builtType,
                defaultValue: null,
                isCovariantByDeclaration: isCovariantByDeclaration,
                isRequired: isRequiredNamed,
                isInitializingFormal: isInitializingFormal,
                isFinal: modifiers.isFinal,
                hasDeclaredDefaultType: hasDeclaredInitializer,
                isSynthesized: name == noNameSentinel,
                isWildcard: isWildcard,
              )..fileOffset = fileOffset,
              isImplicitlyTyped: isTypeOmitted,
            )..fileOffset = fileOffset;
        }
      } else {
        variable = new VariableDeclarationImpl(
          variableName,
          // [VariableDeclarationImpl] uses `null` to signal an omitted type.
          type: isTypeOmitted ? null : builtType,
          isFinal: modifiers.isFinal,
          isConst: false,
          isInitializingFormal: isInitializingFormal,
          isSuperInitializingFormal: isSuperInitializingFormal,
          isCovariantByDeclaration: isCovariantByDeclaration,
          isRequired: isRequiredNamed,
          hasDeclaredInitializer: hasDeclaredInitializer,
          isLowered: isExtensionThis,
          isSynthesized: name == noNameSentinel,
          isWildcard: isWildcard,
        )..fileOffset = fileOffset;
      }
    }
    return variable!;
  }

  @override
  void onInferredType(DartType type) {
    if (variable != null) {
      variable!.type = type;
    }
  }

  FormalParameterBuilder forPrimaryConstructor(FragmentFactory builderFactory) {
    return new FormalParameterBuilder(
      kind: kind,
      modifiers: modifiers | Modifiers.InitializingFormal,
      type: builderFactory.addInferableType(
        InferenceDefaultType.NullableObject,
      ),
      name: name,
      fileOffset: fileOffset,
      nameOffset: nameOffset,
      fileUri: fileUri,
      isExtensionThis: isExtensionThis,
      defaultValueToken: copyDefaultValueToken(),
      hasImmediatelyDeclaredInitializer: hasImmediatelyDeclaredInitializer,
      publicName: publicName,
      isClosureContextLoweringEnabled: isClosureContextLoweringEnabled,
    )..variable = variable;
  }

  FormalParameterBuilder forFormalParameterInitializerScope() {
    if (isInitializingFormal) {
      return new FormalParameterBuilder(
        kind: kind,
        modifiers: modifiers | Modifiers.Final | Modifiers.InitializingFormal,
        type: type,
        name: name,
        fileOffset: fileOffset,
        nameOffset: nameOffset,
        fileUri: fileUri,
        isExtensionThis: isExtensionThis,
        hasImmediatelyDeclaredInitializer: hasImmediatelyDeclaredInitializer,
        publicName: publicName,
        isClosureContextLoweringEnabled: isClosureContextLoweringEnabled,
      )..variable = variable;
    } else if (isSuperInitializingFormal) {
      return new FormalParameterBuilder(
        kind: kind,
        modifiers:
            modifiers | Modifiers.Final | Modifiers.SuperInitializingFormal,
        type: type,
        name: name,
        fileOffset: fileOffset,
        nameOffset: nameOffset,
        fileUri: fileUri,
        isExtensionThis: isExtensionThis,
        hasImmediatelyDeclaredInitializer: hasImmediatelyDeclaredInitializer,
        publicName: publicName,
        isClosureContextLoweringEnabled: isClosureContextLoweringEnabled,
      )..variable = variable;
    } else {
      return this;
    }
  }

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

  /// Builds the default value from this [initializerToken] if this is a
  /// formal parameter on a const constructor or instance method.
  void buildOutlineExpressions({
    required SourceLibraryBuilder libraryBuilder,
    required DeclarationBuilder? declarationBuilder,
    required SourceMemberBuilder memberBuilder,
    required ExtensionScope extensionScope,
    required LookupScope scope,
  }) {
    // For const constructors we need to include default parameter values
    // into the outline. For all other formals we need to call
    // buildOutlineExpressions to clear initializerToken to prevent
    // consuming too much memory.
    Token? initializerToken = _takeDefaultValueToken();
    if (_needsDefaultValuesBuiltAsOutlineExpressions(memberBuilder)) {
      if (initializerToken != null) {
        BodyBuilderContext bodyBuilderContext = new ParameterBodyBuilderContext(
          libraryBuilder,
          declarationBuilder,
          this,
        );
        assert(!initializerWasInferred);
        Resolver resolver = libraryBuilder.loader.createResolver();
        Expression initializer = resolver.buildParameterInitializer(
          libraryBuilder: libraryBuilder,
          bodyBuilderContext: bodyBuilderContext,
          extensionScope: extensionScope,
          scope: scope,
          fileUri: fileUri,
          initializerToken: initializerToken,
          declaredType: variable!.type,
          hasDeclaredInitializer: hasDeclaredInitializer,
        );
        variable!.initializer = initializer..parent = variable;
        if (initializer is InvalidExpression) {
          variable!.isErroneouslyInitialized = true;
        }
        initializerWasInferred = true;
      } else if (kind.isOptional) {
        // As done by BodyBuilder.endFormalParameter.
        variable!.initializer = new NullLiteral()..parent = variable;
      }
    }
  }

  @override
  String toString() => '$runtimeType($name)';
}

class FunctionTypeParameterBuilder implements ParameterBuilder {
  @override
  final FormalParameterKind kind;

  @override
  final TypeBuilder type;

  @override
  final String? name;

  FunctionTypeParameterBuilder(this.kind, this.type, this.name);

  @override
  bool get isNamed => kind.isNamed;

  @override
  bool get isRequiredNamed => kind.isRequiredNamed;

  @override
  bool get isPositional => kind.isPositional;

  @override
  bool get isRequiredPositional => kind.isRequiredPositional;
}
