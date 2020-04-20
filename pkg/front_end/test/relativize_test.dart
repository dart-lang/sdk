// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/util/relativize.dart';
import 'package:test/test.dart';

void main() {
  test('test relativeUri', () {
    void c(String expected, String base, String path, bool isWindows) {
      if (isWindows == null) {
        c(expected, base, path, true);
        c(expected, base, path, false);
        return;
      }

      test(Uri base, Uri uri) {
        String r = relativizeUri(base, uri, isWindows);
        Uri resolved = base.resolve(r);
        expect(resolved.scheme.toLowerCase(), uri.scheme.toLowerCase());
        if (isWindows) {
          expect(resolved.path.toLowerCase(), uri.path.toLowerCase());
        } else {
          expect(resolved.path, uri.path);
        }
        expect(r, expected);
      }

      test(Uri.parse('file:$base'), Uri.parse('file:$path'));

      test(Uri.parse('FILE:$base'), Uri.parse('FILE:$path'));

      test(Uri.parse('file:$base'), Uri.parse('FILE:$path'));

      test(Uri.parse('FILE:$base'), Uri.parse('file:$path'));
    }

    c('bar', '/', '/bar', null);
    c('bar', '/foo', '/bar', null);
    c('/bar', '/foo/', '/bar', null);

    c('bar', '///c:/', '///c:/bar', true);
    c('bar', '///c:/foo', '///c:/bar', true);
    c('/c:/bar', '///c:/foo/', '///c:/bar', true);

    c('BAR', '///c:/', '///c:/BAR', true);
    c('BAR', '///c:/foo', '///c:/BAR', true);
    c('/c:/BAR', '///c:/foo/', '///c:/BAR', true);

    c(
        '../sdk/lib/_internal/compiler/implementation/dart2js.dart',
        '///C:/Users/person/dart_checkout_for_stuff/dart/ReleaseIA32/dart.exe',
        '///c:/Users/person/dart_checkout_for_stuff/dart/sdk/lib/_internal/compiler/'
            'implementation/dart2js.dart',
        true);

    c('/Users/person/file.dart', '/users/person/', '/Users/person/file.dart',
        false);

    c('file.dart', '/Users/person/', '/Users/person/file.dart', null);

    c('../person/file.dart', '/Users/other/', '/Users/person/file.dart', false);

    c('/Users/person/file.dart', '/Users/other/', '/Users/person/file.dart',
        true);

    c('out.js.map', '/Users/person/out.js', '/Users/person/out.js.map', null);

    c('../person/out.js.map', '/Users/other/out.js', '/Users/person/out.js.map',
        false);

    c('/Users/person/out.js.map', '/Users/other/out.js',
        '/Users/person/out.js.map', true);

    c('out.js', '/Users/person/out.js.map', '/Users/person/out.js', null);

    c('../person/out.js', '/Users/other/out.js.map', '/Users/person/out.js',
        false);

    c('/Users/person/out.js', '/Users/other/out.js.map', '/Users/person/out.js',
        true);

    c('out.js', '/out.js.map', '/out.js', null);
  });
}
