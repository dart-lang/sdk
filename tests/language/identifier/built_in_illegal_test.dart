// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Check that we cannot use a pseudo keyword at the class level code.

// Pseudo keywords are not allowed to be used as class names.
class abstract { }
//    ^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.BUILT_IN_IDENTIFIER_AS_TYPE_NAME
// [cfe] Can't use 'abstract' as a name here.
class as { }
//    ^^
// [analyzer] COMPILE_TIME_ERROR.BUILT_IN_IDENTIFIER_AS_TYPE_NAME
// [cfe] Can't use 'as' as a name here.
class dynamic { }
//    ^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.BUILT_IN_IDENTIFIER_AS_TYPE_NAME
// [cfe] Can't use 'dynamic' as a name here.
class export { }
//    ^^^^^^
// [analyzer] SYNTACTIC_ERROR.DIRECTIVE_AFTER_DECLARATION
// [cfe] A class declaration must have a body, even if it is empty.
//    ^^^^^^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_BODY
// [cfe] Directives must appear before any declarations.
//    ^^^^^^
// [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
// [cfe] Expected an identifier, but got 'export'.
// [error line 19, column 14, length 0]
// [cfe] Expected ';' after this.
//           ^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_EXECUTABLE
// [cfe] Expected a String, but got '{'.
//           ^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_STRING_LITERAL
// [cfe] Expected a declaration, but got '{'.
//           ^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
class external { }
//    ^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.BUILT_IN_IDENTIFIER_AS_TYPE_NAME
// [cfe] Can't use 'external' as a name here.
class factory { }
//    ^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.BUILT_IN_IDENTIFIER_AS_TYPE_NAME
// [cfe] Can't use 'factory' as a name here.
class get { }
//    ^^^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_BODY
// [cfe] A class declaration must have a body, even if it is empty.
//    ^^^
// [analyzer] SYNTACTIC_ERROR.MISSING_FUNCTION_PARAMETERS
// [cfe] A function declaration needs an explicit list of parameters.
//    ^^^
// [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
// [cfe] Expected an identifier, but got 'get'.
class interface { }
//    ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.BUILT_IN_IDENTIFIER_AS_TYPE_NAME
// [cfe] Can't use 'interface' as a name here.
class implements { }
//    ^^^^^^^^^^
// [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
// [cfe] Expected an identifier, but got 'implements'.
// [error line 61, column 18, length 0]
// [analyzer] COMPILE_TIME_ERROR.IMPLEMENTS_NON_CLASS
// [cfe] Expected a type, but got '{'.
//               ^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TYPE_NAME
class import { }
//    ^^^^^^
// [analyzer] SYNTACTIC_ERROR.DIRECTIVE_AFTER_DECLARATION
// [cfe] A class declaration must have a body, even if it is empty.
//    ^^^^^^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_BODY
// [cfe] Directives must appear before any declarations.
//    ^^^^^^
// [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
// [cfe] Expected an identifier, but got 'import'.
// [error line 70, column 14, length 0]
// [cfe] Expected ';' after this.
//           ^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_EXECUTABLE
// [cfe] Expected a String, but got '{'.
//           ^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_STRING_LITERAL
// [cfe] Expected a declaration, but got '{'.
//           ^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
class mixin { }
//    ^^^^^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_BODY
// [cfe] A class declaration must have a body, even if it is empty.
//    ^^^^^
// [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
// [cfe] Expected an identifier, but got 'mixin'.
//          ^
// [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
// [cfe] Expected an identifier, but got '{'.
class library { }
//    ^^^^^^^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_BODY
// [cfe] A class declaration must have a body, even if it is empty.
//    ^^^^^^^
// [analyzer] SYNTACTIC_ERROR.LIBRARY_DIRECTIVE_NOT_FIRST
// [cfe] Expected an identifier, but got 'library'.
//    ^^^^^^^
// [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
// [cfe] The library directive must appear before all other directives.
//            ^
// [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
// [cfe] Expected an identifier, but got '{'.
//              ^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_EXECUTABLE
// [cfe] Expected ';' after this.
//              ^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [cfe] Expected a declaration, but got '}'.
class operator { }
//    ^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.BUILT_IN_IDENTIFIER_AS_TYPE_NAME
// [cfe] Can't use 'operator' as a name here.
class part { }
//    ^^^^
// [analyzer] SYNTACTIC_ERROR.DIRECTIVE_AFTER_DECLARATION
// [cfe] A class declaration must have a body, even if it is empty.
//    ^^^^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_BODY
// [cfe] Directives must appear before any declarations.
//    ^^^^
// [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
// [cfe] Expected an identifier, but got 'part'.
// [error line 123, column 12, length 0]
// [analyzer] COMPILE_TIME_ERROR.PART_OF_NON_PART
// [cfe] Expected ';' after this.
//         ^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_EXECUTABLE
// [cfe] Expected a String, but got '{'.
//         ^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_STRING_LITERAL
// [cfe] Expected a declaration, but got '{'.
//         ^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
class set { }
//    ^^^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_BODY
// [cfe] A class declaration must have a body, even if it is empty.
//    ^^^
// [analyzer] SYNTACTIC_ERROR.MISSING_FUNCTION_PARAMETERS
// [cfe] A function declaration needs an explicit list of parameters.
//    ^^^
// [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
// [cfe] Expected an identifier, but got 'set'.
class static { }
//    ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.BUILT_IN_IDENTIFIER_AS_TYPE_NAME
// [cfe] Can't use 'static' as a name here.
class typedef { }
//    ^^^^^^^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_BODY
// [cfe] A class declaration must have a body, even if it is empty.
//    ^^^^^^^
// [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
// [cfe] Expected an identifier, but got 'typedef'.
//            ^
// [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
// [cfe] Expected an identifier, but got '{'.
//              ^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_EXECUTABLE
// [cfe] A typedef needs an explicit list of parameters.
//              ^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [cfe] Expected ';' after this.
//              ^
// [analyzer] SYNTACTIC_ERROR.MISSING_TYPEDEF_PARAMETERS
// [cfe] Expected a declaration, but got '}'.

main() {}
