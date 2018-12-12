// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.field_builder;

import 'builder.dart' show LibraryBuilder, MemberBuilder;

import 'package:kernel/ast.dart' show DartType;

abstract class FieldBuilder<T> extends MemberBuilder {
  final String name;

  final int modifiers;

  FieldBuilder(
      this.name, this.modifiers, LibraryBuilder compilationUnit, int charOffset)
      : super(compilationUnit, charOffset);

  String get debugName => "FieldBuilder";

  DartType get builtType;

  void set initializer(T value);

  bool get hasInitializer;

  bool get isField => true;

  bool get hasTypeInferredFromInitializer;
}
