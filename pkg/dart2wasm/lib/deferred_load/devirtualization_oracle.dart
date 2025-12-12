// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/kernel.dart';
import 'package:vm/metadata/direct_call.dart';
import 'package:vm/metadata/procedure_attributes.dart';
import 'package:vm/metadata/table_selector.dart';

/// Oracle that knows whether instance members will be always called directly
/// (i.e. all call sites are devirtualized direct calls instead of instance
/// calls).
class DevirtualizionOracle {
  final Component component;

  late final Map<TreeNode, DirectCallMetadata> _directCallMetadata =
      (component.metadata[DirectCallMetadataRepository.repositoryTag]
              as DirectCallMetadataRepository)
          .mapping;

  late final Map<TreeNode, ProcedureAttributesMetadata>
      _procedureAttributeMetadata =
      (component.metadata[ProcedureAttributesMetadataRepository.repositoryTag]
              as ProcedureAttributesMetadataRepository)
          .mapping;
  late final List<TableSelectorInfo> _selectorMetadata =
      (component.metadata[TableSelectorMetadataRepository.repositoryTag]
              as TableSelectorMetadataRepository)
          .mapping[component]!
          .selectors;

  DevirtualizionOracle(this.component);

  /// Whether all call sites are guaranteed to be devirtualized.
  bool isAlwaysStaticallyDispatchedTo(Reference reference) {
    final member = reference.asMember;
    assert(member.isInstanceMember);
    final metadata = _procedureAttributeMetadata[member]!;

    final bool isGetter =
        member is Field && reference == member.getterReference ||
            member is Procedure && member.isGetter;

    if (isGetter) {
      if (metadata.getterCalledDynamically) return false;

      final getterId = metadata.getterSelectorId;
      if (getterId != ProcedureAttributesMetadata.kInvalidSelectorId) {
        final selector = _selectorMetadata[getterId];
        if (selector.callCount != 0 || selector.tornOff) {
          return false;
        }
      }
    } else {
      if (metadata.methodOrSetterCalledDynamically) return false;
      // This method may be dynamically torn off.
      if (metadata.getterCalledDynamically) return false;

      final methodOrSetterId = metadata.methodOrSetterSelectorId;
      if (methodOrSetterId != ProcedureAttributesMetadata.kInvalidSelectorId) {
        final selector = _selectorMetadata[methodOrSetterId];
        if (selector.callCount != 0 || selector.tornOff) {
          return false;
        }
      }
    }

    // All uses of this [member] will be devirtualized uses. The deferred
    // loading partitioning algorithm will - on all call sites (which are
    // guaranteed to be devirtualized) - make this target a direct dependency
    // (via calling `staticDispatchTargetFor*` methods below) instead of
    // conservatively enquing this method whenever the class is allocated.
    return true;
  }

  Reference? staticDispatchTargetForGet(InstanceGet node) {
    final devirtualizedTarget = _directCallMetadata[node]?.targetMember;
    if (devirtualizedTarget == null) return null;
    if (devirtualizedTarget is Field) {
      return devirtualizedTarget.getterReference;
    }
    return (devirtualizedTarget as Procedure).reference;
  }

  Reference? staticDispatchTargetForSet(InstanceSet node) {
    final devirtualizedTarget = _directCallMetadata[node]?.targetMember;
    if (devirtualizedTarget == null) return null;
    if (devirtualizedTarget is Field) {
      return devirtualizedTarget.setterReference;
    }
    return (devirtualizedTarget as Procedure).reference;
  }

  Reference? staticDispatchTargetForCall(InstanceInvocation node) {
    final devirtualizedTarget = _directCallMetadata[node]?.targetMember;
    if (devirtualizedTarget == null) return null;
    return (devirtualizedTarget as Procedure).reference;
  }
}
