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
    // These tests cover the LSP handler. A complete set of Type Hierarchy tests
    // are in 'test/src/computer/type_hierarchy_computer_test.dart'.
    defineReflectiveTests(PrepareTypeHierarchyTest);
    defineReflectiveTests(TypeHierarchySupertypesTest);
    defineReflectiveTests(TypeHierarchySubtypesTest);
  });
}

abstract class AbstractTypeHierarchyTest extends AbstractLspAnalysisServerTest {
  /// Code being tested in the main file.
  late TestCode code;

  /// Another file for testing cross-file content.
  late final String otherFilePath;
  late final Uri otherFileUri;
  late TestCode otherCode;

  /// The result of the last prepareTypeHierarchy call.
  TypeHierarchyItem? prepareResult;

  late final dartCodeUri =
      pathContext.toUri(convertPath('/sdk/lib/core/core.dart'));

  /// Matches a [TypeHierarchyItem] for [Object].
  Matcher get _isObject => TypeMatcher<TypeHierarchyItem>()
      .having((e) => e.name, 'name', 'Object')
      .having((e) => e.uri, 'uri', dartCodeUri)
      .having((e) => e.kind, 'kind', SymbolKind.Class)
      .having((e) => e.selectionRange, 'selectionRange', _isValidRange)
      .having((e) => e.range, 'range', _isValidRange);

  /// Matches a valid [Position].
  Matcher get _isValidPosition => TypeMatcher<Position>()
      .having((e) => e.line, 'line', greaterThanOrEqualTo(0))
      .having((e) => e.character, 'character', greaterThanOrEqualTo(0));

  /// Matches a [Range] with valid [Position]s.
  Matcher get _isValidRange => TypeMatcher<Range>()
      .having((e) => e.start, 'start', _isValidPosition)
      .having((e) => e.end, 'end', _isValidPosition);

  @override
  void setUp() {
    super.setUp();
    otherFilePath = join(projectFolderPath, 'lib', 'other.dart');
    otherFileUri = pathContext.toUri(otherFilePath);
  }

  /// Matches a [TypeHierarchyItem] with the given values.
  Matcher _isItem(
    String name,
    Uri uri, {
    String? detail,
    required Range selectionRange,
    required Range range,
  }) =>
      TypeMatcher<TypeHierarchyItem>()
          .having((e) => e.name, 'name', name)
          .having((e) => e.uri, 'uri', uri)
          .having((e) => e.kind, 'kind', SymbolKind.Class)
          .having((e) => e.detail, 'detail', detail)
          .having((e) => e.selectionRange, 'selectionRange', selectionRange)
          .having((e) => e.range, 'range', range);

  /// Parses [content] and calls 'textDocument/prepareTypeHierarchy' at the
  /// marked location.
  Future<void> _prepareTypeHierarchy(String content,
      {String? otherContent}) async {
    code = TestCode.parse(content);
    newFile(mainFilePath, code.code);

    if (otherContent != null) {
      otherCode = TestCode.parse(otherContent);
      newFile(otherFilePath, otherCode.code);
    }

    await initialize();
    final result = await prepareTypeHierarchy(
      mainFileUri,
      code.position.position,
    );
    prepareResult = result?.singleOrNull;
  }
}

@reflectiveTest
class PrepareTypeHierarchyTest extends AbstractTypeHierarchyTest {
  Future<void> test_class() async {
    final content = '''
/*[0*/class /*[1*/MyC^lass1/*1]*/ {}/*0]*/
''';
    await _prepareTypeHierarchy(content);
    expect(
      prepareResult,
      _isItem(
        'MyClass1',
        mainFileUri,
        range: code.ranges[0].range,
        selectionRange: code.ranges[1].range,
      ),
    );
  }

  Future<void> test_extensionType() async {
    final content = '''
/*[0*/extension type /*[1*/Int^Ext/*1]*/(int a) {}/*0]*/
''';
    await _prepareTypeHierarchy(content);
    expect(
      prepareResult,
      _isItem(
        'IntExt',
        mainFileUri,
        range: code.ranges[0].range,
        selectionRange: code.ranges[1].range,
      ),
    );
  }

  Future<void> test_nonClass() async {
    final content = '''
int? a^a;
''';
    await _prepareTypeHierarchy(content);
    expect(prepareResult, isNull);
  }

