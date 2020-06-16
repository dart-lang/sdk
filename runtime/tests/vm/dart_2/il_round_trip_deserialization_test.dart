// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=
// VMOptions=--early-round-trip-serialization
// VMOptions=--late-round-trip-serialization
// VMOptions=--early-round-trip-serialization --late-round-trip-serialization
// VMOptions=--deterministic
// VMOptions=--deterministic --early-round-trip-serialization
// VMOptions=--deterministic --late-round-trip-serialization
// VMOptions=--deterministic --early-round-trip-serialization --late-round-trip-serialization

// Just use the existing hello world test for now.
// TODO(36882): Add more interesting code as the deserializer grows.
import 'hello_world_test.dart' as test;

main(args) {
  test.main();
}
