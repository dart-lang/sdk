// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.formal_parameter_builder;

import 'package:_fe_analyzer_shared/src/parser/formal_parameter_kind.dart'
    show FormalParameterKind, FormalParameterKindExtension;
import 'package:_fe_analyzer_shared/src/scanner/scanner.dart' show Token;
import 'package:front_end/src/fasta/source/constructor_declaration.dart';
import 'package:kernel/ast.dart'
    show DartType, DynamicType, Expression, NullLiteral, VariableDeclaration;
import 'package:kernel/class_hierarchy.dart';

import '../constant_context.dart' show ConstantContext;
import '../kernel/body_builder.dart' show BodyBuilder;
import '../kernel/body_builder_context.dart';
import '../kernel/internal_ast.dart' show VariableDeclarationImpl;
import '../modifier.dart';
import '../scope.dart' show Scope;
import '../source/source_factory_builder.dart';
import '../source/source_field_builder.dart';
import '../source/source_library_builder.dart';
import '../util/helpers.dart' show DelayedActionPerformer;
import 'builder.dart';
import 'constructor_builder.dart';
import 'declaration_builder.dart';
import 'library_builder.dart';
import 'metadata_builder.dart';
import 'modifier_builder.dart';
import 'named_type_builder.dart';
import 'omitted_type_builder.dart';
import 'type_builder.dart';
import 'variable_builder.dart';

abstract class ParameterBuilder {
  /// List of metadata builders for the metadata declared on this parameter.
  List<MetadataBuilder>? get metadata;

  TypeBuilder get type;

  /// The kind of this parameter, i.e. if it's required, positional optional,
  /// or named optional.
  FormalParameterKind get kind;

  bool get isPositional;

  bool get isRequiredPositional;

  bool get isNamed;

  bool get isRequiredNamed;

  String? get name;

  ParameterBuilder clone(
      List<NamedTypeBuilder> newTypes,
      SourceLibraryBuilder contextLibrary,
      TypeParameterScopeBuilder contextDeclaration);
}

