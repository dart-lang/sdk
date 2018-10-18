// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart_style/dart_style.dart';

import 'typescript.dart';

final formatter = new DartFormatter();
Map<String, Interface> _interfaces = {};
Map<String, TypeAlias> _typeAliases = {};

String generateDartForTypes(List<ApiItem> types) {
  // Keep maps of items we may need to look up quickly later.
  types
      .whereType<TypeAlias>()
      .forEach((alias) => _typeAliases[alias.name] = alias);
  types
      .whereType<Interface>()
      .forEach((interface) => _interfaces[interface.name] = interface);
  final buffer = new IndentableStringBuffer();
  _getSorted(types).forEach((t) => _writeType(buffer, t));
  final formattedCode = _formatCode(buffer.toString());
  return formattedCode.trim() + '\n'; // Ensure a single trailing newline.
}

String _formatCode(String code) {
  try {
    code = formatter.format(code);
  } catch (e) {
    print('Failed to format code, returning unformatted code.');
  }
  return code;
}

/// Recursively gets all members from superclasses.
List<Field> _getAllFields(Interface interface) {
  // Handle missing interfaces (such as special cased interfaces that won't
  // be included in this model).
  if (interface == null) {
    return [];
  }
  return interface.members
      .whereType<Field>()
      .followedBy(interface.baseTypes
          .map((name) => _getAllFields(_interfaces[name]))
          .expand((ts) => ts))
      .toList();
}

/// Returns a copy of the list sorted by name.
List<ApiItem> _getSorted(List<ApiItem> items) {
  final sortedList = items.toList();
  sortedList.sort((item1, item2) => item1.name.compareTo(item2.name));
  return sortedList;
}

/// Maps reserved words and identifiers that cause issues in field names.
String _makeValidIdentifier(String identifier) {
  // The SymbolKind class has uses these names which cause issues for code that
  // uses them as types.
  const map = {
    'Object': 'Obj',
    'String': 'Str',
  };
  return map[identifier] ?? identifier;
}

/// Maps a TypeScript type on to a Dart type, including following TypeAliases.
String _mapType(List<String> types) {
  const mapping = <String, String>{
    'boolean': 'bool',
    'string': 'String',
    'number': 'num',
    'any': 'dynamic',
    // Special cases that are hard to parse or anonymous types.
    '{ [uri: string]: TextEdit[]; }': 'Map<String, List<TextEdit>>',
    '{ language: string; value: string }': 'MarkedStringWithLanguage'
  };
  if (types.length > 4) {
    throw 'Unions of more than 4 types are not supported.';
  }
  if (types.length >= 2) {
    final typeArgs = types.map((t) => _mapType([t])).join(', ');
    return 'Either${types.length}<$typeArgs>';
  }

  final type = types.first;
  if (type.endsWith('[]')) {
    return 'List<${_mapType([type.substring(0, type.length - 2)])}>';
  }
  if (_typeAliases.containsKey(type)) {
    return _mapType([_typeAliases[type].baseType]);
  }
  if (mapping.containsKey(type)) {
    return _mapType([mapping[type]]);
  }
  return type;
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
  _writeDocCommentsAndAnnotations(buffer, cons);
  buffer.writeIndentedln('static const ${cons.name} = ${cons.value};');
}

void _writeConstructor(IndentableStringBuffer buffer, Interface interface) {
  final allFields = _getAllFields(interface);
  if (allFields.isEmpty) {
    return;
  }
  buffer
    ..writeIndented('${interface.name}(')
    ..write(allFields.map((field) => 'this.${field.name}').join(', '))
    ..writeln(');');
}

void _writeDocCommentsAndAnnotations(
    IndentableStringBuffer buffer, ApiItem item) {
  var comment = item.comment?.trim();
  if (comment == null || comment.length == 0) {
    return;
  }
  comment = _rewriteCommentReference(comment);
  Iterable<String> lines = comment.split('\n');
  // Wrap at 80 - 4 ('/// ') - indent characters.
  lines = _wrapLines(lines, 80 - 4 - buffer.totalIndent);
  lines.forEach((l) => buffer.writeIndentedln('/// $l'.trim()));
  if (item.isDeprecated) {
    buffer.writeIndentedln('@core.deprecated');
  }
}

