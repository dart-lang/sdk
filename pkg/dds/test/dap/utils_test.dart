// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dds/src/dap/utils.dart';
import 'package:test/test.dart';

main() {
  group('isResolvableUri', () {
    test('false for files', () async {
      expect(isResolvableUri(Uri.parse('file:///foo/bar.dart')), isFalse);
      expect(isResolvableUri(Uri.parse('file:///c:/foo/bar.dart')), isFalse);
    });
    test('false for http(s)', () async {
      expect(isResolvableUri(Uri.parse('http://example.org')), isFalse);
      expect(isResolvableUri(Uri.parse('https://example.org')), isFalse);
    });
    test('true for dart:foo', () async {
      expect(isResolvableUri(Uri.parse('dart:async')), isTrue);
      expect(isResolvableUri(Uri.parse('dart:async/foo')), isTrue);
    });
    test('true for package:foo', () async {
      expect(isResolvableUri(Uri.parse('package:foo')), isTrue);
      expect(isResolvableUri(Uri.parse('package:foo/foo')), isTrue);
    });
    test('false for foo:', () async {
      expect(isResolvableUri(Uri.parse('foo:')), isFalse);
    });
  });
}