/// A builder for a formal parameter, i.e. a parameter on a method or
/// constructor.
class FormalParameterBuilder extends ModifierBuilderImpl
    implements VariableBuilder, ParameterBuilder, InferredTypeListener {
  static const String noNameSentinel = 'no name sentinel';

  /// List of metadata builders for the metadata declared on this parameter.
  @override
  final List<MetadataBuilder>? metadata;

  @override
  final int modifiers;

  @override
  final TypeBuilder type;

  @override
  final String name;

  @override
  final Uri? fileUri;

  @override
  final FormalParameterKind kind;

  /// The variable declaration created for this formal parameter.
  @override
  VariableDeclaration? variable;

  /// The first token of the default value, if any.
  ///
  /// This is stored until outlines have been built through
  /// [buildOutlineExpressions].
  Token? initializerToken;

  bool initializerWasInferred = false;

  /// True if the initializer was declared by the programmer.
  bool hasDeclaredInitializer = false;

  final bool isExtensionThis;

  FormalParameterBuilder(this.metadata, this.kind, this.modifiers, this.type,
      this.name, LibraryBuilder? compilationUnit, int charOffset,
      {Uri? fileUri, this.isExtensionThis = false})
      : this.fileUri = fileUri ?? compilationUnit?.fileUri,
        super(compilationUnit, charOffset) {
    type.registerInferredTypeListener(this);
  }

  @override
  String get debugName => "FormalParameterBuilder";

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

  @override
  bool get isLocal => true;

  bool get isInitializingFormal => (modifiers & initializingFormalMask) != 0;

  bool get isSuperInitializingFormal =>
      (modifiers & superInitializingFormalMask) != 0;

  bool get isCovariantByDeclaration => (modifiers & covariantMask) != 0;

  // An initializing formal parameter might be final without its
  // VariableDeclaration being final. See
  // [ProcedureBuilder.computeFormalParameterInitializerScope]..
  @override
  bool get isAssignable =>
      variable!.isAssignable &&
      !isInitializingFormal &&
      !isSuperInitializingFormal;

  @override
  String get fullNameForErrors => name;

  VariableDeclaration build(SourceLibraryBuilder library) {
    if (variable == null) {
      bool isTypeOmitted = type is OmittedTypeBuilder;
      DartType? builtType = type.build(library, TypeUse.parameterType);
      variable = new VariableDeclarationImpl(
          name == noNameSentinel ? null : name,
          // `null` is used in [VariableDeclarationImpl] to signal an omitted
          // type.
          type: isTypeOmitted ? null : builtType,
          isFinal: isFinal,
          isConst: false,
          isInitializingFormal: isInitializingFormal,
          isCovariantByDeclaration: isCovariantByDeclaration,
          isRequired: isRequiredNamed,
          hasDeclaredInitializer: hasDeclaredInitializer,
          isLowered: isExtensionThis,
          isSynthesized: name == noNameSentinel)
        ..fileOffset = charOffset;
    }
    return variable!;
  }

  @override
  void onInferredType(DartType type) {
    if (variable != null) {
      variable!.type = type;
    }
  }

  @override
  ParameterBuilder clone(
      List<NamedTypeBuilder> newTypes,
      SourceLibraryBuilder contextLibrary,
      TypeParameterScopeBuilder contextDeclaration) {
    // TODO(cstefantsova):  It's not clear how [metadata] is used currently,
    // and how it should be cloned.  Consider cloning it instead of reusing it.
    return new FunctionTypeParameterBuilder(metadata, kind,
        type.clone(newTypes, contextLibrary, contextDeclaration), name);
  }

  FormalParameterBuilder forFormalParameterInitializerScope() {
    if (isInitializingFormal) {
      return new FormalParameterBuilder(
          metadata,
          kind,
          modifiers | finalMask | initializingFormalMask,
          type,
          name,
          null,
          charOffset,
          fileUri: fileUri,
          isExtensionThis: isExtensionThis)
        ..parent = parent
        ..variable = variable;
    } else if (isSuperInitializingFormal) {
      return new FormalParameterBuilder(
          metadata,
          kind,
          modifiers | finalMask | superInitializingFormalMask,
          type,
          name,
          null,
          charOffset,
          fileUri: fileUri,
          isExtensionThis: isExtensionThis)
        ..parent = parent
        ..variable = variable;
    } else {
      return this;
    }
  }

  void finalizeInitializingFormal(
      DeclarationBuilder declarationBuilder,
      ConstructorDeclaration constructorDeclaration,
      ClassHierarchyBase hierarchy) {
    Builder? fieldBuilder = declarationBuilder.lookupLocalMember(name);
    if (fieldBuilder is SourceFieldBuilder) {
      DartType fieldType = fieldBuilder.inferType(hierarchy);
      fieldType = constructorDeclaration.substituteFieldType(fieldType);
      type.registerInferredType(fieldType);
    } else {
      type.registerInferredType(const DynamicType());
    }
  }

  /// Builds the default value from this [initializerToken] if this is a
  /// formal parameter on a const constructor or instance method.
  void buildOutlineExpressions(SourceLibraryBuilder library,
      List<DelayedActionPerformer> delayedActionPerformers) {
    // For modular compilation we need to include default values for optional
    // and named parameters in several cases:
    // * for const constructors to enable constant evaluation,
    // * for instance methods because these might be needed to generated
    //   noSuchMethod forwarders, and
    // * for generative constructors to support forwarding constructors
    //   in mixin applications.
    bool needsDefaultValues = false;
    if (parent is ConstructorBuilder) {
      needsDefaultValues = true;
    } else if (parent is SourceFactoryBuilder) {
      needsDefaultValues = parent!.isFactory && parent!.isConst;
    } else {
      needsDefaultValues = parent!.isClassInstanceMember;
    }
    if (needsDefaultValues) {
      if (initializerToken != null) {
        final DeclarationBuilder declarationBuilder =
            parent!.parent as DeclarationBuilder;
        Scope scope = declarationBuilder.scope;
        BodyBuilderContext bodyBuilderContext =
            new ParameterBodyBuilderContext(this);
        BodyBuilder bodyBuilder = library.loader
            .createBodyBuilderForOutlineExpression(
                library, bodyBuilderContext, scope, fileUri!);
        bodyBuilder.constantContext = ConstantContext.required;
        assert(!initializerWasInferred);
        Expression initializer =
            bodyBuilder.parseFieldInitializer(initializerToken!);
        initializer = bodyBuilder.typeInferrer.inferParameterInitializer(
            bodyBuilder, initializer, variable!.type, hasDeclaredInitializer);
        variable!.initializer = initializer..parent = variable;
        initializerWasInferred = true;
        bodyBuilder.performBacklogComputations(
            delayedActionPerformers: delayedActionPerformers,
            allowFurtherDelays: false);
      } else if (kind != FormalParameterKind.requiredPositional) {
        // As done by BodyBuilder.endFormalParameter.
        variable!.initializer = new NullLiteral()..parent = variable;
      }
    }
    initializerToken = null;
  }
}

class FunctionTypeParameterBuilder implements ParameterBuilder {
  @override
  final List<MetadataBuilder>? metadata;

  @override
  final FormalParameterKind kind;

  @override
  final TypeBuilder type;

  @override
  final String? name;

  FunctionTypeParameterBuilder(this.metadata, this.kind, this.type, this.name);

  @override
  ParameterBuilder clone(
      List<NamedTypeBuilder> newTypes,
      SourceLibraryBuilder contextLibrary,
      TypeParameterScopeBuilder contextDeclaration) {
    // TODO(cstefantsova):  It's not clear how [metadata] is used currently,
    // and how it should be cloned.  Consider cloning it instead of reusing it.
    return new FunctionTypeParameterBuilder(metadata, kind,
        type.clone(newTypes, contextLibrary, contextDeclaration), name);
  }

  @override
  bool get isNamed => kind.isNamed;

  @override
  bool get isRequiredNamed => kind.isRequiredNamed;

  @override
  bool get isPositional => kind.isPositional;

  @override
  bool get isRequiredPositional => kind.isRequiredPositional;
}
