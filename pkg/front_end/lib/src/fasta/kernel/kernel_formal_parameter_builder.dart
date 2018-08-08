// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.kernel_formal_parameter_builder;

import 'kernel_shadow_ast.dart' show VariableDeclarationJudgment;

import '../modifier.dart' show finalMask;

import 'kernel_builder.dart'
    show
        FormalParameterBuilder,
        KernelLibraryBuilder,
        KernelTypeBuilder,
        MetadataBuilder;

import '../source/source_library_builder.dart' show SourceLibraryBuilder;

class KernelFormalParameterBuilder
    extends FormalParameterBuilder<KernelTypeBuilder> {
  VariableDeclarationJudgment declaration;
  final int charOffset;

  KernelFormalParameterBuilder(
      List<MetadataBuilder> metadata,
      int modifiers,
      KernelTypeBuilder type,
      String name,
      bool hasThis,
      KernelLibraryBuilder compilationUnit,
      this.charOffset)
      : super(metadata, modifiers, type, name, hasThis, compilationUnit,
            charOffset);

  @override
  bool get hasTarget => true;

  VariableDeclarationJudgment get target => declaration;

  VariableDeclarationJudgment build(SourceLibraryBuilder library) {
    if (declaration == null) {
      declaration = new VariableDeclarationJudgment(name, 0,
          type: type?.build(library),
          isFinal: isFinal,
          isConst: isConst,
          isFieldFormal: hasThis,
          isCovariant: isCovariant)
        ..fileOffset = charOffset;
    }
    return declaration;
  }

  @override
  FormalParameterBuilder forFormalParameterInitializerScope() {
    assert(declaration != null);
    return !hasThis
        ? this
        : (new KernelFormalParameterBuilder(metadata, modifiers | finalMask,
            type, name, hasThis, parent, charOffset)
          ..declaration = declaration);
  }
}
