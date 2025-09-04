// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/computer/computer_lazy_type_hierarchy.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analysis_server/src/services/search/search_engine_internal.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../abstract_single_unit.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TypeHierarchyComputerFindSubtypesTest);
    defineReflectiveTests(TypeHierarchyComputerFindSupertypesTest);
    defineReflectiveTests(TypeHierarchyComputerFindTargetTest);
  });
}

abstract class AbstractTypeHierarchyTest extends AbstractSingleUnitTest {
  /// Matches a [TypeHierarchyItem] for [Enum].
  Matcher get _isEnum => TypeMatcher<TypeHierarchyItem>()
      .having((e) => e.displayName, 'displayName', 'Enum')
      // Check some basic things without hard-coding values that will make
      // this test brittle.
      .having((e) => e.file, 'file', convertPath('/sdk/lib/core/core.dart'))
      .having((e) => e.nameRange.offset, 'nameRange.offset', isPositive)
      .having((e) => e.nameRange.length, 'nameRange.length', 'Enum'.length)
      .having((e) => e.codeRange.offset, 'codeRange.offset', isPositive)
      .having(
        (e) => e.codeRange.length,
        'codeRange.length',
        greaterThan('class Enum {}'.length),
      );

  /// Matches a [TypeHierarchyItem] for [Object].
  Matcher get _isObject => TypeMatcher<TypeHierarchyItem>()
      .having((e) => e.displayName, 'displayName', 'Object')
      // Check some basic things without hard-coding values that will make
      // this test brittle.
      .having((e) => e.file, 'file', convertPath('/sdk/lib/core/core.dart'))
      .having((e) => e.nameRange.offset, 'nameRange.offset', isPositive)
      .having((e) => e.nameRange.length, 'nameRange.length', 'Object'.length)
      .having((e) => e.codeRange.offset, 'codeRange.offset', isPositive)
      .having(
        (e) => e.codeRange.length,
        'codeRange.length',
        greaterThan('class Object {}'.length),
      );

  Future<TypeHierarchyItem?> findTarget() async {
    expect(
      parsedTestCode,
      isNotNull,
      reason: 'addTestSource should be called first',
    );
    var result = await getResolvedUnit(testFile);
    return DartLazyTypeHierarchyComputer(
      result,
    ).findTarget(parsedTestCode.position.offset);
  }

  /// Matches a [TypeHierarchyItem] with the given values.
  Matcher _isItem(
    String displayName,
    String file, {
    required SourceRange nameRange,
    required SourceRange codeRange,
  }) => TypeMatcher<TypeHierarchyItem>()
      .having((e) => e.displayName, 'displayName', displayName)
      .having((e) => e.file, 'file', file)
      .having((e) => e.nameRange, 'nameRange', nameRange)
      .having((e) => e.codeRange, 'codeRange', codeRange);

  /// Matches a [TypeHierarchyRelatedItem] with the given values.
  Matcher _isRelatedItem(
    String displayName,
    String file, {
    required TypeHierarchyItemRelationship relationship,
    required SourceRange nameRange,
    required SourceRange codeRange,
  }) => allOf([
    _isItem(displayName, file, nameRange: nameRange, codeRange: codeRange),
    TypeMatcher<TypeHierarchyRelatedItem>().having(
      (e) => e.relationship,
      'relationship',
      relationship,
    ),
  ]);
}

@reflectiveTest
class TypeHierarchyComputerFindSubtypesTest extends AbstractTypeHierarchyTest {
  late SearchEngine searchEngine;

  Future<List<TypeHierarchyItem>?> findSubtypes(
    TypeHierarchyItem target,
  ) async {
    var file = getFile(target.file);
    var result = await getResolvedUnit(file);
    return DartLazyTypeHierarchyComputer(
      result,
    ).findSubtypes(target.location, searchEngine);
  }

  @override
  void setUp() {
    super.setUp();
    searchEngine = SearchEngineImpl([driverFor(testFile)]);
  }

  Future<void> test_class_generic() async {
    var content = '''
class My^Class1<T1, T2> {}
/*[0*/class /*[1*/MyClass2/*1]*/<T1> implements MyClass1<T1, String> {}/*0]*/
    ''';

    addTestSource(content);
    var target = await findTarget();
    var subtypes = await findSubtypes(target!);
    expect(subtypes, [
      _isRelatedItem(
        'MyClass2<T1>',
        testFile.path,
        relationship: TypeHierarchyItemRelationship.implements,
        codeRange: parsedTestCode.ranges[0].sourceRange,
        nameRange: parsedTestCode.ranges[1].sourceRange,
      ),
    ]);
  }

