// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/flutter/flutter_domain.dart';
import 'package:analysis_server/src/protocol_server.dart';
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
    newDotPackagesFile('/home/test', content: '''
test:${toUri('/home/test/lib')}
''');

    _addFlutterPackage();

    await createProject();
    handler = server.handlers.whereType<FlutterDomainHandler>().single;
  }

  void _addFlutterPackage() {
    _addMetaPackage();
    var libFolder = MockPackages.instance.addFlutter(resourceProvider);
    _addPackageDependency('flutter', libFolder.parent2.path);
  }

  void _addMetaPackage() {
    var libFolder = MockPackages.instance.addMeta(resourceProvider);
    _addPackageDependency('meta', libFolder.parent2.path);
  }

  void _addPackageDependency(String name, String rootPath) {
    var packagesFile = getFile('/home/test/.packages');
    var packagesContent =
        packagesFile.exists ? packagesFile.readAsStringSync() : '';

    // Ignore if there is already the same package dependency.
    if (packagesContent.contains('$name:file://')) {
      return;
    }

    rootPath = convertPath(rootPath);
    packagesContent += '$name:${toUri('$rootPath/lib')}\n';

    packagesFile.writeAsStringSync(packagesContent);
  }
}
