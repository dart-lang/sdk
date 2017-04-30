// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

class C {
  static var /*@topType=String*/ x = 'x';
  var /*@topType=Map<String, Map<String, String>>*/ y = /*@typeArgs=String, Map<String, String>*/ {
    'a': /*@typeArgs=String, String*/ {'b': 'c'},
    'd': /*@typeArgs=String, String*/ {'e': x}
  };
}
