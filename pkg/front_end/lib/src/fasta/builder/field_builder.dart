// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.field_builder;

import 'builder.dart' show
    MemberBuilder;

abstract class FieldBuilder<T> extends MemberBuilder {
  final String name;

  final int modifiers;

  FieldBuilder(this.name, this.modifiers);

  void set initializer(T value);

  bool get isField => true;
}
