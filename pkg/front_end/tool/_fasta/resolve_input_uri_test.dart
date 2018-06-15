// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show Platform;

import 'package:test/test.dart';

import 'resolve_input_uri.dart';

main() {
  test('data URI scheme is supported by default', () {
    expect(resolveInputUri('data:,foo').scheme, 'data');
  });

  test('internal dart schemes are recognized by default', () {
    expect(resolveInputUri('dart:foo').scheme, 'dart');
    expect(resolveInputUri('package:foo').scheme, 'package');
  });

  test('unknown schemes are not recognized by default', () {
    expect(resolveInputUri('c:/foo').scheme, 'file');
    if (Platform.isWindows) {
      /// : is an invalid path character in windows.
      expect(() => resolveInputUri('test:foo').scheme, throws);
      expect(() => resolveInputUri('org-dartlang-foo:bar').scheme, throws);
    } else {
      expect(resolveInputUri('test:foo').scheme, 'file');
      expect(resolveInputUri('org-dartlang-foo:bar').scheme, 'file');
    }
  });

  test('more schemes can be supported', () {
    expect(resolveInputUri('test:foo', extraSchemes: ['test']).scheme, 'test');
    expect(
        resolveInputUri('org-dartlang-foo:bar',
            extraSchemes: ['org-dartlang-foo']).scheme,
        'org-dartlang-foo');
  });
}
