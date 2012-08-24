// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#import("dart:uri");

#import('compiler_helper.dart');
#import('parser_helper.dart');

#import('../../../lib/compiler/implementation/elements/elements.dart');
#import('../../../lib/compiler/implementation/leg.dart');

void checkAnnotation(String name, String declaration,
                     [bool isTopLevelOnly = false]) {
  var source;

  // Ensure that a compile-time constant can be resolved from an
  // annotation.
  source = """const native = 'xyz';
              @native
              $declaration
              main() {}""";

  compileAndCheck(source, name, (compiler, element) {
    Expect.equals(1, length(element.metadata));
    MetadataAnnotation annotation = element.metadata.head;
    annotation.ensureResolved(compiler);
    Constant value = annotation.value;
    Expect.stringEquals('xyz', value.value.slowToString());
  });

  // Ensure that each repeated annotation has a unique instance of
  // [MetadataAnnotation].
  source = """const native = 'xyz';
              @native @native
              $declaration
              main() {}""";

  compileAndCheck(source, name, (compiler, element) {
    Expect.equals(2, length(element.metadata));
    MetadataAnnotation annotation1 = element.metadata.head;
    MetadataAnnotation annotation2 = element.metadata.tail.head;
    annotation1.ensureResolved(compiler);
    annotation2.ensureResolved(compiler);
    Expect.isTrue(annotation1 !== annotation2, 'expected unique instances');
    Expect.notEquals(annotation1, annotation2, 'expected unequal instances');
    Constant value1 = annotation1.value;
    Constant value2 = annotation2.value;
    Expect.identical(value1, value2, 'expected same compile-time constant');
    Expect.stringEquals('xyz', value1.value.slowToString());
    Expect.stringEquals('xyz', value2.value.slowToString());
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
    Expect.equals(0, length(element.metadata));
    element.ensureResolved(compiler);
    Expect.equals(0, length(element.metadata));
    element = element.lookupLocalMember(buildSourceString(name));
    Expect.equals(1, length(element.metadata));
    MetadataAnnotation annotation = element.metadata.head;
    annotation.ensureResolved(compiler);
    Constant value = annotation.value;
    Expect.stringEquals('xyz', value.value.slowToString());
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
    Expect.equals(0, length(element.metadata));
    element.ensureResolved(compiler);
    Expect.equals(0, length(element.metadata));
    element = element.lookupLocalMember(buildSourceString(name));
    Expect.equals(2, length(element.metadata));
    MetadataAnnotation annotation1 = element.metadata.head;
    MetadataAnnotation annotation2 = element.metadata.tail.head;
    annotation1.ensureResolved(compiler);
    annotation2.ensureResolved(compiler);
    Expect.isTrue(annotation1 !== annotation2, 'expected unique instances');
    Expect.notEquals(annotation1, annotation2, 'expected unequal instances');
    Constant value1 = annotation1.value;
    Constant value2 = annotation2.value;
    Expect.identical(value1, value2, 'expected same compile-time constant');
    Expect.stringEquals('xyz', value1.value.slowToString());
    Expect.stringEquals('xyz', value2.value.slowToString());
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

void main() {
  testClassMetadata();
  testTopLevelMethodMetadata();
  testTopLevelFieldMetadata();
}
