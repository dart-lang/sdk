// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer_plugin/plugin/occurrences_mixin.dart';
import 'package:analyzer_plugin/protocol/protocol.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/src/utilities/occurrences/occurrences.dart';
import 'package:analyzer_plugin/utilities/occurrences/occurrences.dart';
import 'package:path/src/context.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'mocks.dart';

void main() {
  defineReflectiveTests(OccurrencesMixinTest);
}

@reflectiveTest
class OccurrencesMixinTest {
  MemoryResourceProvider resourceProvider = new MemoryResourceProvider();

  String packagePath1;
  String filePath1;
  ContextRoot contextRoot1;

  MockChannel channel;
  _TestServerPlugin plugin;

  void setUp() {
    Context pathContext = resourceProvider.pathContext;

    packagePath1 = resourceProvider.convertPath('/package1');
    filePath1 = pathContext.join(packagePath1, 'lib', 'test.dart');
    resourceProvider.newFile(filePath1, '');
    contextRoot1 = new ContextRoot(packagePath1, <String>[]);

    channel = new MockChannel();
    plugin = new _TestServerPlugin(resourceProvider);
    plugin.start(channel);
  }

  test_sendOccurrencesNotification() async {
    await plugin.handleAnalysisSetContextRoots(
        new AnalysisSetContextRootsParams([contextRoot1]));

    Completer<Null> notificationReceived = new Completer<Null>();
    channel.listen(null, onNotification: (Notification notification) {
      expect(notification, isNotNull);
      AnalysisOccurrencesParams params =
          new AnalysisOccurrencesParams.fromNotification(notification);
      expect(params.file, filePath1);
      List<Occurrences> occurrenceList = params.occurrences;
      expect(occurrenceList, hasLength(3));

      void validate(String elementName, List<int> expectedOffsets) {
        for (Occurrences occurrences in occurrenceList) {
          if (occurrences.element.name == elementName) {
            expect(occurrences.offsets, expectedOffsets);
            expect(occurrences.length, elementName.length);
            return;
          }
        }
        fail('No occurence named $elementName');
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
      for (int offset in offsets) {
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
    Element element1 = new Element(ElementKind.METHOD, 'method', 0);
    Element element2 = new Element(ElementKind.CLASS, 'C', 0);
    Element element3 = new Element(ElementKind.LOCAL_VARIABLE, 'local', 0);
    return <OccurrencesContributor>[
      new _TestOccurrencesContributor({
        element1: [10, 30],
        element2: [20, 40, 60]
      }),
      new _TestOccurrencesContributor({
        element2: [50, 70],
        element3: [80]
      })
    ];
  }

  @override
  Future<OccurrencesRequest> getOccurrencesRequest(String path) async {
    AnalysisResult result = new AnalysisResult(
        null, null, path, null, null, null, null, null, null, null, null);
    return new DartOccurrencesRequestImpl(resourceProvider, result);
  }
}
