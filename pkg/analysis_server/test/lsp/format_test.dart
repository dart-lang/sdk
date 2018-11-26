// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../tool/lsp_spec/matchers.dart';
import 'server_abstract.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FormatTest);
  });
}

@reflectiveTest
class FormatTest extends AbstractLspAnalysisServerTest {
  test_alreadyFormatted() async {
    const contents = '''main() {
  print('test');
}
''';
    await newFile(mainFilePath, content: contents);
    await initialize();
    await openFile(mainFileUri, contents);

    final formatEdits = await formatDocument(mainFileUri);
    expect(formatEdits, isNull);
  }

  test_fileNotOpen() async {
    await newFile(mainFilePath);
    await initialize();

    await expectLater(
      formatDocument(mainFileUri),
      throwsA(isResponseError(ServerErrorCodes.FileNotOpen)),
    );
  }

  test_invalidSyntax() async {
    const contents = '''main(((( {
  print('test');
}
''';
    await newFile(mainFilePath, content: contents);
    await initialize();
    await openFile(mainFileUri, contents);

    final formatEdits = await formatDocument(mainFileUri);
    expect(formatEdits, isNull);
  }

  test_path_doesNotExist() async {
    await initialize();

    await expectLater(
      formatDocument(new Uri.file(join(projectFolderPath, 'missing.dart'))),
      throwsA(isResponseError(ServerErrorCodes.InvalidFilePath)),
    );
  }

  test_path_invalidFormat() async {
    await initialize();

    await expectLater(
      formatDocument(Uri.file(join(projectFolderPath, '*'))),
      throwsA(isResponseError(ServerErrorCodes.InvalidFilePath)),
    );
  }

  test_path_notFileScheme() async {
    await initialize();

    await expectLater(
      formatDocument(Uri.parse('a:/a.a')),
      throwsA(isResponseError(ServerErrorCodes.InvalidFilePath)),
    );
  }

  test_simple() async {
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
    await newFile(mainFilePath, content: contents);
    await initialize();
    await openFile(mainFileUri, contents);

    final formatEdits = await formatDocument(mainFileUri);
    expect(formatEdits, isNotNull);
    final formattedContents = applyEdits(contents, formatEdits);
    expect(formattedContents, equals(expected));
  }
}
