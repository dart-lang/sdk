// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Testing shorthands for constructor calls.

// SharedOptions=--enable-experiment=enum-shorthands

import '../enum_shorthand_helper.dart';

class ConstructorClassContext {
  final ConstructorClass? x;
  ConstructorClassContext(this.x);
  ConstructorClassContext.named({this.x});
  ConstructorClassContext.optional([this.x]);
}

class ConstructorExtContext {
  final ConstructorExt? x;
  ConstructorExtContext(this.x);
  ConstructorExtContext.named({this.x});
  ConstructorExtContext.optional([this.x]);
}

void main() {
  int x = 1;

  ConstructorClass ctor = .new(x);
  ConstructorClass ctor1 = .regular(x);
  ConstructorClass ctor2 = .named(x: x);
  ConstructorClass ctor3 = .optional(x);
  ConstructorClass ctor4 = .constRegular(x);
  ConstructorClass ctor5 = .constNamed(x: x);
  ConstructorClass ctor6 = .constOptional(x);

  ConstructorExt ctorExt = .new(x);
  ConstructorExt ctorExt1 = .regular(x);
  ConstructorExt ctorExt2 = .named(x: x);
  ConstructorExt ctorExt3 = .optional(x);
  ConstructorExt ctorExt4 = .constRegular(x);
  ConstructorExt ctorExt5 = .constNamed(x: x);
  ConstructorExt ctorExt6 = .constOptional(x);

  ConstructorClass? ctorNullable = .new(x);
  ConstructorClass? ctorNullable1 = .regular(x);
  ConstructorClass? ctorNullable2 = .named(x: x);
  ConstructorClass? ctorNullable3 = .optional(x);
  ConstructorClass? ctorNullable4 = .constRegular(x);
  ConstructorClass? ctorNullable5 = .constNamed(x: x);
  ConstructorClass? ctorNullable6 = .constOptional(x);

  ConstructorExt? ctorExtNullable = .new(x);
  ConstructorExt? ctorExtNullable1 = .regular(x);
  ConstructorExt? ctorExtNullable2= .named(x: x);
  ConstructorExt? ctorExtNullable3 = .optional(x);
  ConstructorExt? ctorExtNullable4 = .constRegular(x);
  ConstructorExt? ctorExtNullable5 = .constNamed(x: x);
  ConstructorExt? ctorExtNullable6 = .constOptional(x);

  UnnamedConstructor Function() ctorTearoff = .new;

  // Parameter context type.
  ConstructorClassContext(.new(1));
  ConstructorClassContext.named(x: .optional(1));
  ConstructorClassContext.optional(.optional(1));

  ConstructorExtContext(.new(1));
  ConstructorExtContext.named(x: .optional(1));
  ConstructorExtContext.optional(.optional(1));

  // Collection
  <ConstructorClass>[.new(x), .regular(x), .constRegular(x)];
  <ConstructorClass?>[.new(x), .regular(x), .constRegular(x)];
  <ConstructorExt>[.new(x), .regular(x), .constRegular(x)];
  <ConstructorExt?>[.new(x), .regular(x), .constRegular(x)];
}

