// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Note: This test relies on LF line endings in the source file.
// It requires an entry in the .gitattributes file.

import "package:expect/expect.dart";

main() {
  Expect.equals(
      'foo',
      '''  
foo''');

  Expect.equals(
      '\\\nfoo',
      '''\\
foo''');

  Expect.equals(
      '\t\nfoo',
      '''\t
foo''');

  Expect.equals(
      'foo',
      '''\
foo''');

  Expect.equals(
      'foo',
      '''\ \
foo''');

  Expect.equals(
      ' \nfoo',
      '''\x20
foo''');

  String x = ' ';
  Expect.equals(
      ' \nfoo',
      '''$x
foo''');

  Expect.equals(
      'foo',
      r'''  
foo''');

  Expect.equals(
      '\\\\\nfoo',
      r'''\\
foo''');

  Expect.equals(
      '\\t\nfoo',
      r'''\t
foo''');

  Expect.equals(
      'foo',
      r'''\
foo''');

  Expect.equals(
      'foo',
      r'''\ \
foo''');
}
