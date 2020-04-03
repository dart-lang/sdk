// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/integration_tests.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(OutlineTest);
  });
}

@reflectiveTest
class OutlineTest extends AbstractAnalysisServerIntegrationTest {
  Future<void> test_outline() {
    var pathname = sourcePath('test.dart');
    var text = r'''
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
      var classes = outline.children;
      expect(classes, hasLength(2));
      expect(classes[0].element.name, equals('Class1'));
      expect(classes[1].element.name, equals('Class2'));

      var members = classes[0].children;
      expect(members, hasLength(5));
      expect(members[0].element.name, equals('field'));
      expect(members[1].element.name, equals('method'));
      expect(members[2].element.name, equals('staticMethod'));
      expect(members[3].element.name, equals('getter'));
      expect(members[4].element.name, equals('setter'));
    });
  }
}
