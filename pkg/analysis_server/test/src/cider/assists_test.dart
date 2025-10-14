// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/cider/assists.dart';
import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/assist_internal.dart';
import 'package:analysis_server_plugin/edit/assist/assist.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' show SourceEdit;
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_testing/mock_packages/mock_packages.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../utils/matchers.dart';
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

  void assertHasAssist(AssistKind kind, String expected) {
    var assist = _getAssist(kind);

    var fileEdits = assist.change.edits;
    expect(fileEdits, hasLength(1));

    var resultContent = SourceEdit.applySequence(
      _correctionContext.content,
      fileEdits.single.edits,
    );
    expect(resultContent, equalsNormalized(expected));
  }

  @override
  void setUp() {
    super.setUp();
    registerBuiltInAssistGenerators();
    BlazeMockPackages.instance.addFlutter(resourceProvider);
  }

  Future<void> test_addReturnType() async {
    await _compute(r'''
void m() {
  ^f() {
    return '';
  }
}
''');

    assertHasAssist(DartAssistKind.addReturnType, r'''
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

    assertHasAssist(DartAssistKind.flutterWrapStreamBuilder, r'''
import 'package:flutter/widgets.dart';

void f() {
  StreamBuilder(
    stream: stream,
    builder: (context, asyncSnapshot) {
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

    assertHasAssist(DartAssistKind.assignToLocalVariable, r'''
void f() {
  var i = 12345;
}
''');
  }

  Future<void> _compute(String content) async {
    _updateFile(content);

    var result = await CiderAssistsComputer(logger, fileResolver).compute(
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
    var code = TestCode.parseNormalized(content);
    var offset = code.position.offset;

    content = code.code;
    var lineInfo = LineInfo.fromContent(content);
    var location = lineInfo.getLocation(offset);

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
