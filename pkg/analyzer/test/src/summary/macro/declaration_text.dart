// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:_fe_analyzer_shared/src/macros/api.dart';

/*macro*/ class DeclarationTextMacro implements ClassTypesMacro {
  const DeclarationTextMacro();

  @override
  FutureOr<void> buildTypesForClass(declaration, builder) {
    final printer = _DeclarationPrinter();
    printer.writeClassDeclaration(declaration);
    final text = printer._sink.toString();

    builder.declareType(
      'x',
      DeclarationCode.fromString(
        'const x = r"""$text""";',
      ),
    );
  }
}

class _DeclarationPrinter {
  final StringBuffer _sink = StringBuffer();
  String _indent = '';

  void writeClassDeclaration(ClassDeclaration e) {
    _writeIf(e.isAbstract, 'abstract ');
    _writeIf(e.isExternal, 'external ');

    _writeln('class ${e.identifier.name}');

    _withIndent(() {
      var superclass = e.superclass;
      if (superclass != null) {
        _writeType('superclass', superclass);
      }
    });
  }

  void _withIndent(void Function() f) {
    var savedIndent = _indent;
    _indent = '$savedIndent  ';
    f();
    _indent = savedIndent;
  }

  void _writeIf(bool flag, String str) {
    if (flag) {
      _sink.write(str);
    }
  }

  void _writeln(String line) {
    _sink.writeln(line);
  }

  void _writeType(String name, TypeAnnotation? type) {
    _sink.write(_indent);
    _sink.write('$name: ');

    if (type != null) {
      _writeln(_typeStr(type));
    } else {
      _writeln('null');
    }
  }

  static String _typeStr(TypeAnnotation type) {
    final buffer = StringBuffer();
    _TypeStringBuilder(buffer).write(type);
    return buffer.toString();
  }
}

class _TypeStringBuilder {
  final StringSink _sink;

  _TypeStringBuilder(this._sink);

  void write(TypeAnnotation type) {
    if (type is NamedTypeAnnotation) {
      _sink.write(type.identifier.name);
      _writeList(type.typeArguments, ', ', write, open: '<', close: '>');
    } else {
      throw UnimplementedError('(${type.runtimeType}) $type');
    }
    if (type.isNullable) {
      _sink.write('?');
    }
  }

  void _writeList<T>(
    Iterable<T> elements,
    String separator,
    void Function(T element) write, {
    String? open,
    String? close,
  }) {
    elements = elements.toList();
    if (elements.isNotEmpty) {
      if (open != null) {
        _sink.write(open);
      }
      var isFirst = true;
      for (var element in elements) {
        if (isFirst) {
          isFirst = false;
        } else {
          _sink.write(separator);
        }
        write(element);
      }
      if (close != null) {
        _sink.write(close);
      }
    }
  }
}
