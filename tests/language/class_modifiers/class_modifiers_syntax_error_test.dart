// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Syntax errors when having more than one modifier or an invalid ordering of
// modifiers.

// Duplicate modifiers
sealed sealed class SealedSealed {}
// [error column 1, length 6]
// [analyzer] COMPILE_TIME_ERROR.NOT_A_TYPE
// [cfe] 'sealed' isn't a type.
// [cfe] Can't use 'sealed' because it is declared more than once.
//     ^^^^^^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [cfe] Expected ';' after this.
final final class FinalFinal {}
// [error column 1, length 5]
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [cfe] Expected ';' after this.
//    ^^^^^
// [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
// [analyzer] COMPILE_TIME_ERROR.FINAL_NOT_INITIALIZED
// [cfe] Expected an identifier, but got 'final'.
base base class BaseBase {}
// [error column 1, length 4]
// [analyzer] COMPILE_TIME_ERROR.NOT_A_TYPE
// [cfe] 'base' isn't a type.
// [cfe] Can't use 'base' because it is declared more than once.
//   ^^^^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [cfe] Expected ';' after this.
interface interface class InterfaceInterface {}
// [error column 1, length 9]
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [analyzer] SYNTACTIC_ERROR.MISSING_CONST_FINAL_VAR_OR_TYPE
// [cfe] Expected ';' after this.
// [cfe] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.

// Invalid ordering with 'abstract' and another modifier
final abstract class FinalAbstract {}
//    ^^^^^^^^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [analyzer] SYNTACTIC_ERROR.EXTRANEOUS_MODIFIER
// [analyzer] SYNTACTIC_ERROR.MODIFIER_OUT_OF_ORDER
// [cfe] Can't have modifier 'abstract' here.
// [cfe] Expected ';' after this.
// [cfe] The modifier 'abstract' should be before the modifier 'final'.
//             ^^^^^
// [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
// [analyzer] COMPILE_TIME_ERROR.FINAL_NOT_INITIALIZED
// [cfe] Expected an identifier, but got 'class'.
base abstract class BaseAbstract {}
// [error column 1, length 4]
// [analyzer] COMPILE_TIME_ERROR.NOT_A_TYPE
// [cfe] 'base' isn't a type.
// [cfe] Can't use 'base' because it is declared more than once.
//   ^^^^^^^^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [cfe] Expected ';' after this.
interface abstract class InterfaceAbstract {}
// [error column 1, length 9]
// [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [analyzer] SYNTACTIC_ERROR.MISSING_CONST_FINAL_VAR_OR_TYPE
// [cfe] 'interface' is already declared in this scope.
// [cfe] Expected ';' after this.
// [cfe] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.

// Invalid ways to write '[abstract] base mixin class'
mixin base class MixinBase {}
//    ^^^^
// [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION
// [analyzer] SYNTACTIC_ERROR.EXPECTED_BODY
// [cfe] 'base' is already declared in this scope.
// [cfe] A mixin declaration must have a body, even if it is empty.
mixin base abstract class MixinBaseAbstract {}
//    ^^^^
// [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION
// [analyzer] SYNTACTIC_ERROR.EXPECTED_BODY
// [cfe] 'base' is already declared in this scope.
// [cfe] A mixin declaration must have a body, even if it is empty.
mixin abstract base class MixinAbstractBase {}
//    ^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.BUILT_IN_IDENTIFIER_IN_DECLARATION
// [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION
// [analyzer] SYNTACTIC_ERROR.EXPECTED_BODY
// [cfe] 'abstract' is already declared in this scope.
// [cfe] A mixin declaration must have a body, even if it is empty.
// [cfe] Can't use 'abstract' as a name here.
abstract mixin base class AbstractMixinBase {}
// [error column 1, length 8]
// [analyzer] SYNTACTIC_ERROR.EXTRANEOUS_MODIFIER
// [cfe] Can't have modifier 'abstract' here.
//             ^^^^
// [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION
// [analyzer] SYNTACTIC_ERROR.EXPECTED_BODY
// [cfe] 'base' is already declared in this scope.
// [cfe] A mixin declaration must have a body, even if it is empty.
base mixin abstract class BaseMixinAbstract {}
//         ^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.BUILT_IN_IDENTIFIER_IN_DECLARATION
// [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION
// [analyzer] SYNTACTIC_ERROR.EXPECTED_BODY
// [cfe] 'abstract' is already declared in this scope.
// [cfe] A mixin declaration must have a body, even if it is empty.
// [cfe] Can't use 'abstract' as a name here.
base abstract mixin class BaseAbstractMixin {}
// [error column 1, length 4]
// [analyzer] COMPILE_TIME_ERROR.NOT_A_TYPE
// [cfe] 'base' isn't a type.
// [cfe] Can't use 'base' because it is declared more than once.
//   ^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [cfe] 'abstract' is already declared in this scope.
// [cfe] Expected ';' after this.

