// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/plugin/edit/assist/assist_core.dart';
import 'package:analysis_server/src/cider/assists.dart';
import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/assist_internal.dart';
import 'package:analysis_server/src/services/correction/fix_processor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' show SourceEdit;
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../utilities/mock_packages.dart';
import 'cider_service.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CiderAssistsComputerTest);
  });
}

@reflectiveTest
class CiderAssistsComputerTest extends CiderServiceTest {
  late _CorrectionContext _correctionContext;
  late List<Assist> _assists;

  /// A mapping of [ProducerGenerator]s to the set of lint names with which they
  /// are associated (can fix).
  late Map<ProducerGenerator, Set<String>> _producerGeneratorsForLintRules;

  void assertHasAssist(AssistKind kind, String expected) {
    var assist = _getAssist(kind);

    var fileEdits = assist.change.edits;
    expect(fileEdits, hasLength(1));

    var resultContent = SourceEdit.applySequence(
      _correctionContext.content,
      fileEdits.single.edits,
    );
    expect(resultContent, expected);
  }

  @override
  void setUp() {
    super.setUp();
    BlazeMockPackages.instance.addFlutter(resourceProvider);
    _producerGeneratorsForLintRules = AssistProcessor.computeLintRuleMap();
  }

  Future<void> test_addReturnType() async {
    await _compute(r'''
void m() {
  ^f() {
    return '';
  }
}
''');

    assertHasAssist(DartAssistKind.ADD_RETURN_TYPE, r'''
void m() {
  String f() {
    return '';
  }
}
''');
  }

  Future<void> test_aroundText() async {
    await _compute('''
import 'package:flutter/widgets.dart';

void f() {
  ^Text('a');
}
''');

    assertHasAssist(DartAssistKind.FLUTTER_WRAP_STREAM_BUILDER, r'''
import 'package:flutter/widgets.dart';

void f() {
  StreamBuilder<Object>(
    stream: null,
    builder: (context, snapshot) {
      return Text('a');
    }
  );
}
''');
  }

  Future<void> test_assignToLocalVariable() async {
    await _compute(r'''
void f() {
  12^345;
}
''');

    assertHasAssist(DartAssistKind.ASSIGN_TO_LOCAL_VARIABLE, r'''
void f() {
  var i = 12345;
}
''');
  }

  Future<void> _compute(String content) async {
    _updateFile(content);

    var result = await CiderAssistsComputer(
      logger,
      fileResolver,
      _producerGeneratorsForLintRules,
    ).compute(
      convertPath(testPath),
      _correctionContext.line,
      _correctionContext.character,
      0,
    );
    _assists = result;
  }

  Assist _getAssist(AssistKind kind) {
    for (var assist in _assists) {
      if (assist.kind == kind) {
        return assist;
      }
    }
    fail('No assist $kind');
  }

  void _updateFile(String content) {
    var offset = content.indexOf('^');
    expect(offset, isPositive, reason: 'Expected to find ^');
    expect(content.indexOf('^', offset + 1), -1, reason: 'Expected only one ^');

    var lineInfo = LineInfo.fromContent(content);
    var location = lineInfo.getLocation(offset);

    content = content.substring(0, offset) + content.substring(offset + 1);
    newFile(testPath, content);

    _correctionContext = _CorrectionContext(
      content,
      offset,
      location.lineNumber - 1,
      location.columnNumber - 1,
    );
  }
}

class _CorrectionContext {
  final String content;
  final int offset;
  final int line;
  final int character;

  _CorrectionContext(this.content, this.offset, this.line, this.character);
}
