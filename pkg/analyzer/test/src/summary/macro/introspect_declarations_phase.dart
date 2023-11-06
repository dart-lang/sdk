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
    final buffer = StringBuffer();
    final sink = TreeStringSink(
      sink: buffer,
      indent: '',
    );

    final printer = _Printer(
      sink: sink,
      withDetailsFor: {
        declaration.identifier.name,
        ...withDetailsFor.cast(),
      },
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

  @override
  Future<void> buildDeclarationsForMixin(
    IntrospectableMixinDeclaration declaration,
    MemberDeclarationBuilder builder,
  ) async {
    final buffer = StringBuffer();
    final sink = TreeStringSink(
      sink: buffer,
      indent: '',
    );

    final printer = _Printer(
      sink: sink,
      withDetailsFor: {
        declaration.identifier.name,
        ...withDetailsFor.cast(),
      },
      declarationPhaseIntrospector: builder,
    );
    await printer.writeMixinDeclaration(declaration);
    final text = buffer.toString();

    final resultName = 'introspect_${declaration.identifier.name}';
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

  final Set<String> withDetailsFor;
  final DeclarationPhaseIntrospector declarationPhaseIntrospector;

  Identifier? _enclosingDeclarationIdentifier;

  _Printer({
    required this.sink,
    required this.withDetailsFor,
    required this.declarationPhaseIntrospector,
  });

  Future<void> writeClassDeclaration(IntrospectableClassDeclaration e) async {
    if (!_shouldWriteDetailsFor(e)) {
      return;
    }

    sink.writelnWithIndent('class ${e.identifier.name}');

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
      await writeMetadata(e);
      if (e.superclass case final superclass?) {
        await _writeNamedTypeAnnotation('superclass', superclass);
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

  Future<void> writeMixinDeclaration(IntrospectableMixinDeclaration e) async {
    if (!_shouldWriteDetailsFor(e)) {
      return;
    }

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
    return withDetailsFor.contains(declaration.identifier.name);
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
      await writeMetadata(e);
      await _writeNamedTypeAnnotation('type', e.type);
    });
  }

  Future<void> _writeNamedTypeAnnotation(
    String name,
    TypeAnnotation? type,
  ) async {
    sink.writeWithIndent('$name: ');
    await _writeTypeAnnotation(type);
  }

  Future<void> _writeTypeAnnotation(TypeAnnotation? type) async {
    if (type != null) {
      sink.writeln(type.asString);
      await _writeTypeAnnotationDeclaration(type);
    } else {
      sink.writeln('null');
    }
  }

  Future<void> _writeTypeAnnotationDeclaration(TypeAnnotation type) async {
    await sink.withIndent(() async {
      switch (type) {
        case NamedTypeAnnotation():
          final identifier = type.identifier;
          try {
            final declaration = await declarationPhaseIntrospector
                .typeDeclarationOf(identifier);
            switch (declaration) {
              case IntrospectableClassDeclaration():
                await writeClassDeclaration(declaration);
              case IntrospectableMixinDeclaration():
                await writeMixinDeclaration(declaration);
              default:
                throw UnimplementedError('${declaration.runtimeType}');
            }
          } on ArgumentError {
            sink.writelnWithIndent('noDeclaration');
          }
        default:
          throw UnimplementedError('(${type.runtimeType}) $type');
      }
    });
  }

  Future<void> _writeTypeAnnotations(
    String name,
    Iterable<TypeAnnotation> types,
  ) async {
    await sink.writeElements(name, types, (type) async {
      sink.writeIndent();
      await _writeTypeAnnotation(type);
    });
  }

  Future<void> _writeTypeParameter(TypeParameterDeclaration e) async {
    sink.writelnWithIndent(e.identifier.name);

    await sink.withIndent(() async {
      final bound = e.bound;
      if (bound != null) {
        await _writeNamedTypeAnnotation('bound', bound);
      }
    });
  }

  Future<void> _writeTypeParameters(
    Iterable<TypeParameterDeclaration> elements,
  ) async {
    await sink.writeElements('typeParameters', elements, _writeTypeParameter);
  }
}
