// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:js/js.dart';

@JS()
@anonymous
class A {
  external bool get value;
  external factory A({bool value});
}

void main() {}
