// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@JS()
library lib;

import 'package:js/js.dart';
import 'package:meta/dart2js.dart';

@JS()
@anonymous
class GenericClass<T> {
  external factory GenericClass();

  external set setter(value);
}

main() {
  method();
}

@tryInline
method() {
  new GenericClass().setter = 42;
}
