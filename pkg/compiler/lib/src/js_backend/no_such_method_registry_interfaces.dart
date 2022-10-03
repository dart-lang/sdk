// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../common.dart';
import '../elements/entities.dart';
import '../inferrer/types_interfaces.dart';

abstract class NoSuchMethodRegistry {
  void registerNoSuchMethod(FunctionEntity noSuchMethodElement);
  void onQueueEmpty();
  bool get hasThrowingNoSuchMethod;
  bool get hasComplexNoSuchMethod;
}

abstract class NoSuchMethodData {
  bool isComplex(FunctionEntity element);
  void categorizeComplexImplementations(GlobalTypeInferenceResults results);
  void emitDiagnostic(DiagnosticReporter reporter);
}
