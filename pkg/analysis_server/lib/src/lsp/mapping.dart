import 'package:analysis_server/lsp_protocol/protocol_generated.dart' as lsp;
import 'package:analysis_server/lsp_protocol/protocol_special.dart' as lsp;
import 'package:analysis_server/protocol/protocol_generated.dart' as server;
import 'package:analyzer/error/error.dart' as server;
import 'package:analyzer/source/line_info.dart' as server;
import 'package:analyzer/src/generated/source.dart' as server;

const languageSourceName = 'dart';

lsp.Diagnostic toDiagnostic(
    server.LineInfo lineInfo, server.AnalysisError error,
    [server.ErrorSeverity errorSeverity]) {
  server.ErrorCode errorCode = error.errorCode;

  // Default to the error's severity if none is specified.
  errorSeverity ??= errorCode.errorSeverity;

  return new lsp.Diagnostic(
    toRange(lineInfo, error.offset, error.length),
    toDiagnosticSeverity(errorSeverity),
    // TODO(dantup): We should strip these union types in places where we know
    // we'll only generate one set from the server to simplify this code. We only
    // need to keep unions where the value may be either (eg. originates
    // from the client).
    lsp.Either2<num, String>.t2(errorCode.name.toLowerCase()),
    languageSourceName,
    error.message,
    null,
  );
}

lsp.Range toRange(server.LineInfo lineInfo, int offset, int length) {
  server.CharacterLocation start = lineInfo.getLocation(offset);
  server.CharacterLocation end = lineInfo.getLocation(offset + length);

  return new lsp.Range(
    toPosition(start),
    toPosition(end),
  );
}

lsp.Position toPosition(server.CharacterLocation location) {
  // LSP is zero-based, but analysis server is 1-based.
  return new lsp.Position(location.lineNumber - 1, location.columnNumber - 1);
}

lsp.DiagnosticSeverity toDiagnosticSeverity(server.ErrorSeverity severity) {
  switch (severity) {
    case server.ErrorSeverity.ERROR:
      return lsp.DiagnosticSeverity.Error;
    case server.ErrorSeverity.WARNING:
      return lsp.DiagnosticSeverity.Warning;
    case server.ErrorSeverity.INFO:
      return lsp.DiagnosticSeverity.Information;
    // Note: LSP also supports "Hint", but they won't render in things like the
    // VS Code errors list as they're apparently intended to communicate
    // non-visible diagnostics back (for example, if you wanted to grey out
    // unreachable code without producing an item in the error list).
    default:
      throw 'Unknown AnalysisErrorSeverity: $severity';
  }
}

lsp.MarkupContent asMarkdown(String content) =>
    new lsp.MarkupContent(lsp.MarkupKind.Markdown, content);

/// Returns the file system path for a TextDocumentIdentifier.
String pathOf(lsp.TextDocumentIdentifier doc) =>
    Uri.parse(doc.uri).toFilePath();
