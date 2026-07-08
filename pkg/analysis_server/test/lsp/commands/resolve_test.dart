// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/refactoring/add_import_prefix.dart';
import 'package:analysis_server/src/services/refactoring/move_top_level_to_file.dart';
import 'package:language_server_protocol/protocol_custom_generated.dart';
import 'package:language_server_protocol/protocol_generated.dart';
import 'package:matcher/matcher.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../src/services/refactoring/refactoring_test_support.dart';
import '../../support/interactive_forms.dart';
import '../../utils/lsp_protocol_extensions.dart';
import '../server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CommandResolveTest);
    defineReflectiveTests(CommandResolveFileInputTest);
    defineReflectiveTests(CommandResolveStringInputTest);
  });
}

/// Tests file inputs in `command/resolve` using the MoveToFile refactor.
@reflectiveTest
class CommandResolveFileInputTest extends RefactoringTest {
  /// Simple file content with a single class named 'A'.
  final simpleClassContent = '''
class ^A {}
''';

  /// The title of the refactor when using [simpleClassContent].
  final simpleClassRefactorTitle = "Move 'A' to file";

  @override
  String get refactoringCommandId => MoveTopLevelToFile.commandName;

  @override
  void setUp() {
    super.setUp();

    // Most of the tests here assume we support file. Tests that do not will
    // explicitly unset this.
    setSupportedInteractiveFormInputKinds({'file'});

    // Move to file also requires file create support.
    setFileCreateSupport();
  }

  Future<void> test_acceptsValidAnswers() async {
    addTestSource(simpleClassContent);
    var newFilePath = join(projectFolderPath, 'lib', 'valid_destination.dart');
    var newFileUri = Uri.file(newFilePath);

    await initializeServer();
    var action = await expectCodeActionWithTitle(simpleClassRefactorTitle);
    var command = action.asCommand;

    // Resolve the command, which should add the outstanding form fields.
    var resolvedCommand = await resolveCommand(
      ExecuteCommandParams(
        command: command.command,
        arguments: command.arguments,
      ),
    );

    // Resolve again, with a valid answer.
    expect(resolvedCommand.formFields, hasLength(1));
    var field = resolvedCommand.formFields!.single;
    resolvedCommand = await resolveCommand(
      InteractiveExecuteCommandParams(
        command: resolvedCommand.command,
        arguments: resolvedCommand.arguments,
        formFields: resolvedCommand.formFields,
        formAnswers: [field.answer(newFileUri.toString())], // Valid answer.
      ),
    );

    // Check that the form field has gone, and that the valid answer was moved
    // into the command arguments.
    expect(resolvedCommand.formFields, isNull); // No more fields to complete.
    var arguments = getRefactorCommandArguments(resolvedCommand.arguments);
    expect(arguments, hasLength(1));
    expect(arguments.single, newFileUri.toString());
  }

  Future<void> test_formFields_notSupported() async {
    // If we don't support the 'file' kind, then we shouldn't get back any
    // form fields, only the default value in the arguments.
    setSupportedInteractiveFormInputKinds({'number'});

    addTestSource(simpleClassContent);
    var newFilePath = join(projectFolderPath, 'lib', 'a.dart');
    var newFileUri = Uri.file(newFilePath);

    await initializeServer();
    var action = await expectCodeActionWithTitle(simpleClassRefactorTitle);
    var command = action.asCommand;

    // Resolve the command, which would normally add the form fields, but the
    // only one used here is not supported by us.
    var resolvedCommand = await resolveCommand(
      ExecuteCommandParams(
        command: command.command,
        arguments: command.arguments,
      ),
    );

    // Check basics.
    expect(resolvedCommand.command, command.command);
    expect(resolvedCommand.arguments, command.arguments);
    expect(resolvedCommand.formAnswers, isNull);
    expect(resolvedCommand.formFields, isNull);

    // Check the arguments to the command contain the default value so the
    // command will still work without the user prompt.
    var refactorArguments = getRefactorCommandArguments(
      resolvedCommand.arguments,
    );
    expect(refactorArguments, hasLength(1));
    expect(refactorArguments.single, newFileUri.toString());
  }

  Future<void> test_formFields_supported() async {
    addTestSource(simpleClassContent);
    var newFilePath = join(projectFolderPath, 'lib', 'a.dart');
    var newFileUri = Uri.file(newFilePath);

    await initializeServer();
    var action = await expectCodeActionWithTitle(simpleClassRefactorTitle);
    var command = action.asCommand;

    // Resolve the command, which should add the outstanding form fields.
    var resolvedCommand = await resolveCommand(
      ExecuteCommandParams(
        command: command.command,
        arguments: command.arguments,
      ),
    );

    // Check basics.
    expect(resolvedCommand.command, command.command);
    expect(resolvedCommand.arguments, command.arguments);
    expect(resolvedCommand.formAnswers, isNull);
    expect(resolvedCommand.formFields, hasLength(1));

    // Check the form field is what we'd expect.
    var field = resolvedCommand.formFields!.single;
    expect(field.type.kind, 'file');
    expect(field.description, 'Move to file');
    expect(field.defaultValue, newFileUri.toString());
    expect(field.error, isNull);
  }