  Future<void> test_class_interfaces() async {
    var content = '''
class ^MyClass1 {}
/*[0*/class /*[1*/MyClass2/*1]*/ implements MyClass1 {}/*0]*/
    ''';

    addTestSource(content);
    var target = await findTarget();
    var subtypes = await findSubtypes(target!);
    expect(subtypes, [
      _isRelatedItem(
        'MyClass2',
        testFile.path,
        relationship: TypeHierarchyItemRelationship.implements,
        codeRange: parsedTestCode.ranges[0].sourceRange,
        nameRange: parsedTestCode.ranges[1].sourceRange,
      ),
    ]);
  }

  Future<void> test_class_mixins() async {
    var content = '''
/*[0*/class /*[1*/MyClass1/*1]*/ with MyMixin1 {}/*0]*/
/*[2*/class /*[3*/MyClass2/*3]*/ with MyMixin1 {}/*2]*/
mixin MyMi^xin1 {}
    ''';

    addTestSource(content);
    var target = await findTarget();
    var subtypes = await findSubtypes(target!);
    expect(subtypes, [
      _isRelatedItem(
        'MyClass1',
        testFile.path,
        relationship: TypeHierarchyItemRelationship.mixesIn,
        codeRange: parsedTestCode.ranges[0].sourceRange,
        nameRange: parsedTestCode.ranges[1].sourceRange,
      ),
      _isRelatedItem(
        'MyClass2',
        testFile.path,
        relationship: TypeHierarchyItemRelationship.mixesIn,
        codeRange: parsedTestCode.ranges[2].sourceRange,
        nameRange: parsedTestCode.ranges[3].sourceRange,
      ),
    ]);
  }

  Future<void> test_class_superclass() async {
    var content = '''
class ^MyClass1 {}
/*[0*/class /*[1*/MyClass2/*1]*/ extends MyClass1 {}/*0]*/
    ''';

    addTestSource(content);
    var target = await findTarget();
    var subtypes = await findSubtypes(target!);
    expect(subtypes, [
      _isRelatedItem(
        'MyClass2',
        testFile.path,
        relationship: TypeHierarchyItemRelationship.extends_,
        codeRange: parsedTestCode.ranges[0].sourceRange,
        nameRange: parsedTestCode.ranges[1].sourceRange,
      ),
    ]);
  }

  Future<void> test_enum_interfaces() async {
    var content = '''
/*[0*/enum /*[1*/MyEnum1/*1]*/ implements MyClass1 {
  one,
}/*0]*/
class MyCla^ss1 {}
    ''';

    addTestSource(content);
    var target = await findTarget();
    var subtypes = await findSubtypes(target!);
    expect(subtypes, [
      _isRelatedItem(
        'MyEnum1',
        testFile.path,
        relationship: TypeHierarchyItemRelationship.implements,
        codeRange: parsedTestCode.ranges[0].sourceRange,
        nameRange: parsedTestCode.ranges[1].sourceRange,
      ),
    ]);
  }

  Future<void> test_enum_mixins() async {
    var content = '''
/*[0*/enum /*[1*/MyEnum1/*1]*/ with MyMixin1 {
  one,
}/*0]*/
mixin MyMi^xin1 {}
    ''';

    addTestSource(content);
    var target = await findTarget();
    var subtypes = await findSubtypes(target!);
    expect(subtypes, [
      _isRelatedItem(
        'MyEnum1',
        testFile.path,
        relationship: TypeHierarchyItemRelationship.mixesIn,
        codeRange: parsedTestCode.ranges[0].sourceRange,
        nameRange: parsedTestCode.ranges[1].sourceRange,
      ),
    ]);
  }

  Future<void> test_mixin_interfaces() async {
    var content = '''
/*[0*/mixin /*[1*/MyMixin1/*1]*/ implements MyClass1 {}/*0]*/
class MyCl^ass1 {}
    ''';

    addTestSource(content);
    var target = await findTarget();
    var subtypes = await findSubtypes(target!);
    expect(subtypes, [
      _isRelatedItem(
        'MyMixin1',
        testFile.path,
        relationship: TypeHierarchyItemRelationship.implements,
        codeRange: parsedTestCode.ranges[0].sourceRange,
        nameRange: parsedTestCode.ranges[1].sourceRange,
      ),
    ]);
  }

  Future<void> test_mixin_superclassConstraints() async {
    var content = '''
/*[0*/mixin /*[1*/MyMixin1/*1]*/ on MyClass1 {}/*0]*/
class MyCl^ass1 {}
    ''';

    addTestSource(content);
    var target = await findTarget();
    var subtypes = await findSubtypes(target!);
    expect(subtypes, [
      _isRelatedItem(
        'MyMixin1',
        testFile.path,
        relationship: TypeHierarchyItemRelationship.constrainedTo,
        codeRange: parsedTestCode.ranges[0].sourceRange,
        nameRange: parsedTestCode.ranges[1].sourceRange,
      ),
    ]);
  }
}

