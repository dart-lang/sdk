// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:analyzer_plugin/plugin/navigation_mixin.dart';
import 'package:analyzer_plugin/protocol/protocol.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/src/utilities/navigation/navigation.dart';
import 'package:analyzer_plugin/utilities/navigation/navigation.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'mocks.dart';

void main() {
  defineReflectiveTests(NavigationMixinTest);
}

@reflectiveTest
class NavigationMixinTest with ResourceProviderMixin {
  String packagePath1;
  String filePath1;
  ContextRoot contextRoot1;

  MockChannel channel;
  _TestServerPlugin plugin;

  void setUp() {
    packagePath1 = convertPath('/package1');
    filePath1 = join(packagePath1, 'lib', 'test.dart');
    newFile(filePath1);
    contextRoot1 = ContextRoot(packagePath1, <String>[]);

    channel = MockChannel();
    plugin = _TestServerPlugin(resourceProvider);
    plugin.start(channel);
  }

  Future<void> test_handleAnalysisGetNavigation() async {
    await plugin.handleAnalysisSetContextRoots(
        AnalysisSetContextRootsParams([contextRoot1]));

    var result = await plugin.handleAnalysisGetNavigation(
        AnalysisGetNavigationParams(filePath1, 1, 2));
    expect(result, isNotNull);
    expect(result.files, hasLength(1));
    expect(result.targets, hasLength(1));
    expect(result.regions, hasLength(2));
  }

  Future<void> test_sendNavigationNotification() async {
    await plugin.handleAnalysisSetContextRoots(
        AnalysisSetContextRootsParams([contextRoot1]));

    var notificationReceived = Completer<void>();
    channel.listen(null, onNotification: (Notification notification) {
      expect(notification, isNotNull);
      var params = AnalysisNavigationParams.fromNotification(notification);
      expect(params.files, hasLength(1));
      expect(params.targets, hasLength(1));
      expect(params.regions, hasLength(2));
      notificationReceived.complete();
    });
    await plugin.sendNavigationNotification(filePath1);
    await notificationReceived.future;
  }
}

class _TestNavigationContributor implements NavigationContributor {
  int regionCount;

  _TestNavigationContributor(this.regionCount);

  @override
  void computeNavigation(
      NavigationRequest request, NavigationCollector collector) {
    for (var i = 0; i < regionCount; i++) {
      collector.addRegion(i, 5, ElementKind.METHOD, Location('a', 5, 5, 1, 5));
    }
  }
}

class _TestServerPlugin extends MockServerPlugin with NavigationMixin {
  _TestServerPlugin(ResourceProvider resourceProvider)
      : super(resourceProvider);

  @override
  List<NavigationContributor> getNavigationContributors(String path) {
    return <NavigationContributor>[
      _TestNavigationContributor(2),
      _TestNavigationContributor(1)
    ];
  }

  @override
  Future<NavigationRequest> getNavigationRequest(
      AnalysisGetNavigationParams parameters) async {
    var result = MockResolvedUnitResult(path: parameters.file);
    return DartNavigationRequestImpl(
        resourceProvider, parameters.offset, parameters.length, result);
  }
}
