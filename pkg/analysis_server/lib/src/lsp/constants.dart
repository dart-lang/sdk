// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';

/// Constants for command IDs that are exchanged between LSP client/server.
abstract class Commands {
  /// A list of all commands IDs that can be sent to the client to inform which
  /// commands should be sent to the server for execution (as opposed to being
  /// executed in the local plugin).
  static const serverSupportedCommands = [sortMembers, organizeImports];
  static const sortMembers = 'edit.sortMembers';
  static const organizeImports = 'edit.organizeImports';
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
  static const SortMembers = const CodeActionKind('source.sortMembers');
}

abstract class ServerErrorCodes {
  // JSON-RPC reserves -32000 to -32099 for implementation-defined server-errors.
  static const ServerAlreadyStarted = const ErrorCodes(-32000);
  static const UnhandledError = const ErrorCodes(-32001);
  static const ServerAlreadyInitialized = const ErrorCodes(-32002);
  static const InvalidFilePath = const ErrorCodes(-32003);
  static const InvalidFileLineCol = const ErrorCodes(-32004);
  static const UnknownCommand = const ErrorCodes(-32005);
  static const InvalidCommandArguments = const ErrorCodes(-32006);
  static const FileNotAnalyzed = const ErrorCodes(-32007);
  static const FileHasErrors = const ErrorCodes(-32008);
  static const ClientFailedToApplyEdit = const ErrorCodes(-32009);
  static const RenameNotValid = const ErrorCodes(-32010);

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
  static const ClientServerInconsistentState = const ErrorCodes(-32010);
}

abstract class CustomMethods {
  static const DiagnosticServer = const Method('dart/diagnosticServer');
  static const AnalyzerStatus = const Method(r'$/analyzerStatus');
}
