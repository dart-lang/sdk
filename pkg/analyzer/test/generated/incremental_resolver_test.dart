// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.generated.incremental_resolver_test;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/src/context/cache.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/scanner/reader.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/incremental_logger.dart' as logging;
import 'package:analyzer/src/generated/incremental_resolution_validator.dart';
import 'package:analyzer/src/generated/incremental_resolver.dart';
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/generated/testing/ast_test_factory.dart';
import 'package:analyzer/src/generated/testing/element_factory.dart';
import 'package:analyzer/src/generated/utilities_collection.dart';
import 'package:analyzer/src/task/dart.dart';
import 'package:analyzer/task/dart.dart';
import 'package:analyzer/task/model.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'analysis_context_factory.dart';
import 'resolver_test_case.dart';
import 'test_support.dart';

main() {
  initializeTestEnvironment();
  defineReflectiveSuite(() {
    defineReflectiveTests(IncrementalResolverTest);
    defineReflectiveTests(PoorMansIncrementalResolutionTest);
    defineReflectiveTests(ResolutionContextBuilderTest);
  });
}

void initializeTestEnvironment() {}

void _assertEqualError(AnalysisError incError, AnalysisError fullError) {
  if (incError.errorCode != fullError.errorCode ||
      incError.source != fullError.source ||
      incError.offset != fullError.offset ||
      incError.length != fullError.length ||
      incError.message != fullError.message) {
    StringBuffer buffer = new StringBuffer();
    buffer.writeln('Found error does not match expected error:');
    if (incError.errorCode == fullError.errorCode) {
      buffer.write('  errorCode = ');
      buffer.write(fullError.errorCode.uniqueName);
    } else {
      buffer.write('  Expected errorCode = ');
      buffer.write(fullError.errorCode.uniqueName);
      buffer.write(' found ');
      buffer.write(incError.errorCode.uniqueName);
    }
    buffer.writeln();
    if (incError.source == fullError.source) {
      buffer.write('  source = ');
      buffer.write(fullError.source);
    } else {
      buffer.write('  Expected source = ');
      buffer.write(fullError.source);
      buffer.write(' found ');
      buffer.write(incError.source);
    }
    buffer.writeln();
    if (incError.offset == fullError.offset) {
      buffer.write('  offset = ');
      buffer.write(fullError.offset);
    } else {
      buffer.write('  Expected offset = ');
      buffer.write(fullError.offset);
      buffer.write(' found ');
      buffer.write(incError.offset);
    }
    buffer.writeln();
    if (incError.length == fullError.length) {
      buffer.write('  length = ');
      buffer.write(fullError.length);
    } else {
      buffer.write('  Expected length = ');
      buffer.write(fullError.length);
      buffer.write(' found ');
      buffer.write(incError.length);
    }
    buffer.writeln();
    if (incError.message == fullError.message) {
      buffer.write('  message = ');
      buffer.write(fullError.message);
    } else {
      buffer.write('  Expected message = ');
      buffer.write(fullError.message);
      buffer.write(' found ');
      buffer.write(incError.message);
    }
    fail(buffer.toString());
  }
}

void _assertEqualErrors(
    List<AnalysisError> incErrors, List<AnalysisError> fullErrors) {
  expect(incErrors, hasLength(fullErrors.length));
  if (incErrors.isNotEmpty) {
    incErrors.sort((a, b) => a.offset - b.offset);
  }
  if (fullErrors.isNotEmpty) {
    fullErrors.sort((a, b) => a.offset - b.offset);
  }
  int length = incErrors.length;
  for (int i = 0; i < length; i++) {
    AnalysisError incError = incErrors[i];
    AnalysisError fullError = fullErrors[i];
    _assertEqualError(incError, fullError);
  }
}

void _checkCacheEntries(AnalysisCache cache) {
  Set seen = new Set();
  MapIterator<AnalysisTarget, CacheEntry> it = cache.iterator();
  while (it.moveNext()) {
    AnalysisTarget key = it.key;
    if (cache.get(key) == null) {
      fail("cache corrupted: value of $key changed to null");
    }
    if (!seen.add(key)) {
      fail("cache corrupted: $key appears more than once");
    }
  }
}

@reflectiveTest
class IncrementalResolverTest extends ResolverTestCase {
  Source source;
  String code;
  LibraryElement library;
  CompilationUnit unit;

  void setUp() {
    super.setUp();
    logging.logger = logging.NULL_LOGGER;
  }

  void test_classMemberAccessor_body() {
    _resolveUnit(r'''
class A {
  int get test {
    return 1 + 2;
  }
}''');
    _resolve(_editString('+', '*'), _isFunctionBody);
  }

  void test_computeConstants_offsetChanged() {
    _resolveUnit(r'''
int f() => 0;
main() {
  const x1 = f();
  const x2 = f();
  const x3 = f();
  const x4 = f();
  const x5 = f();
  print(x1 + x2 + x3 + x4 + x5 + 1);
}
''');
    _resolve(_editString('x1', ' x1'), _isFunctionBody);
  }

  void test_constructor_body() {
    _resolveUnit(r'''
class A {
  int f;
  A(int a, int b) {
    f = a + b;
  }
}''');
    _resolve(_editString('+', '*'), _isFunctionBody);
  }

  void test_constructor_label_add() {
    _resolveUnit(r'''
class A {
  A() {
    return 42;
  }
}
''');
    _resolve(_editString('return', 'label: return'), _isBlock);
  }

  void test_constructor_localVariable_add() {
    _resolveUnit(r'''
class A {
  A() {
    42;
  }
}
''');
    _resolve(_editString('42;', 'var res = 42;'), _isBlock);
  }

  void test_function_localFunction_add() {
    _resolveUnit(r'''
int main() {
  return 0;
}
callIt(f) {}
''');
    _resolve(_editString('return 0;', 'callIt((p) {});'), _isBlock);
  }

  void test_functionBody_body() {
    _resolveUnit(r'''
main(int a, int b) {
  return a + b;
}''');
    _resolve(_editString('+', '*'), _isFunctionBody);
  }

  void test_functionBody_statement() {
    _resolveUnit(r'''
main(int a, int b) {
  return a + b;
}''');
    _resolve(_editString('+', '*'), _isStatement);
  }

  void test_method_body() {
    _resolveUnit(r'''
class A {
  m(int a, int b) {
    return a + b;
  }
}''');
    _resolve(_editString('+', '*'), _isFunctionBody);
  }

  void test_method_label_add() {
    _resolveUnit(r'''
class A {
  int m(int a, int b) {
    return a + b;
  }
}
''');
    _resolve(_editString('return', 'label: return'), _isBlock);
  }

  void test_method_localFunction_add() {
    _resolveUnit(r'''
class A {
  int m() {
    return 0;
  }
}
callIt(f) {}
''');
    _resolve(_editString('return 0;', 'callIt((p) {});'), _isBlock);
  }

  void test_method_localVariable_add() {
    _resolveUnit(r'''
class A {
  int m(int a, int b) {
    return a + b;
  }
}
''');
    _resolve(
        _editString(
            '    return a + b;',
            r'''
    int res = a + b;
    return res;
'''),
        _isBlock);
  }

