// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#import("dart:uri");

#import('compiler_helper.dart');

#import('../../../lib/compiler/implementation/elements/elements.dart');
#import('../../../lib/compiler/implementation/leg.dart');

void testClassMetadata() {
  // TODO(ahe): native should be "const", not "final".
  final source = """final native = 'xyz';
                    @native class Foo {}
                    main() {}""";

  check(compiler, element) {
    Expect.isFalse(element.metadata.isEmpty());
    Expect.isTrue(element.metadata.tail.isEmpty());
    MetadataAnnotation annotation = element.metadata.head;
    annotation.ensureResolved(compiler);
    Constant value = annotation.value;
    Expect.stringEquals('xyz', value.value.slowToString());
  }

  compileAndCheck(source, 'Foo', check);
}

void testTopLevelMethodMetadata() {
  // TODO(ahe): native should be "const", not "final".
  final source = """final native = 'xyz';
                    @native
                    main() {}""";

  check(compiler, element) {
    Expect.isFalse(element.metadata.isEmpty());
    Expect.isTrue(element.metadata.tail.isEmpty());
    MetadataAnnotation annotation = element.metadata.head;
    annotation.ensureResolved(compiler);
    Constant value = annotation.value;
    Expect.stringEquals('xyz', value.value.slowToString());
  }

  compileAndCheck(source, 'main', check);
}

void main() {
  testClassMetadata();
  testTopLevelMethodMetadata();
}
