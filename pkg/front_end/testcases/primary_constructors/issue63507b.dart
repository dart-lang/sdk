// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C0 {
  C0(int? i) : assert((i = 0) == 0); // Ok
}

class C1(int? i) {
  this : assert((i = 0) == 0); // Error
}

class C2 {
  bool field;
  C2(int? i) : field = (i = 0) == 0; // Ok
}

class C3(int? i) {
  bool field = (i = 0) == 0; // Error
}
