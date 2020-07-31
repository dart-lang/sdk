// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';

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

/// TODO(dantup): Signature help triggering is even more sensitive to
/// bad chars, so we'll need to implement the logic described here:
/// https://github.com/dart-lang/sdk/issues/34241
const dartSignatureHelpTriggerCharacters = <String>[];

/// Characters to trigger formatting when format-on-type is enabled.
const dartTypeFormattingCharacters = ['}', ';'];

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
  ];
  static const sortMembers = 'edit.sortMembers';
  static const organizeImports = 'edit.organizeImports';
  static const sendWorkspaceEdit = 'edit.sendWorkspaceEdit';
  static const performRefactor = 'refactor.perform';
}

abstract class CustomMethods {
  static const DiagnosticServer = Method('dart/diagnosticServer');
  static const PublishClosingLabels =
      Method('dart/textDocument/publishClosingLabels');
  static const PublishOutline = Method('dart/textDocument/publishOutline');
  static const PublishFlutterOutline =
      Method('dart/textDocument/publishFlutterOutline');
  static const Super = Method('dart/textDocument/super');
  static const AnalyzerStatus = Method(r'$/analyzerStatus');
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
