// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library source_mapping_crash_test;

part 'source_mapping_crash_source.dart';

class Sub extends Super {
  Sub(var x) : super(x.y);
}

class X { var y; }

main() {
  new Sub(new X());
}
