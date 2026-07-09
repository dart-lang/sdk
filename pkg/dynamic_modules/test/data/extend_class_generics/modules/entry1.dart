// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../shared/shared.dart';

class Child<T> extends Base<T> {
  final T t;
  Child(this.t);

  @override
  T method1() => t;
}

@pragma('dyn-module:entry-point')
Object? dynamicModuleEntrypoint() => Child(3);
