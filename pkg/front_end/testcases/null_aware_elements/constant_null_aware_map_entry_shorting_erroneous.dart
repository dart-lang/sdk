// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

const String? key = "key";
const Map<String, int> mapLiteral = <String, int>{?key: 1 / 0}; // Compile-time error: since the key is not null, the value is evaluated and causes a compile-time error.
