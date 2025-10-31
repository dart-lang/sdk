// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/services/refactoring/framework/refactoring_processor.dart';

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
/// The `.` is not included because it falsely triggers whenever typing a
/// cascade (`..`), inserting the very first completion instead of just a second
/// period.
const dartCompletionCommitCharacters = ['('];

/// Set the characters that will cause the editor to automatically
/// trigger completion.
const dartCompletionTriggerCharacters = [
  '.',
  '=',
  '(',
  r'$',
  '"',
  "'",
  '{',
  '/',
  ':',
];

/// Characters that refresh signature help only if it's already open on the client.
const dartSignatureHelpRetriggerCharacters = <String>[','];

/// Characters that automatically trigger signature help when typed in the client.
const dartSignatureHelpTriggerCharacters = <String>['('];

/// Characters to trigger formatting when format-on-type is enabled.
const dartTypeFormattingCharacters = ['}', ';'];

/// A [TextDocumentFilterScheme] for Analysis Options files.
final analysisOptionsFile = TextDocumentFilterScheme(
  language: 'yaml',
  scheme: 'file',
  pattern: '**/analysis_options.yaml',
);

/// A [ProgressToken] used for reporting progress while the server is analyzing.
final analyzingProgressToken = ProgressToken.t2('ANALYZING');

final emptyWorkspaceEdit = WorkspaceEdit();

final fileOperationRegistrationOptions = FileOperationRegistrationOptions(
  filters: [
    FileOperationFilter(
      scheme: 'file',
      pattern: FileOperationPattern(
        glob: '**/*.dart',
        matches: FileOperationPatternKind.file,
      ),
    ),
    FileOperationFilter(
      scheme: 'file',
      pattern: FileOperationPattern(
        glob: '**/',
        matches: FileOperationPatternKind.folder,
      ),
    ),
  ],
);

/// A [TextDocumentFilterScheme] for Fix Data files.
final fixDataFile = TextDocumentFilterScheme(
  language: 'yaml',
  scheme: 'file',
  pattern: '**/lib/{fix_data.yaml,fix_data/**.yaml}',
);

/// A [TextDocumentFilterScheme] for Pubspec files.
final pubspecFile = TextDocumentFilterScheme(
  language: 'yaml',
  scheme: 'file',
  pattern: '**/pubspec.yaml',
);

/// IDs of client-provided commands that the server knows about.
///
/// Clients can advertise support for these commands and the server can then use
/// them in returns commands in CodeActions, CodeLenses etc.
abstract final class ClientCommands {
  static const goToLocation = 'dart.goToLocation';
}

/// Constants for command IDs that are exchanged between LSP client/server.
abstract final class Commands {
  /// A list of all commands IDs that can be sent to the client to inform which
  /// commands should be sent to the server for execution (as opposed to being
  /// executed in the local plugin).
  static final serverSupportedCommands = [
    applyCodeAction,
    sortMembers,
    organizeImports,
    fixAll,
    previewFixAllInWorkspace,
    fixAllInWorkspace,
    sendWorkspaceEdit,
    performRefactor,
    validateRefactor,
    logAction,
    // Add commands for each of the new refactorings.
    ...RefactoringProcessor.generators.keys,
  ];
  static const applyCodeAction = 'dart.edit.codeAction.apply';
  static const sortMembers = 'dart.edit.sortMembers';
  static const organizeImports = 'dart.edit.organizeImports';
  static const fixAll = 'dart.edit.fixAll';
  static const fixAllInWorkspace = 'dart.edit.fixAllInWorkspace';
  static const previewFixAllInWorkspace = 'dart.edit.fixAllInWorkspace.preview';
  static const sendWorkspaceEdit = 'dart.edit.sendWorkspaceEdit';
  static const logAction = 'dart.logAction';
  // TODO(dantup): These command IDs are globally registered in the editor so
  //  should be prefixed (eg. with "dart.") to avoid potential collisions with
  //  other extensions. However, the refactor.* are hard-coded into Dart-Code
  //  for some improved integration, so cannot be updated until some time has
  //  passed where Dart-Code supports prefixed versions.
  //  Support for "dart." prefixed versions shipped in Dart-Code March 2023.
  static const performRefactor = 'refactor.perform';
  static const validateRefactor = 'refactor.validate';
}

