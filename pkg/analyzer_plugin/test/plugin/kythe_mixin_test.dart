// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:analyzer_plugin/plugin/kythe_mixin.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/src/utilities/kythe/entries.dart';
import 'package:analyzer_plugin/utilities/kythe/entries.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'mocks.dart';

void main() {
  defineReflectiveTests(KytheMixinTest);
}

@reflectiveTest
class KytheMixinTest with ResourceProviderMixin {
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

  Future<void> test_handleEditGetAssists() async {
    await plugin.handleAnalysisSetContextRoots(
        AnalysisSetContextRootsParams([contextRoot1]));

    var result = await plugin
        .handleKytheGetKytheEntries(KytheGetKytheEntriesParams(filePath1));
    expect(result, isNotNull);
    expect(result.entries, hasLength(3));
  }
}

class _TestEntryContributor implements EntryContributor {
  List<KytheEntry> entries;

  _TestEntryContributor(this.entries);

  @override
  void computeEntries(EntryRequest request, EntryCollector collector) {
    for (var entry in entries) {
      collector.addEntry(entry);
    }
  }
}

class _TestServerPlugin extends MockServerPlugin with EntryMixin {
  _TestServerPlugin(ResourceProvider resourceProvider)
      : super(resourceProvider);

  PrioritizedSourceChange createChange() {
    return PrioritizedSourceChange(0, SourceChange(''));
  }

  @override
  List<EntryContributor> getEntryContributors(String path) {
    var vName = KytheVName('', '', '', '', '');
    return <EntryContributor>[
      _TestEntryContributor(<KytheEntry>[
        KytheEntry(vName, '', target: vName),
        KytheEntry(vName, '', target: vName)
      ]),
      _TestEntryContributor(<KytheEntry>[KytheEntry(vName, '', target: vName)])
    ];
  }

  @override
  Future<EntryRequest> getEntryRequest(
      KytheGetKytheEntriesParams parameters) async {
    var result = MockResolvedUnitResult();
    return DartEntryRequestImpl(resourceProvider, result);
  }
}
