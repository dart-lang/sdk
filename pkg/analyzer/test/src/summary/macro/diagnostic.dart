// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/macros/api.dart';

/*macro*/ class ThrowExceptionDeclarationsPhase
    implements
        ClassDeclarationsMacro,
        ConstructorDeclarationsMacro,
        FieldDeclarationsMacro,
        MethodDeclarationsMacro {
  const ThrowExceptionDeclarationsPhase();

  @override
  buildDeclarationsForClass(clazz, builder) {
    _doThrow();
  }

  @override
  buildDeclarationsForConstructor(constructor, builder) {
    _doThrow();
  }

  @override
  buildDeclarationsForField(declaration, builder) {
    _doThrow();
  }

  @override
  buildDeclarationsForMethod(method, builder) {
    _doThrow();
  }

  void _doThrow() {
    throw 'My declarations phase';
  }
}

/*macro*/ class ThrowExceptionDefinitionsPhase implements ClassDefinitionMacro {
  const ThrowExceptionDefinitionsPhase();

  @override
  buildDefinitionForClass(clazz, builder) {
    _doThrow();
  }

  void _doThrow() {
    throw 'My definitions phase';
  }
}

/*macro*/ class ThrowExceptionTypesPhase implements ClassTypesMacro {
  const ThrowExceptionTypesPhase();

  @override
  buildTypesForClass(clazz, builder) {
    _doThrow();
  }

  void _doThrow() {
    throw 'My types phase';
  }
}
