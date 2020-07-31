// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=nonfunction-type-aliases

typedef T = C;

class C extends T {}
//    ^
// [analyzer] unspecified
// [cfe] unspecified

main() => C();
