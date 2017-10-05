// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//

library Prefix7NegativeTest.dart;

import "library10.dart" as lib10;

// Top level variables cannot shadow library prefixes, they should collide.

var lib10;

main() {}
