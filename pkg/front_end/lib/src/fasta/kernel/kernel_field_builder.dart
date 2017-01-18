// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.kernel_field_builder;

import 'package:kernel/ast.dart' show
    DynamicType,
    Expression,
    Field,
    Library,
    Name;

import 'kernel_builder.dart' show
    FieldBuilder,
    KernelTypeBuilder,
    MetadataBuilder;

class KernelFieldBuilder extends FieldBuilder<Expression> {
  Field field;
  final List<MetadataBuilder> metadata;
  final KernelTypeBuilder type;

  KernelFieldBuilder(this.metadata, this.type, String name, int modifiers)
      : super(name, modifiers);

  void set initializer(Expression value) {
    field.initializer = value
        ..parent = field;
  }

  Field build(Library library) {
    return field ??= new Field(new Name(name, library),
        type: type?.build() ?? const DynamicType(),
        isFinal: isFinal, isConst: isConst, isStatic: isStatic || isTopLevel);
  }

  Field get target => field;
}
