// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library kernel.transformations.closure_conversion;

import '../ast.dart' show Class, Program, Library;

import '../core_types.dart' show CoreTypes;

import 'closure/converter.dart' show ClosureConverter;

import 'closure/info.dart' show ClosureInfo;

import 'closure/invalidate_closures.dart';
import 'closure/mock.dart'
    show mockUpContextForProgram, mockUpContextForLibraries;

Program transformProgram(CoreTypes coreTypes, Program program) {
  var info = new ClosureInfo();
  info.visitProgram(program);

  Class contextClass = mockUpContextForProgram(coreTypes, program);
  var convert = new ClosureConverter(coreTypes, info, contextClass);
  program = convert.visitProgram(program);
  return new InvalidateClosures().visitProgram(program);
}

void transformLibraries(CoreTypes coreTypes, List<Library> libraries) {
  var info = new ClosureInfo();
  for (var library in libraries) {
    info.visitLibrary(library);
  }

  Class contextClass = mockUpContextForLibraries(coreTypes, libraries);
  var convert = new ClosureConverter(coreTypes, info, contextClass);
  for (int i = 0; i < libraries.length; i++) {
    libraries[i] = convert.visitLibrary(libraries[i]);
  }
  var invalidator = new InvalidateClosures();
  for (int i = 0; i < libraries.length; i++) {
    invalidator.visitLibrary(libraries[i]);
  }
}