  Future<void> test_validates_incorrectType() async {
    addTestSource(simpleClassContent);

    await initializeServer();
    var action = await expectCodeActionWithTitle(simpleClassRefactorTitle);
    var command = action.asCommand;

    // Resolve the command, which should add the outstanding form fields.
    var resolvedCommand = await resolveCommand(
      ExecuteCommandParams(
        command: command.command,
        arguments: command.arguments,
      ),
    );

    // Resolve again, with an incorrect type for the URI.
    expect(resolvedCommand.formFields, hasLength(1));
    var field = resolvedCommand.formFields!.single;
    resolvedCommand = await resolveCommand(
      InteractiveExecuteCommandParams(
        command: resolvedCommand.command,
        arguments: resolvedCommand.arguments,
        formFields: resolvedCommand.formFields,
        formAnswers: [field.answer(true)], // Wrong type.
      ),
    );

    // Check the field has a validation error and the current value is
    // preserved.
    expect(resolvedCommand.formFields, hasLength(1));
    field = resolvedCommand.formFields!.single;
    expect(field.error, contains('valid file:// URI'));
    expect(resolvedCommand.formAnswers!.single, field.answer(true));
  }

  Future<void> test_validates_invalidUri() async {
    addTestSource(simpleClassContent);

    await initializeServer();
    var action = await expectCodeActionWithTitle(simpleClassRefactorTitle);
    var command = action.asCommand;

    // Resolve the command, which should add the outstanding form fields.
    var resolvedCommand = await resolveCommand(
      ExecuteCommandParams(
        command: command.command,
        arguments: command.arguments,
      ),
    );

    // Resolve again, with an invalid value for URI.
    expect(resolvedCommand.formFields, hasLength(1));
    var field = resolvedCommand.formFields!.single;
    resolvedCommand = await resolveCommand(
      InteractiveExecuteCommandParams(
        command: resolvedCommand.command,
        arguments: resolvedCommand.arguments,
        formFields: resolvedCommand.formFields,
        formAnswers: [field.answer('not a valid file uri')],
      ),
    );

    // Check the field has a validation error and the current value is
    // preserved.
    expect(resolvedCommand.formFields, hasLength(1));
    field = resolvedCommand.formFields!.single;
    expect(field.error, contains('valid file:// URI'));
    expect(
      resolvedCommand.formAnswers!.single,
      field.answer('not a valid file uri'),
    );
  }

  Future<void> test_validates_notFileUri() async {
    addTestSource(simpleClassContent);

    await initializeServer();
    var action = await expectCodeActionWithTitle(simpleClassRefactorTitle);
    var command = action.asCommand;

    // Resolve the command, which should add the outstanding form fields.
    var resolvedCommand = await resolveCommand(
      ExecuteCommandParams(
        command: command.command,
        arguments: command.arguments,
      ),
    );

    // Resolve again, with the wrong scheme for the URI.
    expect(resolvedCommand.formFields, hasLength(1));
    var field = resolvedCommand.formFields!.single;
    resolvedCommand = await resolveCommand(
      InteractiveExecuteCommandParams(
        command: resolvedCommand.command,
        arguments: resolvedCommand.arguments,
        formFields: resolvedCommand.formFields,
        formAnswers: [field.answer('https://example.org')],
      ),
    );

    // Check the field has a validation error and the current value is
    // preserved.
    expect(resolvedCommand.formFields, hasLength(1));
    field = resolvedCommand.formFields!.single;
    expect(field.error, contains('valid file:// URI'));
    expect(
      resolvedCommand.formAnswers!.single,
      field.answer('https://example.org'),
    );
  }
}

/// Tests string inputs in `command/resolve` using the AddImportPrefix refactor.
@reflectiveTest
class CommandResolveStringInputTest extends RefactoringTest {
  final source = '''
^import 'package:test/main.dart';
''';

  @override
  String get refactoringCommandId => AddImportPrefix.commandName;

  String get refactoringTitle => AddImportPrefix.constTitle;

  @override
  void setUp() {
    super.setUp();

    // Most of the tests here assume we support string. Tests that do not will
    // explicitly unset this.
    setSupportedInteractiveFormInputKinds({'string'});
  }

  Future<void> test_acceptsValidAnswers() async {
    addTestSource(source);

    await initializeServer();
    var action = await expectCodeActionWithTitle(refactoringTitle);
    var command = action.asCommand;

    // Resolve the command, which should add the outstanding form fields.
    var resolvedCommand = await resolveCommand(
      ExecuteCommandParams(
        command: command.command,
        arguments: command.arguments,
      ),
    );

    // Resolve again, with a valid answer.
    expect(resolvedCommand.formFields, hasLength(1));
    var field = resolvedCommand.formFields!.single;
    resolvedCommand = await resolveCommand(
      InteractiveExecuteCommandParams(
        command: resolvedCommand.command,
        arguments: resolvedCommand.arguments,
        formFields: resolvedCommand.formFields,
        formAnswers: [field.answer('custom_prefix')],
      ),
    );

    // Check that the form field has gone, and that the valid answer was moved
    // into the command arguments.
    expect(resolvedCommand.formFields, isNull);
    var arguments = getRefactorCommandArguments(resolvedCommand.arguments);
    expect(arguments, hasLength(1));
    expect(arguments.single, 'custom_prefix');
  }