abstract final class CustomMethods {
  static const augmented = Method('dart/textDocument/augmented');
  static const augmentation = Method('dart/textDocument/augmentation');
  static const connectToDtd = Method('dart/connectToDtd');
  static const diagnosticServer = Method('dart/diagnosticServer');
  static const reanalyze = Method('dart/reanalyze');
  static const openUri = Method('dart/openUri');
  static const publishClosingLabels = Method(
    'dart/textDocument/publishClosingLabels',
  );
  static const publishOutline = Method('dart/textDocument/publishOutline');
  static const publishFlutterOutline = Method(
    'dart/textDocument/publishFlutterOutline',
  );
  static const summary = Method('dart/textDocument/summary');
  static const super_ = Method('dart/textDocument/super');
  static const imports = Method('dart/textDocument/imports');
  static const dartTextDocumentContent = Method('dart/textDocumentContent');
  static const dartTextDocumentContentDidChange = Method(
    'dart/textDocumentContentDidChange',
  );

  /// Method for requesting the set of editable arguments at a location in a
  /// document.
  static const dartTextDocumentEditableArguments = Method(
    'dart/textDocument/editableArguments',
  );

  /// Method for adding/editing an argument at a location in a document.
  static const dartTextDocumentEditArgument = Method(
    'dart/textDocument/editArgument',
  );

  // TODO(dantup): Remove custom AnalyzerStatus status method soon as no clients
  //  should be relying on it as we now support proper $/progress events.
  static const analyzerStatus = Method(r'$/analyzerStatus');

  /// Semantic tokens are dynamically registered using a single string
  /// "textDocument/semanticTokens" instead of for each individual method
  /// (full, range, full/delta) so the built-in Method class does not contain
  /// the required constant.
  static const semanticTokenDynamicRegistration = Method(
    'textDocument/semanticTokens',
  );

  /// Used to pass diagnostic information from the client editor to the server
  /// that can be shown in the analyzer diagnostic pages, and also included in
  /// the exported diagnostic report.
  static const updateDiagnosticInformation = Method(
    'dart/updateDiagnosticInformation',
  );

  /// An experimental 'echo' handler that can used by tests to verify
  /// experimental handlers only show up when requested.
  static const experimentalEcho = Method('experimental/echo');
}

abstract final class CustomSemanticTokenModifiers {
  /// A modifier applied to the identifier following the `@` annotation token to
  /// allow users to color it differently (for example in the same way as `@`).
  static const annotation = SemanticTokenModifiers('annotation');

  /// A modifier applied to control keywords like if/for/etc. so they can be
  /// colored differently to other keywords (void, import, etc), matching the
  /// original Dart textmate grammar.
  /// https://github.com/dart-lang/dart-syntax-highlight/blob/84a8e84f79bc917ebd959a4587349c865dc945e0/grammars/dart.json#L244-L261
  static const control = SemanticTokenModifiers('control');

  /// A modifier applied to the identifier for an import prefix.
  static const importPrefix = SemanticTokenModifiers('importPrefix');

  /// A modifier applied to parameter references to indicate they are the name/label
  /// to allow theming them differently to the values.
  ///
  /// This is different to [CustomSemanticTokenTypes.label] which is for labels
  /// as used in loops/switch statements.
  ///
  /// In the code `foo({String a}) => foo(a: a)` the a's will be differentiated
  /// as:
  /// - parameter.declaration
  /// - parameter.label
  /// - parameter
  static const label = SemanticTokenModifiers('label');

  /// A modifier applied to constructors to allow coloring them differently
  /// to class names that are not constructors.
  static const constructor = SemanticTokenModifiers('constructor');

  /// A modifier applied to wildcards.
  static const wildcard = SemanticTokenModifiers('wildcard');

  /// A modifier applied to escape characters within a string to allow coloring
  /// them differently.
  static const escape = SemanticTokenModifiers('escape');

  /// A modifier applied to an interpolation expression in a string to allow
  /// coloring it differently to the literal parts of the string.
  ///
  /// Many tokens within interpolation expressions will get their own semantic
  /// tokens so this is mainly to account for the surrounding `${}` and
  /// tokens like parens and operators that may not get their own.
  ///
  /// This is useful for editors that supply their own basic coloring initially
  /// (for faster coloring) and then layer semantic tokens over the top. Without
  /// some marker for interpolation expressions, all otherwise-uncolored parts
  /// of the expression would show through the simple-colorings "string" colors.
  static const interpolation = SemanticTokenModifiers('interpolation');

  /// A modifier applied to instance field/getter/setter/method references and
  /// declarations to distinguish them from top-levels.
  static const instance = SemanticTokenModifiers('instance');

  /// A modifier applied to the void keyword to allow users to color it
  /// differently (for example as a type).
  static const void_ = SemanticTokenModifiers('void');

  /// All custom semantic token modifiers, used to populate the LSP Legend.
  ///
  /// The legend must include all used modifiers. Modifiers used in the
  /// HighlightRegion mappings will be automatically included, but should still
  /// be listed here in case they are removed from mappings in the future.
  static const values = [
    annotation,
    control,
    importPrefix,
    instance,
    label,
    constructor,
    escape,
    interpolation,
    void_,
    wildcard,
  ];
}

