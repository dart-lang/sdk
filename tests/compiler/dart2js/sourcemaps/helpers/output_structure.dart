// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library sourcemap.output_structure;

import 'dart:math' as Math;
import 'html_parts.dart' show CodeLine, JsonStrategy;

// Constants used to identify the subsection of the JavaScript output. These
// are specifically for the unminified full_emitter output.
const String HEAD = '  var dart = [';
const String TAIL = '  }], ';
const String END = '  setupProgram(dart';

final RegExp TOP_LEVEL_VALUE = new RegExp(r'^    (".+?"):');
final RegExp TOP_LEVEL_FUNCTION =
    new RegExp(r'^    ([a-zA-Z0-9_$]+): \[?function');
final RegExp TOP_LEVEL_CLASS = new RegExp(r'^    ([a-zA-Z0-9_$]+): \[?\{');

final RegExp STATICS = new RegExp(r'^      static:');
final RegExp MEMBER_VALUE = new RegExp(r'^      (".+?"):');
final RegExp MEMBER_FUNCTION =
    new RegExp(r'^      ([a-zA-Z0-9_$]+): \[?function');
final RegExp MEMBER_OBJECT = new RegExp(r'^      ([a-zA-Z0-9_$]+): \[?\{');

final RegExp STATIC_FUNCTION =
    new RegExp(r'^        ([a-zA-Z0-9_$]+): \[?function');

/// Subrange of the JavaScript output.
abstract class OutputEntity {
  Interval get interval;
  Interval get header;
  Interval get footer;

  bool get canHaveChildren => false;

  List<OutputEntity> get children;

  CodeSource codeSource;

  Interval getChildInterval(Interval childIndex) {
    return new Interval(children[childIndex.from].interval.from,
        children[childIndex.to - 1].interval.to);
  }

  OutputEntity getChild(int index) {
    return children[index];
  }

  accept(OutputVisitor visitor, arg);

  EntityKind get kind;

  Map toJson(JsonStrategy strategy);

  OutputEntity getEntityForLine(int line);
}

enum EntityKind {
  STRUCTURE,
  LIBRARY,
  CLASS,
  TOP_LEVEL_FUNCTION,
  TOP_LEVEL_VALUE,
  MEMBER_FUNCTION,
  MEMBER_OBJECT,
  MEMBER_VALUE,
  STATICS,
  STATIC_FUNCTION,
}

abstract class OutputVisitor<R, A> {
  R visitStructure(OutputStructure entity, A arg);
  R visitLibrary(LibraryBlock entity, A arg);
  R visitClass(LibraryClass entity, A arg);
  R visitTopLevelFunction(TopLevelFunction entity, A arg);
  R visitTopLevelValue(TopLevelValue entity, A arg);
  R visitMemberObject(MemberObject entity, A arg);
  R visitMemberFunction(MemberFunction entity, A arg);
  R visitMemberValue(MemberValue entity, A arg);
  R visitStatics(Statics entity, A arg);
  R visitStaticFunction(StaticFunction entity, A arg);
}

abstract class BaseOutputVisitor<R, A> extends OutputVisitor<R, A> {
  R visitEntity(OutputEntity entity, A arg) => null;

  R visitStructure(OutputStructure entity, A arg) => visitEntity(entity, arg);
  R visitLibrary(LibraryBlock entity, A arg) => visitEntity(entity, arg);
  R visitClass(LibraryClass entity, A arg) => visitEntity(entity, arg);

  R visitMember(BasicEntity entity, A arg) => visitEntity(entity, arg);

  R visitTopLevelMember(BasicEntity entity, A arg) => visitMember(entity, arg);

  R visitTopLevelFunction(TopLevelFunction entity, A arg) {
    return visitTopLevelMember(entity, arg);
  }

  R visitTopLevelValue(TopLevelValue entity, A arg) {
    return visitTopLevelMember(entity, arg);
  }

  R visitClassMember(BasicEntity entity, A arg) => visitMember(entity, arg);

  R visitMemberObject(MemberObject entity, A arg) {
    return visitClassMember(entity, arg);
  }

