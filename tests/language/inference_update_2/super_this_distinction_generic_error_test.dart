// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that field promotion distinguishes `this` accesses from `super`
// accesses when they resolve to different fields.

// In this test, the fields in question have generic types. This is an important
// special case to test because the analyzer uses special "Member" data
// structures to track accesses to fields with generic types.

// Most of the functionality is tested in
// `super_this_distinction_generic_test.dart`. This "error" test exists solely
// to verify that the implementation properly tracks promotions when determining
// whether it's legal to invoke a member whose type is a nullable function type.

class Base<T> {
  final T Function()? _f;
  Base(this._f);
}

// In this class, `_f` overrides the declaration of `_f` in `super`, so their
// promotions should be tracked separately.
class DerivedClassThatOverridesBaseMembers<T> extends Base<T> {
  final T Function()? _f;
  DerivedClassThatOverridesBaseMembers(this._f, T Function()? superF)
      : super(superF);

  void invokedVariableGet() {
    _f();
//  ^^
// [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
//    ^
// [cfe] Can't use an expression of type 'T Function()?' as a function because it's potentially null.
    this._f();
//  ^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
//         ^
// [cfe] Can't use an expression of type 'T Function()?' as a function because it's potentially null.
    super._f();
//  ^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
//          ^
// [cfe] Can't use an expression of type 'T Function()?' as a function because it's potentially null.
    if (_f != null) {
      _f();
      this._f();
      super._f();
//    ^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
//            ^
// [cfe] Can't use an expression of type 'T Function()?' as a function because it's potentially null.
    }
    if (this._f != null) {
      _f();
      this._f();
      super._f();
//    ^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
//            ^
// [cfe] Can't use an expression of type 'T Function()?' as a function because it's potentially null.
    }
    if (super._f != null) {
      _f();
//    ^^
// [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
//      ^
// [cfe] Can't use an expression of type 'T Function()?' as a function because it's potentially null.
      this._f();
//    ^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
//           ^
// [cfe] Can't use an expression of type 'T Function()?' as a function because it's potentially null.
      super._f();
    }
  }
}

/// In this class, `this._f` and `super._f` refer to the same field. However,
/// they still promote independently, since this is simpler to implement, has no
/// soundness problems, and is unlikely to cause problems in real-world code.
class DerivedClassThatOverridesNothing<T> extends Base<T> {
  DerivedClassThatOverridesNothing(super._f);

  void invokedVariableGet() {
    _f();
//  ^^
// [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
//    ^
// [cfe] Can't use an expression of type 'T Function()?' as a function because it's potentially null.
    this._f();
//  ^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
//         ^
// [cfe] Can't use an expression of type 'T Function()?' as a function because it's potentially null.
    super._f();
//  ^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
//          ^
// [cfe] Can't use an expression of type 'T Function()?' as a function because it's potentially null.
    if (_f != null) {
      _f();
      this._f();
      super._f();
//    ^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
//            ^
// [cfe] Can't use an expression of type 'T Function()?' as a function because it's potentially null.
    }
    if (this._f != null) {
      _f();
      this._f();
      super._f();
//    ^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
//            ^
// [cfe] Can't use an expression of type 'T Function()?' as a function because it's potentially null.
    }
    if (super._f != null) {
      _f();
//    ^^
// [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
//      ^
// [cfe] Can't use an expression of type 'T Function()?' as a function because it's potentially null.
      this._f();
//    ^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
//           ^
// [cfe] Can't use an expression of type 'T Function()?' as a function because it's potentially null.
      super._f();
    }
  }
}

main() {}
