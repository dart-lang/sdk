// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:test/test.dart';

/// A description of an error that is expected to be reported.
class ExpectedError {
  /// An empty array of error descriptors used when no errors are expected.
  static List<ExpectedError> NO_ERRORS = <ExpectedError>[];

  /// The error code associated with the error.
  final ErrorCode code;

  /// The offset of the beginning of the error's region.
  final int offset;

  /// The offset of the beginning of the error's region.
  final int length;

  /// The list of context messages that are expected to be associated with the
  /// error.
  final List<ExpectedMessage> expectedMessages;

  /// Initialize a newly created error description.
  ExpectedError(this.code, this.offset, this.length,
      {this.expectedMessages = const <ExpectedMessage>[]});

  /// Return `true` if the [error] matches this description of what it's
  /// expected to be.
  bool matches(AnalysisError error) {
    if (error.offset != offset ||
        error.length != length ||
        error.errorCode != code) {
      return false;
    }
    List<DiagnosticMessage> contextMessages = error.contextMessages.toList();
    contextMessages.sort((first, second) {
      int result = first.filePath.compareTo(second.filePath);
      if (result != 0) {
        return result;
      }
      return second.offset - first.offset;
    });
    if (contextMessages.length != expectedMessages.length) {
      return false;
    }
    for (int i = 0; i < expectedMessages.length; i++) {
      if (!expectedMessages[i].matches(contextMessages[i])) {
        return false;
      }
    }
    return true;
  }
}

/// A description of a message that is expected to be reported with an error.
class ExpectedMessage {
  /// The path of the file with which the message is associated.
  final String filePath;

  /// The offset of the beginning of the error's region.
  final int offset;

  /// The offset of the beginning of the error's region.
  final int length;

  ExpectedMessage(this.filePath, this.offset, this.length);

  /// Return `true` if the [message] matches this description of what it's
  /// expected to be.
  bool matches(DiagnosticMessage message) {
    return message.filePath == filePath &&
        message.offset == offset &&
        message.length == length;
  }
}

/// An error listener that collects all of the errors passed to it for later
/// examination.
class GatheringErrorListener implements AnalysisErrorListener {
  /// A flag indicating whether error ranges are to be compared when comparing
  /// expected and actual errors.
  final bool checkRanges;

  /// A list containing the errors that were collected.
  List<AnalysisError> _errors = <AnalysisError>[];

  /// A table mapping sources to the line information for the source.
  Map<Source, LineInfo> _lineInfoMap = <Source, LineInfo>{};

  /// Initialize a newly created error listener to collect errors.
  GatheringErrorListener({this.checkRanges = Parser.useFasta});

  /// Return the errors that were collected.
  List<AnalysisError> get errors => _errors;

  /// Return `true` if at least one error has been gathered.
  bool get hasErrors => _errors.isNotEmpty;

  /// Add the given [errors] to this listener.
  void addAll(List<AnalysisError> errors) {
    for (AnalysisError error in errors) {
      onError(error);
    }
  }

  /// Add all of the errors recorded by the given [listener] to this listener.
  void addAll2(RecordingErrorListener listener) {
    addAll(listener.errors);
  }

