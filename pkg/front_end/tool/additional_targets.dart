// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:compiler/src/kernel/dart2js_target.dart' show Dart2jsTarget;
import 'package:dart2wasm/target.dart' as wasm show Mode;
import 'package:dart2wasm/target.dart' show WasmTarget;
import 'package:dev_compiler/src/kernel/target.dart' show DevCompilerTarget;
import 'package:kernel/target/targets.dart' show TargetFlags, targets;
import 'package:vm/modular/target/install.dart' as vm_target_install
    show installAdditionalTargets;

void installAdditionalTargets() {
  // If you add new targets here, please also update FastaUsageLong in
  // ../../messages.yaml.
  targets["dart2js"] =
      (TargetFlags flags) => new Dart2jsTarget("dart2js", flags);
  targets["dart2js_server"] =
      (TargetFlags flags) => new Dart2jsTarget("dart2js_server", flags);
  targets["dartdevc"] = (TargetFlags flags) => new DevCompilerTarget(flags);
  targets["dart2wasm"] = (TargetFlags flags) => new WasmTarget();
  targets["dart2wasm_js_compatibility"] =
      (TargetFlags flags) => new WasmTarget(mode: wasm.Mode.jsCompatibility);
  vm_target_install.installAdditionalTargets();
}
