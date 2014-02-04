// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:mirrors";

import "package:async_helper/async_helper.dart";

import "mirrors_test_helper.dart";
import "../../../lib/mirrors/class_mirror_type_variables_expect.dart";

class CompileTimeEnv implements Env {
  final MirrorSystem mirrors;

  CompileTimeEnv(this.mirrors);

  LibraryMirror get core => mirrors.libraries[Uri.parse('dart:core')];

  LibraryMirror get test =>
      mirrors.findLibrary(#class_mirror_type_variables_data);


  ClassMirror getA() => test.declarations[#A];
  ClassMirror getB() => test.declarations[#B];
  ClassMirror getC() => test.declarations[#C];
  ClassMirror getD() => test.declarations[#D];
  ClassMirror getE() => test.declarations[#E];
  ClassMirror getF() => test.declarations[#F];
  ClassMirror getNoTypeParams() => test.declarations[#NoTypeParams];
  ClassMirror getObject() => core.declarations[#Object];
  ClassMirror getString() => core.declarations[#String];
  ClassMirror getHelperOfString() =>
      createInstantiation(test.declarations[#Helper], [getString()]);
}

main() {
  asyncTest(() => analyze("class_mirror_type_variables_data.dart").
      then((MirrorSystem mirrors) {
    test(new CompileTimeEnv(mirrors));
  }));

}
