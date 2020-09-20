// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

var get;
var get a;
// [error line 6, column 1, length 3]
// [analyzer] SYNTACTIC_ERROR.VAR_RETURN_TYPE
// [cfe] The return type can't be 'var'.
//       ^
// [analyzer] SYNTACTIC_ERROR.MISSING_FUNCTION_BODY
// [cfe] Expected a function body or '=>'.
var get b, c;
// [error line 13, column 1, length 3]
// [analyzer] SYNTACTIC_ERROR.VAR_RETURN_TYPE
// [cfe] The return type can't be 'var'.
//       ^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_EXECUTABLE
// [cfe] Expected '{' before this.
//       ^
// [analyzer] SYNTACTIC_ERROR.MISSING_FUNCTION_BODY
// [cfe] Expected a declaration, but got ','.
//       ^
// [cfe] Expected a function body, but got ','.
//       ^
// [cfe] Expected a function body, but got '{'.
//         ^
// [analyzer] SYNTACTIC_ERROR.MISSING_CONST_FINAL_VAR_OR_TYPE
// [cfe] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.

var set;
var set d;
// [error line 32, column 1, length 3]
// [analyzer] SYNTACTIC_ERROR.VAR_RETURN_TYPE
// [cfe] The return type can't be 'var'.
//      ^
// [analyzer] COMPILE_TIME_ERROR.WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER
// [cfe] A function declaration needs an explicit list of parameters.
//      ^
// [analyzer] SYNTACTIC_ERROR.MISSING_FUNCTION_PARAMETERS
//       ^
// [analyzer] SYNTACTIC_ERROR.MISSING_FUNCTION_BODY
// [cfe] A setter should have exactly one formal parameter.
//       ^
// [cfe] Expected a function body or '=>'.
var set e, f;
// [error line 46, column 1, length 3]
// [analyzer] SYNTACTIC_ERROR.VAR_RETURN_TYPE
// [cfe] The return type can't be 'var'.
//      ^
// [analyzer] COMPILE_TIME_ERROR.WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER
// [cfe] A function declaration needs an explicit list of parameters.
//      ^
// [analyzer] SYNTACTIC_ERROR.MISSING_FUNCTION_PARAMETERS
//       ^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_EXECUTABLE
// [cfe] A setter should have exactly one formal parameter.
//       ^
// [analyzer] SYNTACTIC_ERROR.MISSING_FUNCTION_BODY
// [cfe] Expected '{' before this.
//       ^
// [cfe] Expected a declaration, but got ','.
//         ^
// [analyzer] SYNTACTIC_ERROR.MISSING_CONST_FINAL_VAR_OR_TYPE
// [cfe] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.

class C0 {
//    ^
// [cfe] The non-abstract class 'C0' is missing implementations for these members:
  var get;
  var get a;
//^^^
// [analyzer] SYNTACTIC_ERROR.VAR_RETURN_TYPE
// [cfe] The return type can't be 'var'.
//    ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONCRETE_CLASS_WITH_ABSTRACT_MEMBER
  var get b, c;
//^^^
// [analyzer] SYNTACTIC_ERROR.VAR_RETURN_TYPE
// [cfe] The return type can't be 'var'.
//         ^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_CLASS_MEMBER
// [cfe] Expected '{' before this.
//         ^
// [analyzer] SYNTACTIC_ERROR.MISSING_FUNCTION_BODY
// [cfe] Expected a class member, but got ','.
//           ^
// [analyzer] SYNTACTIC_ERROR.MISSING_CONST_FINAL_VAR_OR_TYPE
// [cfe] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.

  var set;
  var set d;
//^^^
// [analyzer] SYNTACTIC_ERROR.VAR_RETURN_TYPE
// [cfe] The return type can't be 'var'.
//    ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONCRETE_CLASS_WITH_ABSTRACT_MEMBER
//        ^
// [analyzer] COMPILE_TIME_ERROR.WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER
// [cfe] A method declaration needs an explicit list of parameters.
//        ^
// [analyzer] SYNTACTIC_ERROR.MISSING_METHOD_PARAMETERS
//         ^
// [cfe] A setter should have exactly one formal parameter.
  var set e, f;
//^^^
// [analyzer] SYNTACTIC_ERROR.VAR_RETURN_TYPE
// [cfe] The return type can't be 'var'.
//        ^
// [analyzer] COMPILE_TIME_ERROR.WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER
// [cfe] A method declaration needs an explicit list of parameters.
//        ^
// [analyzer] SYNTACTIC_ERROR.MISSING_METHOD_PARAMETERS
//         ^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_CLASS_MEMBER
// [cfe] A setter should have exactly one formal parameter.
//         ^
// [analyzer] SYNTACTIC_ERROR.MISSING_FUNCTION_BODY
// [cfe] Expected '{' before this.
//         ^
// [cfe] Expected a class member, but got ','.
//           ^
// [analyzer] SYNTACTIC_ERROR.MISSING_CONST_FINAL_VAR_OR_TYPE
// [cfe] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
}

