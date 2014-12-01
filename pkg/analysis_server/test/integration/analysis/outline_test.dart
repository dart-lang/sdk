// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.integration.analysis.outline;

import 'package:analysis_server/src/protocol.dart';
import 'package:unittest/unittest.dart';

import '../../reflective_tests.dart';
import '../integration_tests.dart';

main() {
  runReflectiveTests(Test);
}

@ReflectiveTestCase()
class Test extends AbstractAnalysisServerIntegrationTest {
  /**
   * Verify that the range of source text covered by the given outline objects
   * is connected (the end of each object in the list corresponds to the start
   * of the next).
   */
  void checkConnected(List<Outline> outlineObjects) {
    for (int i = 0; i < outlineObjects.length - 1; i++) {
      expect(
          outlineObjects[i + 1].offset,
          equals(outlineObjects[i].offset + outlineObjects[i].length));
    }
  }

  test_outline() {
    String pathname = sourcePath('test.dart');
    String text = r'''
class Class1 {
  int field;

  void method() {
  }

  static staticMethod() {
  }

  get getter {
    return null;
  }

  set setter(value) {
  }
}

class Class2 {
}
''';
    writeFile(pathname, text);
    standardAnalysisSetup();
    sendAnalysisSetSubscriptions({
      AnalysisService.OUTLINE: [pathname]
    });
    Outline outline;
    onAnalysisOutline.listen((AnalysisOutlineParams params) {
      expect(params.file, equals(pathname));
      outline = params.outline;
    });
    return analysisFinished.then((_) {
      expect(outline.element.kind, equals(ElementKind.COMPILATION_UNIT));
      expect(outline.offset, equals(0));
      expect(outline.length, equals(text.length));
      List<Outline> classes = outline.children;
      expect(classes, hasLength(2));
      expect(classes[0].element.name, equals('Class1'));
      expect(classes[1].element.name, equals('Class2'));
      checkConnected(classes);
      List<Outline> members = classes[0].children;
      expect(members, hasLength(5));
      expect(members[0].element.name, equals('field'));
      expect(members[1].element.name, equals('method'));
      expect(members[2].element.name, equals('staticMethod'));
      expect(members[3].element.name, equals('getter'));
      expect(members[4].element.name, equals('setter'));
      checkConnected(members);
    });
  }
}
