// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('import_mapper_tests');

#import('../../../import_mapper/import_mapper.dart', prefix: 'mapper');

// TODO(rnystrom): Better path to unittest.
#import('../../../../lib/unittest/unittest_vm.dart');

main() {
  group('generateImportMap', () {
    test('walks import graph', () {
      final expected = { 'b.dart': 'b.dart', 'c.dart': 'c.dart' };
      final actual = mapper.generateImportMap(
          'utils/tests/import_mapper/src/c.dart',
          (context, name) => name);
      expect(actual).equals(expected);
    });
  });
}
