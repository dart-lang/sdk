// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../base/lookup_result.dart';
import '../builder/builder.dart';
import '../kernel/internal_ast.dart';

abstract class VariableBuilder implements Builder, LookupResult {
  InternalVariable get variable;

  bool get isConst;

  bool get isFinal;

  bool get isLate;

  bool get isAssignable;

  bool get isPrimaryConstructorParameter;
}
