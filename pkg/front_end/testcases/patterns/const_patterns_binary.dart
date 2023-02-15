// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'const_patterns_binary.dart' as prefix;

const value = 1;

class Class {
  static const value = 2;
}

method<T>(o) {
  switch (o) {
    case 1 || 2: // Ok
    case 1 && 2: // Ok
    case 1 as T: // Ok
    case const Object(): // Ok
    case 1 + 2: // Error
    case 1 - 2: // Error
    case 1 * 2: // Error
    case 1 / 2: // Error
    case 1 ~/ 2: // Error
    case 1 % 2: // Error
    case 1 == 2: // Error
    case 1 != 2: // Error
    case 1 ^ 2: // Error
    case 1 & 2: // Error
    case 1 | 2: // Error
    case 1 < 2: // Error
    case 1 <= 2: // Error
    case 1 > 2: // Error
    case 1 >= 2: // Error
    case 1 << 2: // Error
    case 1 >> 2: // Error
    case 1 >>> 2: // Error
    case 1 + 2 + 3: // Error
    case prefix.value as T: // Ok
    case prefix.Class.value as T: // Ok
    case const 1 as int: // Error
    case const 1 + 2: // Error
    case const 1 - 2: // Error
    case const 1 * 2: // Error
    case const 1 / 2: // Error
    case const 1 ~/ 2: // Error
    case const 1 % 2: // Error
    case const 1 == 2: // Error
    case const 1 != 2: // Error
    case const 1 ^ 2: // Error
    case const 1 & 2: // Error
    case const 1 | 2: // Error
    case const 1 < 2: // Error
    case const 1 <= 2: // Error
    case const 1 > 2: // Error
    case const 1 >= 2: // Error
    case const 1 << 2: // Error
    case const 1 >> 2: // Error
    case const 1 >>> 2: // Error
    case const 1 + 2 + 3: // Error
    case const Object() == 2: // Error
    case const <int>[] as List<T>: // Ok
    case const (1 + 2): // Ok
    case const (1 - 2): // Ok
    case const (1 * 2): // Ok
    case const (1 / 2): // Ok
    case const (1 ~/ 2): // Ok
    case const (1 % 2): // Ok
    case const (1 == 2): // Ok
    case const (1 != 2): // Ok
    case const (1 ^ 2): // Ok
    case const (1 & 2): // Ok
    case const (1 | 2): // Ok
    case const (1 < 2): // Ok
    case const (1 <= 2): // Ok
    case const (1 > 2): // Ok
    case const (1 >= 2): // Ok
    case const (1 << 2): // Ok
    case const (1 >> 2): // Ok
    case const (1 >>> 2): // Ok
    case const (1 + 2 + 3): // Ok
    case 1 ?? 2: // Error
    case o++: // Error
    case o--: // Error
    case ++o: // Error
    case --o: // Error
  }
}