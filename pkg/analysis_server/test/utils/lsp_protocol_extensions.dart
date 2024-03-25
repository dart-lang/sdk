import 'package:analysis_server/lsp_protocol/protocol.dart';

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
