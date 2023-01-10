// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=class-modifiers

base class BaseClass {}

abstract class A extends BaseClass {}

class B extends BaseClass {}

base mixin BaseMixin {}

class C extends BaseClass with BaseMixin {}

class D with BaseMixin {}
