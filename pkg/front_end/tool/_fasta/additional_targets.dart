// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.tool.additional_targets;

import 'package:kernel/target/targets.dart' show TargetFlags, targets;

import 'package:compiler/src/kernel/dart2js_target.dart' show Dart2jsTarget;

import 'package:vm/target/dart_runner.dart' show DartRunnerTarget;

import 'package:vm/target/flutter_runner.dart' show FlutterRunnerTarget;

void installAdditionalTargets() {
  // If you add new targets here, please also update FastaUsageLong in
  // ../../messages.yaml.
  targets["dart2js"] =
      (TargetFlags flags) => new Dart2jsTarget("dart2js", flags);
  targets["dart2js_server"] =
      (TargetFlags flags) => new Dart2jsTarget("dart2js_server", flags);
  targets["dart_runner"] = (TargetFlags flags) => new DartRunnerTarget(flags);
  targets["flutter_runner"] =
      (TargetFlags flags) => new FlutterRunnerTarget(flags);
}
