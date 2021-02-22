// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class RenderFoo extends RenderObject {
  FooConstraints get constraints => super.constraints as FooConstraints;
}

class FooConstraints extends Constraints {
  String get axis => "hello";
}

class Constraints {}

class RenderObject {
  Constraints get constraints => new Constraints();
  RenderObject get renderObject => this;
}
