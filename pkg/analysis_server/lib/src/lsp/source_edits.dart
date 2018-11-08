import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analyzer/source/line_info.dart';

String applyEdits(
    String oldContent, List<TextDocumentContentChangeEvent> changes) {
  String newContent = oldContent;
  changes.forEach((change) {
    if (change.range == null && change.rangeLength == null) {
      newContent = change.text;
    } else {
      final lines = LineInfo.fromContent(newContent);
      final offsetOfStartLine = lines.getOffsetOfLine(change.range.start.line);
      final offsetOfStartCharacter =
          offsetOfStartLine + change.range.start.character;
      final offsetOfEndLine = lines.getOffsetOfLine(change.range.end.line);
      final offsetOfEndCharacter = offsetOfEndLine + change.range.end.character;
      newContent = newContent.replaceRange(
          offsetOfStartCharacter, offsetOfEndCharacter, change.text);
    }
  });
  return newContent;
}
