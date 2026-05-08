// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension type ET0(var a); // Error

extension type ET1(var bool a); // Error

extension type ET2(final int a, int b); // Error

extension type ET3(final int a, [bool? b]); // Error

extension type ET4([final int it = 42, bool? b]); // Error

extension type ET5(final int? a, {bool? b}); // Error

extension type ET6({final int? a, bool? b}); // Error

extension type ET7({final int a = 42, bool b = true}); // Error

extension type ET8({required final int a, required int b}); // Error

extension type ET9(covariant int a); // Error

extension type ET10(late int a); // Error

extension type ET11(external int a); // Error

extension type ET12(const int a); // Error

extension type ET13(required int a); // Error

extension type ET14(); // Error