  /// Assert that the number of errors that have been gathered matches the
  /// number of [expectedErrors] and that they have the expected error codes and
  /// locations. The order in which the errors were gathered is ignored.
  void assertErrors(List<ExpectedError> expectedErrors) {
    //
    // Match actual errors to expected errors.
    //
    List<AnalysisError> unmatchedActual = errors.toList();
    List<ExpectedError> unmatchedExpected = expectedErrors.toList();
    int actualIndex = 0;
    while (actualIndex < unmatchedActual.length) {
      bool matchFound = false;
      int expectedIndex = 0;
      while (expectedIndex < unmatchedExpected.length) {
        if (unmatchedExpected[expectedIndex]
            .matches(unmatchedActual[actualIndex])) {
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
    StringBuffer buffer = new StringBuffer();
    if (unmatchedExpected.isNotEmpty) {
      buffer.writeln('Expected but did not find:');
      for (ExpectedError expected in unmatchedExpected) {
        buffer.write('  ');
        buffer.write(expected.code);
        buffer.write(' [');
        buffer.write(expected.offset);
        buffer.write(', ');
        buffer.write(expected.length);
        buffer.writeln(']');
      }
    }
    if (unmatchedActual.isNotEmpty) {
      if (buffer.isNotEmpty) {
        buffer.writeln();
      }
      buffer.writeln('Found but did not expect:');
      for (AnalysisError actual in unmatchedActual) {
        buffer.write('  ');
        buffer.write(actual.errorCode);
        buffer.write(' [');
        buffer.write(actual.offset);
        buffer.write(', ');
        buffer.write(actual.length);
        buffer.writeln(']');
      }
    }
    if (buffer.isNotEmpty) {
      errors.sort((first, second) => first.offset.compareTo(second.offset));
      buffer.writeln();
      buffer.writeln('To accept the current state, expect:');
      for (AnalysisError actual in errors) {
        List<DiagnosticMessage> contextMessages = actual.contextMessages;
        buffer.write('  error(');
        buffer.write(actual.errorCode);
        buffer.write(', ');
        buffer.write(actual.offset);
        buffer.write(', ');
        buffer.write(actual.length);
        if (contextMessages.isNotEmpty) {
          buffer.write(', expectedMessages: [');
          for (int i = 0; i < contextMessages.length; i++) {
            DiagnosticMessage message = contextMessages[i];
            if (i > 0) {
              buffer.write(', ');
            }
            buffer.write('message(\'');
            buffer.write(message.filePath);
            buffer.write('\', ');
            buffer.write(message.offset);
            buffer.write(', ');
            buffer.write(message.length);
            buffer.write(')');
          }
          buffer.write(']');
        }
        buffer.writeln('),');
      }
      fail(buffer.toString());
    }
  }

  /// Assert that the number of errors that have been gathered matches the
  /// number of [expectedErrorCodes] and that they have the expected error
  /// codes. The order in which the errors were gathered is ignored.
  void assertErrorsWithCodes(
      [List<ErrorCode> expectedErrorCodes = const <ErrorCode>[]]) {
    StringBuffer buffer = new StringBuffer();
    //
    // Compute the expected number of each type of error.
    //
    Map<ErrorCode, int> expectedCounts = <ErrorCode, int>{};
    for (ErrorCode code in expectedErrorCodes) {
      int count = expectedCounts[code];
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
    Map<ErrorCode, List<AnalysisError>> errorsByCode =
        <ErrorCode, List<AnalysisError>>{};
    for (AnalysisError error in _errors) {
      errorsByCode
          .putIfAbsent(error.errorCode, () => <AnalysisError>[])
          .add(error);
    }
    //
    // Compare the expected and actual number of each type of error.
    //
    expectedCounts.forEach((ErrorCode code, int expectedCount) {
      int actualCount;
      List<AnalysisError> list = errorsByCode.remove(code);
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
        buffer.write(code.uniqueName);
        buffer.write(", found ");
        buffer.write(actualCount);
      }
    });
    //
    // Check that there are no more errors in the actual-errors map,
    // otherwise record message.
    //
    errorsByCode.forEach((ErrorCode code, List<AnalysisError> actualErrors) {
      int actualCount = actualErrors.length;
      if (buffer.length == 0) {
        buffer.write("Expected ");
      } else {
        buffer.write("; ");
      }
      buffer.write("0 errors of type ");
      buffer.write(code.uniqueName);
      buffer.write(", found ");
      buffer.write(actualCount);
      buffer.write(" (");
      for (int i = 0; i < actualErrors.length; i++) {
        AnalysisError error = actualErrors[i];
        if (i > 0) {
          buffer.write(", ");
        }
        buffer.write(error.offset);
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
  void assertErrorsWithSeverities(List<ErrorSeverity> expectedSeverities) {
    int expectedErrorCount = 0;
    int expectedWarningCount = 0;
    for (ErrorSeverity severity in expectedSeverities) {
      if (severity == ErrorSeverity.ERROR) {
        expectedErrorCount++;
      } else {
        expectedWarningCount++;
      }
    }
    int actualErrorCount = 0;
    int actualWarningCount = 0;
    for (AnalysisError error in _errors) {
      if (error.errorCode.errorSeverity == ErrorSeverity.ERROR) {
        actualErrorCount++;
      } else {
        actualWarningCount++;
      }
    }
    if (expectedErrorCount != actualErrorCount ||
        expectedWarningCount != actualWarningCount) {
      fail("Expected $expectedErrorCount errors "
          "and $expectedWarningCount warnings, "
          "found $actualErrorCount errors "
          "and $actualWarningCount warnings");
    }
  }

  /// Assert that no errors have been gathered.
  void assertNoErrors() {
    assertErrors(ExpectedError.NO_ERRORS);
  }

  /// Return the line information associated with the given [source], or `null`
  /// if no line information has been associated with the source.
  LineInfo getLineInfo(Source source) => _lineInfoMap[source];

  /// Return `true` if an error with the given [errorCode] has been gathered.
  bool hasError(ErrorCode errorCode) {
    for (AnalysisError error in _errors) {
      if (identical(error.errorCode, errorCode)) {
        return true;
      }
    }
    return false;
  }

  @override
  void onError(AnalysisError error) {
    _errors.add(error);
  }

  /// Set the line information associated with the given [source] to the given
  /// list of [lineStarts].
  void setLineInfo(Source source, List<int> lineStarts) {
    _lineInfoMap[source] = new LineInfo(lineStarts);
  }
}

/// Instances of the class [TestInstrumentor] implement an instrumentation
/// service that can be used by tests.
class TestInstrumentor extends InstrumentationService {
  /// All logged messages.
  List<String> log = [];

  TestInstrumentor() : super(null);

  @override
  void logError(String message) {
    log.add("error: $message");
  }

  @override
  void logException(dynamic exception, [StackTrace stackTrace]) {
    log.add("error: $exception $stackTrace");
  }

  @override
  void logInfo(String message, [dynamic exception]) {
    log.add("info: $message");
  }
}

class TestSource extends Source {
  String _name;
  String _contents;
  int _modificationStamp = 0;
  bool exists2 = true;

  /// A flag indicating whether an exception should be generated when an attempt
  /// is made to access the contents of this source.
  bool generateExceptionOnRead = false;

  /// The number of times that the contents of this source have been requested.
  int readCount = 0;

  TestSource([this._name = '/test.dart', this._contents]);

  TimestampedData<String> get contents {
    readCount++;
    if (generateExceptionOnRead) {
      String msg = "I/O Exception while getting the contents of " + _name;
      throw new Exception(msg);
    }
    return new TimestampedData<String>(0, _contents);
  }

  String get encoding => _name;

  String get fullName {
    return _name;
  }

  int get hashCode => 0;

  bool get isInSystemLibrary {
    return false;
  }

  @override
  int get modificationStamp =>
      generateExceptionOnRead ? -1 : _modificationStamp;

  String get shortName {
    return _name;
  }

  Uri get uri => new Uri.file(_name);

  UriKind get uriKind {
    throw new UnsupportedError('uriKind');
  }

  bool operator ==(Object other) {
    if (other is TestSource) {
      return other._name == _name;
    }
    return false;
  }

  bool exists() => exists2;

  Source resolve(String uri) {
    throw new UnsupportedError('resolve');
  }

  void setContents(String value) {
    generateExceptionOnRead = false;
    _modificationStamp = new DateTime.now().millisecondsSinceEpoch;
    _contents = value;
  }

  @override
  String toString() => '$_name';
}

class TestSourceWithUri extends TestSource {
  final Uri uri;

  TestSourceWithUri(String path, this.uri, [String content])
      : super(path, content);

  String get encoding => uri.toString();

  UriKind get uriKind {
    if (uri == null) {
      return UriKind.FILE_URI;
    } else if (uri.scheme == 'dart') {
      return UriKind.DART_URI;
    } else if (uri.scheme == 'package') {
      return UriKind.PACKAGE_URI;
    }
    return UriKind.FILE_URI;
  }

  bool operator ==(Object other) {
    if (other is TestSource) {
      return other.uri == uri;
    }
    return false;
  }
}
