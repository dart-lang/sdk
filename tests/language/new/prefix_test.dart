// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:core' as prefix;

main() {
  return new prefix();
  //         ^^^^^^
  // [analyzer] STATIC_WARNING.NEW_WITH_NON_TYPE
  // [cfe] Method not found: 'prefix'.
}
