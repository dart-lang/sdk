// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.kernel_mixin_application_builder;

import 'package:kernel/ast.dart' show InterfaceType, Supertype;

import '../deprecated_problems.dart' show deprecated_internalProblem;

import '../util/relativize.dart' show relativizeUri;

import 'kernel_builder.dart'
    show
        KernelLibraryBuilder,
        KernelTypeBuilder,
        LibraryBuilder,
        MixinApplicationBuilder,
        TypeVariableBuilder;

class KernelMixinApplicationBuilder
    extends MixinApplicationBuilder<KernelTypeBuilder>
    implements KernelTypeBuilder {
  final int charOffset;

  final String relativeFileUri;

  final KernelLibraryBuilder library;

  Supertype builtType;

  List<TypeVariableBuilder> typeVariables;

  String subclassName;

  KernelMixinApplicationBuilder(KernelTypeBuilder supertype,
      List<KernelTypeBuilder> mixins, this.library, int charOffset, Uri fileUri)
      : charOffset = charOffset,
        relativeFileUri = relativizeUri(fileUri),
        super(supertype, mixins, charOffset, fileUri);

  InterfaceType build(LibraryBuilder library) {
    return deprecated_internalProblem("Unsupported operation.");
  }

  Supertype buildSupertype(LibraryBuilder library) {
    return deprecated_internalProblem("Unsupported operation.");
  }
}
