// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

enum IdKind {
  member,
  cls,
  node,
  invoke,
  update,
  iterator,
  current,
  moveNext,
  stmt,
}

/// Id for a code point or element.
abstract class Id {
  IdKind get kind;
  bool get isGlobal;

  /// Display name for this id.
  String get descriptor;
}

class IdValue {
  final Id id;
  final String value;

  const IdValue(this.id, this.value);

  @override
  int get hashCode => id.hashCode * 13 + value.hashCode * 17;

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! IdValue) return false;
    return id == other.id && value == other.value;
  }

  @override
  String toString() => idToString(id, value);

  static String idToString(Id id, String value) {
    switch (id.kind) {
      case IdKind.member:
        MemberId elementId = id;
        return '$memberPrefix${elementId.name}:$value';
      case IdKind.cls:
        ClassId classId = id;
        return '$classPrefix${classId.name}:$value';
      case IdKind.node:
        return value;
      case IdKind.invoke:
        return '$invokePrefix$value';
      case IdKind.update:
        return '$updatePrefix$value';
      case IdKind.iterator:
        return '$iteratorPrefix$value';
      case IdKind.current:
        return '$currentPrefix$value';
      case IdKind.moveNext:
        return '$moveNextPrefix$value';
      case IdKind.stmt:
        return '$stmtPrefix$value';
    }
    throw new UnsupportedError("Unexpected id kind: ${id.kind}");
  }

  static const String globalPrefix = "global#";
  static const String memberPrefix = "member: ";
  static const String classPrefix = "class: ";
  static const String invokePrefix = "invoke: ";
  static const String updatePrefix = "update: ";
  static const String iteratorPrefix = "iterator: ";
  static const String currentPrefix = "current: ";
  static const String moveNextPrefix = "moveNext: ";
  static const String stmtPrefix = "stmt: ";

  static IdValue decode(int offset, String text) {
    Id id;
    String expected;
    if (text.startsWith(memberPrefix)) {
      text = text.substring(memberPrefix.length);
      int colonPos = text.indexOf(':');
      if (colonPos == -1) throw "Invalid element id: '$text'";
      String name = text.substring(0, colonPos);
      bool isGlobal = name.startsWith(globalPrefix);
      if (isGlobal) {
        name = name.substring(globalPrefix.length);
      }
      id = new MemberId(name, isGlobal: isGlobal);
      expected = text.substring(colonPos + 1);
    } else if (text.startsWith(classPrefix)) {
      text = text.substring(classPrefix.length);
      int colonPos = text.indexOf(':');
      if (colonPos == -1) throw "Invalid class id: '$text'";
      String name = text.substring(0, colonPos);
      bool isGlobal = name.startsWith(globalPrefix);
      if (isGlobal) {
        name = name.substring(globalPrefix.length);
      }
      id = new ClassId(name, isGlobal: isGlobal);
      expected = text.substring(colonPos + 1);
    } else if (text.startsWith(invokePrefix)) {
      id = new NodeId(offset, IdKind.invoke);
      expected = text.substring(invokePrefix.length);
    } else if (text.startsWith(updatePrefix)) {
      id = new NodeId(offset, IdKind.update);
      expected = text.substring(updatePrefix.length);
    } else if (text.startsWith(iteratorPrefix)) {
      id = new NodeId(offset, IdKind.iterator);
      expected = text.substring(iteratorPrefix.length);
    } else if (text.startsWith(currentPrefix)) {
      id = new NodeId(offset, IdKind.current);
      expected = text.substring(currentPrefix.length);
    } else if (text.startsWith(moveNextPrefix)) {
      id = new NodeId(offset, IdKind.moveNext);
      expected = text.substring(moveNextPrefix.length);
    } else if (text.startsWith(stmtPrefix)) {
      id = new NodeId(offset, IdKind.stmt);
      expected = text.substring(stmtPrefix.length);
    } else {
      id = new NodeId(offset, IdKind.node);
      expected = text;
    }
    // Remove newlines.
    expected = expected.replaceAll(new RegExp(r'\s*(\n\s*)+\s*'), '');
    return new IdValue(id, expected);
  }
}

/// Id for an member element.
class MemberId implements Id {
  final String className;
  final String memberName;
  @override
  final bool isGlobal;

  factory MemberId(String text, {bool isGlobal: false}) {
    int dotPos = text.indexOf('.');
    if (dotPos != -1) {
      return new MemberId.internal(text.substring(dotPos + 1),
          className: text.substring(0, dotPos), isGlobal: isGlobal);
    } else {
      return new MemberId.internal(text, isGlobal: isGlobal);
    }
  }

  MemberId.internal(this.memberName, {this.className, this.isGlobal: false});

  @override
  int get hashCode => className.hashCode * 13 + memberName.hashCode * 17;

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! MemberId) return false;
    return className == other.className && memberName == other.memberName;
  }

  @override
  IdKind get kind => IdKind.member;

  String get name => className != null ? '$className.$memberName' : memberName;

  @override
  String get descriptor => 'member $name';

  @override
  String toString() => 'member:$name';
}

/// Id for a class.
class ClassId implements Id {
  final String className;
  @override
  final bool isGlobal;

  ClassId(this.className, {this.isGlobal: false});

  @override
  int get hashCode => className.hashCode * 13;

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! ClassId) return false;
    return className == other.className;
  }

  @override
  IdKind get kind => IdKind.cls;

  String get name => className;

  @override
  String get descriptor => 'class $name';

  @override
  String toString() => 'class:$name';
}

/// Id for a code point.
class NodeId implements Id {
  final int value;
  @override
  final IdKind kind;

  const NodeId(this.value, this.kind);

  @override
  bool get isGlobal => false;

  @override
  int get hashCode => value.hashCode * 13 + kind.hashCode * 17;

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! NodeId) return false;
    return value == other.value && kind == other.kind;
  }

  @override
  String get descriptor => 'offset $value ($kind)';

  @override
  String toString() => '$kind:$value';
}

class ActualData<T> {
  final Id id;
  final T value;
  final Uri uri;
  final int _offset;
  final Object object;

  ActualData(this.id, this.value, this.uri, this._offset, this.object);

  int get offset {
    if (id is NodeId) {
      NodeId nodeId = id;
      return nodeId.value;
    } else {
      return _offset;
    }
  }

  String get objectText {
    return 'object `${'$object'.replaceAll('\n', '')}` (${object.runtimeType})';
  }

  @override
  String toString() => 'ActualData(id=$id,value=$value,uri=$uri,'
      'offset=$offset,object=$objectText)';
}

abstract class DataRegistry<T> {
  Map<Id, ActualData<T>> get actualMap;

  void registerValue(Uri uri, int offset, Id id, T value, Object object) {
    if (actualMap.containsKey(id)) {
      ActualData<T> existingData = actualMap[id];
      report(uri, offset, "Duplicate id ${id}, value=$value, object=$object");
      report(
          uri,
          offset,
          "Duplicate id ${id}, value=${existingData.value}, "
          "object=${existingData.object}");
      fail("Duplicate id $id.");
    }
    if (value != null) {
      actualMap[id] = new ActualData<T>(id, value, uri, offset, object);
    }
  }

  void report(Uri uri, int offset, String message);

  void fail(String message);
}
