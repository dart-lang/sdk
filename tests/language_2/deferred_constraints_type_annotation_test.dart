// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';

import "deferred_constraints_lib.dart" deferred as lib;
import "deferred_constraints_lib.dart" as lib2; //# type_annotation_non_deferred: ok

class F {}

class G2<T> {}

main() {
  lib.C a = null; //# type_annotation_null: compile-time error
  Expect.throws(() { //# new_before_load: compile-time error
    lib.C a = new lib.C(); //# new_before_load: continued
  }, (e) => e is Error); //# new_before_load: continued

  // In this case we do not defer C.
  lib2.C a1 = new lib2.C(); //# type_annotation_non_deferred: continued
  asyncStart();
  lib.loadLibrary().then((_) {
    lib.C a2 = new lib.C(); //# type_annotation1: dynamic type error, compile-time error
    lib.G<F> a3 = new lib.G<F>(); //# type_annotation_generic1: dynamic type error, compile-time error
    G2<lib.C> a4 = new G2(); //# type_annotation_generic2: compile-time error
    G2<lib.C> a5 = new G2<lib.C>(); //# type_annotation_generic3: compile-time error
    lib.G<lib.C> a = new lib.G<lib.C>(); //# type_annotation_generic4: dynamic type error, compile-time error
    var a6 = new lib.C(); //# new: ok
    var g1 = new lib.G<F>(); //# new_generic1: ok
    // new G2<lib.C>() does not give a dynamic type error because a malformed
    // type used as type-parameter is treated as dynamic.
    var g2 = new G2<lib.C>(); //# new_generic2: compile-time error
    var g3 = new lib.G<lib.C>(); //# new_generic3: compile-time error
    var instance = lib.constantInstance;
    Expect.throws(() { //# is_check: compile-time error
      bool a7 = instance is lib.Const; //# is_check: continued
    }, (e) => e is TypeError); //# is_check: continued
    Expect.throws(() { //# as_operation: compile-time error
      instance as lib.Const; //# as_operation: continued
    }, (e) => e is TypeError); //# as_operation: continued
    Expect.throws(() { //# catch_check: compile-time error
      try { throw instance; } on lib.Const {} //# catch_check: continued
    }, (e) => e is TypeError); //# catch_check: continued
    int i = lib.C.staticMethod(); //# static_method: ok
    asyncEnd();
  });
}

lib.C a9 = null; //# type_annotation_top_level: compile-time error
