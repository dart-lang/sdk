// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore: import_internal_library
import 'dart:_internal';

@patch
class PatchedClass {
  final int _field;

  /*member: PatchedClass.:
   initializers=[
    FieldInitializer(_field),
    SuperInitializer],
   patch
  */
  @patch
  const PatchedClass({int field: 0}) : _field = field;
}
