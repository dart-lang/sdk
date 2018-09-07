// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.kernel_type_builder;

import 'package:kernel/ast.dart' show DartType, Library, Supertype;

import '../messages.dart' show LocatedMessage;

import '../problems.dart' show unhandled;

import 'kernel_builder.dart'
    show
        KernelInvalidTypeBuilder,
        KernelTypeBuilder,
        LibraryBuilder,
        TypeBuilder;

class KernelPrebuiltTypeBuilder extends KernelTypeBuilder {
  @override
  final String name;

  final DartType type;

  const KernelPrebuiltTypeBuilder(this.name, this.type);

  @override
  String get debugName => "KernelPrebuiltTypeBuilder";

  @override
  DartType build(LibraryBuilder<TypeBuilder, Object> library) => type;

  @override
  Supertype buildSupertype(LibraryBuilder<KernelTypeBuilder, Library> library,
      int charOffset, Uri fileUri) {
    return unhandled(
        "buildSupertype", "KernelPrebuiltTypeBuilder", charOffset, fileUri);
  }

  @override
  Supertype buildMixedInType(LibraryBuilder<KernelTypeBuilder, Library> library,
      int charOffset, Uri fileUri) {
    return unhandled(
        "buildMixedInType", "KernelPrebuiltTypeBuilder", charOffset, fileUri);
  }

  @override
  KernelInvalidTypeBuilder buildInvalidType(LocatedMessage message) {
    // TODO(ahe): Pass [charOffset] and [fileUri] as parameters instead.
    int charOffset = -1;
    Uri fileUri = null;
    return unhandled(
        "buildInvalidType", "KernelPrebuiltTypeBuilder", charOffset, fileUri);
  }

  @override
  StringBuffer printOn(StringBuffer buffer) {
    buffer.write(type);
    return buffer;
  }

  @override
  TypeBuilder clone(List<TypeBuilder> newTypes) => this;
}
