// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/services/correction/refactoring_performance.dart';
import 'package:analysis_server/src/services/refactoring/add_constructor_name.dart';
import 'package:analysis_server/src/services/refactoring/add_import_prefix.dart';
import 'package:analysis_server/src/services/refactoring/convert_all_formal_parameters_to_named.dart';
import 'package:analysis_server/src/services/refactoring/convert_selected_formal_parameters_to_named.dart';
import 'package:analysis_server/src/services/refactoring/framework/refactoring_context.dart';
import 'package:analysis_server/src/services/refactoring/framework/refactoring_producer.dart';
import 'package:analysis_server/src/services/refactoring/move_selected_formal_parameters_left.dart';
import 'package:analysis_server/src/services/refactoring/move_top_level_to_file.dart';
import 'package:analysis_server/src/services/refactoring/remove_constructor_name.dart';
import 'package:analysis_server/src/services/refactoring/remove_import_prefix.dart';
import 'package:language_server_protocol/protocol_custom_generated.dart';
import 'package:language_server_protocol/protocol_generated.dart';

/// A function that can be executed to create a refactoring producer.
typedef RefactoringProducerGenerator = RefactoringProducer Function(
  RefactoringContext,
);

class RefactoringProcessor {
  /// A list of the generators used to produce refactorings.
  static const Map<String, RefactoringProducerGenerator> generators = {
    AddConstructorName.commandName: AddConstructorName.new,
    AddImportPrefix.commandName: AddImportPrefix.new,
    ConvertAllFormalParametersToNamed.commandName:
        ConvertAllFormalParametersToNamed.new,
    ConvertSelectedFormalParametersToNamed.commandName:
        ConvertSelectedFormalParametersToNamed.new,
    MoveSelectedFormalParametersLeft.commandName:
        MoveSelectedFormalParametersLeft.new,
    MoveTopLevelToFile.commandName: MoveTopLevelToFile.new,
    RemoveConstructorName.commandName: RemoveConstructorName.new,
    RemoveImportPrefix.commandName: RemoveImportPrefix.new,
  };

  /// The context in which the refactorings could be applied.
  final RefactoringContext context;

  final RefactoringPerformance? _performance;

  final Stopwatch _timer = Stopwatch();

  new(this.context, {this._performance});

  /// Return a list containing one code action for each of the refactorings that
  /// are available in the current context.
  Future<List<CodeActionLiteral>> compute() async {
    _timer.start();
    var refactorings = <CodeActionLiteral>[];
    for (var entry in RefactoringProcessor.generators.entries) {
      var generator = entry.value;
      var producer = generator(context);

      if (producer.isExperimental && !context.includeExperimental) {
        continue;
      }
      var startTime = _timer.elapsedMilliseconds;

      Future<void> action() async {
        var isAvailable = producer.isAvailable();
        if (!isAvailable) {
          // Track time checking for availablity before continuing.
          _performance?.producerTimings.add((
            className: producer.runtimeType.toString(),
            elapsedTime: _timer.elapsedMilliseconds - startTime,
          ));
          return;
        }

        var interactiveFormsEnabled =
            // Client has shown it has support by providing at least one
            // input kind that it supports.
            // It is up to the individual refactors to handle the specific
            // kinds of input that are supported, this check is just to know if
            // we will use Interactive Forms instead of the original
            // Dart-specified self-described refactors.
            context
                .clientCapabilities
                ?.supportedInteractiveFormInputTypes
                .isNotEmpty ??
            false;

        var parameters = producer is ParameterizedRefactoringProducer
            ? producer.parameters
            : <CommandParameter>[];
        // In debug mode, throw if we produced a refactoring that has parameters
        // without default values. Support for fields without defaults was
        // removed since this functionality was replaced by Interactive Forms,
        // the only existing interactive refactor always has one, and we do not
        // intend to add any more.
        assert(
          parameters.every((parameter) => parameter.defaultValue != null),
          '${producer.title} refactor returned parameters without defaults',
        );

        var command = entry.key;
        assert(
          (() => Commands.serverSupportedCommands.contains(command))(),
          'serverSupportedCommands did not contain $command',
        );

        refactorings.add(
          CodeActionLiteral(
            title: producer.title,
            kind: producer.kind,
            command: Command(
              command: command,
              title: producer.title,
              arguments: buildCommandArguments(
                context,
                parameters.map((param) => param.defaultValue).toList(),
              ),
            ),
            // Only include the parameters in data if interactive forms are NOT
            // enabled, because if they are this will be handled by
            // `command/resolve` and we don't want to trigger the old version
            // on the client.
            data: parameters.isNotEmpty && !interactiveFormsEnabled
                ? {'parameters': parameters}
                : null,
          ),
        );
        _performance?.producerTimings.add((
          className: producer.runtimeType.toString(),
          elapsedTime: _timer.elapsedMilliseconds - startTime,
        ));
      }

      if (_performance?.operationPerformance != null) {
        await _performance!.operationPerformance!.runAsync(
          producer.runtimeType.toString(),
          (_) async => await action(),
        );
      } else {
        await action();
      }
    }
    _timer.stop();
    _performance?.computeTime = _timer.elapsed;
    return refactorings;
  }

  /// Builds the command arguments that go to the client, which include the
  /// values required to rebuild the refactoring context, and the arguments
  /// specific to the refactor.
  ///
  /// We always use a single argument that is a map so all values are named,
  /// with the refactor-specific arguments being in the `arguments` field of
  /// that map.
  ///
  /// This is the opposite of [extractRefactorArguments] which extracts the
  /// refactor arguments back out of the command.
  static List<Object?> buildCommandArguments(
    RefactoringContext context,
    List<Object?> refactorAguments,
  ) {
    return [
      {
        'filePath': context.resolvedUnitResult.path,
        'selectionOffset': context.selectionOffset,
        'selectionLength': context.selectionLength,
        'arguments': refactorAguments,
      },
    ];
  }
}
