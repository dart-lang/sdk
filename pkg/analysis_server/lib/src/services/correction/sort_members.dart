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
  final String _initialCode;

  final CompilationUnit _unit;

  final LineInfo _lineInfo;

  final List<_PriorityItem> _priorityItems;

  String code;

  MemberSorter(
    this._initialCode,
    this._unit,
    CodeStyleOptions codeStyle,
    this._lineInfo,
  ) : _priorityItems = _getPriorityItems(codeStyle),
      code = _initialCode;

  /// Returns the [SourceEdit]s that sort [_unit].
  List<SourceEdit> sort() {
    _sortClassesMembers();
    _sortUnitMembers();
    // Must sort unit directives last because it may insert newlines, which
    // would confuse the offsets used by the other sort functions.
    _sortUnitDirectives();
    // prepare edits
    var edits = <SourceEdit>[];
    if (code != _initialCode) {
      var diff = computeSimpleDiff(_initialCode, code);
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
        if (o1.item.kind == _MemberKind.classField) {
          return o1.offset - o2.offset;
        }
        // sort all other members by name
        var name1 = o1.name.toLowerCase();
        var name = o2.name.toLowerCase();
        var result = name1.compareTo(name);
        if (result == 0) {
          result = o1.name.compareTo(o2.name);
        }
        if (result == 0) {
          // don't reorder then.
          result = o1.offset - o2.offset;
        }
        return result;
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
    for (var unitMember in _unit.declarations) {
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
        kind = _MemberKind.classConstructor;
        name = member.name?.lexeme ?? '';
      } else if (member is FieldDeclaration) {
        var fieldDeclaration = member;
        List<VariableDeclaration> fields = fieldDeclaration.fields.variables;
        if (fields.isNotEmpty) {
          kind = _MemberKind.classField;
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
          kind = _MemberKind.classAccessor;
          name += ' getter';
        } else if (method.isSetter) {
          kind = _MemberKind.classAccessor;
          name += ' setter';
        } else {
          kind = _MemberKind.classMethod;
        }
      } else {
        throw StateError('Unsupported class of member: ${member.runtimeType}');
      }
      var item = _PriorityItem.forName(isStatic, name, kind);
      var nodeRange = range.nodeWithComments(_lineInfo, member);
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
    var importOrganizer = ImportOrganizer(code, _unit, [], removeUnused: false);
    importOrganizer.organize();
    code = importOrganizer.code;
  }

  /// Sorts all [CompilationUnitMember]s.
  void _sortUnitMembers() {
    var members = <_MemberInfo>[];
    for (var member in _unit.declarations) {
      _MemberKind kind;
      String name;
      switch (member) {
        case ClassDeclaration():
          kind = _MemberKind.unitClass;
          name = member.name.lexeme;
        case ClassTypeAlias():
          kind = _MemberKind.unitClass;
          name = member.name.lexeme;
        case EnumDeclaration():
          kind = _MemberKind.unitClass;
          name = member.name.lexeme;
        case ExtensionTypeDeclaration():
          kind = _MemberKind.unitExtensionType;
          name = member.name.lexeme;
        case ExtensionDeclaration():
          kind = _MemberKind.unitExtension;
          name = member.name?.lexeme ?? '';
        case FunctionDeclaration():
          name = member.name.lexeme;
          if (member.isGetter) {
            kind = _MemberKind.unitAccessor;
            name += ' getter';
          } else if (member.isSetter) {
            kind = _MemberKind.unitAccessor;
            name += ' setter';
          } else {
            if (name == 'main') {
              kind = _MemberKind.unitFunctionMain;
            } else {
              kind = _MemberKind.unitFunction;
            }
          }
        case FunctionTypeAlias():
          kind = _MemberKind.unitFunctionType;
          name = member.name.lexeme;
        case GenericTypeAlias():
          kind = _MemberKind.unitGenericTypeAlias;
          name = member.name.lexeme;
        case MixinDeclaration():
          kind = _MemberKind.unitClass;
          name = member.name.lexeme;
        case TopLevelVariableDeclaration():
          var variableDeclaration = member;
          List<VariableDeclaration> variables =
              variableDeclaration.variables.variables;
          if (variables.isNotEmpty) {
            if (variableDeclaration.variables.isConst) {
              kind = _MemberKind.unitVariableConst;
            } else {
              kind = _MemberKind.unitVariable;
            }
            name = variables[0].name.lexeme;
          } else {
            // Don't sort members if there are errors in the code.
            return;
          }
        default:
          throw StateError('Unsupported member type: ${member.runtimeType}');
      }
      var item = _PriorityItem.forName(false, name, kind);
      var nodeRange = range.nodeWithComments(_lineInfo, member);
      var offset = nodeRange.offset;
      var length = nodeRange.length;
      var text = code.substring(offset, offset + length);
      members.add(_MemberInfo(item, name, offset, length, text));
    }
    // do sort
    _sortAndReorderMembers(members);
  }

  static List<_PriorityItem> _getPriorityItems(CodeStyleOptions codeStyle) {
    return [
      _PriorityItem(false, _MemberKind.unitFunctionMain, false),
      _PriorityItem(false, _MemberKind.unitVariableConst, false),
      _PriorityItem(false, _MemberKind.unitVariableConst, true),
      _PriorityItem(false, _MemberKind.unitVariable, false),
      _PriorityItem(false, _MemberKind.unitVariable, true),
      _PriorityItem(false, _MemberKind.unitAccessor, false),
      _PriorityItem(false, _MemberKind.unitAccessor, true),
      _PriorityItem(false, _MemberKind.unitFunction, false),
      _PriorityItem(false, _MemberKind.unitFunction, true),
      _PriorityItem(false, _MemberKind.unitGenericTypeAlias, false),
      _PriorityItem(false, _MemberKind.unitGenericTypeAlias, true),
      _PriorityItem(false, _MemberKind.unitFunctionType, false),
      _PriorityItem(false, _MemberKind.unitFunctionType, true),
      _PriorityItem(false, _MemberKind.unitClass, false),
      _PriorityItem(false, _MemberKind.unitClass, true),
      _PriorityItem(false, _MemberKind.unitExtensionType, false),
      _PriorityItem(false, _MemberKind.unitExtensionType, true),
      _PriorityItem(false, _MemberKind.unitExtension, false),
      _PriorityItem(false, _MemberKind.unitExtension, true),
      if (codeStyle.sortConstructorsFirst)
        _PriorityItem(false, _MemberKind.classConstructor, false),
      if (codeStyle.sortConstructorsFirst)
        _PriorityItem(false, _MemberKind.classConstructor, true),
      _PriorityItem(true, _MemberKind.classField, false),
      _PriorityItem(true, _MemberKind.classAccessor, false),
      _PriorityItem(true, _MemberKind.classAccessor, true),
      _PriorityItem(false, _MemberKind.classField, false),
      if (!codeStyle.sortConstructorsFirst)
        _PriorityItem(false, _MemberKind.classConstructor, false),
      if (!codeStyle.sortConstructorsFirst)
        _PriorityItem(false, _MemberKind.classConstructor, true),
      _PriorityItem(false, _MemberKind.classAccessor, false),
      _PriorityItem(false, _MemberKind.classAccessor, true),
      _PriorityItem(false, _MemberKind.classMethod, false),
      _PriorityItem(false, _MemberKind.classMethod, true),
      _PriorityItem(true, _MemberKind.classMethod, false),
      _PriorityItem(true, _MemberKind.classMethod, true),
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
  classAccessor,
  classConstructor,
  classField,
  classMethod,
  unitAccessor,
  unitClass,
  unitExtension,
  unitExtensionType,
  unitFunction,
  unitFunctionMain,
  unitFunctionType,
  unitGenericTypeAlias,
  unitVariable,
  unitVariableConst,
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
    if (kind == _MemberKind.classField) {
      return other.kind == kind && other.isStatic == isStatic;
    }
    return other.kind == kind &&
        other.isPrivate == isPrivate &&
        other.isStatic == isStatic;
  }

  @override
  String toString() => kind.toString();
}
