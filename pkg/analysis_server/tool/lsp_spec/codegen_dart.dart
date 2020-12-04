// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart_style/dart_style.dart';

import 'typescript.dart';
import 'typescript_parser.dart';

final formatter = DartFormatter();
Map<String, Interface> _interfaces = {};
Map<String, Namespace> _namespaces = {};
// TODO(dantup): Rename namespaces -> enums since they're always that now.
Map<String, List<String>> _subtypes = {};
Map<String, TypeAlias> _typeAliases = {};

/// Whether our enum class allows any value (eg. should always return true
/// from canParse() for the correct type). This is to allow us to have some
/// type safety for these values but without restricting which values are allowed.
/// This is to support things like custom error codes and also future changes
/// in the spec (it's important the server doesn't crash on deserialising
/// newer values).
bool enumClassAllowsAnyValue(String name) {
  // The types listed here are the ones that have a guaranteed restricted type
  // in the LSP spec, for example:
  //
  //   export type CompletionTriggerKind = 1 | 2 | 3;
  //
  // The other enum types use string/number/etc. in the referencing classes.
  return name != 'CompletionTriggerKind' &&
      name != 'FailureHandlingKind' &&
      name != 'InsertTextFormat' &&
      name != 'MarkupKind' &&
      name != 'ResourceOperationKind';
}

String generateDartForTypes(List<AstNode> types) {
  final buffer = IndentableStringBuffer();
  _getSortedUnique(types).forEach((t) => _writeType(buffer, t));
  final formattedCode = _formatCode(buffer.toString());
  return formattedCode.trim() + '\n'; // Ensure a single trailing newline.
}

void recordTypes(List<AstNode> types) {
  types
      .whereType<TypeAlias>()
      .forEach((alias) => _typeAliases[alias.name] = alias);
  types.whereType<Interface>().forEach((interface) {
    _interfaces[interface.name] = interface;
    // Keep track of our base classes so they can look up their super classes
    // later in their fromJson() to deserialise into the most specific type.
    interface.baseTypes.forEach((base) {
      final subTypes = _subtypes[base.dartType] ??= <String>[];
      subTypes.add(interface.name);
    });
  });
  types
      .whereType<Namespace>()
      .forEach((namespace) => _namespaces[namespace.name] = namespace);
}

TypeBase resolveTypeAlias(TypeBase type, {resolveEnumClasses = false}) {
  if (type is Type && _typeAliases.containsKey(type.name)) {
    final alias = _typeAliases[type.name];
    // Only follow the type if we're not an enum, or we wanted to follow enums.
    if (!_namespaces.containsKey(alias.name) || resolveEnumClasses) {
      return alias.baseType;
    }
  }
  return type;
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
          // This cast is safe because base types are always real types.
          .map((type) => _getAllFields(_interfaces[(type as Type).name]))
          .expand((ts) => ts))
      .toList();
}

/// Returns a copy of the list sorted by name with duplicates (by name+type) removed.
List<AstNode> _getSortedUnique(List<AstNode> items) {
  final uniqueByName = <String, AstNode>{};
  items.forEach((item) {
    // It's fine to have the same name used for different types (eg. namespace +
    // type alias) but some types are just duplicated entirely in the spec in
    // different positions which should not be emitted twice.
    final nameTypeKey = '${item.name}|${item.runtimeType}';
    if (uniqueByName.containsKey(nameTypeKey)) {
      // At the time of writing, there were two duplicated types:
      // - TextDocumentSyncKind (same defintion in both places)
      // - TextDocumentSyncOptions (first definition is just a subset)
      // If this list grows, consider handling this better - or try to have the
      // spec updated to be unambigious.
      print('WARN: More than one definition for $nameTypeKey.');
    }

    // Keep the last one as in some cases the first definition is less specific.
    uniqueByName[nameTypeKey] = item;
  });
  final sortedList = uniqueByName.values.toList();
  sortedList.sort((item1, item2) => item1.name.compareTo(item2.name));
  return sortedList;
}

String _getTypeCheckFailureMessage(TypeBase type) {
  if (type is LiteralType) {
    return 'must be the literal ${type.literal}';
  } else if (type is LiteralUnionType) {
    return 'must be one of the literals ${type.literalTypes.map((t) => t.literal).join(', ')}';
  } else {
    return 'must be of type ${type.dartTypeWithTypeArgs}';
  }
}

