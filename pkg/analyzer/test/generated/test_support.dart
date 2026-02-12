// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/source/source.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer_testing/src/analysis_rule/pub_package_resolution.dart';
import 'package:analyzer_testing/utilities/extensions/diagnostic_code.dart';
import 'package:test/test.dart';

/// A diagnostic listener that collects all of the diagnostics passed to it for
/// later examination.
class GatheringDiagnosticListener implements DiagnosticListener {
  /// A flag indicating whether error ranges are to be compared when comparing
  /// expected and actual diagnostics.
  final bool checkRanges;

  /// A list containing the diagnostics that were collected.
  final List<Diagnostic> _diagnostics = [];

  /// A table mapping sources to the line information for the source.
  final Map<Source, LineInfo> _lineInfoMap = {};

  /// Initialize a newly created diagnostic listener to collect diagnostics.
  GatheringDiagnosticListener({this.checkRanges = true});

  /// Returns the diagnostics that were collected.
  List<Diagnostic> get diagnostics => _diagnostics;

  /// Whether at least one diagnostic has been gathered.
  bool get hasDiagnostics => _diagnostics.isNotEmpty;

  /// Adds the given [diagnostics] to this listener.
  void addAll(List<Diagnostic> diagnostics) {
    for (Diagnostic diagnostic in diagnostics) {
      onDiagnostic(diagnostic);
    }
  }

  /// Adds all of the diagnostics recorded by the given [listener] to this
  /// listener.
  void addAll2(RecordingDiagnosticListener listener) {
    addAll(listener.diagnostics);
  }

  /// Assert that the number of errors that have been gathered matches the
  /// number of [expectedDiagnostics] and that they have the expected error codes and
  /// locations. The order in which the errors were gathered is ignored.
  void assertErrors(List<ExpectedDiagnostic> expectedDiagnostics) {
    //
    // Match actual errors to expected errors.
    //
    List<Diagnostic> unmatchedActual = diagnostics.toList();
    List<ExpectedDiagnostic> unmatchedExpected = expectedDiagnostics.toList();
    int actualIndex = 0;
    while (actualIndex < unmatchedActual.length) {
      bool matchFound = false;
      int expectedIndex = 0;
      while (expectedIndex < unmatchedExpected.length) {
        if (unmatchedExpected[expectedIndex].matches(
          unmatchedActual[actualIndex],
        )) {
          matchFound = true;
          unmatchedActual.removeAt(actualIndex);
          unmatchedExpected.removeAt(expectedIndex);
          break;
        }
        expectedIndex++;
      }
      if (!matchFound) {
        actualIndex++;
      }
    }
    //
    // Write the results.
    //
    StringBuffer buffer = StringBuffer();
    if (unmatchedExpected.isNotEmpty) {
      buffer.writeln('Expected but did not find:');
      for (ExpectedDiagnostic expected in unmatchedExpected) {
        buffer.write('  ');
        switch (expected) {
          case ExpectedError(:var code):
            buffer.write(code.constantName);
          case ExpectedLint(:var lintName):
            buffer.write(lintName);
          case _:
            buffer.write(expected.diagnosticMatcher);
        }
        buffer.write(' [');
        buffer.write(expected.offset);
        buffer.write(', ');
        buffer.write(expected.length);
        if (expected.messageContains.isNotEmpty) {
          buffer.write(', messageContains: ');
          for (var pattern in expected.messageContains) {
            buffer.write(pattern);
            buffer.write(', ');
          }
        }
        if (expected.messageContains.isNotEmpty) {
          buffer.write(', messageContains: ');
          buffer.write(
            json.encode([
              for (var pattern in expected.messageContains) pattern.toString(),
            ]),
          );
        }
        if (expected.correctionContains != null) {
          buffer.write(', correctionContains: ');
          buffer.write(json.encode(expected.correctionContains.toString()));
        }
        if (expected.contextMessages
            case List(:var isNotEmpty) && var contextMessages when isNotEmpty) {
          buffer.write(', contextMessages: [');
          for (var i = 0; i < contextMessages.length; i++) {
            var contextMessage = contextMessages[i];
            if (i > 0) {
              buffer.write(', ');
            }
            buffer.write('message(');
            buffer.write(contextMessage.file.path);
            buffer.write(', ');
            buffer.write(contextMessage.offset);
            buffer.write(', ');
            buffer.write(contextMessage.length);
            if (contextMessage.text != null) {
              buffer.write(', text: ');
              buffer.write(json.encode(contextMessage.text));
            }
            if (contextMessage.textContains.isNotEmpty) {
              buffer.write(', textContains: ');
              buffer.write(
                json.encode([
                  for (var pattern in contextMessage.textContains)
                    pattern.toString(),
                ]),
              );
            }
            buffer.write(')');
          }
        }
        buffer.writeln(']');
      }
    }
    if (unmatchedActual.isNotEmpty) {
      if (buffer.isNotEmpty) {
        buffer.writeln();
      }
      buffer.writeln('Found but did not expect:');
      for (Diagnostic actual in unmatchedActual) {
        buffer.write('  ');
        buffer.write(actual.diagnosticCode);
        buffer.write(' [');
        buffer.write(actual.offset);
        buffer.write(', ');
        buffer.write(actual.length);
        buffer.write(', ');
        buffer.write(json.encode(actual.message));
        if (actual.correctionMessage != null) {
          buffer.write(', ');
          buffer.write(json.encode(actual.correctionMessage));
        }
        if (actual.contextMessages.isNotEmpty) {
          buffer.write(', contextMessages: [');
          for (var i = 0; i < actual.contextMessages.length; i++) {
            var message = actual.contextMessages[i];
            if (i > 0) {
              buffer.write(', ');
            }
            buffer.write('message(');
            // Special case for `testFile`, used very often.
            switch (message.filePath) {
              case '/home/test/lib/test.dart':
                buffer.write('testFile');
              case var filePath:
                buffer.write("'$filePath'");
            }
            buffer.write(', ');
            buffer.write(message.offset);
            buffer.write(', ');
            buffer.write(message.length);
            buffer.write(', ');
            buffer.write(json.encode(message.messageText(includeUrl: false)));
            buffer.write(')');
          }
        }
        buffer.writeln(']');
      }
    }
    if (buffer.isNotEmpty) {
      diagnostics.sort(
        (first, second) => first.offset.compareTo(second.offset),
      );
      buffer.writeln();
      if (diagnostics.isEmpty) {
        buffer.writeln('To accept the current state, expect no errors.');
      } else {
        buffer.writeln('To accept the current state, expect:');
        for (Diagnostic actual in diagnostics) {
          List<DiagnosticMessage> contextMessages = actual.contextMessages;
          buffer.write('  error(');
          buffer.write(actual.diagnosticCode.constantName);
          buffer.write(', ');
          buffer.write(actual.offset);
          buffer.write(', ');
          buffer.write(actual.length);
          if (contextMessages.isNotEmpty) {
            buffer.write(', contextMessages: [');
            for (int i = 0; i < contextMessages.length; i++) {
              DiagnosticMessage message = contextMessages[i];
              if (i > 0) {
                buffer.write(', ');
              }
              buffer.write('message(');

              // Special case for `testFile`, used very often.
              switch (message.filePath) {
                case '/home/test/lib/test.dart':
                  buffer.write('testFile');
                case var filePath:
                  buffer.write("'$filePath'");
              }

              buffer.write(', ');
              buffer.write(message.offset);
              buffer.write(', ');
              buffer.write(message.length);
              buffer.write(')');
            }
            buffer.write(']');
          }
          buffer.writeln('),');
        }
      }
      fail(buffer.toString());
    }
  }

