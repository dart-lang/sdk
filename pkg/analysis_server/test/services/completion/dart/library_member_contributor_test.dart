// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/library_member_contributor.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'completion_contributor_util.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LibraryMemberContributorTest);
  });
}

@reflectiveTest
class LibraryMemberContributorTest extends DartCompletionContributorTest {
  @override
  DartCompletionContributor createContributor() {
    return LibraryMemberContributor();
  }

  Future<void> test_extension() async {
    // SimpleIdentifier  PrefixedIdentifier  ExpressionStatement
    addSource('/home/test/lib/b.dart', '''
extension MyExt on int {}
''');
    addTestSource('''
        import "b.dart" as b;
        main() {b.^}''');
    await computeSuggestions();
    assertSuggest('MyExt');
  }

  Future<void> test_libraryPrefix() async {
    // SimpleIdentifier  PrefixedIdentifier  ExpressionStatement
    addTestSource('import "dart:async" as bar; foo() {bar.^}');
    await computeSuggestions();
    assertSuggestClass('Future');
    assertNotSuggested('loadLibrary');
  }

  Future<void> test_libraryPrefix2() async {
    // SimpleIdentifier  MethodInvocation  ExpressionStatement
    addTestSource('import "dart:async" as bar; foo() {bar.^ print("f")}');
    await computeSuggestions();
    assertSuggestClass('Future');
  }

  Future<void> test_libraryPrefix3() async {
    // SimpleIdentifier  MethodInvocation  ExpressionStatement
    addTestSource('import "dart:async" as bar; foo() {new bar.F^ print("f")}');
    await computeSuggestions();
    assertSuggestConstructor('Future');
    assertSuggestConstructor('Future.delayed');
  }

  Future<void> test_libraryPrefix_cascade() async {
    addTestSource('''
    import "dart:math" as math;
    main() {math..^}''');
    await computeSuggestions();
    assertNoSuggestions();
  }

  Future<void> test_libraryPrefix_cascade2() async {
    addTestSource('''
    import "dart:math" as math;
    main() {math.^.}''');
    await computeSuggestions();
    assertSuggestFunction('min', 'T');
  }

  Future<void> test_libraryPrefix_cascade3() async {
    addTestSource('''
    import "dart:math" as math;
    main() {math..^a}''');
    await computeSuggestions();
    assertNoSuggestions();
  }

  Future<void> test_libraryPrefix_cascade4() async {
    addTestSource('''
    import "dart:math" as math;
    main() {math.^.a}''');
    await computeSuggestions();
    assertSuggestFunction('min', 'T');
  }

  Future<void> test_libraryPrefix_deferred() async {
    // SimpleIdentifier  PrefixedIdentifier  ExpressionStatement
    addTestSource('import "dart:async" deferred as bar; foo() {bar.^}');
    await computeSuggestions();
    assertSuggestClass('Future');
    assertSuggestFunction('loadLibrary', 'Future<dynamic>');
  }

  Future<void> test_libraryPrefix_deferred_inPart() async {
    // SimpleIdentifier  PrefixedIdentifier  ExpressionStatement
    newFile('$testPackageLibPath/a.dart', content: '''
        library testA;
        import "dart:async" deferred as bar;
        part "test.dart";''');
    addTestSource('part of testA; foo() {bar.^}');
    await resolveFile('$testPackageLibPath/a.dart');
    // Assume that libraries containing has been computed for part files
    await computeSuggestions();
    assertSuggestClass('Future');
    assertSuggestFunction('loadLibrary', 'Future<dynamic>');
    assertNotSuggested('foo');
  }

  Future<void> test_libraryPrefix_with_exports() async {
    newFile('$testPackageLibPath/a.dart', content: 'library libA; class A { }');
    newFile('$testPackageLibPath/b.dart', content: '''
        library libB;
        export "a.dart";
        class B { }
        @deprecated class B1 { }''');
    addTestSource('import "b.dart" as foo; main() {foo.^} class C { }');
    await computeSuggestions();
    assertSuggestClass('B');
    assertSuggestClass('B1', isDeprecated: true);
    assertSuggestClass('A');
    assertNotSuggested('C');
  }

