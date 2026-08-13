// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by b
// BSD-style license that can be found in the LICENSE file.

extension type E1(dynamic it) {
  E1.named(dynamic value) : this(value, value);
}

extension type E2(num it) {
  E2.named(super.it) : this(it);
}

extension type E3(String it) {
  E3.named(String it1, String it2) : this(it1), this(it2);
}

extension type E4(bool it) {
  E4.named(bool it) : it = false, this(it);
}
