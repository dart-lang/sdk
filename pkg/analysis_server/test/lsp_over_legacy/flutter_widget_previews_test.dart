// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'abstract_lsp_over_legacy.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FlutterWidgetPreviewsTest);
  });
}

@reflectiveTest
class FlutterWidgetPreviewsTest extends LspOverLegacyTest {
  Future<FlutterWidgetPreviews?> getFlutterWidgetPreviews(Uri uri) {
    var request = makeRequest(
      CustomMethods.getFlutterWidgetPreviews,
      TextDocumentIdentifier(uri: uri),
    );
    return expectSuccessfulResponseTo(request, FlutterWidgetPreviews.fromJson);
  }

  Future<FlutterWidgetPreviews?> getWorkspaceFlutterWidgetPreviews() {
    var request = makeRequest(
      CustomMethods.getWorkspaceFlutterWidgetPreviews,
      null,
    );
    return expectSuccessfulResponseTo(request, FlutterWidgetPreviews.fromJson);
  }

  @override
  Future<void> setUp() async {
    await super.setUp();
    writeTestPackageConfig(flutter: true);
    addFlutter();
    addSkyEngine(sdkPath: sdkRoot.path);
  }

  Future<void> test_getFlutterWidgetPreviews() async {
    var filePath = join(projectFolderPath, 'lib', 'previews.dart');
    var fileUri = Uri.file(filePath);
    newFile(filePath, '''
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

@Preview(name: 'Initial')
Widget preview1() => Text('1');
''');

    await waitForTasksFinished();
    var result = await getFlutterWidgetPreviews(fileUri);
    expect(result!.previews, hasLength(1));
    expect(result.previews.first.functionName, 'preview1');
  }

  Future<void> test_workspacePreviews() async {
    newFile(join(projectFolderPath, 'lib', 'a.dart'), '''
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
@Preview(name: 'A')
Widget a() => Text('A');
''');
    newFile(join(projectFolderPath, 'lib', 'b.dart'), '''
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
@Preview(name: 'B')
Widget b() => Text('B');
''');

    await waitForTasksFinished();
    var result = await getWorkspaceFlutterWidgetPreviews();
    expect(result!.previews, hasLength(2));
    expect(result.previews.any((p) => p.functionName == 'a'), isTrue);
    expect(result.previews.any((p) => p.functionName == 'b'), isTrue);
  }
}
