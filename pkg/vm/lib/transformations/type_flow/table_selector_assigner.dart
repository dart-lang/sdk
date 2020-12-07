// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';

import 'utils.dart' show UnionFind;
import '../../metadata/procedure_attributes.dart';
import '../../metadata/table_selector.dart';

// Assigns dispatch table selector IDs to interface targets.
class TableSelectorAssigner {
  final TableSelectorMetadata metadata = TableSelectorMetadata();

  final Map<Class, Map<Name, int>> _getterMemberIds = {};
  final Map<Class, Map<Name, int>> _methodOrSetterMemberIds = {};

  final UnionFind _unionFind = UnionFind();
  List<int> _selectorIdForMemberId;

  TableSelectorAssigner(Component component) {
    for (Library library in component.libraries) {
      for (Class cls in library.classes) {
        _memberIdsForClass(cls, getter: false);
        _memberIdsForClass(cls, getter: true);
      }
    }
    _selectorIdForMemberId = List.filled(_unionFind.size, null);
    // Assign all selector IDs eagerly to make them independent of how they are
    // queried in later phases. This makes TFA test expectation files (which
    // contain selector IDs) more stable under changes to how selector IDs are
    // used in TFA phases.
    for (Library library in component.libraries) {
      for (Class cls in library.classes) {
        for (Member member in cls.members) {
          if (member.isInstanceMember) {
            _selectorIdForMember(member, getter: false);
            _selectorIdForMember(member, getter: true);
          }
        }
      }
    }
  }

  Map<Name, int> _memberIdsForClass(Class cls, {bool getter}) {
    if (cls == null) return {};

    final cache = getter ? _getterMemberIds : _methodOrSetterMemberIds;

    // Already computed for this class?
    Map<Name, int> memberIds = cache[cls];
    if (memberIds != null) return memberIds;

    // Merge maps from supertypes.
    memberIds = Map.from(_memberIdsForClass(cls.superclass, getter: getter));
    for (Supertype impl in cls.implementedTypes) {
      _memberIdsForClass(impl.classNode, getter: getter).forEach((name, id) {
        final int firstId = memberIds[name];
        if (firstId == null) {
          memberIds[name] = id;
        } else if (firstId != id) {
          _unionFind.union(firstId, id);
        }
      });
    }

    // Add declared instance members.
    for (Member member in cls.members) {
      if (member.isInstanceMember) {
        bool addToMap;
        if (member is Procedure) {
          switch (member.kind) {
            case ProcedureKind.Method:
              addToMap = true;
              break;
            case ProcedureKind.Operator:
            case ProcedureKind.Setter:
              addToMap = !getter;
              break;
            case ProcedureKind.Getter:
              addToMap = getter;
              break;
            default:
              throw "Unexpected procedure kind '${member.kind}'";
          }
        } else if (member is Field) {
          addToMap = getter || member.hasSetter;
        } else {
          throw "Unexpected member kind '${member.runtimeType}'";
        }
        if (addToMap && !memberIds.containsKey(member.name)) {
          memberIds[member.name] = _unionFind.add();
        }
      }
    }

    return cache[cls] = memberIds;
  }

  int _selectorIdForMember(Member member, {bool getter}) {
    final map = getter ? _getterMemberIds : _methodOrSetterMemberIds;
    int memberId = map[member.enclosingClass][member.name];
    if (memberId == null) {
      assert(member is Procedure &&
              ((identical(map, _getterMemberIds) &&
                      (member.kind == ProcedureKind.Operator ||
                          member.kind == ProcedureKind.Setter)) ||
                  identical(map, _methodOrSetterMemberIds) &&
                      member.kind == ProcedureKind.Getter) ||
          member is Field &&
              identical(map, _methodOrSetterMemberIds) &&
              !member.hasSetter);
      return ProcedureAttributesMetadata.kInvalidSelectorId;
    }
    memberId = _unionFind.find(memberId);
    int selectorId = _selectorIdForMemberId[memberId];
    if (selectorId == null) {
      _selectorIdForMemberId[memberId] = selectorId = metadata.addSelector();
    }
    return selectorId;
  }

  int methodOrSetterSelectorId(Member member) {
    return _selectorIdForMember(member, getter: false);
  }

  int getterSelectorId(Member member) {
    return _selectorIdForMember(member, getter: true);
  }

  void registerMethodOrSetterCall(Member member, bool calledOnNull) {
    final TableSelectorInfo selector =
        metadata.selectors[methodOrSetterSelectorId(member)];
    selector.callCount++;
    selector.calledOnNull |= calledOnNull;
  }

  void registerGetterCall(Member member, bool calledOnNull) {
    final TableSelectorInfo selector =
        metadata.selectors[getterSelectorId(member)];
    selector.callCount++;
    selector.calledOnNull |= calledOnNull;
    if (member is Procedure && member.kind == ProcedureKind.Method) {
      final TableSelectorInfo methodSelector =
          metadata.selectors[methodOrSetterSelectorId(member)];
      methodSelector.tornOff = true;
    }
  }

  /// A (conservative) number which is bigger than all selector IDs.
  int get selectorIdRange => metadata.selectors.length;
}
