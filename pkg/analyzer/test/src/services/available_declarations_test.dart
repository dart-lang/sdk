// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/services/available_declarations.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvailableDeclarationsTest);
  });
}

class AbstractContextTest with ResourceProviderMixin {
  final byteStore = MemoryByteStore();

  AnalysisContextCollection analysisContextCollection;

  AnalysisContext testAnalysisContext;

  void addTestPackageDependency(String name, String rootPath) {
    var packagesFile = getFile('/home/test/.packages');
    var packagesContent = packagesFile.readAsStringSync();

    // Ignore if there is already the same package dependency.
    if (packagesContent.contains('$name:file://')) {
      return;
    }

    rootPath = convertPath(rootPath);
    packagesContent += '$name:${toUri('$rootPath/lib')}\n';

    packagesFile.writeAsStringSync(packagesContent);

    createAnalysisContexts();
  }

  /// Create all analysis contexts in `/home`.
  void createAnalysisContexts() {
    analysisContextCollection = AnalysisContextCollectionImpl(
      includedPaths: [convertPath('/home')],
      resourceProvider: resourceProvider,
      sdkPath: convertPath('/sdk'),
    );

    var testPath = convertPath('/home/test');
    testAnalysisContext = getContext(testPath);
  }

  /// Return the existing analysis context that should be used to analyze the
  /// given [path], or throw [StateError] if the [path] is not analyzed in any
  /// of the created analysis contexts.
  AnalysisContext getContext(String path) {
    path = convertPath(path);
    return analysisContextCollection.contextFor(path);
  }

  setUp() {
    new MockSdk(resourceProvider: resourceProvider);

    newFolder('/home/test');
    newFile('/home/test/.packages', content: r'''
test:file:///home/test/lib
''');

    createAnalysisContexts();
  }
}

@reflectiveTest
class AvailableDeclarationsTest extends AbstractContextTest {
  DeclarationsTracker tracker;

  final List<LibraryChange> changes = [];

  final Map<int, Library> idToLibrary = {};
  final Map<String, Library> uriToLibrary = {};

  @override
  setUp() {
    super.setUp();
    _createTracker();
  }

  test_export() async {
    newFile('/home/test/lib/a.dart', content: r'''
class A {}
class B {}
''');
    newFile('/home/test/lib/test.dart', content: r'''
export 'a.dart';
class C {}
''');
    tracker.addContext(testAnalysisContext);

    await _doAllTrackerWork();
    _assertLibraryDeclarations([
      _ExpectedDeclaration.class_('A'),
      _ExpectedDeclaration.class_('B'),
      _ExpectedDeclaration.class_('C'),
    ], uriStr: 'package:test/test.dart');
  }

  test_export_combinators_hide() async {
    newFile('/home/test/lib/a.dart', content: r'''
class A {}
class B {}
class C {}
''');
    newFile('/home/test/lib/test.dart', content: r'''
export 'a.dart' hide B;
class D {}
''');
    tracker.addContext(testAnalysisContext);

    await _doAllTrackerWork();
    _assertLibraryDeclarations([
      _ExpectedDeclaration.class_('A'),
      _ExpectedDeclaration.class_('C'),
      _ExpectedDeclaration.class_('D'),
    ], uriStr: 'package:test/test.dart');
  }

  test_export_combinators_show() async {
    newFile('/home/test/lib/a.dart', content: r'''
class A {}
class B {}
class C {}
''');
    newFile('/home/test/lib/test.dart', content: r'''
export 'a.dart' show B;
class D {}
''');
    tracker.addContext(testAnalysisContext);

    await _doAllTrackerWork();
    _assertLibraryDeclarations([
      _ExpectedDeclaration.class_('B'),
      _ExpectedDeclaration.class_('D'),
    ], uriStr: 'package:test/test.dart');
  }

