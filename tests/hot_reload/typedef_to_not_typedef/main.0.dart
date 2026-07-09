// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

// Adapted from:
// https://github.com/dart-lang/sdk/blob/0b221871890a3daf331799aba7409bf299a35cfb/runtime/vm/isolate_reload_test.cc#L6013

// The CFE lowers typedefs to function types and as such the VM will not see
// any name collision between a class and a typedef class (which doesn't exist
// anymore).

typedef bool Predicate(dynamic x);

void expectHelper() {
  Expect.type<Predicate>((foo) => false);
  Expect.notType<Predicate>(42);
}

Future<void> main() async {
  expectHelper();
  await hotReload();
  expectHelper();
}
