// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/plugin/protocol/protocol.dart' as server;
import 'package:analysis_server/src/plugin/request_converter.dart';
import 'package:analysis_server/src/protocol/protocol_internal.dart' as server;
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'protocol_test_utilities.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RequestConverterTest);
  });
}

@reflectiveTest
class RequestConverterTest extends ProtocolTestUtilities {
  RequestConverter converter = new RequestConverter();

  void test_convertAnalysisService() {
    Map<plugin.AnalysisService, server.AnalysisService> kindMap =
        <plugin.AnalysisService, server.AnalysisService>{
      plugin.AnalysisService.FOLDING: server.AnalysisService.FOLDING,
      plugin.AnalysisService.HIGHLIGHTS: server.AnalysisService.HIGHLIGHTS,
      plugin.AnalysisService.NAVIGATION: server.AnalysisService.NAVIGATION,
      plugin.AnalysisService.OCCURRENCES: server.AnalysisService.OCCURRENCES,
      plugin.AnalysisService.OUTLINE: server.AnalysisService.OUTLINE,
    };
    kindMap.forEach(
        (plugin.AnalysisService pluginKind, server.AnalysisService serverKind) {
      expect(converter.convertAnalysisService(serverKind), pluginKind);
    });
  }

  void test_convertFileOverlay_add() {
    String content = 'content';
    plugin.AddContentOverlay result =
        converter.convertFileOverlay(new server.AddContentOverlay(content));
    expect(result, isNotNull);
    expect(result.content, content);
  }

  void test_convertFileOverlay_change() {
    List<server.SourceEdit> serverEdits = <server.SourceEdit>[
      new server.SourceEdit(10, 5, 'a'),
      new server.SourceEdit(20, 6, 'b'),
      new server.SourceEdit(30, 7, 'c'),
    ];
    plugin.ChangeContentOverlay result = converter
        .convertFileOverlay(new server.ChangeContentOverlay(serverEdits));
    expect(result, isNotNull);
    List<plugin.SourceEdit> pluginEdits = result.edits;
    int editCount = serverEdits.length;
    expect(pluginEdits, hasLength(editCount));
    for (int i = 0; i < editCount; i++) {
      server.SourceEdit serverEdit = serverEdits[i];
      plugin.SourceEdit pluginEdit = pluginEdits[i];
      expect(pluginEdit.offset, serverEdit.offset);
      expect(pluginEdit.length, serverEdit.length);
      expect(pluginEdit.replacement, serverEdit.replacement);
    }
  }

  void test_convertFileOverlay_remove() {
    plugin.RemoveContentOverlay result =
        converter.convertFileOverlay(new server.RemoveContentOverlay());
    expect(result, isNotNull);
  }

  void test_convertSourceEdit() {
    int offset = 5;
    int length = 3;
    String replacement = 'x';
    plugin.SourceEdit result = converter
        .convertSourceEdit(new server.SourceEdit(offset, length, replacement));
    expect(result, isNotNull);
    expect(result.offset, offset);
    expect(result.length, length);
    expect(result.replacement, replacement);
  }
}
