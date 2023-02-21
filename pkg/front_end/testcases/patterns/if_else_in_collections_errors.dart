// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

test1(dynamic x) => [1, if (x case int y) 2 else y, 3]; // Error.

test2(dynamic x) => <int>{1, if (x case int y) 2 else y, 3}; // Error.

test3(dynamic x) => <int, int>{1: 1, if (x case int y) 2: 2 else 2: y, 3: 3}; // Error.

main() {}

