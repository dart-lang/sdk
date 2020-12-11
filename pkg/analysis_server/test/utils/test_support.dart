// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// These classes were copied from `analyzer`. They should be moved into the
/// `analyzer/lib/src/test_utilities` directory so that they can be shared.
/// (This version has been converted to a more modern style.)
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:test/test.dart';

/// A description of a message that is expected to be reported with an error.
class ExpectedContextMessage {
  /// The path of the file with which the message is associated.
  final String filePath;

  /// The offset of the beginning of the error's region.
  final int offset;

  /// The offset of the beginning of the error's region.
  final int length;

  /// The message text for the error.
  final String text;

  ExpectedContextMessage(this.filePath, this.offset, this.length, {this.text});

  /// Return `true` if the [message] matches this description of what the state
  /// of the [message] is expected to be.
  bool matches(DiagnosticMessage message) {
    return message.filePath == filePath &&
        message.offset == offset &&
        message.length == length &&
        (text == null || message.message == text);
  }
}

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

  /// The message text of the error or `null` if the message should not be checked.
  final String message;

  /// A pattern that should be contained in the error message or `null` if the message
  /// contents should not be checked.
  final Pattern messageContains;

  /// The list of context messages that are expected to be associated with the
  /// error.
  final List<ExpectedContextMessage> expectedContextMessages;

  /// Initialize a newly created error description.
  ExpectedError(this.code, this.offset, this.length,
      {this.message,
      this.messageContains,
      this.expectedContextMessages = const <ExpectedContextMessage>[]});

  /// Return `true` if the [error] matches this description of what the state
  /// of the [error] is expected to be.
  bool matches(AnalysisError error) {
    if (error.offset != offset ||
        error.length != length ||
        error.errorCode != code) {
      return false;
    }
    if (message != null && error.message != message) {
      return false;
    }
    if (messageContains != null &&
        error.message?.contains(messageContains) != true) {
      return false;
    }
    var contextMessages = error.contextMessages.toList();
    contextMessages.sort((first, second) {
      var result = first.filePath.compareTo(second.filePath);
      if (result != 0) {
        return result;
      }
      return second.offset - first.offset;
    });
    if (contextMessages.length != expectedContextMessages.length) {
      return false;
    }
    for (var i = 0; i < expectedContextMessages.length; i++) {
      if (!expectedContextMessages[i].matches(contextMessages[i])) {
        return false;
      }
    }
    return true;
  }
}

/// An error listener that collects all of the errors passed to it for later
/// examination.
class GatheringErrorListener implements AnalysisErrorListener {
  /// A flag indicating whether error ranges are to be compared when comparing
  /// expected and actual errors.
  final bool checkRanges;

  /// A list containing the errors that were collected.
  final List<AnalysisError> _errors = <AnalysisError>[];

  /// A table mapping sources to the line information for the source.
  final Map<Source, LineInfo> _lineInfoMap = <Source, LineInfo>{};

  /// Initialize a newly created error listener to collect errors.
  GatheringErrorListener({this.checkRanges = true});

  /// Return the errors that were collected.
  List<AnalysisError> get errors => _errors;

  /// Return `true` if at least one error has been gathered.
  bool get hasErrors => _errors.isNotEmpty;