  /// Asserts that the number of diagnostics that have been gathered matches the
  /// number of [expectedCodes] and that they have the expected diagnostic
  /// codes.
  ///
  /// The order in which the diagnostics were gathered is ignored.
  void assertErrorsWithCodes([
    List<DiagnosticCode> expectedCodes = const <DiagnosticCode>[],
  ]) {
    StringBuffer buffer = StringBuffer();
    // Compute the expected number of each type of diagnostic.
    Map<DiagnosticCode, int> expectedCounts = <DiagnosticCode, int>{};
    for (DiagnosticCode code in expectedCodes) {
      var count = expectedCounts[code];
      if (count == null) {
        count = 1;
      } else {
        count = count + 1;
      }
      expectedCounts[code] = count;
    }
    //
    // Compute the actual number of each type of error.
    //
    Map<DiagnosticCode, List<Diagnostic>> diagnosticsByCode =
        <DiagnosticCode, List<Diagnostic>>{};
    for (Diagnostic diagnostic in _diagnostics) {
      diagnosticsByCode
          .putIfAbsent(diagnostic.diagnosticCode, () => <Diagnostic>[])
          .add(diagnostic);
    }
    //
    // Compare the expected and actual number of each type of error.
    //
    expectedCounts.forEach((DiagnosticCode code, int expectedCount) {
      int actualCount;
      var list = diagnosticsByCode.remove(code);
      if (list == null) {
        actualCount = 0;
      } else {
        actualCount = list.length;
      }
      if (actualCount != expectedCount) {
        if (buffer.length == 0) {
          buffer.write("Expected ");
        } else {
          buffer.write("; ");
        }
        buffer.write(expectedCount);
        buffer.write(" errors of type ");
        buffer.write(code.lowerCaseUniqueName);
        buffer.write(", found ");
        buffer.write(actualCount);
      }
    });
    //
    // Check that there are no more errors in the actual-errors map,
    // otherwise record message.
    //
    diagnosticsByCode.forEach((
      DiagnosticCode code,
      List<Diagnostic> actualDiagnostics,
    ) {
      int actualCount = actualDiagnostics.length;
      if (buffer.length == 0) {
        buffer.write("Expected ");
      } else {
        buffer.write("; ");
      }
      buffer.write("0 errors of type ");
      buffer.write(code.lowerCaseUniqueName);
      buffer.write(", found ");
      buffer.write(actualCount);
      buffer.write(" (");
      for (int i = 0; i < actualDiagnostics.length; i++) {
        Diagnostic diagnostic = actualDiagnostics[i];
        if (i > 0) {
          buffer.write(", ");
        }
        buffer.write(diagnostic.offset);
      }
      buffer.write(")");
    });
    if (buffer.length > 0) {
      fail(buffer.toString());
    }
  }