bool _isSimpleType(TypeBase type) {
  const literals = ['num', 'String', 'bool'];
  return type is Type && literals.contains(type.dartType);
}

bool _isSpecType(TypeBase type) {
  return type is Type &&
      (_interfaces.containsKey(type.name) ||
          (_namespaces.containsKey(type.name)));
}

/// Maps reserved words and identifiers that cause issues in field names.
String _makeValidIdentifier(String identifier) {
  // Some identifiers used in LSP are reserved words in Dart, so map them to
  // other values.
  const map = {
    'Object': 'Obj',
    'String': 'Str',
    'class': 'class_',
    'enum': 'enum_',
  };
  return map[identifier] ?? identifier;
}

String _rewriteCommentReference(String comment) {
  final commentReferencePattern = RegExp(r'\[([\w ]+)\]\(#(\w+)\)');
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
        var lastSpace = line.lastIndexOf(' ', maxLength);
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

void _writeCanParseMethod(IndentableStringBuffer buffer, Interface interface) {
  buffer
    ..writeIndentedln(
        'static bool canParse(Object obj, LspJsonReporter reporter) {')
    ..indent()
    ..writeIndentedln('if (obj is Map<String, dynamic>) {')
    ..indent();
  // In order to consider this valid for parsing, all fields that must not be
  // undefined must be present and also type check for the correct type.
  // Any fields that are optional but present, must still type check.
  final fields = _getAllFields(interface);
  for (var field in fields) {
    buffer
      ..writeIndentedln("reporter.push('${field.name}');")
      ..writeIndentedln('try {')
      ..indent();
    if (!field.allowsUndefined) {
      buffer
        ..writeIndentedln("if (!obj.containsKey('${field.name}')) {")
        ..indent()
        ..writeIndentedln("reporter.reportError('must not be undefined');")
        ..writeIndentedln('return false;')
        ..outdent()
        ..writeIndentedln('}');
    }
    if (!field.allowsNull && !field.allowsUndefined) {
      buffer
        ..writeIndentedln("if (obj['${field.name}'] == null) {")
        ..indent()
        ..writeIndentedln("reporter.reportError('must not be null');")
        ..writeIndentedln('return false;')
        ..outdent()
        ..writeIndentedln('}');
    }
    buffer.writeIndented('if (');
    if (field.allowsNull || field.allowsUndefined) {
      buffer.write("obj['${field.name}'] != null && ");
    }
    buffer.write('!(');
    _writeTypeCheckCondition(
        buffer, interface, "obj['${field.name}']", field.type, 'reporter');
    buffer
      ..write(')) {')
      ..indent()
      ..writeIndentedln(
          "reporter.reportError('${_getTypeCheckFailureMessage(field.type).replaceAll("'", "\\'")}');")
      ..writeIndentedln('return false;')
      ..outdent()
      ..writeIndentedln('}')
      ..outdent()
      ..writeIndentedln('} finally {')
      ..indent()
      ..writeIndentedln('reporter.pop();')
      ..outdent()
      ..writeIndentedln('}');
  }
  buffer
    ..writeIndentedln('return true;')
    ..outdent()
    ..writeIndentedln('} else {')
    ..indent()
    ..writeIndentedln(
        "reporter.reportError('must be of type ${interface.nameWithTypeArgs}');")
    ..writeIndentedln('return false;')
    ..outdent()
    ..writeIndentedln('}')
    ..outdent()
    ..writeIndentedln('}');
}

void _writeConst(IndentableStringBuffer buffer, Const cons) {
  _writeDocCommentsAndAnnotations(buffer, cons);
  buffer.writeIndentedln('static const ${cons.name} = ${cons.valueAsLiteral};');
}

void _writeConstructor(IndentableStringBuffer buffer, Interface interface) {
  final allFields = _getAllFields(interface);
  if (allFields.isEmpty) {
    return;
  }
  buffer
    ..writeIndented('${interface.name}({')
    ..write(allFields.map((field) {
      final isLiteral = field.type is LiteralType;
      final isRequired =
          !isLiteral && !field.allowsNull && !field.allowsUndefined;
      final annotation = isRequired ? '@required' : '';
      final valueCode =
          isLiteral ? ' = ${(field.type as LiteralType).literal}' : '';
      return '$annotation this.${field.name}$valueCode';
    }).join(', '))
    ..write('})');
  final fieldsWithValidation = allFields
      .where(
          (f) => (!f.allowsNull && !f.allowsUndefined) || f.type is LiteralType)
      .toList();
  if (fieldsWithValidation.isNotEmpty) {
    buffer
      ..writeIndentedln(' {')
      ..indent();
    for (var field in fieldsWithValidation) {
      final type = field.type;
      if (type is LiteralType) {
        buffer
          ..writeIndentedln('if (${field.name} != ${type.literal}) {')
          ..indent()
          ..writeIndentedln(
              "throw '${field.name} may only be the literal ${type.literal.replaceAll("'", "\\'")}';")
          ..outdent()
          ..writeIndentedln('}');
      } else if (!field.allowsNull && !field.allowsUndefined) {
        buffer
          ..writeIndentedln('if (${field.name} == null) {')
          ..indent()
          ..writeIndentedln(
              "throw '${field.name} is required but was not provided';")
          ..outdent()
          ..writeIndentedln('}');
      }
    }
    buffer
      ..outdent()
      ..writeIndentedln('}');
  } else {
    buffer.writeln(';');
  }
}

void _writeDocCommentsAndAnnotations(
    IndentableStringBuffer buffer, AstNode node) {
  var comment = node.commentText?.trim();
  if (comment != null && comment.isNotEmpty) {
    comment = _rewriteCommentReference(comment);
    Iterable<String> lines = comment.split('\n');
    // Wrap at 80 - 4 ('/// ') - indent characters.
    lines = _wrapLines(lines, (80 - 4 - buffer.totalIndent).clamp(0, 80));
    lines.forEach((l) => buffer.writeIndentedln('/// $l'.trim()));
  }
  // Marking LSP-deprecated fields as deprecated in Dart results in a lot
  // of warnings because we still often populate these fields for clients that
  // may still be using them. This code is useful for enabling temporarily
  // and reviewing which deprecated fields we should still support but isn't
  // generally useful to keep enabled.
  // if (node.isDeprecated) {
  //   buffer.writeIndentedln('@core.deprecated');
  // }
}

void _writeEnumClass(IndentableStringBuffer buffer, Namespace namespace) {
  _writeDocCommentsAndAnnotations(buffer, namespace);
  final consts = namespace.members.cast<Const>().toList();
  final allowsAnyValue = enumClassAllowsAnyValue(namespace.name);
  final constructorName = allowsAnyValue ? '' : '._';
  final firstValueType = consts.first.type;
  // Enums can have constant values in their fields so if a field is a literal
  // use its underlying type for type checking.
  final requiredValueType =
      firstValueType is LiteralType ? firstValueType.type : firstValueType;
  final typeOfValues =
      resolveTypeAlias(requiredValueType, resolveEnumClasses: true);

  buffer
    ..writeln('class ${namespace.name} {')
    ..indent()
    ..writeIndentedln('const ${namespace.name}$constructorName(this._value);')
    ..writeIndentedln('const ${namespace.name}.fromJson(this._value);')
    ..writeln()
    ..writeIndentedln('final ${typeOfValues.dartTypeWithTypeArgs} _value;')
    ..writeln()
    ..writeIndentedln(
        'static bool canParse(Object obj, LspJsonReporter reporter) {')
    ..indent();
  if (allowsAnyValue) {
    buffer.writeIndentedln('return ');
    _writeTypeCheckCondition(buffer, null, 'obj', typeOfValues, 'reporter');
    buffer.writeln(';');
  } else {
    buffer
      ..writeIndentedln('switch (obj) {')
      ..indent();
    consts.forEach((cons) {
      buffer.writeIndentedln('case ${cons.valueAsLiteral}:');
    });
    buffer
      ..indent()
      ..writeIndentedln('return true;')
      ..outdent()
      ..outdent()
      ..writeIndentedln('}')
      ..writeIndentedln('return false;');
  }
  buffer
    ..outdent()
    ..writeIndentedln('}');
  namespace.members.whereType<Const>().forEach((cons) {
    // We don't use any deprecated enum values, so ommit them entirely.
    if (cons.isDeprecated) {
      return;
    }
    _writeDocCommentsAndAnnotations(buffer, cons);
    buffer.writeIndentedln(
        'static const ${_makeValidIdentifier(cons.name)} = ${namespace.name}$constructorName(${cons.valueAsLiteral});');
  });
  buffer
    ..writeln()
    ..writeIndentedln('Object toJson() => _value;')
    ..writeln()
    ..writeIndentedln('@override String toString() => _value.toString();')
    ..writeln()
    ..writeIndentedln('@override int get hashCode => _value.hashCode;')
    ..writeln()
    ..writeIndentedln(
        'bool operator ==(Object o) => o is ${namespace.name} && o._value == _value;')
    ..outdent()
    ..writeln('}')
    ..writeln();
}

void _writeEquals(IndentableStringBuffer buffer, Interface interface) {
  buffer
    ..writeIndentedln('@override')
    ..writeIndentedln('bool operator ==(Object other) {')
    ..indent()
    // We want an exact type match, but also need `is` to have the analyzer
    // promote the type to allow access to the fields on `other`.
    ..writeIndentedln(
        'if (other is ${interface.name} && other.runtimeType == ${interface.name}) {')
    ..indent()
    ..writeIndented('return ');
  for (var field in _getAllFields(interface)) {
    final type = resolveTypeAlias(field.type);
    _writeEqualsExpression(buffer, type, field.name, 'other.${field.name}');
    buffer.write(' && ');
  }
  buffer
    ..writeln('true;')
    ..outdent()
    ..writeIndentedln('}')
    ..writeIndentedln('return false;')
    ..outdent()
    ..writeIndentedln('}');
}

void _writeEqualsExpression(IndentableStringBuffer buffer, TypeBase type,
    String thisName, String otherName) {
  if (type is ArrayType) {
    final elementType = type.elementType;
    final elementDartType = elementType.dartTypeWithTypeArgs;
    buffer.write(
        'listEqual($thisName, $otherName, ($elementDartType a, $elementDartType b) => ');
    _writeEqualsExpression(buffer, elementType, 'a', 'b');
    buffer.write(')');
  } else if (type is MapType) {
    final valueType = type.valueType;
    final valueDartType = valueType.dartTypeWithTypeArgs;
    buffer.write(
        'mapEqual($thisName, $otherName, ($valueDartType a, $valueDartType b) => ');
    _writeEqualsExpression(buffer, valueType, 'a', 'b');
    buffer.write(')');
  } else {
    buffer.write('$thisName == $otherName');
  }
}

void _writeField(IndentableStringBuffer buffer, Field field) {
  _writeDocCommentsAndAnnotations(buffer, field);
  buffer
    ..writeIndented('final ')
    ..write(field.type.dartTypeWithTypeArgs)
    ..writeln(' ${field.name};');
}

void _writeFromJsonCode(
    IndentableStringBuffer buffer, TypeBase type, String valueCode,
    {bool allowsNull}) {
  type = resolveTypeAlias(type);

  if (_isSimpleType(type)) {
    buffer.write('$valueCode');
  } else if (_isSpecType(type)) {
    // Our own types have fromJson() constructors we can call.
    buffer.write(
        '$valueCode != null ? ${type.dartType}.fromJson${type.typeArgsString}($valueCode) : null');
  } else if (type is ArrayType) {
    // Lists need to be map()'d so we can recursively call writeFromJsonCode
    // as they may need fromJson on each element.
    buffer.write('$valueCode?.map((item) => ');
    _writeFromJsonCode(buffer, type.elementType, 'item',
        allowsNull: allowsNull);
    buffer
        .write(')?.cast<${type.elementType.dartTypeWithTypeArgs}>()?.toList()');
  } else if (type is MapType) {
    // Maps need to be map()'d so we can recursively call writeFromJsonCode as
    // they may need fromJson on each key or value.
    buffer.write('$valueCode?.map((key, value) => MapEntry(');
    _writeFromJsonCode(buffer, type.indexType, 'key', allowsNull: allowsNull);
    buffer.write(', ');
    _writeFromJsonCode(buffer, type.valueType, 'value', allowsNull: allowsNull);
    buffer.write(
        '))?.cast<${type.indexType.dartTypeWithTypeArgs}, ${type.valueType.dartTypeWithTypeArgs}>()');
  } else if (type is LiteralUnionType) {
    _writeFromJsonCodeForLiteralUnion(buffer, type, valueCode,
        allowsNull: allowsNull);
  } else if (type is UnionType) {
    _writeFromJsonCodeForUnion(buffer, type, valueCode, allowsNull: allowsNull);
  } else {
    buffer.write('$valueCode');
  }
}

void _writeFromJsonCodeForLiteralUnion(
    IndentableStringBuffer buffer, LiteralUnionType union, String valueCode,
    {bool allowsNull}) {
  final allowedValues = [
    if (allowsNull) null,
    ...union.literalTypes.map((t) => t.literal)
  ];
  buffer.write(
      "const {${allowedValues.join(', ')}}.contains($valueCode) ? $valueCode : "
      "throw '''\${$valueCode} was not one of (${allowedValues.join(', ')})'''");
}

void _writeFromJsonCodeForUnion(
    IndentableStringBuffer buffer, UnionType union, String valueCode,
    {bool allowsNull}) {
  // Write a check against each type, eg.:
  // x is y ? new Either.tx(x) : (...)
  var hasIncompleteCondition = false;
  var unclosedParens = 0;
  for (var i = 0; i < union.types.length; i++) {
    final type = union.types[i];
    final isDynamic = type.dartType == 'dynamic';

    // Dynamic matches all type checks, so only emit it if required.
    if (!isDynamic) {
      _writeTypeCheckCondition(
          buffer, null, valueCode, type, 'nullLspJsonReporter');
      buffer.write(' ? ');
    }

    // The code to construct a value with this "side" of the union.
    buffer.write('${union.dartTypeWithTypeArgs}.t${i + 1}(');
    _writeFromJsonCode(buffer, type, valueCode,
        allowsNull: allowsNull); // Call recursively!
    buffer.write(')');

    // If we output the type condition at the top, prepare for the next condition.
    if (!isDynamic) {
      buffer.write(' : (');
      hasIncompleteCondition = true;
      unclosedParens++;
    } else {
      hasIncompleteCondition = false;
    }
  }
  // Fill the final parens with a throw because if we fell through all of the
  // cases then the value we had didn't match any of the types in the union.
  if (hasIncompleteCondition) {
    if (allowsNull) {
      buffer.write('$valueCode == null ? null : (');
      unclosedParens++;
    }
    buffer.write(
        "throw '''\${$valueCode} was not one of (${union.types.map((t) => t.dartTypeWithTypeArgs).join(', ')})'''");
  }
  buffer.write(')' * unclosedParens);
}

void _writeFromJsonConstructor(
    IndentableStringBuffer buffer, Interface interface) {
  final allFields = _getAllFields(interface);
  buffer
    ..writeIndentedln('static ${interface.nameWithTypeArgs} '
        'fromJson${interface.typeArgsString}(Map<String, dynamic> json) {')
    ..indent();
  // First check whether any of our subclasses can deserialise this.
  for (final subclassName in _subtypes[interface.name] ?? const <String>[]) {
    final subclass = _interfaces[subclassName];
    buffer
      ..writeIndentedln(
          'if (${subclass.name}.canParse(json, nullLspJsonReporter)) {')
      ..indent()
      ..writeln('return ${subclass.nameWithTypeArgs}.fromJson(json);')
      ..outdent()
      ..writeIndentedln('}');
  }
  for (final field in allFields) {
    buffer.writeIndented('final ${field.name} = ');
    _writeFromJsonCode(buffer, field.type, "json['${field.name}']",
        allowsNull: field.allowsNull || field.allowsUndefined);
    buffer.writeln(';');
  }
  buffer
    ..writeIndented('return ${interface.nameWithTypeArgs}(')
    ..write(allFields.map((field) => '${field.name}: ${field.name}').join(', '))
    ..writeln(');')
    ..outdent()
    ..writeIndented('}');
}

void _writeHashCode(IndentableStringBuffer buffer, Interface interface) {
  buffer
    ..writeIndentedln('@override')
    ..writeIndentedln('int get hashCode {')
    ..indent()
    ..writeIndentedln('var hash = 0;');
  for (var field in _getAllFields(interface)) {
    final type = resolveTypeAlias(field.type);
    if (type is ArrayType || type is MapType) {
      buffer.writeIndentedln(
          'hash = JenkinsSmiHash.combine(hash, lspHashCode(${field.name}));');
    } else {
      buffer.writeIndentedln(
          'hash = JenkinsSmiHash.combine(hash, ${field.name}.hashCode);');
    }
  }
  buffer
    ..writeIndentedln('return JenkinsSmiHash.finish(hash);')
    ..outdent()
    ..writeIndentedln('}');
}

void _writeInterface(IndentableStringBuffer buffer, Interface interface) {
  _writeDocCommentsAndAnnotations(buffer, interface);

  buffer.writeIndented('class ${interface.nameWithTypeArgs} ');
  final allBaseTypes =
      interface.baseTypes.map((t) => t.dartTypeWithTypeArgs).toList();
  allBaseTypes.addAll(getSpecialBaseTypes(interface));
  allBaseTypes.add('ToJsonable');
  if (allBaseTypes.isNotEmpty) {
    buffer.writeIndented('implements ${allBaseTypes.join(', ')} ');
  }
  buffer
    ..writeln('{')
    ..indent();
  _writeJsonHandler(buffer, interface);
  _writeConstructor(buffer, interface);
  _writeFromJsonConstructor(buffer, interface);
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
  _writeCanParseMethod(buffer, interface);
  _writeEquals(buffer, interface);
  _writeHashCode(buffer, interface);
  _writeToString(buffer, interface);
  buffer
    ..outdent()
    ..writeIndentedln('}')
    ..writeln();
}

void _writeJsonHandler(IndentableStringBuffer buffer, Interface interface) {
  buffer
    ..writeIndented('static const jsonHandler = ')
    ..write('LspJsonHandler(')
    ..write('${interface.name}.canParse, ${interface.name}.fromJson')
    ..writeln(');')
    ..writeln();
}

void _writeJsonMapAssignment(
    IndentableStringBuffer buffer, Field field, String mapName) {
  // If we are allowed to be undefined, we'll only add the value if set.
  final shouldBeOmittedIfNoValue = field.allowsUndefined;
  if (shouldBeOmittedIfNoValue) {
    buffer
      ..writeIndentedln('if (${field.name} != null) {')
      ..indent();
  }
  // Suppress the ? operator if we've output a null check already.
  final nullOp = shouldBeOmittedIfNoValue ? '' : '?';
  final valueCode =
      _isSpecType(field.type) ? '${field.name}$nullOp.toJson()' : field.name;
  buffer.writeIndented('''$mapName['${field.name}'] = $valueCode''');
  if (!field.allowsUndefined && !field.allowsNull) {
    buffer.write(''' ?? (throw '${field.name} is required but was not set')''');
  }
  buffer.writeln(';');
  if (shouldBeOmittedIfNoValue) {
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
  _getSortedUnique(members).forEach((m) => _writeMember(buffer, m));
}

void _writeToJsonFieldsForResponseMessage(
    IndentableStringBuffer buffer, Interface interface) {
  const mapName = '__result';

  final allFields = _getAllFields(interface);
  final standardFields =
      allFields.where((f) => f.name != 'error' && f.name != 'result');

  for (var field in standardFields) {
    _writeJsonMapAssignment(buffer, field, mapName);
  }

  // Write special code for result/error so that only one is populated.
  buffer
    ..writeIndentedln('if (error != null && result != null) {')
    ..indent()
    ..writeIndentedln('''throw 'result and error cannot both be set';''')
    ..outdent()
    ..writeIndentedln('} else if (error != null) {')
    ..indent()
    ..writeIndentedln('''$mapName['error'] = error;''')
    ..outdent()
    ..writeIndentedln('} else {')
    ..indent()
    ..writeIndentedln('''$mapName['result'] = result;''')
    ..outdent()
    ..writeIndentedln('}');
}

void _writeToJsonMethod(IndentableStringBuffer buffer, Interface interface) {
  // It's important the name we use for the map here isn't in use in the object
  // already. 'result' was, so we prefix it with some underscores.
  buffer
    ..writeIndentedln('Map<String, dynamic> toJson() {')
    ..indent()
    ..writeIndentedln('var __result = <String, dynamic>{};');
  // ResponseMessage must confirm to JSON-RPC which says only one of
  // result/error can be included. Since this isn't encoded in the types we
  // need to special-case it's toJson generation.
  if (interface.name == 'ResponseMessage') {
    _writeToJsonFieldsForResponseMessage(buffer, interface);
  } else {
    for (var field in _getAllFields(interface)) {
      _writeJsonMapAssignment(buffer, field, '__result');
    }
  }
  buffer
    ..writeIndentedln('return __result;')
    ..outdent()
    ..writeIndentedln('}');
}

void _writeToString(IndentableStringBuffer buffer, Interface interface) {
  buffer
    ..writeIndentedln('@override')
    ..writeIndentedln('String toString() => jsonEncoder.convert(toJson());');
}

void _writeType(IndentableStringBuffer buffer, AstNode type) {
  if (type is Interface) {
    _writeInterface(buffer, type);
  } else if (type is Namespace) {
    _writeEnumClass(buffer, type);
  } else if (type is TypeAlias) {
    // For now type aliases are not supported, so are collected at the start
    // of the process in a map, and just replaced with the aliased type during
    // generation.
    // _writeTypeAlias(buffer, type);
  } else {
    throw 'Unknown type';
  }
}

void _writeTypeCheckCondition(IndentableStringBuffer buffer,
    Interface interface, String valueCode, TypeBase type, String reporter) {
  type = resolveTypeAlias(type);

  final dartType = type.dartType;
  final fullDartType = type.dartTypeWithTypeArgs;
  if (fullDartType == 'dynamic') {
    buffer.write('true');
  } else if (_isSimpleType(type)) {
    buffer.write('$valueCode is $fullDartType');
  } else if (type is LiteralType) {
    buffer.write('$valueCode == ${type.literal}');
  } else if (_isSpecType(type)) {
    buffer.write('$dartType.canParse($valueCode, $reporter)');
  } else if (type is ArrayType) {
    buffer.write('($valueCode is List');
    if (fullDartType != 'dynamic') {
      // TODO(dantup): If we're happy to assume we never have two lists in a union
      // we could skip this bit.
      buffer.write(' && ($valueCode.every((item) => ');
      _writeTypeCheckCondition(
          buffer, interface, 'item', type.elementType, reporter);
      buffer.write('))');
    }
    buffer.write(')');
  } else if (type is MapType) {
    buffer.write('($valueCode is Map');
    if (fullDartType != 'dynamic') {
      buffer..write(' && (')..write('$valueCode.keys.every((item) => ');
      _writeTypeCheckCondition(
          buffer, interface, 'item', type.indexType, reporter);
      buffer.write('&& $valueCode.values.every((item) => ');
      _writeTypeCheckCondition(
          buffer, interface, 'item', type.valueType, reporter);
      buffer.write(')))');
    }
    buffer.write(')');
  } else if (type is UnionType) {
    // To type check a union, we just recursively check against each of its types.
    buffer.write('(');
    for (var i = 0; i < type.types.length; i++) {
      if (i != 0) {
        buffer.write(' || ');
      }
      _writeTypeCheckCondition(
          buffer, interface, valueCode, type.types[i], reporter);
    }
    buffer.write(')');
  } else if (interface != null &&
      interface.typeArgs != null &&
      interface.typeArgs.any((typeArg) => typeArg.lexeme == fullDartType)) {
    final comment = '/* $fullDartType.canParse($valueCode) */';
    print(
        'WARN: Unable to write a type check for $valueCode with generic type $fullDartType. '
        'Please review the generated code annotated with $comment');
    buffer.write('true $comment');
  } else {
    throw 'Unable to type check $valueCode against $fullDartType';
  }
}

class IndentableStringBuffer extends StringBuffer {
  int _indentLevel = 0;
  final int _indentSpaces = 2;

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
}
