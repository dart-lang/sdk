import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analyzer/source/line_info.dart';

String applyEdits(
    String oldContent, List<TextDocumentContentChangeEvent> changes) {
  String newContent = oldContent;
  changes.forEach((change) {
    if (change.range == null && change.rangeLength == null) {
      newContent = change.text;
    } else {
      final lines = LineInfo.fromContent(newContent);
      final offsetStart = toOffset(lines, change.range.start);
      final offsetEnd = toOffset(lines, change.range.end);
      newContent = newContent.replaceRange(offsetStart, offsetEnd, change.text);
    }
  });
  return newContent;
}
