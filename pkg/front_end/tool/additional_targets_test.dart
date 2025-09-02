// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/base/command_line_options.dart';
import 'package:front_end/src/codes/cfe_codes.dart'
    show MessageCode, codeFastaUsageLong;
import 'package:kernel/target/targets.dart' show targets;

import 'additional_targets.dart' show installAdditionalTargets;

void main() {
  installAdditionalTargets();
  String expected =
      "  ${Flags.target}=${(targets.keys.toList()..sort()).join('|')}";
  MessageCode code = codeFastaUsageLong;
  if (!code.problemMessage.contains(expected)) {
    throw "Error: ${code.name} in pkg/front_end/messages.yaml doesn't contain"
        " '$expected'.";
  }
}
