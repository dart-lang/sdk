// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/library_graph.dart';

extension LibraryCycleExtensions on LibraryCycle {
  /// The number of libraries in the cycle.
  int get size => libraries.length;
}
