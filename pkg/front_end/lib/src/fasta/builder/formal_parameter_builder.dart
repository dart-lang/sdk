// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.formal_parameter_builder;

import 'package:_fe_analyzer_shared/src/parser/formal_parameter_kind.dart'
    show
        isMandatoryFormalParameterKind,
        isOptionalNamedFormalParameterKind,
        isOptionalPositionalFormalParameterKind;
import 'package:_fe_analyzer_shared/src/parser/parser.dart'
    show FormalParameterKind;
import 'package:_fe_analyzer_shared/src/scanner/scanner.dart' show Token;
import 'package:kernel/ast.dart'
    show DartType, DynamicType, Expression, VariableDeclaration;
import 'package:kernel/src/legacy_erasure.dart';

import '../constant_context.dart' show ConstantContext;
import '../kernel/body_builder.dart' show BodyBuilder;
import '../kernel/internal_ast.dart' show VariableDeclarationImpl;
import '../modifier.dart';
import '../scope.dart' show Scope;
import '../source/source_factory_builder.dart';
import '../source/source_field_builder.dart';
import '../source/source_library_builder.dart';
import '../util/helpers.dart' show DelayedActionPerformer;
import 'builder.dart';
import 'class_builder.dart';
import 'constructor_builder.dart';
import 'library_builder.dart';
import 'metadata_builder.dart';
import 'modifier_builder.dart';
import 'named_type_builder.dart';
import 'type_builder.dart';
import 'variable_builder.dart';

/// A builder for a formal parameter, i.e. a parameter on a method or
/// constructor.
class FormalParameterBuilder extends ModifierBuilderImpl
    implements VariableBuilder {
  static const String noNameSentinel = 'no name sentinel';

  /// List of metadata builders for the metadata declared on this parameter.
  final List<MetadataBuilder>? metadata;

  @override
  final int modifiers;

  final TypeBuilder? type;

  @override
  final String name;

  @override
  final Uri? fileUri;

  /// The kind of this parameter, i.e. if it's required, positional optional,
  /// or named optional.
  FormalParameterKind kind = FormalParameterKind.mandatory;

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

  FormalParameterBuilder(this.metadata, this.modifiers, this.type, this.name,
      LibraryBuilder? compilationUnit, int charOffset,
      {Uri? fileUri, this.isExtensionThis: false})
      : this.fileUri = fileUri ?? compilationUnit?.fileUri,
        super(compilationUnit, charOffset);

  @override
  String get debugName => "FormalParameterBuilder";

  // TODO(johnniwinther): Cleanup `isRequired` semantics in face of required
  // named parameters.
  bool get isRequired => isMandatoryFormalParameterKind(kind);

  // TODO(johnniwinther): Rename to `isRequired`.
  bool get isNamedRequired => (modifiers & requiredMask) != 0;

  bool get isPositional {
    return isOptionalPositionalFormalParameterKind(kind) ||
        isMandatoryFormalParameterKind(kind);
  }

  bool get isNamed => isOptionalNamedFormalParameterKind(kind);

  bool get isOptional => !isRequired;

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

  VariableDeclaration build(
      SourceLibraryBuilder library, int functionNestingLevel) {
    if (variable == null) {
      DartType? builtType = type?.build(library);
      if (!library.isNonNullableByDefault && builtType != null) {
        builtType = legacyErasure(builtType);
      }
      variable = new VariableDeclarationImpl(
          name == noNameSentinel ? null : name, functionNestingLevel,
          type: builtType,
          isFinal: isFinal,
          isConst: isConst,
          isInitializingFormal: isInitializingFormal,
          isCovariantByDeclaration: isCovariantByDeclaration,
          isRequired: isNamedRequired,
          hasDeclaredInitializer: hasDeclaredInitializer,
          isLowered: isExtensionThis)
        ..fileOffset = charOffset;
    }
    return variable!;
  }

  FormalParameterBuilder clone(
      List<NamedTypeBuilder> newTypes,
      SourceLibraryBuilder contextLibrary,
      TypeParameterScopeBuilder contextDeclaration) {
    // TODO(dmitryas):  It's not clear how [metadata] is used currently, and
    // how it should be cloned.  Consider cloning it instead of reusing it.
    return new FormalParameterBuilder(
        metadata,
        modifiers,
        type?.clone(newTypes, contextLibrary, contextDeclaration),
        name,
        parent as LibraryBuilder?,
        charOffset,
        fileUri: fileUri,
        isExtensionThis: isExtensionThis)
      ..kind = kind;
  }

  FormalParameterBuilder forFormalParameterInitializerScope() {
    // ignore: unnecessary_null_comparison
    assert(variable != null);
    if (isInitializingFormal) {
      return new FormalParameterBuilder(
          metadata,
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

  void finalizeInitializingFormal(ClassBuilder classBuilder) {
    Builder? fieldBuilder = classBuilder.lookupLocalMember(name);
    if (fieldBuilder is SourceFieldBuilder) {
      variable!.type = fieldBuilder.inferType();
    } else {
      variable!.type = const DynamicType();
    }
  }

  /// Builds the default value from this [initializerToken] if this is a
  /// formal parameter on a const constructor or instance method.
  void buildOutlineExpressions(SourceLibraryBuilder library,
      List<DelayedActionPerformer> delayedActionPerformers) {
    if (initializerToken != null) {
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
        final ClassBuilder classBuilder = parent!.parent as ClassBuilder;
        Scope scope = classBuilder.scope;
        BodyBuilder bodyBuilder = library.loader
            .createBodyBuilderForOutlineExpression(
                library, classBuilder, this, scope, fileUri!);
        bodyBuilder.constantContext = ConstantContext.required;
        assert(!initializerWasInferred);
        Expression initializer =
            bodyBuilder.parseFieldInitializer(initializerToken!);
        initializer = bodyBuilder.typeInferrer.inferParameterInitializer(
            bodyBuilder, initializer, variable!.type, hasDeclaredInitializer);
        variable!.initializer = initializer..parent = variable;
        library.loader.transformPostInference(
            variable!,
            bodyBuilder.transformSetLiterals,
            bodyBuilder.transformCollections,
            library.library);
        initializerWasInferred = true;
        bodyBuilder.performBacklogComputations(delayedActionPerformers);
      }
    }
    initializerToken = null;
  }
}
