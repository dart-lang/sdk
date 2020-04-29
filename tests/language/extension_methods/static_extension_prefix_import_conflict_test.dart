// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

import "helpers/on_object.dart";
import "helpers/also_on_object.dart" as p2;

void main() {
  Object o = 1;
  o.onObject;
  //^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.AMBIGUOUS_EXTENSION_MEMBER_ACCESS
  // [cfe] The property 'onObject' is defined in multiple extensions for 'Object' and neither is more specific.
}
