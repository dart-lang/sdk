// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library engine.test_support;

import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer/src/generated/java_junit.dart';
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/scanner.dart';
import 'package:analyzer/src/generated/ast.dart' show AstNode, NodeLocator;
import 'package:analyzer/src/generated/element.dart' show InterfaceType, MethodElement, PropertyAccessorElement;
import 'package:analyzer/src/generated/engine.dart';
import 'package:unittest/unittest.dart' as _ut;

/**
 * Instances of the class `GatheringErrorListener` implement an error listener that collects
 * all of the errors passed to it for later examination.
 */
class GatheringErrorListener implements AnalysisErrorListener {
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
  Map<Source, LineInfo> _lineInfoMap = new Map<Source, LineInfo>();

  /**
   * An empty array of errors used when no errors are expected.
   */
  static List<AnalysisError> _NO_ERRORS = new List<AnalysisError>(0);

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
   * Add all of the errors recorded by the given listener to this listener.
   *
   * @param listener the listener that has recorded the errors to be added
   */
  void addAll(RecordingErrorListener listener) {
    for (AnalysisError error in listener.errors) {
      onError(error);
    }
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
  void assertErrorsWithCodes(List<ErrorCode> expectedErrorCodes) {
    JavaStringBuilder builder = new JavaStringBuilder();
    //
    // Verify that the expected error codes have a non-empty message.
    //
    for (ErrorCode errorCode in expectedErrorCodes) {
      JUnitTestCase.assertFalseMsg("Empty error code message", errorCode.message.isEmpty);
    }
    //
    // Compute the expected number of each type of error.
    //
    Map<ErrorCode, int> expectedCounts = new Map<ErrorCode, int>();
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
    Map<ErrorCode, List<AnalysisError>> errorsByCode = new Map<ErrorCode, List<AnalysisError>>();
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
    for (MapEntry<ErrorCode, int> entry in getMapEntrySet(expectedCounts)) {
      ErrorCode code = entry.getKey();
      int expectedCount = entry.getValue();
      int actualCount;
      List<AnalysisError> list = errorsByCode.remove(code);
      if (list == null) {
        actualCount = 0;
      } else {
        actualCount = list.length;
      }
      if (actualCount != expectedCount) {
        if (builder.length == 0) {
          builder.append("Expected ");
        } else {
          builder.append("; ");
        }
        builder.append(expectedCount);
        builder.append(" errors of type ");
        builder.append("${code.runtimeType.toString()}.${code}");
        builder.append(", found ");
        builder.append(actualCount);
      }
    }
    //
    // Check that there are no more errors in the actual-errors map, otherwise, record message.
    //
    for (MapEntry<ErrorCode, List<AnalysisError>> entry in getMapEntrySet(errorsByCode)) {
      ErrorCode code = entry.getKey();
      List<AnalysisError> actualErrors = entry.getValue();
      int actualCount = actualErrors.length;
      if (builder.length == 0) {
        builder.append("Expected ");
      } else {
        builder.append("; ");
      }
      builder.append("0 errors of type ");
      builder.append("${code.runtimeType.toString()}.${code}");
      builder.append(", found ");
      builder.append(actualCount);
      builder.append(" (");
      for (int i = 0; i < actualErrors.length; i++) {
        AnalysisError error = actualErrors[i];
        if (i > 0) {
          builder.append(", ");
        }
        builder.append(error.offset);
      }
      builder.append(")");
    }
    if (builder.length > 0) {
      JUnitTestCase.fail(builder.toString());
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
    if (expectedErrorCount != actualErrorCount || expectedWarningCount != actualWarningCount) {
      JUnitTestCase.fail("Expected ${expectedErrorCount} errors and ${expectedWarningCount} warnings, found ${actualErrorCount} errors and ${actualWarningCount} warnings");
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
   * Return the errors that were collected.
   *
   * @return the errors that were collected
   */
  List<AnalysisError> get errors => _errors;

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

  /**
   * Return `true` if at least one error has been gathered.
   *
   * @return `true` if at least one error has been gathered
   */
  bool get hasErrors => _errors.length > 0;

  @override
  void onError(AnalysisError error) {
    if (_rawSource != null) {
      int left = error.offset;
      int right = left + error.length - 1;
      _markedSource = "${_rawSource.substring(0, left)}^${_rawSource.substring(left, right)}^${_rawSource.substring(right)}";
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
  bool _equalErrors(AnalysisError firstError, AnalysisError secondError) => identical(firstError.errorCode, secondError.errorCode) && firstError.offset == secondError.offset && firstError.length == secondError.length && _equalSources(firstError.source, secondError.source);

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
    PrintStringWriter writer = new PrintStringWriter();
    writer.print("Expected ");
    writer.print(expectedErrors.length);
    writer.print(" errors:");
    for (AnalysisError error in expectedErrors) {
      Source source = error.source;
      LineInfo lineInfo = _lineInfoMap[source];
      writer.newLine();
      if (lineInfo == null) {
        int offset = error.offset;
        writer.printf("  %s %s (%d..%d)", [
            source == null ? "" : source.shortName,
            error.errorCode,
            offset,
            offset + error.length]);
      } else {
        LineInfo_Location location = lineInfo.getLocation(error.offset);
        writer.printf("  %s %s (%d, %d/%d)", [
            source == null ? "" : source.shortName,
            error.errorCode,
            location.lineNumber,
            location.columnNumber,
            error.length]);
      }
    }
    writer.newLine();
    writer.print("found ");
    writer.print(_errors.length);
    writer.print(" errors:");
    for (AnalysisError error in _errors) {
      Source source = error.source;
      LineInfo lineInfo = _lineInfoMap[source];
      writer.newLine();
      if (lineInfo == null) {
        int offset = error.offset;
        writer.printf("  %s %s (%d..%d): %s", [
            source == null ? "" : source.shortName,
            error.errorCode,
            offset,
            offset + error.length,
            error.message]);
      } else {
        LineInfo_Location location = lineInfo.getLocation(error.offset);
        writer.printf("  %s %s (%d, %d/%d): %s", [
            source == null ? "" : source.shortName,
            error.errorCode,
            location.lineNumber,
            location.columnNumber,
            error.length,
            error.message]);
      }
    }
    JUnitTestCase.fail(writer.toString());
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
 * The class `EngineTestCase` defines utility methods for making assertions.
 */
class EngineTestCase extends JUnitTestCase {
  static int _PRINT_RANGE = 6;

  /**
   * Assert that the tokens in the actual stream of tokens have the same types and lexemes as the
   * tokens in the expected stream of tokens. Note that this does not assert anything about the
   * offsets of the tokens (although the lengths will be equal).
   *
   * @param expectedStream the head of the stream of tokens that were expected
   * @param actualStream the head of the stream of tokens that were actually found
   * @throws AssertionFailedError if the two streams of tokens are not the same
   */
  static void assertAllMatch(Token expectedStream, Token actualStream) {
    Token left = expectedStream;
    Token right = actualStream;
    while (left.type != TokenType.EOF && right.type != TokenType.EOF) {
      assertMatches(left, right);
      left = left.next;
      right = right.next;
    }
  }

  /**
   * Assert that the given collection is non-`null` and has the expected number of elements.
   *
   * @param expectedSize the expected number of elements
   * @param c the collection being tested
   * @throws AssertionFailedError if the list is `null` or does not have the expected number
   *           of elements
   */
  static void assertCollectionSize(int expectedSize, Iterable c) {
    if (c == null) {
      JUnitTestCase.fail("Expected collection of size ${expectedSize}; found null");
    } else if (c.length != expectedSize) {
      JUnitTestCase.fail("Expected collection of size ${expectedSize}; contained ${c.length} elements");
    }
  }

  /**
   * Assert that the given array is non-`null` and contains the expected elements. The
   * elements can appear in any order.
   *
   * @param array the array being tested
   * @param expectedElements the expected elements
   * @throws AssertionFailedError if the array is `null` or does not contain the expected
   *           elements
   */
  static void assertContains(List<Object> array, List<Object> expectedElements) {
    int expectedSize = expectedElements.length;
    if (array == null) {
      JUnitTestCase.fail("Expected array of length ${expectedSize}; found null");
    }
    if (array.length != expectedSize) {
      JUnitTestCase.fail("Expected array of length ${expectedSize}; contained ${array.length} elements");
    }
    List<bool> found = new List<bool>.filled(expectedSize, false);
    for (int i = 0; i < expectedSize; i++) {
      _privateAssertContains(array, found, expectedElements[i]);
    }
  }

  /**
   * Assert that the array of actual values contain exactly the same values as those in the array of
   * expected value, with the exception that the order of the elements is not required to be the
   * same.
   *
   * @param expectedValues the values that are expected to be found
   * @param actualValues the actual values that are being compared against the expected values
   */
  static void assertEqualsIgnoreOrder(List<Object> expectedValues, List<Object> actualValues) {
    JUnitTestCase.assertNotNull(actualValues);
    int expectedLength = expectedValues.length;
    JUnitTestCase.assertEquals(expectedLength, actualValues.length);
    List<bool> found = new List<bool>.filled(expectedLength, false);
    for (int i = 0; i < expectedLength; i++) {
      found[i] = false;
    }
    for (Object actualValue in actualValues) {
      bool wasExpected = false;
      for (int i = 0; i < expectedLength; i++) {
        if (!found[i] && expectedValues[i] == actualValue) {
          found[i] = true;
          wasExpected = true;
          break;
        }
      }
      if (!wasExpected) {
        JUnitTestCase.fail("The actual value ${actualValue} was not expected");
      }
    }
  }

  /**
   * Assert that a given String is equal to an expected value.
   *
   * @param expected the expected String value
   * @param actual the actual String value
   */
  static void assertEqualString(String expected, String actual) {
    if (actual == null || expected == null) {
      if (identical(actual, expected)) {
        return;
      }
      if (actual == null) {
        JUnitTestCase.assertTrueMsg("Content not as expected: is 'null' expected: ${expected}", false);
      } else {
        JUnitTestCase.assertTrueMsg("Content not as expected: expected 'null' is: ${actual}", false);
      }
    }
    int diffPos = _getDiffPos(expected, actual);
    if (diffPos != -1) {
      int diffAhead = Math.max(0, diffPos - _PRINT_RANGE);
      int diffAfter = Math.min(actual.length, diffPos + _PRINT_RANGE);
      String diffStr = "${actual.substring(diffAhead, diffPos)}^${actual.substring(diffPos, diffAfter)}";
      // use detailed message
      String message = "Content not as expected: is\n${actual}\nDiffers at pos ${diffPos}: ${diffStr}\nexpected:\n${expected}";
      JUnitTestCase.assertEqualsMsg(message, expected, actual);
    }
  }

  /**
   * Assert that the given array is non-`null` and has exactly expected elements.
   *
   * @param array the array being tested
   * @param expectedElements the expected elements
   * @throws AssertionFailedError if the array is `null` or does not have the expected
   *           elements
   */
  static void assertExactElementsInArray(List<Object> array, List<Object> expectedElements) {
    int expectedSize = expectedElements.length;
    if (array == null) {
      JUnitTestCase.fail("Expected array of size ${expectedSize}; found null");
    }
    if (array.length != expectedSize) {
      JUnitTestCase.fail("Expected array of size ${expectedSize}; contained ${array.length} elements");
    }
    for (int i = 0; i < expectedSize; i++) {
      Object element = array[i];
      Object expectedElement = expectedElements[i];
      if (element != expectedElement) {
        JUnitTestCase.fail("Expected ${expectedElement} at [${i}]; found ${element}");
      }
    }
  }

  /**
   * Assert that the given list is non-`null` and has exactly expected elements.
   *
   * @param list the list being tested
   * @param expectedElements the expected elements
   * @throws AssertionFailedError if the list is `null` or does not have the expected elements
   */
  static void assertExactElementsInList(List list, List<Object> expectedElements) {
    int expectedSize = expectedElements.length;
    if (list == null) {
      JUnitTestCase.fail("Expected list of size ${expectedSize}; found null");
    }
    if (list.length != expectedSize) {
      JUnitTestCase.fail("Expected list of size ${expectedSize}; contained ${list.length} elements");
    }
    for (int i = 0; i < expectedSize; i++) {
      Object element = list[i];
      Object expectedElement = expectedElements[i];
      if (element != expectedElement) {
        JUnitTestCase.fail("Expected ${expectedElement} at [${i}]; found ${element}");
      }
    }
  }

  /**
   * Assert that the given list is non-`null` and has exactly expected elements.
   *
   * @param set the list being tested
   * @param expectedElements the expected elements
   * @throws AssertionFailedError if the list is `null` or does not have the expected elements
   */
  static void assertExactElementsInSet(Set set, List<Object> expectedElements) {
    int expectedSize = expectedElements.length;
    if (set == null) {
      JUnitTestCase.fail("Expected list of size ${expectedSize}; found null");
    }
    if (set.length != expectedSize) {
      JUnitTestCase.fail("Expected list of size ${expectedSize}; contained ${set.length} elements");
    }
    for (int i = 0; i < expectedSize; i++) {
      Object expectedElement = expectedElements[i];
      if (!set.contains(expectedElement)) {
        JUnitTestCase.fail("Expected ${expectedElement} in set${set}");
      }
    }
  }

  /**
   * Assert that the given object is an instance of the expected class.
   *
   * @param expectedClass the class that the object is expected to be an instance of
   * @param object the object being tested
   * @return the object that was being tested
   * @throws Exception if the object is not an instance of the expected class
   */
  static Object assertInstanceOf(Predicate<Object> predicate, Type expectedClass, Object object) {
    if (!predicate(object)) {
      JUnitTestCase.fail("Expected instance of ${expectedClass.toString()}, found ${(object == null ? "null" : object.runtimeType.toString())}");
    }
    return object;
  }

  /**
   * Assert that the given array is non-`null` and has the expected number of elements.
   *
   * @param expectedLength the expected number of elements
   * @param array the array being tested
   * @throws AssertionFailedError if the array is `null` or does not have the expected number
   *           of elements
   */
  static void assertLength(int expectedLength, List<Object> array) {
    if (array == null) {
      JUnitTestCase.fail("Expected array of length ${expectedLength}; found null");
    } else if (array.length != expectedLength) {
      JUnitTestCase.fail("Expected array of length ${expectedLength}; contained ${array.length} elements");
    }
  }

  /**
   * Assert that the actual token has the same type and lexeme as the expected token. Note that this
   * does not assert anything about the offsets of the tokens (although the lengths will be equal).
   *
   * @param expectedToken the token that was expected
   * @param actualToken the token that was found
   * @throws AssertionFailedError if the two tokens are not the same
   */
  static void assertMatches(Token expectedToken, Token actualToken) {
    JUnitTestCase.assertEquals(expectedToken.type, actualToken.type);
    if (expectedToken is KeywordToken) {
      assertInstanceOf((obj) => obj is KeywordToken, KeywordToken, actualToken);
      JUnitTestCase.assertEquals(expectedToken.keyword, (actualToken as KeywordToken).keyword);
    } else if (expectedToken is StringToken) {
      assertInstanceOf((obj) => obj is StringToken, StringToken, actualToken);
      JUnitTestCase.assertEquals(expectedToken.lexeme, (actualToken as StringToken).lexeme);
    }
  }

  /**
   * Assert that the given list is non-`null` and has the expected number of elements.
   *
   * @param expectedSize the expected number of elements
   * @param list the list being tested
   * @throws AssertionFailedError if the list is `null` or does not have the expected number
   *           of elements
   */
  static void assertSizeOfList(int expectedSize, List list) {
    if (list == null) {
      JUnitTestCase.fail("Expected list of size ${expectedSize}; found null");
    } else if (list.length != expectedSize) {
      JUnitTestCase.fail("Expected list of size ${expectedSize}; contained ${list.length} elements");
    }
  }

  /**
   * Assert that the given map is non-`null` and has the expected number of elements.
   *
   * @param expectedSize the expected number of elements
   * @param map the map being tested
   * @throws AssertionFailedError if the map is `null` or does not have the expected number of
   *           elements
   */
  static void assertSizeOfMap(int expectedSize, Map map) {
    if (map == null) {
      JUnitTestCase.fail("Expected map of size ${expectedSize}; found null");
    } else if (map.length != expectedSize) {
      JUnitTestCase.fail("Expected map of size ${expectedSize}; contained ${map.length} elements");
    }
  }

  /**
   * Assert that the given set is non-`null` and has the expected number of elements.
   *
   * @param expectedSize the expected number of elements
   * @param set the set being tested
   * @throws AssertionFailedError if the set is `null` or does not have the expected number of
   *           elements
   */
  static void assertSizeOfSet(int expectedSize, Set set) {
    if (set == null) {
      JUnitTestCase.fail("Expected set of size ${expectedSize}; found null");
    } else if (set.length != expectedSize) {
      JUnitTestCase.fail("Expected set of size ${expectedSize}; contained ${set.length} elements");
    }
  }

  /**
   * Convert the given array of lines into a single source string.
   *
   * @param lines the lines to be merged into a single source string
   * @return the source string composed of the given lines
   */
  static String createSource(List<String> lines) {
    PrintStringWriter writer = new PrintStringWriter();
    for (String line in lines) {
      writer.println(line);
    }
    return writer.toString();
  }

  /**
   * @return the [AstNode] with requested type at offset of the "prefix".
   */
  static AstNode findNode(AstNode root, String code, String prefix, Predicate<AstNode> predicate) {
    int offset = code.indexOf(prefix);
    if (offset == -1) {
      throw new IllegalArgumentException("Not found '${prefix}'.");
    }
    AstNode node = new NodeLocator.con1(offset).searchWithin(root);
    return node.getAncestor(predicate);
  }

  /**
   * Calculate the offset where the given strings differ.
   *
   * @param str1 the first String to compare
   * @param str2 the second String to compare
   * @return the offset at which the strings differ (or <code>-1</code> if they do not)
   */
  static int _getDiffPos(String str1, String str2) {
    int len1 = Math.min(str1.length, str2.length);
    int diffPos = -1;
    for (int i = 0; i < len1; i++) {
      if (str1.codeUnitAt(i) != str2.codeUnitAt(i)) {
        diffPos = i;
        break;
      }
    }
    if (diffPos == -1 && str1.length != str2.length) {
      diffPos = len1;
    }
    return diffPos;
  }

  static void _privateAssertContains(List<Object> array, List<bool> found, Object element) {
    if (element == null) {
      for (int i = 0; i < array.length; i++) {
        if (!found[i]) {
          if (array[i] == null) {
            found[i] = true;
            return;
          }
        }
      }
      JUnitTestCase.fail("Does not contain null");
    } else {
      for (int i = 0; i < array.length; i++) {
        if (!found[i]) {
          if (element == array[i]) {
            found[i] = true;
            return;
          }
        }
      }
      JUnitTestCase.fail("Does not contain ${element}");
    }
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
    JUnitTestCase.fail("Could not find getter named ${getterName} in ${type.displayName}");
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
    JUnitTestCase.fail("Could not find method named ${methodName} in ${type.displayName}");
    return null;
  }

  static dartSuite() {
    _ut.group('EngineTestCase', () {
    });
  }
}

main() {
}

class TestSource implements Source {
  String _name;
  TestSource([this._name = '/test.dart']);
  int get hashCode => 0;
  bool operator ==(Object object) {
    return object is TestSource;
  }
  AnalysisContext get context {
    throw new UnsupportedOperationException();
  }
  void getContentsToReceiver(Source_ContentReceiver receiver) {
    throw new UnsupportedOperationException();
  }
  String get fullName {
    return _name;
  }
  String get shortName {
    return _name;
  }
  String get encoding {
    throw new UnsupportedOperationException();
  }
  int get modificationStamp {
    throw new UnsupportedOperationException();
  }
  bool exists() => true;
  bool get isInSystemLibrary {
    throw new UnsupportedOperationException();
  }
  Source resolve(String uri) {
    throw new UnsupportedOperationException();
  }
  Source resolveRelative(Uri uri) {
    throw new UnsupportedOperationException();
  }
  UriKind get uriKind {
    throw new UnsupportedOperationException();
  }
  TimestampedData<String> get contents {
    throw new UnsupportedOperationException();
  }
}
