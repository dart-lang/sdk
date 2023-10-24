// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:_fe_analyzer_shared/src/macros/api.dart';

import 'introspect_shared.dart';

/*macro*/ class DeclarationTextMacro
    implements ClassTypesMacro, MethodTypesMacro {
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

  @override
  FutureOr<void> buildTypesForMethod(method, builder) {
    final printer = _DeclarationPrinter();
    printer.writeMethodDeclaration(method);
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
    _writeIf(e.hasAbstract, 'abstract ');
    _writeIf(e.hasExternal, 'external ');

    _writeln('class ${e.identifier.name}');

    _withIndent(() {
      var superclass = e.superclass;
      if (superclass != null) {
        _writeTypeAnnotation('superclass', superclass);
      }

      _writeTypeParameters(e.typeParameters);
      _writeTypeAnnotations('mixins', e.mixins);
      _writeTypeAnnotations('interfaces', e.interfaces);
    });
  }

  void writeIndent() {
    _sink.write(_indent);
  }

  /// TODO(scheglov) Copy TreeStringSink here
  void writeIndentedLine(void Function() f) {
    writeIndent();
    f();
    writeln();
  }

  void writeln([Object? object = '']) {
    _sink.writeln(object);
  }

  void writeMethodDeclaration(MethodDeclaration e) {
    _writelnWithIndent(e.identifier.name);

    _withIndent(() {
      _writeFlags({
        'hasAbstract': e.hasAbstract,
        'hasBody': e.hasBody,
        'hasExternal': e.hasExternal,
        'isGetter': e.isGetter,
        'isOperator': e.isOperator,
        'isSetter': e.isSetter,
        'isStatic': e.isStatic,
      });

      _writeMetadata(e);
      _writeNamedFormalParameters(e.namedParameters);
      _writePositionalFormalParameters(e.positionalParameters);
      _writeTypeAnnotation('returnType', e.returnType);
      _writeTypeParameters(e.typeParameters);
    });
  }

  void _withIndent(void Function() f) {
    var savedIndent = _indent;
    _indent = '$savedIndent  ';
    f();
    _indent = savedIndent;
  }

  void _writeElements<T>(
    String name,
    Iterable<T> elements,
    void Function(T) f,
  ) {
    if (elements.isNotEmpty) {
      _writelnWithIndent(name);
      _withIndent(() {
        for (var element in elements) {
          f(element);
        }
      });
    }
  }

  void _writeFlags(Map<String, bool> flags) {
    if (flags.values.any((flag) => flag)) {
      writeIndentedLine(() {
        _sink.write('flags:');
        for (final entry in flags.entries) {
          if (entry.value) {
            _sink.write(' ${entry.key}');
          }
        }
      });
    }
  }

  void _writeFormalParameter(ParameterDeclaration e) {
    _writelnWithIndent(e.identifier.name);
    _withIndent(() {
      _writeFlags({
        'isNamed': e.isNamed,
        'isRequired': e.isRequired,
      });
      _writeTypeAnnotation('type', e.type);
    });
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

  void _writeMetadata(Annotatable e) {
    _writeElements('metadata', e.metadata, _writeMetadataAnnotation);
  }

  void _writeMetadataAnnotation(MetadataAnnotation e) {
    // TODO(scheglov) implement
  }

  void _writeNamedFormalParameters(
    Iterable<ParameterDeclaration> elements,
  ) {
    _writeElements('namedParameters', elements, _writeFormalParameter);
  }

  void _writePositionalFormalParameters(
    Iterable<ParameterDeclaration> elements,
  ) {
    _writeElements('positionalParameters', elements, _writeFormalParameter);
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

  void _writeTypeAnnotationLine(TypeAnnotation type) {
    _writelnWithIndent(type.asString);
  }

  void _writeTypeAnnotations(String name, Iterable<TypeAnnotation> elements) {
    _writeElements(name, elements, _writeTypeAnnotationLine);
  }

  void _writeTypeParameter(TypeParameterDeclaration e) {
    _writelnWithIndent(e.identifier.name);

    _withIndent(() {
      var bound = e.bound;
      if (bound != null) {
        _writeTypeAnnotation('bound', bound);
      }
    });
  }

  void _writeTypeParameters(Iterable<TypeParameterDeclaration> elements) {
    _writeElements('typeParameters', elements, _writeTypeParameter);
  }
}