  void test_superInvocation() {
    _resolveUnit(r'''
class A {
  foo(p) {}
}
class B extends A {
  bar() {
    super.foo(1 + 2);
  }
}''');
    _resolve(_editString('+', '*'), _isFunctionBody);
  }

  void test_topLevelAccessor_body() {
    _resolveUnit(r'''
int get test {
  return 1 + 2;
}''');
    _resolve(_editString('+', '*'), _isFunctionBody);
  }

  void test_topLevelFunction_label_add() {
    _resolveUnit(r'''
int main(int a, int b) {
  return a + b;
}
''');
    _resolve(_editString('  return', 'label: return a + b;'), _isBlock);
  }

  void test_topLevelFunction_label_remove() {
    _resolveUnit(r'''
int main(int a, int b) {
  label: return a + b;
}
''');
    _resolve(_editString('label: ', ''), _isBlock);
  }

  void test_topLevelFunction_localVariable_add() {
    _resolveUnit(r'''
int main(int a, int b) {
  return a + b;
}
''');
    _resolve(
        _editString(
            '  return a + b;',
            r'''
  int res = a + b;
  return res;
'''),
        _isBlock);
  }

  void test_topLevelFunction_localVariable_remove() {
    _resolveUnit(r'''
int main(int a, int b) {
  int res = a * b;
  return a + b;
}
''');
    _resolve(_editString('int res = a * b;', ''), _isBlock);
  }

  void test_updateElementOffset() {
    _resolveUnit(r'''
class A {
  int am(String ap) {
    int av = 1;
    return av;
  }
}
main(int a, int b) {
  return a + b;
}
class B {
  int bm(String bp) {
    int bv = 1;
    return bv;
  }
}
''');
    _resolve(_editString('+', ' + '), _isStatement);
  }

  _Edit _editString(String search, String replacement, [int length]) {
    int offset = code.indexOf(search);
    expect(offset, isNot(-1));
    if (length == null) {
      length = search.length;
    }
    return new _Edit(offset, length, replacement);
  }

  /**
   * Applies [edit] to [code], find the [AstNode] specified by [predicate]
   * and incrementally resolves it.
   *
   * Then resolves the new code from scratch and validates that results of
   * the incremental resolution and non-incremental resolutions are the same.
   */
  void _resolve(_Edit edit, Predicate<AstNode> predicate) {
    int offset = edit.offset;
    // parse "newCode"
    String newCode = code.substring(0, offset) +
        edit.replacement +
        code.substring(offset + edit.length);
    CompilationUnit newUnit = _parseUnit(newCode);
    AnalysisCache cache = analysisContext2.analysisCache;
    _checkCacheEntries(cache);

    // replace the node
    AstNode oldNode = _findNodeAt(unit, offset, predicate);
    AstNode newNode = _findNodeAt(newUnit, offset, predicate);
    {
      bool success = NodeReplacer.replace(oldNode, newNode);
      expect(success, isTrue);
    }
    // update tokens
    {
      int delta = edit.replacement.length - edit.length;
      _shiftTokens(unit.beginToken, offset, delta);
      Token oldBeginToken = oldNode.beginToken;
      Token oldEndTokenNext = oldNode.endToken.next;
      oldBeginToken.previous.setNext(newNode.beginToken);
      newNode.endToken.setNext(oldEndTokenNext);
    }
    // do incremental resolution
    int updateOffset = edit.offset;
    int updateEndOld = updateOffset + edit.length;
    int updateOldNew = updateOffset + edit.replacement.length;
    IncrementalResolver resolver;
    LibrarySpecificUnit lsu = new LibrarySpecificUnit(source, source);
    resolver = new IncrementalResolver(cache, cache.get(source), cache.get(lsu),
        unit.element, updateOffset, updateEndOld, updateOldNew);

    BlockFunctionBody body = newNode.getAncestor((n) => n is BlockFunctionBody);
    expect(body, isNotNull);

    resolver.resolve(body);
    _checkCacheEntries(cache);

    List<AnalysisError> newErrors = analysisContext.computeErrors(source);
    // resolve "newCode" from scratch
    CompilationUnit fullNewUnit;
    {
      source = addSource(newCode);
      _runTasks();
      LibraryElement library = resolve2(source);
      fullNewUnit = resolveCompilationUnit(source, library);
    }
    _checkCacheEntries(cache);

    assertSameResolution(unit, fullNewUnit);
    // errors
    List<AnalysisError> newFullErrors =
        analysisContext.getErrors(source).errors;
    _assertEqualErrors(newErrors, newFullErrors);
    // prepare for the next cycle
    code = newCode;
  }

  void _resolveUnit(String code) {
    this.code = code;
    source = addSource(code);
    library = resolve2(source);
    unit = resolveCompilationUnit(source, library);
    _runTasks();
    _checkCacheEntries(analysisContext2.analysisCache);
  }

  void _runTasks() {
    AnalysisResult result = analysisContext.performAnalysisTask();
    while (result.changeNotices != null) {
      result = analysisContext.performAnalysisTask();
    }
  }

  static AstNode _findNodeAt(
      CompilationUnit oldUnit, int offset, Predicate<AstNode> predicate) {
    NodeLocator locator = new NodeLocator(offset);
    AstNode node = locator.searchWithin(oldUnit);
    return node.getAncestor(predicate);
  }

  static bool _isBlock(AstNode node) => node is Block;

  static bool _isFunctionBody(AstNode node) => node is FunctionBody;

  static bool _isStatement(AstNode node) => node is Statement;

  static CompilationUnit _parseUnit(String code) {
    var errorListener = new BooleanErrorListener();
    var reader = new CharSequenceReader(code);
    var scanner = new Scanner(null, reader, errorListener);
    var token = scanner.tokenize();
    var parser = new Parser(null, errorListener);
    return parser.parseCompilationUnit(token);
  }

  static void _shiftTokens(Token token, int afterOffset, int delta) {
    while (true) {
      if (token.offset > afterOffset) {
        token.applyDelta(delta);
      }
      if (token.type == TokenType.EOF) {
        break;
      }
      token = token.next;
    }
  }
}

/**
 * The test for [poorMansIncrementalResolution] function and its integration
 * into [AnalysisContext].
 */
@reflectiveTest
class PoorMansIncrementalResolutionTest extends ResolverTestCase {
  final _TestLogger logger = new _TestLogger();

  Source source;
  String code;
  LibraryElement oldLibrary;
  CompilationUnit oldUnit;
  CompilationUnitElement oldUnitElement;

  void assertSameReferencedNames(
      ReferencedNames incNames, ReferencedNames fullNames) {
    expectEqualSets(Iterable actual, Iterable expected) {
      expect(actual, unorderedEquals(expected));
    }

    expectEqualSets(incNames.names, fullNames.names);
    expectEqualSets(incNames.instantiatedNames, fullNames.instantiatedNames);
    expectEqualSets(incNames.superToSubs.keys, fullNames.superToSubs.keys);
    for (String key in fullNames.superToSubs.keys) {
      expectEqualSets(incNames.superToSubs[key], fullNames.superToSubs[key]);
    }
  }

