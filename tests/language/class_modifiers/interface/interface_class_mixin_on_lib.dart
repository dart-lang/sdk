// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=class-modifiers

interface class InterfaceClass {}

abstract class A extends InterfaceClass {}

class B extends InterfaceClass {}

interface mixin InterfaceMixin {}

class C extends InterfaceClass with InterfaceMixin {}

class D with InterfaceMixin {}
