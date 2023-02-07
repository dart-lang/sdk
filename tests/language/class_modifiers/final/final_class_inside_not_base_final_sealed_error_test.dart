// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=class-modifiers

// Error when subtyping a final class where the subtype is not base, final or
// sealed.

final class FinalClass {}
final mixin FinalMixin {}

class Extends extends FinalClass {}
// ^
// [analyzer] unspecified
// [cfe] unspecified

class Implements implements FinalClass {}
// ^
// [analyzer] unspecified
// [cfe] unspecified

mixin MixinImplements implements FinalMixin {}
// ^
// [analyzer] unspecified
// [cfe] unspecified

class With with FinalMixin {}
// ^
// [analyzer] unspecified
// [cfe] unspecified

mixin On on FinalClass {}
// ^
// [analyzer] unspecified
// [cfe] unspecified
