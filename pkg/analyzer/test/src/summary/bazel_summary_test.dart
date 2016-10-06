// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/context/cache.dart';
import 'package:analyzer/src/dart/scanner/reader.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/bazel_summary.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/summarize_ast.dart';
import 'package:analyzer/src/summary/summarize_elements.dart';
import 'package:analyzer/src/util/fast_uri.dart';
import 'package:analyzer/task/dart.dart';
import 'package:path/path.dart' as pathos;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../context/abstract_context.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BazelResultProviderTest);
    defineReflectiveTests(SummaryProviderTest);
  });
}

const OUT_ROOT = '$SRC_ROOT/bazel-bin';
const SRC_ROOT = '/company/src/user/project/root';

@reflectiveTest
class BazelResultProviderTest extends _BaseTest {
  BazelResultProvider provider;

  @override
  void setUp() {
    super.setUp();
    provider = new BazelResultProvider(new SummaryProvider(
        resourceProvider,
        '_.temp',
        _getOutputFolder,
        resourceProvider.getFolder('/tmp/dart/bazel/linked'),
        context));
  }

  test_failure_inconsistent_directDependency() {
    _setComponentFile('aaa', 'a.dart', 'class A {}');
    _setComponentFile(
        'bbb',
        'b.dart',
        r'''
import 'package:components.aaa/a.dart';
class B extends A {}
''');
    _writeUnlinkedBundle('components.aaa');
    _writeUnlinkedBundle('components.bbb');
    _setComponentFile('aaa', 'a.dart', 'class A2 {}');
    // The 'aaa' unlinked bundle in inconsistent, so 'bbb' linking fails.
    Source source = _resolveUri('package:components.bbb/b.dart');
    CacheEntry entry = context.getCacheEntry(source);
    expect(provider.compute(entry, LIBRARY_ELEMENT), isFalse);
  }

  test_failure_missingDirectDependency() {
    _setComponentFile('aaa', 'a.dart', 'class A {}');
    _setComponentFile(
        'bbb',
        'b.dart',
        r'''
import 'package:components.aaa/a.dart';
class B extends A {}
''');
    _writeUnlinkedBundle('components.bbb');
    // We cannot find 'aaa' bundle, so 'bbb' linking fails.
    Source source = _resolveUri('package:components.bbb/b.dart');
    CacheEntry entry = context.getCacheEntry(source);
    expect(provider.compute(entry, LIBRARY_ELEMENT), isFalse);
  }

  test_success_withoutDependencies() {
    _setComponentFile('aaa', 'a.dart', 'class A {}');
    _writeUnlinkedBundle('components.aaa');
    // Resynthesize 'aaa' library.
    Source source = _resolveUri('package:components.aaa/a.dart');
    LibraryElement library = _resynthesizeLibrary(source);
    List<ClassElement> types = library.definingCompilationUnit.types;
    expect(types, hasLength(1));
    expect(types.single.name, 'A');
  }

  test_withDependency_import() {
    _setComponentFile('aaa', 'a.dart', 'class A {}');
    _setComponentFile(
        'bbb',
        'b.dart',
        r'''
import 'package:components.aaa/a.dart';
class B extends A {}
''');
    _writeUnlinkedBundle('components.aaa');
    _writeUnlinkedBundle('components.bbb');
    // Prepare sources.
    Source sourceA = _resolveUri('package:components.aaa/a.dart');
    Source sourceB = _resolveUri('package:components.bbb/b.dart');
    // Resynthesize 'bbb' library.
    LibraryElement libraryB = _resynthesizeLibrary(sourceB);
    List<ClassElement> types = libraryB.definingCompilationUnit.types;
    expect(types, hasLength(1));
    ClassElement typeB = types.single;
    expect(typeB.name, 'B');
    expect(typeB.supertype.name, 'A');
    // The LibraryElement for 'aaa' is not created at all.
    expect(context.getResult(sourceA, LIBRARY_ELEMENT), isNull);
    // But we can resynthesize it, and it's the same as from 'bbb'.
    expect(provider.compute(context.getCacheEntry(sourceA), LIBRARY_ELEMENT),
        isTrue);
    LibraryElement libraryA = context.getResult(sourceA, LIBRARY_ELEMENT);
    expect(libraryA, isNotNull);
    expect(typeB.supertype.element.library, same(libraryA));
  }

