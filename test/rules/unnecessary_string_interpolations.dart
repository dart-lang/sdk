// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N unnecessary_string_interpolations`

String o;

f() {
  o = '$o'; // LINT
  o = '''$o'''; // LINT
  o = '${o}'; // LINT
  o = '${o.substring(1)}'; // LINT
  o = '${o.length}'; // OK
  o = 'a$o'; // OK
  o = '''a$o'''; // OK
  o = 'a' '$o'; // OK
}