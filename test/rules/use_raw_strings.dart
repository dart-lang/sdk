// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N use_raw_strings`

f(o){
  f('\\'); // LINT
  f('\$'); // LINT
  f('\$ and \\'); // LINT
  f('\$ and \\ and \n'); // OK
  f('\$ and \\ and $f'); // OK

  f('''\\'''); // LINT
  f('''\$'''); // LINT
  f('''\$ and \\'''); // LINT
  f('''\$ and \\ and \n'''); // OK
  f('''\$ and \\ and $f'''); // OK

  f(r'\\'); // OK
  f(r'\$'); // OK
  f(r'\$ and \\'); // OK
  f(r'\$ and \\ and \n'); // OK
  f(r'\$ and \\ and $f'); // OK
}
