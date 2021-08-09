// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension E1 on int show num {
  int ceil() {} // Error.
}

extension E2 on int show num hide ceil {
  int ceil() {} // Ok.
  int floor() {} // Error.
}

extension E3 on int hide isEven {
  // `on int hide isEven` means `on int show int hide isEven`.
  bool get isOdd => throw 42; // Error.
  bool get isEven => throw 42; // Ok.
}

main() {}
