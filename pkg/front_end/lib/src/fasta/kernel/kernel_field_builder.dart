// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.kernel_field_builder;

import 'package:kernel/ast.dart' show Expression, Field, Name;

import 'kernel_builder.dart'
    show
        Builder,
        FieldBuilder,
        KernelTypeBuilder,
        LibraryBuilder,
        MetadataBuilder;

class KernelFieldBuilder extends FieldBuilder<Expression> {
  final Field field;
  final List<MetadataBuilder> metadata;
  final KernelTypeBuilder type;

  KernelFieldBuilder(this.metadata, this.type, String name, int modifiers,
      Builder compilationUnit, int charOffset)
      : field = new Field(null, fileUri: compilationUnit?.relativeFileUri)
          ..fileOffset = charOffset,
        super(name, modifiers, compilationUnit, charOffset);

  void set initializer(Expression value) {
    field.initializer = value..parent = field;
  }

  Field build(LibraryBuilder library) {
    field.name ??= new Name(name, library.target);
    if (type != null) {
      field.type = type.build(library);
    }
    bool isInstanceMember = !isStatic && !isTopLevel;
    return field
      ..isFinal = isFinal
      ..isConst = isConst
      ..hasImplicitGetter = isInstanceMember
      ..hasImplicitSetter = isInstanceMember && !isConst && !isFinal
      ..isStatic = !isInstanceMember;
  }

  Field get target => field;
}
