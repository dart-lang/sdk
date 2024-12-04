// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../analysis_server_base.dart';

@reflectiveTest
class FlutterBase extends PubPackageAnalysisServerTest {
  FlutterWidgetProperty getProperty(
    FlutterGetWidgetDescriptionResult result,
    String name,
  ) {
    return result.properties.singleWhere((property) {
      return property.name == name;
    });
  }

  Future<FlutterGetWidgetDescriptionResult> getWidgetDescription(
    String search,
  ) async {
    var response = await getWidgetDescriptionResponse(search);
    expect(response.error, isNull);
    return FlutterGetWidgetDescriptionResult.fromResponse(
      response,
      clientUriConverter: server.uriConverter,
    );
  }

  Future<Response> getWidgetDescriptionResponse(String search) async {
    var request = FlutterGetWidgetDescriptionParams(
      testFile.path,
      findOffset(search),
    ).toRequest('0', clientUriConverter: server.uriConverter);
    return await handleRequest(request);
  }

  @override
  Future<void> setUp() async {
    super.setUp();

    newPubspecYamlFile(testPackageRootPath, '');

    writeTestPackageConfig(meta: true, flutter: true);

    await setRoots(included: [workspaceRootPath], excluded: []);
  }
}