  LibraryElement _resynthesizeLibrary(Source source) {
    CacheEntry entry = context.getCacheEntry(source);
    expect(provider.compute(entry, LIBRARY_ELEMENT), isTrue);
    return context.getResult(source, LIBRARY_ELEMENT);
  }
}

@reflectiveTest
class SummaryProviderTest extends _BaseTest {
  SummaryProvider manager;

  @override
  void setUp() {
    super.setUp();
    _createManager();
  }

  test_getLinkedPackages_cached() {
    _setComponentFile('aaa', 'a.dart', 'class A {}');
    _setComponentFile(
        'bbb',
        'b.dart',
        r'''
import 'package:components.aaa/a.dart';
class B extends A {}
''');
    _writeUnlinkedBundle('components.aaa');
    _writeUnlinkedBundle('components.bbb');
    Source source = _resolveUri('package:components.bbb/b.dart');

    // Session 1.
    // Create linked bundles and store them in files.
    {
      List<Package> packages = manager.getLinkedPackages(source);
      expect(packages, hasLength(2));
    }

    // Session 2.
    // Recreate manager (with disabled linking) and ask again.
    {
      _createManager(allowLinking: false);
      List<Package> packages = manager.getLinkedPackages(source);
      expect(packages, hasLength(2));
    }
  }

  test_getLinkedPackages_cached_declaredVariables_export() {
    _testImpl_getLinkedPackages_cached_declaredVariables('export');
  }

  test_getLinkedPackages_cached_declaredVariables_import() {
    _testImpl_getLinkedPackages_cached_declaredVariables('import');
  }

  test_getLinkedPackages_null_inconsistent_directDependency() {
    _setComponentFile('aaa', 'a.dart', 'class A {}');
    _setComponentFile(
        'bbb',
        'b.dart',
        r'''
import 'package:components.aaa/a.dart';
class B extends A {}
''');
    _writeUnlinkedBundle('components.aaa');
    _writeUnlinkedBundle('components.bbb');
    _setComponentFile('aaa', 'a.dart', 'class A2 {}');
    // The 'aaa' unlinked bundle in inconsistent, so 'bbb' linking fails.
    Source source = _resolveUri('package:components.bbb/b.dart');
    List<Package> packages = manager.getLinkedPackages(source);
    expect(packages, isNull);
  }

  test_getLinkedPackages_null_missingBundle() {
    _setComponentFile('aaa', 'a.dart', 'class A {}');
    // We don't write 'aaa', so we cannot get its package.
    // Ask the package for the URI.
    Source source = _resolveUri('package:components.aaa/a.dart');
    List<Package> packages = manager.getLinkedPackages(source);
    expect(packages, isNull);
  }

  test_getLinkedPackages_null_missingDirectDependency() {
    _setComponentFile('aaa', 'a.dart', 'class A {}');
    _setComponentFile(
        'bbb',
        'b.dart',
        r'''
import 'package:components.aaa/a.dart';
class B extends A {}
''');
    _writeUnlinkedBundle('components.bbb');
    // We cannot find 'aaa' bundle, so 'bbb' linking fails.
    Source source = _resolveUri('package:components.bbb/b.dart');
    List<Package> packages = manager.getLinkedPackages(source);
    expect(packages, isNull);
  }

  test_getLinkedPackages_null_missingIndirectDependency() {
    _setComponentFile('aaa', 'a.dart', 'class A {}');
    _setComponentFile(
        'bbb',
        'b.dart',
        r'''
import 'package:components.aaa/a.dart';
class B extends A {}
''');
    _setComponentFile(
        'ccc',
        'c.dart',
        r'''
import 'package:components.bbb/b.dart';
class C extends B {}
''');
    _writeUnlinkedBundle('components.bbb');
    _writeUnlinkedBundle('components.ccc');
    // We cannot find 'aaa' bundle, so 'ccc' linking fails.
    Source source = _resolveUri('package:components.ccc/c.dart');
    List<Package> packages = manager.getLinkedPackages(source);
    expect(packages, isNull);
  }

