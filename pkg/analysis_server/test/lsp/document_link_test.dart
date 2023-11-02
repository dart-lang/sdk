// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../utils/test_code_extensions.dart';
import 'server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DocumentLinkTest);
  });
}

@reflectiveTest
class DocumentLinkTest extends AbstractLspAnalysisServerTest {
  Future<void> test_exampleLink() async {
    final exampleFolderPath = join(projectFolderPath, 'examples', 'api');
    final exampleFileUri = Uri.file(join(exampleFolderPath, 'foo.dart'));

    final code = TestCode.parse('''
/// {@tool dartpad}
/// ** See code in [!examples/api/foo.dart!] **
/// {@end-tool}
class A {}
''');

    newFolder(exampleFolderPath);
    newFile(mainFilePath, code.code);

    await initialize();
    final links = await getDocumentLinks(mainFileUri);

    final link = links!.single;
    expect(link.range, code.range.range);
    expect(link.target, exampleFileUri.toString());
  }
}
