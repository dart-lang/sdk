// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.kernel_formal_parameter_builder;

import 'package:front_end/src/fasta/kernel/kernel_shadow_ast.dart'
    show KernelVariableDeclaration;

import '../modifier.dart' show finalMask;

import 'kernel_builder.dart'
    show
        FormalParameterBuilder,
        KernelLibraryBuilder,
        KernelTypeBuilder,
        MetadataBuilder;

import 'package:front_end/src/fasta/source/source_library_builder.dart'
    show SourceLibraryBuilder;

class KernelFormalParameterBuilder
    extends FormalParameterBuilder<KernelTypeBuilder> {
  KernelVariableDeclaration declaration;
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

  KernelVariableDeclaration get target => declaration;

  KernelVariableDeclaration build(SourceLibraryBuilder library) {
    if (declaration == null) {
      declaration = new KernelVariableDeclaration(name, 0,
          type: type?.build(library),
          isFinal: isFinal,
          isConst: isConst,
          isFieldFormal: hasThis)
        ..fileOffset = charOffset;
      if (type == null && hasThis) {
        library.loader.typeInferenceEngine
            .recordInitializingFormal(declaration);
      }
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
