// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class {
  Class method() => this;
}

extension Extension on Class {
  Class extensionMethod() => this;
}

main() {
  Class? c;
  c?..method();
  c?..method()..method();
  c?..extensionMethod();
  c?..extensionMethod()..extensionMethod();
}
