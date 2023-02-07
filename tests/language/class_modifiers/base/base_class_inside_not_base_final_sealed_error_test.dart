// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=class-modifiers

// Error when subtyping a base class where the subtype is not base, final or
// sealed.

base class BaseClass {}
base mixin BaseMixin {}

class Extends extends BaseClass {}
// ^
// [analyzer] unspecified
// [cfe] unspecified

class Implements implements BaseClass {}
// ^
// [analyzer] unspecified
// [cfe] unspecified

mixin MixinImplements implements BaseMixin {}
// ^
// [analyzer] unspecified
// [cfe] unspecified

class With with BaseMixin {}
// ^
// [analyzer] unspecified
// [cfe] unspecified

mixin On on BaseClass {}
// ^
// [analyzer] unspecified
// [cfe] unspecified
