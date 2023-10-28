// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:_fe_analyzer_shared/src/macros/api.dart';

import 'introspect_shared.dart';

/*macro*/ class IntrospectDeclarationsPhaseMacro
    implements ClassDeclarationsMacro {
  final Set<Object?> withDetailsFor;

  const IntrospectDeclarationsPhaseMacro({
    this.withDetailsFor = const {},
  });

  @override
  Future<void> buildDeclarationsForClass(
    IntrospectableClassDeclaration declaration,
    MemberDeclarationBuilder builder,
  ) async {
    final buffer = StringBuffer();
    final sink = TreeStringSink(
      sink: buffer,
      indent: '',
    );

    final printer = _DeclarationPrinter(
      sink: sink,
      withDetailsFor: withDetailsFor.cast(),
      declarationPhaseIntrospector: builder,
    );
    await printer.writeClassDeclaration(declaration);
    final text = buffer.toString();

    final resultName = 'introspect_${declaration.identifier.name}';
    builder.declareInLibrary(
      DeclarationCode.fromString(
        'const $resultName = r"""$text""";',
      ),
    );
  }
}

class _DeclarationPrinter {
  final TreeStringSink sink;
  final Set<String> withDetailsFor;
  final DeclarationPhaseIntrospector declarationPhaseIntrospector;

  Identifier? _enclosingDeclarationIdentifier;

  _DeclarationPrinter({
    required this.sink,
    required this.withDetailsFor,
    required this.declarationPhaseIntrospector,
  });

  Future<void> writeClassDeclaration(IntrospectableClassDeclaration e) async {
    sink.writelnWithIndent('class ${e.identifier.name}');

    if (!_shouldWriteDetailsFor(e)) {
      return;
    }

    await sink.withIndent(() async {
      await sink.writeFlags({
        'hasAbstract': e.hasAbstract,
        'hasBase': e.hasBase,
        'hasExternal': e.hasExternal,
        'hasFinal': e.hasFinal,
        'hasInterface': e.hasInterface,
        'hasMixin': e.hasMixin,
        'hasSealed': e.hasSealed,
      });

      final superAnnotation = e.superclass;
      if (superAnnotation != null) {
        final superIdentifier = superAnnotation.identifier;
        sink.writelnWithIndent('superclass');
        try {
          final superDeclaration = await declarationPhaseIntrospector
                  .typeDeclarationOf(superIdentifier)
              as IntrospectableClassDeclaration;
          await sink.withIndent(() => writeClassDeclaration(superDeclaration));
        } on ArgumentError {
          await sink.withIndent(() async {
            sink.writelnWithIndent('notType ${superIdentifier.name}');
          });
        }
      }

      await _writeTypeParameters(e.typeParameters);
      await _writeTypeAnnotations('mixins', e.mixins);
      await _writeTypeAnnotations('interfaces', e.interfaces);

      _enclosingDeclarationIdentifier = e.identifier;
      await sink.writeElements<FieldDeclaration>(
        'fields',
        await declarationPhaseIntrospector.fieldsOf(e),
        _writeField,
      );
    });
  }

  void _assertEnclosingClass(MemberDeclaration e) {
    if (e.definingType != _enclosingDeclarationIdentifier) {
      throw StateError('Mismatch: definingClass');
    }
  }

  bool _shouldWriteDetailsFor(Declaration declaration) {
    return withDetailsFor.isEmpty ||
        withDetailsFor.contains(declaration.identifier.name);
  }

  Future<void> _writeField(FieldDeclaration e) async {
    _assertEnclosingClass(e);

    sink.writelnWithIndent(e.identifier.name);

    await sink.withIndent(() async {
      await sink.writeFlags({
        'hasExternal': e.hasExternal,
        'hasFinal': e.hasFinal,
        'hasLate': e.hasLate,
        'isStatic': e.isStatic,
      });
      _writeTypeAnnotation('type', e.type);
    });
  }

  void _writeTypeAnnotation(String name, TypeAnnotation? type) {
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
    await sink.writeElements(name, elements, _writeTypeAnnotationLine);
  }

  Future<void> _writeTypeParameter(TypeParameterDeclaration e) async {
    sink.writelnWithIndent(e.identifier.name);

    await sink.withIndent(() async {
      final bound = e.bound;
      if (bound != null) {
        _writeTypeAnnotation('bound', bound);
      }
    });
  }

  Future<void> _writeTypeParameters(
    Iterable<TypeParameterDeclaration> elements,
  ) async {
    await sink.writeElements('typeParameters', elements, _writeTypeParameter);
  }
}
