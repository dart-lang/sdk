// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

// The test checks that a legacy type is inferred even if some of the input
// types are from opted-in libraries.

import './infer_in_legacy_from_opted_in_lib.dart';

bar(int x) {
  baz(foo(x, y));
}

main() {}
