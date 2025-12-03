// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C1 {
  new = 42;
}

class C2 {
  new() = 42;
}

class C3 {
  C3() = C3;
}

class C4 {
  C4.name() = C4;
}