  Future<void> test_PrefixedIdentifier_library() async {
    // SimpleIdentifier  PrefixedIdentifier  ExpressionStatement
    addSource('/home/test/lib/b.dart', '''
        lib B;
        var T1;
        class X { }
        class Y { }''');
    addTestSource('''
        import "b.dart" as b;
        var T2;
        class A { }
        main() {b.^}''');
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestClass('X');
    assertSuggestClass('Y');
    assertSuggestTopLevelVar('T1', null);
    assertNotSuggested('T2');
    assertNotSuggested('Object');
    assertNotSuggested('b');
    assertNotSuggested('A');
    assertNotSuggested('==');
  }

  Future<void> test_PrefixedIdentifier_library_export_withShow() async {
    addSource('/home/test/lib/a.dart', r'''
class A {}
class B {}
''');
    addSource('/home/test/lib/b.dart', r'''
export 'a.dart' show A;
''');
    addTestSource(r'''
import 'b.dart' as p;
main() {
  p.^
}
''');
    await computeSuggestions();
    assertSuggestClass('A');
    assertNotSuggested('B');
  }

  Future<void> test_PrefixedIdentifier_library_import_withShow() async {
    addSource('/home/test/lib/a.dart', r'''
class A {}
class B {}
''');
    addTestSource(r'''
import 'a.dart' as p show A;
main() {
  p.^
}
''');
    await computeSuggestions();
    assertSuggestClass('A');
    assertNotSuggested('B');
  }

  Future<void> test_PrefixedIdentifier_library_inPart() async {
    // SimpleIdentifier  PrefixedIdentifier  ExpressionStatement
    newFile('$testPackageLibPath/b.dart', content: '''
        lib B;
        var T1;
        class X { }
        class Y { }''');
    newFile('$testPackageLibPath/a.dart', content: '''
        library testA;
        import "b.dart" as b;
        part "test.dart";
        var T2;
        class A { }''');
    addTestSource('''
        part of testA;
        main() {b.^}''');
    await resolveFile('$testPackageLibPath/a.dart');
    // Assume that libraries containing has been computed for part files
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestClass('X');
    assertSuggestClass('Y');
    assertSuggestTopLevelVar('T1', null);
    assertNotSuggested('T2');
    assertNotSuggested('Object');
    assertNotSuggested('b');
    assertNotSuggested('A');
    assertNotSuggested('==');
  }

  Future<void> test_PrefixedIdentifier_library_typesOnly() async {
    // SimpleIdentifier  PrefixedIdentifier  TypeName
    newFile('$testPackageLibPath/b.dart', content: '''
        lib B;
        var T1;
        class X { }
        class Y { }''');
    addTestSource('''
        import "b.dart" as b;
        var T2;
        class A { }
        foo(b.^ f) {}''');
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestClass('X');
    assertSuggestClass('Y');
    assertNotSuggested('T1');
    assertNotSuggested('T2');
    assertNotSuggested('Object');
    assertNotSuggested('b');
    assertNotSuggested('A');
    assertNotSuggested('==');
  }

  Future<void> test_PrefixedIdentifier_library_typesOnly2() async {
    // SimpleIdentifier  PrefixedIdentifier  TypeName
    newFile('$testPackageLibPath/b.dart', content: '''
        lib B;
        var T1;
        class X { }
        class Y { }''');
    addTestSource('''
        import "b.dart" as b;
        var T2;
        class A { }
        foo(b.^) {}''');
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestClass('X');
    assertSuggestClass('Y');
    assertNotSuggested('T1');
    assertNotSuggested('T2');
    assertNotSuggested('Object');
    assertNotSuggested('b');
    assertNotSuggested('A');
    assertNotSuggested('==');
  }

  Future<void> test_PrefixedIdentifier_parameter() async {
    // SimpleIdentifier  PrefixedIdentifier  ExpressionStatement
    newFile('$testPackageLibPath/b.dart', content: '''
        lib B;
        class _W {M y; var _z;}
        class X extends _W {}
        class M{}''');
    addTestSource('''
        import "b.dart";
        foo(X x) {x.^}''');
    await computeSuggestions();
    assertNoSuggestions();
  }

  Future<void> test_PrefixedIdentifier_prefix() async {
    // SimpleIdentifier  PrefixedIdentifier  ExpressionStatement
    newFile('$testPackageLibPath/a.dart', content: '''
        class A {static int bar = 10;}
        _B() {}''');
    addTestSource('''
        import "a.dart";
        class X {foo(){A^.bar}}''');
    await computeSuggestions();
    assertNoSuggestions();
  }
}
