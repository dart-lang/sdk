// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('util_tests');

#import('dart:html');
#import('../../../testing/unittest/unittest.dart');
#import('../../../util/utilslib.dart');

main() {
  test('insertAt', () {
    var a = [];
    CollectionUtils.insertAt(a, 0, 1);
    expect(a).equalsCollection([1]);

    CollectionUtils.insertAt(a, 0, 2);
    expect(a).equalsCollection([2, 1]);

    CollectionUtils.insertAt(a, 0, 5);
    CollectionUtils.insertAt(a, 0, 4);
    CollectionUtils.insertAt(a, 0, 3);
    expect(a).equalsCollection([3, 4, 5, 2, 1]);

    a = [];
    CollectionUtils.insertAt(a, 0, 1);
    expect(a).equalsCollection([1]);

    CollectionUtils.insertAt(a, 1, 2);
    expect(a).equalsCollection([1, 2]);

    CollectionUtils.insertAt(a, 1, 3);
    CollectionUtils.insertAt(a, 3, 4);
    CollectionUtils.insertAt(a, 3, 5);
    expect(a).equalsCollection([1, 3, 2, 5, 4]);
  });

  test('defaultString', () {
    expect(StringUtils.defaultString(null)).equals('');
    expect(StringUtils.defaultString('')).equals('');
    expect(StringUtils.defaultString('test')).equals('test');
  });
}
