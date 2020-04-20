// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.target.install;

import 'package:kernel/target/targets.dart' show targets, TargetFlags;
import 'package:vm/target/dart_runner.dart' show DartRunnerTarget;
import 'package:vm/target/flutter.dart' show FlutterTarget;
import 'package:vm/target/flutter_runner.dart' show FlutterRunnerTarget;
import 'package:vm/target/vm.dart' show VmTarget;

bool _installed = false;

void installAdditionalTargets() {
  if (!_installed) {
    targets["dart_runner"] = (TargetFlags flags) => DartRunnerTarget(flags);
    targets["flutter"] = (TargetFlags flags) => FlutterTarget(flags);
    targets["flutter_runner"] =
        (TargetFlags flags) => FlutterRunnerTarget(flags);
    targets["vm"] = (TargetFlags flags) => VmTarget(flags);
    _installed = true;
  }
}
