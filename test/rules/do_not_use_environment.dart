// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N do_not_use_environment`

void f() {
  int.fromEnvironment('key'); // LINT
  bool.fromEnvironment('key'); // LINT
  String.fromEnvironment('key'); //LINT
  bool.hasEnvironment('key'); //LINT
}
