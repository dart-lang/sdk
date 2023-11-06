// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/macros/api.dart';

mixin SharedPrinter {
  TreeStringSink get sink;

  Future<void> writeMetadata(Annotatable e) async {
    await sink.writeElements(
      'metadata',
      e.metadata,
      _writeMetadataAnnotation,
    );
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
