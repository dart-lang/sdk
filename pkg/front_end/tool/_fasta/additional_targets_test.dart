// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.tool.additional_targets_test;

import 'package:kernel/target/targets.dart' show targets;

import 'package:front_end/src/base/command_line_options.dart';

import 'package:front_end/src/fasta/fasta_codes.dart'
    show MessageCode, messageFastaUsageLong;

import 'additional_targets.dart' show installAdditionalTargets;

main() {
  installAdditionalTargets();
  String expected =
      "  ${Flags.target}=${(targets.keys.toList()..sort()).join('|')}";
  MessageCode code = messageFastaUsageLong;
  if (!code.message.contains(expected)) {
    throw "Error: ${code.name} in pkg/front_end/messages.yaml doesn't contain"
        " '$expected'.";
  }
}