  @override
  void setUp() {
    super.setUp();
    _resetWithIncremental(true);
  }

  void test_computeConstants() {
    _resolveUnit(r'''
int f() => 0;
main() {
  const x = f();
  print(x + 1);
}
''');
    _updateAndValidate(
        r'''
int f() => 0;
main() {
  const x = f();
  print(x + 2);
}
''',
        expectCachePostConstantsValid: false);
  }

  void test_dartDoc_beforeField() {
    _resolveUnit(r'''
class A {
  /**
   * A field [field] of type [int] in class [A].
   */
  int field;
}
''');
    _updateAndValidate(r'''
class A {
  /**
   * A field [field] of the type [int] in the class [A].
   * Updated, with a reference to the [String] type.
   */
  int field;
}
''');
  }

  void test_dartDoc_beforeTopLevelVariable() {
    _resolveUnit(r'''
/**
 * Variables [V1] and [V2] of type [int].
 */
int V1, V2;
''');
    _updateAndValidate(r'''
/**
 * Variables [V1] and [V2] of type [int].
 * Updated, with a reference to the [String] type.
 */
int V1, V2;
''');
  }

  void test_dartDoc_clumsy_addReference() {
    _resolveUnit(r'''
/**
 * aaa bbbb
 */
main() {
}
''');
    _updateAndValidate(r'''
/**
 * aaa [main] bbbb
 */
main() {
}
''');
  }

  void test_dartDoc_clumsy_removeReference() {
    _resolveUnit(r'''
/**
 * aaa [main] bbbb
 */
main() {
}
''');
    _updateAndValidate(r'''
/**
 * aaa bbbb
 */
main() {
}
''');
  }

  void test_dartDoc_clumsy_updateText_beforeKeywordToken() {
    _resolveUnit(r'''
/**
 * A comment with the [int] type reference.
 */
class A {}
''');
    _updateAndValidate(r'''
/**
 * A comment with the [int] type reference.
 * Plus reference to [A] itself.
 */
class A {}
''');
  }

  void test_dartDoc_clumsy_updateText_insert() {
    _resolveUnit(r'''
/**
 * A function [main] with a parameter [p] of type [int].
 */
main(int p) {
  unresolvedFunctionProblem();
}
/**
 * Other comment with [int] reference.
 */
foo() {}
''');
    _updateAndValidate(r'''
/**
 * A function [main] with a parameter [p] of type [int].
 * Inserted text with [String] reference.
 */
main(int p) {
  unresolvedFunctionProblem();
}
/**
 * Other comment with [int] reference.
 */
foo() {}
''');
  }

  void test_dartDoc_clumsy_updateText_remove() {
    _resolveUnit(r'''
/**
 * A function [main] with a parameter [p] of type [int].
 * Some text with [String] reference to remove.
 */
main(int p) {
}
/**
 * Other comment with [int] reference.
 */
foo() {}
''');
    _updateAndValidate(r'''
/**
 * A function [main] with a parameter [p] of type [int].
 */
main(int p) {
}
/**
 * Other comment with [int] reference.
 */
foo() {}
''');
  }

  void test_dartDoc_elegant_addReference() {
    _resolveUnit(r'''
/// aaa bbb
main() {
  return 1;
}
''');
    _updateAndValidate(r'''
/// aaa [main] bbb
/// ccc [int] ddd
main() {
  return 1;
}
''');
  }

  void test_dartDoc_elegant_removeReference() {
    _resolveUnit(r'''
/// aaa [main] bbb
/// ccc [int] ddd
main() {
  return 1;
}
''');
    _updateAndValidate(r'''
/// aaa bbb
main() {
  return 1;
}
''');
  }

  void test_dartDoc_elegant_updateText_insertToken() {
    _resolveUnit(r'''
/// A
/// [int]
class Test {
}
''');
    _updateAndValidate(r'''
/// A
///
/// [int]
class Test {
}
''');
  }

  void test_dartDoc_elegant_updateText_removeToken() {
    _resolveUnit(r'''
/// A
///
/// [int]
class Test {
}
''');
    _updateAndValidate(r'''
/// A
/// [int]
class Test {
}
''');
  }

  void test_endOfLineComment_add_beforeKeywordToken() {
    _resolveUnit(r'''
main() {
  var v = 42;
}
''');
    _updateAndValidate(r'''
main() {
  // some comment
  var v = 42;
}
''');
  }

  void test_endOfLineComment_add_beforeStringToken() {
    _resolveUnit(r'''
main() {
  print(0);
}
''');
    _updateAndValidate(r'''
main() {
  // some comment
  print(0);
}
''');
  }

  void test_endOfLineComment_edit() {
    _resolveUnit(r'''
main() {
  // some comment
  print(0);
}
''');
    _updateAndValidate(r'''
main() {
  // edited comment text
  print(0);
}
''');
  }

  void test_endOfLineComment_outBody_add() {
    _resolveUnit(r'''
main() {
  Object x;
  x.foo();
}
''');
    _updateAndValidate(
        r'''
// 000
main() {
  Object x;
  x.foo();
}
''',
        expectedSuccess: false);
  }

  void test_endOfLineComment_outBody_remove() {
    _resolveUnit(r'''
// 000
main() {
  Object x;
  x.foo();
}
''');
    _updateAndValidate(
        r'''
main() {
  Object x;
  x.foo();
}
''',
        expectedSuccess: false);
  }

  void test_endOfLineComment_outBody_update() {
    _resolveUnit(r'''
// 000
main() {
  Object x;
  x.foo();
}
''');
    _updateAndValidate(
        r'''
// 10
main() {
  Object x;
  x.foo();
}
''',
        expectedSuccess: false);
  }

  void test_endOfLineComment_remove() {
    _resolveUnit(r'''
main() {
  // some comment
  print(0);
}
''');
    _updateAndValidate(r'''
main() {
  print(0);
}
''');
  }

  void test_endOfLineComment_toDartDoc() {
    _resolveUnit(r'''
class A {
  // text
  main() {
    print(42);
  }
}''');
    _updateAndValidate(
        r'''
class A {
  /// text
  main() {
    print(42);
  }
}''',
        expectedSuccess: false);
  }

  void test_false_constConstructor_initializer() {
    _resolveUnit(r'''
class C {
  final int x;
  const C(this.x);
  const C.foo() : x = 0;
}
main() {
  const {const C(0): 0, const C.foo(): 1};
}
''');
    _updateAndValidate(
        r'''
class C {
  final int x;
  const C(this.x);
  const C.foo() : x = 1;
}
main() {
  const {const C(0): 0, const C.foo(): 1};
}
''',
        expectedSuccess: false);
  }

  void test_false_constructor_initializer_damage() {
    _resolveUnit(r'''
class Problem {
  final Map location;
  final String message;

  Problem(Map json)
      : location = json["location"],
        message = json["message"];
}''');
    _updateAndValidate(
        r'''
class Problem {
  final Map location;
  final String message;

  Problem(Map json)
      : location = json["location],
        message = json["message"];
}''',
        expectedSuccess: false);
  }

