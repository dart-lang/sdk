// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension type ET1(int i) {} // Ok

extension type ET2(var int i) {} // Error

extension type ET3(final int i) {}

extension type ET4(i) {}

extension type ET5(var i) {} // Error

extension type ET6(final i) {}
