// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:macros/macros.dart';

final _dartCore = Uri(scheme: 'dart', path: 'core');

/*macro*/ class AutoToString
    implements ClassDeclarationsMacro, ClassDefinitionMacro {
  const AutoToString();

  /// We pre-declare the toString override here, but fill it in later in the
  /// definitions phase, where we are guaranteed a full and accurate view of
  /// all the classes members.
  @override
  Future<void> buildDeclarationsForClass(
      ClassDeclaration clazz, MemberDeclarationBuilder builder) async {
    // Give an error if the user wrote their own `toString`, there isn't
    // anything sensible for us to do in this case.
    var methods = await builder.methodsOf(clazz);
    var existingToString =
        methods.where((m) => m.identifier.name == 'toString').firstOrNull;
    if (existingToString != null) {
      throw DiagnosticException(Diagnostic(
          DiagnosticMessage(
              'Cannot generate toString due to existing declaration',
              target: existingToString.asDiagnosticTarget),
          Severity.error));
    }

    var [override, string] = await Future.wait([
      // ignore: deprecated_member_use
      builder.resolveIdentifier(_dartCore, 'override'),
      // ignore: deprecated_member_use
      builder.resolveIdentifier(_dartCore, 'String'),
    ]);
    builder.declareInType(DeclarationCode.fromParts(
        ['  @', override, '\n  ', string, ' toString();']));
  }

  @override
  Future<void> buildDefinitionForClass(
      ClassDeclaration clazz, TypeDefinitionBuilder builder) async {
    // Find the method we want to augment (toString), and get a builder for it.
    var methods = await builder.methodsOf(clazz);
    var toString = methods.firstWhere((m) => m.identifier.name == 'toString');
    var toStringBuilder = await builder.buildMethod(toString.identifier);

    // Finally, we generate the toString based on the field names.
    //
    // Note that we don't surface getters, only true fields. Pure getters would
    // appear in the methods list.
    var fields = await builder.fieldsOf(clazz);
    toStringBuilder.augment(FunctionBodyCode.fromParts([
      '{\n',
      '    // You can add breakpoints here!\n',
      '    return """\n${clazz.identifier.name} {\n',
      for (var field in fields) ...[
        '  ${field.identifier.name}: \${',
        field.identifier,
        '}\n',
      ],
      '}""";\n',
      '  }'
    ]));
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    var iterator = this.iterator;
    if (iterator.moveNext()) return iterator.current;
    return null;
  }
}
