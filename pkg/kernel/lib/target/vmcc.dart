// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.target.vmcc;

import '../ast.dart' show Component, Library;
import '../core_types.dart' show CoreTypes;
import '../class_hierarchy.dart';
import '../transformations/continuation.dart' as cont;
import '../transformations/mixin_full_resolution.dart' as mix;
import '../transformations/sanitize_for_vm.dart';
import '../transformations/treeshaker.dart';
import '../transformations/closure_conversion.dart' as cc
    show transformComponent;
import 'targets.dart' show TargetFlags;
import 'vm.dart' as vm_target;

// VmClosureConvertedTarget used legacy VmTarget which was superseded by
// VmFastaTarget. Legacy transformations pipeline was pulled from VmTarget
// into this class when VmTarget was merged with new VmFastaTarget.
// TODO(alexmarkov): Figure out if this target is still used, and either remove
// it or unify its transformation pipeline with new VmTarget.
class VmClosureConvertedTarget extends vm_target.VmTarget {
  VmClosureConvertedTarget(TargetFlags flags) : super(flags);

  @override
  String get name => "vmcc";

  ClassHierarchy _hierarchy;

  @override
  void performModularTransformationsOnLibraries(
      CoreTypes coreTypes, ClassHierarchy hierarchy, List<Library> libraries,
      {void logger(String msg)}) {
    var mixins = new mix.MixinFullResolution(this, coreTypes, hierarchy)
      ..transform(libraries);

    _hierarchy = mixins.hierarchy;
  }

  @override
  void performGlobalTransformations(CoreTypes coreTypes, Component component,
      {void logger(String msg)}) {
    if (flags.treeShake) {
      performTreeShaking(coreTypes, component);
    }

    cont.transformComponent(coreTypes, component, flags.syncAsync);

    new SanitizeForVM().transform(component);

    cc.transformComponent(coreTypes, component);
  }

  void performTreeShaking(CoreTypes coreTypes, Component component) {
    new TreeShaker(coreTypes, _hierarchy, component,
            strongMode: strongMode, programRoots: flags.programRoots)
        .transform(component);
    _hierarchy = null; // Hierarchy must be recomputed.
  }
}
