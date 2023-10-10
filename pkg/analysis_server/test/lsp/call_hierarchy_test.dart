// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:language_server_protocol/protocol_generated.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

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
  /// [mainContents] and uses the single result to call
  /// `callHierarchy/incomingCalls` and ensures the results match
  /// [expectedResults].
  Future<void> expectResults({
    required String mainContents,
    String? otherContents,
    required List<CallHierarchyIncomingCall> expectedResults,
  }) async {
    await initialize();
    await openFile(mainFileUri, withoutMarkers(mainContents));

    if (otherContents != null) {
      await openFile(otherFileUri, withoutMarkers(otherContents));
    }

    final prepareResult = await prepareCallHierarchy(
      mainFileUri,
      positionFromMarker(mainContents),
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
    final contents = '''
    class Foo {
      Fo^o();
    }
    ''';

    final otherContents = '''
    import 'main.dart';

    class Bar {
      final foo = Foo();
    }
    ''';

    await expectResults(
      mainContents: contents,
      otherContents: otherContents,
      expectedResults: [
        CallHierarchyIncomingCall(
          // Container of the call
          from: CallHierarchyItem(
            name: 'Bar',
            detail: 'other.dart',
            kind: SymbolKind.Class,
            uri: otherFileUri,
            range: rangeOfPattern(
                otherContents, RegExp(r'class Bar \{.*\}', dotAll: true)),
            selectionRange: rangeOfString(otherContents, 'Bar'),
          ),
          // Ranges of calls within this container
          fromRanges: [
            rangeOfString(otherContents, 'Foo'),
          ],
        ),
      ],
    );
  }

  Future<void> test_function() async {
    final contents = '''
    String fo^o() {}
    ''';

    final otherContents = '''
    import 'main.dart';

    final x = foo();
    ''';

    await expectResults(
      mainContents: contents,
      otherContents: otherContents,
      expectedResults: [
        CallHierarchyIncomingCall(
          // Container of the call
          from: CallHierarchyItem(
            name: 'other.dart',
            detail: null,
            kind: SymbolKind.File,
            uri: otherFileUri,
            range: entireRange(otherContents),
            selectionRange: startOfDocRange,
          ),
          // Ranges of calls within this container
          fromRanges: [
            rangeOfString(otherContents, 'foo'),
          ],
        ),
      ],
    );
  }

  Future<void> test_functionInPattern() async {
    final contents = '''
    bool gr^eater(int x, int y) => x > y;
    ''';

    final otherContents = '''
    import 'main.dart';

    void foo() {
      var pair = (1, 2);
      switch (pair) {
        case (int a, int b) when greater(a, b):
        print('First element');
      }
    }
    ''';

    await expectResults(
      mainContents: contents,
      otherContents: otherContents,
      expectedResults: [
        CallHierarchyIncomingCall(
          // Container of the call
          from: CallHierarchyItem(
            name: 'foo',
            detail: 'other.dart',
            kind: SymbolKind.Function,
            uri: otherFileUri,
            range: rangeOfPattern(
                otherContents, RegExp(r'void foo\(\) \{.*\}', dotAll: true)),
            selectionRange: rangeOfString(otherContents, 'foo'),
          ),
          // Ranges of calls within this container.
          fromRanges: [
            rangeOfString(otherContents, 'greater'),
          ],
        ),
      ],
    );
  }

  Future<void> test_implicitConstructor() async {
    final contents = '''
    import 'other.dart';

    void main() {
      final foo = Fo^o();
    }
    ''';

    final otherContents = '''
    class Foo {}
    ''';

    await expectResults(
      mainContents: contents,
      otherContents: otherContents,
      expectedResults: [
        CallHierarchyIncomingCall(
          // Container of the call
          from: CallHierarchyItem(
            name: 'main',
            detail: 'main.dart',
            kind: SymbolKind.Function,
            uri: mainFileUri,
            range: rangeOfPattern(
                contents, RegExp(r'void main\(\) \{.*\}', dotAll: true)),
            selectionRange: rangeOfString(contents, 'main'),
          ),
          // Ranges of calls within this container
          fromRanges: [
            rangeOfString(contents, 'Foo'),
          ],
        ),
      ],
    );
  }

  Future<void> test_method() async {
    final contents = '''
    class A {
      String fo^o() {}
    }
    ''';

    final otherContents = '''
    import 'main.dart';

    class B {
      String bar() {
        A().foo();
      }
    }
    ''';

    await expectResults(
      mainContents: contents,
      otherContents: otherContents,
      expectedResults: [
        CallHierarchyIncomingCall(
          // Container of the call
          from: CallHierarchyItem(
            name: 'bar',
            detail: 'B',
            kind: SymbolKind.Method,
            uri: otherFileUri,
            range: rangeOfPattern(otherContents,
                RegExp(r'String bar\(\) \{.*\      }', dotAll: true)),
            selectionRange: rangeOfString(otherContents, 'bar'),
          ),
          // Ranges of calls within this container
          fromRanges: [
            rangeOfString(otherContents, 'foo'),
          ],
        ),
      ],
    );
  }

  Future<void> test_method_extension() async {
    final contents = '''
extension type E1(int a) {
  void foo^() {}
}
''';

    final otherContents = '''
import 'main.dart';

extension type E2(E1 a) {
  void g() {
    a.foo();
  }
}
''';

    await expectResults(
      mainContents: contents,
      otherContents: otherContents,
      expectedResults: [
        CallHierarchyIncomingCall(
          // Container of the call
          from: CallHierarchyItem(
            name: 'g',
            detail: 'E2',
            kind: SymbolKind.Method,
            uri: otherFileUri,
            range: rangeOfPattern(
                otherContents, RegExp(r'void g\(\) \{.*\  }', dotAll: true)),
            selectionRange: rangeOfString(otherContents, 'g'),
          ),
          // Ranges of calls within this container
          fromRanges: [
            rangeOfString(otherContents, 'foo'),
          ],
        ),
      ],
    );
  }

  Future<void> test_namedConstructor() async {
    final contents = '''
    class Foo {
      Foo.nam^ed();
    }
    ''';

    final otherContents = '''
    import 'main.dart';

    class Bar {
      final foo = Foo.named();
    }
    ''';

    await expectResults(
      mainContents: contents,
      otherContents: otherContents,
      expectedResults: [
        CallHierarchyIncomingCall(
          // Container of the call
          from: CallHierarchyItem(
            name: 'Bar',
            detail: 'other.dart',
            kind: SymbolKind.Class,
            uri: otherFileUri,
            range: rangeOfPattern(
                otherContents, RegExp(r'class Bar \{.*\}', dotAll: true)),
            selectionRange: rangeOfString(otherContents, 'Bar'),
          ),
          // Ranges of calls within this container
          fromRanges: [
            rangeOfString(otherContents, 'named'),
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
  /// [mainContents] and uses the single result to call
  /// `callHierarchy/outgoingCalls` and ensures the results match
  /// [expectedResults].
  Future<void> expectResults({
    required String mainContents,
    String? otherContents,
    required List<CallHierarchyOutgoingCall> expectedResults,
  }) async {
    await initialize();
    await openFile(mainFileUri, withoutMarkers(mainContents));

    if (otherContents != null) {
      await openFile(otherFileUri, withoutMarkers(otherContents));
    }

    final prepareResult = await prepareCallHierarchy(
      mainFileUri,
      positionFromMarker(mainContents),
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
    final contents = '''
    import 'other.dart';

    class Foo {
      Fo^o() {
        final b = Bar();
      }
    }
    ''';

    final otherContents = '''
    class Bar {
      Bar();
    }
    ''';

    await expectResults(
      mainContents: contents,
      otherContents: otherContents,
      expectedResults: [
        CallHierarchyOutgoingCall(
          // Target of the call.
          to: CallHierarchyItem(
            name: 'Bar',
            detail: 'Bar',
            kind: SymbolKind.Constructor,
            uri: otherFileUri,
            range: rangeOfString(otherContents, 'Bar();'),
            selectionRange:
                rangeStartingAtString(otherContents, 'Bar();', 'Bar'),
          ),
          // Ranges of the outbound call.
          fromRanges: [
            rangeOfString(contents, 'Bar'),
          ],
        ),
      ],
    );
  }

  Future<void> test_function() async {
    final contents = '''
    import 'other.dart';

    void fo^o() {
      bar();
    }
    ''';

    final otherContents = '''
    void bar() {}
    ''';

    await expectResults(
      mainContents: contents,
      otherContents: otherContents,
      expectedResults: [
        CallHierarchyOutgoingCall(
          // Target of the call.
          to: CallHierarchyItem(
            name: 'bar',
            detail: 'other.dart',
            kind: SymbolKind.Function,
            uri: otherFileUri,
            range: rangeOfString(otherContents, 'void bar() {}'),
            selectionRange: rangeOfString(otherContents, 'bar'),
          ),
          // Ranges of the outbound call.
          fromRanges: [
            rangeOfString(contents, 'bar'),
          ],
        ),
      ],
    );
  }

  Future<void> test_functionInPattern() async {
    final contents = '''
    import 'other.dart';

    void fo^o() {
      var pair = (1, 2);
      switch (pair) {
        case (int a, int b) when greater(a, b):
        break;
      }
    }
    ''';

    final otherContents = '''
    bool greater(int x, int y) => x > y;
    ''';

    await expectResults(
      mainContents: contents,
      otherContents: otherContents,
      expectedResults: [
        CallHierarchyOutgoingCall(
          // Target of the call.
          to: CallHierarchyItem(
            name: 'greater',
            detail: 'other.dart',
            kind: SymbolKind.Function,
            uri: otherFileUri,
            range: rangeOfString(
                otherContents, 'bool greater(int x, int y) => x > y;'),
            selectionRange: rangeOfString(otherContents, 'greater'),
          ),
          // Ranges of the outbound call.
          fromRanges: [
            rangeOfString(contents, 'greater'),
          ],
        ),
      ],
    );
  }

  Future<void> test_implicitConstructor() async {
    final contents = '''
    import 'other.dart';

    class Foo {
      Fo^o() {
        final b = Bar();
      }
    }
    ''';

    final otherContents = '''
    class Bar {}
    ''';

    await expectResults(
      mainContents: contents,
      otherContents: otherContents,
      expectedResults: [
        CallHierarchyOutgoingCall(
          // Target of the call.
          to: CallHierarchyItem(
            name: 'Bar',
            detail: 'Bar',
            kind: SymbolKind.Constructor,
            uri: otherFileUri,
            range: rangeOfString(otherContents, 'class Bar {}'),
            selectionRange: rangeOfString(otherContents, 'Bar'),
          ),
          // Ranges of the outbound call.
          fromRanges: [
            rangeOfString(contents, 'Bar'),
          ],
        ),
      ],
    );
  }

  Future<void> test_method() async {
    final contents = '''
    import 'other.dart';

    class Foo {
      final b = Bar();
      void f^oo() {
        b.bar();
      }
    }
    ''';

    final otherContents = '''
    class Bar {
      void bar() {}
    }
    ''';

    await expectResults(
      mainContents: contents,
      otherContents: otherContents,
      expectedResults: [
        CallHierarchyOutgoingCall(
          // Target of the call.
          to: CallHierarchyItem(
            name: 'bar',
            detail: 'Bar',
            kind: SymbolKind.Method,
            uri: otherFileUri,
            range: rangeOfString(otherContents, 'void bar() {}'),
            selectionRange: rangeOfString(otherContents, 'bar'),
          ),
          // Ranges of the outbound call.
          fromRanges: [
            rangeOfString(contents, 'bar'),
          ],
        ),
      ],
    );
  }

  Future<void> test_method_extensionType() async {
    final contents = '''
import 'other.dart';

extension type E2(E1 a) {
  void g^() {
    a.foo();
  }
}
''';

    final otherContents = '''
extension type E1(int a) {
  void foo() {}
}
''';

    await expectResults(
      mainContents: contents,
      otherContents: otherContents,
      expectedResults: [
        CallHierarchyOutgoingCall(
          // Target of the call.
          to: CallHierarchyItem(
            name: 'foo',
            detail: 'E1',
            kind: SymbolKind.Method,
            uri: otherFileUri,
            range: rangeOfString(otherContents, 'void foo() {}'),
            selectionRange: rangeOfString(otherContents, 'foo'),
          ),
          // Ranges of the outbound call.
          fromRanges: [
            rangeOfString(contents, 'foo'),
          ],
        ),
      ],
    );
  }

  Future<void> test_namedConstructor() async {
    final contents = '''
    import 'other.dart';

    class Foo {
      Foo.nam^ed() {
        final b = Bar.named();
      }
    }
    ''';

    final otherContents = '''
    class Bar {
      Bar.named();
    }
    ''';

    await expectResults(
      mainContents: contents,
      otherContents: otherContents,
      expectedResults: [
        CallHierarchyOutgoingCall(
          // Target of the call.
          to: CallHierarchyItem(
            name: 'Bar.named',
            detail: 'Bar',
            kind: SymbolKind.Constructor,
            uri: otherFileUri,
            range: rangeOfString(otherContents, 'Bar.named();'),
            selectionRange: rangeOfString(otherContents, 'named'),
          ),
          // Ranges of the outbound call.
          fromRanges: [
            rangeStartingAtString(contents, 'named();', 'named'),
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
  /// [mainContents] and expects a null result.
  Future<void> expectNullResults(String mainContents) async {
    await initialize();
    await openFile(mainFileUri, withoutMarkers(mainContents));
    final result = await prepareCallHierarchy(
      mainFileUri,
      positionFromMarker(mainContents),
    );
    expect(result, isNull);
  }

  /// Calls textDocument/prepareCallHierarchy at the location of `^` in
  /// [mainContents] and ensures the results match [expectedResults].
  Future<void> expectResults({
    required String mainContents,
    String? otherContents,
    required CallHierarchyItem expectedResult,
  }) async {
    await initialize();
    await openFile(mainFileUri, withoutMarkers(mainContents));

    if (otherContents != null) {
      await openFile(otherFileUri, withoutMarkers(otherContents));
    }

    final results = await prepareCallHierarchy(
      mainFileUri,
      positionFromMarker(mainContents),
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
    final contents = '''
    class Foo {
      [[Fo^o]](String a) {}
    }
    ''';

    await expectResults(
      mainContents: contents,
      expectedResult: CallHierarchyItem(
          name: 'Foo',
          detail: 'Foo', // Containing class name
          kind: SymbolKind.Constructor,
          uri: mainFileUri,
          range: rangeOfString(contents, 'Foo(String a) {}'),
          selectionRange: rangeFromMarkers(contents)),
    );
  }

  Future<void> test_constructorCall() async {
    final contents = '''
    import 'other.dart';

    main() {
      final foo = Fo^o();
    }
    ''';

    final otherContents = '''
    class Foo {
      [[Foo]]();
    }
    ''';

    await expectResults(
        mainContents: contents,
        otherContents: otherContents,
        expectedResult: CallHierarchyItem(
            name: 'Foo',
            detail: 'Foo', // Containing class name
            kind: SymbolKind.Constructor,
            uri: otherFileUri,
            range: rangeOfString(otherContents, 'Foo();'),
            selectionRange: rangeFromMarkers(otherContents)));
  }

  Future<void> test_function() async {
    final contents = '''
    void myFun^ction() {}
    ''';

    await expectResults(
      mainContents: contents,
      expectedResult: CallHierarchyItem(
          name: 'myFunction',
          detail: 'main.dart', // Containing file name
          kind: SymbolKind.Function,
          uri: mainFileUri,
          range: rangeOfString(contents, 'void myFunction() {}'),
          selectionRange: rangeOfString(contents, 'myFunction')),
    );
  }

  Future<void> test_functionCall() async {
    final contents = '''
    import 'other.dart' as f;

    main() {
      f.myFun^ction();
    }
    ''';

    final otherContents = '''
    void myFunction() {}
    ''';

    await expectResults(
      mainContents: contents,
      otherContents: otherContents,
      expectedResult: CallHierarchyItem(
          name: 'myFunction',
          detail: 'other.dart', // Containing file name
          kind: SymbolKind.Function,
          uri: otherFileUri,
          range: rangeOfString(otherContents, 'void myFunction() {}'),
          selectionRange: rangeOfString(otherContents, 'myFunction')),
    );
  }

  Future<void> test_implicitConstructorCall() async {
    // Even if a constructor is implicit, we might want to be able to get the
    // incoming calls, so invoking it here should still return an element
    // (the class).
    final contents = '''
    import 'other.dart';

    main() {
      final foo = Fo^o();
    }
    ''';

    final otherContents = '''
    class Foo {}
    ''';

    await expectResults(
      mainContents: contents,
      otherContents: otherContents,
      expectedResult: CallHierarchyItem(
          name: 'Foo',
          detail: 'Foo', // Containing class name
          kind: SymbolKind.Constructor,
          uri: otherFileUri,
          range: rangeOfString(otherContents, 'class Foo {}'),
          selectionRange: rangeOfString(otherContents, 'Foo')),
    );
  }

  Future<void> test_method() async {
    final contents = '''
    class Foo {
      void myMet^hod() {}
    }
    ''';

    await expectResults(
      mainContents: contents,
      expectedResult: CallHierarchyItem(
          name: 'myMethod',
          detail: 'Foo', // Containing class name
          kind: SymbolKind.Method,
          uri: mainFileUri,
          range: rangeOfString(contents, 'void myMethod() {}'),
          selectionRange: rangeOfString(contents, 'myMethod')),
    );
  }

  Future<void> test_methodCall() async {
    final contents = '''
    import 'other.dart';

    main() {
      Foo().myMet^hod();
    }
    ''';

    final otherContents = '''
    class Foo {
      void myMethod() {}
    }
    ''';

    await expectResults(
      mainContents: contents,
      otherContents: otherContents,
      expectedResult: CallHierarchyItem(
          name: 'myMethod',
          detail: 'Foo', // Containing class name
          kind: SymbolKind.Method,
          uri: otherFileUri,
          range: rangeOfString(otherContents, 'void myMethod() {}'),
          selectionRange: rangeOfString(otherContents, 'myMethod')),
    );
  }

  Future<void> test_methodCall_extension() async {
    final contents = '''
import 'other.dart';

void main() {
  E1(1).f^();
}
''';

    final otherContents = '''
extension type E1(int a) {
  void f() {}
}
''';

    await expectResults(
      mainContents: contents,
      otherContents: otherContents,
      expectedResult: CallHierarchyItem(
          name: 'f',
          detail: 'E1',
          kind: SymbolKind.Method,
          uri: otherFileUri,
          range: rangeOfString(otherContents, 'void f() {}'),
          selectionRange: rangeOfString(otherContents, 'f')),
    );
  }

  Future<void> test_namedConstructor() async {
    final contents = '''
    class Foo {
      Foo.Ba^r(String a) {}
    }
    ''';

    await expectResults(
      mainContents: contents,
      expectedResult: CallHierarchyItem(
          name: 'Foo.Bar',
          detail: 'Foo', // Containing class name
          kind: SymbolKind.Constructor,
          uri: mainFileUri,
          range: rangeOfString(contents, 'Foo.Bar(String a) {}'),
          selectionRange: rangeOfString(contents, 'Bar')),
    );
  }

  Future<void> test_namedConstructorCall() async {
    final contents = '''
    import 'other.dart';

    main() {
      final foo = Foo.Ba^r();
    }
    ''';

    final otherContents = '''
    class Foo {
      Foo.Bar();
    }
    ''';

    await expectResults(
      mainContents: contents,
      otherContents: otherContents,
      expectedResult: CallHierarchyItem(
          name: 'Foo.Bar',
          detail: 'Foo', // Containing class name
          kind: SymbolKind.Constructor,
          uri: otherFileUri,
          range: rangeOfString(otherContents, 'Foo.Bar();'),
          selectionRange: rangeOfString(otherContents, 'Bar')),
    );
  }

  Future<void> test_whitespace() async {
    await expectNullResults(' ^  main() {}');
  }
}
