// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library engine.test_support;

import 'dart:collection';

import 'package:analyzer/src/generated/ast.dart' show AstNode, NodeLocator;
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:unittest/unittest.dart';


/**
 * The class `EngineTestCase` defines utility methods for making assertions.
 */
class EngineTestCase {
  void setUp() {}

  void tearDown() {}

  /**
   * Assert that the given collection has the same number of elements as the number of specified
   * names, and that for each specified name, a corresponding element can be found in the given
   * collection with that name.
   *
   * @param elements the elements
   * @param names the names
   */
  void assertNamedElements(List<Element> elements, List<String> names) {
    for (String elemName in names) {
      bool found = false;
      for (Element elem in elements) {
        if (elem.name == elemName) {
          found = true;
          break;
        }
      }
      if (!found) {
        StringBuffer buffer = new StringBuffer();
        buffer.write("Expected element named: ");
        buffer.write(elemName);
        buffer.write("\n  but found: ");
        for (Element elem in elements) {
          buffer.write(elem.name);
          buffer.write(", ");
        }
        fail(buffer.toString());
      }
    }
    expect(elements, hasLength(names.length));
  }

  AnalysisContextImpl createAnalysisContext() {
    AnalysisContextImpl context = new AnalysisContextImpl();
    context.sourceFactory = new SourceFactory([]);
    return context;
  }

  /**
   * Return the getter in the given type with the given name. Inherited getters are ignored.
   *
   * @param type the type in which the getter is declared
   * @param getterName the name of the getter to be returned
   * @return the property accessor element representing the getter with the given name
   */
  PropertyAccessorElement getGetter(InterfaceType type, String getterName) {
    for (PropertyAccessorElement accessor in type.element.accessors) {
      if (accessor.isGetter && accessor.name == getterName) {
        return accessor;
      }
    }
    fail("Could not find getter named $getterName in ${type.displayName}");
    return null;
  }

  /**
   * Return the method in the given type with the given name. Inherited methods are ignored.
   *
   * @param type the type in which the method is declared
   * @param methodName the name of the method to be returned
   * @return the method element representing the method with the given name
   */
  MethodElement getMethod(InterfaceType type, String methodName) {
    for (MethodElement method in type.element.methods) {
      if (method.name == methodName) {
        return method;
      }
    }
    fail("Could not find method named $methodName in ${type.displayName}");
    return null;
  }

  /**
   * Assert that the given object is an instance of the expected class.
   *
   * @param expectedClass the class that the object is expected to be an instance of
   * @param object the object being tested
   * @return the object that was being tested
   * @throws Exception if the object is not an instance of the expected class
   */
  static Object assertInstanceOf(Predicate<Object> predicate,
      Type expectedClass, Object object) {
    if (!predicate(object)) {
      fail("Expected instance of $expectedClass, found ${object == null ? "null" : object.runtimeType}");
    }
    return object;
  }

  /**
   * @return the [AstNode] with requested type at offset of the "prefix".
   */
  static AstNode findNode(AstNode root, String code, String prefix,
      Predicate<AstNode> predicate) {
    int offset = code.indexOf(prefix);
    if (offset == -1) {
      throw new IllegalArgumentException("Not found '$prefix'.");
    }
    AstNode node = new NodeLocator.con1(offset).searchWithin(root);
    return node.getAncestor(predicate);
  }
}

/**
 * Instances of the class `GatheringErrorListener` implement an error listener that collects
 * all of the errors passed to it for later examination.
 */
class GatheringErrorListener implements AnalysisErrorListener {
  /**
   * An empty array of errors used when no errors are expected.
   */
  static List<AnalysisError> _NO_ERRORS = new List<AnalysisError>(0);

  /**
   * The source being parsed.
   */
  final String _rawSource;

  /**
   * The source being parsed after inserting a marker at the beginning and end of the range of the
   * most recent error.
   */
  String _markedSource;

  /**
   * A list containing the errors that were collected.
   */
  List<AnalysisError> _errors = new List<AnalysisError>();

  /**
   * A table mapping sources to the line information for the source.
   */
  HashMap<Source, LineInfo> _lineInfoMap = new HashMap<Source, LineInfo>();

  /**
   * Initialize a newly created error listener to collect errors.
   */
  GatheringErrorListener() : this.con1(null);

  /**
   * Initialize a newly created error listener to collect errors.
   */
  GatheringErrorListener.con1(this._rawSource) {
    this._markedSource = _rawSource;
  }

  /**
   * Return the errors that were collected.
   *
   * @return the errors that were collected
   */
  List<AnalysisError> get errors => _errors;

  /**
   * Return `true` if at least one error has been gathered.
   *
   * @return `true` if at least one error has been gathered
   */
  bool get hasErrors => _errors.length > 0;

  /**
   * Add all of the given errors to this listener.
   *
   * @param the errors to be added
   */
  void addAll(List<AnalysisError> errors) {
    for (AnalysisError error in errors) {
      onError(error);
    }
  }

