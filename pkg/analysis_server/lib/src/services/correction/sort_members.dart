// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/organize_imports.dart';
import 'package:analysis_server/src/utilities/extensions/range_factory.dart';
import 'package:analysis_server/src/utilities/strings.dart';
import 'package:analyzer/dart/analysis/code_style_options.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' hide Element;
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// Sorter for unit/class members.
class MemberSorter {
  final String initialCode;

  final CompilationUnit unit;

  final LineInfo lineInfo;

  final String endOfLine;

  final List<_PriorityItem> _priorityItems;

  String code;

  MemberSorter(
    this.initialCode,
    this.unit,
    CodeStyleOptions codeStyle,
    this.lineInfo,
  ) : endOfLine = getEOL(initialCode),
      code = initialCode,
      _priorityItems = _getPriorityItems(codeStyle);

  /// Return the [SourceEdit]s that sort [unit].
  List<SourceEdit> sort() {
    _sortClassesMembers();
    _sortUnitMembers();
    // Must sort unit directives last because it may insert newlines, which
    // would confuse the offsets used by the other sort functions.
    _sortUnitDirectives();
    // prepare edits
    var edits = <SourceEdit>[];
    if (code != initialCode) {
      var diff = computeSimpleDiff(initialCode, code);
      var edit = SourceEdit(diff.offset, diff.length, diff.replacement);
      edits.add(edit);
    }
    return edits;
  }

  int _getPriority(_PriorityItem item) {
    var priority = _priorityItems.indexOf(item);
    return priority != -1 ? priority : 0;
  }

  List<_MemberInfo> _getSortedMembers(List<_MemberInfo> members) {
    var membersSorted = List.of(members);
    membersSorted.sort((_MemberInfo o1, _MemberInfo o2) {
      var priority1 = _getPriority(o1.item);
      var priority2 = _getPriority(o2.item);
      if (priority1 == priority2) {
        // don't reorder class fields
        if (o1.item.kind == _MemberKind.CLASS_FIELD) {
          return o1.offset - o2.offset;
        }
        // sort all other members by name
        var name1 = o1.name.toLowerCase();
        var name = o2.name.toLowerCase();
        return name1.compareTo(name);
      }
      return priority1 - priority2;
    });
    return membersSorted;
  }

  void _sortAndReorderMembers(List<_MemberInfo> members) {
    var membersSorted = _getSortedMembers(members);
    var size = membersSorted.length;
    for (var i = 0; i < size; i++) {
      var newInfo = membersSorted[size - 1 - i];
      var oldInfo = members[size - 1 - i];
      if (newInfo != oldInfo) {
        var beforeCode = code.substring(0, oldInfo.offset);
        var afterCode = code.substring(oldInfo.end);
        code = beforeCode + newInfo.text + afterCode;
      }
    }
  }

  /// Sorts all class members.
  void _sortClassesMembers() {
    for (var unitMember in unit.declarations) {
      if (unitMember is ClassDeclaration) {
        _sortClassMembers(unitMember.members);
      } else if (unitMember is EnumDeclaration) {
        _sortClassMembers(unitMember.members);
      } else if (unitMember is ExtensionDeclaration) {
        _sortClassMembers(unitMember.members);
      } else if (unitMember is ExtensionTypeDeclaration) {
        _sortClassMembers(unitMember.members);
      } else if (unitMember is MixinDeclaration) {
        _sortClassMembers(unitMember.members);
      }
    }
  }

  /// Sorts the [membersToSort].
  void _sortClassMembers(List<ClassMember> membersToSort) {
    var members = <_MemberInfo>[];
    for (var member in membersToSort) {
      _MemberKind kind;
      var isStatic = false;
      String name;
      if (member is ConstructorDeclaration) {
        kind = _MemberKind.CLASS_CONSTRUCTOR;
        name = member.name?.lexeme ?? '';
      } else if (member is FieldDeclaration) {
        var fieldDeclaration = member;
        List<VariableDeclaration> fields = fieldDeclaration.fields.variables;
        if (fields.isNotEmpty) {
          kind = _MemberKind.CLASS_FIELD;
          isStatic = fieldDeclaration.isStatic;
          name = fields[0].name.lexeme;
        } else {
          // Don't sort members if there are errors in the code.
          return;
        }
      } else if (member is MethodDeclaration) {
        var method = member;
        isStatic = method.isStatic;
        name = method.name.lexeme;
        if (method.isGetter) {
          kind = _MemberKind.CLASS_ACCESSOR;
          name += ' getter';
        } else if (method.isSetter) {
          kind = _MemberKind.CLASS_ACCESSOR;
          name += ' setter';
        } else {
          kind = _MemberKind.CLASS_METHOD;
        }
      } else {
        throw StateError('Unsupported class of member: ${member.runtimeType}');
      }
      var item = _PriorityItem.forName(isStatic, name, kind);
      var nodeRange = range.nodeWithComments(lineInfo, member);
      var offset = nodeRange.offset;
      var length = nodeRange.length;
      var text = code.substring(offset, offset + length);
      members.add(_MemberInfo(item, name, offset, length, text));
    }
    // do sort
    _sortAndReorderMembers(members);
  }

