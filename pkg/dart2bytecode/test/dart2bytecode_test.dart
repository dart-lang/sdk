// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:dart2bytecode/dart2bytecode.dart' show prefixUri;
import 'package:test/test.dart';

void main() {
  group('prefixUri', () {
    test('prefixes file URIs', () {
      expect(prefixUri(Uri.parse('file:///foo/bar.dart'), ['pre', 'fix']),
          Uri.parse('file:///pre/fix/foo/bar.dart'));
    });
    test('prefixes package URIs', () {
      expect(prefixUri(Uri.parse('package:foo/bar.dart'), ['pre', 'fix']),
          Uri.parse('package:pre.fix.foo/bar.dart'));
    });
  });
}
