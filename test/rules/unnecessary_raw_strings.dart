// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N unnecessary_raw_strings`

f(o) {
  f(r'a b c d');// LINT
  f(r"a b c d");// LINT
  f(r'''a b c d''');// LINT
  f(r"""a b c d""");// LINT
  // with \
  f(r'a b c\d');// OK
  f(r"a b c\d");// OK
  f(r'''a b c\d''');// OK
  f(r"""a b c\d""");// OK
  // with $
  f(r'a b c$d');// OK
  f(r"a b c$d");// OK
  f(r'''a b c$d''');// OK
  f(r"""a b c$d""");// OK
}
