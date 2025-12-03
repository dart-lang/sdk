// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// `late` and `external` instance variables cannot be introduced by a declaring
// parameter.

// SharedOptions=--enable-experiment=primary-constructors

class C1(late int x, external double d);
//       ^
// [analyzer] unspecified
// [cfe] unspecified