  /// Sorts all [Directive]s.
  void _sortUnitDirectives() {
    var importOrganizer = ImportOrganizer(code, unit, [], removeUnused: false);
    importOrganizer.organize();
    code = importOrganizer.code;
  }

  /// Sorts all [CompilationUnitMember]s.
  void _sortUnitMembers() {
    var members = <_MemberInfo>[];
    for (var member in unit.declarations) {
      _MemberKind kind;
      String name;
      if (member is ClassDeclaration) {
        kind = _MemberKind.UNIT_CLASS;
        name = member.name.lexeme;
      } else if (member is ClassTypeAlias) {
        kind = _MemberKind.UNIT_CLASS;
        name = member.name.lexeme;
      } else if (member is EnumDeclaration) {
        kind = _MemberKind.UNIT_CLASS;
        name = member.name.lexeme;
      } else if (member is ExtensionTypeDeclaration) {
        kind = _MemberKind.UNIT_EXTENSION_TYPE;
        name = member.name.lexeme;
      } else if (member is ExtensionDeclaration) {
        kind = _MemberKind.UNIT_EXTENSION;
        name = member.name?.lexeme ?? '';
      } else if (member is FunctionDeclaration) {
        name = member.name.lexeme;
        if (member.isGetter) {
          kind = _MemberKind.UNIT_ACCESSOR;
          name += ' getter';
        } else if (member.isSetter) {
          kind = _MemberKind.UNIT_ACCESSOR;
          name += ' setter';
        } else {
          if (name == 'main') {
            kind = _MemberKind.UNIT_FUNCTION_MAIN;
          } else {
            kind = _MemberKind.UNIT_FUNCTION;
          }
        }
      } else if (member is FunctionTypeAlias) {
        kind = _MemberKind.UNIT_FUNCTION_TYPE;
        name = member.name.lexeme;
      } else if (member is GenericTypeAlias) {
        kind = _MemberKind.UNIT_GENERIC_TYPE_ALIAS;
        name = member.name.lexeme;
      } else if (member is MixinDeclaration) {
        kind = _MemberKind.UNIT_CLASS;
        name = member.name.lexeme;
      } else if (member is TopLevelVariableDeclaration) {
        var variableDeclaration = member;
        List<VariableDeclaration> variables =
            variableDeclaration.variables.variables;
        if (variables.isNotEmpty) {
          if (variableDeclaration.variables.isConst) {
            kind = _MemberKind.UNIT_VARIABLE_CONST;
          } else {
            kind = _MemberKind.UNIT_VARIABLE;
          }
          name = variables[0].name.lexeme;
        } else {
          // Don't sort members if there are errors in the code.
          return;
        }
      } else {
        throw StateError('Unsupported class of member: ${member.runtimeType}');
      }
      var item = _PriorityItem.forName(false, name, kind);
      var nodeRange = range.nodeWithComments(lineInfo, member);
      var offset = nodeRange.offset;
      var length = nodeRange.length;
      var text = code.substring(offset, offset + length);
      members.add(_MemberInfo(item, name, offset, length, text));
    }
    // do sort
    _sortAndReorderMembers(members);
  }

  /// Return the EOL to use for [code].
  static String getEOL(String code) {
    if (code.contains('\r\n')) {
      return '\r\n';
    } else {
      return '\n';
    }
  }

