// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension Extension on int {
  num get getter => this;
}

method1(int i) => switch (i) {
      int(:num getter) => 0, // Ok
    };

method2(int i) => switch (i) /* Error */ {
      int(:int getter) => 0,
    };
