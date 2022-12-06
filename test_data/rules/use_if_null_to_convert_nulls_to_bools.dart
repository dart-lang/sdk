// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `dart test -N use_if_null_to_convert_nulls_to_bools`

m() {
  bool? e;
  bool r;
  r = e == true; // LINT
  r = e == false; // OK
  r = e ?? false; // OK
  r = e != false; // LINT
  r = e != true; // OK
  r = e ?? true; // OK
}
