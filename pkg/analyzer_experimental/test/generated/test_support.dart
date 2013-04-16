// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library engine.test_support;

import 'dart:collection';
import 'dart:uri';
import 'package:analyzer_experimental/src/generated/java_core.dart';
import 'package:analyzer_experimental/src/generated/java_engine.dart';
import 'package:analyzer_experimental/src/generated/java_junit.dart';
import 'package:analyzer_experimental/src/generated/source.dart';
import 'package:analyzer_experimental/src/generated/error.dart';
import 'package:analyzer_experimental/src/generated/scanner.dart';
import 'package:analyzer_experimental/src/generated/element.dart' show InterfaceType, MethodElement, PropertyAccessorElement;
import 'package:analyzer_experimental/src/generated/engine.dart' show AnalysisContext, AnalysisContextImpl;
import 'package:unittest/unittest.dart' as _ut;

/**
 * Instances of the class {@code GatheringErrorListener} implement an error listener that collects
 * all of the errors passed to it for later examination.
 */
class GatheringErrorListener implements AnalysisErrorListener {
  /**
   * The source being parsed.
   */
  String _rawSource;
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
  GatheringErrorListener() : super() {
    _jtd_constructor_347_impl();
  }
  _jtd_constructor_347_impl() {
  }
  /**
   * Initialize a newly created error listener to collect errors.
   */
  GatheringErrorListener.con1(String rawSource2) {
    _jtd_constructor_348_impl(rawSource2);
  }
  _jtd_constructor_348_impl(String rawSource2) {
    this._rawSource = rawSource2;
    this._markedSource = rawSource2;
  }
  /**
   * Assert that the number of errors that have been gathered matches the number of errors that are
   * given and that they have the expected error codes and locations. The order in which the errors
   * were gathered is ignored.
   * @param errorCodes the errors that should have been gathered
   * @throws AssertionFailedError if a different number of errors have been gathered than were
   * expected or if they do not have the same codes and locations
   */
  void assertErrors(List<AnalysisError> expectedErrors) {
    if (_errors.length != expectedErrors.length) {
      fail(expectedErrors);
    }
    List<AnalysisError> remainingErrors = new List<AnalysisError>();
    for (AnalysisError error in expectedErrors) {
      remainingErrors.add(error);
    }
    for (AnalysisError error in _errors) {
      if (!foundAndRemoved(remainingErrors, error)) {
        fail(expectedErrors);
      }
    }
  }
  /**
   * Assert that the number of errors that have been gathered matches the number of errors that are
   * given and that they have the expected error codes. The order in which the errors were gathered
   * is ignored.
   * @param expectedErrorCodes the error codes of the errors that should have been gathered
   * @throws AssertionFailedError if a different number of errors have been gathered than were
   * expected
   */
  void assertErrors2(List<ErrorCode> expectedErrorCodes) {
    JavaStringBuilder builder = new JavaStringBuilder();
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
        builder.append(code);
        builder.append(", found ");
        builder.append(actualCount);
      }
    }
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
      builder.append(code);
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
   * @param expectedSeverities the severities of the errors that should have been gathered
   * @throws AssertionFailedError if a different number of errors have been gathered than were
   * expected
   */
  void assertErrors3(List<ErrorSeverity> expectedSeverities) {
    int expectedErrorCount = 0;
    int expectedWarningCount = 0;
    for (ErrorSeverity severity in expectedSeverities) {
      if (identical(severity, ErrorSeverity.ERROR)) {
        expectedErrorCount++;
      } else {
        expectedWarningCount++;
      }
    }
    int actualErrorCount = 0;
    int actualWarningCount = 0;
    for (AnalysisError error in _errors) {
      if (identical(error.errorCode.errorSeverity, ErrorSeverity.ERROR)) {
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
   * @throws AssertionFailedError if any errors have been gathered
   */
  void assertNoErrors() {
    assertErrors(_NO_ERRORS);
  }
  /**
   * Return the errors that were collected.
   * @return the errors that were collected
   */
  List<AnalysisError> get errors => _errors;
  /**
   * Return the line information associated with the given source, or {@code null} if no line
   * information has been associated with the source.
   * @param source the source with which the line information is associated
   * @return the line information associated with the source
   */
  LineInfo getLineInfo(Source source) => _lineInfoMap[source];
  /**
   * Return {@code true} if an error with the given error code has been gathered.
   * @param errorCode the error code being searched for
   * @return {@code true} if an error with the given error code has been gathered
   */
  bool hasError(ErrorCode errorCode5) {
    for (AnalysisError error in _errors) {
      if (identical(error.errorCode, errorCode5)) {
        return true;
      }
    }
    return false;
  }
  /**
   * Return {@code true} if at least one error has been gathered.
   * @return {@code true} if at least one error has been gathered
   */
  bool hasErrors() => _errors.length > 0;
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
   * @param source the source with which the line information is associated
   * @param lineStarts the line start information to be associated with the source
   */
  void setLineInfo(Source source, List<int> lineStarts) {
    _lineInfoMap[source] = new LineInfo(lineStarts);
  }
  /**
   * Set the line information associated with the given source to the given information.
   * @param source the source with which the line information is associated
   * @param lineInfo the line information to be associated with the source
   */
  void setLineInfo2(Source source, LineInfo lineInfo) {
    _lineInfoMap[source] = lineInfo;
  }
  /**
   * Return {@code true} if the two errors are equivalent.
   * @param firstError the first error being compared
   * @param secondError the second error being compared
   * @return {@code true} if the two errors are equivalent
   */
  bool equals(AnalysisError firstError, AnalysisError secondError) => identical(firstError.errorCode, secondError.errorCode) && firstError.offset == secondError.offset && firstError.length == secondError.length && equals3(firstError.source, secondError.source);
  /**
   * Return {@code true} if the two sources are equivalent.
   * @param firstSource the first source being compared
   * @param secondSource the second source being compared
   * @return {@code true} if the two sources are equivalent
   */
  bool equals3(Source firstSource, Source secondSource) {
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
   * @param errorCodes the errors that should have been gathered
   * @throws AssertionFailedError with
   */
  void fail(List<AnalysisError> expectedErrors) {
    PrintStringWriter writer = new PrintStringWriter();
    writer.print("Expected ");
    writer.print(expectedErrors.length);
    writer.print(" errors:");
    for (AnalysisError error in expectedErrors) {
      Source source16 = error.source;
      LineInfo lineInfo = _lineInfoMap[source16];
      writer.println();
      if (lineInfo == null) {
        int offset10 = error.offset;
        writer.printf("  %s %s (%d..%d)", [source16 == null ? "" : source16.shortName, error.errorCode, offset10, offset10 + error.length]);
      } else {
        LineInfo_Location location = lineInfo.getLocation(error.offset);
        writer.printf("  %s %s (%d, %d/%d)", [source16 == null ? "" : source16.shortName, error.errorCode, location.lineNumber, location.columnNumber, error.length]);
      }
    }
    writer.println();
    writer.print("found ");
    writer.print(_errors.length);
    writer.print(" errors:");
    for (AnalysisError error in _errors) {
      Source source17 = error.source;
      LineInfo lineInfo = _lineInfoMap[source17];
      writer.println();
      if (lineInfo == null) {
        int offset11 = error.offset;
        writer.printf("  %s %s (%d..%d): %s", [source17 == null ? "" : source17.shortName, error.errorCode, offset11, offset11 + error.length, error.message]);
      } else {
        LineInfo_Location location = lineInfo.getLocation(error.offset);
        writer.printf("  %s %s (%d, %d/%d): %s", [source17 == null ? "" : source17.shortName, error.errorCode, location.lineNumber, location.columnNumber, error.length, error.message]);
      }
    }
    JUnitTestCase.fail(writer.toString());
  }
  /**
   * Search through the given list of errors for an error that is equal to the target error. If one
   * is found, remove it from the list and return {@code true}, otherwise return {@code false}without modifying the list.
   * @param errors the errors through which we are searching
   * @param targetError the error being searched for
   * @return {@code true} if the error is found and removed from the list
   */
  bool foundAndRemoved(List<AnalysisError> errors, AnalysisError targetError) {
    for (AnalysisError error in errors) {
      if (equals(error, targetError)) {
        errors.remove(error);
        return true;
      }
    }
    return true;
  }
}
/**
 * The class {@code EngineTestCase} defines utility methods for making assertions.
 */
class EngineTestCase extends JUnitTestCase {
  static int _PRINT_RANGE = 6;
  /**
   * Assert that the tokens in the actual stream of tokens have the same types and lexemes as the
   * tokens in the expected stream of tokens. Note that this does not assert anything about the
   * offsets of the tokens (although the lengths will be equal).
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
   * Assert that the array of actual values contain exactly the same values as those in the array of
   * expected value, with the exception that the order of the elements is not required to be the
   * same.
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
    int diffPos = getDiffPos(expected, actual);
    if (diffPos != -1) {
      int diffAhead = Math.max(0, diffPos - _PRINT_RANGE);
      int diffAfter = Math.min(actual.length, diffPos + _PRINT_RANGE);
      String diffStr = "${actual.substring(diffAhead, diffPos)}^${actual.substring(diffPos, diffAfter)}";
      String message = "Content not as expected: is\n${actual}\nDiffers at pos ${diffPos}: ${diffStr}\nexpected:\n${expected}";
      JUnitTestCase.assertEqualsMsg(message, expected, actual);
    }
  }
  /**
   * Assert that the given list is non-{@code null} and has exactly expected elements.
   * @param list the list being tested
   * @param expectedElements the expected elements
   * @throws AssertionFailedError if the list is {@code null} or does not have the expected elements
   */
  static void assertExactElements(List<Object> list, List<Object> expectedElements) {
    int expectedSize = expectedElements.length;
    if (list == null) {
      JUnitTestCase.fail("Expected list of size ${expectedSize}; found null");
    }
    if (list.length != expectedSize) {
      JUnitTestCase.fail("Expected list of size ${expectedSize}; contained ${list.length} elements");
    }
    for (int i = 0; i < expectedElements.length; i++) {
      Object element = list[i];
      Object expectedElement = expectedElements[i];
      if (!element == expectedElement) {
        JUnitTestCase.fail("Expected ${expectedElement} at [${i}]; found ${element}");
      }
    }
  }
  /**
   * Assert that the given array is non-{@code null} and has exactly expected elements.
   * @param array the array being tested
   * @param expectedElements the expected elements
   * @throws AssertionFailedError if the array is {@code null} or does not have the expected
   * elements
   */
  static void assertExactElements2(List<Object> array, List<Object> expectedElements) {
    int expectedSize = expectedElements.length;
    if (array == null) {
      JUnitTestCase.fail("Expected array of size ${expectedSize}; found null");
    }
    if (array.length != expectedSize) {
      JUnitTestCase.fail("Expected array of size ${expectedSize}; contained ${array.length} elements");
    }
    for (int i = 0; i < expectedElements.length; i++) {
      Object element = array[0];
      Object expectedElement = expectedElements[i];
      if (!element == expectedElement) {
        JUnitTestCase.fail("Expected ${expectedElement} at [${i}]; found ${element}");
      }
    }
  }
  /**
   * Assert that the given list is non-{@code null} and has exactly expected elements.
   * @param set the list being tested
   * @param expectedElements the expected elements
   * @throws AssertionFailedError if the list is {@code null} or does not have the expected elements
   */
  static void assertExactElements3(Set<Object> set, List<Object> expectedElements) {
    int expectedSize = expectedElements.length;
    if (set == null) {
      JUnitTestCase.fail("Expected list of size ${expectedSize}; found null");
    }
    if (set.length != expectedSize) {
      JUnitTestCase.fail("Expected list of size ${expectedSize}; contained ${set.length} elements");
    }
    for (int i = 0; i < expectedElements.length; i++) {
      Object expectedElement = expectedElements[i];
      if (!set.contains(expectedElement)) {
        JUnitTestCase.fail("Expected ${expectedElement} in set${set}");
      }
    }
  }
  /**
   * Assert that the given object is an instance of the expected class.
   * @param expectedClass the class that the object is expected to be an instance of
   * @param object the object being tested
   * @return the object that was being tested
   * @throws Exception if the object is not an instance of the expected class
   */
  static Object assertInstanceOf(Type expectedClass, Object object) {
    if (!isInstanceOf(object, expectedClass)) {
      JUnitTestCase.fail("Expected instance of ${expectedClass.toString()}, found ${(object == null ? "null" : object.runtimeType.toString())}");
    }
    return object as Object;
  }
  /**
   * Assert that the given array is non-{@code null} and has the expected number of elements.
   * @param expectedLength the expected number of elements
   * @param array the array being tested
   * @throws AssertionFailedError if the array is {@code null} or does not have the expected number
   * of elements
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
   * @param expectedToken the token that was expected
   * @param actualToken the token that was found
   * @throws AssertionFailedError if the two tokens are not the same
   */
  static void assertMatches(Token expectedToken, Token actualToken) {
    JUnitTestCase.assertEquals(expectedToken.type, actualToken.type);
    if (expectedToken is KeywordToken) {
      assertInstanceOf(KeywordToken, actualToken);
      JUnitTestCase.assertEquals(((expectedToken as KeywordToken)).keyword, ((actualToken as KeywordToken)).keyword);
    } else if (expectedToken is StringToken) {
      assertInstanceOf(StringToken, actualToken);
      JUnitTestCase.assertEquals(((expectedToken as StringToken)).lexeme, ((actualToken as StringToken)).lexeme);
    }
  }
  /**
   * Assert that the given list is non-{@code null} and has the expected number of elements.
   * @param expectedSize the expected number of elements
   * @param list the list being tested
   * @throws AssertionFailedError if the list is {@code null} or does not have the expected number
   * of elements
   */
  static void assertSize(int expectedSize, List<Object> list) {
    if (list == null) {
      JUnitTestCase.fail("Expected list of size ${expectedSize}; found null");
    } else if (list.length != expectedSize) {
      JUnitTestCase.fail("Expected list of size ${expectedSize}; contained ${list.length} elements");
    }
  }
  /**
   * Assert that the given map is non-{@code null} and has the expected number of elements.
   * @param expectedSize the expected number of elements
   * @param map the map being tested
   * @throws AssertionFailedError if the map is {@code null} or does not have the expected number of
   * elements
   */
  static void assertSize2(int expectedSize, Map<Object, Object> map) {
    if (map == null) {
      JUnitTestCase.fail("Expected map of size ${expectedSize}; found null");
    } else if (map.length != expectedSize) {
      JUnitTestCase.fail("Expected map of size ${expectedSize}; contained ${map.length} elements");
    }
  }
  /**
   * Assert that the given set is non-{@code null} and has the expected number of elements.
   * @param expectedSize the expected number of elements
   * @param set the set being tested
   * @throws AssertionFailedError if the set is {@code null} or does not have the expected number of
   * elements
   */
  static void assertSize3(int expectedSize, Set<Object> set) {
    if (set == null) {
      JUnitTestCase.fail("Expected set of size ${expectedSize}; found null");
    } else if (set.length != expectedSize) {
      JUnitTestCase.fail("Expected set of size ${expectedSize}; contained ${set.length} elements");
    }
  }
  /**
   * Convert the given array of lines into a single source string.
   * @param lines the lines to be merged into a single source string
   * @return the source string composed of the given lines
   */
  static String createSource(List<String> lines) {
    PrintStringWriter writer = new PrintStringWriter();
    for (String line in lines) {
      writer.printlnObject(line);
    }
    return writer.toString();
  }
  /**
   * Calculate the offset where the given strings differ.
   * @param str1 the first String to compare
   * @param str2 the second String to compare
   * @return the offset at which the strings differ (or <code>-1</code> if they do not)
   */
  static int getDiffPos(String str1, String str2) {
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
  AnalysisContextImpl createAnalysisContext() {
    AnalysisContextImpl context = new AnalysisContextImpl();
    context.sourceFactory = new SourceFactory.con2([]);
    return context;
  }
  /**
   * Return the getter in the given type with the given name. Inherited getters are ignored.
   * @param type the type in which the getter is declared
   * @param getterName the name of the getter to be returned
   * @return the property accessor element representing the getter with the given name
   */
  PropertyAccessorElement getGetter(InterfaceType type, String getterName) {
    for (PropertyAccessorElement accessor in type.element.accessors) {
      if (accessor.isGetter() && accessor.name == getterName) {
        return accessor;
      }
    }
    JUnitTestCase.fail("Could not find getter named ${getterName} in ${type.name}");
    return null;
  }
  /**
   * Return the method in the given type with the given name. Inherited methods are ignored.
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
    JUnitTestCase.fail("Could not find method named ${methodName} in ${type.name}");
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
  int get hashCode => 0;
  bool operator ==(Object object) {
    return object is TestSource;
  }
  AnalysisContext get context {
    throw new UnsupportedOperationException();
  }
  void getContents(Source_ContentReceiver receiver) {
    throw new UnsupportedOperationException();
  }
  String get fullName {
    throw new UnsupportedOperationException();
  }
  String get shortName {
    throw new UnsupportedOperationException();
  }
  String get encoding {
    throw new UnsupportedOperationException();
  }
  int get modificationStamp {
    throw new UnsupportedOperationException();
  }
  bool exists() => true;
  bool isInSystemLibrary() {
    throw new UnsupportedOperationException();
  }
  Source resolve(String uri) {
    throw new UnsupportedOperationException();
  }
  Source resolveRelative(Uri uri) {
    throw new UnsupportedOperationException();
  }
}

/**
 * Wrapper around [Function] which should be called with [target] and [arguments].
 */
class MethodTrampoline {
  int parameterCount;
  Function trampoline;
  MethodTrampoline(this.parameterCount, this.trampoline);
  Object invoke(target, List arguments) {
    if (arguments.length != parameterCount) {
      throw new IllegalArgumentException("${arguments.length} != $parameterCount");
    }
    switch (parameterCount) {
      case 0:
        return trampoline(target);
      case 1:
        return trampoline(target, arguments[0]);
      case 2:
        return trampoline(target, arguments[0], arguments[1]);
      case 3:
        return trampoline(target, arguments[0], arguments[1], arguments[2]);
      case 4:
        return trampoline(target, arguments[0], arguments[1], arguments[2], arguments[3]);
      default:
        throw new IllegalArgumentException("Not implemented for > 4 arguments");
    }
  }
}
