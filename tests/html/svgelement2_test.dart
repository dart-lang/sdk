// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('SVGElement2Test');
#import('../../lib/unittest/unittest.dart');
#import('../../lib/unittest/html_config.dart');
#import('dart:html');
#import('svgelement_test.dart', prefix: 'originalTest');

class A {
  var _this;
  A(x) : this._this = x;
}

main() {
  // The svgelement_test requires the field "_this" to map to "_this". In this
  // test-case we use another library's '_this' first (see issue 3039 and
  // _ChildNodeListLazy.first).
  Expect.equals(499, new A(499)._this);
  originalTest.main();
}