  test_getLinkedPackages_withDependency_export() {
    _setComponentFile('aaa', 'a.dart', 'class A {}');
    _setComponentFile(
        'bbb',
        'b.dart',
        r'''
export 'package:components.aaa/a.dart';
''');
    _writeUnlinkedBundle('components.aaa');
    _writeUnlinkedBundle('components.bbb');
    Source source = _resolveUri('package:components.bbb/b.dart');
    List<Package> packages = manager.getLinkedPackages(source);
    expect(packages, hasLength(2));
  }

  test_getLinkedPackages_withDependency_import() {
    _setComponentFile('aaa', 'a.dart', 'class A {}');
    _setComponentFile(
        'bbb',
        'b.dart',
        r'''
import 'package:components.aaa/a.dart';
class B extends A {}
''');
    _writeUnlinkedBundle('components.aaa');
    _writeUnlinkedBundle('components.bbb');
    Source source = _resolveUri('package:components.bbb/b.dart');
    List<Package> packages = manager.getLinkedPackages(source);
    expect(packages, hasLength(2));
  }

  test_getLinkedPackages_withDependency_import_cycle() {
    _setComponentFile(
        'aaa',
        'a.dart',
        r'''
import 'package:components.bbb/b.dart';
class A {}
class A2 extends B {}
''');
    _setComponentFile(
        'bbb',
        'b.dart',
        r'''
import 'package:components.aaa/a.dart';
class B extends A {}
class B2 extends A2 {}
''');
    _writeUnlinkedBundle('components.aaa');
    _writeUnlinkedBundle('components.bbb');
    Source source = _resolveUri('package:components.bbb/b.dart');
    List<Package> packages = manager.getLinkedPackages(source);
    expect(packages, hasLength(2));
  }

  test_getLinkedPackages_withDependency_import_indirect() {
    _setComponentFile('aaa', 'a.dart', 'class A {}');
    _setComponentFile(
        'bbb',
        'b.dart',
        r'''
import 'package:components.aaa/a.dart';
class B extends A {}
''');
    _setComponentFile(
        'ccc',
        'c.dart',
        r'''
import 'package:components.bbb/b.dart';
class C extends B {}
''');
    _writeUnlinkedBundle('components.aaa');
    _writeUnlinkedBundle('components.bbb');
    _writeUnlinkedBundle('components.ccc');
    Source source = _resolveUri('package:components.ccc/c.dart');
    List<Package> packages = manager.getLinkedPackages(source);
    expect(packages, hasLength(3));
  }

  test_getLinkedPackages_withoutDependencies() {
    _setComponentFile('aaa', 'a.dart', 'class A {}');
    _writeUnlinkedBundle('components.aaa');
    // Ask the package for the URI.
    Source source = _resolveUri('package:components.aaa/a.dart');
    List<Package> packages = manager.getLinkedPackages(source);
    expect(packages, hasLength(1));
  }

  test_getUnlinkedForUri() {
    _setComponentFile('aaa', 'a1.dart', 'class A1 {}');
    _setComponentFile('aaa', 'a2.dart', 'class A2 {}');
    _writeUnlinkedBundle('components.aaa');
    // Ask the package for the URI.
    Source source1 = _resolveUri('package:components.aaa/a1.dart');
    Source source2 = _resolveUri('package:components.aaa/a2.dart');
    Package package = manager.getUnlinkedForUri(source1.uri);
    expect(package, isNotNull);
    // The same instance is returned to another URI in the same package.
    expect(manager.getUnlinkedForUri(source2.uri), same(package));
  }

  test_getUnlinkedForUri_inconsistent_fileContent() {
    File file1 = _setComponentFile('aaa', 'a1.dart', 'class A1 {}');
    _setComponentFile('aaa', 'a2.dart', 'class A2 {}');
    _writeUnlinkedBundle('components.aaa');
    // Update one of the files, so the bundle is not consistent.
    file1.writeAsStringSync('\nclass A1 {}');
    Source source1 = _resolveUri('package:components.aaa/a1.dart');
    Source source2 = _resolveUri('package:components.aaa/a2.dart');
    expect(manager.getUnlinkedForUri(source1.uri), isNull);
    expect(manager.getUnlinkedForUri(source2.uri), isNull);
  }

