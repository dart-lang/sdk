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

class KernelMixinApplicationBuilder
    extends MixinApplicationBuilder<KernelTypeBuilder>
    implements KernelTypeBuilder {
  Supertype builtType;

  KernelMixinApplicationBuilder(KernelTypeBuilder supertype,
      List<KernelTypeBuilder> mixins)
      : super(supertype, mixins);

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
          typeParameters: null); // TODO(ahe): Compute these.
      // TODO(ahe): Use asThisSupertype instead and translate type variables.
      supertype = application.asRawSupertype;
    }
    builtType = supertype;
    return builtType;
  }
}