  R visitMemberFunction(MemberFunction entity, A arg) {
    return visitClassMember(entity, arg);
  }

  R visitMemberValue(MemberValue entity, A arg) {
    return visitClassMember(entity, arg);
  }

  R visitStatics(Statics entity, A arg) {
    return visitClassMember(entity, arg);
  }

  R visitStaticFunction(StaticFunction entity, A arg) {
    return visitClassMember(entity, arg);
  }
}

/// The whole JavaScript output.
class OutputStructure extends OutputEntity {
  final List<CodeLine> lines;
  final int headerEnd;
  final int footerStart;
  final List<LibraryBlock> children;

  OutputStructure(this.lines, this.headerEnd, this.footerStart, this.children);

  @override
  EntityKind get kind => EntityKind.STRUCTURE;

  Interval get interval => new Interval(0, lines.length);

  Interval get header => new Interval(0, headerEnd);

  Interval get footer => new Interval(footerStart, lines.length);

  bool get canHaveChildren => true;

  OutputEntity getEntityForLine(int line) {
    if (line < headerEnd || line >= footerStart) {
      return this;
    }
    for (LibraryBlock library in children) {
      if (library.interval.contains(line)) {
        return library.getEntityForLine(line);
      }
    }
    return null;
  }

  /// Compute the structure of the JavaScript [lines].
  static OutputStructure parse(List<CodeLine> lines) {
    int findHeaderStart(List<CodeLine> lines) {
      int index = 0;
      for (CodeLine line in lines) {
        if (line.code.startsWith(HEAD)) {
          return index;
        }
        index++;
      }
      return lines.length;
    }

    int findHeaderEnd(int start, List<CodeLine> lines) {
      int index = start;
      for (CodeLine line in lines.skip(start)) {
        if (line.code.startsWith(END)) {
          return index;
        }
        index++;
      }
      return lines.length;
    }

    String readHeader(CodeLine line) {
      String code = line.code;
      if (code.startsWith(HEAD)) {
        return code.substring(HEAD.length);
      } else if (code.startsWith(TAIL)) {
        return code.substring(TAIL.length);
      }
      return null;
    }

    List<LibraryBlock> computeHeaderMap(
        List<CodeLine> lines, int start, int end) {
      List<LibraryBlock> libraryBlocks = <LibraryBlock>[];
      LibraryBlock current;
      for (int index = start; index < end; index++) {
        String header = readHeader(lines[index]);
        if (header != null) {
          if (current != null) {
            current.to = index;
          }
          libraryBlocks.add(current = new LibraryBlock(header, index));
        }
      }
      if (current != null) {
        current.to = end;
      }
      return libraryBlocks;
    }

    int headerEnd = findHeaderStart(lines);
    int footerStart = findHeaderEnd(headerEnd, lines);
    List<LibraryBlock> libraryBlocks =
        computeHeaderMap(lines, headerEnd, footerStart);
    for (LibraryBlock block in libraryBlocks) {
      block.preprocess(lines);
    }

    return new OutputStructure(lines, headerEnd, footerStart, libraryBlocks);
  }

  accept(OutputVisitor visitor, arg) => visitor.visitStructure(this, arg);

  @override
  Map toJson(JsonStrategy strategy) {
    return {
      'lines': lines.map((line) => line.toJson(strategy)).toList(),
      'headerEnd': headerEnd,
      'footerStart': footerStart,
      'children': children.map((child) => child.toJson(strategy)).toList(),
    };
  }

  static OutputStructure fromJson(Map json, JsonStrategy strategy) {
    List<CodeLine> lines =
        json['lines'].map((l) => CodeLine.fromJson(l, strategy)).toList();
    int headerEnd = json['headerEnd'];
    int footerStart = json['footerStart'];
    List<LibraryBlock> children = json['children']
        .map((j) => AbstractEntity.fromJson(j, strategy))
        .toList();
    return new OutputStructure(lines, headerEnd, footerStart, children);
  }
}

abstract class AbstractEntity extends OutputEntity {
  final String name;
  final int from;
  int to;

  AbstractEntity(this.name, this.from);

  Interval get interval => new Interval(from, to);

