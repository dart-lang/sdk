// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:uri';

import '../../../sdk/lib/_internal/compiler/implementation/util/uri_extras.dart';


void testRelativize() {
  void c(String expected, String base, String path, bool isWindows) {
    if (isWindows === null) {
      c(expected, base, path, true);
      c(expected, base, path, false);
      return;
    }
    String r;

    r = relativize(new Uri.fromString('file:$base'),
                   new Uri.fromString('file:$path'),
                   isWindows);
    Expect.stringEquals(expected, r);

    r = relativize(new Uri.fromString('FILE:$base'),
                   new Uri.fromString('FILE:$path'),
                   isWindows);
    Expect.stringEquals(expected, r);

    r = relativize(new Uri.fromString('file:$base'),
                   new Uri.fromString('FILE:$path'),
                   isWindows);
    Expect.stringEquals(expected, r);

    r = relativize(new Uri.fromString('FILE:$base'),
                   new Uri.fromString('file:$path'),
                   isWindows);
    Expect.stringEquals(expected, r);
  }
  c('bar', '/', '/bar', null);
  c('/bar', '/foo', '/bar', null);
  c('/bar', '/foo/', '/bar', null);

  c('bar', '///c:/', '///c:/bar', true);
  c('/c:/bar', '///c:/foo', '///c:/bar', true);
  c('/c:/bar', '///c:/foo/', '///c:/bar', true);

  c('BAR', '///c:/', '///c:/BAR', true);
  c('/c:/BAR', '///c:/foo', '///c:/BAR', true);
  c('/c:/BAR', '///c:/foo/', '///c:/BAR', true);

  c('../lib/_internal/compiler/implementation/dart2js.dart',
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
}

void main() {
  testRelativize();
}
