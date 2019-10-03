// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.mixin_application_builder;

import 'builder.dart'
    show LibraryBuilder, NullabilityBuilder, TypeBuilder, TypeVariableBuilder;

import 'package:kernel/ast.dart' show InterfaceType, Supertype;

import '../fasta_codes.dart' show LocatedMessage;

import '../problems.dart' show unsupported;

class MixinApplicationBuilder extends TypeBuilder {
  final TypeBuilder supertype;
  final List<TypeBuilder> mixins;
  Supertype builtType;

  List<TypeVariableBuilder> typeVariables;

  MixinApplicationBuilder(this.supertype, this.mixins);

  String get name => null;

  NullabilityBuilder get nullabilityBuilder {
    return unsupported("nullabilityBuilder", -1, null);
  }

  String get debugName => "MixinApplicationBuilder";

  StringBuffer printOn(StringBuffer buffer) {
    buffer.write(supertype);
    buffer.write(" with ");
    bool first = true;
    for (TypeBuilder t in mixins) {
      if (!first) buffer.write(", ");
      first = false;
      t.printOn(buffer);
    }
    return buffer;
  }

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
  buildInvalidType(LocatedMessage message, {List<LocatedMessage> context}) {
    return unsupported("buildInvalidType", message.charOffset, message.uri);
  }

  @override
  MixinApplicationBuilder withNullabilityBuilder(
      NullabilityBuilder nullabilityBuilder) {
    return unsupported("withNullabilityBuilder", -1, null);
  }

  MixinApplicationBuilder clone(List<TypeBuilder> newTypes) {
    int charOffset = -1; // TODO(dmitryas): Provide these.
    Uri fileUri = null; // TODO(dmitryas): Provide these.
    return unsupported("clone", charOffset, fileUri);
  }
}
