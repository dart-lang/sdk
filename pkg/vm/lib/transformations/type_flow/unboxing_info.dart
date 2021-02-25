// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/external_name.dart' show getExternalName;
import 'package:vm/metadata/procedure_attributes.dart';
import 'package:vm/transformations/pragma.dart';
import 'package:vm/transformations/type_flow/analysis.dart';
import 'package:vm/transformations/type_flow/calls.dart';
import 'package:vm/transformations/type_flow/native_code.dart';
import 'package:vm/transformations/type_flow/table_selector_assigner.dart';
import 'package:vm/transformations/type_flow/types.dart';

import '../../metadata/unboxing_info.dart';
import 'utils.dart';

class UnboxingInfoManager {
  final Map<Member, UnboxingInfoMetadata> _memberInfo = {};

  final TypeHierarchy _typeHierarchy;
  final CoreTypes _coreTypes;
  final NativeCodeOracle _nativeCodeOracle;

  UnboxingInfoManager(TypeFlowAnalysis typeFlowAnalysis)
      : _typeHierarchy = typeFlowAnalysis.hierarchyCache,
        _coreTypes = typeFlowAnalysis.environment.coreTypes,
        _nativeCodeOracle = typeFlowAnalysis.nativeCodeOracle;

  UnboxingInfoMetadata getUnboxingInfoOfMember(Member member) {
    final UnboxingInfoMetadata info = _memberInfo[member];
    if (member is Procedure && member.isGetter) {
      // Remove placeholder parameter info slot for setters that the getter is
      // grouped with.
      return UnboxingInfoMetadata(0)..returnInfo = info.returnInfo;
    }
    return info;
  }

  void analyzeComponent(Component component, TypeFlowAnalysis typeFlowAnalysis,
      TableSelectorAssigner tableSelectorAssigner) {
    const kInvalidSelectorId = ProcedureAttributesMetadata.kInvalidSelectorId;

    // Unboxing info for instance members is grouped by selector ID, such that
    // the unboxing decisions match up for all members that can be called from
    // the same call site.

    // Unify the selector IDs for the getter and setter of every (writable)
    // field, such that it can be grouped with both getters and setters.
    // In the unified unboxing info, the return info represents the getters, and
    // the parameter info represents the setters.
    final selectorUnionFind = UnionFind(tableSelectorAssigner.selectorIdRange);
    for (Library library in component.libraries) {
      for (Class cls in library.classes) {
        for (Field field in cls.fields) {
          if (field.isInstanceMember && field.hasSetter) {
            final getterId = tableSelectorAssigner.getterSelectorId(field);
            final setterId =
                tableSelectorAssigner.methodOrSetterSelectorId(field);
            assert(getterId != kInvalidSelectorId);
            assert(setterId != kInvalidSelectorId);
            selectorUnionFind.union(getterId, setterId);
          }
        }
      }
    }

    // Map members to unboxing info.
    final Map<int, UnboxingInfoMetadata> selectorIdToInfo = {};

    void addMember(Member member) {
      if (!(member is Procedure || member is Constructor || member is Field)) {
        return;
      }
      // Give getters one parameter info slot to hold the unboxing info for the
      // setters that the getter is grouped with.
      final int paramCount = member is Field
          ? (member.hasSetter ? 1 : 0)
          : member is Procedure && member.isGetter
              ? 1
              : member.function.requiredParameterCount;
      UnboxingInfoMetadata info;
      if (member.isInstanceMember) {
        int selectorId =
            member is Field || member is Procedure && member.isGetter
                ? tableSelectorAssigner.getterSelectorId(member)
                : tableSelectorAssigner.methodOrSetterSelectorId(member);
        assert(selectorId != kInvalidSelectorId);
        selectorId = selectorUnionFind.find(selectorId);
        info = selectorIdToInfo[selectorId];
        if (info == null) {
          info = UnboxingInfoMetadata(paramCount);
          selectorIdToInfo[selectorId] = info;
        } else {
          if (paramCount < info.unboxedArgsInfo.length) {
            info.unboxedArgsInfo.length = paramCount;
          }
        }
      } else {
        info = UnboxingInfoMetadata(paramCount);
      }
      _memberInfo[member] = info;
      _updateUnboxingInfoOfMember(member, typeFlowAnalysis);
    }

    for (Library library in component.libraries) {
      for (Class cls in library.classes) {
        for (Member member in cls.members) {
          addMember(member);
        }
      }
      for (Member member in library.members) {
        addMember(member);
      }
    }
  }