  @override
  Map toJson(JsonStrategy strategy) {
    return {
      'kind': kind.index,
      'name': name,
      'from': from,
      'to': to,
      'children': children.map((child) => child.toJson(strategy)).toList(),
      'codeSource': codeSource != null ? codeSource.toJson() : null,
    };
  }

  static AbstractEntity fromJson(Map json, JsonStrategy strategy) {
    EntityKind kind = EntityKind.values[json['kind']];
    String name = json['name'];
    int from = json['from'];
    int to = json['to'];
    CodeSource codeSource = CodeSource.fromJson(json['codeSource']);

    switch (kind) {
      case EntityKind.STRUCTURE:
        throw new StateError('Unexpected entity kind $kind');
      case EntityKind.LIBRARY:
        LibraryBlock lib = new LibraryBlock(name, from)
          ..to = to
          ..codeSource = codeSource;
        json['children']
            .forEach((child) => lib.children.add(fromJson(child, strategy)));
        return lib;
      case EntityKind.CLASS:
        LibraryClass cls = new LibraryClass(name, from)
          ..to = to
          ..codeSource = codeSource;
        json['children']
            .forEach((child) => cls.children.add(fromJson(child, strategy)));
        return cls;
      case EntityKind.TOP_LEVEL_FUNCTION:
        return new TopLevelFunction(name, from)
          ..to = to
          ..codeSource = codeSource;
      case EntityKind.TOP_LEVEL_VALUE:
        return new TopLevelValue(name, from)
          ..to = to
          ..codeSource = codeSource;
      case EntityKind.MEMBER_FUNCTION:
        return new MemberFunction(name, from)
          ..to = to
          ..codeSource = codeSource;
      case EntityKind.MEMBER_OBJECT:
        return new MemberObject(name, from)
          ..to = to
          ..codeSource = codeSource;
      case EntityKind.MEMBER_VALUE:
        return new MemberValue(name, from)
          ..to = to
          ..codeSource = codeSource;
      case EntityKind.STATICS:
        Statics statics = new Statics(from)
          ..to = to
          ..codeSource = codeSource;
        json['children'].forEach(
            (child) => statics.children.add(fromJson(child, strategy)));
        return statics;
      case EntityKind.STATIC_FUNCTION:
        return new StaticFunction(name, from)
          ..to = to
          ..codeSource = codeSource;
    }
    throw "Unhandled: $kind";
  }
}

/// A block defining the content of a Dart library.
class LibraryBlock extends AbstractEntity {
  List<BasicEntity> children = <BasicEntity>[];
  int get headerEnd => from + 2;
  int get footerStart => to /* - 1*/;

  LibraryBlock(String name, int from) : super(name, from);

  @override
  EntityKind get kind => EntityKind.LIBRARY;

  Interval get header => new Interval(from, headerEnd);

  Interval get footer => new Interval(footerStart, to);

  bool get canHaveChildren => true;

  void preprocess(List<CodeLine> lines) {
    int index = headerEnd;
    BasicEntity current;
    while (index < footerStart) {
      String line = lines[index].code;
      BasicEntity next;
      Match matchFunction = TOP_LEVEL_FUNCTION.firstMatch(line);
      if (matchFunction != null) {
        next = new TopLevelFunction(matchFunction.group(1), index);
      } else {
        Match matchClass = TOP_LEVEL_CLASS.firstMatch(line);
        if (matchClass != null) {
          next = new LibraryClass(matchClass.group(1), index);
        } else {
          Match matchValue = TOP_LEVEL_VALUE.firstMatch(line);
          if (matchValue != null) {
            next = new TopLevelValue(matchValue.group(1), index);
          }
        }
      }
      if (next != null) {
        if (current != null) {
          current.to = index;
        }
        children.add(current = next);
      } else if (index == headerEnd) {
        throw 'Failed to match first library block line:\n$line';
      }

      index++;
    }
    if (current != null) {
      current.to = footerStart;
    }

    for (BasicEntity entity in children) {
      entity.preprocess(lines);
    }
  }

  accept(OutputVisitor visitor, arg) => visitor.visitLibrary(this, arg);

