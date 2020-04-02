// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DefinitionTest);
  });
}

@reflectiveTest
class DefinitionTest extends AbstractLspAnalysisServerTest {
  Future<void> test_acrossFiles() async {
    final mainContents = '''
    import 'referenced.dart';

    main() {
      fo^o();
    }
    ''';

    final referencedContents = '''
    /// Ensure the function is on a line that
    /// does not exist in the mainContents file
    /// to ensure we're translating offsets to line/col
    /// using the correct file's LineInfo
    /// ...
    /// ...
    /// ...
    /// ...
    /// ...
    [[foo]]() {}
    ''';

    final referencedFileUri =
        Uri.file(join(projectFolderPath, 'lib', 'referenced.dart'));

    await initialize();
    await openFile(mainFileUri, withoutMarkers(mainContents));
    await openFile(referencedFileUri, withoutMarkers(referencedContents));
    final res =
        await getDefinition(mainFileUri, positionFromMarker(mainContents));

    expect(res, hasLength(1));
    var loc = res.single;
    expect(loc.range, equals(rangeFromMarkers(referencedContents)));
    expect(loc.uri, equals(referencedFileUri.toString()));
  }

  Future<void> test_nonDartFile() async {
    newFile(pubspecFilePath, content: simplePubspecContent);
    await initialize();

    final res = await getDefinition(pubspecFileUri, startOfDocPos);
    expect(res, isEmpty);
  }

  Future<void> test_singleFile() async {
    final contents = '''
    [[foo]]() {
      fo^o();
    }
    ''';

    await initialize();
    await openFile(mainFileUri, withoutMarkers(contents));
    final res = await getDefinition(mainFileUri, positionFromMarker(contents));

    expect(res, hasLength(1));
    var loc = res.single;
    expect(loc.range, equals(rangeFromMarkers(contents)));
    expect(loc.uri, equals(mainFileUri.toString()));
  }

  Future<void> test_unopenFile() async {
    final contents = '''
    [[foo]]() {
      fo^o();
    }
    ''';

    newFile(mainFilePath, content: withoutMarkers(contents));
    await initialize();
    final res = await getDefinition(mainFileUri, positionFromMarker(contents));

    expect(res, hasLength(1));
    var loc = res.single;
    expect(loc.range, equals(rangeFromMarkers(contents)));
    expect(loc.uri, equals(mainFileUri.toString()));
  }
}
