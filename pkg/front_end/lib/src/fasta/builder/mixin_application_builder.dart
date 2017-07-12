// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.mixin_application_builder;

import '../problems.dart' show unsupported;

import 'builder.dart'
    show Scope, TypeBuilder, TypeDeclarationBuilder, TypeVariableBuilder;

abstract class MixinApplicationBuilder<T extends TypeBuilder>
    extends TypeBuilder {
  final T supertype;
  final List<T> mixins;

  MixinApplicationBuilder(
      this.supertype, this.mixins, int charOffset, Uri fileUri)
      : super(charOffset, fileUri);

  void set typeVariables(List<TypeVariableBuilder> variables);

  /// If this mixin application uses type variables, it needs a unique name
  /// based on its subclass. If this name is provided, the name will be
  /// `name^mixin`, otherwise it'll be `superclass&mixin`.
  //
  // TODO(ahe): This is to reduce diff against dartk. Consider if this is
  // necessary.
  void set subclassName(String value);

  String get name => null;

  void resolveIn(Scope scope) {
    supertype.resolveIn(scope);
    for (T t in mixins) {
      t.resolveIn(scope);
    }
  }

  void bind(TypeDeclarationBuilder builder) {
    unsupported("bind", -1, null);
  }

  String get debugName => "MixinApplicationBuilder";

  StringBuffer printOn(StringBuffer buffer) {
    buffer.write(supertype);
    buffer.write(" with ");
    bool first = true;
    for (T t in mixins) {
      if (!first) buffer.write(", ");
      first = false;
      t.printOn(buffer);
    }
    return buffer;
  }
}