  test_export_cycle() async {
    newFile('/home/test/lib/a.dart', content: r'''
export 'b.dart';
class A {}
''');
    newFile('/home/test/lib/b.dart', content: r'''
export 'a.dart';
class B {}
''');
    newFile('/home/test/lib/test.dart', content: r'''
export 'b.dart';
class C {}
''');
    tracker.addContext(testAnalysisContext);

    await _doAllTrackerWork();

    _assertLibraryDeclarations([
      _ExpectedDeclaration.class_('A'),
      _ExpectedDeclaration.class_('B'),
    ], uriStr: 'package:test/a.dart');

    _assertLibraryDeclarations([
      _ExpectedDeclaration.class_('A'),
      _ExpectedDeclaration.class_('B'),
    ], uriStr: 'package:test/b.dart');

    _assertLibraryDeclarations([
      _ExpectedDeclaration.class_('A'),
      _ExpectedDeclaration.class_('B'),
      _ExpectedDeclaration.class_('C'),
    ], uriStr: 'package:test/test.dart');
  }

  test_export_missing() async {
    newFile('/home/test/lib/test.dart', content: r'''
export 'a.dart';
class C {}
''');
    tracker.addContext(testAnalysisContext);

    await _doAllTrackerWork();
    _assertLibraryDeclarations([
      _ExpectedDeclaration.class_('C'),
    ], uriStr: 'package:test/test.dart');
  }

  test_export_sequence() async {
    newFile('/home/test/lib/a.dart', content: r'''
class A {}
''');
    newFile('/home/test/lib/b.dart', content: r'''
export 'a.dart';
class B {}
''');
    newFile('/home/test/lib/test.dart', content: r'''
export 'b.dart';
class C {}
''');
    tracker.addContext(testAnalysisContext);

    await _doAllTrackerWork();

    _assertLibraryDeclarations([
      _ExpectedDeclaration.class_('A'),
    ], uriStr: 'package:test/a.dart');

    _assertLibraryDeclarations([
      _ExpectedDeclaration.class_('A'),
      _ExpectedDeclaration.class_('B'),
    ], uriStr: 'package:test/b.dart');

    _assertLibraryDeclarations([
      _ExpectedDeclaration.class_('A'),
      _ExpectedDeclaration.class_('B'),
      _ExpectedDeclaration.class_('C'),
    ], uriStr: 'package:test/test.dart');
  }

  test_export_shadowedByLocal() async {
    newFile('/home/test/lib/a.dart', content: r'''
class A {}
class B {}
''');
    newFile('/home/test/lib/test.dart', content: r'''
export 'a.dart';

mixin B {}
''');
    tracker.addContext(testAnalysisContext);

    await _doAllTrackerWork();
    _assertLibraryDeclarations([
      _ExpectedDeclaration.class_('A'),
      _ExpectedDeclaration.mixin('B'),
    ], uriStr: 'package:test/test.dart');
  }

  test_getLibraries_pub() async {
    newFile('/home/aaa/lib/a.dart', content: r'''
class A {}
''');
    newFile('/home/aaa/lib/src/a2.dart', content: r'''
class A2 {}
''');

    newFile('/home/bbb/lib/b.dart', content: r'''
class B {}
''');
    newFile('/home/bbb/lib/src/b2.dart', content: r'''
class B2 {}
''');

    addTestPackageDependency('aaa', '/home/aaa');
    addTestPackageDependency('bbb', '/home/bbb');

    newFile('/home/test/pubspec.yaml', content: r'''
name: test

dependencies:
  aaa: any

dev_dependencies:
  bbb: any
''');

    newFile('/home/test/lib/test.dart', content: '');
    var context = tracker.addContext(testAnalysisContext);

    await _doAllTrackerWork();

    var aUri = 'package:aaa/a.dart';
    var bUri = 'package:bbb/b.dart';

    _assertLibraryDeclarations([
      _ExpectedDeclaration.class_('A'),
    ], uriStr: aUri);
    _assertLibraryDeclarations([
      _ExpectedDeclaration.class_('B'),
    ], uriStr: bUri);

    // package/lib can see only regular dependencies
    {
      var path = convertPath('/home/test/lib/a.dart');
      var idList = context.getLibraries(path);
      expect(idList, contains(uriToLibrary[aUri].id));
      expect(idList, isNot(contains(uriToLibrary[bUri].id)));
    }

    // package/bin can see regular and dev dependencies
    {
      var path = convertPath('/home/test/bin/b.dart');
      var idList = context.getLibraries(path);
      expect(idList, contains(uriToLibrary[aUri].id));
      expect(idList, contains(uriToLibrary[bUri].id));
    }

    // package/test can see regular and dev dependencies
    {
      var path = convertPath('/home/test/test/c.dart');
      var idList = context.getLibraries(path);
      expect(idList, contains(uriToLibrary[aUri].id));
      expect(idList, contains(uriToLibrary[bUri].id));
    }
  }