// Mixin classes with invalid modifiers
sealed mixin class SealedMixinClass {}
// [error column 1, length 6]
// [analyzer] SYNTACTIC_ERROR.SEALED_MIXIN_CLASS
// [cfe] A mixin class can't be declared 'sealed'.
final mixin class FinalMixinClass {}
// [error column 1, length 5]
// [analyzer] SYNTACTIC_ERROR.FINAL_MIXIN_CLASS
// [cfe] A mixin class can't be declared 'final'.
interface mixin class InterfaceMixinClass {}
// [error column 1, length 9]
// [analyzer] SYNTACTIC_ERROR.INTERFACE_MIXIN_CLASS
// [cfe] A mixin class can't be declared 'interface'.

// Invalid ordering + invalid modifiers for mixin classes
mixin sealed class MixinSealedClass {}
//    ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION
// [analyzer] SYNTACTIC_ERROR.EXPECTED_BODY
// [cfe] 'sealed' is already declared in this scope.
// [cfe] A mixin declaration must have a body, even if it is empty.
mixin final class MixinFinalClass {}
//    ^^^^^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_BODY
// [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
// [cfe] A mixin declaration must have a body, even if it is empty.
// [cfe] Expected an identifier, but got 'final'.
mixin interface class MixinInterfaceClass {}
//    ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.BUILT_IN_IDENTIFIER_IN_DECLARATION
// [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION
// [analyzer] SYNTACTIC_ERROR.EXPECTED_BODY
// [cfe] 'interface' is already declared in this scope.
// [cfe] A mixin declaration must have a body, even if it is empty.
// [cfe] Can't use 'interface' as a name here.

// Mixins with invalid modifiers
sealed mixin SealedMixin {}
// [error column 1, length 6]
// [analyzer] SYNTACTIC_ERROR.SEALED_MIXIN
// [cfe] A mixin can't be declared 'sealed'.
final mixin FinalMixin {}
// [error column 1, length 5]
// [analyzer] SYNTACTIC_ERROR.FINAL_MIXIN
// [cfe] A mixin can't be declared 'final'.
interface mixin InterfaceMixin {}
// [error column 1, length 9]
// [analyzer] SYNTACTIC_ERROR.INTERFACE_MIXIN
// [cfe] A mixin can't be declared 'interface'.

// Invalid ordering + invalid modifiers for mixin
mixin sealed MixinSealed {}
//    ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION
// [cfe] 'sealed' is already declared in this scope.
//           ^^^^^^^^^^^
// [analyzer] SYNTACTIC_ERROR.UNEXPECTED_TOKEN
// [cfe] Unexpected token 'MixinSealed'.
mixin final MixinFinal {}
//    ^^^^^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_BODY
// [analyzer] SYNTACTIC_ERROR.EXTRANEOUS_MODIFIER
// [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
// [cfe] A mixin declaration must have a body, even if it is empty.
// [cfe] Can't have modifier 'final' here.
// [cfe] Expected an identifier, but got 'final'.
//          ^^^^^^^^^^
// [analyzer] SYNTACTIC_ERROR.MISSING_FUNCTION_PARAMETERS
// [cfe] A function declaration needs an explicit list of parameters.
mixin interface MixinInterface {}
//    ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.BUILT_IN_IDENTIFIER_IN_DECLARATION
// [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION
// [cfe] 'interface' is already declared in this scope.
// [cfe] Can't use 'interface' as a name here.
//              ^^^^^^^^^^^^^^
// [analyzer] SYNTACTIC_ERROR.UNEXPECTED_TOKEN
// [cfe] Unexpected token 'MixinInterface'.

