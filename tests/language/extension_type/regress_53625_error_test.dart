// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression check for https://dartbug.com/53625
//
// Extension type declarations must have a "representation declaration"
// of the form: '(' <metadata> <type> <identifier> ')'
// where `<metadata>` can be empty, the other two not.
//
// Any other format is (currently) disallowed.


// The "representation declaration" is like the parameter list of
// an implicit constructor.
// It still does not accept any other parameter list shape than the above.

extension type E00(int) {}
//                 ^^^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_REPRESENTATION_TYPE
// [cfe] Expected a representation type.

extension type E01(int x,) {}
//                      ^
// [analyzer] SYNTACTIC_ERROR.REPRESENTATION_FIELD_TRAILING_COMMA
// [cfe] The representation field can't have a trailing comma.

extension type E02(final int x) {}
//                 ^^^^^
// [analyzer] SYNTACTIC_ERROR.REPRESENTATION_FIELD_MODIFIER
//                           ^
// [cfe] Representation fields can't have modifiers.

extension type E03(var x) {}
//                 ^^^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_REPRESENTATION_TYPE
// [analyzer] SYNTACTIC_ERROR.REPRESENTATION_FIELD_MODIFIER
//                     ^
// [cfe] Expected a representation type.

extension type E04(final x) {}
//                 ^^^^^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_REPRESENTATION_TYPE
// [analyzer] SYNTACTIC_ERROR.REPRESENTATION_FIELD_MODIFIER
//                       ^
// [cfe] Expected a representation type.
// [cfe] Representation fields can't have modifiers.

extension type E05(covariant int x) {}
//                 ^^^^^^^^^
// [analyzer] SYNTACTIC_ERROR.EXTRANEOUS_MODIFIER_IN_PRIMARY_CONSTRUCTOR
// [cfe] Can't have modifier 'covariant' in a primary constructor.

extension type E06(required int x) {}
//                 ^^^^^^^^
// [analyzer] SYNTACTIC_ERROR.EXTRANEOUS_MODIFIER
// [cfe] Can't have modifier 'required' here.

extension type E07(int this.x) {} // Initializing formal.
//                 ^^^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_REPRESENTATION_FIELD
//                          ^
// [cfe] Primary constructors in extension types can't use initializing formals.

extension type E08(this.x) {} // Initializing formal.
//                 ^^^^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_REPRESENTATION_FIELD
//                      ^
// [cfe] Expected a representation type.
// [cfe] Primary constructors in extension types can't use initializing formals.

extension type E09(int super.x) implements E {} // Constructor super-parameter.
//                 ^^^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_REPRESENTATION_FIELD
//                           ^
// [cfe] Extension type constructors can't declare super formal parameters.

extension type E10(super.x) implements E {} // Constructor super-parameter.
//                 ^^^^^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_REPRESENTATION_FIELD
//                       ^
// [cfe] Expected a representation type.
// [cfe] Extension type constructors can't declare super formal parameters.

extension type E11(int x()) {} // Old-style function parameter syntax.
//                 ^^^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_REPRESENTATION_FIELD
//                     ^
// [cfe] Primary constructors in extension types can't use function formal parameter syntax.

// The "primary parameter" declares a "field",
// but still does not accept field modifiers or initializers.

extension type E12(late int x) {}
//                 ^^^^
// [analyzer] SYNTACTIC_ERROR.EXTRANEOUS_MODIFIER
// [cfe] Can't have modifier 'late' here.

extension type E13(int x = 0) {}
//                 ^^^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_REPRESENTATION_FIELD
//                       ^
// [analyzer] SYNTACTIC_ERROR.NAMED_PARAMETER_OUTSIDE_GROUP
// [cfe] Non-optional parameters can't have a default value.

extension type E14(static int x) {}
//                 ^^^^^^
// [analyzer] SYNTACTIC_ERROR.EXTRANEOUS_MODIFIER
// [cfe] Can't have modifier 'static' here.

extension type const E15(const int x) {}
//                       ^^^^^
// [analyzer] SYNTACTIC_ERROR.EXTRANEOUS_MODIFIER
// [cfe] Can't have modifier 'const' here.
//                                 ^
// [cfe] Representation fields can't have modifiers.

// Precisely one parameter is allowed and required.

extension type E16() {}
//                ^
// [cfe] Expected a representation field.
//                 ^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_REPRESENTATION_FIELD

extension type E17(int x, String y) {}
//                ^
// [cfe] Each extension type should have exactly one representation field.
//                      ^
// [analyzer] SYNTACTIC_ERROR.MULTIPLE_REPRESENTATION_FIELDS

extension type E18(int x, [String y = "2"]) {}
//                      ^
// [analyzer] SYNTACTIC_ERROR.MULTIPLE_REPRESENTATION_FIELDS
//                                ^
// [cfe] Extension type declarations can't have optional parameters.

extension type E19(int x, {required String y}) {}
//                      ^
// [analyzer] SYNTACTIC_ERROR.MULTIPLE_REPRESENTATION_FIELDS
//                                         ^
// [cfe] Extension type declarations can't have named parameters.

extension type E20(int x, {String y = "2"}) {}
//                      ^
// [analyzer] SYNTACTIC_ERROR.MULTIPLE_REPRESENTATION_FIELDS
//                                ^
// [cfe] Extension type declarations can't have named parameters.

extension type E21([int x = 0]) {}
//                 ^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_REPRESENTATION_FIELD
//                      ^
// [cfe] Extension type declarations can't have optional parameters.

extension type E22([int x = 0, int y = 0]) {}
//                 ^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_REPRESENTATION_FIELD
//                                 ^
// [cfe] Extension type declarations can't have optional parameters.

extension type E23({required int x}) {}
//                 ^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_REPRESENTATION_FIELD
//                               ^
// [cfe] Extension type declarations can't have named parameters.

extension type E24({int x = 0}) {}
//                 ^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_REPRESENTATION_FIELD
//                      ^
// [cfe] Extension type declarations can't have named parameters.

extension type E25({int x = 0, int y = 0}) {}
//                 ^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_REPRESENTATION_FIELD
//                                 ^
// [cfe] Extension type declarations can't have named parameters.

// Annotations are allowed, but only at the start.

extension type E26(@anno int) {}
//                 ^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_REPRESENTATION_TYPE
//                       ^
// [cfe] Expected a representation type.

extension type E27(int @anno x) {}
//                 ^^^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_REPRESENTATION_TYPE
// [cfe] Expected a representation type.
//                     ^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [cfe] Expected ')' before this.

extension type E28(int x @anno) {}
//                       ^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [cfe] Expected ')' before this.


// Helpers
const anno = "Annotation";

extension type E(int x) {}

void main() {}
