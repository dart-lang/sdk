// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:language_server_protocol/protocol_generated.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../utils/test_code_extensions.dart';
import 'server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PrepareCallHierarchyTest);
    defineReflectiveTests(IncomingCallHierarchyTest);
    defineReflectiveTests(OutgoingCallHierarchyTest);
  });
}

@reflectiveTest
class IncomingCallHierarchyTest extends AbstractLspAnalysisServerTest {
  late final Uri otherFileUri;

  /// Calls textDocument/prepareCallHierarchy at the location of `^` in
  /// [maincode.code] and uses the single result to call
  /// `callHierarchy/incomingCalls` and ensures the results match
  /// [expectedResults].
  Future<void> expectResults({
    required TestCode mainCode,
    TestCode? otherCode,
    required List<CallHierarchyIncomingCall> expectedResults,
  }) async {
    await initialize();
    await openFile(mainFileUri, mainCode.code);

    if (otherCode != null) {
      await openFile(otherFileUri, otherCode.code);
    }

    final prepareResult = await prepareCallHierarchy(
      mainFileUri,
      mainCode.position.position,
    );
    final result = await callHierarchyIncoming(prepareResult!.single);

    expect(result!, unorderedEquals(expectedResults));
  }

  @override
  void setUp() {
    super.setUp();
    otherFileUri =
        pathContext.toUri(join(projectFolderPath, 'lib', 'other.dart'));
  }

  Future<void> test_constructor() async {
    final code = TestCode.parse('''
class Foo {
  Fo^o();
}
''');

    final otherCode = TestCode.parse('''
import 'main.dart';

class Bar {
  final foo = Foo();
}
''');

    await expectResults(
      mainCode: code,
      otherCode: otherCode,
      expectedResults: [
        CallHierarchyIncomingCall(
          // Container of the call
          from: CallHierarchyItem(
            name: 'Bar',
            detail: 'other.dart',
            kind: SymbolKind.Class,
            uri: otherFileUri,
            range: rangeOfPattern(
                otherCode, RegExp(r'class Bar \{.*\}', dotAll: true)),
            selectionRange: rangeOfString(otherCode, 'Bar'),
          ),
          // Ranges of calls within this container
          fromRanges: [
            rangeOfString(otherCode, 'Foo'),
          ],
        ),
      ],
    );
  }

  Future<void> test_function() async {
    final code = TestCode.parse('''
String fo^o() {}
''');

    final otherCode = TestCode.parse('''
import 'main.dart';

final x = foo();
''');

    await expectResults(
      mainCode: code,
      otherCode: otherCode,
      expectedResults: [
        CallHierarchyIncomingCall(
          // Container of the call
          from: CallHierarchyItem(
            name: 'other.dart',
            detail: null,
            kind: SymbolKind.File,
            uri: otherFileUri,
            range: entireRange(otherCode.code),
            selectionRange: startOfDocRange,
          ),
          // Ranges of calls within this container
          fromRanges: [
            rangeOfString(otherCode, 'foo'),
          ],
        ),
      ],
    );
  }

  Future<void> test_functionInPattern() async {
    final code = TestCode.parse('''
bool gr^eater(int x, int y) => x > y;
''');

    final otherCode = TestCode.parse('''
import 'main.dart';

void foo() {
  var pair = (1, 2);
  switch (pair) {
    case (int a, int b) when greater(a, b):
    print('First element');
  }
}
''');

    await expectResults(
      mainCode: code,
      otherCode: otherCode,
      expectedResults: [
        CallHierarchyIncomingCall(
          // Container of the call
          from: CallHierarchyItem(
            name: 'foo',
            detail: 'other.dart',
            kind: SymbolKind.Function,
            uri: otherFileUri,
            range: rangeOfPattern(
                otherCode, RegExp(r'void foo\(\) \{.*\}', dotAll: true)),
            selectionRange: rangeOfString(otherCode, 'foo'),
          ),
          // Ranges of calls within this container.
          fromRanges: [
            rangeOfString(otherCode, 'greater'),
          ],
        ),
      ],
    );
  }

  Future<void> test_implicitConstructor() async {
    final code = TestCode.parse('''
import 'other.dart';

void main() {
  final foo = Fo^o();
}
''');

    final otherCode = TestCode.parse('''
class Foo {}
''');

    await expectResults(
      mainCode: code,
      otherCode: otherCode,
      expectedResults: [
        CallHierarchyIncomingCall(
          // Container of the call
          from: CallHierarchyItem(
            name: 'main',
            detail: 'main.dart',
            kind: SymbolKind.Function,
            uri: mainFileUri,
            range: rangeOfPattern(
                code, RegExp(r'void main\(\) \{.*\}', dotAll: true)),
            selectionRange: rangeOfString(code, 'main'),
          ),
          // Ranges of calls within this container
          fromRanges: [
            rangeOfString(code, 'Foo'),
          ],
        ),
      ],
    );
  }

