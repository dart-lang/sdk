// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:_fe_analyzer_shared/src/macros/api.dart';

import 'introspect_shared.dart';

const introspectMacro = IntrospectDeclarationsPhaseMacro();

/*macro*/ class IntrospectDeclarationsPhaseMacro
    implements ClassDeclarationsMacro {
  const IntrospectDeclarationsPhaseMacro();

  @override
  Future<void> buildDeclarationsForClass(
    ClassDeclaration declaration,
    ClassMemberDeclarationBuilder builder,
  ) async {
    final printer = _DeclarationPrinter(
      classIntrospector: builder,
      typeResolver: builder,
    );
    await printer.writeClassDeclaration(declaration);
    final text = printer._sink.toString();

    final resultName = 'introspect_${declaration.identifier.name}';
    builder.declareInLibrary(
      DeclarationCode.fromString(
        'const $resultName = r"""$text""";',
      ),
    );
  }
}

class _DeclarationPrinter {
  final ClassIntrospector classIntrospector;
  final TypeResolver typeResolver;
  final StringBuffer _sink = StringBuffer();
  String _indent = '';

  _DeclarationPrinter({
    required this.classIntrospector,
    required this.typeResolver,
  });

  Future<void> writeClassDeclaration(ClassDeclaration e) async {
    _sink.write(_indent);
    _writeIf(e.isAbstract, 'abstract ');
    _writeIf(e.isExternal, 'external ');

    _writeln('class ${e.identifier.name}');

    await _withIndent(() async {
      var superclass = await classIntrospector.superclassOf(e);
      if (superclass != null) {
        _writelnWithIndent('superclass');
        await _withIndent(() => writeClassDeclaration(superclass));
      }

      await _writeTypeParameters(e.typeParameters);
      await _writeTypeAnnotations('mixins', e.mixins);
      await _writeTypeAnnotations('interfaces', e.interfaces);
    });
  }

  Future<void> _withIndent(Future<void> Function() f) async {
    var savedIndent = _indent;
    _indent = '$savedIndent  ';
    await f();
    _indent = savedIndent;
  }

  Future<void> _writeElements<T>(
    String name,
    Iterable<T> elements,
    Future<void> Function(T) f,
  ) async {
    if (elements.isNotEmpty) {
      _writelnWithIndent(name);
      await _withIndent(() async {
        for (var element in elements) {
          await f(element);
        }
      });
    }
  }

  void _writeIf(bool flag, String str) {
    if (flag) {
      _sink.write(str);
    }
  }

  void _writeln(String line) {
    _sink.writeln(line);
  }

  void _writelnWithIndent(String line) {
    _sink.write(_indent);
    _sink.writeln(line);
  }

  void _writeTypeAnnotation(String name, TypeAnnotation? type) {
    _sink.write(_indent);
    _sink.write('$name: ');

    if (type != null) {
      _writeln(type.asString);
    } else {
      _writeln('null');
    }
  }

  Future<void> _writeTypeAnnotationLine(TypeAnnotation type) async {
    _writelnWithIndent(type.asString);
  }

  Future<void> _writeTypeAnnotations(
    String name,
    Iterable<TypeAnnotation> elements,
  ) async {
    await _writeElements(name, elements, _writeTypeAnnotationLine);
  }

  Future<void> _writeTypeParameter(TypeParameterDeclaration e) async {
    _writelnWithIndent(e.identifier.name);

    await _withIndent(() async {
      var bound = e.bound;
      if (bound != null) {
        _writeTypeAnnotation('bound', bound);
      }
    });
  }

  Future<void> _writeTypeParameters(
    Iterable<TypeParameterDeclaration> elements,
  ) async {
    await _writeElements('typeParameters', elements, _writeTypeParameter);
  }
}