  OutputEntity getEntityForLine(int line) {
    if (line < headerEnd || line >= footerStart) {
      return this;
    }
    for (BasicEntity child in children) {
      if (child.interval.contains(line)) {
        return child.getEntityForLine(line);
      }
    }
    return null;
  }
}

/// A simple member of a library or class.
abstract class BasicEntity extends AbstractEntity {
  BasicEntity(String name, int from) : super(name, from);

  Interval get header => new Interval(from, to);

  Interval get footer => new Interval(to, to);

  List<OutputEntity> get children => const <OutputEntity>[];

  void preprocess(List<CodeLine> lines) {}

  @override
  OutputEntity getEntityForLine(int line) {
    if (interval.contains(line)) {
      return this;
    }
    return null;
  }
}

class TopLevelFunction extends BasicEntity {
  TopLevelFunction(String name, int from) : super(name, from);

  @override
  EntityKind get kind => EntityKind.TOP_LEVEL_FUNCTION;

  accept(OutputVisitor visitor, arg) {
    return visitor.visitTopLevelFunction(this, arg);
  }
}

class TopLevelValue extends BasicEntity {
  TopLevelValue(String name, int from) : super(name, from);

  @override
  EntityKind get kind => EntityKind.TOP_LEVEL_VALUE;

  accept(OutputVisitor visitor, arg) {
    return visitor.visitTopLevelValue(this, arg);
  }
}

/// A block defining a Dart class.
class LibraryClass extends BasicEntity {
  List<BasicEntity> children = <BasicEntity>[];
  int get headerEnd => from + 1;
  int get footerStart => to - 1;

  LibraryClass(String name, int from) : super(name, from);

  @override
  EntityKind get kind => EntityKind.CLASS;

  Interval get header => new Interval(from, headerEnd);

  Interval get footer => new Interval(footerStart, to);

  bool get canHaveChildren => true;

  void preprocess(List<CodeLine> lines) {
    int index = headerEnd;
    BasicEntity current;
    while (index < footerStart) {
      String line = lines[index].code;
      BasicEntity next;
      Match match = MEMBER_FUNCTION.firstMatch(line);
      if (match != null) {
        next = new MemberFunction(match.group(1), index);
      } else {
        match = STATICS.firstMatch(line);
        if (match != null) {
          next = new Statics(index);
        } else {
          match = MEMBER_OBJECT.firstMatch(line);
          if (match != null) {
            next = new MemberObject(match.group(1), index);
          } else {
            match = MEMBER_VALUE.firstMatch(line);
            if (match != null) {
              next = new MemberValue(match.group(1), index);
            }
          }
        }
      }
      if (next != null) {
        if (current != null) {
          current.to = index;
        }
        children.add(current = next);
      } else if (index == headerEnd) {
        throw 'Failed to match first library block line:\n$line';
      }

      index++;
    }
    if (current != null) {
      current.to = footerStart;
    }

    for (BasicEntity entity in children) {
      entity.preprocess(lines);
    }
  }

  accept(OutputVisitor visitor, arg) => visitor.visitClass(this, arg);

  OutputEntity getEntityForLine(int line) {
    if (line < headerEnd || line >= footerStart) {
      return this;
    }
    for (BasicEntity child in children) {
      if (child.interval.contains(line)) {
        return child.getEntityForLine(line);
      }
    }
    return null;
  }
}

/// A block defining static members of a Dart class.
class Statics extends BasicEntity {
  List<BasicEntity> children = <BasicEntity>[];
  int get headerEnd => from + 1;
  int get footerStart => to - 1;

  Statics(int from) : super('statics', from);

  @override
  EntityKind get kind => EntityKind.STATICS;

  Interval get header => new Interval(from, headerEnd);

  Interval get footer => new Interval(footerStart, to);

  bool get canHaveChildren => true;

  void preprocess(List<CodeLine> lines) {
    int index = headerEnd;
    BasicEntity current;
    while (index < footerStart) {
      String line = lines[index].code;
      BasicEntity next;
      Match matchFunction = STATIC_FUNCTION.firstMatch(line);
      if (matchFunction != null) {
        next = new MemberFunction(matchFunction.group(1), index);
      }
      if (next != null) {
        if (current != null) {
          current.to = index;
        }
        children.add(current = next);
      } else if (index == headerEnd) {
        throw 'Failed to match first statics line:\n$line';
      }

      index++;
    }
    if (current != null) {
      current.to = footerStart;
    }
  }

