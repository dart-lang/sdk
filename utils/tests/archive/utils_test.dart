// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('utils_test');

#import('../../../pkg/unittest/lib/unittest.dart');
#import('../../archive/utils.dart');

main() {
  // TODO(nweiz): re-enable this once issue 4378 is fixed.
  return;

  group('attachFinalizer', () {
    test('calls the finalizer eventually once the object is collected', () {
      var finalized = null;

      void finalizer(String data) {
        finalized = data;
      }

      while (finalized == null) {
        var list = [1, 2, 3];
        attachFinalizer(list, finalizer, 'finally finalized!');
      }

      expect(finalized, equals('finally finalized!'));
    });

    test("doesn't call the finalizer while the object is in scope", () {
      var finalized = null;

      void finalizer(String data) {
        finalized = data;
      }

      var list = [1, 2, 3];
      attachFinalizer(list, finalizer, 'finally finalized!');
      expect(finalized, isNull);
    });
  });
}
