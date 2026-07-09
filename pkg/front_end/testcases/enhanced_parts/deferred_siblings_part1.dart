// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'deferred_siblings_lib1.dart' deferred as d;

part of 'deferred_siblings.dart';

method1() {
  d.loadLibrary();
  d.method1();
}