void _writeEnumClass(IndentableStringBuffer buffer, Namespace namespace) {
  _writeDocCommentsAndAnnotations(buffer, namespace);
  buffer
    ..writeln('class ${namespace.name} {')
    ..indent()
    ..writeIndentedln('const ${namespace.name}._(this._value);')
    ..writeln()
    ..writeIndentedln('final Object _value;')
    ..writeln();
  namespace.members.whereType<Const>().forEach((cons) {
    _writeDocCommentsAndAnnotations(buffer, cons);
    buffer
      ..writeIndentedln(
          'static const ${_makeValidIdentifier(cons.name)} = const ${namespace.name}._(${cons.value});');
  });
  buffer
    ..writeln()
    ..writeIndentedln('Object toJson() => _value;')
    ..writeln()
    ..writeIndentedln('@override String toString() => _value.toString();')
    ..writeln()
    ..writeIndentedln('@override get hashCode => _value.hashCode;')
    ..writeln()
    ..writeIndentedln(
        'bool operator ==(o) => o is ${namespace.name} && o._value == _value;')
    ..outdent()
    ..writeln('}')
    ..writeln();
}

void _writeField(IndentableStringBuffer buffer, Field field) {
  _writeDocCommentsAndAnnotations(buffer, field);
  buffer
    ..writeIndented('final ')
    ..write(_mapType(field.types))
    ..writeln(' ${field.name};');
}

void _writeInterface(IndentableStringBuffer buffer, Interface interface) {
  _writeDocCommentsAndAnnotations(buffer, interface);

  buffer.writeIndented('class ${interface.name} ');
  if (interface.baseTypes.isNotEmpty) {
    buffer.writeIndented('implements ${interface.baseTypes.join(', ')} ');
  }
  buffer
    ..writeln('{')
    ..indent();
  _writeConstructor(buffer, interface);
  // Handle Consts and Fields separately, since we need to include superclass
  // Fields.
  final consts = interface.members.whereType<Const>().toList();
  final fields = _getAllFields(interface);
  buffer.writeln();
  _writeMembers(buffer, consts);
  buffer.writeln();
  _writeMembers(buffer, fields);
  buffer.writeln();
  _writeToJsonMethod(buffer, interface);
  // TODO(dantup): Generate fromJson()
  buffer
    ..outdent()
    ..writeIndentedln('}')
    ..writeln();
}

void _writeJsonMapAssignment(
    IndentableStringBuffer buffer, Field field, String mapName) {
  // If we are allowed to be undefined (which essentially means required to be
  // undefined and never explicitly null), we'll only add the value if set.
  if (field.allowsUndefined) {
    buffer
      ..writeIndentedlnIf(
          field.isDeprecated, '// ignore: deprecated_member_use')
      ..writeIndentedln('if (${field.name} != null) {')
      ..indent();
  }
  buffer
    ..writeIndentedlnIf(field.isDeprecated, '// ignore: deprecated_member_use')
    ..writeIndented('''$mapName['${field.name}'] = ${field.name}''');
  if (!field.allowsUndefined && !field.allowsNull) {
    buffer.write(''' ?? (throw '${field.name} is required but was not set')''');
  }
  buffer.writeln(';');
  if (field.allowsUndefined) {
    buffer
      ..outdent()
      ..writeIndentedln('}');
  }
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
  _getSorted(members).forEach((m) => _writeMember(buffer, m));
}

void _writeNamespace(IndentableStringBuffer buffer, Namespace namespace) {
  // Namespaces are just groups of constants. For some uses we can write these
  // as enum classes for extra type safety, but not for all - for example
  // CodeActionKind can be an arbitrary String even though it also defines
  // constants for common values. We can tell which can have their own values
  // because they're marked with type aliases, with the exception of ErrorCodes!
  if (!_typeAliases.containsKey(namespace.name) &&
      namespace.name != 'ErrorCodes') {
    _writeEnumClass(buffer, namespace);
    return;
  }

  _writeDocCommentsAndAnnotations(buffer, namespace);
  buffer
    ..writeln('abstract class ${namespace.name} {')
    ..indent();
  _writeMembers(buffer, namespace.members);
  buffer
    ..outdent()
    ..writeln('}')
    ..writeln();
}

void _writeToJsonMethod(IndentableStringBuffer buffer, Interface interface) {
  // It's important the name we use for the map here isn't in use in the object
  // already. 'result' was, so we prefix it with some underscores.
  buffer
    ..writeIndentedln('Map<String, dynamic> toJson() {')
    ..indent()
    ..writeIndentedln('Map<String, dynamic> __result = {};');
  for (var field in _getAllFields(interface)) {
    _writeJsonMapAssignment(buffer, field, '__result');
  }
  buffer
    ..writeIndentedln('return __result;')
    ..outdent()
    ..writeIndentedln('}');
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

  void writeIndentedln(Object obj) {
    write(_indentString);
    writeln(obj);
  }

  void writeIndentedlnIf(bool condition, Object obj) {
    if (condition) {
      writeIndentedln(obj);
    }
  }
}