  test_getUnlinkedForUri_inconsistent_majorVersion() {
    _setComponentFile('aaa', 'a.dart', 'class A {}');
    _writeUnlinkedBundle('components.aaa');
    Source source = _resolveUri('package:components.aaa/a.dart');

    // Create manager with a different major version.
    // The unlinked bundle cannot be used.
    _createManager(majorVersion: 12345);
    Package package = manager.getUnlinkedForUri(source.uri);
    expect(package, isNull);
  }

  void _createManager(
      {bool allowLinking: true,
      int majorVersion: PackageBundleAssembler.currentMajorVersion}) {
    manager = new SummaryProvider(resourceProvider, '_.temp', _getOutputFolder,
        resourceProvider.getFolder('/tmp/dart/bazel/linked'), context,
        allowLinking: allowLinking, majorVersion: majorVersion);
  }

  void _testImpl_getLinkedPackages_cached_declaredVariables(
      String importOrExport) {
    _setComponentFile(
        'aaa',
        'user.dart',
        '''
    $importOrExport 'foo.dart'
      if (dart.library.io) 'foo_io.dart'
      if (dart.library.html) 'foo_html.dart';
    ''');
    _setComponentFile('aaa', 'foo.dart', 'class B {}');
    _setComponentFile('aaa', 'foo_io.dart', 'class B {}');
    _setComponentFile('aaa', 'foo_dart.dart', 'class B {}');
    _writeUnlinkedBundle('components.aaa');
    Source source = _resolveUri('package:components.aaa/user.dart');

    void _assertDependencyInUser(PackageBundle bundle, String shortName) {
      for (var i = 0; i < bundle.linkedLibraryUris.length; i++) {
        if (bundle.linkedLibraryUris[i].endsWith('user.dart')) {
          LinkedLibrary library = bundle.linkedLibraries[i];
          expect(library.dependencies.map((d) => d.uri),
              unorderedEquals(['', 'dart:core', shortName]));
          return;
        }
      }
      fail('Not found user.dart in $bundle');
    }

    // Session 1.
    // Create linked bundles and store them in files.
    {
      List<Package> packages = manager.getLinkedPackages(source);
      expect(packages, hasLength(1));
      _assertDependencyInUser(packages.single.linked, 'foo.dart');
    }

    // Session 2.
    // Recreate manager and don't allow it to perform new linking.
    // Set a declared variable, which is not used in the package.
    // We still can get the cached linked bundle.
    {
      context.declaredVariables.define('not.used.variable', 'baz');
      _createManager(allowLinking: false);
      List<Package> packages = manager.getLinkedPackages(source);
      expect(packages, hasLength(1));
      _assertDependencyInUser(packages.single.linked, 'foo.dart');
    }

    // Session 3.
    // Recreate manager and don't allow it to perform new linking.
    // Set the value of a referenced declared variable.
    // So, we cannot use the previously cached linked bundle.
    {
      context.declaredVariables.define('dart.library.io', 'does-not-matter');
      _createManager(allowLinking: false);
      List<Package> packages = manager.getLinkedPackages(source);
      expect(packages, isEmpty);
    }

    // Session 4.
    // Enable new linking, and configure to use 'foo_html.dart'.
    {
      context.declaredVariables.define('dart.library.html', 'true');
      _createManager(allowLinking: true);
      List<Package> packages = manager.getLinkedPackages(source);
      expect(packages, hasLength(1));
      _assertDependencyInUser(packages.single.linked, 'foo_html.dart');
    }
  }
}

class _BaseTest extends AbstractContextTest {
  @override
  void setUp() {
    super.setUp();
    // Include a 'package' URI resolver.
    sourceFactory = new SourceFactory(<UriResolver>[
      sdkResolver,
      resourceResolver,
      new _TestPackageResolver(resourceProvider)
    ], null, resourceProvider);
    context.sourceFactory = sourceFactory;
  }

  Folder _getOutputFolder(Uri absoluteUri) {
    if (absoluteUri.scheme == 'package') {
      List<String> segments = absoluteUri.pathSegments;
      if (segments.isNotEmpty) {
        String packageName = segments.first;
        String path = OUT_ROOT + '/' + packageName.replaceAll('.', '/');
        return resourceProvider.getFolder(path);
      }
    }
    return null;
  }

