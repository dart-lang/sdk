// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_utilities/src/api_summary/src/uri_sorting.dart';
import 'package:collection/collection.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UriTest);
  });
}

@reflectiveTest
class UriTest {
  void test_sortOrder_inOrOutOfPackageBeforeName() {
    _checkSorting(
      uris: [
        Uri.parse('package:a/a.dart'),
        Uri.parse('package:b/b.dart'),
        Uri.parse('package:c/c.dart'),
      ],
      expectedOrder: [
        'package:b/b.dart',
        'package:a/a.dart',
        'package:c/c.dart',
      ],
      packageName: 'b',
    );
  }

  void _checkSorting({
    required List<Uri> uris,
    required List<String> expectedOrder,
    required String packageName,
  }) {
    expect(
      uris
          .sortedBy((e) => UriSortKey(e, packageName))
          .map((e) => e.toString())
          .toList(),
      expectedOrder,
    );
    expect(
      uris.reversed
          .sortedBy((e) => UriSortKey(e, packageName))
          .map((e) => e.toString())
          .toList(),
      expectedOrder,
    );
  }
}