  accept(OutputVisitor visitor, arg) => visitor.visitStatics(this, arg);

  OutputEntity getEntityForLine(int line) {
    if (line < headerEnd || line >= footerStart) {
      return this;
    }
    for (BasicEntity child in children) {
      if (child.interval.contains(line)) {
        return child.getEntityForLine(line);
      }
    }
    return null;
  }
}

class MemberFunction extends BasicEntity {
  MemberFunction(String name, int from) : super(name, from);

  @override
  EntityKind get kind => EntityKind.MEMBER_FUNCTION;

  accept(OutputVisitor visitor, arg) => visitor.visitMemberFunction(this, arg);
}

class MemberObject extends BasicEntity {
  MemberObject(String name, int from) : super(name, from);

  @override
  EntityKind get kind => EntityKind.MEMBER_OBJECT;

  accept(OutputVisitor visitor, arg) => visitor.visitMemberObject(this, arg);
}

class MemberValue extends BasicEntity {
  MemberValue(String name, int from) : super(name, from);

  @override
  EntityKind get kind => EntityKind.MEMBER_VALUE;

  accept(OutputVisitor visitor, arg) => visitor.visitMemberValue(this, arg);
}

class StaticFunction extends BasicEntity {
  StaticFunction(String name, int from) : super(name, from);

  @override
  EntityKind get kind => EntityKind.STATIC_FUNCTION;

  accept(OutputVisitor visitor, arg) => visitor.visitStaticFunction(this, arg);
}

class Interval {
  final int from;
  final int to;

  const Interval(this.from, this.to);

  int get length => to - from;

  bool get isEmpty => from == to;

  bool contains(int value) {
    return from <= value && value < to;
  }

  Interval include(int index) {
    return new Interval(Math.min(from, index), Math.max(to, index + 1));
  }

  bool inWindow(int index, {int windowSize: 0}) {
    return from - windowSize <= index && index < to + windowSize;
  }

  String toString() => '[$from,$to[';
}

enum CodeKind {
  LIBRARY,
  CLASS,
  MEMBER,
}

class CodeLocation {
  final Uri uri;
  final String name;
  final int offset;

  CodeLocation(this.uri, this.name, this.offset);

  String toString() => '$uri:$name:$offset';

  Map toJson(JsonStrategy strategy) {
    return {
      'uri': uri.toString(),
      'name': name,
      'offset': offset,
    };
  }

  static CodeLocation fromJson(Map json, JsonStrategy strategy) {
    if (json == null) return null;
    return new CodeLocation(
        Uri.parse(json['uri']), json['name'], json['offset']);
  }
}

/// A named entity in source code. This is used to serialize [Element]
/// references without serializing the [Element] itself.
class CodeSource {
  final CodeKind kind;
  final Uri uri;
  final String name;
  final int begin;
  final int end;
  final List<CodeSource> members = <CodeSource>[];

  CodeSource(this.kind, this.uri, this.name, this.begin, this.end);

  int get hashCode {
    return kind.hashCode * 13 +
        uri.hashCode * 17 +
        name.hashCode * 19 +
        begin.hashCode * 23;
  }

  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! CodeSource) return false;
    return kind == other.kind &&
        uri == other.uri &&
        name == other.name &&
        begin == other.begin;
  }

  String toString() => '${toJson()}';

  Map toJson() {
    return {
      'kind': kind.index,
      'uri': uri.toString(),
      'name': name,
      'begin': begin,
      'end': end,
      'members': members.map((c) => c.toJson()).toList(),
    };
  }

  static CodeSource fromJson(Map json) {
    if (json == null) return null;
    CodeSource codeSource = new CodeSource(CodeKind.values[json['kind']],
        Uri.parse(json['uri']), json['name'], json['begin'], json['end']);
    json['members'].forEach((m) => codeSource.members.add(fromJson(m)));
    return codeSource;
  }
}
