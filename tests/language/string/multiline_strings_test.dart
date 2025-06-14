// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

void main() {
  // Spaces after '''.
  Expect.equals('foo', '''  
foo''');

  // Tab characters after '''.
  Expect.equals('foo', '''		
foo''');

  Expect.equals('\\\nfoo', '''\\
foo''');

  Expect.equals('\t\nfoo', '''\t
foo''');

  // Backslash just before newline.
  Expect.equals('foo', '''\
foo''');

  // Backslash before space, tab and newline.
  Expect.equals('foo', '''\ \	\
foo''');

  Expect.equals(' \nfoo', '''\x20
foo''');

  String x = ' ';
  Expect.equals(' \nfoo', '''$x
foo''');

  /// Spaces after '''.
  Expect.equals('foo', r'''  
foo''');

  /// Tab characters after '''.
  Expect.equals('foo', r'''		
foo''');

  Expect.equals('\\\\\nfoo', r'''\\
foo''');

  Expect.equals('\\t\nfoo', r'''\t
foo''');

  // Backslash before newline.
  Expect.equals('foo', r'''\
foo''');

  // Backslash before space, tab and newline.
  Expect.equals('foo', r'''\ \	\
foo''');
}
