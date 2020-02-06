// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';

import '../../metadata/procedure_attributes.dart';

// Assigns dispatch table selector IDs to interface targets.
// TODO(dartbug.com/40188): Implement a more fine-grained assignment based on
// hierarchy connectedness.
class TableSelectorAssigner {
  final Map<Name, int> _methodSelectorId = {};
  final Map<Name, int> _getterSelectorId = {};
  final Map<Name, int> _setterSelectorId = {};
  int _nextSelectorId = ProcedureAttributesMetadata.kInvalidSelectorId + 1;

  int _selectorIdForMap(Map<Name, int> map, Member member) {
    return map.putIfAbsent(member.name, () => _nextSelectorId++);
  }

  int methodOrSetterSelectorId(Member member) {
    if (member is Procedure) {
      switch (member.kind) {
        case ProcedureKind.Method:
        case ProcedureKind.Operator:
          return _selectorIdForMap(_methodSelectorId, member);
        case ProcedureKind.Setter:
          return _selectorIdForMap(_setterSelectorId, member);
        case ProcedureKind.Getter:
          return ProcedureAttributesMetadata.kInvalidSelectorId;
        default:
          throw "Unexpected procedure kind '${member.kind}'";
      }
    }
    if (member is Field) {
      return _selectorIdForMap(_setterSelectorId, member);
    }
    throw "Unexpected member kind '${member.runtimeType}'";
  }

  int getterSelectorId(Member member) {
    if (member is Procedure) {
      switch (member.kind) {
        case ProcedureKind.Getter:
        case ProcedureKind.Method:
          return _selectorIdForMap(_getterSelectorId, member);
        case ProcedureKind.Operator:
        case ProcedureKind.Setter:
          return ProcedureAttributesMetadata.kInvalidSelectorId;
        default:
          throw "Unexpected procedure kind '${member.kind}'";
      }
    }
    if (member is Field) {
      return _selectorIdForMap(_getterSelectorId, member);
    }
    throw "Unexpected member kind '${member.runtimeType}'";
  }
}
