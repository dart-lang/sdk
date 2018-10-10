// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'typescript.dart';

String generateDartForTypes(List<ApiItem> types) {
  final buffer = new IndentableStringBuffer();
  types.forEach((t) => _writeType(buffer, t));
  return buffer.toString();
}

String _mapType(String type) {
  if (type.endsWith('[]')) {
    return 'List<${_mapType(type.substring(0, type.length - 2))}>';
  }
  const types = <String, String>{
    'boolean': 'bool',
    'string': 'String',
    'number': 'num',
    'any': 'Object',
  };
  return types[type] ?? type;
}

Iterable<String> _wrapLines(List<String> lines, int maxLength) sync* {
  lines = lines.map((l) => l.trimRight()).toList();
  for (var line in lines) {
    while (true) {
      if (line.length <= maxLength) {
        yield line;
        break;
      } else {
        int lastSpace = line.lastIndexOf(' ', maxLength);
        // If there was no valid place to wrap, yield the whole string.
        if (lastSpace == -1) {
          yield line;
          break;
        } else {
          yield line.substring(0, lastSpace);
          line = line.substring(lastSpace + 1);
        }
      }
    }
  }
}

void _writeConst(IndentableStringBuffer buffer, Const cons) {
  _writeDocComment(buffer, cons.comment);
  buffer.writeIndentedLn('static const ${cons.name} = ${cons.value};');
}

void _writeDocComment(IndentableStringBuffer buffer, String comment) {
  comment = comment?.trim();
  if (comment == null || comment.length == 0) {
    return;
  }
  Iterable<String> lines = comment.split('\n');
  // Wrap at 80 - 4 ('/// ') - indent characters.
  lines = _wrapLines(lines, 80 - 4 - buffer.totalIndent);
  lines.forEach((l) => buffer.writeIndentedLn('/// ${l.trim()}'));
}

void _writeField(IndentableStringBuffer buffer, Field field) {
  _writeDocComment(buffer, field.comment);
  if (field.types.length == 1) {
    buffer.writeIndented(_mapType(field.types.first));
  } else {
    buffer.writeIndented('Either<${field.types.map(_mapType).join(', ')}>');
  }
  buffer.writeln(' ${field.name};');
}

void _writeInterface(IndentableStringBuffer buffer, Interface interface) {
  _writeDocComment(buffer, interface.comment);
  buffer
    ..writeln('class ${interface.name} {')
    ..indent();
  // TODO(dantup): Generate constructors (inc. type checks for unions)
  interface.members.forEach((m) => _writeMember(buffer, m));
  // TODO(dantup): Generate toJson()
  // TODO(dantup): Generate fromJson()
  buffer
    ..outdent()
    ..writeln('}')
    ..writeln();
}

void _writeMember(IndentableStringBuffer buffer, Member member) {
  if (member is Field) {
    _writeField(buffer, member);
  } else if (member is Const) {
    _writeConst(buffer, member);
  } else {
    throw 'Unknown type';
  }
}

void _writeNamespace(IndentableStringBuffer buffer, Namespace namespace) {
  _writeDocComment(buffer, namespace.comment);
  buffer
    ..writeln('abstract class ${namespace.name} {')
    ..indent();
  namespace.members.forEach((m) => _writeMember(buffer, m));
  buffer
    ..outdent()
    ..writeln('}')
    ..writeln();
}

void _writeType(IndentableStringBuffer buffer, ApiItem type) {
  if (type is Interface) {
    _writeInterface(buffer, type);
  } else if (type is TypeAlias) {
    _writeTypeAlias(buffer, type);
  } else if (type is Namespace) {
    _writeNamespace(buffer, type);
  } else {
    throw 'Unknown type';
  }
}

void _writeTypeAlias(IndentableStringBuffer buffer, TypeAlias typeAlias) {
  print('Skipping type alias ${typeAlias.name}');
}

class IndentableStringBuffer extends StringBuffer {
  int _indentLevel = 0;
  int _indentSpaces = 2;

  int get totalIndent => _indentLevel * _indentSpaces;
  String get _indentString => ' ' * totalIndent;

  void indent() => _indentLevel++;
  void outdent() => _indentLevel--;

  void writeIndented(Object obj) {
    write(_indentString);
    write(obj);
  }

  void writeIndentedLn(Object obj) {
    write(_indentString);
    writeln(obj);
  }
}