@reflectiveTest
class TypeHierarchyComputerFindSupertypesTest
    extends AbstractTypeHierarchyTest {
  Future<List<TypeHierarchyItem>?> findSupertypes(
    TypeHierarchyItem target,
  ) async {
    var file = getFile(target.file);
    var result = await getResolvedUnit(file);
    return DartLazyTypeHierarchyComputer(
      result,
    ).findSupertypes(target.location);
  }

  /// Test that if the file is modified between fetching a target and it's
  /// sub/supertypes it can still be located (by name).
  Future<void> test_class_afterModification() async {
    var content = '''
/*[0*/class /*[1*/MyClass1/*1]*/ {}/*0]*/
class ^MyClass2 extends MyClass1 {}
    ''';

    addTestSource(content);
    var target = await findTarget();

    // Update the content so that offsets have changed since we got `target`.
    updateTestSource('''
// extra
$content''');

    var supertypes = await findSupertypes(target!);
    expect(supertypes, [
      _isRelatedItem(
        'MyClass1',
        testFile.path,
        relationship: TypeHierarchyItemRelationship.extends_,
        codeRange: parsedTestCode.ranges[0].sourceRange,
        nameRange: parsedTestCode.ranges[1].sourceRange,
      ),
    ]);
  }

  Future<void> test_class_generic() async {
    var content = '''
/*[0*/class /*[1*/MyClass1/*1]*/<T1, T2> {}/*0]*/
class ^MyClass2<T1> implements MyClass1<T1, String> {}
    ''';

    addTestSource(content);
    var target = await findTarget();
    var supertypes = await findSupertypes(target!);
    expect(supertypes, [
      _isObject,
      _isRelatedItem(
        'MyClass1<T1, T2>',
        testFile.path,
        relationship: TypeHierarchyItemRelationship.implements,
        codeRange: parsedTestCode.ranges[0].sourceRange,
        nameRange: parsedTestCode.ranges[1].sourceRange,
      ),
    ]);
  }

  /// Ensure that type parameters are shown instead of type arguments.
  Future<void> test_class_generic_typeParameters() async {
    var content = '''
class A<T1, T2> {}
class B<T1, T2> extends A<T1, T2> {}
class C<T1> extends B<T1, String> {}
class D extends C<int> {}
class ^E extends D {}
    ''';
    addTestSource(content);
    fileForContextSelection = testFile;

    // Walk the tree and collect names at each level.
    var names = <String>[];
    var target = await findTarget();
    while (target != null) {
      names.add(target.displayName);
      var supertypes = await findSupertypes(target);
      target = (supertypes != null && supertypes.isNotEmpty)
          ? supertypes.single
          : null;
    }

    expect(names, ['E', 'D', 'C<T1>', 'B<T1, T2>', 'A<T1, T2>', 'Object']);
  }

  Future<void> test_class_interfaces() async {
    var content = '''
/*[0*/class /*[1*/MyClass1/*1]*/ {}/*0]*/
class ^MyClass2 implements MyClass1 {}
    ''';

    addTestSource(content);
    var target = await findTarget();
    var supertypes = await findSupertypes(target!);
    expect(supertypes, [
      _isObject,
      _isRelatedItem(
        'MyClass1',
        testFile.path,
        relationship: TypeHierarchyItemRelationship.implements,
        codeRange: parsedTestCode.ranges[0].sourceRange,
        nameRange: parsedTestCode.ranges[1].sourceRange,
      ),
    ]);
  }

  Future<void> test_class_mixins() async {
    var content = '''
/*[0*/mixin /*[1*/MyMixin1/*1]*/ {}/*0]*/
/*[2*/mixin /*[3*/MyMixin2/*3]*/ {}/*2]*/
class ^MyClass1 with MyMixin1, MyMixin2 {}
    ''';

    addTestSource(content);
    var target = await findTarget();
    var supertypes = await findSupertypes(target!);
    expect(supertypes, [
      _isObject,
      _isRelatedItem(
        'MyMixin1',
        testFile.path,
        relationship: TypeHierarchyItemRelationship.mixesIn,
        codeRange: parsedTestCode.ranges[0].sourceRange,
        nameRange: parsedTestCode.ranges[1].sourceRange,
      ),
      _isRelatedItem(
        'MyMixin2',
        testFile.path,
        relationship: TypeHierarchyItemRelationship.mixesIn,
        codeRange: parsedTestCode.ranges[2].sourceRange,
        nameRange: parsedTestCode.ranges[3].sourceRange,
      ),
    ]);
  }

  Future<void> test_class_superclass() async {
    var content = '''
/*[0*/class /*[1*/MyClass1/*1]*/ {}/*0]*/
class ^MyClass2 extends MyClass1 {}
    ''';

    addTestSource(content);
    var target = await findTarget();
    var supertypes = await findSupertypes(target!);
    expect(supertypes, [
      _isRelatedItem(
        'MyClass1',
        testFile.path,
        relationship: TypeHierarchyItemRelationship.extends_,
        codeRange: parsedTestCode.ranges[0].sourceRange,
        nameRange: parsedTestCode.ranges[1].sourceRange,
      ),
    ]);
  }

  Future<void> test_enum_interfaces() async {
    var content = '''
enum MyEn^um1 implements MyClass1 { one }
/*[0*/class /*[1*/MyClass1/*1]*/ {}/*0]*/
    ''';

    addTestSource(content);
    var target = await findTarget();
    var supertypes = await findSupertypes(target!);
    expect(supertypes, [
      _isEnum,
      _isRelatedItem(
        'MyClass1',
        testFile.path,
        relationship: TypeHierarchyItemRelationship.implements,
        codeRange: parsedTestCode.ranges[0].sourceRange,
        nameRange: parsedTestCode.ranges[1].sourceRange,
      ),
    ]);
  }

  Future<void> test_enum_mixins() async {
    var content = '''
enum MyEn^um1 with MyMixin1 { one }
/*[0*/mixin /*[1*/MyMixin1/*1]*/ {}/*0]*/
    ''';

    addTestSource(content);
    var target = await findTarget();
    var supertypes = await findSupertypes(target!);
    expect(supertypes, [
      _isEnum,
      _isRelatedItem(
        'MyMixin1',
        testFile.path,
        relationship: TypeHierarchyItemRelationship.mixesIn,
        codeRange: parsedTestCode.ranges[0].sourceRange,
        nameRange: parsedTestCode.ranges[1].sourceRange,
      ),
    ]);
  }

  Future<void> test_mixin_interfaces() async {
    var content = '''
/*[0*/class /*[1*/MyClass1/*1]*/ {}/*0]*/
mixin MyMix^in2 implements MyClass1 {}
    ''';

    addTestSource(content);
    var target = await findTarget();
    var supertypes = await findSupertypes(target!);
    expect(supertypes, [
      _isObject,
      _isRelatedItem(
        'MyClass1',
        testFile.path,
        relationship: TypeHierarchyItemRelationship.implements,
        codeRange: parsedTestCode.ranges[0].sourceRange,
        nameRange: parsedTestCode.ranges[1].sourceRange,
      ),
    ]);
  }

  Future<void> test_mixin_superclassConstraints() async {
    var content = '''
/*[0*/class /*[1*/MyClass1/*1]*/ {}/*0]*/
mixin MyMix^in2 on MyClass1 {}
    ''';

    addTestSource(content);
    var target = await findTarget();
    var supertypes = await findSupertypes(target!);
    expect(supertypes, [
      _isRelatedItem(
        'MyClass1',
        testFile.path,
        relationship: TypeHierarchyItemRelationship.constrainedTo,
        codeRange: parsedTestCode.ranges[0].sourceRange,
        nameRange: parsedTestCode.ranges[1].sourceRange,
      ),
    ]);
  }
}

