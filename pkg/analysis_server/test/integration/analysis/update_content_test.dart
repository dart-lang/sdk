// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/integration_tests.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UpdateContentTest);
  });
}

@reflectiveTest
class UpdateContentTest extends AbstractAnalysisServerIntegrationTest {
  Future<void> test_updateContent() async {
    var path = sourcePath('test.dart');
    var goodText = r'''
void f() {
  print("Hello, world!");
}''';

    var badText = goodText.replaceAll(';', '');
    writeFile(path, badText);
    await standardAnalysisSetup();

    // The contents on disk (badText) are missing a semicolon.
    expect(await waitForFileErrors(path), isNotEmpty);

    // There should be no errors now because the contents on disk have been
    // overridden with goodText.
    await sendAnalysisUpdateContent({path: AddContentOverlay(goodText)});
    expect(await waitForFileErrors(path), isEmpty);

    // There should be errors now because we've removed the semicolon.
    await sendAnalysisUpdateContent({
      path: ChangeContentOverlay([SourceEdit(goodText.indexOf(';'), 1, '')]),
    });
    expect(await waitForFileErrors(path), isNotEmpty);

    // There should be no errors now because we've added the semicolon back.
    await sendAnalysisUpdateContent({
      path: ChangeContentOverlay([SourceEdit(goodText.indexOf(';'), 0, ';')]),
    });
    expect(await waitForFileErrors(path), isEmpty);

    // Now there should be errors again, because the contents on disk are no
    // longer overridden.
    await sendAnalysisUpdateContent({path: RemoveContentOverlay()});
    expect(await waitForFileErrors(path), isNotEmpty);
  }

  Future<void> test_updateContent_multipleAdds() async {
    var pathname = sourcePath('test.dart');
    writeFile(pathname, r'''
class Person {
  String _name;
  Person(this._name);
  String get name => this._name;
  String toString() => "Name: ${name}";
}
void f() {
  var p = new Person("Skeletor");
  p.xname = "Faker";
  print(p);
}
''');
    await standardAnalysisSetup();
    await analysisFinished;
    expect(currentAnalysisErrors[pathname], isList);
    var errors1 = existingErrorsForFile(pathname);
    expect(errors1, hasLength(1));
    expect(errors1[0].location.file, equals(pathname));

    await sendAnalysisUpdateContent({
      pathname: AddContentOverlay(r'''
class Person {
  String _name;
  Person(this._name);
  String get name => this._name;
  String toString() => "Name: ${name}";
}
void f() {
  var p = new Person("Skeletor");
  p.name = "Faker";
  print(p);
}
'''),
    });
    await analysisFinished;
    expect(currentAnalysisErrors[pathname], isList);
    var errors2 = existingErrorsForFile(pathname);
    expect(errors2, hasLength(1));
    expect(errors2[0].location.file, equals(pathname));
  }
}
