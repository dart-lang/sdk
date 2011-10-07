// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('util_tests');

#import('dart:html');
#import('../../../testing/unittest/unittest.dart');
#import('../../../util/utilslib.dart');

main() {
  new UtilsTests().run();
}

class UtilsTests extends UnitTestSuite {

  UtilsTests() : super() {}

  void setUpTestSuite() {
    addTest(void testInsertAt() {
      List a = new List();
      CollectionUtils.insertAt(a, 0, 1);
      Expect.listEquals([1], a);

      CollectionUtils.insertAt(a, 0, 2);
      Expect.listEquals([2, 1], a);

      CollectionUtils.insertAt(a, 0, 5);
      CollectionUtils.insertAt(a, 0, 4);
      CollectionUtils.insertAt(a, 0, 3);
      Expect.listEquals([3, 4, 5, 2, 1], a);

      a = new List();
      CollectionUtils.insertAt(a, 0, 1);
      Expect.listEquals([1], a);

      CollectionUtils.insertAt(a, 1, 2);
      Expect.listEquals([1, 2], a);

      CollectionUtils.insertAt(a, 1, 3);
      CollectionUtils.insertAt(a, 3, 4);
      CollectionUtils.insertAt(a, 3, 5);
      Expect.listEquals([1, 3, 2, 5, 4], a);
    });

    addTest(void testDefaultString() {
      Expect.equals('', StringUtils.defaultString(null));
      Expect.equals('', StringUtils.defaultString(''));
      Expect.equals('test', StringUtils.defaultString('test'));
    });
  }
}
