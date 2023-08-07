// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'ir.dart';

mixin Indexable {
  static int _globalId = 0;
  late final int _id = _globalId++;

  FinalizableIndex get finalizableIndex;

  /// [index] will be valid only after finalization, otherwise invoking this
  /// getter will throw.
  int get index => finalizableIndex.value;

  /// [name] will always be valid, though it may not be unique and should only
  /// be used for debugging. Subclasses should override [name] when they can
  /// provide a better alternative.
  String get name => '$_id';
}
