// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/scanner/reader.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/bazel_summary.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/summarize_ast.dart';
import 'package:analyzer/src/summary/summarize_elements.dart';
import 'package:analyzer/src/util/fast_uri.dart';
import 'package:path/path.dart' as pathos;
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:unittest/unittest.dart';

import '../../utils.dart';
import '../context/abstract_context.dart';

main() {
  initializeTestEnvironment();
  defineReflectiveTests(SummaryProviderTest);
}

const OUT_ROOT = '$SRC_ROOT/bazel-bin';
const SRC_ROOT = '/company/src/user/project/root';

@reflectiveTest
class SummaryProviderTest extends AbstractContextTest {
  SummaryProvider manager;

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
    // Create a new SummaryProvider instance.
    manager = new SummaryProvider(resourceProvider, _getOutputFolder, context);
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

  test_getUnlinkedForUri_inconsistent() {
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
