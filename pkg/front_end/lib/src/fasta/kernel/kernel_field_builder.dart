// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.kernel_field_builder;

import 'package:kernel/ast.dart'
    show DartType, DynamicType, Expression, Field, Name, NullLiteral;

import '../../base/instrumentation.dart'
    show Instrumentation, InstrumentationValueForType;

import '../fasta_codes.dart' show messageInternalProblemAlreadyInitialized;

import '../problems.dart' show internalProblem, unsupported;

import 'kernel_body_builder.dart' show KernelBodyBuilder;

import 'kernel_builder.dart'
    show
        Declaration,
        ImplicitType,
        FieldBuilder,
        KernelLibraryBuilder,
        KernelTypeBuilder,
        MetadataBuilder;

import 'kernel_shadow_ast.dart' show ShadowField;

class KernelFieldBuilder extends FieldBuilder<Expression> {
  final ShadowField field;
  final List<MetadataBuilder> metadata;
  final KernelTypeBuilder type;

  KernelFieldBuilder(this.metadata, this.type, String name, int modifiers,
      Declaration compilationUnit, int charOffset, int charEndOffset)
      : field = new ShadowField(null, type == null,
            fileUri: compilationUnit?.fileUri)
          ..fileOffset = charOffset
          ..fileEndOffset = charEndOffset,
        super(name, modifiers, compilationUnit, charOffset);

  void set initializer(Expression value) {
    if (!hasInitializer && value is! NullLiteral && !isConst && !isFinal) {
      internalProblem(
          messageInternalProblemAlreadyInitialized, charOffset, fileUri);
    }
    field.initializer = value..parent = field;
  }

  bool get isEligibleForInference {
    return !library.legacyMode &&
        type == null &&
        (hasInitializer || isInstanceMember);
  }

  Field build(KernelLibraryBuilder library) {
    field.name ??= new Name(name, library.target);
    if (type != null) {
      field.type = type.build(library);
    }
    bool isInstanceMember = !isStatic && !isTopLevel;
    field
      ..isCovariant = isCovariant
      ..isFinal = isFinal
      ..isConst = isConst
      ..hasImplicitGetter = isInstanceMember
      ..hasImplicitSetter = isInstanceMember && !isConst && !isFinal
      ..isStatic = !isInstanceMember;
    if (isEligibleForInference && !isInstanceMember) {
      library.loader.typeInferenceEngine
          .recordStaticFieldInferenceCandidate(field, library);
    }
    return field;
  }

  Field get target => field;

  void prepareTopLevelInference() {
    if (!isEligibleForInference) return;
    KernelLibraryBuilder library = this.library;
    var typeInferrer = library.loader.typeInferenceEngine
        .createTopLevelTypeInferrer(
            field.enclosingClass?.thisType, field, null);
    if (hasInitializer) {
      if (field.type is! ImplicitType) {
        unsupported(
            "$name has unexpected type ${field.type}", charOffset, fileUri);
        return;
      }
      ImplicitType type = field.type;
      field.type = const DynamicType();
      initializer = new KernelBodyBuilder.forField(this, typeInferrer)
          .parseFieldInitializer(type.initializerToken);
    }
  }

  @override
  void instrumentTopLevelInference(Instrumentation instrumentation) {
    if (isEligibleForInference) {
      instrumentation.record(field.fileUri, field.fileOffset, 'topType',
          new InstrumentationValueForType(field.type));
    }
  }

  @override
  DartType get builtType => field.type;
}