  Future<void> test_method() async {
    final code = TestCode.parse('''
class A {
  String fo^o() {}
}
''');

    final otherCode = TestCode.parse('''
import 'main.dart';

class B {
  String bar() {
    A().foo();
  }
}
''');

    await expectResults(
      mainCode: code,
      otherCode: otherCode,
      expectedResults: [
        CallHierarchyIncomingCall(
          // Container of the call
          from: CallHierarchyItem(
            name: 'bar',
            detail: 'B',
            kind: SymbolKind.Method,
            uri: otherFileUri,
            range: rangeOfPattern(
                otherCode, RegExp(r'String bar\(\) \{.*\  }', dotAll: true)),
            selectionRange: rangeOfString(otherCode, 'bar'),
          ),
          // Ranges of calls within this container
          fromRanges: [
            rangeOfString(otherCode, 'foo'),
          ],
        ),
      ],
    );
  }

  Future<void> test_method_extension() async {
    final code = TestCode.parse('''
extension type E1(int a) {
  void foo^() {}
}
''');

    final otherCode = TestCode.parse('''
import 'main.dart';

extension type E2(E1 a) {
  void g() {
    a.foo();
  }
}
''');

    await expectResults(
      mainCode: code,
      otherCode: otherCode,
      expectedResults: [
        CallHierarchyIncomingCall(
          // Container of the call
          from: CallHierarchyItem(
            name: 'g',
            detail: 'E2',
            kind: SymbolKind.Method,
            uri: otherFileUri,
            range: rangeOfPattern(
                otherCode, RegExp(r'void g\(\) \{.*\  }', dotAll: true)),
            selectionRange: rangeOfString(otherCode, 'g'),
          ),
          // Ranges of calls within this container
          fromRanges: [
            rangeOfString(otherCode, 'foo'),
          ],
        ),
      ],
    );
  }

  Future<void> test_namedConstructor() async {
    final code = TestCode.parse('''
class Foo {
  Foo.nam^ed();
}
''');

    final otherCode = TestCode.parse('''
import 'main.dart';

class Bar {
  final foo = Foo.named();
}
''');

    await expectResults(
      mainCode: code,
      otherCode: otherCode,
      expectedResults: [
        CallHierarchyIncomingCall(
          // Container of the call
          from: CallHierarchyItem(
            name: 'Bar',
            detail: 'other.dart',
            kind: SymbolKind.Class,
            uri: otherFileUri,
            range: rangeOfPattern(
                otherCode, RegExp(r'class Bar \{.*\}', dotAll: true)),
            selectionRange: rangeOfString(otherCode, 'Bar'),
          ),
          // Ranges of calls within this container
          fromRanges: [
            rangeOfString(otherCode, 'named'),
          ],
        ),
      ],
    );
  }
}

@reflectiveTest
class OutgoingCallHierarchyTest extends AbstractLspAnalysisServerTest {
  late final Uri otherFileUri;

  /// Calls textDocument/prepareCallHierarchy at the location of `^` in
  /// [maincode.code] and uses the single result to call
  /// `callHierarchy/outgoingCalls` and ensures the results match
  /// [expectedResults].
  Future<void> expectResults({
    required TestCode mainCode,
    TestCode? otherCode,
    required List<CallHierarchyOutgoingCall> expectedResults,
  }) async {
    await initialize();
    await openFile(mainFileUri, mainCode.code);

    if (otherCode != null) {
      await openFile(otherFileUri, otherCode.code);
    }

    final prepareResult = await prepareCallHierarchy(
      mainFileUri,
      mainCode.position.position,
    );
    final result = await callHierarchyOutgoing(prepareResult!.single);

    expect(result!, unorderedEquals(expectedResults));
  }

  @override
  void setUp() {
    super.setUp();
    otherFileUri =
        pathContext.toUri(join(projectFolderPath, 'lib', 'other.dart'));
  }

