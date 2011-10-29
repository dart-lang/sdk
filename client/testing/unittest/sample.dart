// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Just a dumb test script to validate that the VM flavor works.

#library('sample');

#import('unittest_vm.dart');

main() {
  group('group 1', () {
    test('passing test 1', () {
      expect(1).equals(1);
      expect(1).equals(1);
    });

    test('failing test 2', () {
      expect(1).equals(1);
      expect(1).equals(2);
    });
  });

  group('group 2', () {
    test('passing test 3', () {
      expect(1).equals(1);
      expect(1).equals(1);
    });

    test('failing test 4', () {
      expect(1).equals(1);
      expect(1).equals(2);
    });
  });

  test('ungrouped passing test 5', () {
    expect(1).equals(1);
    expect(1).equals(1);
  });

  test('ungrouped failing test 5', () {
    expect(1).equals(1);
    expect(1).equals(2);
  });

  asyncTest('async', 2, () {
    new Timer((timer) {
      expect(1).equals(1);
      callbackDone();

      new Timer((timer) {
        expect(1).equals(1);
        callbackDone();
      }, 10, false);
    }, 10, false);
  });
}