  void test_false_constructor_initializer_remove() {
    _resolveUnit(r'''
class Problem {
  final String severity;
  final Map location;
  final String message;

  Problem(Map json)
      : severity = json["severity"],
        location = json["location"],
        message = json["message"];
}''');
    _updateAndValidate(
        r'''
class Problem {
  final String severity;
  final Map location;
  final String message;

  Problem(Map json)
      : severity = json["severity"],
        message = json["message"];
}''',
        expectedSuccess: false);
  }

  void test_false_endOfLineComment_localFunction_inTopLevelVariable() {
    _resolveUnit(r'''
typedef int Binary(one, two, three);

int Global = f((a, b, c) {
  return 0; // Some comment
});
''');
    _updateAndValidate(
        r'''
typedef int Binary(one, two, three);

int Global = f((a, b, c) {
  return 0; // Some  comment
});
''',
        expectedSuccess: false);
  }

  void test_false_expressionBody() {
    _resolveUnit(r'''
class A {
  final f = (() => 1)();
}
''');
    _updateAndValidate(
        r'''
class A {
  final f = (() => 2)();
}
''',
        expectedSuccess: false);
  }

  void test_false_expressionBody2() {
    _resolveUnit(r'''
class A {
  int m() => 10 * 10;
}
''');
    _updateAndValidate(
        r'''
class A {
  int m() => 10 * 100;
}
''',
        expectedSuccess: false);
  }

  void test_false_inBody_addAsync() {
    _resolveUnit(r'''
class C {
  test() {}
}
''');
    _updateAndValidate(
        r'''
class C {
  test() async {}
}
''',
        expectedSuccess: false);
  }

  void test_false_inBody_async_addStar() {
    _resolveUnit(r'''
import 'dart:async';
class C {
  Stream test() async {}
}
''');
    _updateAndValidate(
        r'''
import 'dart:async';
class C {
  Stream test() async* {}
}
''',
        expectedSuccess: false);
  }

  void test_false_inBody_async_removeStar() {
    _resolveUnit(r'''
import 'dart:async';
class C {
  Stream test() async* {}
}
''');
    _updateAndValidate(
        r'''
import 'dart:async';
class C {
  Stream test() async {}
}
''',
        expectedSuccess: false);
  }

  void test_false_inBody_functionExpression() {
    _resolveUnit(r'''
class C extends D {
  static final f = () {
    var x = 0;
  }();
}

class D {}
''');
    _updateAndValidate(
        r'''
class C extends D {
  static final f = () {
    var x = 01;
  }();
}

class D {}
''',
        expectedSuccess: false);
  }

  void test_false_inBody_removeAsync() {
    _resolveUnit(r'''
class C {
  test() async {}
}
''');
    _updateAndValidate(
        r'''
class C {
  test() {}
}
''',
        expectedSuccess: false);
  }

  void test_false_inBody_sync_addStar() {
    _resolveUnit(r'''
class C {
  test() {}
}
''');
    _updateAndValidate(
        r'''
class C {
  test() sync* {}
}
''',
        expectedSuccess: false);
  }

  void test_false_topLevelFunction_name() {
    _resolveUnit(r'''
a() {}
b() {}
''');
    _updateAndValidate(
        r'''
a() {}
bb() {}
''',
        expectedSuccess: false);
  }

  void test_false_unbalancedCurlyBrackets_inNew() {
    _resolveUnit(r'''
class A {
  aaa() {
    if (true) {
      1;
    }
  }

  bbb() {
    print(0123456789);
  }
}''');
    _updateAndValidate(
        r'''
class A {
  aaa() {
      1;
    }
  }

  bbb() {
    print(0123456789);
  }
}''',
        expectedSuccess: false);
  }

  void test_false_unbalancedCurlyBrackets_inOld() {
    _resolveUnit(r'''
class A {
  aaa() {
      1;
    }
  }

  bbb() {
    print(0123456789);
  }
}''');
    _updateAndValidate(
        r'''
class A {
  aaa() {
    if (true) {
      1;
    }
  }

  bbb() {
    print(0123456789);
  }
}''',
        expectedSuccess: false);
  }

  void test_false_wholeConstructor() {
    _resolveUnit(r'''
class A {
  A(int a) {
    print(a);
  }
}
''');
    _updateAndValidate(
        r'''
class A {
  A(int b) {
    print(b);
  }
}
''',
        expectedSuccess: false);
  }

  void test_false_wholeConstructor_addInitializer() {
    _resolveUnit(r'''
class A {
  int field;
  A();
}
''');
    _updateAndValidate(
        r'''
class A {
  int field;
  A() : field = 5;
}
''',
        expectedSuccess: false);
  }

  void test_false_wholeFunction() {
    _resolveUnit(r'''
foo() {}
main(int a) {
  print(a);
}
''');
    _updateAndValidate(
        r'''
foo() {}
main(int b) {
  print(b);
}
''',
        expectedSuccess: false);
  }

  void test_false_wholeMethod() {
    _resolveUnit(r'''
class A {
  main(int a) {
    print(a);
  }
}
''');
    _updateAndValidate(
        r'''
class A {
  main(int b) {
    print(b);
  }
}
''',
        expectedSuccess: false);
  }

  void test_fieldClassField_propagatedType() {
    _resolveUnit(r'''
class A {
  static const A b = const B();
  const A();
}

class B extends A {
  const B();
}

main() {
  print(12);
  A.b;
}
''');
    _updateAndValidate(r'''
class A {
  static const A b = const B();
  const A();
}

class B extends A {
  const B();
}

main() {
  print(123);
  A.b;
}
''');
  }

  void test_hasElementAfter_defaultParameter() {
    _resolveUnit(r'''
main() {
  print(1);
}
otherFunction([p = 0]) {}
''');
    _updateAndValidate(r'''
main() {
  print(2);
}
otherFunction([p = 0]) {}
''');
  }

  void test_inBody_expression() {
    _resolveUnit(r'''
class A {
  m() {
    print(1);
  }
}
''');
    _updateAndValidate(r'''
class A {
  m() {
    print(2 + 3);
  }
}
''');
  }

  void test_inBody_insertStatement() {
    _resolveUnit(r'''
main() {
  print(1);
}
''');
    _updateAndValidate(r'''
main() {
  print(0);
  print(1);
}
''');
  }

  void test_inBody_tokenToNode() {
    _resolveUnit(r'''
main() {
  var v = 42;
  print(v);
}
''');
    _updateAndValidate(r'''
main() {
  int v = 42;
  print(v);
}
''');
  }

  void test_multiple_emptyLine() {
    _resolveUnit(r'''
class A {
  m() {
    return true;
  }
}''');
    for (int i = 0; i < 6; i++) {
      if (i.isEven) {
        _updateAndValidate(
            r'''
class A {
  m() {
    return true;

  }
}''',
            compareWithFull: false);
      } else {
        _updateAndValidate(
            r'''
class A {
  m() {
    return true;
  }
}''',
            compareWithFull: false);
      }
    }
  }

