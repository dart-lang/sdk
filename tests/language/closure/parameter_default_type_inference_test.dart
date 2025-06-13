// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// These tests verify that the proper context type is applied to default values
// of closure parameters.

import 'package:expect/expect.dart';
import '../static_type_helper.dart';

// If the closure has an optional positional parameter with an explicit type:
//
// - The explicit parameter type will be used as the type inference context for
//   the default value of the closure parameter
void testPositionalExplicit() {
  var f = ([List<num> x = const []]) {
    x.expectStaticType<Exactly<List<num>>>();
    Expect.type<List<num>>(x);
    Expect.identical(x, const <num>[]);
  };
  f();
}

// If the closure has an optional positional parameter with an implicit type,
// and the closure's context is a function type with a required positional
// parameter:
//
// - The type of the closure's parameter will be inferred from the
//   corresponding required parameter in the context type
// - And that type in turn will be used as the type inference context for the
//   default value of the closure parameter.
void testPositionalInferredFromRequired() {
  void Function(List<int>) f = ([x = const []]) {
    x.expectStaticType<Exactly<List<int>>>();
    Expect.type<List<int>>(x);
    Expect.identical(x, const <int>[]);
  };
  (f as void Function([List<int>]))();
}

// If the closure has an optional positional parameter with an implicit type,
// and the closure's context is a function type with an optional positional
// parameter:
//
// - The type of the closure's parameter will be inferred from the
//   corresponding optional parameter in the context type
// - And that type in turn will be used as the type inference context for the
//   default value of the closure parameter.
void testPositionalInferredFromOptional() {
  void Function([List<int>]) f = ([x = const []]) {
    x.expectStaticType<Exactly<List<int>>>();
    Expect.type<List<int>>(x);
    Expect.identical(x, const <int>[]);
  };
  f();
}

// If the closure has an optional named parameter with an explicit type:
//
// - The explicit parameter type will be used as the type inference context for
//   the default value of the closure parameter
void testNamedExplicit() {
  var f = ({List<num> x = const []}) {
    x.expectStaticType<Exactly<List<num>>>();
    Expect.type<List<num>>(x);
    Expect.identical(x, const <num>[]);
  };
  f();
}

// If the closure has an optional named parameter with an implicit type, and the
// closure's context is a function type with a required named parameter:
//
// - The type of the closure's parameter will be inferred from the
//   corresponding required parameter in the context type
// - And that type in turn will be used as the type inference context for the
//   default value of the closure parameter.
void testNamedInferredFromRequired() {
  void Function({required List<int> x}) f = ({x = const []}) {
    x.expectStaticType<Exactly<List<int>>>();
    Expect.type<List<int>>(x);
    Expect.identical(x, const <int>[]);
  };
  (f as void Function({List<int> x}))();
}

// If the closure has an optional named parameter with an implicit type, and the
// closure's context is a function type with an optional named parameter:
//
// - The type of the closure's parameter will be inferred from the
//   corresponding optional parameter in the context type
// - And that type in turn will be used as the type inference context for the
//   default value of the closure parameter.
void testNamedInferredFromOptional() {
  void Function({List<int> x}) f = ({x = const []}) {
    x.expectStaticType<Exactly<List<int>>>();
    Expect.type<List<int>>(x);
    Expect.identical(x, const <int>[]);
  };
  f();
}

main() {
  testPositionalExplicit();
  testPositionalInferredFromRequired();
  testPositionalInferredFromOptional();
  testNamedExplicit();
  testNamedInferredFromRequired();
  testNamedInferredFromOptional();
}
