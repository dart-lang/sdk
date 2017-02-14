// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library kernel.transformations.closure_conversion;

import '../ast.dart' show Class, Program;

import '../core_types.dart' show CoreTypes;

import 'closure/converter.dart' show ClosureConverter;

import 'closure/info.dart' show ClosureInfo;

import 'closure/invalidate_closures.dart';
import 'closure/mock.dart' show mockUpContext;

Program transformProgram(Program program) {
  var info = new ClosureInfo();
  info.visitProgram(program);

  CoreTypes coreTypes = new CoreTypes(program);
  Class contextClass = mockUpContext(coreTypes, program);
  var convert = new ClosureConverter(coreTypes, info, contextClass);
  program = convert.visitProgram(program);
  return new InvalidateClosures().visitProgram(program);
}
