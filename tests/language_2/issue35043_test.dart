// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

final foo = Map<int>();
//          ^^^^^^^^
// [analyzer] STATIC_WARNING.NEW_WITH_INVALID_TYPE_PARAMETERS
// [cfe] Expected 2 type arguments.

main() {}