  Future<void> test_formFields_notSupported() async {
    // If we don't support the 'string' kind, then we shouldn't get back any
    // form fields, only the default value in the arguments.
    setSupportedInteractiveFormInputKinds({'file'});

    addTestSource(source);

    await initializeServer();
    var action = await expectCodeActionWithTitle(refactoringTitle);
    var command = action.asCommand;

    // Resolve the command, which would normally add the form fields, but the
    // only one used here is not supported by us.
    var resolvedCommand = await resolveCommand(
      ExecuteCommandParams(
        command: command.command,
        arguments: command.arguments,
      ),
    );

    // Check basics.
    expect(resolvedCommand.command, command.command);
    expect(resolvedCommand.formAnswers, isNull);
    expect(resolvedCommand.formFields, isNull);

    // Check the arguments to the command contain the default value so the
    // command will still work without the user prompt.
    var refactorArguments = getRefactorCommandArguments(
      resolvedCommand.arguments,
    );
    expect(refactorArguments, hasLength(1));
    expect(refactorArguments.single, 'main');
  }

  Future<void> test_formFields_supported() async {
    addTestSource(source);

    await initializeServer();
    var action = await expectCodeActionWithTitle(refactoringTitle);
    var command = action.asCommand;

    // Resolve the command, which should add the outstanding form fields.
    var resolvedCommand = await resolveCommand(
      ExecuteCommandParams(
        command: command.command,
        arguments: command.arguments,
      ),
    );

    // Check basics.
    expect(resolvedCommand.command, command.command);
    expect(resolvedCommand.formAnswers, isNull);
    expect(resolvedCommand.formFields, hasLength(1));

    // Because this argument is optional (because we only expect it when using
    // Interactive Forms but the refactor can be used without), args are
    // populated with the default during resolve.
    var arguments = getRefactorCommandArguments(resolvedCommand.arguments);
    expect(arguments, hasLength(1));
    expect(arguments.single, 'main');

    // Check the form field is what we'd expect.
    var field = resolvedCommand.formFields!.single;
    expect(field.type.kind, 'string');
    expect(field.description, 'Import Prefix');
    expect(field.defaultValue, 'main');
    expect(field.error, isNull);
  }

  Future<void> test_validates_invalidValue() async {
    addTestSource(source);

    await initializeServer();
    var action = await expectCodeActionWithTitle(refactoringTitle);
    var command = action.asCommand;

    // Resolve the command, which should add the outstanding form fields.
    var resolvedCommand = await resolveCommand(
      ExecuteCommandParams(
        command: command.command,
        arguments: command.arguments,
      ),
    );

    // Resolve again, with an invalid prefix name.
    expect(resolvedCommand.formFields, hasLength(1));
    var field = resolvedCommand.formFields!.single;
    resolvedCommand = await resolveCommand(
      InteractiveExecuteCommandParams(
        command: resolvedCommand.command,
        arguments: resolvedCommand.arguments,
        formFields: resolvedCommand.formFields,
        formAnswers: [field.answer('Invalid Prefix')],
      ),
    );

    // Check the field has a validation error and the current value is
    // preserved.
    expect(resolvedCommand.formFields, hasLength(1));
    field = resolvedCommand.formFields!.single;
    expect(field.error, "Import prefix name must not contain ' '.");
    expect(resolvedCommand.formAnswers!.single, field.answer('Invalid Prefix'));

    // Resolve again with a valid value and ensure the field is completed.
    resolvedCommand = await resolveCommand(
      InteractiveExecuteCommandParams(
        command: resolvedCommand.command,
        arguments: resolvedCommand.arguments,
        formFields: resolvedCommand.formFields,
        formAnswers: [field.answer('valid_prefix')],
      ),
    );

    expect(resolvedCommand.formFields, isNull);
    var arguments = getRefactorCommandArguments(resolvedCommand.arguments);
    expect(arguments, hasLength(1));
    expect(arguments.single, 'valid_prefix');
  }
}

@reflectiveTest
class CommandResolveTest extends AbstractLspAnalysisServerTest {
  Future<void> test_returnsInputForUnknownCommand() async {
    // Basic command that only includes the normal fields from
    // ExecuteCommandParams. This ensures calling resolve() for commands that
    // don't need form input will return the same result (with no formFields).
    var command = InteractiveExecuteCommandParams(
      command: 'my_unknown_command',
      arguments: [1, 'two'],
    );

    await initialize();

    var resolvedCommand = await resolveCommand(command);

    expect(resolvedCommand, command);
  }
}
