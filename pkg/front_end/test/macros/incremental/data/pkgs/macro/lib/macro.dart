// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:_fe_analyzer_shared/src/macros/api.dart';

macro

class ToStringMacro implements ClassDeclarationsMacro {
  const ToStringMacro();

  @override
  FutureOr<void> buildDeclarationsForClass(IntrospectableClassDeclaration clazz,
      MemberDeclarationBuilder builder) async {
    Iterable<MethodDeclaration> methods = await builder.methodsOf(clazz);
    if (!methods.any((m) => m.identifier.name == 'toString')) {
      Iterable<FieldDeclaration> fields = await builder.fieldsOf(clazz);
      Uri dartCore = Uri.parse('dart:core');
      Identifier stringClass =
      await builder.resolveIdentifier(dartCore, 'String');
      List<Object> parts = [stringClass, '''
 toString() {
    return "${clazz.identifier.name}('''
      ];
      String comma = '';
      for (FieldDeclaration field in fields) {
        parts.add(comma);
        parts.add('${field.identifier.name}=\${');
        parts.add(field.identifier.name);
        parts.add('}');
        comma = ',';
      }
      parts.add(''')";
  }''');
      builder.declareInType(new DeclarationCode.fromParts(parts));
    }
  }
}

macro

class InjectMacro implements ClassDeclarationsMacro {
  const InjectMacro();

  @override
  FutureOr<void> buildDeclarationsForClass(IntrospectableClassDeclaration clazz,
      MemberDeclarationBuilder builder) async {
    Iterable<MethodDeclaration> methods = await builder.methodsOf(clazz);
    if (!methods.any((m) => m.identifier.name == 'injectedMethod')) {
      builder.declareInType(new DeclarationCode.fromString('''
 void injectedMethod() {}'''));
    }
  }
}