  Future<void> test_constructor() async {
    final code = TestCode.parse('''
import 'other.dart';

class Foo {
  Fo^o() {
    final b = Bar();
  }
}
''');

    final otherCode = TestCode.parse('''
class Bar {
  Bar();
}
''');

    await expectResults(
      mainCode: code,
      otherCode: otherCode,
      expectedResults: [
        CallHierarchyOutgoingCall(
          // Target of the call.
          to: CallHierarchyItem(
            name: 'Bar',
            detail: 'Bar',
            kind: SymbolKind.Constructor,
            uri: otherFileUri,
            range: rangeOfString(otherCode, 'Bar();'),
            selectionRange:
                rangeStartingAtString(otherCode.code, 'Bar();', 'Bar'),
          ),
          // Ranges of the outbound call.
          fromRanges: [
            rangeOfString(code, 'Bar'),
          ],
        ),
      ],
    );
  }

  Future<void> test_function() async {
    final code = TestCode.parse('''
import 'other.dart';

void fo^o() {
  bar();
}
''');

    final otherCode = TestCode.parse('''
void bar() {}
''');

    await expectResults(
      mainCode: code,
      otherCode: otherCode,
      expectedResults: [
        CallHierarchyOutgoingCall(
          // Target of the call.
          to: CallHierarchyItem(
            name: 'bar',
            detail: 'other.dart',
            kind: SymbolKind.Function,
            uri: otherFileUri,
            range: rangeOfString(otherCode, 'void bar() {}'),
            selectionRange: rangeOfString(otherCode, 'bar'),
          ),
          // Ranges of the outbound call.
          fromRanges: [
            rangeOfString(code, 'bar'),
          ],
        ),
      ],
    );
  }

  Future<void> test_functionInPattern() async {
    final code = TestCode.parse('''
import 'other.dart';

void fo^o() {
  var pair = (1, 2);
  switch (pair) {
    case (int a, int b) when greater(a, b):
    break;
  }
}
''');

    final otherCode = TestCode.parse('''
bool greater(int x, int y) => x > y;
''');

    await expectResults(
      mainCode: code,
      otherCode: otherCode,
      expectedResults: [
        CallHierarchyOutgoingCall(
          // Target of the call.
          to: CallHierarchyItem(
            name: 'greater',
            detail: 'other.dart',
            kind: SymbolKind.Function,
            uri: otherFileUri,
            range: rangeOfString(
                otherCode, 'bool greater(int x, int y) => x > y;'),
            selectionRange: rangeOfString(otherCode, 'greater'),
          ),
          // Ranges of the outbound call.
          fromRanges: [
            rangeOfString(code, 'greater'),
          ],
        ),
      ],
    );
  }

  Future<void> test_implicitConstructor() async {
    final code = TestCode.parse('''
import 'other.dart';

class Foo {
  Fo^o() {
    final b = Bar();
  }
}
''');

    final otherCode = TestCode.parse('''
class Bar {}
''');

    await expectResults(
      mainCode: code,
      otherCode: otherCode,
      expectedResults: [
        CallHierarchyOutgoingCall(
          // Target of the call.
          to: CallHierarchyItem(
            name: 'Bar',
            detail: 'Bar',
            kind: SymbolKind.Constructor,
            uri: otherFileUri,
            range: rangeOfString(otherCode, 'class Bar {}'),
            selectionRange: rangeOfString(otherCode, 'Bar'),
          ),
          // Ranges of the outbound call.
          fromRanges: [
            rangeOfString(code, 'Bar'),
          ],
        ),
      ],
    );
  }

  Future<void> test_method() async {
    final code = TestCode.parse('''
import 'other.dart';

class Foo {
  final b = Bar();
  void f^oo() {
    b.bar();
  }
}
''');

    final otherCode = TestCode.parse('''
class Bar {
  void bar() {}
}
''');

    await expectResults(
      mainCode: code,
      otherCode: otherCode,
      expectedResults: [
        CallHierarchyOutgoingCall(
          // Target of the call.
          to: CallHierarchyItem(
            name: 'bar',
            detail: 'Bar',
            kind: SymbolKind.Method,
            uri: otherFileUri,
            range: rangeOfString(otherCode, 'void bar() {}'),
            selectionRange: rangeOfString(otherCode, 'bar'),
          ),
          // Ranges of the outbound call.
          fromRanges: [
            rangeOfString(code, 'bar'),
          ],
        ),
      ],
    );
  }

