// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@string
@symbol
library test.typedef_metadata_test;

import 'dart:mirrors';

import 'metadata_test.dart';

class S {}

class M {}

@symbol
class MA = S with M;

@string
typedef bool Predicate(Object o);

main() {
  checkMetadata(reflectType(MA), [symbol]);
  checkMetadata(reflectType(Predicate), [string]);
}
