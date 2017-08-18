// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/integration_tests.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UpdateContentTest);
  });
}

@reflectiveTest
class UpdateContentTest extends AbstractAnalysisServerIntegrationTest {
  test_updateContent() async {
    String path = sourcePath('test.dart');
    String goodText = r'''
main() {
  print("Hello, world!");
}''';

    String badText = goodText.replaceAll(';', '');
    writeFile(path, badText);
    standardAnalysisSetup();

    // The contents on disk (badText) are missing a semicolon.
    await analysisFinished;
    expect(currentAnalysisErrors[path], isNotEmpty);

    // There should be no errors now because the contents on disk have been
    // overridden with goodText.
    sendAnalysisUpdateContent({path: new AddContentOverlay(goodText)});
    await analysisFinished;
    expect(currentAnalysisErrors[path], isEmpty);

    // There should be errors now because we've removed the semicolon.
    sendAnalysisUpdateContent({
      path: new ChangeContentOverlay(
          [new SourceEdit(goodText.indexOf(';'), 1, '')])
    });
    await analysisFinished;
    expect(currentAnalysisErrors[path], isNotEmpty);

    // There should be no errors now because we've added the semicolon back.
    sendAnalysisUpdateContent({
      path: new ChangeContentOverlay(
          [new SourceEdit(goodText.indexOf(';'), 0, ';')])
    });
    await analysisFinished;
    expect(currentAnalysisErrors[path], isEmpty);

    // Now there should be errors again, because the contents on disk are no
    // longer overridden.
    sendAnalysisUpdateContent({path: new RemoveContentOverlay()});
    await analysisFinished;
    expect(currentAnalysisErrors[path], isNotEmpty);
  }

  @failingTest
  test_updateContent_multipleAdds() async {
    String pathname = sourcePath('test.dart');
    writeFile(pathname, r'''
class Person {
  String _name;
  Person(this._name);
  String get name => this._name;
  String toString() => "Name: ${name}";
}
void main() {
  var p = new Person("Skeletor");
  p.xname = "Faker";
  print(p);
}
''');
    standardAnalysisSetup();
    await analysisFinished;
    expect(currentAnalysisErrors[pathname], isList);
    List<AnalysisError> errors1 = currentAnalysisErrors[pathname];
    expect(errors1, hasLength(1));
    expect(errors1[0].location.file, equals(pathname));

    await sendAnalysisUpdateContent({
      pathname: new AddContentOverlay(r'''
class Person {
  String _name;
  Person(this._name);
  String get name => this._name;
  String toString() => "Name: ${name}";
}
void main() {
  var p = new Person("Skeletor");
  p.name = "Faker";
  print(p);
}
''')
    });
    await analysisFinished;
    expect(currentAnalysisErrors[pathname], isList);
    List<AnalysisError> errors2 = currentAnalysisErrors[pathname];
    expect(errors2, hasLength(1));
    expect(errors2[0].location.file, equals(pathname));
  }
}
