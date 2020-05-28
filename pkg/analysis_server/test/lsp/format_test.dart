// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/lsp/constants.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../tool/lsp_spec/matchers.dart';
import 'server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FormatTest);
  });
}

@reflectiveTest
class FormatTest extends AbstractLspAnalysisServerTest {
  Future<void> test_alreadyFormatted() async {
    const contents = '''main() {
  print('test');
}
''';
    await initialize();
    await openFile(mainFileUri, contents);

    final formatEdits = await formatDocument(mainFileUri.toString());
    expect(formatEdits, isNull);
  }

  Future<void> test_formatOnType_simple() async {
    const contents = '''
    main  ()
    {

        print('test');
    ^}
    ''';
    final expected = '''main() {
  print('test');
}
''';
    await initialize();
    await openFile(mainFileUri, withoutMarkers(contents));

    final formatEdits = await formatOnType(
        mainFileUri.toString(), positionFromMarker(contents), '}');
    expect(formatEdits, isNotNull);
    final formattedContents = applyTextEdits(contents, formatEdits);
    expect(formattedContents, equals(expected));
  }

  Future<void> test_invalidSyntax() async {
    const contents = '''main(((( {
  print('test');
}
''';
    await initialize();
    await openFile(mainFileUri, contents);

    final formatEdits = await formatDocument(mainFileUri.toString());
    expect(formatEdits, isNull);
  }

  Future<void> test_nonDartFile() async {
    await initialize();
    await openFile(pubspecFileUri, simplePubspecContent);

    final formatEdits =
        await formatOnType(pubspecFileUri.toString(), startOfDocPos, '}');
    expect(formatEdits, isNull);
  }

  Future<void> test_path_doesNotExist() async {
    await initialize();

    await expectLater(
      formatDocument(
          Uri.file(join(projectFolderPath, 'missing.dart')).toString()),
      throwsA(isResponseError(ServerErrorCodes.InvalidFilePath)),
    );
  }

  Future<void> test_path_invalidFormat() async {
    await initialize();

    await expectLater(
      // Add some invalid path characters to the end of a valid file:// URI.
      formatDocument(mainFileUri.toString() + '***.dart'),
      throwsA(isResponseError(ServerErrorCodes.InvalidFilePath)),
    );
  }

  Future<void> test_path_notFileScheme() async {
    await initialize();

    await expectLater(
      formatDocument('a:/a.dart'),
      throwsA(isResponseError(ServerErrorCodes.InvalidFilePath)),
    );
  }

  Future<void> test_simple() async {
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
    await initialize();
    await openFile(mainFileUri, contents);

    final formatEdits = await formatDocument(mainFileUri.toString());
    expect(formatEdits, isNotNull);
    final formattedContents = applyTextEdits(contents, formatEdits);
    expect(formattedContents, equals(expected));
  }

  Future<void> test_unopenFile() async {
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

    final formatEdits = await formatDocument(mainFileUri.toString());
    expect(formatEdits, isNotNull);
    final formattedContents = applyTextEdits(contents, formatEdits);
    expect(formattedContents, equals(expected));
  }
}