  /// Assert that the number of errors that have been gathered matches the
  /// number of [expectedSeverities] and that there are the same number of
  /// errors and warnings as specified by the argument. The order in which the
  /// errors were gathered is ignored.
  void assertErrorsWithSeverities(List<DiagnosticSeverity> expectedSeverities) {
    int expectedErrorCount = 0;
    int expectedWarningCount = 0;
    for (DiagnosticSeverity severity in expectedSeverities) {
      if (severity == DiagnosticSeverity.ERROR) {
        expectedErrorCount++;
      } else {
        expectedWarningCount++;
      }
    }
    int actualErrorCount = 0;
    int actualWarningCount = 0;
    for (Diagnostic diagnostic in _diagnostics) {
      if (diagnostic.diagnosticCode.severity == DiagnosticSeverity.ERROR) {
        actualErrorCount++;
      } else {
        actualWarningCount++;
      }
    }
    if (expectedErrorCount != actualErrorCount ||
        expectedWarningCount != actualWarningCount) {
      fail(
        "Expected $expectedErrorCount errors "
        "and $expectedWarningCount warnings, "
        "found $actualErrorCount errors "
        "and $actualWarningCount warnings",
      );
    }
  }

  /// Assert that no errors have been gathered.
  void assertNoErrors() {
    assertErrors(const []);
  }

  /// Return the line information associated with the given [source], or `null`
  /// if no line information has been associated with the source.
  LineInfo? getLineInfo(Source source) => _lineInfoMap[source];

  @override
  void onDiagnostic(Diagnostic diagnostic) {
    _diagnostics.add(diagnostic);
  }

  /// Set the line information associated with the given [source] to [lineInfo].
  void setLineInfo(Source source, LineInfo lineInfo) {
    _lineInfoMap[source] = lineInfo;
  }
}

/// Instances of the class [TestInstrumentor] implement an instrumentation
/// service that can be used by tests.
class TestInstrumentor extends NoopInstrumentationService {
  /// All logged messages.
  List<String> log = [];

  @override
  void logError(String message) {
    log.add("error: $message");
  }

  @override
  void logException(
    dynamic exception, [
    StackTrace? stackTrace,
    List<InstrumentationServiceAttachment>? attachments,
  ]) {
    log.add("error: $exception $stackTrace");
  }

  @override
  void logInfo(String message, [dynamic exception]) {
    log.add("info: $message");
  }
}

class TestSource extends Source {
  final String _name;
  String _contents;
  bool exists2 = true;

  /// A flag indicating whether an exception should be generated when an attempt
  /// is made to access the contents of this source.
  bool generateExceptionOnRead = false;

  /// The number of times that the contents of this source have been requested.
  int readCount = 0;

  TestSource([this._name = '/test.dart', this._contents = '']);

  @override
  TimestampedData<String> get contents {
    readCount++;
    if (generateExceptionOnRead) {
      String msg = "I/O Exception while getting the contents of $_name";
      throw Exception(msg);
    }
    return TimestampedData<String>(0, _contents);
  }

  @override
  String get fullName {
    return _name;
  }

  @override
  int get hashCode => 0;

  @override
  String get shortName {
    return _name;
  }

  @override
  Uri get uri => Uri.file(_name);

  @override
  bool operator ==(Object other) {
    if (other is TestSource) {
      return other._name == _name;
    }
    return false;
  }

  @override
  bool exists() => exists2;

  Source resolve(String uri) {
    throw UnsupportedError('resolve');
  }

  void setContents(String value) {
    generateExceptionOnRead = false;
    _contents = value;
  }

  @override
  String toString() => _name;
}

class TestSourceWithUri extends TestSource {
  @override
  final Uri uri;

  TestSourceWithUri(String path, this.uri, [String content = ''])
    : super(path, content);

  @override
  bool operator ==(Object other) {
    if (other is TestSource) {
      return other.uri == uri;
    }
    return false;
  }
}
