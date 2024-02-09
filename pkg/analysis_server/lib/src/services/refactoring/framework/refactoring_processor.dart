// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/services/refactoring/convert_all_formal_parameters_to_named.dart';
import 'package:analysis_server/src/services/refactoring/convert_selected_formal_parameters_to_named.dart';
import 'package:analysis_server/src/services/refactoring/framework/refactoring_context.dart';
import 'package:analysis_server/src/services/refactoring/framework/refactoring_producer.dart';
import 'package:analysis_server/src/services/refactoring/move_selected_formal_parameters_left.dart';
import 'package:analysis_server/src/services/refactoring/move_top_level_to_file.dart';
import 'package:language_server_protocol/protocol_generated.dart';

/// A function that can be executed to create a refactoring producer.
typedef ProducerGenerator = RefactoringProducer Function(RefactoringContext);

class RefactoringProcessor {
  /// A list of the generators used to produce refactorings.
  static const Map<String, ProducerGenerator> generators = {
    ConvertAllFormalParametersToNamed.commandName:
        ConvertAllFormalParametersToNamed.new,
    ConvertSelectedFormalParametersToNamed.commandName:
        ConvertSelectedFormalParametersToNamed.new,
    MoveSelectedFormalParametersLeft.commandName:
        MoveSelectedFormalParametersLeft.new,
    MoveTopLevelToFile.commandName: MoveTopLevelToFile.new,
  };

  /// The context in which the refactorings could be applied.
  final RefactoringContext context;

  RefactoringProcessor(this.context);

  /// Return a list containing one code action for each of the refactorings that
  /// are available in the current context.
  Future<List<CodeAction>> compute() async {
    var refactorings = <CodeAction>[];
    for (var entry in RefactoringProcessor.generators.entries) {
      var generator = entry.value;
      var producer = generator(context);

      if (producer.isExperimental && !context.includeExperimental) {
        continue;
      }

      final isAvailable = producer.isAvailable();
      if (!isAvailable) {
        continue;
      }

      var parameters = producer.parameters;
      // In debug mode, throw if we produced a refactoring that has parameters
      // without default values that are not supported by the client.
      assert(
        () {
          return parameters.every((parameter) =>
              parameter.defaultValue != null ||
              producer.supportsCommandParameter(parameter.kind));
        }(),
        '${producer.title} refactor returned parameters without defaults '
        'that are not supported by the client',
      );

      final command = entry.key;
      assert(
        (() => Commands.serverSupportedCommands.contains(command))(),
        'serverSupportedCommands did not contain $command',
      );

      refactorings.add(
        CodeAction(
            title: producer.title,
            kind: producer.kind,
            command: Command(
              command: command,
              title: producer.title,
              arguments: [
                {
                  'filePath': context.resolvedUnitResult.path,
                  'selectionOffset': context.selectionOffset,
                  'selectionLength': context.selectionLength,
                  'arguments':
                      parameters.map((param) => param.defaultValue).toList(),
                }
              ],
            ),
            data: {
              'parameters': parameters,
            }),
      );
    }
    return refactorings;
  }
}
