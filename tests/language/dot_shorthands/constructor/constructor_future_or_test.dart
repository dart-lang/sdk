// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// `FutureOr<S>` denotes the same namespace as `S` for dot shorthands on
// constructors.

import 'dart:async';

import '../dot_shorthand_helper.dart';

class ConstructorClassFutureOrContext {
  final FutureOr<ConstructorClass> ctor;
  final FutureOr<ConstructorClass?> nullableCtor;
  ConstructorClassFutureOrContext(this.ctor, this.nullableCtor);
  ConstructorClassFutureOrContext.named({this.ctor = const .constRegular(1), this.nullableCtor});
  ConstructorClassFutureOrContext.optional([this.ctor = const .constNamed(x: 1), this.nullableCtor]);
}

class ConstructorExtFutureOrContext {
  final FutureOr<ConstructorExt> ctorExt;
  final FutureOr<ConstructorExt?> nullableCtorExt;
  ConstructorExtFutureOrContext(this.ctorExt, this.nullableCtorExt);
  ConstructorExtFutureOrContext.named({this.ctorExt = const .constRegular(1), this.nullableCtorExt});
  ConstructorExtFutureOrContext.optional([this.ctorExt = const .constRegular(1), this.nullableCtorExt]);
}

void main() {
  // Class
  FutureOr<ConstructorClass> ctor = .new(1);
  FutureOr<ConstructorClass> ctorNamed = .named(x: 1);
  FutureOr<ConstructorClass> ctorOptional = .optional(1);
  FutureOr<ConstructorClass?> nullableCtor = .regular(1);
  FutureOr<ConstructorClass?> nullableCtorNamed = .named(x: 1);
  FutureOr<ConstructorClass?> nullableCtorOptional = .optional(1);
  const FutureOr<ConstructorClass> constCtor = .constRegular(1);
  const FutureOr<ConstructorClass> constCtorNamed = .constNamed(x: 1);
  const FutureOr<ConstructorClass> constCtorOptional = .constOptional(1);
  const FutureOr<ConstructorClass?> constNullableCtor = .constRegular(1);
  const FutureOr<ConstructorClass?> constNullableCtorNamed = .constNamed(x: 1);
  const FutureOr<ConstructorClass?> constNullableCtorOptional = .constOptional(1);
  FutureOr<FutureOr<ConstructorClass>> ctorNested = .new(1);
  const FutureOr<FutureOr<ConstructorClass>> constCtorNested = .constRegular(1);

  var ctorList = <FutureOr<ConstructorClass>>[.new(1), .regular(1), .optional(1), .named(x: 1)];
  var nullableCtorList = <FutureOr<ConstructorClass?>>[.new(1), .regular(1), .optional(1), .named(x: 1)];

  var ctorContextPositional = ConstructorClassFutureOrContext(.new(1), .regular(1));
  var ctorContextPositional2 = ConstructorClassFutureOrContext(.optional(1), .named(x: 1));
  var ctorContextNamed = ConstructorClassFutureOrContext.named(ctor: .new(1), nullableCtor: .regular(1));
  var ctorContextNamed2 = ConstructorClassFutureOrContext.named(ctor: .optional(1), nullableCtor: .named(x: 1));
  var ctorContextOptional = ConstructorClassFutureOrContext.optional(.new(1), .regular(1));
  var ctorContextOptional2 = ConstructorClassFutureOrContext.optional(.optional(1), .named(x: 1));

  // Extension type
  FutureOr<ConstructorExt> ctorExt = .new(1);
  FutureOr<ConstructorExt> ctorExtNamed = .named(x: 1);
  FutureOr<ConstructorExt> ctorExtOptional = .optional(1);
  FutureOr<ConstructorExt?> nullableCtorExt =  .regular(1);
  FutureOr<ConstructorExt?> nullableCtorExtNamed = .named(x: 1);
  FutureOr<ConstructorExt?> nullableCtorExtOptional = .optional(1);
  const FutureOr<ConstructorExt> constCtorExt = .constRegular(1);
  const FutureOr<ConstructorExt> constCtorExtNamed = .constNamed(x: 1);
  const FutureOr<ConstructorExt> constCtorExtOptional = .constOptional(1);
  const FutureOr<ConstructorExt?> constNullableCtorExt = .constRegular(1);
  const FutureOr<ConstructorExt?> constNullableCtorExtNamed = .constNamed(x: 1);
  const FutureOr<ConstructorExt?> constNullableCtorExtOptional = .constOptional(1);
  FutureOr<FutureOr<ConstructorExt>> ctorExtNested = .new(1);
  const FutureOr<FutureOr<ConstructorExt>> constCtorExtNested = .constRegular(1);

  var ctorExtList = <FutureOr<ConstructorExt>>[.new(1), .regular(1), .optional(1), .named(x: 1)];
  var nullableIntegerExtList = <FutureOr<ConstructorExt?>>[.new(1), .regular(1), .optional(1), .named(x: 1)];

  var ctorExtContextPositional = ConstructorExtFutureOrContext(.new(1), .regular(1));
  var ctorExtContextPositional2 = ConstructorExtFutureOrContext(.optional(1), .named(x: 1));
  var ctorExtContextNamed = ConstructorExtFutureOrContext.named(ctorExt: .new(1), nullableCtorExt: .regular(1));
  var ctorExtContextNamed2 = ConstructorExtFutureOrContext.named(ctorExt: .optional(1), nullableCtorExt: .named(x: 1));
  var ctorExtContextOptional = ConstructorExtFutureOrContext.optional(.new(1), .regular(1));
  var ctorExtContextOptional2 = ConstructorExtFutureOrContext.optional(.optional(1), .named(x: 1));
}

