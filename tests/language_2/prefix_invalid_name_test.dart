// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Prefix must be a valid identifier.
import "library1.dart"
    as lib1.invalid //# 01: compile-time error
    ;

main() {}
