// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Check that we cannot use a pseudo keyword at the class level code.

// @dart = 2.9

// Pseudo keywords are not allowed to be used as class names.
class abstract { }
//    ^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.BUILT_IN_IDENTIFIER_IN_DECLARATION
// [cfe] Can't use 'abstract' as a name here.
class as { }
//    ^^
// [analyzer] COMPILE_TIME_ERROR.BUILT_IN_IDENTIFIER_IN_DECLARATION
// [cfe] Can't use 'as' as a name here.
class dynamic { }
//    ^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.BUILT_IN_IDENTIFIER_IN_DECLARATION
// [cfe] Can't use 'dynamic' as a name here.
class export { }
//    ^^^^^^
// [analyzer] SYNTACTIC_ERROR.DIRECTIVE_AFTER_DECLARATION
// [analyzer] SYNTACTIC_ERROR.EXPECTED_BODY
// [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
// [cfe] A class declaration must have a body, even if it is empty.
// [cfe] Directives must appear before any declarations.
// [cfe] Expected an identifier, but got 'export'.
//           ^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_EXECUTABLE
// [analyzer] SYNTACTIC_ERROR.EXPECTED_STRING_LITERAL
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [cfe] Expected ';' after this.
// [cfe] Expected a String, but got '{'.
// [cfe] Expected a declaration, but got '{'.
class external { }
//    ^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.BUILT_IN_IDENTIFIER_IN_DECLARATION
// [cfe] Can't use 'external' as a name here.
class factory { }
//    ^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.BUILT_IN_IDENTIFIER_IN_DECLARATION
// [cfe] Can't use 'factory' as a name here.
class get { }
//    ^^^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_BODY
// [analyzer] SYNTACTIC_ERROR.MISSING_FUNCTION_PARAMETERS
// [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
// [cfe] A class declaration must have a body, even if it is empty.
// [cfe] A function declaration needs an explicit list of parameters.
// [cfe] Expected an identifier, but got 'get'.
class interface { }
//    ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.BUILT_IN_IDENTIFIER_IN_DECLARATION
// [cfe] Can't use 'interface' as a name here.
class implements { }
//    ^^^^^^^^^^
// [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
// [cfe] Expected an identifier, but got 'implements'.
// [error line 56, column 18, length 0]
// [analyzer] COMPILE_TIME_ERROR.IMPLEMENTS_NON_CLASS
//               ^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TYPE_NAME
// [cfe] Expected a type, but got '{'.
class import { }
//    ^^^^^^
// [analyzer] SYNTACTIC_ERROR.DIRECTIVE_AFTER_DECLARATION
// [analyzer] SYNTACTIC_ERROR.EXPECTED_BODY
// [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
// [cfe] A class declaration must have a body, even if it is empty.
// [cfe] Directives must appear before any declarations.
// [cfe] Expected an identifier, but got 'import'.
//           ^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_EXECUTABLE
// [analyzer] SYNTACTIC_ERROR.EXPECTED_STRING_LITERAL
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [cfe] Expected ';' after this.
// [cfe] Expected a String, but got '{'.
// [cfe] Expected a declaration, but got '{'.
class mixin { }
//    ^^^^^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_BODY
// [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
// [cfe] A class declaration must have a body, even if it is empty.
// [cfe] Expected an identifier, but got 'mixin'.
//          ^
// [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
// [cfe] Expected an identifier, but got '{'.
class library { }
//    ^^^^^^^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_BODY
// [analyzer] SYNTACTIC_ERROR.LIBRARY_DIRECTIVE_NOT_FIRST
// [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
// [cfe] A class declaration must have a body, even if it is empty.
// [cfe] Expected an identifier, but got 'library'.
// [cfe] The library directive must appear before all other directives.
//            ^
// [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
// [cfe] Expected an identifier, but got '{'.
//              ^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_EXECUTABLE
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [cfe] Expected ';' after this.
// [cfe] Expected a declaration, but got '}'.
class operator { }
//    ^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.BUILT_IN_IDENTIFIER_IN_DECLARATION
// [cfe] Can't use 'operator' as a name here.
class part { }
//    ^^^^
// [analyzer] SYNTACTIC_ERROR.DIRECTIVE_AFTER_DECLARATION
// [analyzer] SYNTACTIC_ERROR.EXPECTED_BODY
// [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
// [cfe] A class declaration must have a body, even if it is empty.
// [cfe] Directives must appear before any declarations.
// [cfe] Expected an identifier, but got 'part'.
//         ^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_EXECUTABLE
// [analyzer] SYNTACTIC_ERROR.EXPECTED_STRING_LITERAL
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [cfe] Expected ';' after this.
// [cfe] Expected a String, but got '{'.
// [cfe] Expected a declaration, but got '{'.
class set { }
//    ^^^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_BODY
// [analyzer] SYNTACTIC_ERROR.MISSING_FUNCTION_PARAMETERS
// [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
// [cfe] A class declaration must have a body, even if it is empty.
// [cfe] A function declaration needs an explicit list of parameters.
// [cfe] Expected an identifier, but got 'set'.
class static { }
//    ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.BUILT_IN_IDENTIFIER_IN_DECLARATION
// [cfe] Can't use 'static' as a name here.
class typedef { }
//    ^^^^^^^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_BODY
// [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
// [cfe] A class declaration must have a body, even if it is empty.
// [cfe] Expected an identifier, but got 'typedef'.
//            ^
// [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
// [cfe] Expected an identifier, but got '{'.
//              ^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_EXECUTABLE
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [analyzer] SYNTACTIC_ERROR.MISSING_TYPEDEF_PARAMETERS
// [cfe] A typedef needs an explicit list of parameters.
// [cfe] Expected ';' after this.
// [cfe] Expected a declaration, but got '}'.

main() {}