  void test_multiple_expression() {
    _resolveUnit(r'''
main() {
  print(1);
}''');
    for (int i = 0; i < 6; i++) {
      if (i.isEven) {
        _updateAndValidate(
            r'''
main() {
  print(12);
}''',
            compareWithFull: false);
      } else {
        _updateAndValidate(
            r'''
main() {
  print(1);
}''',
            compareWithFull: false);
      }
    }
  }

  void test_strongMode_typeComments_insertWhitespace() {
    _resolveUnit(r'''
import 'dart:async';

void fadeIn(int milliseconds) {
  Future<String> f;
  f.then/*<String>*/((e) {print("hello");});
}
''');
    _updateAndValidate(r'''
import 'dart:async';

void fadeIn(int milliseconds) {
  Future<String> f;
  f.then/*<String>*/((e) {print("hello") ;});
}
''');
  }

  void test_true_emptyLine_betweenClassMembers_insert() {
    _resolveUnit(r'''
class A {
  a() {}
  b() {}
}
''');
    _updateAndValidate(r'''
class A {
  a() {}

  b() {}
}
''');
  }

  void test_true_emptyLine_betweenClassMembers_insert_beforeComment() {
    _resolveUnit(r'''
class A {
  a() {}
  /// BBB
  b() {}
}
''');
    _updateAndValidate(r'''
class A {
  a() {}

  /// BBB
  b() {}
}
''');
  }

  void test_true_emptyLine_betweenClassMembers_remove() {
    _resolveUnit(r'''
class A {
  a() {}

  b() {}
}
''');
    _updateAndValidate(r'''
class A {
  a() {}
  b() {}
}
''');
  }

  void test_true_emptyLine_betweenClassMembers_remove_beforeComment() {
    _resolveUnit(r'''
class A {
  a() {}

  /// BBB
  b() {}
}
''');
    _updateAndValidate(r'''
class A {
  a() {}
  /// BBB
  b() {}
}
''');
  }

  void test_true_emptyLine_betweenUnitMembers_insert() {
    _resolveUnit(r'''
a() {}
b() {}
''');
    _updateAndValidate(r'''
a() {}

b() {}
''');
  }

  void test_true_emptyLine_betweenUnitMembers_insert_beforeComment() {
    _resolveUnit(r'''
a() {}

// BBB
b() {}
''');
    _updateAndValidate(r'''
a() {}


// BBB
b() {}
''');
  }

  void test_true_emptyLine_betweenUnitMembers_remove() {
    _resolveUnit(r'''
a() {
  print(1)
}

b() {
  foo(42);
}
foo(String p) {}
''');
    _updateAndValidate(r'''
a() {
  print(1)
}
b() {
  foo(42);
}
foo(String p) {}
''');
  }

  void test_true_emptyLine_betweenUnitMembers_remove_beforeComment() {
    _resolveUnit(r'''
a() {}

// BBB
b() {}
''');
    _updateAndValidate(r'''
a() {}
// BBB
b() {}
''');
  }

  void test_true_todoHint() {
    _resolveUnit(r'''
main() {
  print(1);
}
foo() {
 // TODO
}
''');
    List<AnalysisError> oldErrors = analysisContext.computeErrors(source);
    _updateAndValidate(r'''
main() {
  print(2);
}
foo() {
 // TODO
}
''');
    List<AnalysisError> newErrors = analysisContext.computeErrors(source);
    _assertEqualErrors(newErrors, oldErrors);
  }

  void test_unusedHint_add_wasUsedOnlyInPart() {
    Source partSource = addNamedSource(
        '/my_unit.dart',
        r'''
part of lib;

f(A a) {
  a._foo();
}
''');
    _resolveUnit(r'''
library lib;
part 'my_unit.dart';
class A {
  _foo() {
    print(1);
  }
}
''');
    _runTasks();
    // perform incremental resolution
    _resetWithIncremental(true);
    analysisContext2.setContents(
        partSource,
        r'''
part of lib;

f(A a) {
//  a._foo();
}
''');
    // no hints right now, because we delay hints computing
    {
      List<AnalysisError> errors = analysisContext.getErrors(source).errors;
      expect(errors, isEmpty);
    }
    // a new hint should be added
    List<AnalysisError> errors = analysisContext.computeErrors(source);
    expect(errors, hasLength(1));
    expect(errors[0].errorCode.type, ErrorType.HINT);
    // the same hint should be reported using a ChangeNotice
    bool noticeFound = false;
    AnalysisResult result = analysisContext2.performAnalysisTask();
    for (ChangeNotice notice in result.changeNotices) {
      if (notice.source == source) {
        expect(notice.errors, contains(errors[0]));
        noticeFound = true;
      }
    }
    expect(noticeFound, isTrue);
  }

  void test_unusedHint_false_stillUsedInPart() {
    addNamedSource(
        '/my_unit.dart',
        r'''
part of lib;

f(A a) {
  a._foo();
}
''');
    _resolveUnit(r'''
library lib;
part 'my_unit.dart';
class A {
  _foo() {
    print(1);
  }
}
''');
    // perform incremental resolution
    _resetWithIncremental(true);
    analysisContext2.setContents(
        source,
        r'''
library lib;
part 'my_unit.dart';
class A {
  _foo() {
    print(12);
  }
}
''');
    // no hints
    List<AnalysisError> errors = analysisContext.getErrors(source).errors;
    expect(errors, isEmpty);
  }

  void test_updateConstantInitializer() {
    _resolveUnit(r'''
main() {
  const v = const [Unknown];
}
''');
    _updateAndValidate(
        r'''
main() {
   const v = const [Unknown];
}
''',
        expectCachePostConstantsValid: false);
  }

  void test_updateErrors_addNew_hint1() {
    _resolveUnit(r'''
int main() {
  return 42;
}
''');
    _updateAndValidate(r'''
int main() {
}
''');
  }

  void test_updateErrors_addNew_hint2() {
    _resolveUnit(r'''
main() {
  int v = 0;
  print(v);
}
''');
    _updateAndValidate(r'''
main() {
  int v = 0;
}
''');
  }

  void test_updateErrors_addNew_parse() {
    _resolveUnit(r'''
main() {
  print(42);
}
''');
    _updateAndValidate(r'''
main() {
  print(42)
}
''');
  }

  void test_updateErrors_addNew_resolve() {
    _resolveUnit(r'''
main() {
  foo();
}
foo() {}
''');
    _updateAndValidate(r'''
main() {
  bar();
}
foo() {}
''');
  }

  void test_updateErrors_addNew_resolve2() {
    _resolveUnit(r'''
// this comment is important to reproduce the problem
main() {
  int vvv = 42;
  print(vvv);
}
''');
    _updateAndValidate(r'''
// this comment is important to reproduce the problem
main() {
  int vvv = 42;
  print(vvv2);
}
''');
  }

  void test_updateErrors_addNew_scan() {
    _resolveUnit(r'''
main() {
  1;
}
''');
    _updateAndValidate(r'''
main() {
  1e;
}
''');
  }

  void test_updateErrors_addNew_verify() {
    _resolveUnit(r'''
main() {
  foo(0);
}
foo(int p) {}
''');
    _updateAndValidate(r'''
main() {
  foo('abc');
}
foo(int p) {}
''');
  }

