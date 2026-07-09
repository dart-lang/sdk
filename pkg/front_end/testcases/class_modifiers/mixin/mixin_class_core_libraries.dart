// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that it is an error to mix in a non-mixin class post 3.0.

// Error
class A with Comparable<int> {
  int compareTo(int x) => 0;
}

class B with Error {} /* Error */
