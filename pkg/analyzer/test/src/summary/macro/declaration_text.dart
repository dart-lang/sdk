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
  Future<void> buildTypesForClass(declaration, builder) async {
    final buffer = StringBuffer();
    final sink = TreeStringSink(
      sink: buffer,
      indent: '',
    );

    final printer = _DeclarationPrinter(
      sink: sink,
    );
    await printer.writeClassDeclaration(declaration);
    final text = buffer.toString();

    builder.declareType(
      'x',
      DeclarationCode.fromString(
        'const x = r"""$text""";',
      ),
    );
  }

  @override
  Future<void> buildTypesForMethod(method, builder) async {
    final buffer = StringBuffer();
    final sink = TreeStringSink(
      sink: buffer,
      indent: '',
    );

    final printer = _DeclarationPrinter(
      sink: sink,
    );
    await printer.writeMethodDeclaration(method);
    final text = buffer.toString();

    builder.declareType(
      'x',
      DeclarationCode.fromString(
        'const x = r"""$text""";',
      ),
    );
  }
}

class _DeclarationPrinter {
  final TreeStringSink sink;

  _DeclarationPrinter({
    required this.sink,
  });

  Future<void> writeClassDeclaration(ClassDeclaration e) async {
    sink.writelnWithIndent('class ${e.identifier.name}');

    await sink.withIndent(() async {
      await sink.writeFlags({
        'hasAbstract': e.hasAbstract,
        'hasExternal': e.hasExternal,
      });

      var superclass = e.superclass;
      if (superclass != null) {
        await _writeTypeAnnotation('superclass', superclass);
      }

      await _writeTypeParameters(e.typeParameters);
      await _writeTypeAnnotations('mixins', e.mixins);
      await _writeTypeAnnotations('interfaces', e.interfaces);
    });
  }

  Future<void> writeMethodDeclaration(MethodDeclaration e) async {
    sink.writelnWithIndent(e.identifier.name);

    await sink.withIndent(() async {
      await sink.writeFlags({
        'hasAbstract': e.hasAbstract,
        'hasBody': e.hasBody,
        'hasExternal': e.hasExternal,
        'isGetter': e.isGetter,
        'isOperator': e.isOperator,
        'isSetter': e.isSetter,
        'isStatic': e.isStatic,
      });

      await _writeMetadata(e);
      await _writeNamedFormalParameters(e.namedParameters);
      await _writePositionalFormalParameters(e.positionalParameters);
      await _writeTypeAnnotation('returnType', e.returnType);
      await _writeTypeParameters(e.typeParameters);
    });
  }

  Future<void> _writeFormalParameter(ParameterDeclaration e) async {
    sink.writelnWithIndent(e.identifier.name);
    await sink.withIndent(() async {
      await sink.writeFlags({
        'isNamed': e.isNamed,
        'isRequired': e.isRequired,
      });
      await _writeTypeAnnotation('type', e.type);
    });
  }

  Future<void> _writeMetadata(Annotatable e) async {
    await sink.writeElements(
      'metadata',
      e.metadata,
      _writeMetadataAnnotation,
    );
  }

  Future<void> _writeMetadataAnnotation(MetadataAnnotation e) async {
    // TODO(scheglov) implement
  }

  Future<void> _writeNamedFormalParameters(
    Iterable<ParameterDeclaration> elements,
  ) async {
    await sink.writeElements(
      'namedParameters',
      elements,
      _writeFormalParameter,
    );
  }

  Future<void> _writePositionalFormalParameters(
    Iterable<ParameterDeclaration> elements,
  ) async {
    await sink.writeElements(
      'positionalParameters',
      elements,
      _writeFormalParameter,
    );
  }

  Future<void> _writeTypeAnnotation(String name, TypeAnnotation? type) async {
    sink.writeWithIndent('$name: ');

    if (type != null) {
      sink.writeln(type.asString);
    } else {
      sink.writeln('null');
    }
  }

  Future<void> _writeTypeAnnotationLine(TypeAnnotation type) async {
    sink.writelnWithIndent(type.asString);
  }

  Future<void> _writeTypeAnnotations(
    String name,
    Iterable<TypeAnnotation> elements,
  ) async {
    await sink.writeElements(
      name,
      elements,
      _writeTypeAnnotationLine,
    );
  }

  Future<void> _writeTypeParameter(TypeParameterDeclaration e) async {
    sink.writelnWithIndent(e.identifier.name);

    await sink.withIndent(() async {
      var bound = e.bound;
      if (bound != null) {
        await _writeTypeAnnotation('bound', bound);
      }
    });
  }

  Future<void> _writeTypeParameters(
    Iterable<TypeParameterDeclaration> elements,
  ) async {
    await sink.writeElements(
      'typeParameters',
      elements,
      _writeTypeParameter,
    );
  }
}
