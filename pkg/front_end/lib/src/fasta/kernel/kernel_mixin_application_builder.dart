// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.kernel_mixin_application_builder;

import 'package:kernel/ast.dart' show
    Class,
    InterfaceType,
    Supertype;

import 'kernel_builder.dart' show
    KernelTypeBuilder,
    MixinApplicationBuilder;

import '../util/relativize.dart' show
    relativizeUri;

class KernelMixinApplicationBuilder
    extends MixinApplicationBuilder<KernelTypeBuilder>
    implements KernelTypeBuilder {
  final int charOffset;

  final String relativeFileUri;

  Supertype builtType;

  KernelMixinApplicationBuilder(KernelTypeBuilder supertype,
      List<KernelTypeBuilder> mixins, int charOffset, Uri fileUri)
      : charOffset = charOffset,
        relativeFileUri = relativizeUri(fileUri),
        super(supertype, mixins, charOffset, fileUri);

  InterfaceType build() => buildSupertype().asInterfaceType;

  Supertype buildSupertype() {
    if (builtType != null) return builtType;
    Supertype supertype =
        this.supertype.buildSupertype()?.classNode?.asRawSupertype;
    if (supertype == null) {
      return null;
    }
    for (KernelTypeBuilder builder in mixins) {
      Supertype mixin = builder.buildSupertype()?.classNode?.asRawSupertype;
      if (mixin == null) {
        return null;
      }
      Class application = new Class(
          name: "${supertype.classNode.name}&${mixin.classNode.name}",
          isAbstract: true,
          supertype: supertype,
          mixedInType: mixin,
          typeParameters: null, // TODO(ahe): Compute these.
          fileUri: relativeFileUri);
      application.fileOffset = charOffset;
      // TODO(ahe): Use asThisSupertype instead and translate type variables.
      supertype = application.asRawSupertype;
    }
    builtType = supertype;
    return builtType;
  }
}
