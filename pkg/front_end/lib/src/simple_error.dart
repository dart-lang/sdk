import 'package:front_end/compilation_error.dart';

import 'package:source_span/source_span.dart' show SourceSpan;

/// An error that only contains a message and no error location.
class SimpleError implements CompilationError {
  String get correction => null;
  SourceSpan get span => null;
  final String message;
  SimpleError(this.message);
}