  Future<void> test_method_extensionType() async {
    final code = TestCode.parse('''
import 'other.dart';

extension type E2(E1 a) {
  void g^() {
    a.foo();
  }
}
''');

    final otherCode = TestCode.parse('''
extension type E1(int a) {
  void foo() {}
}
''');

    await expectResults(
      mainCode: code,
      otherCode: otherCode,
      expectedResults: [
        CallHierarchyOutgoingCall(
          // Target of the call.
          to: CallHierarchyItem(
            name: 'foo',
            detail: 'E1',
            kind: SymbolKind.Method,
            uri: otherFileUri,
            range: rangeOfString(otherCode, 'void foo() {}'),
            selectionRange: rangeOfString(otherCode, 'foo'),
          ),
          // Ranges of the outbound call.
          fromRanges: [
            rangeOfString(code, 'foo'),
          ],
        ),
      ],
    );
  }

  Future<void> test_namedConstructor() async {
    final code = TestCode.parse('''
import 'other.dart';

class Foo {
  Foo.nam^ed() {
    final b = Bar.named();
  }
}
''');

    final otherCode = TestCode.parse('''
class Bar {
  Bar.named();
}
''');

    await expectResults(
      mainCode: code,
      otherCode: otherCode,
      expectedResults: [
        CallHierarchyOutgoingCall(
          // Target of the call.
          to: CallHierarchyItem(
            name: 'Bar.named',
            detail: 'Bar',
            kind: SymbolKind.Constructor,
            uri: otherFileUri,
            range: rangeOfString(otherCode, 'Bar.named();'),
            selectionRange: rangeOfString(otherCode, 'named'),
          ),
          // Ranges of the outbound call.
          fromRanges: [
            rangeStartingAtString(code.code, 'named();', 'named'),
          ],
        ),
      ],
    );
  }
}

@reflectiveTest
class PrepareCallHierarchyTest extends AbstractLspAnalysisServerTest {
  late final Uri otherFileUri;

  /// Calls textDocument/prepareCallHierarchy at the location of `^` in
  /// [contents] and expects a null result.
  Future<void> expectNullResults(String contents) async {
    final code = TestCode.parse(contents);

    await initialize();
    await openFile(mainFileUri, code.code);

    final result = await prepareCallHierarchy(
      mainFileUri,
      code.position.position,
    );
    expect(result, isNull);
  }

  /// Calls textDocument/prepareCallHierarchy at the location of `^` in
  /// [maincode.code] and ensures the results match [expectedResults].
  Future<void> expectResults({
    required TestCode mainCode,
    TestCode? otherCode,
    required CallHierarchyItem expectedResult,
  }) async {
    await initialize();
    await openFile(mainFileUri, mainCode.code);

    if (otherCode != null) {
      await openFile(otherFileUri, otherCode.code);
    }

    final results = await prepareCallHierarchy(
      mainFileUri,
      mainCode.position.position,
    );

    expect(results, isNotNull);
    expect(results!, hasLength(1));
    expect(results.single, expectedResult);
  }

  @override
  void setUp() {
    super.setUp();
    otherFileUri = toUri(join(projectFolderPath, 'lib', 'other.dart'));
  }

  Future<void> test_args() async {
    await expectNullResults('main(int ^a) {}');
  }

  Future<void> test_block() async {
    await expectNullResults('main() {^}');
  }

  Future<void> test_comment() async {
    await expectNullResults('main() {} // this is a ^comment');
  }

  Future<void> test_constructor() async {
    final code = TestCode.parse('''
class Foo {
  [!Fo^o!](String a) {}
}
''');

    await expectResults(
      mainCode: code,
      expectedResult: CallHierarchyItem(
          name: 'Foo',
          detail: 'Foo', // Containing class name
          kind: SymbolKind.Constructor,
          uri: mainFileUri,
          range: rangeOfString(code, 'Foo(String a) {}'),
          selectionRange: code.range.range),
    );
  }

  Future<void> test_constructorCall() async {
    final mainCode = TestCode.parse('''
import 'other.dart';

main() {
  final foo = Fo^o();
}
''');

    final otherCode = TestCode.parse('''
class Foo {
  [!Foo!]();
}
''');

    await expectResults(
        mainCode: mainCode,
        otherCode: otherCode,
        expectedResult: CallHierarchyItem(
            name: 'Foo',
            detail: 'Foo', // Containing class name
            kind: SymbolKind.Constructor,
            uri: otherFileUri,
            range: rangeOfString(otherCode, 'Foo();'),
            selectionRange: otherCode.range.range));
  }

  Future<void> test_function() async {
    final code = TestCode.parse('''
void myFun^ction() {}
''');

    await expectResults(
      mainCode: code,
      expectedResult: CallHierarchyItem(
          name: 'myFunction',
          detail: 'main.dart', // Containing file name
          kind: SymbolKind.Function,
          uri: mainFileUri,
          range: rangeOfString(code, 'void myFunction() {}'),
          selectionRange: rangeOfString(code, 'myFunction')),
    );
  }

