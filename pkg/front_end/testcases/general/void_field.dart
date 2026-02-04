// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef T<X> = void;

T<int> value = null;

class C {
  T<int> field1;

  T<int> field2 = value;

  T<int> field3;

  C(this.field1) : field3 = value;
}
