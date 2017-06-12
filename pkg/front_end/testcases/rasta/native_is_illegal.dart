// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

foo() native "foo";

class Bar {
  Bar get x native "Bar_get_x";
  set x(Bar value) native "Bar_set_x";
  f() native "Bar_f";
  factory Bar() native "Bar_constructor";
}