  test_getLibraries_pub_inner() async {
    newFile('/home/aaa/lib/a.dart', content: r'''
class A {}
''');
    newFile('/home/bbb/lib/b.dart', content: r'''
class B {}
''');

    addTestPackageDependency('aaa', '/home/aaa');
    addTestPackageDependency('bbb', '/home/bbb');

    newFile('/home/test/pubspec.yaml', content: r'''
name: test

dependencies:
  aaa: any

dev_dependencies:
  bbb: any
''');

    newFile('/home/test/examples/basic/pubspec.yaml', content: r'''
name: basic

dependencies:
  bbb: any
''');

    newFile('/home/test/lib/test.dart', content: '');
    newFile('/home/test/examples/basic/lib/basic.dart', content: '');

    var context = tracker.addContext(testAnalysisContext);

    await _doAllTrackerWork();

    var aUri = 'package:aaa/a.dart';
    var bUri = 'package:bbb/b.dart';

    _assertLibraryDeclarations([
      _ExpectedDeclaration.class_('A'),
    ], uriStr: aUri);
    _assertLibraryDeclarations([
      _ExpectedDeclaration.class_('B'),
    ], uriStr: bUri);

    // package/lib can see package:aaa
    {
      var path = convertPath('/home/test/lib/a.dart');
      var idList = context.getLibraries(path);
      expect(idList, contains(uriToLibrary[aUri].id));
      expect(idList, isNot(contains(uriToLibrary[bUri].id)));
    }

    // examples/basic can see package:bbb
    {
      var path = convertPath('/home/test/examples/basic/lib/basic.dart');
      var idList = context.getLibraries(path);
      expect(idList, isNot(contains(uriToLibrary[aUri].id)));
      expect(idList, contains(uriToLibrary[bUri].id));
    }
  }

  test_getLibraries_setDependencies() async {
    newFile('/home/aaa/lib/a.dart', content: r'''
export 'src/a2.dart' show A2;
class A1 {}
''');
    newFile('/home/aaa/lib/src/a2.dart', content: r'''
class A2 {}
class A3 {}
''');
    newFile('/home/bbb/lib/b.dart', content: r'''
class B {}
''');

    addTestPackageDependency('aaa', '/home/aaa');
    addTestPackageDependency('bbb', '/home/bbb');

    newFile('/home/test/lib/test.dart', content: r'''
class C {}
''');

    var context = tracker.addContext(testAnalysisContext);
    context.setDependencies({
      convertPath('/home/test'): [
        convertPath('/home/aaa/lib'),
        convertPath('/home/bbb/lib'),
      ],
      convertPath('/home/test/lib'): [convertPath('/home/aaa/lib')],
    });

    await _doAllTrackerWork();

    var aUri = 'package:aaa/a.dart';
    var bUri = 'package:bbb/b.dart';

    _assertLibraryDeclarations([
      _ExpectedDeclaration.class_('A1'),
      _ExpectedDeclaration.class_('A2'),
    ], uriStr: aUri);
    _assertNoLibrary('package:aaa/src/a2.dart');
    _assertLibraryDeclarations([
      _ExpectedDeclaration.class_('B'),
    ], uriStr: bUri);

    // package/lib can see only regular dependencies
    {
      var path = convertPath('/home/test/lib/a.dart');
      var idList = context.getLibraries(path);
      expect(idList, contains(uriToLibrary[aUri].id));
      expect(idList, isNot(contains(uriToLibrary[bUri].id)));
    }

    // package/bin can see regular and dev dependencies
    {
      var path = convertPath('/home/test/bin/b.dart');
      var idList = context.getLibraries(path);
      expect(idList, contains(uriToLibrary[aUri].id));
      expect(idList, contains(uriToLibrary[bUri].id));
    }
  }

