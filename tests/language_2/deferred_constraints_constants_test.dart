// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'dart:mirrors';

import "deferred_constraints_constants_lib.dart" deferred as lib;

const myConst1 =
  lib.constantInstance; //# reference1: compile-time error
  /* //                   //# reference1: continued
    499;
  */ //                   //# reference1: continued
const myConst2 =
  lib.Const.instance; //# reference2: compile-time error
  /* //                 //# reference2: continued
    499;
  */ //                 //# reference2: continued

void f1(
    {a:
  const lib.Const() //# default_argument1: compile-time error
  /* //                  //# default_argument1: continued
        499
  */ //                  //# default_argument1: continued
    }) {}

void f2(
    {a:
  lib.constantInstance //# default_argument2: compile-time error
  /* //                        //# default_argument2: continued
        499
  */ //                        //# default_argument2: continued
    }) {}

@lib.Const() //# metadata1: compile-time error
class H1 {}

@lib.Const.instance //# metadata2: compile-time error
class H2 {}

@lib.Const.namedConstructor() //# metadata3: compile-time error
class H3 {}

void main() {
  var a1 = myConst1;
  var a2 = myConst2;

  asyncStart();
  lib.loadLibrary().then((_) {
    var instance = lib.constantInstance;
    var c1 = const lib.Const(); //# constructor1: compile-time error
    var c2 = const lib.Const.namedConstructor(); //# constructor2: compile-time error
    f1();
    f2();
    var constInstance = lib.constantInstance; //# reference_after_load: ok
    var h1 = new H1();
    var h2 = new H2();
    var h3 = new H3();

    // Need to access the metadata to trigger the expected compilation error.
    reflectClass(H1).metadata; // metadata1: continued
    reflectClass(H2).metadata; // metadata2: continued
    reflectClass(H3).metadata; // metadata3: continued

    asyncEnd();
  });
}
