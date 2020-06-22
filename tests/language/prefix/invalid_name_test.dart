// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Prefix must be a valid identifier.
import "../library1.dart"
    as lib1.invalid
    // ^^^^
    // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
    // [cfe] Expected ';' after this.
    //     ^
    // [analyzer] SYNTACTIC_ERROR.EXPECTED_EXECUTABLE
    // [cfe] Expected a declaration, but got '.'.
    //      ^^^^^^^
    // [analyzer] SYNTACTIC_ERROR.MISSING_CONST_FINAL_VAR_OR_TYPE
    // [cfe] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
    ;

main() {}
