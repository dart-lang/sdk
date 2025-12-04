// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/error_or.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/lsp/registration/feature_registration.dart';
import 'package:analysis_server/src/lsp/source_edits.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';

typedef StaticOptions = DocumentOnTypeFormattingOptions?;

class FormatOnTypeHandler
    extends
        SharedMessageHandler<DocumentOnTypeFormattingParams, List<TextEdit>?> {
  FormatOnTypeHandler(super.server);

  @override
  Method get handlesMessage => Method.textDocument_onTypeFormatting;

  @override
  LspJsonHandler<DocumentOnTypeFormattingParams> get jsonHandler =>
      DocumentOnTypeFormattingParams.jsonHandler;

  @override
  bool get requiresTrustedCaller => false;

  Future<ErrorOr<List<TextEdit>?>> formatFile(
    String path,
    Position typedCharacterPosition,
    String typedCharacter,
  ) async {
    var file = server.resourceProvider.getFile(path);
    if (!file.exists) {
      return error(
        ServerErrorCodes.invalidFilePath,
        'File does not exist',
        path,
      );
    }

    var result = await server.getParsedUnit(path);
    if (result == null || result.diagnostics.isNotEmpty) {
      return success(null);
    }

    // The client will always send a request when a trigger character is typed
    // even if it's in a comment or something else that shouldn't trigger
    // formatting so we need to check the character/position to see if this is
    // really something that should be allowed to trigger formatting.
    if (!_shouldTriggerFormatting(
      result,
      typedCharacterPosition,
      typedCharacter,
    )) {
      return success(null);
    }

    var lineLength = server.lspClientConfiguration.forResource(path).lineLength;
    return generateEditsForFormatting(result, defaultPageWidth: lineLength);
  }

  @override
  Future<ErrorOr<List<TextEdit>?>> handle(
    DocumentOnTypeFormattingParams params,
    MessageInfo message,
    CancellationToken token,
  ) async {
    if (!isDartDocument(params.textDocument)) {
      return success(null);
    }

    var path = pathOfDoc(params.textDocument);
    return path.mapResult((path) async {
      if (!server.lspClientConfiguration.forResource(path).enableSdkFormatter) {
        // Because we now support formatting for just some WorkspaceFolders
        // we should silently do nothing for those that are disabled.
        return success(null);
      }

      return await formatFile(path, params.position, params.ch);
    });
  }

  /// Returns whether [character] at [position] should trigger formatting.
  ///
  /// Generally we only want to trigger formatting for things like a `;` at the
  /// end of a statement, and not inside something like a string or comment.
  ///
  /// Trigger characters are declared in [dartTypeFormattingCharacters].
  bool _shouldTriggerFormatting(
    ParsedUnitResult result,
    Position position,
    String character,
  ) {
    var offset =
        result.lineInfo.getOffsetOfLine(position.line) + position.character;
    var node = result.unit.nodeCovering(offset: offset);

    /// Helper to check if a token is at the current offset.
    ///
    /// Check both offset/end because the LSP spec says
    /// >> This is not necessarily the exact position where the character
    /// >> denoted by the property `ch` got typed.
    /// and in testing with VS Code it's the end.
    bool isAtOffset(Token token) =>
        token.offset == offset || token.end == offset;

    return switch (character) {
      // Only consider semicolons that are the end of statements/declarations
      ';' => switch (node) {
        // Statements
        AssertStatement(:var semicolon) ||
        BreakStatement(:var semicolon) ||
        ContinueStatement(:var semicolon) ||
        DoStatement(:var semicolon) ||
        EmptyStatement(:var semicolon) ||
        ExpressionStatement(:var semicolon?) ||
        PatternVariableDeclarationStatement(:var semicolon) ||
        ReturnStatement(:var semicolon) ||
        VariableDeclarationStatement(:var semicolon) ||
        YieldStatement(:var semicolon) ||
        // Bodies
        EmptyClassBody(:var semicolon) ||
        EmptyFunctionBody(:var semicolon) ||
        ExpressionFunctionBody(:var semicolon?) ||
        NativeFunctionBody(:var semicolon) ||
        // Declarations
        FieldDeclaration(:var semicolon) ||
        TopLevelVariableDeclaration(:var semicolon) ||
        TypeAlias(:var semicolon) ||
        // Directives
        LibraryDirective(:var semicolon) ||
        NamespaceDirective(:var semicolon) ||
        PartDirective(:var semicolon) ||
        PartOfDirective(:var semicolon) => isAtOffset(semicolon),
        _ => false,
      },
      // Only consider closing braces that are the end of "blocks" but not
      // things like patterns that might usually be inline.
      '}' => switch (node) {
        Block(:var rightBracket) ||
        BlockClassBody(:var rightBracket) ||
        EnumBody(:var rightBracket) ||
        ListLiteral(:var rightBracket) ||
        SetOrMapLiteral(:var rightBracket) ||
        SwitchExpression(:var rightBracket) ||
        SwitchStatement(:var rightBracket) => isAtOffset(rightBracket),
        _ => false,
      },
      _ => false,
    };
  }
}

class FormatOnTypeRegistrations extends FeatureRegistration
    with SingleDynamicRegistration, StaticRegistration<StaticOptions> {
  FormatOnTypeRegistrations(super.info);

  bool get enableFormatter => clientConfiguration.global.enableSdkFormatter;

  @override
  ToJsonable? get options {
    return DocumentOnTypeFormattingRegistrationOptions(
      documentSelector: dartFiles, // This is currently Dart-specific
      firstTriggerCharacter: dartTypeFormattingCharacters.first,
      moreTriggerCharacter: dartTypeFormattingCharacters.skip(1).toList(),
    );
  }

  @override
  Method get registrationMethod => Method.textDocument_onTypeFormatting;

  @override
  StaticOptions get staticOptions => enableFormatter
      ? DocumentOnTypeFormattingOptions(
          firstTriggerCharacter: dartTypeFormattingCharacters.first,
          moreTriggerCharacter: dartTypeFormattingCharacters.skip(1).toList(),
        )
      : null;

  @override
  bool get supportsDynamic => enableFormatter && clientDynamic.typeFormatting;

  @override
  bool get supportsStatic => enableFormatter;
}