  void test_updateErrors_invalidVerifyErrors() {
    _resolveUnit(r'''
main() {
  foo('aaa');
}
main2() {
  foo('bbb');
}
foo(int p) {}
''');
    // Complete analysis, e.g. compute VERIFY_ERRORS.
    _runTasks();
    // Invalidate VERIFY_ERRORS.
    AnalysisCache cache = analysisContext2.analysisCache;
    LibrarySpecificUnit target = new LibrarySpecificUnit(source, source);
    CacheEntry cacheEntry = cache.get(target);
    expect(cacheEntry.getValue(VERIFY_ERRORS), hasLength(2));
    cacheEntry.setState(VERIFY_ERRORS, CacheState.INVALID);
    // Perform incremental resolution.
    _resetWithIncremental(true);
    analysisContext2.setContents(
        source,
        r'''
main() {
  foo(0);
}
main2() {
  foo('bbb');
}
foo(int p) {}
''');
    // VERIFY_ERRORS is still invalid.
    expect(cacheEntry.getState(VERIFY_ERRORS), CacheState.INVALID);
    // Continue analysis - run tasks, so recompute VERIFY_ERRORS.
    _runTasks();
    expect(cacheEntry.getState(VERIFY_ERRORS), CacheState.VALID);
    expect(cacheEntry.getValue(VERIFY_ERRORS), hasLength(1));
  }

  void test_updateErrors_removeExisting_hint() {
    _resolveUnit(r'''
int main() {
}
''');
    _updateAndValidate(r'''
int main() {
  return 42;
}
''');
  }

  void test_updateErrors_removeExisting_verify() {
    _resolveUnit(r'''
f1() {
  print(1)
}
f2() {
  print(22)
}
f3() {
  print(333)
}
''');
    _updateAndValidate(r'''
f1() {
  print(1)
}
f2() {
  print(22);
}
f3() {
  print(333)
}
''');
  }

  void test_updateErrors_shiftExisting() {
    _resolveUnit(r'''
f1() {
  print(1)
}
f2() {
  print(2);
}
f3() {
  print(333)
}
''');
    _updateAndValidate(r'''
f1() {
  print(1)
}
f2() {
  print(22);
}
f3() {
  print(333)
}
''');
  }

  void test_updateFunctionToForLoop() {
    _resolveUnit(r'''
class PlayDrag {
  final List<num> times = new List<num>();

  PlayDrag.start() {}

  void update(num pos) {
    fo (int i = times.length - 2; i >= 0; i--) {}
  }
}
''');

    _updateAndValidate(
        r'''
class PlayDrag {
  final List<num> times = new List<num>();

  PlayDrag.start() {}

  void update(num pos) {
    for (int i = times.length - 2; i >= 0; i--) {}
  }
}
''',
        expectLibraryUnchanged: false);
  }

  void test_visibleRange() {
    _resolveUnit(r'''
class Test {
  method1(p1) {
    var v1;
    f1() {}
    return 1;
  }
  method2(p2) {
    var v2;
    f2() {}
    return 2;
  }
  method3(p3) {
    var v3;
    f3() {}
    return 3;
  }
}
''');
    _updateAndValidate(r'''
class Test {
  method1(p1) {
    var v1;
    f1() {}
    return 1;
  }
  method2(p2) {
    var v2;
    f2() {}
    return 2222;
  }
  method3(p3) {
    var v3;
    f3() {}
    return 3;
  }
}
''');
  }

  void test_whitespace_getElementAt() {
    _resolveUnit(r'''
class A {}
class B extends A {}
''');
    {
      ClassElement typeA = oldUnitElement.getType('A');
      expect(oldUnitElement.getElementAt(typeA.nameOffset), typeA);
    }
    {
      ClassElement typeB = oldUnitElement.getType('B');
      expect(oldUnitElement.getElementAt(typeB.nameOffset), typeB);
    }
    _updateAndValidate(r'''
class A {}

class B extends A {}
''');
    // getElementAt() caches results, it should be notified when offset
    // are changed.
    {
      ClassElement typeA = oldUnitElement.getType('A');
      expect(oldUnitElement.getElementAt(typeA.nameOffset), typeA);
    }
    {
      ClassElement typeB = oldUnitElement.getType('B');
      expect(oldUnitElement.getElementAt(typeB.nameOffset), typeB);
    }
  }

  void _assertCacheResults(
      {bool expectLibraryUnchanged: true,
      bool expectCachePostConstantsValid: true}) {
    _assertCacheSourceResult(TOKEN_STREAM);
    _assertCacheSourceResult(SCAN_ERRORS);
    _assertCacheSourceResult(PARSED_UNIT);
    _assertCacheSourceResult(PARSE_ERRORS);
    if (!expectLibraryUnchanged) {
      return;
    }
    _assertCacheSourceResult(LIBRARY_ELEMENT1);
    _assertCacheSourceResult(LIBRARY_ELEMENT2);
    _assertCacheSourceResult(LIBRARY_ELEMENT3);
    _assertCacheSourceResult(LIBRARY_ELEMENT4);
    _assertCacheSourceResult(LIBRARY_ELEMENT5);
    _assertCacheSourceResult(LIBRARY_ELEMENT6);
    _assertCacheSourceResult(LIBRARY_ELEMENT7);
    _assertCacheSourceResult(LIBRARY_ELEMENT8);
    _assertCacheSourceResult(LIBRARY_ELEMENT9);
    if (expectCachePostConstantsValid) {
      _assertCacheSourceResult(LIBRARY_ELEMENT);
    }
    _assertCacheUnitResult(RESOLVED_UNIT1);
    _assertCacheUnitResult(RESOLVED_UNIT2);
    _assertCacheUnitResult(RESOLVED_UNIT3);
    _assertCacheUnitResult(RESOLVED_UNIT4);
    _assertCacheUnitResult(RESOLVED_UNIT5);
    _assertCacheUnitResult(RESOLVED_UNIT6);
    _assertCacheUnitResult(RESOLVED_UNIT7);
    _assertCacheUnitResult(RESOLVED_UNIT8);
    _assertCacheUnitResult(RESOLVED_UNIT9);
    _assertCacheUnitResult(RESOLVED_UNIT10);
    _assertCacheUnitResult(RESOLVED_UNIT11);
    if (expectCachePostConstantsValid) {
      _assertCacheUnitResult(RESOLVED_UNIT12);
      _assertCacheUnitResult(RESOLVED_UNIT);
    }
  }

  /**
   * Assert that the [result] of [source] is not INVALID.
   */
  void _assertCacheSourceResult(ResultDescriptor result) {
    AnalysisCache cache = analysisContext2.analysisCache;
    CacheState state = cache.getState(source, result);
    expect(state, isNot(CacheState.INVALID), reason: result.toString());
  }

  /**
   * Assert that the [result] of the defining unit [source] is not INVALID.
   */
  void _assertCacheUnitResult(ResultDescriptor result) {
    AnalysisCache cache = analysisContext2.analysisCache;
    LibrarySpecificUnit target = new LibrarySpecificUnit(source, source);
    CacheState state = cache.getState(target, result);
    expect(state, isNot(CacheState.INVALID), reason: result.toString());
  }

