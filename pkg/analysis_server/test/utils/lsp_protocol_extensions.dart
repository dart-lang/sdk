import 'package:analysis_server/lsp_protocol/protocol.dart';

extension CodeActionExtensions on CodeAction {
  /// A helper to assert (and return) that a this [CodeAction] is a
  /// [CodeActionLiteral] and not just a bare [Command].
  CodeActionLiteral get asCodeActionLiteral {
    return map(
      (literal) => literal,
      (command) =>
          throw 'Expected CodeActionLiteral, but got Command (${command.title})',
    );
  }

  /// A helper to assert (and return) that a this [CodeAction] is just a
  /// bare [Command] and not a [CodeActionLiteral].
  Command get asCommand {
    return map(
      (literal) =>
          throw 'Expected Command, but got CodeAction literal (${literal.title})',
      (command) => command,
    );
  }

  /// Whether this [CodeAction] is a [CodeActionLiteral].
  bool get isCodeActionLiteral {
    return map(
      (_) => true, // literal
      (_) => false, // command
    );
  }

  /// Whether this [CodeAction] is a [Command].
  bool get isCommand {
    return map(
      (_) => false, // literal
      (_) => true, // command
    );
  }
}

extension GlobPatternExtension on GlobPattern? {
  String? get asString {
    return this?.map(
      (string) => string,
      (relativePattern) => throw 'Expected String, got RelativePattern',
    );
  }
}

extension MarkupContentOrStringExtension on Either2<MarkupContent, String> {
  String get asString {
    return map(
      (markup) => throw 'Expected String, got MarkupContent',
      (string) => string,
    );
  }
}

extension PositionExtension on Position {
  String toText() => '${line + 1}:${character + 1}';
}

extension RangeExtension on Range {
  /// Checks whether the range covers [position] (inclusive).
  bool containsPosition(Position position) {
    // On an earlier line.
    if (position.line < start.line) {
      return false;
    }

    // On start line, but before start character.
    if (position.line == start.line && position.character < start.character) {
      return false;
    }

    // On end line, but after end character.
    if (position.line == end.line && position.character > end.character) {
      return false;
    }

    // On a later line.
    if (position.line > end.line) {
      return false;
    }

    return true;
  }

  String toText() => '${start.toText()}-${end.toText()}';
}

extension TextEditUnionExtension
    on
        Either4<
          AnnotatedTextEdit,
          LegacySnippetTextEdit,
          SnippetTextEdit,
          TextEdit
        > {
  /// Extracts a TextEdit from a union of TextEdits and SnippetTextEdits.
  ///
  /// For testing purposes, we just map snippet text edits into normal
  /// edits so that the snippet string just appears verbatim in the
  /// string.
  TextEdit extractTextEdit() {
    // All types extend from TextEdit except SnippetTextEdit which we just
    // copy over manually.
    return map(
      (e) => e,
      (e) => e,
      // For testing purposes, we just map snippet text edits into normal
      // edits so that the snippet string just appears verbatim in the
      // string.
      (snippetEdit) => TextEdit(
        range: snippetEdit.range,
        newText: snippetEdit.snippet.value,
      ),
      (e) => e,
    );
  }
}
