import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/protocol_server.dart' as server
    show SourceEdit;
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' as plugin;
import 'package:analyzer_plugin/utilities/pair.dart';
import 'package:dart_style/dart_style.dart';

final DartFormatter formatter = DartFormatter();

/// Transforms a sequence of LSP document change events to a sequence of source
/// edits used by analysis plugins.
///
/// Since the translation from line/characters to offsets needs to take previous
/// changes into account, this will also apply the edits to [oldContent].
ErrorOr<Pair<String, List<plugin.SourceEdit>>> applyAndConvertEditsToServer(
  String oldContent,
  List<TextDocumentContentChangeEvent> changes, {
  failureIsCritical = false,
}) {
  var newContent = oldContent;
  final serverEdits = <server.SourceEdit>[];

  for (var change in changes) {
    if (change.range == null && change.rangeLength == null) {
      serverEdits
        ..clear()
        ..add(server.SourceEdit(0, newContent.length, change.text));
      newContent = change.text;
    } else {
      final lines = LineInfo.fromContent(newContent);
      final offsetStart = toOffset(lines, change.range.start,
          failureIsCritial: failureIsCritical);
      final offsetEnd = toOffset(lines, change.range.end,
          failureIsCritial: failureIsCritical);
      if (offsetStart.isError) {
        return ErrorOr.error(offsetStart.error);
      }
      if (offsetEnd.isError) {
        return ErrorOr.error(offsetEnd.error);
      }
      newContent = newContent.replaceRange(
          offsetStart.result, offsetEnd.result, change.text);
      serverEdits.add(server.SourceEdit(offsetStart.result,
          offsetEnd.result - offsetStart.result, change.text));
    }
  }
  return ErrorOr.success(Pair(newContent, serverEdits));
}

List<TextEdit> generateEditsForFormatting(String unformattedSource) {
  final lineInfo = LineInfo.fromContent(unformattedSource);
  final code =
      SourceCode(unformattedSource, uri: null, isCompilationUnit: true);
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
    TextEdit(
      Range(Position(0, 0), toPosition(end)),
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
