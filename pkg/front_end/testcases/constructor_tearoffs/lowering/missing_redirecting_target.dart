// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class {
  Class._();
  static Class constructor() => new Class._();
  static Class Function() field = () => new Class._();

  factory Class.a() = Class.nonexisting;
  factory Class.b() = Class.constructor;
}

main() {}
