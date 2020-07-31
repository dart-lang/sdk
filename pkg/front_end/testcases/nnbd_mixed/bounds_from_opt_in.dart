// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

import 'bounds_from_opt_in_lib.dart';

class LegacyClass<T extends Null> extends Class<T> {
  method<T extends Null>() {}
}

test() {
  Class<Null> c = new Class<Null>();
  c.method<Null>();
  method<Null>();
}

main() {}
