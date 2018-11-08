// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:test/test.dart';
import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'server_abstract.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FormatTest);
  });
}

@reflectiveTest
class FormatTest extends AbstractLspAnalysisServerTest {
  test_simple_format() async {
    const contents = '''
    main  ()
    {

        print('test');
    }
    ''';
    final expected = '''main() {
  print('test');
}
''';
    newFile(mainFilePath, content: contents);

    await initialize();
    final formatEdits = await formatDocument(mainFileUri);
    expect(formatEdits, isNotNull);
    final formattedContents = applyEdits(contents, formatEdits);
    expect(formattedContents, equals(expected));
  }

  test_no_format() async {
    const contents = '''main() {
  print('test');
}
''';
    newFile(mainFilePath, content: contents);

    await initialize();
    final formatEdits = await formatDocument(mainFileUri);
    expect(formatEdits, isNull);
  }

  test_invalid_syntax() async {
    const contents = '''main(((( {
  print('test');
}
''';
    newFile(mainFilePath, content: contents);

    await initialize();
    final formatEdits = await formatDocument(mainFileUri);
    expect(formatEdits, isNull);
  }

  test_invalid_path() async {
    await initialize();
    try {
      await formatDocument(
        new Uri.file(join(projectFolderPath, 'missing.dart')),
      );
      throw 'Expected an InvalidFilePath response error';
    } on ResponseError catch (e) {
      expect(e.code, equals(ServerErrorCodes.InvalidFilePath));
    }
  }
}
