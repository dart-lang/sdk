// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'typescript.dart';

Map<String, String> _typeAliases = {};
String generateDartForTypes(List<ApiItem> types) {
  // Build the map of type aliases for substitution later.
  types
      .whereType<TypeAlias>()
      .forEach((alias) => _typeAliases[alias.name] = alias.baseType);
  final buffer = new IndentableStringBuffer();
  types.forEach((t) => _writeType(buffer, t));
  return buffer.toString().trim() + '\n'; // Ensure a single trailing newline.
}

/// Maps a TypeScript type on to a Dart type, including following TypeAliases.
/// Return value may include a trailing space when comments are included (for
/// example `String /* Document */`) due to how dartfmt formats these as
/// type arguments; this may need trimming for correct formatting in other
/// places.
String _mapType(String type) {
  if (type.endsWith('[]')) {
    return 'List<${_mapType(type.substring(0, type.length - 2))}>';
  }
  if (_typeAliases.containsKey(type)) {
    return _mapType(_typeAliases[type]) + ' /*$type*/ ';
  }
  const types = <String, String>{
    'boolean': 'bool',
    'string': 'String',
    'number': 'num',
    'any': 'Object',
  };
  return types[type] ?? type;
}

String _rewriteCommentReference(String comment) {
  final commentReferencePattern = new RegExp(r'\[([\w ]+)\]\(#(\w+)\)');
  return comment.replaceAllMapped(commentReferencePattern, (m) {
    final description = m.group(1);
    final reference = m.group(2);
    if (description == reference) {
      return '[$reference]';
    } else {
      return '$description ([$reference])';
    }
  });
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
  comment = _rewriteCommentReference(comment);
  Iterable<String> lines = comment.split('\n');
  // Wrap at 80 - 4 ('/// ') - indent characters.
  lines = _wrapLines(lines, 80 - 4 - buffer.totalIndent);
  lines.forEach((l) => buffer.writeIndentedLn('/// $l'.trim()));
}

void _writeField(IndentableStringBuffer buffer, Field field) {
  _writeDocComment(buffer, field.comment);
  if (field.types.length == 1) {
    buffer.writeIndented(_mapType(field.types.first).trim());
  } else {
    // TODO(dantup): Support union types better so that we have type safety from
    // the outside.
    buffer.writeIndented(
        'Object /*Either<${field.types.map(_mapType).join(', ')}>*/');
  }
  buffer.writeln(' ${field.name};');
}

void _writeInterface(IndentableStringBuffer buffer, Interface interface) {
  _writeDocComment(buffer, interface.comment);

  // TODO(dantup): Remove this code once this issue is fixed. For now we use this
  // only to ensure empty classes are formatted without newlines (as dartfmt) does
  // so that generated code is all dartfmt-clean.
  if (interface.members.isEmpty) {
    print(
        'Interface ${interface.name} was empty. This may suggest an error parsing the spec.');
    buffer..writeln('class ${interface.name} {}')..writeln();
    return;
  }

  buffer
    ..writeln('class ${interface.name} {')
    ..indent();
  // TODO(dantup): Generate constructors (inc. type checks for unions)
  _writeMembers(buffer, interface.members);
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

void _writeMembers(IndentableStringBuffer buffer, List<Member> members) {
  for (var i = 0; i < members.length; i++) {
    if (i != 0) {
      buffer.writeln();
    }
    _writeMember(buffer, members[i]);
  }
}

void _writeNamespace(IndentableStringBuffer buffer, Namespace namespace) {
  _writeDocComment(buffer, namespace.comment);
  buffer
    ..writeln('abstract class ${namespace.name} {')
    ..indent();
  _writeMembers(buffer, namespace.members);
  buffer
    ..outdent()
    ..writeln('}')
    ..writeln();
}

void _writeType(IndentableStringBuffer buffer, ApiItem type) {
  if (type is Interface) {
    _writeInterface(buffer, type);
  } else if (type is Namespace) {
    _writeNamespace(buffer, type);
  } else if (type is TypeAlias) {
    // For now type aliases are not supported, so are collected at the start
    // of the process in a map, and just replaced with the aliased type during
    // generation.
    // _writeTypeAlias(buffer, type);
  } else {
    throw 'Unknown type';
  }
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
