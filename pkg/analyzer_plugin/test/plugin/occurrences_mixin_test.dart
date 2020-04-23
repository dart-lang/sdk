// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:analyzer_plugin/plugin/occurrences_mixin.dart';
import 'package:analyzer_plugin/protocol/protocol.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/src/utilities/occurrences/occurrences.dart';
import 'package:analyzer_plugin/utilities/occurrences/occurrences.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'mocks.dart';

void main() {
  defineReflectiveTests(OccurrencesMixinTest);
}

@reflectiveTest
class OccurrencesMixinTest with ResourceProviderMixin {
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

  Future<void> test_sendOccurrencesNotification() async {
    await plugin.handleAnalysisSetContextRoots(
        AnalysisSetContextRootsParams([contextRoot1]));

    var notificationReceived = Completer<void>();
    channel.listen(null, onNotification: (Notification notification) {
      expect(notification, isNotNull);
      var params = AnalysisOccurrencesParams.fromNotification(notification);
      expect(params.file, filePath1);
      var occurrenceList = params.occurrences;
      expect(occurrenceList, hasLength(3));

      void validate(String elementName, List<int> expectedOffsets) {
        for (var occurrences in occurrenceList) {
          if (occurrences.element.name == elementName) {
            expect(occurrences.offsets, expectedOffsets);
            expect(occurrences.length, elementName.length);
            return;
          }
        }
        fail('No occurrence named $elementName');
      }

      validate('method', [10, 30]);
      validate('C', [20, 40, 50, 60, 70]);
      validate('local', [80]);
      notificationReceived.complete();
    });
    await plugin.sendOccurrencesNotification(filePath1);
    await notificationReceived.future;
  }
}

class _TestOccurrencesContributor implements OccurrencesContributor {
  Map<Element, List<int>> elements;

  _TestOccurrencesContributor(this.elements);

  @override
  void computeOccurrences(
      OccurrencesRequest request, OccurrencesCollector collector) {
    elements.forEach((element, offsets) {
      for (var offset in offsets) {
        collector.addOccurrence(element, offset);
      }
    });
  }
}

class _TestServerPlugin extends MockServerPlugin with OccurrencesMixin {
  _TestServerPlugin(ResourceProvider resourceProvider)
      : super(resourceProvider);

  @override
  List<OccurrencesContributor> getOccurrencesContributors(String path) {
    var element1 = Element(ElementKind.METHOD, 'method', 0);
    var element2 = Element(ElementKind.CLASS, 'C', 0);
    var element3 = Element(ElementKind.LOCAL_VARIABLE, 'local', 0);
    return <OccurrencesContributor>[
      _TestOccurrencesContributor({
        element1: [10, 30],
        element2: [20, 40, 60]
      }),
      _TestOccurrencesContributor({
        element2: [50, 70],
        element3: [80]
      })
    ];
  }

  @override
  Future<OccurrencesRequest> getOccurrencesRequest(String path) async {
    var result = MockResolvedUnitResult(path: path);
    return DartOccurrencesRequestImpl(resourceProvider, result);
  }
}