  /// Add the given [errors] to this listener.
  void addAll(List<AnalysisError> errors) {
    for (var error in errors) {
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
    var unmatchedActual = errors.toList();
    var unmatchedExpected = expectedErrors.toList();
    var actualIndex = 0;
    while (actualIndex < unmatchedActual.length) {
      var matchFound = false;
      var expectedIndex = 0;
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
    var buffer = StringBuffer();
    if (unmatchedExpected.isNotEmpty) {
      buffer.writeln('Expected but did not find:');
      for (var expected in unmatchedExpected) {
        buffer.write('  ');
        buffer.write(expected.code);
        buffer.write(' [');
        buffer.write(expected.offset);
        buffer.write(', ');
        buffer.write(expected.length);
        if (expected.message != null) {
          buffer.write(', ');
          buffer.write(expected.message);
        }
        buffer.writeln(']');
      }
    }
    if (unmatchedActual.isNotEmpty) {
      if (buffer.isNotEmpty) {
        buffer.writeln();
      }
      buffer.writeln('Found but did not expect:');
      for (var actual in unmatchedActual) {
        buffer.write('  ');
        buffer.write(actual.errorCode);
        buffer.write(' [');
        buffer.write(actual.offset);
        buffer.write(', ');
        buffer.write(actual.length);
        buffer.write(', ');
        buffer.write(actual.message);
        buffer.writeln(']');
      }
    }
    if (buffer.isNotEmpty) {
      errors.sort((first, second) => first.offset.compareTo(second.offset));
      buffer.writeln();
      buffer.writeln('To accept the current state, expect:');
      for (var actual in errors) {
        var contextMessages = actual.contextMessages;
        buffer.write('  error(');
        buffer.write(actual.errorCode);
        buffer.write(', ');
        buffer.write(actual.offset);
        buffer.write(', ');
        buffer.write(actual.length);
        if (contextMessages.isNotEmpty) {
          buffer.write(', contextMessages: [');
          for (var i = 0; i < contextMessages.length; i++) {
            var message = contextMessages[i];
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
    var buffer = StringBuffer();
    //
    // Compute the expected number of each type of error.
    //
    var expectedCounts = <ErrorCode, int>{};
    for (var code in expectedErrorCodes) {
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
    var errorsByCode = <ErrorCode, List<AnalysisError>>{};
    for (var error in _errors) {
      errorsByCode
          .putIfAbsent(error.errorCode, () => <AnalysisError>[])
          .add(error);
    }
    //
    // Compare the expected and actual number of each type of error.
    //
    expectedCounts.forEach((ErrorCode code, int expectedCount) {
      int actualCount;
      var list = errorsByCode.remove(code);
      if (list == null) {
        actualCount = 0;
      } else {
        actualCount = list.length;
      }
      if (actualCount != expectedCount) {
        if (buffer.length == 0) {
          buffer.write('Expected ');
        } else {
          buffer.write('; ');
        }
        buffer.write(expectedCount);
        buffer.write(' errors of type ');
        buffer.write(code.uniqueName);
        buffer.write(', found ');
        buffer.write(actualCount);
      }
    });
    //
    // Check that there are no more errors in the actual-errors map,
    // otherwise record message.
    //
    errorsByCode.forEach((ErrorCode code, List<AnalysisError> actualErrors) {
      var actualCount = actualErrors.length;
      if (buffer.length == 0) {
        buffer.write('Expected ');
      } else {
        buffer.write('; ');
      }
      buffer.write('0 errors of type ');
      buffer.write(code.uniqueName);
      buffer.write(', found ');
      buffer.write(actualCount);
      buffer.write(' (');
      for (var i = 0; i < actualErrors.length; i++) {
        var error = actualErrors[i];
        if (i > 0) {
          buffer.write(', ');
        }
        buffer.write(error.offset);
      }
      buffer.write(')');
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
    var expectedErrorCount = 0;
    var expectedWarningCount = 0;
    for (var severity in expectedSeverities) {
      if (severity == ErrorSeverity.ERROR) {
        expectedErrorCount++;
      } else {
        expectedWarningCount++;
      }
    }
    var actualErrorCount = 0;
    var actualWarningCount = 0;
    for (var error in _errors) {
      if (error.errorCode.errorSeverity == ErrorSeverity.ERROR) {
        actualErrorCount++;
      } else {
        actualWarningCount++;
      }
    }
    if (expectedErrorCount != actualErrorCount ||
        expectedWarningCount != actualWarningCount) {
      fail('Expected $expectedErrorCount errors '
          'and $expectedWarningCount warnings, '
          'found $actualErrorCount errors '
          'and $actualWarningCount warnings');
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
    for (var error in _errors) {
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
    _lineInfoMap[source] = LineInfo(lineStarts);
  }
}