@reflectiveTest
class TypeHierarchyComputerFindTargetTest extends AbstractTypeHierarchyTest {
  Future<void> expectNoTarget() async {
    await expectTarget(isNull);
  }

  Future<void> expectTarget(Matcher matcher) async {
    var target = await findTarget();
    expect(target, matcher);
  }

  Future<void> test_class_body() async {
    var content = '''
/*[0*/class /*[1*/MyClass1/*1]*/ {
  int? a^;
}/*0]*/
    ''';

    addTestSource(content);
    await expectTarget(
      _isItem(
        'MyClass1',
        testFile.path,
        codeRange: parsedTestCode.ranges[0].sourceRange,
        nameRange: parsedTestCode.ranges[1].sourceRange,
      ),
    );
  }

  Future<void> test_class_generic() async {
    var content = '''
/*[0*/class /*[1*/MyCl^ass1/*1]*/<T1, T2> {}/*0]*/
    ''';

    addTestSource(content);
    await expectTarget(
      _isItem(
        'MyClass1<T1, T2>',
        testFile.path,
        codeRange: parsedTestCode.ranges[0].sourceRange,
        nameRange: parsedTestCode.ranges[1].sourceRange,
      ),
    );
  }

  Future<void> test_class_keyword() async {
    var content = '''
/*[0*/cla^ss /*[1*/MyClass1/*1]*/ {
}/*0]*/
    ''';

    addTestSource(content);
    await expectTarget(
      _isItem(
        'MyClass1',
        testFile.path,
        codeRange: parsedTestCode.ranges[0].sourceRange,
        nameRange: parsedTestCode.ranges[1].sourceRange,
      ),
    );
  }