  /**
   * Add all of the errors recorded by the given listener to this listener.
   *
   * @param listener the listener that has recorded the errors to be added
   */
  void addAll2(RecordingErrorListener listener) {
    addAll(listener.errors);
  }

  /**
   * Assert that the number of errors that have been gathered matches the number of errors that are
   * given and that they have the expected error codes and locations. The order in which the errors
   * were gathered is ignored.
   *
   * @param errorCodes the errors that should have been gathered
   * @throws AssertionFailedError if a different number of errors have been gathered than were
   *           expected or if they do not have the same codes and locations
   */
  void assertErrors(List<AnalysisError> expectedErrors) {
    if (_errors.length != expectedErrors.length) {
      _fail(expectedErrors);
    }
    List<AnalysisError> remainingErrors = new List<AnalysisError>();
    for (AnalysisError error in expectedErrors) {
      remainingErrors.add(error);
    }
    for (AnalysisError error in _errors) {
      if (!_foundAndRemoved(remainingErrors, error)) {
        _fail(expectedErrors);
      }
    }
  }

  /**
   * Assert that the number of errors that have been gathered matches the number of errors that are
   * given and that they have the expected error codes. The order in which the errors were gathered
   * is ignored.
   *
   * @param expectedErrorCodes the error codes of the errors that should have been gathered
   * @throws AssertionFailedError if a different number of errors have been gathered than were
   *           expected
   */
  void assertErrorsWithCodes([List<ErrorCode> expectedErrorCodes = ErrorCode.EMPTY_LIST]) {
    StringBuffer buffer = new StringBuffer();
    //
    // Verify that the expected error codes have a non-empty message.
    //
    for (ErrorCode errorCode in expectedErrorCodes) {
      expect(errorCode.message.isEmpty, isFalse, reason: "Empty error code message");
    }
    //
    // Compute the expected number of each type of error.
    //
    HashMap<ErrorCode, int> expectedCounts = new HashMap<ErrorCode, int>();
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
    HashMap<ErrorCode, List<AnalysisError>> errorsByCode =
        new HashMap<ErrorCode, List<AnalysisError>>();
    for (AnalysisError error in _errors) {
      ErrorCode code = error.errorCode;
      List<AnalysisError> list = errorsByCode[code];
      if (list == null) {
        list = new List<AnalysisError>();
        errorsByCode[code] = list;
      }
      list.add(error);
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

  /**
   * Assert that the number of errors that have been gathered matches the number of severities that
   * are given and that there are the same number of errors and warnings as specified by the
   * argument. The order in which the errors were gathered is ignored.
   *
   * @param expectedSeverities the severities of the errors that should have been gathered
   * @throws AssertionFailedError if a different number of errors have been gathered than were
   *           expected
   */
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
      fail("Expected $expectedErrorCount errors and $expectedWarningCount warnings, found $actualErrorCount errors and $actualWarningCount warnings");
    }
  }

  /**
   * Assert that no errors have been gathered.
   *
   * @throws AssertionFailedError if any errors have been gathered
   */
  void assertNoErrors() {
    assertErrors(_NO_ERRORS);
  }

  /**
   * Return the line information associated with the given source, or `null` if no line
   * information has been associated with the source.
   *
   * @param source the source with which the line information is associated
   * @return the line information associated with the source
   */
  LineInfo getLineInfo(Source source) => _lineInfoMap[source];

