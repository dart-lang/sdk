// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.kernel_mixin_application_builder;

import 'package:kernel/ast.dart' show InterfaceType, Supertype;

import '../problems.dart' show unsupported;

import 'kernel_builder.dart'
    show
        KernelTypeBuilder,
        LibraryBuilder,
        MixinApplicationBuilder,
        TypeBuilder,
        TypeVariableBuilder;

class KernelMixinApplicationBuilder
    extends MixinApplicationBuilder<KernelTypeBuilder>
    implements KernelTypeBuilder {
  Supertype builtType;

  List<TypeVariableBuilder> typeVariables;

  KernelMixinApplicationBuilder(
      KernelTypeBuilder supertype, List<KernelTypeBuilder> mixins)
      : super(supertype, mixins);

  @override
  InterfaceType build(LibraryBuilder library) {
    int charOffset = -1; // TODO(ahe): Provide these.
    Uri fileUri = null; // TODO(ahe): Provide these.
    return unsupported("build", charOffset, fileUri);
  }

  @override
  Supertype buildSupertype(
      LibraryBuilder library, int charOffset, Uri fileUri) {
    return unsupported("buildSupertype", charOffset, fileUri);
  }

  @override
  Supertype buildMixedInType(
      LibraryBuilder library, int charOffset, Uri fileUri) {
    return unsupported("buildMixedInType", charOffset, fileUri);
  }

  @override
  buildInvalidType(int charOffset, Uri fileUri) {
    return unsupported("buildInvalidType", charOffset, fileUri);
  }

  KernelMixinApplicationBuilder clone(List<TypeBuilder> newTypes) {
    int charOffset = -1; // TODO(dmitryas): Provide these.
    Uri fileUri = null; // TODO(dmitryas): Provide these.
    return unsupported("clone", charOffset, fileUri);
  }
}
