// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:gardening/src/results_workflow/ask_for_logs.dart';
import 'package:gardening/src/workflow.dart';

/// Class [StatusCommand] handles the 'status' sub-command to edit status files
/// for result logs.
class StatusCommand extends Command {
  @override
  String get description => "Update status files, from failure data and "
      "existing status entries.";

  @override
  String get name => "status";

  Future run() async {
    var workflow = new Workflow();
    var askForLogs = new AskForLogs();
    for (var input in argResults.rest) {
      await askForLogs.processInput(input);
    }
    return workflow.start(askForLogs);
  }
}
