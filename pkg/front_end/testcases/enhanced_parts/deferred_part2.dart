// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'deferred_part1.dart';

import 'deferred_lib2.dart' deferred as d;

method2() {
  d.loadLibrary();
}