  Future<void> test_class_name() async {
    var content = '''
/*[0*/class /*[1*/MyCla^ss1/*1]*/ {
}/*0]*/
    ''';

    addTestSource(content);
    await expectTarget(
      _isItem(
        'MyClass1',
        testFile.path,
        codeRange: parsedTestCode.ranges[0].sourceRange,
        nameRange: parsedTestCode.ranges[1].sourceRange,
      ),
    );
  }

  Future<void> test_enum_body() async {
    var content = '''
/*[0*/enum /*[1*/MyEnum1/*1]*/ {
^  v
}/*0]*/
    ''';

    addTestSource(content);
    await expectTarget(
      _isItem(
        'MyEnum1',
        testFile.path,
        codeRange: parsedTestCode.ranges[0].sourceRange,
        nameRange: parsedTestCode.ranges[1].sourceRange,
      ),
    );
  }

  Future<void> test_enum_keyword() async {
    var content = '''
/*[0*/en^um /*[1*/MyEnum1/*1]*/ {
  v
}/*0]*/
    ''';

    addTestSource(content);
    await expectTarget(
      _isItem(
        'MyEnum1',
        testFile.path,
        codeRange: parsedTestCode.ranges[0].sourceRange,
        nameRange: parsedTestCode.ranges[1].sourceRange,
      ),
    );
  }

  Future<void> test_enumName() async {
    var content = '''
/*[0*/enum /*[1*/MyEn^um1/*1]*/ {
  v
}/*0]*/
    ''';

    addTestSource(content);
    await expectTarget(
      _isItem(
        'MyEnum1',
        testFile.path,
        codeRange: parsedTestCode.ranges[0].sourceRange,
        nameRange: parsedTestCode.ranges[1].sourceRange,
      ),
    );
  }

  Future<void> test_invalid_topLevel_nonClass() async {
    var content = '''
int? a^;
''';

    addTestSource(content);
    await expectNoTarget();
  }

  Future<void> test_invalid_topLevel_whitespace() async {
    var content = '''
int? a;
^
int? b;
''';

    addTestSource(content);
    await expectNoTarget();
  }

  Future<void> test_mixin_body() async {
    var content = '''
/*[0*/mixin /*[1*/MyMixin1/*1]*/ {
  ^
}/*0]*/
    ''';

    addTestSource(content);
    await expectTarget(
      _isItem(
        'MyMixin1',
        testFile.path,
        codeRange: parsedTestCode.ranges[0].sourceRange,
        nameRange: parsedTestCode.ranges[1].sourceRange,
      ),
    );
  }

  Future<void> test_mixin_keyword() async {
    var content = '''
/*[0*/mi^xin /*[1*/MyMixin1/*1]*/ {
}/*0]*/
    ''';

    addTestSource(content);
    await expectTarget(
      _isItem(
        'MyMixin1',
        testFile.path,
        codeRange: parsedTestCode.ranges[0].sourceRange,
        nameRange: parsedTestCode.ranges[1].sourceRange,
      ),
    );
  }

  Future<void> test_mixinName() async {
    var content = '''
/*[0*/mixin /*[1*/MyMix^in1/*1]*/ {
}/*0]*/
    ''';

    addTestSource(content);
    await expectTarget(
      _isItem(
        'MyMixin1',
        testFile.path,
        codeRange: parsedTestCode.ranges[0].sourceRange,
        nameRange: parsedTestCode.ranges[1].sourceRange,
      ),
    );
  }

  /// Ensure invocations directly on a type with type arguments show the type
  /// parameters.
  Future<void> test_typeReference_generic() async {
    var content = '''
/*[0*/class /*[1*/MyClass1/*1]*/<T1, T2> {}/*0]*/
MyCl^ass1<String, String>? a;
    ''';

    addTestSource(content);
    await expectTarget(
      _isItem(
        'MyClass1<T1, T2>',
        testFile.path,
        codeRange: parsedTestCode.ranges[0].sourceRange,
        nameRange: parsedTestCode.ranges[1].sourceRange,
      ),
    );
  }
}
