// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Uses a deferred constant that contains an unevaluated constant inside a
// record constant.
//
// Regression test for https://github.com/dart-lang/sdk/issues/52468
import 'lib.dart' deferred as l;

main() => l.loadLibrary().then((_) => print(l.list));
