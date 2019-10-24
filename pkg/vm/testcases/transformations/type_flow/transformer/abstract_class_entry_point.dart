// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that an abstract class with no members is retained if marked as an
// entry-point.

@pragma("vm:entry-point")
abstract class AbstractEmptyClass {}

main() {}
