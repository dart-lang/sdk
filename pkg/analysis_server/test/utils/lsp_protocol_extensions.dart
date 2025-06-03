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
}
