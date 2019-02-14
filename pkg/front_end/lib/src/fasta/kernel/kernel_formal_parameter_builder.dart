// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.kernel_formal_parameter_builder;

import 'package:kernel/ast.dart' show VariableDeclaration;

import '../modifier.dart' show finalMask, initializingFormalMask;

import 'kernel_builder.dart'
    show
        ClassBuilder,
        Declaration,
        FormalParameterBuilder,
        KernelFieldBuilder,
        KernelLibraryBuilder,
        KernelTypeBuilder,
        MetadataBuilder,
        TypeBuilder;

import 'kernel_shadow_ast.dart' show VariableDeclarationJudgment;

class KernelFormalParameterBuilder
    extends FormalParameterBuilder<KernelTypeBuilder> {
  VariableDeclaration declaration;

  KernelFormalParameterBuilder(
      List<MetadataBuilder> metadata,
      int modifiers,
      KernelTypeBuilder type,
      String name,
      KernelLibraryBuilder compilationUnit,
      int charOffset)
      : super(metadata, modifiers, type, name, compilationUnit, charOffset);

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

  KernelFormalParameterBuilder clone(List<TypeBuilder> newTypes) {
    // TODO(dmitryas):  It's not clear how [metadata] is used currently, and
    // how it should be cloned.  Consider cloning it instead of reusing it.
    return new KernelFormalParameterBuilder(
        metadata, modifiers, type?.clone(newTypes), name, parent, charOffset)
      ..kind = kind;
  }

  @override
  FormalParameterBuilder forFormalParameterInitializerScope() {
    assert(declaration != null);
    return !isInitializingFormal
        ? this
        : (new KernelFormalParameterBuilder(
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
}
