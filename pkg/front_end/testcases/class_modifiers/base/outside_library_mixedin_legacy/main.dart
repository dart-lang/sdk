// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.19

// Tests that it's a compile-time error if a class declaration from a
// pre-feature library mixes in a mixin marked `base` in a
// post-feature library, but is not marked 'base', 'final' or 'sealed'.

import 'main_lib.dart';

class WithBaseMixinClass with BaseMixinClass {}

class WithAbstractBaseMixinClass with AbstractBaseMixinClass {}

class WithBaseMixin with BaseMixin {}

abstract class AbstractWithBaseMixinClass with BaseMixinClass {}

abstract class AbstractWithAbstractBaseMixinClass with AbstractBaseMixinClass {}

abstract class AbstractWithBaseMixin with BaseMixin {}
