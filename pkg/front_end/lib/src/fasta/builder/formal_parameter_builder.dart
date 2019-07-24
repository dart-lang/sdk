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

import 'builder.dart'
    show LibraryBuilder, MetadataBuilder, ModifierBuilder, TypeBuilder;

import 'package:kernel/ast.dart' show VariableDeclaration;

import '../constant_context.dart' show ConstantContext;

import '../modifier.dart' show finalMask, initializingFormalMask;

import '../scanner.dart' show Token;

import '../scope.dart' show Scope;

import '../source/source_loader.dart' show SourceLoader;

import '../kernel/body_builder.dart' show BodyBuilder;

import '../kernel/kernel_builder.dart'
    show
        ClassBuilder,
        Declaration,
        KernelConstructorBuilder,
        KernelFieldBuilder,
        KernelLibraryBuilder,
        LibraryBuilder,
        MetadataBuilder,
        TypeBuilder;

import '../kernel/kernel_shadow_ast.dart' show VariableDeclarationJudgment;

/// A builder for a formal parameter, i.e. a parameter on a method or
/// constructor.
class FormalParameterBuilder extends ModifierBuilder {
  /// List of metadata builders for the metadata declared on this parameter.
  final List<MetadataBuilder> metadata;

  final int modifiers;

  final TypeBuilder type;

  final String name;

  /// The kind of this parameter, i.e. if it's required, positional optional,
  /// or named optional.
  FormalParameterKind kind = FormalParameterKind.mandatory;

  /// The variable declaration created for this formal parameter.
  VariableDeclaration declaration;

  /// The first token of the default value, if any.
  ///
  /// This is stored until outlines have been built through
  /// [buildOutlineExpressions].
  Token initializerToken;

  FormalParameterBuilder(this.metadata, this.modifiers, this.type, this.name,
      LibraryBuilder compilationUnit, int charOffset)
      : super(compilationUnit, charOffset);

  String get debugName => "FormalParameterBuilder";

  bool get isRequired => isMandatoryFormalParameterKind(kind);

  bool get isPositional {
    return isOptionalPositionalFormalParameterKind(kind) ||
        isMandatoryFormalParameterKind(kind);
  }

  bool get isNamed => isOptionalNamedFormalParameterKind(kind);

  bool get isOptional => !isRequired;

  bool get isLocal => true;

  @override
  String get fullNameForErrors => name;

  VariableDeclaration get target => declaration;

  VariableDeclaration build(
      KernelLibraryBuilder library, int functionNestingLevel) {
    if (declaration == null) {
      declaration = new VariableDeclarationJudgment(name, functionNestingLevel,
          type: type?.build(library),
          isFinal: isFinal,
          isConst: isConst,
          isFieldFormal: isInitializingFormal,
          isCovariant: isCovariant)
        ..fileOffset = charOffset;
    }
    return declaration;
  }

  FormalParameterBuilder clone(List<TypeBuilder> newTypes) {
    // TODO(dmitryas):  It's not clear how [metadata] is used currently, and
    // how it should be cloned.  Consider cloning it instead of reusing it.
    return new FormalParameterBuilder(
        metadata, modifiers, type?.clone(newTypes), name, parent, charOffset)
      ..kind = kind;
  }

  FormalParameterBuilder forFormalParameterInitializerScope() {
    assert(declaration != null);
    return !isInitializingFormal
        ? this
        : (new FormalParameterBuilder(
            metadata,
            modifiers | finalMask | initializingFormalMask,
            type,
            name,
            null,
            charOffset)
          ..parent = parent
          ..declaration = declaration);
  }

  void finalizeInitializingFormal() {
    Object cls = parent.parent;
    if (cls is ClassBuilder) {
      Declaration field = cls.scope.lookup(name, charOffset, fileUri);
      if (field is KernelFieldBuilder) {
        target.type = field.target.type;
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
    final bool isConstConstructorParameter =
        (parent is KernelConstructorBuilder && parent.target.isConst);
    if ((isConstConstructorParameter || parent.isInstanceMember) &&
        initializerToken != null) {
      final ClassBuilder classBuilder = parent.parent;
      Scope scope = classBuilder.scope;
      BodyBuilder bodyBuilder = new BodyBuilder.forOutlineExpression(
          library, classBuilder, this, scope, fileUri);
      bodyBuilder.constantContext = ConstantContext.required;
      target.initializer = bodyBuilder.parseFieldInitializer(initializerToken)
        ..parent = target;
      bodyBuilder.typeInferrer?.inferParameterInitializer(
          bodyBuilder, target.initializer, target.type);
      if (library.loader is SourceLoader) {
        SourceLoader loader = library.loader;
        loader.transformPostInference(target, bodyBuilder.transformSetLiterals,
            bodyBuilder.transformCollections);
      }
      bodyBuilder.resolveRedirectingFactoryTargets();
    }
    initializerToken = null;
  }
}
