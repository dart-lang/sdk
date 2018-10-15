// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(dantup): Regex seemed like a good choice when parsing the first few...
// maybe it's not so great now. We should parse this properly if it turns out
// there are issues with what we have here.
const String _blockBody = r'\{([\s\S]*?)\s*\n\s*\}';
const String _comment = r'(?:\/\*\*((?:[\S\s](?!\*\/))+?)\s\*\/)?\s*';

List<ApiItem> extractAllTypes(List<String> code) {
  return extractTypes(code.join('\n'));
}

List<ApiItem> extractTypes(String code) {
  final types = ApiItem.extractFrom(code);
  _removeUnwantedTypes(types);
  _sort(types);
  return types;
}

/// Removes types that are in the spec that we don't want.
void _removeUnwantedTypes(List<ApiItem> types) {
  // These types are not used for v3.0 (Feb 2017) and by dropping them we don't
  // have to handle any cases where both a namespace and interfaces are declared
  // with the same name.
  types.removeWhere((item) => item.name == 'InitializeError');
}

String _cleanComment(String comment) {
  if (comment == null) {
    return null;
  }
  final _commentLinePrefixes = new RegExp(r'\n\s*\* ?');
  final _nonConcurrentNewlines = new RegExp(r'\n(?![\n\s\-*])');
  final _newLinesThatRequireReinserting = new RegExp(r'\n (\w)');
  // Remove any Windows newlines from the source.
  comment = comment.replaceAll('\r', '');
  // Remove the * prefixes.
  comment = comment.replaceAll(_commentLinePrefixes, '\n');
  // Remove and newlines that look like wrapped text.
  comment = comment.replaceAll(_nonConcurrentNewlines, ' ');
  // The above will remove one of the newlines when there are two, so we need
  // to re-insert newlines for any block that starts immediately after a newline.
  comment = comment.replaceAllMapped(
      _newLinesThatRequireReinserting, (m) => '\n\n${m.group(1)}');
  return comment.trim();
}

List<String> _parseTypes(String baseTypes, String sep) {
  // Special case for a single complicated type we can't parse easily...
  if (baseTypes ==
      '(TextDocumentEdit[] | (TextDocumentEdit | CreateFile | RenameFile | DeleteFile)[])') {
    return ['FileOperation[]'];
  }
  return baseTypes?.split(sep)?.map((t) => t.trim())?.toList() ?? [];
}

/// Sorts all ApiItems by their name so that generated code is easier to diff
/// across changes.
void _sort(List<ApiItem> items) {
  items.sort((item1, item2) => item1.name.compareTo(item2.name));
}

/// Base class for Interface, Field, Constant, etc. parsed from the LSP spec.
abstract class ApiItem {
  String name, comment;
  ApiItem(this.name, String comment) : comment = _cleanComment(comment);

  static List<ApiItem> extractFrom(String code) {
    List<ApiItem> types = [];
    types.addAll(Interface.extractFrom(code));
    types.addAll(Namespace.extractFrom(code));
    types.addAll(TypeAlias.extractFrom(code));
    _sort(types);
    return types;
  }
}

/// A Constant parsed from the LSP spec.
class Const extends Member {
  final String type, value;
  Const(String name, String comment, this.type, this.value)
      : super(name, comment);

  static List<Const> extractFrom(String code) {
    final RegExp _constPattern = new RegExp(_comment +
        r'''(?:export\s+)?const\s+(\w+)(?::\s+([\w\[\]'".-]+?))?\s*=\s*([\w\[\]'".-]+)\s*(?:;|$)''');

    final consts = _constPattern.allMatches(code).map((m) {
      final String comment = m.group(1);
      final String name = m.group(2);
      final String type = m.group(3);
      final String value = m.group(4);
      return new Const(name, comment, type, value);
    }).toList();
    _sort(consts);
    return consts;
  }
}

/// A Field for an Interface parsed from the LSP spec.
class Field extends Member {
  final List<String> types;
  final bool allowsNull, allowsUndefined;
  Field(String name, String comment, this.types, this.allowsNull,
      this.allowsUndefined)
      : super(name, comment);

