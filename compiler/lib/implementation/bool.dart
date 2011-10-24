// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Adds Dart-methods to the prototype of the JS Boolean function.
// TODO(floitsch): the following comment needs to be updated once we compile
// boolean checks with '=== true'.
// WARNING: 'this' inside this class is always treated as 'true'.
// That is if (this) ... will always pick the 'then' branch.
// The reason is that, once compiled to JS, 'this' is represented by a
// JS Boolean object. However "if (new Boolean(false)) .." picks the then
// branch.
class BoolImplementation implements bool native "Boolean" {
  bool operator ==(other) native;

  // TODO(floitsch): we should intercept toString for primitives, to avoid
  // creating a wrapper object.
  String toString() native;

  BoolImplementation toBool() native;

  get dynamic() { return toBool(); }
}
