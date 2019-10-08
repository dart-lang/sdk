// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.formal_parameter_builder;

import '../parser.dart' show FormalParameterKind;

import '../parser/formal_parameter_kind.dart'
    show
        isMandatoryFormalParameterKind,
        isOptionalNamedFormalParameterKind,
        isOptionalPositionalFormalParameterKind;

import 'builder.dart' show LibraryBuilder, MetadataBuilder, TypeBuilder;

import 'modifier_builder.dart';

import 'package:kernel/ast.dart' show VariableDeclaration;

import '../constant_context.dart' show ConstantContext;

import '../modifier.dart' show finalMask, initializingFormalMask, requiredMask;

import '../scanner.dart' show Token;

import '../scope.dart' show Scope;

import '../source/source_library_builder.dart' show SourceLibraryBuilder;

import '../source/source_loader.dart' show SourceLoader;

import '../kernel/body_builder.dart' show BodyBuilder;

import '../kernel/kernel_builder.dart'
    show
        ClassBuilder,
        Builder,
        ConstructorBuilder,
        FieldBuilder,
        LibraryBuilder,
        MetadataBuilder,
        TypeBuilder;

import '../kernel/kernel_shadow_ast.dart' show VariableDeclarationImpl;

/// A builder for a formal parameter, i.e. a parameter on a method or
/// constructor.
class FormalParameterBuilder extends ModifierBuilderImpl {
  /// List of metadata builders for the metadata declared on this parameter.
  final List<MetadataBuilder> metadata;

  final int modifiers;

  final TypeBuilder type;

  final String name;

  /// The kind of this parameter, i.e. if it's required, positional optional,
  /// or named optional.
  FormalParameterKind kind = FormalParameterKind.mandatory;

  /// The variable declaration created for this formal parameter.
  VariableDeclaration variable;

  /// The first token of the default value, if any.
  ///
  /// This is stored until outlines have been built through
  /// [buildOutlineExpressions].
  Token initializerToken;

  FormalParameterBuilder(this.metadata, this.modifiers, this.type, this.name,
      LibraryBuilder compilationUnit, int charOffset,
      [Uri fileUri])
      : super(compilationUnit, charOffset, fileUri);

  String get debugName => "FormalParameterBuilder";

  // TODO(johnniwinther): Cleanup `isRequired` semantics in face of required
  // named parameters.
  bool get isRequired => isMandatoryFormalParameterKind(kind);

  bool get isNamedRequired => (modifiers & requiredMask) != 0;

  bool get isPositional {
    return isOptionalPositionalFormalParameterKind(kind) ||
        isMandatoryFormalParameterKind(kind);
  }

  bool get isNamed => isOptionalNamedFormalParameterKind(kind);

  bool get isOptional => !isRequired;

  bool get isLocal => true;

  @override
  String get fullNameForErrors => name;

  VariableDeclaration get target => variable;

  VariableDeclaration build(
      SourceLibraryBuilder library, int functionNestingLevel) {
    if (variable == null) {
      variable = new VariableDeclarationImpl(name, functionNestingLevel,
          type: type?.build(library),
          isFinal: isFinal,
          isConst: isConst,
          isFieldFormal: isInitializingFormal,
          isCovariant: isCovariant,
          isRequired: isNamedRequired)
        ..fileOffset = charOffset;
    }
    return variable;
  }

  FormalParameterBuilder clone(List<TypeBuilder> newTypes) {
    // TODO(dmitryas):  It's not clear how [metadata] is used currently, and
    // how it should be cloned.  Consider cloning it instead of reusing it.
    return new FormalParameterBuilder(metadata, modifiers,
        type?.clone(newTypes), name, parent, charOffset, fileUri)
      ..kind = kind;
  }

  FormalParameterBuilder forFormalParameterInitializerScope() {
    assert(variable != null);
    return !isInitializingFormal
        ? this
        : (new FormalParameterBuilder(
            metadata,
            modifiers | finalMask | initializingFormalMask,
            type,
            name,
            null,
            charOffset,
            fileUri)
          ..parent = parent
          ..variable = variable);
  }

  void finalizeInitializingFormal() {
    Object cls = parent.parent;
    if (cls is ClassBuilder) {
      Builder fieldBuilder = cls.scope.lookup(name, charOffset, fileUri);
      if (fieldBuilder is FieldBuilder) {
        variable.type = fieldBuilder.field.type;
      }
    }
  }

  /// Builds the default value from this [initializerToken] if this is a
  /// formal parameter on a const constructor or instance method.
  void buildOutlineExpressions(LibraryBuilder library) {
    // For modular compilation we need to include initializers for optional
    // and named parameters of const constructors into the outline - to enable
    // constant evaluation. Similarly we need to include initializers for
    // optional and named parameters of instance methods because these might be
    // needed to generated noSuchMethod forwarders.
    bool isConstConstructorParameter = false;
    if (parent is ConstructorBuilder) {
      ConstructorBuilder constructorBuilder = parent;
      isConstConstructorParameter = constructorBuilder.constructor.isConst;
    }
    if ((isConstConstructorParameter || parent.isClassInstanceMember) &&
        initializerToken != null) {
      final ClassBuilder classBuilder = parent.parent;
      Scope scope = classBuilder.scope;
      BodyBuilder bodyBuilder = library.loader
          .createBodyBuilderForOutlineExpression(
              library, classBuilder, this, scope, fileUri);
      bodyBuilder.constantContext = ConstantContext.required;
      variable.initializer = bodyBuilder.parseFieldInitializer(initializerToken)
        ..parent = variable;
      bodyBuilder.typeInferrer?.inferParameterInitializer(
          bodyBuilder, variable.initializer, variable.type);
      if (library.loader is SourceLoader) {
        SourceLoader loader = library.loader;
        loader.transformPostInference(variable,
            bodyBuilder.transformSetLiterals, bodyBuilder.transformCollections);
      }
      bodyBuilder.resolveRedirectingFactoryTargets();
    }
    initializerToken = null;
  }
}
