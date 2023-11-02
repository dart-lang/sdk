// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=inline-class

import "dart:async" show FutureOr;

// Extension type declarations must have a "representation declaration"
// of the form: '(' <metadata> <type> <identifier> ')'
//
// Any type term is allowed.

// Any special, or semi-special, type is allowed.
extension type V01(dynamic _) {}
extension type V02(void _) {}
extension type V03(Never _) {}
//                 ^^^^^
// [analyzer] COMPILE_TIME_ERROR.EXTENSION_TYPE_REPRESENTATION_TYPE_BOTTOM
//                       ^
// [cfe] The representation type can't be a bottom type.
extension type V04(Null _) {}
extension type V05(Function _) {}
extension type V06(Record _) {}
extension type V07(Type _) {}
extension type V08(Object? _) {}
extension type V09(FutureOr<int> _) {}
extension type V10(FutureOr<int>? _) {}

// Interface types.
extension type V11(List<int> _) {}
extension type V12(IType _) {}
extension type V13(FType _) {}
extension type V14(SType _) {}
extension type V15(MType _) {}
extension type V16(EType _) {}

// Extension types.
extension type V17(ExtType _) {}

// Record types.
extension type V18(() _) {}
extension type V19((int,) _) {}
extension type V20(({int x}) _) {}
extension type V21((int, String) _) {}
extension type V22((int, {String x}) _) {}
extension type V23(({int x, String y}) _) {}

// Function types
extension type V24(Function() _) {}
extension type V25(void Function() _) {}
extension type V26(void Function(int) _) {}
extension type V27(void Function(int x) _) {}
extension type V28(void Function(int, String) _) {}
extension type V29(void Function(int, [String]) _) {}
extension type V30(void Function([int, String]) _) {}
extension type V31(void Function(int, {String y}) _) {}
extension type V32(void Function({int x, String y}) _) {}
extension type V33(void Function(int, {required String y}) _) {}
extension type V34(void Function({required int x, String y}) _) {}
extension type V35(Function Function(Function) Function() _) {}

// Type variables
extension type V36<T>(T _) {}
extension type V37<T>(List<T> _) {}
extension type V38<T>(FutureOr<T?>? _) {}

// Type aliases
extension type V39(AType _) {}
extension type V40(A<IType> _) {}
extension type V41(A<FType> _) {}
extension type V42(A<SType> _) {}
extension type V43(A<MType> _) {}
extension type V44(A<EType> _) {}
extension type V45(A<ExtType> _) {}

// And can be created.
void main() {
  V01(1)._;
  V02(1)._;
  try {
    V03(0 as Never)._;
  } on Error {
    // Expected!
  }
  V04(null)._;
  V05(() {})._;
  V06(())._;
  V07(int)._;
  V08(1)._;
  V09(1)._;
  V10(1)._;
  V11([])._;
  V12(instance)._;
  V13(instance)._;
  V14(instance)._;
  V15(instance)._;
  V16(instance)._;
  V17(ExtType(int))._;
  V18(())._;
  V19((1,))._;
  V20((x: 1))._;
  V21((1, "2"))._;
  V22((1, x: "2"))._;
  V23((x: 1, y: "2"))._;
  V24(() {})._;
  V25(() {})._;
  V26((int x) {})._;
  V27((int x) {})._;
  V28((int x, String y) {})._;
  V29((int x, [String y = "0"]) {})._;
  V30(([int x = 0, String y = "0"]) {})._;
  V31((int x, {String y = "0"}) {})._;
  V32(({int x = 0, String y = "0"}) {})._;
  V33((int x, {required String y}) {})._;
  V34(({required int x, String y = "0"}) {})._;
  V35(() => (Function f) => f)._;
  V36<Type>(int)._;
  V37<Type>([int])._;
  V38<Type>(int)._;
  V39(int)._;
  V40(instance)._;
  V41(instance)._;
  V42(instance)._;
  V43(instance)._;
  V44(instance)._;
  V45(ExtType(int))._;
}

// Helpers.
extension type ExtType(Type x) implements Type {}

abstract interface class IType implements Type {}

mixin MType implements Type {}

sealed class SType with MType {}

final class FType extends SType implements IType {}

enum EType implements FType { e }

typedef A<X> = X;
typedef AType = Type;
const instance = EType.e;
