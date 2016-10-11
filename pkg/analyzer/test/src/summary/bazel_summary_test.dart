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
    manager = new SummaryProvider(resourceProvider, _getOutputPath, context);
  }

  test_getPackageForUri() {
    String pathA = '$SRC_ROOT/components/aaa/lib';
    resourceProvider.newFile(
        '$pathA/a1.dart',
        r'''
class A1 {}
''');
    resourceProvider.newFile(
        '$pathA/a2.dart',
        r'''
class A2 {}
''');
    _writeUnlinkedBundle('components.aaa');
    // Ask the package for the URI.
    Source source1 = _resolveUri('package:components.aaa/a1.dart');
    Source source2 = _resolveUri('package:components.aaa/a2.dart');
    Package package = manager.getPackageForUri(source1.uri);
    expect(package, isNotNull);
    // The same instance is returned to another URI in the same package.
    expect(manager.getPackageForUri(source2.uri), same(package));
  }

  test_getPackageForUri_inconsistent() {
    String pathA = '$SRC_ROOT/components/aaa/lib';
    File fileA1 = resourceProvider.newFile(
        '$pathA/a1.dart',
        r'''
class A1 {}
''');
    resourceProvider.newFile(
        '$pathA/a2.dart',
        r'''
class A2 {}
''');
    _writeUnlinkedBundle('components.aaa');
    // Update one of the files file, so the bundle is not consistent.
    fileA1.writeAsStringSync('// different');
    Source source1 = _resolveUri('package:components.aaa/a1.dart');
    Source source2 = _resolveUri('package:components.aaa/a2.dart');
    expect(manager.getPackageForUri(source1.uri), isNull);
    expect(manager.getPackageForUri(source2.uri), isNull);
  }

  Source _resolveUri(String uri) {
    return context.sourceFactory.resolveUri(null, uri);
  }

  void _writeUnlinkedBundle(String packageName) {
    String packagePath = packageName.replaceAll('.', '/');
    var unlinkedBundle = _computeUnlinkedBundle(
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

  static String _getOutputPath(ResourceProvider provider, Uri uri) {
    if (uri.scheme == 'package') {
      List<String> segments = uri.pathSegments;
      if (segments.isNotEmpty) {
        String packageName = segments.first;
        return OUT_ROOT + '/' + packageName.replaceAll('.', '/');
      }
    }
    return null;
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
