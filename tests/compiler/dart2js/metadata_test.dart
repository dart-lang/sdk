// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/constants/values.dart' show PrimitiveConstantValue;
import 'package:expect/expect.dart';
import 'compiler_helper.dart';
import 'package:compiler/src/parser/partial_elements.dart'
    show PartialMetadataAnnotation;
import 'package:compiler/src/diagnostics/diagnostic_listener.dart'
    show DiagnosticReporter;

void checkPosition(Spannable spannable, Node node, String source,
    DiagnosticReporter reporter) {
  SourceSpan span = reporter.spanFromSpannable(spannable);
  Expect.isTrue(
      span.begin < span.end, 'begin = ${span.begin}; end = ${span.end}');
  Expect.isTrue(
      span.end < source.length, 'end = ${span.end}; length = ${source.length}');
  String yield = source.substring(span.begin, span.end);

  // TODO(ahe): The node does not include "@". Fix that.
  Expect.stringEquals('@$node', yield);
}

void checkAnnotation(String name, String declaration,
    {bool isTopLevelOnly: false}) {
  // Ensure that a compile-time constant can be resolved from an
  // annotation.
  var source1 = """const native = 'xyz';
                   @native
                   $declaration
                   main() {}""";

  analyzeAndCheck(source1, name, (compiler, element) {
    compiler.enqueuer.resolution.queueIsClosed = false;
    Expect.equals(
        1, element.metadata.length, 'Unexpected metadata count on $element.');
    PartialMetadataAnnotation annotation = element.metadata.first;
    annotation.ensureResolved(compiler.resolution);
    PrimitiveConstantValue value =
        compiler.constants.getConstantValue(annotation.constant);
    Expect.stringEquals('xyz', value.primitiveValue);

    checkPosition(
        annotation, annotation.cachedNode, source1, compiler.reporter);
  });

  // Ensure that each repeated annotation has a unique instance of
  // [MetadataAnnotation].
  var source2 = """const native = 'xyz';
                   @native @native
                   $declaration
                   main() {}""";

  analyzeAndCheck(source2, name, (compiler, element) {
    compiler.enqueuer.resolution.queueIsClosed = false;
    Expect.equals(2, element.metadata.length);
    PartialMetadataAnnotation annotation1 = element.metadata.elementAt(0);
    PartialMetadataAnnotation annotation2 = element.metadata.elementAt(1);
    annotation1.ensureResolved(compiler.resolution);
    annotation2.ensureResolved(compiler.resolution);
    Expect.isFalse(
        identical(annotation1, annotation2), 'expected unique instances');
    Expect.notEquals(annotation1, annotation2, 'expected unequal instances');
    PrimitiveConstantValue value1 =
        compiler.constants.getConstantValue(annotation1.constant);
    PrimitiveConstantValue value2 =
        compiler.constants.getConstantValue(annotation2.constant);
    Expect.identical(value1, value2, 'expected same compile-time constant');
    Expect.stringEquals('xyz', value1.primitiveValue);
    Expect.stringEquals('xyz', value2.primitiveValue);

    checkPosition(
        annotation1, annotation1.cachedNode, source2, compiler.reporter);
    checkPosition(
        annotation2, annotation2.cachedNode, source2, compiler.reporter);
  });

  if (isTopLevelOnly) return;

  // Ensure that a compile-time constant can be resolved from an
  // annotation.
  var source3 = """const native = 'xyz';
                   class Foo {
                     @native
                     $declaration
                   }
                   main() {}""";

  analyzeAndCheck(source3, 'Foo', (compiler, element) {
    compiler.enqueuer.resolution.queueIsClosed = false;
    Expect.equals(0, element.metadata.length);
    element.ensureResolved(compiler.resolution);
    Expect.equals(0, element.metadata.length);
    element = element.lookupLocalMember(name);
    Expect.equals(1, element.metadata.length);
    PartialMetadataAnnotation annotation = element.metadata.first;
    annotation.ensureResolved(compiler.resolution);
    PrimitiveConstantValue value =
        compiler.constants.getConstantValue(annotation.constant);
    Expect.stringEquals('xyz', value.primitiveValue);

    checkPosition(
        annotation, annotation.cachedNode, source3, compiler.reporter);
  });

  // Ensure that each repeated annotation has a unique instance of
  // [MetadataAnnotation].
  var source4 = """const native = 'xyz';
                   class Foo {
                     @native @native
                     $declaration
                   }
                   main() {}""";

  analyzeAndCheck(source4, 'Foo', (compiler, element) {
    compiler.enqueuer.resolution.queueIsClosed = false;
    Expect.equals(0, element.metadata.length);
    element.ensureResolved(compiler.resolution);
    Expect.equals(0, element.metadata.length);
    element = element.lookupLocalMember(name);
    Expect.equals(2, element.metadata.length);
    PartialMetadataAnnotation annotation1 = element.metadata.elementAt(0);
    PartialMetadataAnnotation annotation2 = element.metadata.elementAt(1);
    annotation1.ensureResolved(compiler.resolution);
    annotation2.ensureResolved(compiler.resolution);
    Expect.isFalse(
        identical(annotation1, annotation2), 'expected unique instances');
    Expect.notEquals(annotation1, annotation2, 'expected unequal instances');
    PrimitiveConstantValue value1 =
        compiler.constants.getConstantValue(annotation1.constant);
    PrimitiveConstantValue value2 =
        compiler.constants.getConstantValue(annotation2.constant);
    Expect.identical(value1, value2, 'expected same compile-time constant');
    Expect.stringEquals('xyz', value1.primitiveValue);
    Expect.stringEquals('xyz', value2.primitiveValue);

    checkPosition(
        annotation1, annotation1.cachedNode, source4, compiler.reporter);
    checkPosition(
        annotation1, annotation2.cachedNode, source4, compiler.reporter);
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
  checkAnnotation('bar', 'var foo, bar;');
}

void testLibraryTags() {
  void compileAndCheckLibrary(String source,
      List<MetadataAnnotation> extractMetadata(LibraryElement element)) {
    Uri partUri = new Uri(scheme: 'source', path: 'part.dart');
    String partSource = '@native part of foo;';

    Uri libUri = new Uri(scheme: 'source', path: 'lib.dart');
    String libSource = 'library lib;';

    Uri uri = new Uri(scheme: 'source', path: 'main.dart');

    var compiler = compilerFor(source, uri, analyzeOnly: true)
      ..registerSource(partUri, partSource)
      ..registerSource(libUri, libSource);

    asyncTest(() => compiler.run(uri).then((_) {
          compiler.enqueuer.resolution.queueIsClosed = false;
          LibraryElement element = compiler.libraryLoader.lookupLibrary(uri);
          Expect.isNotNull(element, 'Cannot find $uri');

          List<MetadataAnnotation> metadata = extractMetadata(element);
          Expect.equals(1, metadata.length);

          PartialMetadataAnnotation annotation = metadata.first;
          annotation.ensureResolved(compiler.resolution);
          PrimitiveConstantValue value =
              compiler.constants.getConstantValue(annotation.constant);
          Expect.stringEquals('xyz', value.primitiveValue);

          checkPosition(
              annotation, annotation.cachedNode, source, compiler.reporter);
        }));
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
  compileAndCheckLibrary(
      source, (e) => e.compilationUnits.first.partTag.metadata);
}

void main() {
  testClassMetadata();
  testTopLevelMethodMetadata();
  testTopLevelFieldMetadata();
  testLibraryTags();
}
