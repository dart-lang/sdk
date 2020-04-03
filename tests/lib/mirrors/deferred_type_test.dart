// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library deferred_type;

import 'dart:mirrors';
import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';

import 'deferred_type_other.dart' deferred as other;

bad(other.DeferredType x) {}

main() {
  print((reflect(bad) as ClosureMirror).function.parameters[0].type);
  throw "Should have died sooner. other.DeferredType is not loaded";
}
