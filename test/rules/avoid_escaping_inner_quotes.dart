// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N avoid_escaping_inner_quotes`

f(o) {
  f(""); // OK
  f(''); // OK
  f("\""); // LINT
  f('\''); // LINT
  f("\"'"); // OK
  f('\'"'); // OK
  f("\"$f"); // LINT
  f('\'$f'); // LINT
  f("\"'$f"); // OK
  f('\'"$f'); // OK
}