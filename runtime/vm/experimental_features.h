// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// NOTE: THIS FILE IS GENERATED. DO NOT EDIT.
//
// Instead modify 'tools/experimental_features.yaml' and run
// 'dart tools/generate_experimental_flags.dart' to update.

#ifndef RUNTIME_VM_EXPERIMENTAL_FEATURES_H_
#define RUNTIME_VM_EXPERIMENTAL_FEATURES_H_

namespace dart {

enum class ExperimentalFeature {
  inference_update_2,
  sealed_class,
  class_modifiers,
  records,
  patterns,
  unnamed_libraries,
  inference_update_1,
  enhanced_enums,
  named_arguments_anywhere,
  super_parameters,
  constructor_tearoffs,
  generic_metadata,
  triple_shift,
  nonfunction_type_aliases,
  non_nullable,
  extension_methods,
  constant_update_2018,
  control_flow_collections,
  set_literals,
  spread_collections,
};

bool GetExperimentalFeatureDefault(ExperimentalFeature feature);
const char* GetExperimentalFeatureName(ExperimentalFeature feature);

}  // namespace dart

#endif  // RUNTIME_VM_EXPERIMENTAL_FEATURES_H_
