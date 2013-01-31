// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library type_test_helper;

import "../../../sdk/lib/_internal/compiler/implementation/dart2jslib.dart";
import '../../../sdk/lib/_internal/compiler/implementation/dart_types.dart';
import "../../../sdk/lib/_internal/compiler/implementation/elements/elements.dart";
import "../../../sdk/lib/_internal/compiler/implementation/tree/tree.dart";
import "../../../sdk/lib/_internal/compiler/implementation/util/util.dart";
import "compiler_helper.dart";
import "dart:uri";

InterfaceType instantiate(ClassElement element, List<DartType> arguments) {
  return new InterfaceType(element, new Link<DartType>.fromList(arguments));
}

class TypeEnvironment {
  final Compiler compiler;

  factory TypeEnvironment(String source) {
    var uri = new Uri.fromComponents(scheme: 'source');
    Compiler compiler = compilerFor('''
        main() {}
        $source''',
        uri);
    compiler.runCompiler(uri);
    return new TypeEnvironment._(compiler);
  }

  TypeEnvironment._(Compiler this.compiler);

  Element getElement(String name) {
    var element = findElement(compiler, name);
    Expect.isNotNull(element);
    if (identical(element.kind, ElementKind.CLASS)) {
      element.ensureResolved(compiler);
    }
    return element;
  }

  DartType getElementType(String name) {
    return getElement(name).computeType(compiler);
  }

  DartType operator[] (String name) {
    if (name == 'dynamic') return compiler.types.dynamicType;
    return getElementType(name);
  }

  bool isSubtype(DartType T, DartType S) {
    return compiler.types.isSubtype(T, S);
  }
}
