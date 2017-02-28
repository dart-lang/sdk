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
        MetadataBuilder;

class KernelFormalParameterBuilder
    extends FormalParameterBuilder<KernelTypeBuilder> {
  VariableDeclaration declaration;

  KernelFormalParameterBuilder(
      List<MetadataBuilder> metadata,
      int modifiers,
      KernelTypeBuilder type,
      String name,
      bool hasThis,
      KernelLibraryBuilder compilationUnit,
      int charOffset)
      : super(metadata, modifiers, type, name, hasThis, compilationUnit,
            charOffset);

  VariableDeclaration build() {
    return declaration ??= new VariableDeclaration(name,
        type: type?.build() ?? const DynamicType(),
        isFinal: isFinal,
        isConst: isConst);
  }

  VariableDeclaration get target => declaration;
}
