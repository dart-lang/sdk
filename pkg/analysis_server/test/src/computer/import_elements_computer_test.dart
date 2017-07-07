// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/computer/import_elements_computer.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../abstract_context.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ImportElementsComputerTest);
  });
}

/**
 * Tests that the [ImportElementsComputer] will correctly update imports. The
 * tests are generally labeled based on the kind of import in the source (from
 * which the text was copied) and the kind of import in the target (into which
 * the text was pasted). Kinds are a combination of "prefix", "hide", "show" and
 * "deferred", or "bare" when there are none of the previous, or "none" when
 * there is no import.
 */
@reflectiveTest
class ImportElementsComputerTest extends AbstractContextTest {
  String targetPath;
  String targetCode;

  ResolveResult result;

  setUp() async {
    super.setUp();
    packageMap['p'] = [provider.newFolder(provider.convertPath('/p/lib'))];
    targetPath = provider.convertPath('/p/lib/target.dart');
    targetCode = '''
main() {}
''';
    provider.newFile(targetPath, targetCode);
    result = await driver.getResult(targetPath);
  }

  @failingTest
  test_bare_none() {
    List<ImportedElements> elements = <ImportedElements>[
      new ImportedElements(provider.convertPath('/p/lib/a.dart'),
          'package:p/a.dart', '', <String>['A']),
    ];
    List<SourceEdit> edits = _computeEditsFor(elements);
    expect(edits, hasLength(1));
    SourceEdit edit = edits[0];
    expect(edit, isNotNull);
    expect(edit.offset, 0);
    expect(edit.length, 0);
    expect(
        edit.apply(targetCode),
        """
import 'source.dart';

main() {}
""");
  }

  test_none_none() {
    List<ImportedElements> elements = <ImportedElements>[];
    List<SourceEdit> edits = _computeEditsFor(elements);
    expect(edits, hasLength(0));
  }

  List<SourceEdit> _computeEditsFor(List<ImportedElements> elements) {
    ImportElementsComputer computer =
        new ImportElementsComputer(result, targetPath, elements);
    return computer.compute();
  }
}
