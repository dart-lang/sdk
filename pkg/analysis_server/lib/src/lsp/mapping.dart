import 'package:analysis_server/lsp_protocol/protocol_generated.dart' as lsp;
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analyzer/error/error.dart' as engine;
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/generated/source.dart' as engine;

const languageSourceName = 'dart';

lsp.Diagnostic toDiagnostic(
    engine.LineInfo lineInfo, engine.AnalysisError error,
    [engine.ErrorSeverity errorSeverity]) {
  engine.ErrorCode errorCode = error.errorCode;
  CharacterLocation startLocation = lineInfo.getLocation(error.offset);
  CharacterLocation endLocation =
      lineInfo.getLocation(error.offset + error.length);

  // Default to the error's severity if none is specified.
  errorSeverity ??= errorCode.errorSeverity;

  return new lsp.Diagnostic(
    toRange(startLocation, endLocation),
    toDiagnosticSeverity(errorSeverity),
    // TODO(dantup): We should strip these union types in places where we know
    // we'll only generate one set from the server to simplify this code. We only
    // need to keep unions where the value may be either (eg. originates
    // from the client).
    Either2<num, String>.t2(errorCode.name.toLowerCase()),
    languageSourceName,
    error.message,
    null,
  );
}

lsp.Range toRange(CharacterLocation start, CharacterLocation end) {
  return new lsp.Range(
    toPosition(start),
    toPosition(end),
  );
}

lsp.Position toPosition(CharacterLocation location) {
  // LSP is zero-based, but analysis server is 1-based.
  return new lsp.Position(location.lineNumber - 1, location.columnNumber - 1);
}

lsp.DiagnosticSeverity toDiagnosticSeverity(engine.ErrorSeverity severity) {
  switch (severity) {
    case engine.ErrorSeverity.ERROR:
      return lsp.DiagnosticSeverity.Error;
    case engine.ErrorSeverity.WARNING:
      return lsp.DiagnosticSeverity.Warning;
    case engine.ErrorSeverity.INFO:
      return lsp.DiagnosticSeverity.Information;
    // Note: LSP also supports "Hint", but they won't render in things like the
    // VS Code errors list as they're apparently intended to communicate
    // non-visible diagnostics back (for example, if you wanted to grey out
    // unreachable code without producing an item in the error list).
    default:
      throw 'Unknown AnalysisErrorSeverity: $severity';
  }
}
