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
    final buffer = StringBuffer();
    final sink = TreeStringSink(
      sink: buffer,
      indent: '',
    );

    final printer = _Printer(
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

    final printer = _Printer(
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

  @override
  Future<void> buildTypesForMixin(declaration, builder) async {
    final buffer = StringBuffer();
    final sink = TreeStringSink(
      sink: buffer,
      indent: '',
    );

    final printer = _Printer(
      sink: sink,
    );
    await printer.writeMixinDeclaration(declaration);
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

  _Printer({
    required this.sink,
  });

  Future<void> writeClassDeclaration(ClassDeclaration e) async {
    sink.writelnWithIndent('class ${e.identifier.name}');

    await sink.withIndent(() async {
      await sink.writeFlags({
        'hasAbstract': e.hasAbstract,
        'hasExternal': e.hasExternal,
      });

      await writeMetadata(e);
      await _writeTypeParameters(e.typeParameters);
      if (e.superclass case final superclass?) {
        await _writeTypeAnnotation('superclass', superclass);
      }
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

      await writeMetadata(e);
      await _writeNamedFormalParameters(e.namedParameters);
      await _writePositionalFormalParameters(e.positionalParameters);
      await _writeTypeAnnotation('returnType', e.returnType);
      await _writeTypeParameters(e.typeParameters);
    });
  }

  Future<void> writeMixinDeclaration(MixinDeclaration e) async {
    sink.writelnWithIndent('mixin ${e.identifier.name}');

    await sink.withIndent(() async {
      await sink.writeFlags({
        'hasBase': e.hasBase,
      });

      await writeMetadata(e);
      await _writeTypeParameters(e.typeParameters);
      await _writeTypeAnnotations(
        'superclassConstraints',
        e.superclassConstraints,
      );
      await _writeTypeAnnotations('interfaces', e.interfaces);
    });
  }

  Future<void> _writeFormalParameter(ParameterDeclaration e) async {
    sink.writelnWithIndent(e.identifier.name);
    await sink.withIndent(() async {
      await sink.writeFlags({
        'isNamed': e.isNamed,
        'isRequired': e.isRequired,
      });
      await writeMetadata(e);
      await _writeTypeAnnotation('type', e.type);
    });
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
      await writeMetadata(e);
      if (e.bound case final bound?) {
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