  static List<_PriorityItem> _getPriorityItems(CodeStyleOptions codeStyle) {
    return [
      _PriorityItem(false, _MemberKind.UNIT_FUNCTION_MAIN, false),
      _PriorityItem(false, _MemberKind.UNIT_VARIABLE_CONST, false),
      _PriorityItem(false, _MemberKind.UNIT_VARIABLE_CONST, true),
      _PriorityItem(false, _MemberKind.UNIT_VARIABLE, false),
      _PriorityItem(false, _MemberKind.UNIT_VARIABLE, true),
      _PriorityItem(false, _MemberKind.UNIT_ACCESSOR, false),
      _PriorityItem(false, _MemberKind.UNIT_ACCESSOR, true),
      _PriorityItem(false, _MemberKind.UNIT_FUNCTION, false),
      _PriorityItem(false, _MemberKind.UNIT_FUNCTION, true),
      _PriorityItem(false, _MemberKind.UNIT_GENERIC_TYPE_ALIAS, false),
      _PriorityItem(false, _MemberKind.UNIT_GENERIC_TYPE_ALIAS, true),
      _PriorityItem(false, _MemberKind.UNIT_FUNCTION_TYPE, false),
      _PriorityItem(false, _MemberKind.UNIT_FUNCTION_TYPE, true),
      _PriorityItem(false, _MemberKind.UNIT_CLASS, false),
      _PriorityItem(false, _MemberKind.UNIT_CLASS, true),
      _PriorityItem(false, _MemberKind.UNIT_EXTENSION_TYPE, false),
      _PriorityItem(false, _MemberKind.UNIT_EXTENSION_TYPE, true),
      _PriorityItem(false, _MemberKind.UNIT_EXTENSION, false),
      _PriorityItem(false, _MemberKind.UNIT_EXTENSION, true),
      if (codeStyle.sortConstructorsFirst)
        _PriorityItem(false, _MemberKind.CLASS_CONSTRUCTOR, false),
      if (codeStyle.sortConstructorsFirst)
        _PriorityItem(false, _MemberKind.CLASS_CONSTRUCTOR, true),
      _PriorityItem(true, _MemberKind.CLASS_FIELD, false),
      _PriorityItem(true, _MemberKind.CLASS_ACCESSOR, false),
      _PriorityItem(true, _MemberKind.CLASS_ACCESSOR, true),
      _PriorityItem(false, _MemberKind.CLASS_FIELD, false),
      if (!codeStyle.sortConstructorsFirst)
        _PriorityItem(false, _MemberKind.CLASS_CONSTRUCTOR, false),
      if (!codeStyle.sortConstructorsFirst)
        _PriorityItem(false, _MemberKind.CLASS_CONSTRUCTOR, true),
      _PriorityItem(false, _MemberKind.CLASS_ACCESSOR, false),
      _PriorityItem(false, _MemberKind.CLASS_ACCESSOR, true),
      _PriorityItem(false, _MemberKind.CLASS_METHOD, false),
      _PriorityItem(false, _MemberKind.CLASS_METHOD, true),
      _PriorityItem(true, _MemberKind.CLASS_METHOD, false),
      _PriorityItem(true, _MemberKind.CLASS_METHOD, true),
    ];
  }
}

class _MemberInfo {
  final _PriorityItem item;
  final String name;
  final int offset;
  final int length;
  final int end;
  final String text;

  _MemberInfo(this.item, this.name, this.offset, this.length, this.text)
    : end = offset + length;

  @override
  String toString() {
    return '(priority=$item; name=$name; offset=$offset; length=$length)';
  }
}

enum _MemberKind {
  CLASS_ACCESSOR,
  CLASS_CONSTRUCTOR,
  CLASS_FIELD,
  CLASS_METHOD,
  UNIT_ACCESSOR,
  UNIT_CLASS,
  UNIT_EXTENSION,
  UNIT_EXTENSION_TYPE,
  UNIT_FUNCTION,
  UNIT_FUNCTION_MAIN,
  UNIT_FUNCTION_TYPE,
  UNIT_GENERIC_TYPE_ALIAS,
  UNIT_VARIABLE,
  UNIT_VARIABLE_CONST,
}

class _PriorityItem {
  final _MemberKind kind;
  final bool isPrivate;
  final bool isStatic;

  _PriorityItem(this.isStatic, this.kind, this.isPrivate);

  factory _PriorityItem.forName(bool isStatic, String name, _MemberKind kind) {
    var isPrivate = Identifier.isPrivateName(name);
    return _PriorityItem(isStatic, kind, isPrivate);
  }

  @override
  int get hashCode => Object.hash(kind, isPrivate, isStatic);

  @override
  bool operator ==(Object obj) {
    var other = obj as _PriorityItem;
    if (kind == _MemberKind.CLASS_FIELD) {
      return other.kind == kind && other.isStatic == isStatic;
    }
    return other.kind == kind &&
        other.isPrivate == isPrivate &&
        other.isStatic == isStatic;
  }

  @override
  String toString() => kind.toString();
}
