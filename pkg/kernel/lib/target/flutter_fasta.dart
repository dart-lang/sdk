// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.target.flutter_fasta;

import '../ast.dart' show Program, Library;
import '../core_types.dart' show CoreTypes;
import '../class_hierarchy.dart' show ClassHierarchy;

import '../transformations/mixin_full_resolution.dart' as transformMixins
    show transformLibraries;
import '../transformations/continuation.dart' as transformAsync
    show transformLibraries;
import '../transformations/erasure.dart' as tranformErasure
    show transformLibraries;

import 'targets.dart' show TargetFlags;
import 'flutter.dart' as flutter_target;

class FlutterFastaTarget extends flutter_target.FlutterTarget {
  FlutterFastaTarget(TargetFlags flags) : super(flags);

  String get name => "flutter_fasta";

  void performModularTransformationsOnLibraries(
      CoreTypes coreTypes, ClassHierarchy hierarchy, List<Library> libraries,
      {void logger(String msg)}) {
    transformMixins.transformLibraries(this, coreTypes, hierarchy, libraries);
    logger?.call("Transformed mixin applications");

    // TODO(ahe): Don't generate type variables in the first place.
    if (!strongMode) {
      tranformErasure.transformLibraries(coreTypes, libraries);
      logger?.call("Erased type variables in generic methods");
    }

    // TODO(kmillikin): Make this run on a per-method basis.
    transformAsync.transformLibraries(coreTypes, libraries);
    logger?.call("Transformed async methods");
  }

  void performGlobalTransformations(CoreTypes coreTypes, Program program,
      {void logger(String msg)}) {}
}
