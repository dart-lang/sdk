// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Make sure errors are emitted when trying to use interface classes without
// the `class-modifiers` experiment enabled.

interface class InterfaceClass {}
// ^
// [analyzer] unspecified
// [cfe] unspecified

mixin M {}
interface class InterfaceClassTypeAlias = Object with M;
// ^
// [analyzer] unspecified
// [cfe] unspecified

interface mixin InterfaceMixin {}
// ^
// [analyzer] unspecified
// [cfe] unspecified
