// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test program importing the core library explicitly.

library SourceSelfNegativeTest;

part "source_self_negative_test.dart"; // recursive reference to self.

main() {
  print('should not be able to recursively include self as library part');
}
