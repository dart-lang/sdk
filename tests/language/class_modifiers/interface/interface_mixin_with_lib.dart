// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=class-modifiers

// Allow interface mixins to be mixed by multiple classes in the same library.

interface mixin InterfaceMixin {
  int foo = 0;
}

interface mixin MixinForEnum {}

abstract class A with InterfaceMixin {}

class B with InterfaceMixin {}

enum EnumInside implements MixinForEnum { x }
