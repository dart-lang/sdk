// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'compiler_helper.dart';
import 'parser_helper.dart';

void checkPosition(Spannable spannable, Node node, String source, compiler) {
  SourceSpan span = compiler.spanFromSpannable(spannable);
  Expect.isTrue(span.begin < span.end,
                'begin = ${span.begin}; end = ${span.end}');
  Expect.isTrue(span.end < source.length,
                'end = ${span.end}; length = ${source.length}');
  String yield = source.substring(span.begin, span.end);

  // TODO(ahe): The node does not include "@". Fix that.
  Expect.stringEquals('@$node', yield);
}

void checkAnnotation(String name, String declaration,
                     {bool isTopLevelOnly: false}) {
  var source;

  // Ensure that a compile-time constant can be resolved from an
  // annotation.
  source = """const native = 'xyz';
              @native
              $declaration
              main() {}""";

  compileAndCheck(source, name, (compiler, element) {
    compiler.enqueuer.resolution.queueIsClosed = false;
    Expect.equals(1, length(element.metadata));
    PartialMetadataAnnotation annotation = element.metadata.head;
    annotation.ensureResolved(compiler);
    Constant value = annotation.value;
    Expect.stringEquals('xyz', value.value.slowToString());

    checkPosition(annotation, annotation.cachedNode, source, compiler);
  });

  // Ensure that each repeated annotation has a unique instance of
  // [MetadataAnnotation].
  source = """const native = 'xyz';
              @native @native
              $declaration
              main() {}""";

  compileAndCheck(source, name, (compiler, element) {
    compiler.enqueuer.resolution.queueIsClosed = false;
    Expect.equals(2, length(element.metadata));
    PartialMetadataAnnotation annotation1 = element.metadata.head;
    PartialMetadataAnnotation annotation2 = element.metadata.tail.head;
    annotation1.ensureResolved(compiler);
    annotation2.ensureResolved(compiler);
    Expect.isFalse(identical(annotation1, annotation2),
                   'expected unique instances');
    Expect.notEquals(annotation1, annotation2, 'expected unequal instances');
    Constant value1 = annotation1.value;
    Constant value2 = annotation2.value;
    Expect.identical(value1, value2, 'expected same compile-time constant');
    Expect.stringEquals('xyz', value1.value.slowToString());
    Expect.stringEquals('xyz', value2.value.slowToString());

    checkPosition(annotation1, annotation1.cachedNode, source, compiler);
    checkPosition(annotation2, annotation2.cachedNode, source, compiler);
  });

  if (isTopLevelOnly) return;

  // Ensure that a compile-time constant can be resolved from an
  // annotation.
  source = """const native = 'xyz';
              class Foo {
                @native
                $declaration
              }
              main() {}""";

  compileAndCheck(source, 'Foo', (compiler, element) {
    compiler.enqueuer.resolution.queueIsClosed = false;
    Expect.equals(0, length(element.metadata));
    element.ensureResolved(compiler);
    Expect.equals(0, length(element.metadata));
    element = element.lookupLocalMember(buildSourceString(name));
    Expect.equals(1, length(element.metadata));
    PartialMetadataAnnotation annotation = element.metadata.head;
    annotation.ensureResolved(compiler);
    Constant value = annotation.value;
    Expect.stringEquals('xyz', value.value.slowToString());

    checkPosition(annotation, annotation.cachedNode, source, compiler);
  });

  // Ensure that each repeated annotation has a unique instance of
  // [MetadataAnnotation].
  source = """const native = 'xyz';
              class Foo {
                @native @native
                $declaration
              }
              main() {}""";

  compileAndCheck(source, 'Foo', (compiler, element) {
    compiler.enqueuer.resolution.queueIsClosed = false;
    Expect.equals(0, length(element.metadata));
    element.ensureResolved(compiler);
    Expect.equals(0, length(element.metadata));
    element = element.lookupLocalMember(buildSourceString(name));
    Expect.equals(2, length(element.metadata));
    PartialMetadataAnnotation annotation1 = element.metadata.head;
    PartialMetadataAnnotation annotation2 = element.metadata.tail.head;
    annotation1.ensureResolved(compiler);
    annotation2.ensureResolved(compiler);
    Expect.isFalse(identical(annotation1, annotation2),
                   'expected unique instances');
    Expect.notEquals(annotation1, annotation2, 'expected unequal instances');
    Constant value1 = annotation1.value;
    Constant value2 = annotation2.value;
    Expect.identical(value1, value2, 'expected same compile-time constant');
    Expect.stringEquals('xyz', value1.value.slowToString());
    Expect.stringEquals('xyz', value2.value.slowToString());

    checkPosition(annotation1, annotation1.cachedNode, source, compiler);
    checkPosition(annotation1, annotation2.cachedNode, source, compiler);
  });
}

void testClassMetadata() {
  checkAnnotation('Foo', 'class Foo {}', isTopLevelOnly: true);
}

void testTopLevelMethodMetadata() {
  checkAnnotation('foo', 'foo() {}');
}

void testTopLevelFieldMetadata() {
  checkAnnotation('foo', 'var foo;');
}

void testLibraryTags() {
  void compileAndCheckLibrary(
      String source,
      Link<MetadataAnnotation> extractMetadata(LibraryElement element)) {
    Uri partUri = new Uri.fromComponents(scheme: 'source', path: 'part.dart');
    String partSource = '@native part of foo;';

    Uri libUri = new Uri.fromComponents(scheme: 'source', path: 'lib.dart');
    String libSource = 'library lib;';

    Uri uri = new Uri.fromComponents(scheme: 'source', path: 'main.dart');

    Uri async = new Uri.fromComponents(scheme: 'dart', path: 'async');

    var compiler = compilerFor(source, uri)
        ..registerSource(partUri, partSource)
        ..registerSource(libUri, libSource)
        ..registerSource(async, 'class DeferredLibrary {}')
        ..runCompiler(uri);
    compiler.enqueuer.resolution.queueIsClosed = false;
    LibraryElement element = compiler.libraries['$uri'];
    Expect.isNotNull(element, 'Cannot find $uri');

    Link<MetadataAnnotation> metadata = extractMetadata(element);
    Expect.equals(1, length(metadata));

    PartialMetadataAnnotation annotation = metadata.head;
    annotation.ensureResolved(compiler);
    Constant value = annotation.value;
    Expect.stringEquals('xyz', value.value.slowToString());

    checkPosition(annotation, annotation.cachedNode, source, compiler);
  }

  var source;

  source = """@native
              library foo;
              const native = 'xyz';
              main() {}""";
  compileAndCheckLibrary(source, (e) => e.libraryTag.metadata);

  source = """@native
              import 'lib.dart';
              const native = 'xyz';
              main() {}""";
  compileAndCheckLibrary(source, (e) => e.tags.single.metadata);

  source = """@native
              export 'lib.dart';
              const native = 'xyz';
              main() {}""";
  compileAndCheckLibrary(source, (e) => e.tags.single.metadata);

  source = """@native
              part 'part.dart';
              const native = 'xyz';
              main() {}""";
  compileAndCheckLibrary(source, (e) => e.tags.single.metadata);

  source = """@native
              part 'part.dart';
              const native = 'xyz';
              main() {}""";
  compileAndCheckLibrary(source,
                         (e) => e.compilationUnits.first.partTag.metadata);
}

void main() {
  testClassMetadata();
  testTopLevelMethodMetadata();
  testTopLevelFieldMetadata();
  testLibraryTags();
}
