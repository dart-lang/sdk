// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:_fe_analyzer_shared/src/macros/api.dart';

macro class FunctionDefinitionMacro1 implements FunctionDefinitionMacro {
  const FunctionDefinitionMacro1();

  FutureOr<void> buildDefinitionForFunction(
      FunctionDeclaration function, FunctionDefinitionBuilder builder) {
      builder.augment(new FunctionBodyCode.fromString('''{
  return 42;
}'''));
  }
}