  /**
   * Return `true` if an error with the given error code has been gathered.
   *
   * @param errorCode the error code being searched for
   * @return `true` if an error with the given error code has been gathered
   */
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
    if (_rawSource != null) {
      int left = error.offset;
      int right = left + error.length - 1;
      _markedSource =
          "${_rawSource.substring(0, left)}^${_rawSource.substring(left, right)}^${_rawSource.substring(right)}";
    }
    _errors.add(error);
  }

  /**
   * Set the line information associated with the given source to the given information.
   *
   * @param source the source with which the line information is associated
   * @param lineStarts the line start information to be associated with the source
   */
  void setLineInfo(Source source, List<int> lineStarts) {
    _lineInfoMap[source] = new LineInfo(lineStarts);
  }

  /**
   * Return `true` if the two errors are equivalent.
   *
   * @param firstError the first error being compared
   * @param secondError the second error being compared
   * @return `true` if the two errors are equivalent
   */
  bool _equalErrors(AnalysisError firstError, AnalysisError secondError) =>
      identical(firstError.errorCode, secondError.errorCode) &&
          firstError.offset == secondError.offset &&
          firstError.length == secondError.length &&
          _equalSources(firstError.source, secondError.source);

  /**
   * Return `true` if the two sources are equivalent.
   *
   * @param firstSource the first source being compared
   * @param secondSource the second source being compared
   * @return `true` if the two sources are equivalent
   */
  bool _equalSources(Source firstSource, Source secondSource) {
    if (firstSource == null) {
      return secondSource == null;
    } else if (secondSource == null) {
      return false;
    }
    return firstSource == secondSource;
  }

  /**
   * Assert that the number of errors that have been gathered matches the number of errors that are
   * given and that they have the expected error codes. The order in which the errors were gathered
   * is ignored.
   *
   * @param errorCodes the errors that should have been gathered
   * @throws AssertionFailedError with
   */
  void _fail(List<AnalysisError> expectedErrors) {
    StringBuffer buffer = new StringBuffer();
    buffer.write("Expected ");
    buffer.write(expectedErrors.length);
    buffer.write(" errors:");
    for (AnalysisError error in expectedErrors) {
      Source source = error.source;
      LineInfo lineInfo = _lineInfoMap[source];
      buffer.writeln();
      if (lineInfo == null) {
        int offset = error.offset;
        StringUtils.printf(
            buffer,
            "  %s %s (%d..%d)",
            [
                source == null ? "" : source.shortName,
                error.errorCode,
                offset,
                offset + error.length]);
      } else {
        LineInfo_Location location = lineInfo.getLocation(error.offset);
        StringUtils.printf(
            buffer,
            "  %s %s (%d, %d/%d)",
            [
                source == null ? "" : source.shortName,
                error.errorCode,
                location.lineNumber,
                location.columnNumber,
                error.length]);
      }
    }
    buffer.writeln();
    buffer.write("found ");
    buffer.write(_errors.length);
    buffer.write(" errors:");
    for (AnalysisError error in _errors) {
      Source source = error.source;
      LineInfo lineInfo = _lineInfoMap[source];
      buffer.writeln();
      if (lineInfo == null) {
        int offset = error.offset;
        StringUtils.printf(
            buffer,
            "  %s %s (%d..%d): %s",
            [
                source == null ? "" : source.shortName,
                error.errorCode,
                offset,
                offset + error.length,
                error.message]);
      } else {
        LineInfo_Location location = lineInfo.getLocation(error.offset);
        StringUtils.printf(
            buffer,
            "  %s %s (%d, %d/%d): %s",
            [
                source == null ? "" : source.shortName,
                error.errorCode,
                location.lineNumber,
                location.columnNumber,
                error.length,
                error.message]);
      }
    }
    fail(buffer.toString());
  }

  /**
   * Search through the given list of errors for an error that is equal to the target error. If one
   * is found, remove it from the list and return `true`, otherwise return `false`
   * without modifying the list.
   *
   * @param errors the errors through which we are searching
   * @param targetError the error being searched for
   * @return `true` if the error is found and removed from the list
   */
  bool _foundAndRemoved(List<AnalysisError> errors, AnalysisError targetError) {
    for (AnalysisError error in errors) {
      if (_equalErrors(error, targetError)) {
        errors.remove(error);
        return true;
      }
    }
    return false;
  }
}

/**
 * Instances of the class [TestLogger] implement a logger that can be used by
 * tests.
 */
class TestLogger implements Logger {
  /**
   * The number of error messages that were logged.
   */
  int errorCount = 0;

  /**
   * The number of informational messages that were logged.
   */
  int infoCount = 0;

  @override
  void logError(String message, [CaughtException exception]) {
    errorCount++;
  }

  @override
  void logError2(String message, Object exception) {
    errorCount++;
  }

  @override
  void logInformation(String message, [CaughtException exception]) {
    infoCount++;
  }

  @override
  void logInformation2(String message, Object exception) {
    infoCount++;
  }
}


class TestSource implements Source {
  String _name;
  String _contents;
  int modificationStamp = 0;
  bool exists2 = true;

  /**
   * A flag indicating whether an exception should be generated when an attempt
   * is made to access the contents of this source.
   */
  bool generateExceptionOnRead = false;

  /**
   * The number of times that the contents of this source have been requested.
   */
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
  void setContents(String value) {
    modificationStamp = new DateTime.now().millisecondsSinceEpoch;
    _contents = value;
  }
  String get encoding {
    throw new UnsupportedOperationException();
  }
  String get fullName {
    return _name;
  }
  int get hashCode => 0;
  bool get isInSystemLibrary {
    return false;
  }
  String get shortName {
    return _name;
  }
  Uri get uri {
    throw new UnsupportedOperationException();
  }
  UriKind get uriKind {
    throw new UnsupportedOperationException();
  }
  bool operator ==(Object other) {
    if (other is TestSource) {
      return other._name == _name;
    }
    return false;
  }
  bool exists() => exists2;
  void getContentsToReceiver(Source_ContentReceiver receiver) {
    throw new UnsupportedOperationException();
  }
  Source resolve(String uri) {
    throw new UnsupportedOperationException();
  }
  Uri resolveRelativeUri(Uri uri) {
    return new Uri(scheme: 'file', path: _name).resolveUri(uri);
  }
}
