// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer_plugin/plugin/kythe_mixin.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/src/utilities/kythe/entries.dart';
import 'package:analyzer_plugin/utilities/kythe/entries.dart';
import 'package:path/src/context.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'mocks.dart';

void main() {
  defineReflectiveTests(KytheMixinTest);
}

@reflectiveTest
class KytheMixinTest {
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

  test_handleEditGetAssists() async {
    await plugin.handleAnalysisSetContextRoots(
        new AnalysisSetContextRootsParams([contextRoot1]));

    KytheGetKytheEntriesResult result = await plugin
        .handleKytheGetKytheEntries(new KytheGetKytheEntriesParams(filePath1));
    expect(result, isNotNull);
    expect(result.entries, hasLength(3));
  }
}

class _TestEntryContributor implements EntryContributor {
  List<KytheEntry> entries;

  _TestEntryContributor(this.entries);

  @override
  void computeEntries(EntryRequest request, EntryCollector collector) {
    for (KytheEntry entry in entries) {
      collector.addEntry(entry);
    }
  }
}

class _TestServerPlugin extends MockServerPlugin with EntryMixin {
  _TestServerPlugin(ResourceProvider resourceProvider)
      : super(resourceProvider);

  PrioritizedSourceChange createChange() {
    return new PrioritizedSourceChange(0, new SourceChange(''));
  }

  @override
  List<EntryContributor> getEntryContributors(String path) {
    KytheVName vName = new KytheVName('', '', '', '', '');
    return <EntryContributor>[
      new _TestEntryContributor(<KytheEntry>[
        new KytheEntry(vName, '', vName, '', <int>[]),
        new KytheEntry(vName, '', vName, '', <int>[])
      ]),
      new _TestEntryContributor(
          <KytheEntry>[new KytheEntry(vName, '', vName, '', <int>[])])
    ];
  }

  @override
  Future<EntryRequest> getEntryRequest(
      KytheGetKytheEntriesParams parameters) async {
    AnalysisResult result = new AnalysisResult(
        null, null, null, null, null, null, null, null, null, null, null);
    return new DartEntryRequestImpl(resourceProvider, result);
  }
}
