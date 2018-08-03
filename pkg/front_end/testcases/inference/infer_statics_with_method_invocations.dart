// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

import 'infer_statics_with_method_invocations_a.dart';

class T {
  static final T foo = m1(m2(m3('', '')));
  static T m1(String m) {
    return null;
  }

  static String m2(e) {
    return '';
  }
}

main() {}
