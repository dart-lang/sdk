// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'nodes.dart';

abstract class OptimizationPhase {
  String get name;
  void visitGraph(HGraph graph);
  bool validPostcondition(HGraph graph);
}