  test_getLibraries_setDependencies_twice() async {
    newFile('/home/aaa/lib/a.dart', content: r'''
class A {}
''');
    newFile('/home/bbb/lib/b.dart', content: r'''
class B {}
''');

    addTestPackageDependency('aaa', '/home/aaa');
    addTestPackageDependency('bbb', '/home/bbb');

    newFile('/home/test/lib/test.dart', content: r'''
class C {}
''');

    var context = tracker.addContext(testAnalysisContext);

    var aUri = 'package:aaa/a.dart';
    var bUri = 'package:bbb/b.dart';

    context.setDependencies({
      convertPath('/home/test'): [convertPath('/home/aaa/lib')],
    });
    await _doAllTrackerWork();

    _assertLibraryDeclarations([
      _ExpectedDeclaration.class_('A'),
    ], uriStr: aUri);
    _assertNoLibrary(bUri);

    // The package can see package:aaa, but not package:bbb
    {
      var path = convertPath('/home/test/lib/a.dart');
      var idList = context.getLibraries(path);
      expect(idList, contains(uriToLibrary[aUri].id));
      expect(uriToLibrary[bUri], isNull);
    }

    context.setDependencies({
      convertPath('/home/test'): [convertPath('/home/bbb/lib')],
    });
    await _doAllTrackerWork();

    _assertLibraryDeclarations([
      _ExpectedDeclaration.class_('A'),
    ], uriStr: aUri);
    _assertLibraryDeclarations([
      _ExpectedDeclaration.class_('B'),
    ], uriStr: bUri);

    // The package can see package:bbb, but not package:aaa
    {
      var path = convertPath('/home/test/lib/a.dart');
      var idList = context.getLibraries(path);
      expect(idList, isNot(contains(uriToLibrary[aUri].id)));
      expect(idList, contains(uriToLibrary[bUri].id));
    }
  }

  test_kindsOfDeclarations() async {
    newFile('/home/test/lib/test.dart', content: r'''
class MyClass {}
class MyClassTypeAlias = Object with MyMixin;
enum MyEnum {a, b, c}
void myFunction() {}
typedef MyFunctionTypeAlias = void Function();
mixin MyMixin {}
var myVariable1, myVariable2;
''');
    tracker.addContext(testAnalysisContext);

    await _doAllTrackerWork();
    _assertLibraryDeclarations([
      _ExpectedDeclaration.class_('MyClass'),
      _ExpectedDeclaration.classTypeAlias('MyClassTypeAlias'),
      _ExpectedDeclaration.enum_('MyEnum'),
      _ExpectedDeclaration.function('myFunction'),
      _ExpectedDeclaration.functionTypeAlias('MyFunctionTypeAlias'),
      _ExpectedDeclaration.mixin('MyMixin'),
      _ExpectedDeclaration.variable('myVariable1'),
      _ExpectedDeclaration.variable('myVariable2'),
    ], uriStr: 'package:test/test.dart');
  }

  test_parts() async {
    newFile('/home/test/lib/a.dart', content: r'''
part of 'test.dart';
class A {}
''');
    newFile('/home/test/lib/b.dart', content: r'''
part of 'test.dart';
class B {}
''');
    newFile('/home/test/lib/test.dart', content: r'''
part 'a.dart';
part 'b.dart';
class C {}
''');
    tracker.addContext(testAnalysisContext);

    await _doAllTrackerWork();
    _assertLibraryDeclarations([
      _ExpectedDeclaration.class_('A'),
      _ExpectedDeclaration.class_('B'),
      _ExpectedDeclaration.class_('C'),
    ], uriStr: 'package:test/test.dart');
  }

  test_publicOnly() async {
    newFile('/home/test/lib/a.dart', content: r'''
part of 'test.dart';
class A {}
class _A {}
''');
    newFile('/home/test/lib/test.dart', content: r'''
part 'a.dart';
class B {}
class _B {}
''');
    tracker.addContext(testAnalysisContext);

    await _doAllTrackerWork();
    _assertLibraryDeclarations([
      _ExpectedDeclaration.class_('A'),
      _ExpectedDeclaration.class_('B'),
    ], uriStr: 'package:test/test.dart');
  }

