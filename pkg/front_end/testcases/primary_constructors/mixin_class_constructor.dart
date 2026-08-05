// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

mixin class Class1(); // Ok

mixin class Class2.named(); // Ok

mixin class Class3 {
  Class3(); // Ok
}

mixin class Class4() /* Ok */ {
  Class4.named(); // Error
}

mixin class Class5.named() /* Ok */ {
  Class5(); // Error
}
