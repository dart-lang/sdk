// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' hide MapEntry;
import 'package:kernel/core_types.dart';

import "kernel_type_parser.dart";
import "type_parser.dart";
import "mock_sdk.dart" show mockSdk;

class Env {
  Component component;

  CoreTypes coreTypes;

  KernelEnvironment _libraryEnvironment;

  Env(String source) {
    Uri libraryUri = Uri.parse('memory:main.dart');
    Uri coreUri = Uri.parse("dart:core");
    KernelEnvironment coreEnvironment = new KernelEnvironment(coreUri, coreUri);
    Library coreLibrary =
        parseLibrary(coreUri, mockSdk, environment: coreEnvironment);
    _libraryEnvironment = new KernelEnvironment(libraryUri, libraryUri)
        .extend(coreEnvironment.declarations);
    Library library =
        parseLibrary(libraryUri, source, environment: _libraryEnvironment);
    library.name = "lib";
    component = new Component(libraries: <Library>[coreLibrary, library]);
    coreTypes = new CoreTypes(component);
  }

  DartType parseType(String text) {
    List<ParsedType> types = parse(text);
    return _libraryEnvironment.kernelFromParsedType(types.single);
  }
}
