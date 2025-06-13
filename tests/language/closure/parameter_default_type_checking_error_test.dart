// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// These tests verify that type checking is properly applied to default values
// of closure parameters.

// If the closure has an optional positional parameter with an explicit type:
//
// - The explicit parameter type will be used as the type inference context for
//   the default value of the closure parameter
void testPositionalExplicit() {
  var f = ([List<int> x = const ['foo']]) {};
  //                             ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] A value of type 'String' can't be assigned to a variable of type 'int'.
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
  void Function(List<int>) f = ([x = const ['foo']]) {};
  //                                        ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] A value of type 'String' can't be assigned to a variable of type 'int'.
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
  void Function([List<int>]) f = ([x = const ['foo']]) {};
  //                                          ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] A value of type 'String' can't be assigned to a variable of type 'int'.
}

// If the closure has an optional named parameter with an explicit type:
//
// - The explicit parameter type will be used as the type inference context for
//   the default value of the closure parameter
void testNamedExplicit() {
  var f = ({List<int> x = const ['foo']}) {};
  //                             ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] A value of type 'String' can't be assigned to a variable of type 'int'.
}

// If the closure has an optional named parameter with an implicit type, and the
// closure's context is a function type with a required named parameter:
//
// - The type of the closure's parameter will be inferred from the
//   corresponding required parameter in the context type
// - And that type in turn will be used as the type inference context for the
//   default value of the closure parameter.
void testNamedInferredFromRequired() {
  void Function({required List<int> x}) f = ({x = const ['foo']}) {};
  //                                                     ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] A value of type 'String' can't be assigned to a variable of type 'int'.
}

// If the closure has an optional named parameter with an implicit type, and the
// closure's context is a function type with an optional named parameter:
//
// - The type of the closure's parameter will be inferred from the
//   corresponding optional parameter in the context type
// - And that type in turn will be used as the type inference context for the
//   default value of the closure parameter.
void testNamedInferredFromOptional() {
  void Function({List<int> x}) f = ({x = const ['foo']}) {};
  //                                            ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] A value of type 'String' can't be assigned to a variable of type 'int'.
}

main() {}
