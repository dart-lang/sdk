// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.kernel_formal_parameter_builder;

import 'package:kernel/ast.dart' show DynamicType, VariableDeclaration;

import 'kernel_builder.dart'
    show
        FormalParameterBuilder,
        KernelLibraryBuilder,
        KernelTypeBuilder,
        LibraryBuilder,
        MetadataBuilder;

class KernelFormalParameterBuilder
    extends FormalParameterBuilder<KernelTypeBuilder> {
  VariableDeclaration declaration;
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

  VariableDeclaration build(LibraryBuilder library) {
    return declaration ??= new VariableDeclaration(name,
        type: type?.build(library) ?? const DynamicType(),
        isFinal: isFinal,
        isConst: isConst)..fileOffset = charOffset;
  }

  VariableDeclaration get target => declaration;
}
