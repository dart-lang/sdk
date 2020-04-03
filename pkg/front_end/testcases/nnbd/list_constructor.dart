// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The test checks that it's an error to invoke the default constructor of List
// with potentially non-nullable type argument and specify the length.

foo<T extends Object?>() {
  new List<T>(42);
  new List<int?>(42);
  new List<int>(42);
}

main() {}