// Multiple modifiers
sealed final class SealedFinal {}
// [error column 1, length 6]
// [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [analyzer] SYNTACTIC_ERROR.MISSING_CONST_FINAL_VAR_OR_TYPE
// [cfe] 'sealed' is already declared in this scope.
// [cfe] Expected ';' after this.
// [cfe] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
sealed base class SealedBase {}
// [error column 1, length 6]
// [analyzer] COMPILE_TIME_ERROR.NOT_A_TYPE
// [cfe] 'sealed' isn't a type.
// [cfe] Can't use 'sealed' because it is declared more than once.
//     ^^^^
// [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [cfe] 'base' is already declared in this scope.
// [cfe] Expected ';' after this.
sealed interface class SealedInterface {}
// [error column 1, length 6]
// [analyzer] COMPILE_TIME_ERROR.NOT_A_TYPE
// [cfe] 'sealed' isn't a type.
// [cfe] Can't use 'sealed' because it is declared more than once.
//     ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [cfe] 'interface' is already declared in this scope.
// [cfe] Expected ';' after this.
final sealed class FinalSealed {}
//    ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION
// [analyzer] COMPILE_TIME_ERROR.FINAL_NOT_INITIALIZED
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [cfe] 'sealed' is already declared in this scope.
// [cfe] Expected ';' after this.
// [cfe] The final variable 'sealed' must be initialized.
final base class FinalBase {}
//    ^^^^
// [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION
// [analyzer] COMPILE_TIME_ERROR.FINAL_NOT_INITIALIZED
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [cfe] 'base' is already declared in this scope.
// [cfe] Expected ';' after this.
// [cfe] The final variable 'base' must be initialized.
final interface class FinalInterface {}
//    ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION
// [analyzer] COMPILE_TIME_ERROR.FINAL_NOT_INITIALIZED
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [cfe] 'interface' is already declared in this scope.
// [cfe] Expected ';' after this.
// [cfe] The final variable 'interface' must be initialized.
base sealed class BaseSealed {}
// [error column 1, length 4]
// [analyzer] COMPILE_TIME_ERROR.NOT_A_TYPE
// [cfe] 'base' isn't a type.
// [cfe] Can't use 'base' because it is declared more than once.
//   ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [cfe] 'sealed' is already declared in this scope.
// [cfe] Expected ';' after this.
base final class BaseFinal {}
// [error column 1, length 4]
// [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [analyzer] SYNTACTIC_ERROR.MISSING_CONST_FINAL_VAR_OR_TYPE
// [cfe] 'base' is already declared in this scope.
// [cfe] Expected ';' after this.
// [cfe] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
base interface class BaseInterface {}
// [error column 1, length 4]
// [analyzer] COMPILE_TIME_ERROR.NOT_A_TYPE
// [cfe] 'base' isn't a type.
// [cfe] Can't use 'base' because it is declared more than once.
//   ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [cfe] 'interface' is already declared in this scope.
// [cfe] Expected ';' after this.
interface sealed class InterfaceSealed {}
// [error column 1, length 9]
// [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [analyzer] SYNTACTIC_ERROR.MISSING_CONST_FINAL_VAR_OR_TYPE
// [cfe] 'interface' is already declared in this scope.
// [cfe] Expected ';' after this.
// [cfe] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
interface final class InterfaceFinal {}
// [error column 1, length 9]
// [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [analyzer] SYNTACTIC_ERROR.MISSING_CONST_FINAL_VAR_OR_TYPE
// [cfe] 'interface' is already declared in this scope.
// [cfe] Expected ';' after this.
// [cfe] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
interface base class InterfaceBase {}
// [error column 1, length 9]
// [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [analyzer] SYNTACTIC_ERROR.MISSING_CONST_FINAL_VAR_OR_TYPE
// [cfe] 'interface' is already declared in this scope.
// [cfe] Expected ';' after this.
// [cfe] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