  void _updateUnboxingInfoOfMember(
      Member member, TypeFlowAnalysis typeFlowAnalysis) {
    if (typeFlowAnalysis.isMemberUsed(member)) {
      final UnboxingInfoMetadata unboxingInfo = _memberInfo[member];
      if (_cannotUnbox(member)) {
        unboxingInfo.unboxedArgsInfo.length = 0;
        unboxingInfo.returnInfo = UnboxingInfoMetadata.kBoxed;
        return;
      }
      if (member is Procedure || member is Constructor) {
        final Args<Type> argTypes = typeFlowAnalysis.argumentTypes(member);
        assert(argTypes != null);

        final int firstParamIndex =
            numTypeParams(member) + (hasReceiverArg(member) ? 1 : 0);

        final positionalParams = member.function.positionalParameters;
        assert(argTypes.positionalCount ==
            firstParamIndex + positionalParams.length);

        for (int i = 0; i < positionalParams.length; i++) {
          final inferredType = argTypes.values[firstParamIndex + i];
          _applyToArg(unboxingInfo, i, inferredType);
        }

        final names = argTypes.names;
        for (int i = 0; i < names.length; i++) {
          final inferredType =
              argTypes.values[firstParamIndex + positionalParams.length + i];
          _applyToArg(unboxingInfo, positionalParams.length + i, inferredType);
        }

        final Type resultType = typeFlowAnalysis.getSummary(member).resultType;
        _applyToReturn(unboxingInfo, resultType);
      } else if (member is Field) {
        final fieldValue = typeFlowAnalysis.getFieldValue(member).value;
        if (member.hasSetter) {
          _applyToArg(unboxingInfo, 0, fieldValue);
        }
        _applyToReturn(unboxingInfo, fieldValue);
      } else {
        assert(false, "Unexpected member: $member");
      }
    }
  }

  void _applyToArg(UnboxingInfoMetadata unboxingInfo, int argPos, Type type) {
    if (argPos < 0 || unboxingInfo.unboxedArgsInfo.length <= argPos) {
      return;
    }

    if (type is NullableType ||
        (!type.isSubtypeOf(_typeHierarchy, _coreTypes.intClass) &&
            !type.isSubtypeOf(_typeHierarchy, _coreTypes.doubleClass))) {
      unboxingInfo.unboxedArgsInfo[argPos] = UnboxingInfoMetadata.kBoxed;
    } else {
      final unboxingType = type.isSubtypeOf(_typeHierarchy, _coreTypes.intClass)
          ? UnboxingInfoMetadata.kUnboxedIntCandidate
          : UnboxingInfoMetadata.kUnboxedDoubleCandidate;
      unboxingInfo.unboxedArgsInfo[argPos] &= unboxingType;
    }
  }

  void _applyToReturn(UnboxingInfoMetadata unboxingInfo, Type type) {
    if (type is NullableType ||
        (!type.isSubtypeOf(_typeHierarchy, _coreTypes.intClass) &&
            !type.isSubtypeOf(_typeHierarchy, _coreTypes.doubleClass))) {
      unboxingInfo.returnInfo = UnboxingInfoMetadata.kBoxed;
    } else {
      final unboxingType = type.isSubtypeOf(_typeHierarchy, _coreTypes.intClass)
          ? UnboxingInfoMetadata.kUnboxedIntCandidate
          : UnboxingInfoMetadata.kUnboxedDoubleCandidate;
      unboxingInfo.returnInfo &= unboxingType;
    }
  }

  bool _cannotUnbox(Member member) {
    // Methods that do not need dynamic invocation forwarders can not have
    // unboxed parameters and return because dynamic calls always use boxed
    // values.
    // Similarly C->Dart calls (entrypoints) and Dart->C calls (natives) need to
    // have boxed parameters and return values.
    return _isNative(member) ||
        _nativeCodeOracle.isMemberReferencedFromNativeCode(member) ||
        _nativeCodeOracle.isRecognized(member, const [
          PragmaRecognizedType.AsmIntrinsic,
          PragmaRecognizedType.Other
        ]);
  }

  bool _isNative(Member member) => getExternalName(member) != null;
}