  Future<void> test_whitespace() async {
    final content = '''
int? a;
^
int? b;
''';
    await _prepareTypeHierarchy(content);
    expect(prepareResult, isNull);
  }
}

@reflectiveTest
class TypeHierarchySubtypesTest extends AbstractTypeHierarchyTest {
  List<TypeHierarchyItem>? subtypes;

  Future<void> test_anotherFile() async {
    final content = '''
class MyCl^ass1 {}
''';
    final otherContent = '''
import 'main.dart';

/*[0*/class /*[1*/MyClass2/*1]*/ extends MyClass1 {}/*0]*/
''';
    await _fetchSubtypes(content, otherContent: otherContent);
    expect(
        subtypes,
        equals([
          _isItem(
            'MyClass2',
            otherFileUri,
            range: otherCode.ranges[0].range,
            selectionRange: otherCode.ranges[1].range,
          ),
        ]));
  }

  Future<void> test_extends() async {
    final content = '''
class MyCla^ss1 {}
/*[0*/class /*[1*/MyClass2/*1]*/ extends MyClass1 {}/*0]*/
''';
    await _fetchSubtypes(content);
    expect(
        subtypes,
        equals([
          _isItem(
            'MyClass2',
            mainFileUri,
            range: code.ranges[0].range,
            selectionRange: code.ranges[1].range,
          ),
        ]));
  }

  Future<void> test_implements() async {
    final content = '''
class MyCla^ss1 {}
/*[0*/class /*[1*/MyClass2/*1]*/ implements MyClass1 {}/*0]*/
/*[2*/extension type /*[3*/E1/*3]*/(MyClass1 a) implements MyClass1 {}/*2]*/

''';
    await _fetchSubtypes(content);
    expect(
        subtypes,
        equals([
          _isItem(
            'MyClass2',
            mainFileUri,
            range: code.ranges[0].range,
            selectionRange: code.ranges[1].range,
          ),
          _isItem(
            'E1',
            mainFileUri,
            range: code.ranges[2].range,
            selectionRange: code.ranges[3].range,
          ),
        ]));
  }

  Future<void> test_implements_extensionType() async {
    final content = '''
class A {}
extension type E^1(A a) {}
/*[0*/extension type /*[1*/E2/*1]*/(A a) implements E1 {}/*0]*/
''';
    await _fetchSubtypes(content);
    expect(
        subtypes,
        equals([
          _isItem(
            'E2',
            mainFileUri,
            range: code.ranges[0].range,
            selectionRange: code.ranges[1].range,
          ),
        ]));
  }

  Future<void> test_on() async {
    final content = '''
class MyCla^ss1 {}
/*[0*/mixin /*[1*/MyMixin1/*1]*/ on MyClass1 {}/*0]*/
''';
    await _fetchSubtypes(content);
    expect(
        subtypes,
        equals([
          _isItem(
            'MyMixin1',
            mainFileUri,
            range: code.ranges[0].range,
            selectionRange: code.ranges[1].range,
          ),
        ]));
  }

  Future<void> test_with() async {
    final content = '''
mixin MyMi^xin1 {}
/*[0*/class /*[1*/MyClass1/*1]*/ with MyMixin1 {}/*0]*/
''';
    await _fetchSubtypes(content);
    expect(
        subtypes,
        equals([
          _isItem(
            'MyClass1',
            mainFileUri,
            range: code.ranges[0].range,
            selectionRange: code.ranges[1].range,
          ),
        ]));
  }

  /// Parses [content], calls 'textDocument/prepareTypeHierarchy' at the
  /// marked location and then calls 'typeHierarchy/subtypes' with the result.
  Future<void> _fetchSubtypes(String content, {String? otherContent}) async {
    await _prepareTypeHierarchy(content, otherContent: otherContent);
    subtypes = await typeHierarchySubtypes(prepareResult!);
  }
}

@reflectiveTest
class TypeHierarchySupertypesTest extends AbstractTypeHierarchyTest {
  List<TypeHierarchyItem>? supertypes;

