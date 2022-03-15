// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class {
  Class.positional([int a = 0, int b = 42]);
  factory Class.redirect1a() = Class.positional;
  factory Class.redirect2a(int a) = Class.positional;
  factory Class.redirect3a([int a]) = Class.positional;
  factory Class.redirect4a(int a, [int b]) = Class.positional;
  factory Class.redirect5a([int a, int b]) = Class.positional;
  factory Class.redirect6a([int a, int b = 2]) = Class.positional;

  Class.named({int a = 0, int b = 42});
  factory Class.redirect1b() = Class.named;
  factory Class.redirect2b({int a}) = Class.named;
  factory Class.redirect3b({int b}) = Class.named;
  factory Class.redirect4b({int a, int b}) = Class.named;
  factory Class.redirect5b({int b, int a}) = Class.named;
  factory Class.redirect6b({int a = 1, int b}) = Class.named;
}

main() {}
