// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check that compile-time evaluation of constants is consistent with runtime
// evaluation.

import 'dart:mirrors';
import 'package:expect/expect.dart';

const top_const = identical(-0.0, 0);

@top_const
class C {}

void main() {
  var local_var = identical(-0.0, 0);
  var metadata = reflectClass(C).metadata[0].reflectee;
  Expect.equals(top_const, metadata);
  Expect.equals(local_var, metadata);
}
