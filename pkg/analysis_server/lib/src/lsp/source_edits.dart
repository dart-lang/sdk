import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/protocol_server.dart' as server
    show SourceEdit;
import 'package:analyzer/source/line_info.dart';
import 'package:dart_style/dart_style.dart';

final DartFormatter formatter = new DartFormatter();

ErrorOr<String> applyEdits(
  String oldContent,
  List<TextDocumentContentChangeEvent> changes, {
  failureIsCritical: false,
}) {
  String newContent = oldContent;
  for (var change in changes) {
    if (change.range == null && change.rangeLength == null) {
      newContent = change.text;
    } else {
      final lines = LineInfo.fromContent(newContent);
      final offsetStart = toOffset(lines, change.range.start,
          failureIsCritial: failureIsCritical);
      final offsetEnd = toOffset(lines, change.range.end,
          failureIsCritial: failureIsCritical);
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

List<TextEdit> generateEditsForFormatting(String unformattedSource) {
  final lineInfo = new LineInfo.fromContent(unformattedSource);
  final code =
      new SourceCode(unformattedSource, uri: null, isCompilationUnit: true);
  SourceCode formattedResult;
  try {
    formattedResult = formatter.formatSource(code);
  } on FormatterException {
    // If the document fails to parse, just return no edits to avoid the the
    // use seeing edits on every save with invalid code (if LSP gains the
    // ability to pass a context to know if the format was manually invoked
    // we may wish to change this to return an error for that case).
    return null;
  }
  final formattedSource = formattedResult.text;

  if (formattedSource == unformattedSource) {
    return null;
  }

  // We don't currently support returning "minimal" edits, we just replace
  // entire document.
  final end = lineInfo.getLocation(unformattedSource.length);
  return [
    new TextEdit(
      new Range(new Position(0, 0), toPosition(end)),
      formattedSource,
    )
  ];
}

/// Helper class that bundles up all information required when converting server
/// SourceEdits into LSP-compatible WorkspaceEdits.
class FileEditInformation {
  final VersionedTextDocumentIdentifier doc;
  final LineInfo lineInfo;
  final List<server.SourceEdit> edits;

  FileEditInformation(this.doc, this.lineInfo, this.edits);
}
