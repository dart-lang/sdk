// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check that compile-time evaluation of constants is consistent with runtime
// evaluation.

import 'dart:mirrors';

import 'package:expect/expect.dart';

const top_const = identical(-0.0, 0);
final top_final = identical(-0.0, 0);
var top_var = identical(-0.0, 0);

@top_const
class C {
  static const static_const = identical(-0.0, 0);
  static final static_final = identical(-0.0, 0);
  static var static_var = identical(-0.0, 0);

  final instance_final = identical(-0.0, 0);
  var instance_var = identical(-0.0, 0);

  void test() {
    const local_const = identical(-0.0, 0);
    final local_final = identical(-0.0, 0);
    var local_var = identical(-0.0, 0);

    Expect.equals(identical(-0.0, 0), top_const);
    Expect.equals(top_const, top_final);
    Expect.equals(top_final, top_var);
    Expect.equals(top_var, static_const);
    Expect.equals(static_const, static_final);
    Expect.equals(static_final, static_var);
    Expect.equals(static_var, instance_final);
    Expect.equals(instance_final, instance_var);
    Expect.equals(instance_var, local_const);
    Expect.equals(local_const, local_final);
    Expect.equals(local_final, local_var);
    var metadata = reflectClass(C).metadata[0].reflectee; //# 01: ok
    Expect.equals(top_const, metadata); //                //# 01: continued
    Expect.equals(local_var, metadata); //                //# 01: continued
  }
}

void main() {
  new C().test();
}
