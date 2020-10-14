// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A<T extends num> {}

typedef FArgument<X extends num> = Function(X);
typedef FReturn<X extends num> = X Function();
typedef FBoth<X extends num> = X Function(X);
typedef FNowhere<X extends num> = Function();

foo() {
  A<Object> aObject; // Error.
  A<num?> aNumNullable; // Error.
  A<int?> aIntNullable; // Error.
  A<Null> aNull; // Error.
  FArgument<Object> fArgumentObject; // Error.
  FArgument<num?> fArgumentNumNullable; // Error.
  FArgument<int?> fArgumentIntNullable; // Error.
  FArgument<Null> fArgumentNull; // Error.
  FReturn<Object> fReturnObject; // Error.
  FReturn<num?> fReturnNumNullable; // Error.
  FReturn<int?> fReturnIntNullable; // Error.
  FReturn<Null> fReturnNull; // Error.
  FBoth<Object> fBothObject; // Error.
  FBoth<num?> fBothNumNullable; // Error.
  FBoth<int?> fBothIntNullable; // Error.
  FBoth<Null> fBothNull; // Error.
  FNowhere<Object> fNowhereObject; // Error.
  FNowhere<num?> fNowhereNumNullable; // Error.
  FNowhere<int?> fNowhereIntNullable; // Error.
  FNowhere<Null> fNowhereNull; // Error.

  A<Object?> aObjectNullable; // Ok.
  A<dynamic> aDynamic; // Ok.
  A<void> aVoid; // Ok.
  A<num> aNum; // Ok.
  A<int> aInt; // Ok.
  A<Never> aNever; // Ok.
  FArgument<Object?> fArgumentObjectNullable; // Ok.
  FArgument<dynamic> fArgumentDynamic; // Ok.
  FArgument<void> fArgumentVoid; // Ok.
  FArgument<num> fArgumentNum; // Ok.
  FArgument<int> fArgumentInt; // Ok.
  FArgument<Never> fArgumentNever; // Ok.
  FReturn<Object?> fReturnObjectNullable; // Ok.
  FReturn<dynamic> fReturnDynamic; // Ok.
  FReturn<void> fReturnVoid; // Ok.
  FReturn<num> fReturnNum; // Ok.
  FReturn<int> fReturnInt; // Ok.
  FReturn<Never> fReturnNever; // Ok.
  FBoth<Object?> fBothObjectNullable; // Ok.
  FBoth<dynamic> fBothDynamic; // Ok.
  FBoth<void> fBothVoid; // Ok.
  FBoth<num> fBothNum; // Ok.
  FBoth<int> fBothInt; // Ok.
  FBoth<Never> fBothNever; // Ok.
  FNowhere<Object?> fNowhereObjectNullable; // Ok.
  FNowhere<dynamic> fNowhereDynamic; // Ok.
  FNowhere<void> fNowhereVoid; // Ok.
  FNowhere<num> fNowhereNum; // Ok.
  FNowhere<int> fNowhereInt; // Ok.
  FNowhere<Never> fNowhereNever; // Ok.
}

main() {}
