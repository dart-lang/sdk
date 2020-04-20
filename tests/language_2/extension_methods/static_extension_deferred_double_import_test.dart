// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

import "helpers/on_object.dart";
import "helpers/on_object.dart" deferred as p1 hide OnObject;

// Allow explicit and implicit access to non-deferred import extensions.

void main() async {
  Object o = 1;
  Expect.equals("object", OnObject(o).onObject);
  Expect.equals("object", o.onObject);
}