abstract final class CustomSemanticTokenTypes {
  static const annotation = SemanticTokenTypes('annotation');
  static const boolean = SemanticTokenTypes('boolean');

  /// A token type for labels.
  ///
  /// This is different to [CustomSemanticTokenModifiers.label] which is for
  /// parameter name labels.
  ///
  /// 'label' is listed as a standard VS Code token type at
  /// https://code.visualstudio.com/api/language-extensions/semantic-highlight-guide
  /// and therefore may be used by theme authors, but it's currently not defined
  /// by LSP (and therefore missing from the code-generated SemanticTokenTypes)
  /// so we have to define it here.
  ///
  /// This can be removed once
  /// https://github.com/microsoft/language-server-protocol/issues/2137 is
  /// resolved.
  static const label = SemanticTokenTypes('label');

  /// A placeholder token type for basic source code that is not usually colored.
  ///
  /// This is used only where clients might otherwise provide their own coloring
  /// (for example coloring whole strings that may include interpolated code).
  ///
  /// Tokens using this type should generally also provide a custom
  /// [CustomSemanticTokenModifiers] to give the client more information about
  /// the reason for this token and allow specific coloring if desired.
  static const source = SemanticTokenTypes('source');

  /// All custom semantic token types, used to populate the LSP Legend which must
  /// include all used types.
  static const values = [annotation, boolean, label, source];
}

/// CodeActionKinds supported by the server that are not declared in the LSP spec.
abstract final class DartCodeActionKind {
  /// A list of all supported CodeAction kinds, supplied to the client during
  /// initialization to allow enabling features based upon them.
  static const serverSupportedKinds = [
    CodeActionKind.Source,
    // We have to explicitly list this for the client to enable built-in command.
    CodeActionKind.SourceOrganizeImports,
    fixAll,
    sortMembers,
    CodeActionKind.QuickFix,
    CodeActionKind.Refactor,
  ];
  static const sortMembers = CodeActionKind('source.sortMembers');
  // TODO(dantup): Once this PR is merged into LSP and released, regenerated the
  //   LSP protocol code and swap this code CodeActionKind.SourceFixAll
  //   https://github.com/microsoft/language-server-protocol/pull/1308
  static const fixAll = CodeActionKind('source.fixAll');
  // TODO(dantup): Remove this in favour of CodeActionKind.RefactorMove once it
  //   has been added to a published LSP version.
  static const refactorMove = CodeActionKind('refactor.move');
}

abstract final class ServerErrorCodes {
  // JSON-RPC reserves -32000 to -32099 for implementation-defined server-errors.
  static const serverAlreadyStarted = ErrorCodes(-32000);
  static const unhandledError = ErrorCodes(-32001);
  static const serverAlreadyInitialized = ErrorCodes(-32002);
  static const invalidFilePath = ErrorCodes(-32003);
  static const invalidFileLineCol = ErrorCodes(-32004);
  static const unknownCommand = ErrorCodes(-32005);
  static const invalidCommandArguments = ErrorCodes(-32006);

  /// A file that is not part of the analyzed set.
  static const fileNotAnalyzed = ErrorCodes(-32007);
  static const fileHasErrors = ErrorCodes(-32008);
  static const clientFailedToApplyEdit = ErrorCodes(-32009);
  static const renameNotValid = ErrorCodes(-32010);
  static const featureDisabled = ErrorCodes(-32012);

  /// A file that is expected to be analyzed, but failed.
  static const fileAnalysisFailed = ErrorCodes(-32013);

  /// Computation of a refactoring change failed.
  static const refactoringComputeStatusFailure = ErrorCodes(-32014);

  /// General state error.
  static const stateError = ErrorCodes(-32015);

  /// A request was made that requires use of workspace/applyEdit but the
  /// current editor does not support it.
  static const editsUnsupportedByEditor = ErrorCodes(-32016);

  /// An editArgument request tried to modify an invocation at a position where
  /// there was no invocation.
  static const editArgumentInvalidPosition = ErrorCodes(-32017);

  /// An editArgument request tried to modify a parameter that does not exist or
  /// is not editable.
  static const editArgumentInvalidParameter = ErrorCodes(-32018);

  /// An editArgument request tried to set an argument value that is not valid.
  static const editArgumentInvalidValue = ErrorCodes(-32019);

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
  static const clientServerInconsistentState = ErrorCodes(-32099);
}

/// Strings used in user prompts (window/showMessageRequest).
abstract final class UserPromptActions {
  static const String yes = 'Yes';
  static const String no = 'No';
  static const String cancel = 'Cancel';
  static const String renameAnyway = 'Rename Anyway';
}
