// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=class-modifiers

final class FinalClass {}

abstract class A extends FinalClass {}

class B extends FinalClass {}

final mixin FinalMixin {}

class C extends FinalClass with FinalMixin {}

class D with FinalMixin {}
