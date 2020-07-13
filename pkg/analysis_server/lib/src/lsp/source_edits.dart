import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/protocol_server.dart' as server
    show SourceEdit;
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' as plugin;
import 'package:analyzer_plugin/utilities/pair.dart';
import 'package:dart_style/dart_style.dart';

DartFormatter formatter = DartFormatter();

/// Transforms a sequence of LSP document change events to a sequence of source
/// edits used by analysis plugins.
///
/// Since the translation from line/characters to offsets needs to take previous
/// changes into account, this will also apply the edits to [oldContent].
ErrorOr<Pair<String, List<plugin.SourceEdit>>> applyAndConvertEditsToServer(
  String oldContent,
  List<
          Either2<TextDocumentContentChangeEvent1,
              TextDocumentContentChangeEvent2>>
      changes, {
  failureIsCritical = false,
}) {
  var newContent = oldContent;
  final serverEdits = <server.SourceEdit>[];

  for (var change in changes) {
    // Change is a union that may/may not include a range. If no range
    // is provided (t2 of the union) the whole document should be replaced.
    final result = change.map(
      // TextDocumentContentChangeEvent1
      // {range, text}
      (change) {
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
      },
      // TextDocumentContentChangeEvent2
      // {text}
      (change) {
        serverEdits
          ..clear()
          ..add(server.SourceEdit(0, newContent.length, change.text));
        newContent = change.text;
      },
    );
    // If any change fails, immediately return the error.
    if (result?.isError ?? false) {
      return ErrorOr.error(result.error);
    }
  }
  return ErrorOr.success(Pair(newContent, serverEdits));
}

List<TextEdit> generateEditsForFormatting(
    String unformattedSource, int lineLength) {
  final lineInfo = LineInfo.fromContent(unformattedSource);
  final code =
      SourceCode(unformattedSource, uri: null, isCompilationUnit: true);
  SourceCode formattedResult;
  try {
    // If the lineLength has changed, recreate the formatter with the new setting.
    if (lineLength != formatter.pageWidth) {
      formatter = DartFormatter(pageWidth: lineLength);
    }
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
      range:
          Range(start: Position(line: 0, character: 0), end: toPosition(end)),
      newText: formattedSource,
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
