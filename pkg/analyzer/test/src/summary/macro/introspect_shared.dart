// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/macros/api.dart';

abstract class SharedPrinter {
  final TreeStringSink sink;
  final bool withMetadata;

  Identifier? _enclosingDeclarationIdentifier;

  SharedPrinter({
    required this.sink,
    required this.withMetadata,
  });

  TypePhaseIntrospector get introspector;

  bool shouldWriteDetailsFor(Declaration declaration) {
    return true;
  }

  Future<void> writeClassDeclaration(ClassDeclaration e) async {
    if (!shouldWriteDetailsFor(e)) {
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
      await _writeMetadata(e);
      if (e.superclass case final superclass?) {
        await _writeNamedTypeAnnotation('superclass', superclass);
      }
      await _writeTypeParameters(e.typeParameters);
      await _writeTypeAnnotations('mixins', e.mixins);
      await _writeTypeAnnotations('interfaces', e.interfaces);
      await _writeTypeDeclarationMembers(e);
    });
  }

  Future<void> writeField(FieldDeclaration e) async {
    _assertEnclosingClass(e);
    sink.writelnWithIndent(e.identifier.name);

    await sink.withIndent(() async {
      await sink.writeFlags({
        'hasExternal': e.hasExternal,
        'hasFinal': e.hasFinal,
        'hasLate': e.hasLate,
        'isStatic': e.isStatic,
      });
      await _writeMetadata(e);
      await _writeNamedTypeAnnotation('type', e.type);
    });
  }

  Future<void> writeMethodDeclaration(MethodDeclaration e) async {
    _assertEnclosingClass(e);
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
      await _writeNamedTypeAnnotation('returnType', e.returnType);
      await _writeTypeParameters(e.typeParameters);
    });
  }

  Future<void> writeMixinDeclaration(MixinDeclaration e) async {
    if (!shouldWriteDetailsFor(e)) {
      return;
    }

    sink.writelnWithIndent('mixin ${e.identifier.name}');

    await sink.withIndent(() async {
      await sink.writeFlags({
        'hasBase': e.hasBase,
      });

      await _writeMetadata(e);

      await _writeTypeParameters(e.typeParameters);
      await _writeTypeAnnotations(
        'superclassConstraints',
        e.superclassConstraints,
      );
      await _writeTypeAnnotations('interfaces', e.interfaces);
      await _writeTypeDeclarationMembers(e);
    });
  }

  void _assertEnclosingClass(MemberDeclaration e) {
    final enclosing = _enclosingDeclarationIdentifier;
    if (enclosing != null && e.definingType != enclosing) {
      throw StateError('Mismatch: definingClass');
    }
  }

  Future<void> _writeFormalParameter(ParameterDeclaration e) async {
    sink.writelnWithIndent(e.identifier.name);
    await sink.withIndent(() async {
      await sink.writeFlags({
        'isNamed': e.isNamed,
        'isRequired': e.isRequired,
      });
      await _writeMetadata(e);
      await _writeNamedTypeAnnotation('type', e.type);
    });
  }

  Future<void> _writeMetadata(Annotatable e) async {
    if (withMetadata) {
      await sink.writeElements(
        'metadata',
        e.metadata,
        _writeMetadataAnnotation,
      );
    }
  }

  Future<void> _writeMetadataAnnotation(MetadataAnnotation e) async {
    switch (e) {
      case ConstructorMetadataAnnotation():
        sink.writelnWithIndent('ConstructorMetadataAnnotation');
        await sink.withIndent(() async {
          sink.writelnWithIndent('type: ${e.type.name}');
          final constructorName = e.constructor.name;
          if (constructorName.isNotEmpty) {
            sink.writelnWithIndent('constructorName: $constructorName');
          }
        });
      case IdentifierMetadataAnnotation():
        sink.writelnWithIndent('IdentifierMetadataAnnotation');
        await sink.withIndent(() async {
          sink.writelnWithIndent('identifier: ${e.identifier.name}');
        });
      default:
    }
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

  Future<void> _writeNamedTypeAnnotation(
    String name,
    TypeAnnotation? type,
  ) async {
    sink.writeWithIndent('$name: ');
    await _writeTypeAnnotation(type);
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

  Future<void> _writeTypeAnnotation(TypeAnnotation? type) async {
    if (type != null) {
      sink.writeln(type.asString);
      await _writeTypeAnnotationDeclaration(type);
    } else {
      sink.writeln('null');
    }
  }

  Future<void> _writeTypeAnnotationDeclaration(TypeAnnotation type) async {
    final introspector = this.introspector;
    if (introspector is! DeclarationPhaseIntrospector) {
      return;
    }

    await sink.withIndent(() async {
      switch (type) {
        case NamedTypeAnnotation():
          TypeDeclaration declaration;
          try {
            final identifier = type.identifier;
            declaration = await introspector.typeDeclarationOf(identifier);
          } on ArgumentError {
            sink.writelnWithIndent('noDeclaration');
            return;
          }

          switch (declaration) {
            case ClassDeclaration():
              await writeClassDeclaration(declaration);
            case MixinDeclaration():
              await writeMixinDeclaration(declaration);
            default:
              throw UnimplementedError('${declaration.runtimeType}');
          }
        case OmittedTypeAnnotation():
          // No declaration, yet.
          break;
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

  Future<void> _writeTypeDeclarationMembers(TypeDeclaration e) async {
    _enclosingDeclarationIdentifier = e.identifier;

    final introspector = this.introspector;
    if (introspector is DeclarationPhaseIntrospector) {
      if (e is IntrospectableType) {
        await sink.writeElements(
          'fields',
          await introspector.fieldsOf(e),
          writeField,
        );
        await sink.writeElements(
          'methods',
          await introspector.methodsOf(e),
          writeMethodDeclaration,
        );
      }
    }

    _enclosingDeclarationIdentifier = null;
  }

  Future<void> _writeTypeParameter(TypeParameterDeclaration e) async {
    sink.writelnWithIndent(e.identifier.name);

    await sink.withIndent(() async {
      await _writeMetadata(e);
      if (e.bound case final bound?) {
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

/// Wrapper around a [StringSink] for writing tree structures.
class TreeStringSink {
  final StringSink _sink;
  String _indent = '';

  TreeStringSink({
    required StringSink sink,
    required String indent,
  })  : _sink = sink,
        _indent = indent;

  Future<void> withIndent(Future<void> Function() f) async {
    final indent = _indent;
    _indent = '$indent  ';
    await f();
    _indent = indent;
  }

  void write(Object object) {
    _sink.write(object);
  }

  Future<void> writeElements<T extends Object>(
    String name,
    Iterable<T> elements,
    Future<void> Function(T) f,
  ) async {
    if (elements.isNotEmpty) {
      writelnWithIndent(name);
      await withIndent(() async {
        for (final element in elements) {
          await f(element);
        }
      });
    }
  }

  Future<void> writeFlags(Map<String, bool> flags) async {
    if (flags.values.any((flag) => flag)) {
      await writeIndentedLine(() async {
        write('flags:');
        for (final entry in flags.entries) {
          if (entry.value) {
            write(' ${entry.key}');
          }
        }
      });
    }
  }

  void writeIf(bool flag, Object object) {
    if (flag) {
      write(object);
    }
  }

  void writeIndent() {
    _sink.write(_indent);
  }

  Future<void> writeIndentedLine(void Function() f) async {
    writeIndent();
    f();
    writeln();
  }

  void writeln([Object? object = '']) {
    _sink.writeln(object);
  }

  void writelnWithIndent(Object object) {
    _sink.write(_indent);
    _sink.writeln(object);
  }

  void writeWithIndent(Object object) {
    _sink.write(_indent);
    _sink.write(object);
  }
}

class _TypeAnnotationStringBuilder {
  final StringSink _sink;

  _TypeAnnotationStringBuilder(this._sink);

  void write(TypeAnnotation type) {
    if (type is FunctionTypeAnnotation) {
      _writeFunctionTypeAnnotation(type);
    } else if (type is NamedTypeAnnotation) {
      _writeNamedTypeAnnotation(type);
    } else if (type is OmittedTypeAnnotation) {
      _sink.write('OmittedType');
    } else {
      throw UnimplementedError('(${type.runtimeType}) $type');
    }
    if (type.isNullable) {
      _sink.write('?');
    }
  }

  void _writeFormalParameter(FunctionTypeParameter node) {
    final String closeSeparator;
    if (node.isNamed) {
      _sink.write('{');
      closeSeparator = '}';
      if (node.isRequired) {
        _sink.write('required ');
      }
    } else if (!node.isRequired) {
      _sink.write('[');
      closeSeparator = ']';
    } else {
      closeSeparator = '';
    }

    write(node.type);
    if (node.name != null) {
      _sink.write(' ');
      _sink.write(node.name);
    }

    _sink.write(closeSeparator);
  }

  void _writeFunctionTypeAnnotation(FunctionTypeAnnotation type) {
    write(type.returnType);
    _sink.write(' Function');

    _sink.writeList(
      elements: type.typeParameters,
      write: _writeTypeParameter,
      separator: ', ',
      open: '<',
      close: '>',
    );

    _sink.write('(');
    var hasFormalParameter = false;
    for (final formalParameter in type.positionalParameters) {
      if (hasFormalParameter) {
        _sink.write(', ');
      }
      _writeFormalParameter(formalParameter);
      hasFormalParameter = true;
    }
    for (final formalParameter in type.namedParameters) {
      if (hasFormalParameter) {
        _sink.write(', ');
      }
      _writeFormalParameter(formalParameter);
      hasFormalParameter = true;
    }
    _sink.write(')');
  }

  void _writeNamedTypeAnnotation(NamedTypeAnnotation type) {
    _sink.write(type.identifier.name);
    _sink.writeList(
      elements: type.typeArguments,
      write: write,
      separator: ', ',
      open: '<',
      close: '>',
    );
  }

  void _writeTypeParameter(TypeParameterDeclaration node) {
    _sink.write(node.identifier.name);

    final bound = node.bound;
    if (bound != null) {
      _sink.write(' extends ');
      write(bound);
    }
  }
}

extension on StringSink {
  void writeList<T>({
    required Iterable<T> elements,
    required void Function(T element) write,
    required String separator,
    String? open,
    String? close,
  }) {
    elements = elements.toList();
    if (elements.isEmpty) {
      return;
    }

    if (open != null) {
      this.write(open);
    }
    var isFirst = true;
    for (var element in elements) {
      if (isFirst) {
        isFirst = false;
      } else {
        this.write(separator);
      }
      write(element);
    }
    if (close != null) {
      this.write(close);
    }
  }
}

extension E on TypeAnnotation {
  String get asString {
    final buffer = StringBuffer();
    _TypeAnnotationStringBuilder(buffer).write(this);
    return buffer.toString();
  }
}
