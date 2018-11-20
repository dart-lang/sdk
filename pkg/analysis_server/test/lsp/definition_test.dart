// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'server_abstract.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DefinitionTest);
  });
}

@reflectiveTest
class DefinitionTest extends AbstractLspAnalysisServerTest {
  test_definition() async {
    final contents = '''
    [[foo]]() {
      fo^o();
    }
    ''';

    await initialize();
    await openFile(mainFileUri, withoutMarkers(contents));
    final res = await getDefinition(mainFileUri, positionFromMarker(contents));

    expect(res, hasLength(1));
    Location loc = res.single;
    expect(loc.range, equals(rangeFromMarkers(contents)));
    expect(loc.uri, equals(mainFileUri.toString()));
  }
}
