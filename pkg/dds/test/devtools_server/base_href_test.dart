// Copyright 2024 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:dds/src/devtools/handler.dart';
import 'package:test/test.dart';

void main() {
  /// A set of test cases to verify base hrefs for.
  ///
  /// The key is a suffix appended to / or /devtools/ depending on how DevTools
  /// is hosted.
  /// The value is the expected base href (which should always resolve back to
  /// the root of where DevTools is being hosted).
  final testBaseHrefs = {
    '': '.',
    'inspector': '.',
    'inspector/': '..',
    'inspector/foo': '..',
    'inspector/foo/': '../..',
    'inspector/foo/bar': '../..',
    'inspector/foo/bar/baz': '../../..',
  };

  for (final MapEntry(key: suffix, value: expectedBaseHref)
      in testBaseHrefs.entries) {
    test('computes correct base href for /$suffix with devtools at root',
        () async {
      final actual = computeRelativeBaseHref(
        '/',
        Uri.parse('http://localhost/$suffix'),
      );
      expect(actual, expectedBaseHref);
    });

    test('computes correct base href for /$suffix with devtools at /devtools/',
        () async {
      final actual = computeRelativeBaseHref(
        '/devtools/',
        Uri.parse('http://localhost/devtools/$suffix'),
      );
      expect(actual, expectedBaseHref);
    });

    test('computes correct base href for /$suffix in a devtools extension',
        () async {
      final actual = computeRelativeBaseHref(
        '/devtools/devtools_extension/foo/',
        Uri.parse('http://localhost/devtools/devtools_extension/foo/$suffix'),
      );
      expect(actual, expectedBaseHref);
    });
  }
}