  Future<void> test_anotherFile() async {
    final content = '''
import 'other.dart';

class MyCla^ss2 extends MyClass1 {}
''';
    final otherContent = '''
/*[0*/class /*[1*/MyClass1/*1]*/ {}/*0]*/
''';
    await _fetchSupertypes(content, otherContent: otherContent);
    expect(
        supertypes,
        equals([
          _isItem(
            'MyClass1',
            otherFileUri,
            range: otherCode.ranges[0].range,
            selectionRange: otherCode.ranges[1].range,
          ),
        ]));
  }

  Future<void> test_extends() async {
    final content = '''
/*[0*/class /*[1*/MyClass1/*1]*/ {}/*0]*/
class MyCla^ss2 extends MyClass1 {}
''';
    await _fetchSupertypes(content);
    expect(
        supertypes,
        equals([
          _isItem(
            'MyClass1',
            mainFileUri,
            range: code.ranges[0].range,
            selectionRange: code.ranges[1].range,
          ),
        ]));
  }

  Future<void> test_extensionType() async {
    final content = '''
class A extends B {}
/*[0*/class /*[1*/B/*1]*/ {}/*0]*/
/*[2*/extension type /*[3*/E1/*3]*/(A a) {}/*2]*/
extension type E^2(A a) implements B, E1 {}
''';
    await _fetchSupertypes(content);
    expect(
        supertypes,
        equals([
          _isItem(
            'B',
            mainFileUri,
            range: code.ranges[0].range,
            selectionRange: code.ranges[1].range,
          ),
          _isItem(
            'E1',
            mainFileUri,
            range: code.ranges[2].range,
            selectionRange: code.ranges[3].range,
          ),
        ]));
  }

  /// Ensure that type arguments flow across multiple levels of the tree.
  Future<void> test_generics_typeArgsFlow() async {
    final content = '''
class A<T1, T2> {}
class B<T1, T2> extends A<T1, T2> {}
class C<T1> extends B<T1, String> {}
class D extends C<int> {}
class ^E extends D {}
''';
    await _prepareTypeHierarchy(content);

    // Walk the tree and collect names at each level.
    var item = prepareResult;
    var names = <String>[];
    while (item != null) {
      names.add(item.name);
      final supertypes = await typeHierarchySupertypes(item);
      item = (supertypes != null && supertypes.isNotEmpty)
          ? supertypes.single
          : null;
    }

    // Check for substituted type args.
    expect(names, [
      'E',
      'D',
      'C<int>',
      'B<int, String>',
      'A<int, String>',
      'Object',
    ]);
  }

  Future<void> test_implements() async {
    final content = '''
/*[0*/class /*[1*/MyClass1/*1]*/ {}/*0]*/
class MyCla^ss2 implements MyClass1 {}
''';
    await _fetchSupertypes(content);
    expect(
        supertypes,
        equals([
          _isObject,
          _isItem(
            'MyClass1',
            mainFileUri,
            range: code.ranges[0].range,
            selectionRange: code.ranges[1].range,
          ),
        ]));
  }

  Future<void> test_on() async {
    final content = '''
/*[0*/class /*[1*/MyClass1/*1]*/ {}/*0]*/
mixin MyMix^in1 on MyClass1 {}
''';
    await _fetchSupertypes(content);
    expect(
        supertypes,
        equals([
          _isItem(
            'MyClass1',
            mainFileUri,
            range: code.ranges[0].range,
            selectionRange: code.ranges[1].range,
          ),
        ]));
  }

  Future<void> test_with() async {
    final content = '''
/*[0*/mixin /*[1*/MyMixin1/*1]*/ {}/*0]*/
class MyCla^ss1 with MyMixin1 {}
''';
    await _fetchSupertypes(content);
    expect(
        supertypes,
        equals([
          _isObject,
          _isItem(
            'MyMixin1',
            mainFileUri,
            range: code.ranges[0].range,
            selectionRange: code.ranges[1].range,
          ),
        ]));
  }

  /// Parses [content], calls 'textDocument/prepareTypeHierarchy' at the
  /// marked location and then calls 'typeHierarchy/supertypes' with the result.
  Future<void> _fetchSupertypes(String content, {String? otherContent}) async {
    await _prepareTypeHierarchy(content, otherContent: otherContent);
    supertypes = await typeHierarchySupertypes(prepareResult!);
  }
}
