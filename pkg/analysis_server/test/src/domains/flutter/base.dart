// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/flutter/flutter_domain.dart';
import 'package:analysis_server/src/protocol_server.dart';
import 'package:analyzer/src/test_utilities/package_config_file_builder.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../analysis_abstract.dart';
import '../../utilities/mock_packages.dart';

@reflectiveTest
class FlutterBase extends AbstractAnalysisTest {
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
    return FlutterGetWidgetDescriptionResult.fromResponse(response);
  }

  Future<Response> getWidgetDescriptionResponse(String search) async {
    var request = FlutterGetWidgetDescriptionParams(
      testFile,
      findOffset(search),
    ).toRequest('0');
    return await waitResponse(request);
  }

  @override
  Future<void> setUp() async {
    super.setUp();
    projectPath = convertPath('/home');
    testFile = convertPath('/home/test/lib/test.dart');

    newPubspecYamlFile('/home/test', '');

    var metaLib = MockPackages.instance.addMeta(resourceProvider);
    var flutterLib = MockPackages.instance.addFlutter(resourceProvider);
    newPackageConfigJsonFile(
      '/home/test',
      (PackageConfigFileBuilder()
            ..add(name: 'test', rootPath: '/home/test')
            ..add(name: 'meta', rootPath: metaLib.parent.path)
            ..add(name: 'flutter', rootPath: flutterLib.parent.path))
          .toContent(toUriStr: toUriStr),
    );

    await createProject();
    handler = server.handlers.whereType<FlutterDomainHandler>().single;
  }
}
