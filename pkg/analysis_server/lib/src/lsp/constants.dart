// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';

/// The characters that will cause the editor to automatically commit the selected
/// completion item.
///
/// For example, pressing `(` at the location of `^` in the code below would
/// automatically commit the functions name and insert a `(` to avoid either having
/// to press `<enter>` and then `(` or having `()` included in the completion items
/// `insertText` (which is incorrect when passing a function around rather than
/// invoking it).
///
///     myLongFunctionName();
///     print(myLong^)
///
/// The `.` is not included because it falsely triggers whenver typing a
/// cascade (`..`), inserting the very first completion instead of just a second
/// period.
const dartCompletionCommitCharacters = ['('];

/// Set the characters that will cause the editor to automatically
/// trigger completion.
/// TODO(dantup): There are several characters that we want to conditionally
/// allow to trigger completion, but they can only be added when the completion
/// provider is able to handle them in context:
///
///    {   trigger if being typed in a string immediately after a $
///    '   trigger if the opening quote for an import/export
///    "   trigger if the opening quote for an import/export
///    /   trigger if as part of a path in an import/export
///    \   trigger if as part of a path in an import/export
///    :   don't trigger when typing case expressions (`case x:`)
///
/// Additionally, we need to prefix `filterText` on completion items
/// with spaces for those that can follow whitespace (eg. `foo` in
/// `myArg: foo`) to ensure they're not filtered away when the user
/// types space.
///
/// See https://github.com/Dart-Code/Dart-Code/blob/68d1cd271e88a785570257d487adbdec17abd6a3/src/providers/dart_completion_item_provider.ts#L36-L64
/// for the VS Code implementation of this.
const dartCompletionTriggerCharacters = ['.', '=', '(', r'$'];

/// Characters that refresh signature help only if it's already open on the client.
const dartSignatureHelpRetriggerCharacters = <String>[','];

/// Characters that automatically trigger signature help when typed in the client.
const dartSignatureHelpTriggerCharacters = <String>['('];

/// Characters to trigger formatting when format-on-type is enabled.
const dartTypeFormattingCharacters = ['}', ';'];

/// A [ProgressToken] used for reporting progress when the server is analyzing.
final analyzingProgressToken = Either2<num, String>.t2('ANALYZING');

final emptyWorkspaceEdit = WorkspaceEdit();

/// Constants for command IDs that are exchanged between LSP client/server.
abstract class Commands {
  /// A list of all commands IDs that can be sent to the client to inform which
  /// commands should be sent to the server for execution (as opposed to being
  /// executed in the local plugin).
  static const serverSupportedCommands = [
    sortMembers,
    organizeImports,
    sendWorkspaceEdit,
    performRefactor,
    fixAllOfErrorCodeInFile,
  ];
  static const sortMembers = 'edit.sortMembers';
  static const organizeImports = 'edit.organizeImports';
  static const sendWorkspaceEdit = 'edit.sendWorkspaceEdit';
  static const performRefactor = 'refactor.perform';
  static const fixAllOfErrorCodeInFile = 'edit.fixAll.errorCodeInFile';
}

abstract class CustomMethods {
  static const diagnosticServer = Method('dart/diagnosticServer');
  static const reanalyze = Method('dart/reanalyze');
  static const publishClosingLabels =
      Method('dart/textDocument/publishClosingLabels');
  static const publishOutline = Method('dart/textDocument/publishOutline');
  static const publishFlutterOutline =
      Method('dart/textDocument/publishFlutterOutline');
  static const super_ = Method('dart/textDocument/super');

  // TODO(dantup): Remove custom AnalyzerStatus status method soon as no clients
  // should be relying on it as we now support proper $/progress events.
  static const analyzerStatus = Method(r'$/analyzerStatus');

  /// Semantic tokens are dynamically registered using a single string
  /// "textDocument/semanticTokens" instead of for each individual method
  /// (full, range, full/delta) so the built-in Method class does not contain
  /// the required constant.
  static const semanticTokenDynamicRegistration =
      Method('textDocument/semanticTokens');
}

abstract class CustomSemanticTokenTypes {
  static const annotation = SemanticTokenTypes('annotation');
  static const boolean = SemanticTokenTypes('boolean');
}

/// CodeActionKinds supported by the server that are not declared in the LSP spec.
abstract class DartCodeActionKind {
  /// A list of all supported CodeAction kinds, supplied to the client during
  /// initialization to allow enabling features based upon them.
  static const serverSupportedKinds = [
    CodeActionKind.Source,
    // We have to explicitly list this for the client to enable built-in command.
    CodeActionKind.SourceOrganizeImports,
    SortMembers,
    CodeActionKind.QuickFix,
    CodeActionKind.Refactor,
  ];
  static const SortMembers = CodeActionKind('source.sortMembers');
}

abstract class ServerErrorCodes {
  // JSON-RPC reserves -32000 to -32099 for implementation-defined server-errors.
  static const ServerAlreadyStarted = ErrorCodes(-32000);
  static const UnhandledError = ErrorCodes(-32001);
  static const ServerAlreadyInitialized = ErrorCodes(-32002);
  static const InvalidFilePath = ErrorCodes(-32003);
  static const InvalidFileLineCol = ErrorCodes(-32004);
  static const UnknownCommand = ErrorCodes(-32005);
  static const InvalidCommandArguments = ErrorCodes(-32006);
  static const FileNotAnalyzed = ErrorCodes(-32007);
  static const FileHasErrors = ErrorCodes(-32008);
  static const ClientFailedToApplyEdit = ErrorCodes(-32009);
  static const RenameNotValid = ErrorCodes(-32010);
  static const RefactorFailed = ErrorCodes(-32011);
  static const FeatureDisabled = ErrorCodes(-32012);

  /// An error raised when the server detects that the server and client are out
  /// of sync and cannot recover. For example if a textDocument/didChange notification
  /// has invalid offsets, suggesting the client and server have become out of sync
  /// and risk invalid modifications to a file.
  ///
  /// The server should detect this error being returned, log it, then exit.
  /// The client is expected to behave as suggested in the spec:
  ///
  ///  "If a client notices that a server exists unexpectedly it should try to
  ///   restart the server. However clients should be careful to not restart a
  ///   crashing server endlessly. VS Code for example doesn't restart a server
  ///   if it crashes 5 times in the last 180 seconds."
  static const ClientServerInconsistentState = ErrorCodes(-32099);
}

/// Strings used in user prompts (window/showMessageRequest).
abstract class UserPromptActions {
  static const String cancel = 'Cancel';
  static const String renameAnyway = 'Rename Anyway';
}
