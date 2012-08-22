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
    return; // TODO(ahe): I'm working on the following.
    Expect.isFalse(element.metadata.isEmpty());
    MetadataAnnotation annotation = element.metadata.head;
    Expect.isNotNull(annotation);
    Constant value = annotation.value;
    print(value);
  }

  compileAndCheck(source, 'Foo', check);
}

void main() {
  testClassMetadata();
}