  void _assertEqualLineInfo(LineInfo incLineInfo, LineInfo fullLineInfo) {
    for (int offset = 0; offset < 1000; offset++) {
      LineInfo_Location incLocation = incLineInfo.getLocation(offset);
      LineInfo_Location fullLocation = fullLineInfo.getLocation(offset);
      if (incLocation.lineNumber != fullLocation.lineNumber ||
          incLocation.columnNumber != fullLocation.columnNumber) {
        fail('At offset $offset ' +
            '(${incLocation.lineNumber}, ${incLocation.columnNumber})' +
            ' != ' +
            '(${fullLocation.lineNumber}, ${fullLocation.columnNumber})');
      }
    }
  }

  /**
   * Reset the analysis context to have the 'incremental' option set to the
   * given value.
   */
  void _resetWithIncremental(bool enable) {
    AnalysisOptionsImpl analysisOptions = new AnalysisOptionsImpl();
    analysisOptions.strongMode = true;
    analysisOptions.incremental = enable;
    analysisOptions.incrementalApi = enable;
    logging.logger = logger;
    analysisContext2.analysisOptions = analysisOptions;
  }

  void _resolveUnit(String code) {
    this.code = code;
    source = addSource(code);
    oldLibrary = resolve2(source);
    oldUnit = resolveCompilationUnit(source, oldLibrary);
    oldUnitElement = oldUnit.element;
  }

  void _runTasks() {
    AnalysisResult result = analysisContext.performAnalysisTask();
    while (result.changeNotices != null) {
      result = analysisContext.performAnalysisTask();
    }
  }

  void _updateAndValidate(String newCode,
      {bool expectedSuccess: true,
      bool expectLibraryUnchanged: true,
      bool expectCachePostConstantsValid: true,
      bool compareWithFull: true,
      bool runTasksBeforeIncremental: true}) {
    // Run any pending tasks tasks.
    if (runTasksBeforeIncremental) {
      _runTasks();
    }
    // Update the source - currently this may cause incremental resolution.
    // Then request the updated resolved unit.
    _resetWithIncremental(true);
    analysisContext2.setContents(source, newCode);
    CompilationUnit newUnit = resolveCompilationUnit(source, oldLibrary);
    logger.expectNoErrors();
    List<AnalysisError> newErrors = analysisContext.computeErrors(source);
    LineInfo newLineInfo = analysisContext.getLineInfo(source);
    ReferencedNames newReferencedNames =
        analysisContext.getResult(source, REFERENCED_NAMES);
    // check for expected failure
    if (!expectedSuccess) {
      expect(newUnit.element, isNot(same(oldUnitElement)));
      return;
    }
    // The cache must still have enough results to make the incremental
    // resolution useful.
    _assertCacheResults(
        expectLibraryUnchanged: expectLibraryUnchanged,
        expectCachePostConstantsValid: expectCachePostConstantsValid);
    // The existing CompilationUnit[Element] should be updated.
    expect(newUnit, same(oldUnit));
    expect(newUnit.element, same(oldUnitElement));
    expect(analysisContext.getResolvedCompilationUnit(source, oldLibrary),
        same(oldUnit));
    // The only expected pending task should return the same resolved
    // "newUnit", so all clients will get it using the usual way.
    AnalysisResult analysisResult = analysisContext.performAnalysisTask();
    ChangeNotice notice = analysisResult.changeNotices[0];
    expect(notice.resolvedDartUnit, same(newUnit));
    // Resolve "newCode" from scratch.
    if (compareWithFull) {
      _resetWithIncremental(false);
      changeSource(source, '');
      changeSource(source, newCode);
      _runTasks();
      LibraryElement library = resolve2(source);
      CompilationUnit fullNewUnit = resolveCompilationUnit(source, library);
      // Validate tokens.
      _assertEqualTokens(newUnit, fullNewUnit);
      // Validate LineInfo
      _assertEqualLineInfo(newLineInfo, analysisContext.getLineInfo(source));
      // Validate referenced names.
      ReferencedNames fullReferencedNames =
          analysisContext.getResult(source, REFERENCED_NAMES);
      assertSameReferencedNames(newReferencedNames, fullReferencedNames);
      // Validate that "incremental" and "full" units have the same resolution.
      try {
        assertSameResolution(newUnit, fullNewUnit, validateTypes: true);
      } on IncrementalResolutionMismatch catch (mismatch) {
        fail(mismatch.message);
      }
      List<AnalysisError> newFullErrors =
          analysisContext.getErrors(source).errors;
      _assertEqualErrors(newErrors, newFullErrors);
    }
    _checkCacheEntries(analysisContext2.analysisCache);
  }

  static void _assertEqualToken(Token incToken, Token fullToken) {
//    print('[${incToken.offset}] |$incToken| vs. [${fullToken.offset}] |$fullToken|');
    expect(incToken.type, fullToken.type);
    expect(incToken.offset, fullToken.offset);
    expect(incToken.length, fullToken.length);
    expect(incToken.lexeme, fullToken.lexeme);
  }

  static void _assertEqualTokens(
      CompilationUnit incUnit, CompilationUnit fullUnit) {
    Token incToken = incUnit.beginToken;
    Token fullToken = fullUnit.beginToken;
    while (incToken.type != TokenType.EOF && fullToken.type != TokenType.EOF) {
      _assertEqualToken(incToken, fullToken);
      // comments
      {
        Token incComment = incToken.precedingComments;
        Token fullComment = fullToken.precedingComments;
        while (true) {
          if (fullComment == null) {
            expect(incComment, isNull);
            break;
          }
          expect(incComment, isNotNull);
          _assertEqualToken(incComment, fullComment);
          incComment = incComment.next;
          fullComment = fullComment.next;
        }
      }
      // next tokens
      incToken = incToken.next;
      fullToken = fullToken.next;
    }
  }
}

@reflectiveTest
class ResolutionContextBuilderTest extends EngineTestCase {
  void test_scopeFor_ClassDeclaration() {
    Scope scope = _scopeFor(_createResolvedClassDeclaration());
    EngineTestCase.assertInstanceOf(
        (obj) => obj is LibraryScope, LibraryScope, scope);
  }

  void test_scopeFor_ClassTypeAlias() {
    Scope scope = _scopeFor(_createResolvedClassTypeAlias());
    EngineTestCase.assertInstanceOf(
        (obj) => obj is LibraryScope, LibraryScope, scope);
  }

  void test_scopeFor_CompilationUnit() {
    Scope scope = _scopeFor(_createResolvedCompilationUnit());
    EngineTestCase.assertInstanceOf(
        (obj) => obj is LibraryScope, LibraryScope, scope);
  }

  void test_scopeFor_ConstructorDeclaration() {
    Scope scope = _scopeFor(_createResolvedConstructorDeclaration());
    EngineTestCase.assertInstanceOf(
        (obj) => obj is ClassScope, ClassScope, scope);
  }

