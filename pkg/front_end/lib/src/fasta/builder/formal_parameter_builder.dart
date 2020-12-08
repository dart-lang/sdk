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
import 'package:front_end/src/fasta/builder/procedure_builder.dart';

import 'package:kernel/ast.dart'
    show DynamicType, Expression, VariableDeclaration;

import '../constant_context.dart' show ConstantContext;

import '../modifier.dart';

import '../scope.dart' show Scope;

import '../source/source_library_builder.dart' show SourceLibraryBuilder;

import '../source/source_loader.dart' show SourceLoader;

import '../kernel/body_builder.dart' show BodyBuilder;

import '../kernel/internal_ast.dart' show VariableDeclarationImpl;

import 'builder.dart';
import 'class_builder.dart';
import 'constructor_builder.dart';
import 'field_builder.dart';
import 'library_builder.dart';
import 'metadata_builder.dart';
import 'modifier_builder.dart';
import 'type_builder.dart';
import 'variable_builder.dart';

/// A builder for a formal parameter, i.e. a parameter on a method or
/// constructor.
class FormalParameterBuilder extends ModifierBuilderImpl
    implements VariableBuilder {
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

  bool initializerWasInferred = false;

  /// True if the initializer was declared by the programmer.
  bool hasDeclaredInitializer = false;

  final bool isExtensionThis;

  FormalParameterBuilder(this.metadata, this.modifiers, this.type, this.name,
      LibraryBuilder compilationUnit, int charOffset,
      {Uri fileUri, this.isExtensionThis: false})
      : super(compilationUnit, charOffset, fileUri);

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

  bool get isLocal => true;

  bool get isInitializingFormal => (modifiers & initializingFormalMask) != 0;

  bool get isCovariant => (modifiers & covariantMask) != 0;

  // An initializing formal parameter might be final without its
  // VariableDeclaration being final. See
  // [ProcedureBuilder.computeFormalParameterInitializerScope]..
  bool get isAssignable => variable.isAssignable && !isInitializingFormal;

  @override
  String get fullNameForErrors => name;

  VariableDeclaration build(
      SourceLibraryBuilder library, int functionNestingLevel,
      [bool notInstanceContext]) {
    if (variable == null) {
      variable = new VariableDeclarationImpl(name, functionNestingLevel,
          type: type?.build(library, null, notInstanceContext),
          isFinal: isFinal,
          isConst: isConst,
          isFieldFormal: isInitializingFormal,
          isCovariant: isCovariant,
          isRequired: isNamedRequired,
          hasDeclaredInitializer: hasDeclaredInitializer,
          isLowered: isExtensionThis)
        ..fileOffset = charOffset;
    }
    return variable;
  }

  FormalParameterBuilder clone(List<TypeBuilder> newTypes) {
    // TODO(dmitryas):  It's not clear how [metadata] is used currently, and
    // how it should be cloned.  Consider cloning it instead of reusing it.
    return new FormalParameterBuilder(
        metadata, modifiers, type?.clone(newTypes), name, parent, charOffset,
        fileUri: fileUri, isExtensionThis: isExtensionThis)
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
            fileUri: fileUri,
            isExtensionThis: isExtensionThis)
          ..parent = parent
          ..variable = variable);
  }

  void finalizeInitializingFormal(ClassBuilder classBuilder) {
    assert(variable.type == null);
    Builder fieldBuilder = classBuilder.lookupLocalMember(name);
    if (fieldBuilder is FieldBuilder) {
      variable.type = fieldBuilder.inferType();
    } else {
      variable.type = const DynamicType();
    }
  }

  /// Builds the default value from this [initializerToken] if this is a
  /// formal parameter on a const constructor or instance method.
  void buildOutlineExpressions(LibraryBuilder library) {
    if (initializerToken != null) {
      // For modular compilation we need to include initializers for optional
      // and named parameters of const constructors into the outline - to enable
      // constant evaluation. Similarly we need to include initializers for
      // optional and named parameters of instance methods because these might
      // be needed to generated noSuchMethod forwarders.
      bool isConstConstructorParameter = false;
      if (parent is ConstructorBuilder) {
        isConstConstructorParameter = parent.isConst;
      } else if (parent is ProcedureBuilder) {
        isConstConstructorParameter = parent.isFactory && parent.isConst;
      }
      if (isConstConstructorParameter || parent.isClassInstanceMember) {
        final ClassBuilder classBuilder = parent.parent;
        Scope scope = classBuilder.scope;
        BodyBuilder bodyBuilder = library.loader
            .createBodyBuilderForOutlineExpression(
                library, classBuilder, this, scope, fileUri);
        bodyBuilder.constantContext = ConstantContext.required;
        assert(!initializerWasInferred);
        Expression initializer =
            bodyBuilder.parseFieldInitializer(initializerToken);
        initializer = bodyBuilder.typeInferrer?.inferParameterInitializer(
            bodyBuilder, initializer, variable.type, hasDeclaredInitializer);
        variable.initializer = initializer..parent = variable;
        if (library.loader is SourceLoader) {
          SourceLoader loader = library.loader;
          loader.transformPostInference(
              variable,
              bodyBuilder.transformSetLiterals,
              bodyBuilder.transformCollections,
              library.library);
        }
        initializerWasInferred = true;
        bodyBuilder.resolveRedirectingFactoryTargets();
      }
    }
    initializerToken = null;
  }
}