  Source _resolveUri(String uri) {
    return context.sourceFactory.resolveUri(null, uri);
  }

  File _setComponentFile(String componentName, String fileName, String code) {
    String path = '$SRC_ROOT/components/$componentName/lib/$fileName';
    return resourceProvider.newFile(path, code);
  }

  void _writeUnlinkedBundle(String packageName) {
    String packagePath = packageName.replaceAll('.', '/');
    PackageBundleBuilder unlinkedBundle = _computeUnlinkedBundle(
        resourceProvider,
        packageName,
        resourceProvider.getFolder(SRC_ROOT + '/' + packagePath + '/lib'),
        true);
    String shortName = packageName.substring(packageName.lastIndexOf('.') + 1);
    resourceProvider.newFileWithBytes(
        '$OUT_ROOT/$packagePath/$shortName.full.ds', unlinkedBundle.toBuffer());
  }

  static PackageBundleBuilder _computeUnlinkedBundle(ResourceProvider provider,
      String packageName, Folder libFolder, bool strong) {
    var pathContext = provider.pathContext;
    String libPath = libFolder.path + pathContext.separator;
    PackageBundleAssembler assembler = new PackageBundleAssembler();

    /**
     * Return the `package` [Uri] for the given [path] in the `lib` folder
     * of the current package.
     */
    Uri getUri(String path) {
      String pathInLib = path.substring(libPath.length);
      String uriPath = pathos.posix.joinAll(pathContext.split(pathInLib));
      String uriStr = 'package:$packageName/$uriPath';
      return FastUri.parse(uriStr);
    }

    /**
     * If the given [file] is a Dart file, add its unlinked unit.
     */
    void addDartFile(File file) {
      String path = file.path;
      if (AnalysisEngine.isDartFileName(path)) {
        Uri uri = getUri(path);
        Source source = file.createSource(uri);
        CompilationUnit unit = _parse(source, strong);
        UnlinkedUnitBuilder unlinkedUnit = serializeAstUnlinked(unit);
        assembler.addUnlinkedUnit(source, unlinkedUnit);
      }
    }

    /**
     * Visit the [folder] recursively.
     */
    void addDartFiles(Folder folder) {
      List<Resource> children = folder.getChildren();
      for (Resource child in children) {
        if (child is File) {
          addDartFile(child);
        }
      }
      for (Resource child in children) {
        if (child is Folder) {
          addDartFiles(child);
        }
      }
    }

    addDartFiles(libFolder);
    return assembler.assemble();
  }

  /**
   * Parse the given [source] into AST.
   */
  static CompilationUnit _parse(Source source, bool strong) {
    String code = source.contents.data;
    AnalysisErrorListener errorListener = AnalysisErrorListener.NULL_LISTENER;
    CharSequenceReader reader = new CharSequenceReader(code);
    Scanner scanner = new Scanner(source, reader, errorListener);
    scanner.scanGenericMethodComments = strong;
    Token token = scanner.tokenize();
    LineInfo lineInfo = new LineInfo(scanner.lineStarts);
    Parser parser = new Parser(source, errorListener);
    parser.parseGenericMethodComments = strong;
    CompilationUnit unit = parser.parseCompilationUnit(token);
    unit.lineInfo = lineInfo;
    return unit;
  }
}

class _TestPackageResolver implements UriResolver {
  final ResourceProvider resourceProvider;

  _TestPackageResolver(this.resourceProvider);

  @override
  Source resolveAbsolute(Uri uri, [Uri actualUri]) {
    if (uri.scheme == 'package') {
      List<String> segments = uri.pathSegments;
      if (segments.isNotEmpty) {
        pathos.Context pathContext = resourceProvider.pathContext;
        String packageName = segments.first;
        String folderPath = pathContext.join(
            SRC_ROOT, packageName.replaceAll('.', pathContext.separator));
        String path = pathContext.join(
            folderPath, 'lib', pathContext.joinAll(segments.skip(1)));
        return resourceProvider.getFile(path).createSource(uri);
      }
    }
    return null;
  }

  @override
  Uri restoreAbsolute(Source source) {
    throw new UnimplementedError();
  }
}