  void test_scopeFor_ConstructorDeclaration_parameters() {
    Scope scope = _scopeFor(_createResolvedConstructorDeclaration().parameters);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is FunctionScope, FunctionScope, scope);
  }

  void test_scopeFor_FunctionDeclaration() {
    Scope scope = _scopeFor(_createResolvedFunctionDeclaration());
    EngineTestCase.assertInstanceOf(
        (obj) => obj is LibraryScope, LibraryScope, scope);
  }

  void test_scopeFor_FunctionDeclaration_parameters() {
    Scope scope = _scopeFor(
        _createResolvedFunctionDeclaration().functionExpression.parameters);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is FunctionScope, FunctionScope, scope);
  }

  void test_scopeFor_FunctionTypeAlias() {
    Scope scope = _scopeFor(_createResolvedFunctionTypeAlias());
    EngineTestCase.assertInstanceOf(
        (obj) => obj is LibraryScope, LibraryScope, scope);
  }

  void test_scopeFor_FunctionTypeAlias_parameters() {
    Scope scope = _scopeFor(_createResolvedFunctionTypeAlias().parameters);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is FunctionTypeScope, FunctionTypeScope, scope);
  }

  void test_scopeFor_MethodDeclaration() {
    Scope scope = _scopeFor(_createResolvedMethodDeclaration());
    EngineTestCase.assertInstanceOf(
        (obj) => obj is ClassScope, ClassScope, scope);
  }

  void test_scopeFor_MethodDeclaration_body() {
    Scope scope = _scopeFor(_createResolvedMethodDeclaration().body);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is FunctionScope, FunctionScope, scope);
  }

  void test_scopeFor_notInCompilationUnit() {
    try {
      _scopeFor(AstTestFactory.identifier3("x"));
      fail("Expected AnalysisException");
    } on AnalysisException {
      // Expected
    }
  }

  void test_scopeFor_null() {
    try {
      _scopeFor(null);
      fail("Expected AnalysisException");
    } on AnalysisException {
      // Expected
    }
  }

  void test_scopeFor_unresolved() {
    try {
      _scopeFor(AstTestFactory.compilationUnit());
      fail("Expected AnalysisException");
    } on AnalysisException {
      // Expected
    }
  }

  ClassDeclaration _createResolvedClassDeclaration() {
    CompilationUnit unit = _createResolvedCompilationUnit();
    String className = "C";
    ClassDeclaration classNode = AstTestFactory.classDeclaration(
        null, className, AstTestFactory.typeParameterList(), null, null, null);
    unit.declarations.add(classNode);
    ClassElement classElement = ElementFactory.classElement2(className);
    classNode.name.staticElement = classElement;
    (unit.element as CompilationUnitElementImpl).types = <ClassElement>[
      classElement
    ];
    return classNode;
  }

  ClassTypeAlias _createResolvedClassTypeAlias() {
    CompilationUnit unit = _createResolvedCompilationUnit();
    String className = "C";
    ClassTypeAlias classNode = AstTestFactory.classTypeAlias(
        className, AstTestFactory.typeParameterList(), null, null, null, null);
    unit.declarations.add(classNode);
    ClassElement classElement = ElementFactory.classElement2(className);
    classNode.name.staticElement = classElement;
    (unit.element as CompilationUnitElementImpl).types = <ClassElement>[
      classElement
    ];
    return classNode;
  }

  CompilationUnit _createResolvedCompilationUnit() {
    CompilationUnit unit = AstTestFactory.compilationUnit();
    LibraryElementImpl library =
        ElementFactory.library(AnalysisContextFactory.contextWithCore(), "lib");
    unit.element = library.definingCompilationUnit;
    return unit;
  }

  ConstructorDeclaration _createResolvedConstructorDeclaration() {
    ClassDeclaration classNode = _createResolvedClassDeclaration();
    String constructorName = "f";
    ConstructorDeclaration constructorNode =
        AstTestFactory.constructorDeclaration(
            AstTestFactory.identifier3(constructorName),
            null,
            AstTestFactory.formalParameterList(),
            null);
    classNode.members.add(constructorNode);
    ConstructorElement constructorElement =
        ElementFactory.constructorElement2(classNode.element, null);
    constructorNode.element = constructorElement;
    (classNode.element as ClassElementImpl).constructors = <ConstructorElement>[
      constructorElement
    ];
    return constructorNode;
  }

  FunctionDeclaration _createResolvedFunctionDeclaration() {
    CompilationUnit unit = _createResolvedCompilationUnit();
    String functionName = "f";
    FunctionDeclaration functionNode = AstTestFactory.functionDeclaration(
        null, null, functionName, AstTestFactory.functionExpression());
    unit.declarations.add(functionNode);
    FunctionElement functionElement =
        ElementFactory.functionElement(functionName);
    functionNode.name.staticElement = functionElement;
    (unit.element as CompilationUnitElementImpl).functions = <FunctionElement>[
      functionElement
    ];
    return functionNode;
  }

  FunctionTypeAlias _createResolvedFunctionTypeAlias() {
    CompilationUnit unit = _createResolvedCompilationUnit();
    FunctionTypeAlias aliasNode = AstTestFactory.typeAlias(
        AstTestFactory.typeName4("A"),
        "F",
        AstTestFactory.typeParameterList(),
        AstTestFactory.formalParameterList());
    unit.declarations.add(aliasNode);
    SimpleIdentifier aliasName = aliasNode.name;
    FunctionTypeAliasElement aliasElement =
        new FunctionTypeAliasElementImpl.forNode(aliasName);
    aliasName.staticElement = aliasElement;
    (unit.element as CompilationUnitElementImpl).typeAliases =
        <FunctionTypeAliasElement>[aliasElement];
    return aliasNode;
  }

  MethodDeclaration _createResolvedMethodDeclaration() {
    ClassDeclaration classNode = _createResolvedClassDeclaration();
    String methodName = "f";
    MethodDeclaration methodNode = AstTestFactory.methodDeclaration(
        null,
        null,
        null,
        null,
        AstTestFactory.identifier3(methodName),
        AstTestFactory.formalParameterList());
    classNode.members.add(methodNode);
    MethodElement methodElement =
        ElementFactory.methodElement(methodName, null);
    methodNode.name.staticElement = methodElement;
    (classNode.element as ClassElementImpl).methods = <MethodElement>[
      methodElement
    ];
    return methodNode;
  }

  Scope _scopeFor(AstNode node) {
    return ResolutionContextBuilder.contextFor(node).scope;
  }
}

class _Edit {
  final int offset;
  final int length;
  final String replacement;
  _Edit(this.offset, this.length, this.replacement);
}

class _TestLogger implements logging.Logger {
  Object lastException;
  Object lastStackTrace;

  @override
  void enter(String name) {}

  @override
  void exit() {}

  void expectNoErrors() {
    if (lastException != null) {
      fail("logged an exception:\n$lastException\n$lastStackTrace\n");
    }
  }

  @override
  void log(Object obj) {}

  @override
  void logException(Object exception, [Object stackTrace]) {
    lastException = exception;
    lastStackTrace = stackTrace;
  }

  @override
  logging.LoggingTimer startTimer() {
    return new logging.LoggingTimer(this);
  }
}
