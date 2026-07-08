// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

final _expectationPattern = RegExp(
  r'//[ \t]*\[diag\.([A-Za-z_][A-Za-z0-9_]*)\]',
);

/// Returns diagnostic code references in expectation comments embedded in a
/// string literal token lexeme.
List<AnalyzerDiagnosticExpectationReference>
analyzerDiagnosticExpectationReferences(String lexeme) {
  return [
    for (var match in _expectationPattern.allMatches(lexeme))
      if (match.group(1) case var name?)
        AnalyzerDiagnosticExpectationReference(
          name: name,
          offsetInLexeme: match.end - 1 - name.length,
        ),
  ];
}

/// Whether analyzer diagnostic expectation comments should be recognized for a
/// file with the given URI string.
bool canContainAnalyzerDiagnosticExpectations(String uriStr) {
  return uriStr.contains('/pkg/analyzer/test/');
}

/// A reference to a diagnostic code in an analyzer test expectation comment.
final class AnalyzerDiagnosticExpectationReference {
  /// The name after `diag.` in an expectation such as `// [diag.foo]`.
  final String name;

  /// The offset of [name] relative to the string literal token lexeme.
  final int offsetInLexeme;

  const AnalyzerDiagnosticExpectationReference({
    required this.name,
    required this.offsetInLexeme,
  });
}
