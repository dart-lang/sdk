import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analyzer/source/line_info.dart';

ErrorOr<String> applyEdits(
    String oldContent, List<TextDocumentContentChangeEvent> changes) {
  String newContent = oldContent;
  for (var change in changes) {
    if (change.range == null && change.rangeLength == null) {
      newContent = change.text;
    } else {
      final lines = LineInfo.fromContent(newContent);
      final offsetStart = toOffset(lines, change.range.start);
      final offsetEnd = toOffset(lines, change.range.end);
      if (offsetStart.isError) {
        return new ErrorOr<String>.error(offsetStart.error);
      }
      if (offsetEnd.isError) {
        return new ErrorOr<String>.error(offsetEnd.error);
      }
      newContent = newContent.replaceRange(
          offsetStart.result, offsetEnd.result, change.text);
    }
  }
  return new ErrorOr<String>.success(newContent);
}