class C1 {
  List get;
  List get a => null;
  List get b, c;
  //        ^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_CLASS_MEMBER
  // [cfe] Expected '{' before this.
  //        ^
  // [analyzer] SYNTACTIC_ERROR.MISSING_FUNCTION_BODY
  // [cfe] Expected a class member, but got ','.
  //          ^
  // [analyzer] SYNTACTIC_ERROR.MISSING_CONST_FINAL_VAR_OR_TYPE
  // [cfe] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.

  List set;
  List set d;
//^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_VOID_RETURN_FOR_SETTER
// [cfe] The return type of the setter must be 'void' or absent.
//^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONCRETE_CLASS_WITH_ABSTRACT_MEMBER
//         ^
// [analyzer] COMPILE_TIME_ERROR.WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER
// [cfe] A method declaration needs an explicit list of parameters.
//         ^
// [analyzer] SYNTACTIC_ERROR.MISSING_METHOD_PARAMETERS
//          ^
// [cfe] A setter should have exactly one formal parameter.
  List set e, f;
//^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_VOID_RETURN_FOR_SETTER
// [cfe] The return type of the setter must be 'void' or absent.
//         ^
// [analyzer] COMPILE_TIME_ERROR.WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER
// [cfe] A method declaration needs an explicit list of parameters.
//         ^
// [analyzer] SYNTACTIC_ERROR.MISSING_METHOD_PARAMETERS
//          ^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_CLASS_MEMBER
// [cfe] A setter should have exactly one formal parameter.
//          ^
// [analyzer] SYNTACTIC_ERROR.MISSING_FUNCTION_BODY
// [cfe] Expected '{' before this.
//          ^
// [cfe] Expected a class member, but got ','.
//            ^
// [analyzer] SYNTACTIC_ERROR.MISSING_CONST_FINAL_VAR_OR_TYPE
// [cfe] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
}

class C2 {
  List<int> get;
  List<int> get a => null;
  List<int> get b, c;
  //             ^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_CLASS_MEMBER
  // [cfe] Expected '{' before this.
  //             ^
  // [analyzer] SYNTACTIC_ERROR.MISSING_FUNCTION_BODY
  // [cfe] Expected a class member, but got ','.
  //               ^
  // [analyzer] SYNTACTIC_ERROR.MISSING_CONST_FINAL_VAR_OR_TYPE
  // [cfe] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.

  List<int> set;
  List<int> set d;
//^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_VOID_RETURN_FOR_SETTER
// [cfe] The return type of the setter must be 'void' or absent.
//^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONCRETE_CLASS_WITH_ABSTRACT_MEMBER
//              ^
// [analyzer] COMPILE_TIME_ERROR.WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER
// [cfe] A method declaration needs an explicit list of parameters.
//              ^
// [analyzer] SYNTACTIC_ERROR.MISSING_METHOD_PARAMETERS
//               ^
// [cfe] A setter should have exactly one formal parameter.
  List<int> set e, f;
//^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_VOID_RETURN_FOR_SETTER
// [cfe] The return type of the setter must be 'void' or absent.
//              ^
// [analyzer] COMPILE_TIME_ERROR.WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER
// [cfe] A method declaration needs an explicit list of parameters.
//              ^
// [analyzer] SYNTACTIC_ERROR.MISSING_METHOD_PARAMETERS
//               ^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_CLASS_MEMBER
// [cfe] A setter should have exactly one formal parameter.
//               ^
// [analyzer] SYNTACTIC_ERROR.MISSING_FUNCTION_BODY
// [cfe] Expected '{' before this.
//               ^
// [cfe] Expected a class member, but got ','.
//                 ^
// [analyzer] SYNTACTIC_ERROR.MISSING_CONST_FINAL_VAR_OR_TYPE
// [cfe] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
}

main() {
  new C0();
  new C1();
  new C2();
}
