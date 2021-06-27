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
// [analyzer] COMPILE_TIME_ERROR.BUILT_IN_IDENTIFIER_IN_DECLARATION
// [cfe] Can't use 'export' as a name here.
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
// [analyzer] COMPILE_TIME_ERROR.BUILT_IN_IDENTIFIER_IN_DECLARATION
// [cfe] Can't use 'get' as a name here.
class interface { }
//    ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.BUILT_IN_IDENTIFIER_IN_DECLARATION
// [cfe] Can't use 'interface' as a name here.
class implements { }
//    ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.BUILT_IN_IDENTIFIER_IN_DECLARATION
// [cfe] Can't use 'implements' as a name here.
class import { }
//    ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.BUILT_IN_IDENTIFIER_IN_DECLARATION
// [cfe] Can't use 'import' as a name here.
class mixin { }
//    ^^^^^
// [analyzer] COMPILE_TIME_ERROR.BUILT_IN_IDENTIFIER_IN_DECLARATION
// [cfe] Can't use 'mixin' as a name here.
class library { }
//    ^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.BUILT_IN_IDENTIFIER_IN_DECLARATION
// [cfe] Can't use 'library' as a name here.
class operator { }
//    ^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.BUILT_IN_IDENTIFIER_IN_DECLARATION
// [cfe] Can't use 'operator' as a name here.
class part { }
//    ^^^^
// [analyzer] COMPILE_TIME_ERROR.BUILT_IN_IDENTIFIER_IN_DECLARATION
// [cfe] Can't use 'part' as a name here.
class set { }
//    ^^^
// [analyzer] COMPILE_TIME_ERROR.BUILT_IN_IDENTIFIER_IN_DECLARATION
// [cfe] Can't use 'set' as a name here.
class static { }
//    ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.BUILT_IN_IDENTIFIER_IN_DECLARATION
// [cfe] Can't use 'static' as a name here.
class typedef { }
//    ^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.BUILT_IN_IDENTIFIER_IN_DECLARATION
// [cfe] Can't use 'typedef' as a name here.

main() {}