  test_readByteStore() async {
    newFile('/home/test/lib/a.dart', content: r'''
class A {}
''');
    newFile('/home/test/lib/b.dart', content: r'''
class B {}
''');
    newFile('/home/test/lib/test.dart', content: r'''
export 'a.dart' show A;
part 'b.dart';
class C {}
''');

    // The byte store is empty, fill it.
    tracker.addContext(testAnalysisContext);
    await _doAllTrackerWork();

    // Re-create tracker, will read from byte store.
    _createTracker();
    tracker.addContext(testAnalysisContext);
    await _doAllTrackerWork();

    _assertLibraryDeclarations([
      _ExpectedDeclaration.class_('A'),
      _ExpectedDeclaration.class_('B'),
      _ExpectedDeclaration.class_('C'),
    ], uriStr: 'package:test/test.dart');
  }

  test_removeContext_afterAddContext() async {
    newFile('/home/test/lib/test.dart', content: r'''
class A {}
''');

    // No libraries initially.
    expect(uriToLibrary, isEmpty);

    // Add the context, and remove it immediately.
    tracker.addContext(testAnalysisContext);
    tracker.removeContext(testAnalysisContext);

    // There is no work to do.
    expect(tracker.hasWork, isFalse);
    await _doAllTrackerWork();

    // So, there are no new libraries.
    expect(uriToLibrary, isEmpty);
  }

  void _assertLibraryDeclarations(
      List<_ExpectedDeclaration> expectedDeclarations,
      {String uriStr}) {
    var library = uriToLibrary[uriStr];
    expect(library, isNotNull);
    expect(library.declarations, hasLength(expectedDeclarations.length));
    for (var expected in expectedDeclarations) {
      expect(
        library.declarations,
        contains(predicate((Declaration d) {
          return d.name == expected.name && d.kind == expected.kind;
        })),
        reason: '$expected',
      );
    }
  }

  void _assertNoLibrary(String uriStr) {
    expect(uriToLibrary, isNot(contains(uriStr)));
  }

  void _createTracker() {
    uriToLibrary.clear();

    tracker = DeclarationsTracker(byteStore, resourceProvider);
    tracker.changes.listen((change) {
      for (var library in change.changed) {
        var uriStr = library.uri.toString();
        idToLibrary[library.id] = library;
        uriToLibrary[uriStr] = library;
      }
      idToLibrary.removeWhere((uriStr, library) {
        return change.removed.contains(library.id);
      });
      uriToLibrary.removeWhere((uriStr, library) {
        return change.removed.contains(library.id);
      });
    });
  }

  Future<void> _doAllTrackerWork() async {
    while (tracker.hasWork) {
      tracker.doWork();
    }
    await pumpEventQueue();
  }

  static Future pumpEventQueue([int times = 5000]) {
    if (times == 0) return new Future.value();
    return new Future.delayed(Duration.zero, () => pumpEventQueue(times - 1));
  }
}

//class _ExpectedLibrary {
//  final Uri uri;
//  final String path;
//}

class _ExpectedDeclaration {
  final String name;
  final DeclarationKind kind;

  _ExpectedDeclaration(this.name, this.kind);

  _ExpectedDeclaration.class_(String name) : this(name, DeclarationKind.CLASS);

  _ExpectedDeclaration.classTypeAlias(String name)
      : this(name, DeclarationKind.CLASS_TYPE_ALIAS);

  _ExpectedDeclaration.enum_(String name) : this(name, DeclarationKind.ENUM);

  _ExpectedDeclaration.function(String name)
      : this(name, DeclarationKind.FUNCTION);

  _ExpectedDeclaration.functionTypeAlias(String name)
      : this(name, DeclarationKind.FUNCTION_TYPE_ALIAS);

  _ExpectedDeclaration.mixin(String name) : this(name, DeclarationKind.MIXIN);

  _ExpectedDeclaration.variable(String name)
      : this(name, DeclarationKind.VARIABLE);

  @override
  String toString() {
    return '($name, $kind)';
  }
}
