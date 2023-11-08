// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:_fe_analyzer_shared/src/macros/api.dart';

import 'introspect_shared.dart';

/*macro*/ class IntrospectTypesPhaseMacro
    implements ClassTypesMacro, MethodTypesMacro, MixinTypesMacro {
  const IntrospectTypesPhaseMacro();

  @override
  Future<void> buildTypesForClass(declaration, builder) async {
    await _write(builder, (printer) async {
      await printer.writeClassDeclaration(declaration);
    });
  }

  @override
  Future<void> buildTypesForMethod(declaration, builder) async {
    await _write(builder, (printer) async {
      await printer.writeMethodDeclaration(declaration);
    });
  }

  @override
  Future<void> buildTypesForMixin(declaration, builder) async {
    await _write(builder, (printer) async {
      await printer.writeMixinDeclaration(declaration);
    });
  }

  Future<void> _write(
    TypeBuilder builder,
    Future<void> Function(_Printer printer) f,
  ) async {
    final buffer = StringBuffer();
    final sink = TreeStringSink(
      sink: buffer,
      indent: '',
    );

    final printer = _Printer(
      sink: sink,
      introspector: builder,
    );
    await f(printer);
    final text = buffer.toString();

    builder.declareType(
      'x',
      DeclarationCode.fromString(
        'const x = r"""$text""";',
      ),
    );
  }
}

class _Printer with SharedPrinter {
  @override
  final TreeStringSink sink;

  @override
  final TypePhaseIntrospector introspector;

  _Printer({
    required this.sink,
    required this.introspector,
  });
}