  Future<void> test_functionCall() async {
    final code = TestCode.parse('''
import 'other.dart' as f;

main() {
  f.myFun^ction();
}
''');

    final otherCode = TestCode.parse('''
void myFunction() {}
''');

    await expectResults(
      mainCode: code,
      otherCode: otherCode,
      expectedResult: CallHierarchyItem(
          name: 'myFunction',
          detail: 'other.dart', // Containing file name
          kind: SymbolKind.Function,
          uri: otherFileUri,
          range: rangeOfString(otherCode, 'void myFunction() {}'),
          selectionRange: rangeOfString(otherCode, 'myFunction')),
    );
  }

  Future<void> test_implicitConstructorCall() async {
// Even if a constructor is implicit, we might want to be able to get the
// incoming calls, so invoking it here should still return an element
// (the class).
    final code = TestCode.parse('''
import 'other.dart';

main() {
  final foo = Fo^o();
}
''');

    final otherCode = TestCode.parse('''
class Foo {}
''');

    await expectResults(
      mainCode: code,
      otherCode: otherCode,
      expectedResult: CallHierarchyItem(
          name: 'Foo',
          detail: 'Foo', // Containing class name
          kind: SymbolKind.Constructor,
          uri: otherFileUri,
          range: rangeOfString(otherCode, 'class Foo {}'),
          selectionRange: rangeOfString(otherCode, 'Foo')),
    );
  }

  Future<void> test_method() async {
    final code = TestCode.parse('''
class Foo {
  void myMet^hod() {}
}
''');

    await expectResults(
      mainCode: code,
      expectedResult: CallHierarchyItem(
          name: 'myMethod',
          detail: 'Foo', // Containing class name
          kind: SymbolKind.Method,
          uri: mainFileUri,
          range: rangeOfString(code, 'void myMethod() {}'),
          selectionRange: rangeOfString(code, 'myMethod')),
    );
  }

  Future<void> test_methodCall() async {
    final code = TestCode.parse('''
import 'other.dart';

main() {
  Foo().myMet^hod();
}
''');

    final otherCode = TestCode.parse('''
class Foo {
  void myMethod() {}
}
''');

    await expectResults(
      mainCode: code,
      otherCode: otherCode,
      expectedResult: CallHierarchyItem(
          name: 'myMethod',
          detail: 'Foo', // Containing class name
          kind: SymbolKind.Method,
          uri: otherFileUri,
          range: rangeOfString(otherCode, 'void myMethod() {}'),
          selectionRange: rangeOfString(otherCode, 'myMethod')),
    );
  }

  Future<void> test_methodCall_extension() async {
    final code = TestCode.parse('''
import 'other.dart';

void main() {
  E1(1).f^();
}
''');

    final otherCode = TestCode.parse('''
extension type E1(int a) {
  void f() {}
}
''');

    await expectResults(
      mainCode: code,
      otherCode: otherCode,
      expectedResult: CallHierarchyItem(
          name: 'f',
          detail: 'E1',
          kind: SymbolKind.Method,
          uri: otherFileUri,
          range: rangeOfString(otherCode, 'void f() {}'),
          selectionRange: rangeOfString(otherCode, 'f')),
    );
  }

  Future<void> test_namedConstructor() async {
    final code = TestCode.parse('''
class Foo {
  Foo.Ba^r(String a) {}
}
''');

    await expectResults(
      mainCode: code,
      expectedResult: CallHierarchyItem(
          name: 'Foo.Bar',
          detail: 'Foo', // Containing class name
          kind: SymbolKind.Constructor,
          uri: mainFileUri,
          range: rangeOfString(code, 'Foo.Bar(String a) {}'),
          selectionRange: rangeOfString(code, 'Bar')),
    );
  }

  Future<void> test_namedConstructorCall() async {
    final code = TestCode.parse('''
import 'other.dart';

main() {
  final foo = Foo.Ba^r();
}
''');

    final otherCode = TestCode.parse('''
class Foo {
  Foo.Bar();
}
''');

    await expectResults(
      mainCode: code,
      otherCode: otherCode,
      expectedResult: CallHierarchyItem(
          name: 'Foo.Bar',
          detail: 'Foo', // Containing class name
          kind: SymbolKind.Constructor,
          uri: otherFileUri,
          range: rangeOfString(otherCode, 'Foo.Bar();'),
          selectionRange: rangeOfString(otherCode, 'Bar')),
    );
  }

  Future<void> test_whitespace() async {
    await expectNullResults(' ^  main() {}');
  }
}
