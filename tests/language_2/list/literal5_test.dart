// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

/// Legacy compound literal syntax that should go away.

main() {
  new List<int>[1, 2];
//^^^^^^^^
// [analyzer] SYNTACTIC_ERROR.LITERAL_WITH_CLASS_AND_NEW
// [cfe] A list literal can't be prefixed by 'new List'.
}
