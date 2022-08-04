// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_custom_generated.dart';
import 'package:analysis_server/src/services/refactoring/framework/refactoring_producer.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';

/// An object that can compute a refactoring in a Dart file.
class MoveTopLevelToFile extends RefactoringProducer {
  @override
  late String title;

  /// The default path of the file to which the declaration should be moved.
  late String defaultFilePath;

  /// Initialize a newly created refactoring producer to use the given
  /// [context].
  MoveTopLevelToFile(super.context);

  @override
  String get commandName => 'move_top_level_to_file';

  @override
  List<CommandParameter> get parameters => [
        CommandParameter(
          label: 'Move to:',
          type: CommandParameterType.filePath,
          defaultValue: defaultFilePath,
        ),
      ];

  @override
  Future<void> compute(List<String> commandArguments, ChangeBuilder builder) {
    // TODO: implement compute
    throw UnimplementedError();
  }

  @override
  bool isAvailable() {
    // TODO: implement isAvailable
    // TODO: initialize `title` to "Move '$name' to file"
    // TODO: initialize `defaultFilePath` to a path based on the name of the
    //  declaration.
    return false;
  }
}
