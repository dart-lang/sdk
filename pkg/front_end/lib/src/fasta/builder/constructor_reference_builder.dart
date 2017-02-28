// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.constructor_reference_builder;

import 'builder.dart' show PrefixBuilder, ClassBuilder, Builder, TypeBuilder;

import '../messages.dart' show warning;

import 'scope.dart' show Scope;

class ConstructorReferenceBuilder extends Builder {
  final String name;

  final List<TypeBuilder> typeArguments;

  /// This is the name of a named constructor. As `bar` in `new Foo<T>.bar()`.
  final String suffix;

  Builder target;

  ConstructorReferenceBuilder(this.name, this.typeArguments, this.suffix,
      Builder parent, int charOffset)
      : super(parent, charOffset, parent.fileUri);

  String get fullNameForErrors => "$name${suffix == null ? '' : '.$suffix'}";

  void resolveIn(Scope scope) {
    int index = name.indexOf(".");
    Builder builder;
    if (index == -1) {
      builder = scope.lookup(name, charOffset, fileUri);
    } else {
      String prefix = name.substring(0, index);
      String middle = name.substring(index + 1);
      builder = scope.lookup(prefix, charOffset, fileUri);
      if (builder is PrefixBuilder) {
        PrefixBuilder prefix = builder;
        builder = prefix.exports[middle];
      } else if (builder is ClassBuilder) {
        ClassBuilder cls = builder;
        builder = cls.constructors[middle];
        if (suffix == null) {
          target = builder;
          return;
        }
      }
    }
    if (builder is ClassBuilder) {
      target = builder.constructors[suffix ?? ""];
    }
    if (target == null) {
      warning(null, -1, "Couldn't find constructor '$fullNameForErrors'.");
    }
  }
}
