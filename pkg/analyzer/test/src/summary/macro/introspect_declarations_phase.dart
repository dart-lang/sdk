// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:_fe_analyzer_shared/src/macros/api.dart';

import 'introspect_shared.dart';

/*macro*/ class IntrospectDeclarationsPhaseMacro
    implements ClassDeclarationsMacro, MixinDeclarationsMacro {
  final Set<Object?> withDetailsFor;

  const IntrospectDeclarationsPhaseMacro({
    this.withDetailsFor = const {},
  });

  @override
  Future<void> buildDeclarationsForClass(
    IntrospectableClassDeclaration declaration,
    MemberDeclarationBuilder builder,
  ) async {
    await _write(builder, declaration, (printer) async {
      await printer.writeClassDeclaration(declaration);
    });
  }

  @override
  Future<void> buildDeclarationsForMixin(
    IntrospectableMixinDeclaration declaration,
    MemberDeclarationBuilder builder,
  ) async {
    await _write(builder, declaration, (printer) async {
      await printer.writeMixinDeclaration(declaration);
    });
  }

  Future<void> _write(
    DeclarationBuilder builder,
    Declaration declaration,
    Future<void> Function(_Printer printer) f,
  ) async {
    final declarationName = declaration.identifier.name;

    final buffer = StringBuffer();
    final sink = TreeStringSink(
      sink: buffer,
      indent: '',
    );

    final printer = _Printer(
      sink: sink,
      introspector: builder,
      withDetailsFor: {
        declarationName,
        ...withDetailsFor.cast(),
      },
    );
    await f(printer);
    final text = buffer.toString();

    final resultName = 'introspect_$declarationName';
    builder.declareInLibrary(
      DeclarationCode.fromString(
        'const $resultName = r"""$text""";',
      ),
    );
  }
}

class _Printer with SharedPrinter {
  @override
  final TreeStringSink sink;

  @override
  final DeclarationPhaseIntrospector introspector;

  final Set<String> withDetailsFor;

  _Printer({
    required this.sink,
    required this.introspector,
    required this.withDetailsFor,
  });

  @override
  bool shouldWriteDetailsFor(Declaration declaration) {
    return withDetailsFor.contains(declaration.identifier.name);
  }
}