  static List<Field> extractFrom(String code) {
    final RegExp _fieldPattern = new RegExp(
        _comment + r'([\w\[\]]+\??)\s*:\s*([\w\[\] \|\{\}\(\):;]+)\s*(?:;|$)');

    final fields = _fieldPattern.allMatches(code).where((m) {
      // Skip over the indexer in FormattingOptions since we don't need this
      // (for now) and it's complicated to represent.
      if (m.group(0).contains('[key: string]: boolean | number | string;')) {
        return false;
      }
      return true;
    }).map((m) {
      String comment = m.group(1);
      String name = m.group(2);
      String typesString = m.group(3).trim();
      // Our regex may result in semicolons on the end...
      // TODO(dantup): Fix this, or make a simple parser.
      if (typesString.endsWith(';')) {
        typesString = typesString.substring(0, typesString.length - 1);
      }
      // Some fields have weird comments like this in the spec:
      //     {@link MessageType}
      // These seem to be the correct type of the field, while the field is
      // marked with number.
      if (comment != null) {
        final RegExp _linkTypePattern = new RegExp(r'See \{@link (\w+)\}\.?');
        final linkTypeMatch = _linkTypePattern.firstMatch(comment);
        if (linkTypeMatch != null) {
          typesString = linkTypeMatch.group(1);
          comment = comment.replaceAll(_linkTypePattern, '');
        }
      }
      final List<String> types = _parseTypes(typesString, '|');
      final bool allowsNull = types.contains('null');
      if (allowsNull) {
        types.remove('null');
      }
      final bool allowsUndefined = name.endsWith('?');
      if (allowsUndefined) {
        name = name.substring(0, name.length - 1);
      }
      return new Field(name, comment, types, allowsNull, allowsUndefined);
    }).toList();
    _sort(fields);
    return fields;
  }
}

/// An Interface parsed from the LSP spec.
class Interface extends ApiItem {
  final List<String> baseTypes;
  final List<Member> members;
  Interface(String name, String comment, this.baseTypes, this.members)
      : super(name, comment);

  static List<Interface> extractFrom(String code) {
    final RegExp _interfacePattern = new RegExp(_comment +
        r'(?:export\s+)?(?:interface|class)\s+(\w+)(?:\s+extends\s+([\w, ]+?))?\s*' +
        _blockBody);

    final interfaces = _interfacePattern.allMatches(code).map((match) {
      final String comment = match.group(1);
      final String name = match.group(2);
      final List<String> baseTypes = _parseTypes(match.group(3), ',');
      final String body = match.group(4);
      final List<Member> members = Member.extractFrom(body);

      // Add any special base classes we've added to simplify types.
      baseTypes.addAll(_getSpecialBaseClasses(name));

      return new Interface(name, comment, baseTypes, members);
    }).toList();
    _sort(interfaces);
    return interfaces;
  }
}

List<String> _getSpecialBaseClasses(String name) {
  const fileOperationTypes = [
    'TextDocumentEdit',
    'CreateFile',
    'RenameFile',
    'DeleteFile'
  ];
  if (fileOperationTypes.contains(name)) {
    return ['FileOperation'];
  } else {
    return [];
  }
}

/// A Field or Constant parsed from the LSP type.
abstract class Member extends ApiItem {
  Member(String name, String comment) : super(name, comment);

  static List<Member> extractFrom(String code) {
    List<Member> members = [];
    members.addAll(Field.extractFrom(code));
    members.addAll(Const.extractFrom(code));
    _sort(members);
    return members;
  }
}

/// A Namespace parsed from the LSP spec. Usually used to hold enum-like
/// Constants.
class Namespace extends ApiItem {
  final List<Member> members;
  Namespace(String name, String comment, this.members) : super(name, comment);

  static List<Namespace> extractFrom(String code) {
    final RegExp _namespacePattern = new RegExp(
        _comment + r'(?:export\s+)?namespace\s+(\w+)\s*' + _blockBody);

    final namespaces = _namespacePattern.allMatches(code).map((match) {
      final String comment = match.group(1);
      final String name = match.group(2);
      final String body = match.group(3);
      final List<Member> members = Member.extractFrom(body);
      return new Namespace(name, comment, members);
    }).toList();
    _sort(namespaces);
    return namespaces;
  }
}

/// A type alias parsed from the LSP spec.
class TypeAlias extends ApiItem {
  final String baseType;
  TypeAlias(name, comment, this.baseType) : super(name, comment);

  static List<TypeAlias> extractFrom(String code) {
    final RegExp _typeAliasPattern =
        new RegExp(_comment + r'type\s+([\w]+)\s+=\s+([\w\[\]]+)\s*;');

    final typeAliases = _typeAliasPattern.allMatches(code).map((match) {
      final String comment = match.group(1);
      final String name = match.group(2);
      final String baseType = match.group(3);
      return new TypeAlias(name, comment, baseType);
    }).toList();
    _sort(typeAliases);
    return typeAliases;
  }
}
