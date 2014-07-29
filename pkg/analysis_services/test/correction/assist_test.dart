// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library test.services.correction.assist;

import 'package:analysis_services/correction/assist.dart';
import 'package:analysis_services/correction/change.dart';
import 'package:analysis_services/index/index.dart';
import 'package:analysis_services/index/local_memory_index.dart';
import 'package:analysis_services/src/search/search_engine.dart';
import 'package:analysis_testing/abstract_single_unit.dart';
import 'package:analysis_testing/reflective_tests.dart';
import 'package:unittest/unittest.dart';


main() {
  groupSep = ' | ';
  runReflectiveTests(AssistProcessorTest);
}


@ReflectiveTestCase()
class AssistProcessorTest extends AbstractSingleUnitTest {
  Index index;
  SearchEngineImpl searchEngine;

  int offset;
  int length;

  Assist assist;
  Change change;
  String resultCode;

  /**
   * Asserts that there is an [Assist] of the given [kind] at [offset] which
   * produces the [expected] code when applied to [testCode].
   */
  void assertHasAssist(AssistKind kind, String expected) {
    assist = _assertHasAssist(kind);
    change = assist.change;
    // apply to "file"
    List<FileEdit> fileEdits = change.edits;
    expect(fileEdits, hasLength(1));
    resultCode = _applyEdits(testCode, change.edits[0].edits);
    // verify
    expect(resultCode, expected);
  }

  /**
   * Calls [assertHasAssist] at the offset of [offsetSearch] in [testCode].
   */
  void assertHasAssistAt(String offsetSearch, AssistKind kind,
      String expected) {
    offset = findOffset(offsetSearch);
    assertHasAssist(kind, expected);
  }

  void assertHasPositionGroup(String id, List<Position> expectedPositions) {
    List<LinkedPositionGroup> linkedPositionGroups =
        change.linkedPositionGroups;
    for (LinkedPositionGroup group in linkedPositionGroups) {
      if (group.id == id) {
        expect(group.positions, unorderedEquals(expectedPositions));
        return;
      }
    }
    fail('No PositionGroup with id=$id found in $linkedPositionGroups');
  }

  /**
   * Asserts that there is no [Assist] of the given [kind] at [offset].
   */
  void assertNoAssist(AssistKind kind) {
    List<Assist> assists =
        computeAssists(searchEngine, testUnit, offset, length);
    for (Assist assist in assists) {
      if (assist.kind == kind) {
        throw fail('Unexpected assist $kind in\n${assists.join('\n')}');
      }
    }
  }

  /**
   * Calls [assertNoAssist] at the offset of [offsetSearch] in [testCode].
   */
  void assertNoAssistAt(String offsetSearch, AssistKind kind) {
    offset = findOffset(offsetSearch);
    assertNoAssist(kind);
  }

  Position expectedPosition(String search) {
    int offset = resultCode.indexOf(search);
    int length = getLeadingIdentifierLength(search);
    return new Position(testFile, offset, length);
  }

  List<Position> expectedPositions(List<String> patterns) {
    List<Position> positions = <Position>[];
    patterns.forEach((String search) {
      positions.add(expectedPosition(search));
    });
    return positions;
  }

  void setUp() {
    super.setUp();
    index = createLocalMemoryIndex();
    searchEngine = new SearchEngineImpl(index);
    offset = 0;
    length = 0;
  }

  void test_addTypeAnnotation_classField_OK_final() {
    _indexTestUnit('''
class A {
  final f = 0;
}
''');
    assertHasAssistAt('final ', AssistKind.ADD_TYPE_ANNOTATION, '''
class A {
  final int f = 0;
}
''');
  }

  void test_addTypeAnnotation_classField_OK_int() {
    _indexTestUnit('''
class A {
  var f = 0;
}
''');
    assertHasAssistAt('var ', AssistKind.ADD_TYPE_ANNOTATION, '''
class A {
  int f = 0;
}
''');
  }

  void test_addTypeAnnotation_local_OK_Function() {
    _indexTestUnit('''
main() {
  var v = () => 1;
}
''');
    assertHasAssistAt('v =', AssistKind.ADD_TYPE_ANNOTATION, '''
main() {
  Function v = () => 1;
}
''');
  }

  void test_addTypeAnnotation_local_OK_List() {
    _indexTestUnit('''
main() {
  var v = <String>[];
}
''');
    assertHasAssistAt('v =', AssistKind.ADD_TYPE_ANNOTATION, '''
main() {
  List<String> v = <String>[];
}
''');
  }

  void test_addTypeAnnotation_local_OK_int() {
    _indexTestUnit('''
main() {
  var v = 0;
}
''');
    assertHasAssistAt('v =', AssistKind.ADD_TYPE_ANNOTATION, '''
main() {
  int v = 0;
}
''');
  }

  void test_addTypeAnnotation_local_OK_onInitializer() {
    _indexTestUnit('''
main() {
  var v = 123;
}
''');
    assertHasAssistAt('23', AssistKind.ADD_TYPE_ANNOTATION, '''
main() {
  int v = 123;
}
''');
  }

  void test_addTypeAnnotation_local_OK_onName() {
    _indexTestUnit('''
main() {
  var abc = 0;
}
''');
    assertHasAssistAt('bc', AssistKind.ADD_TYPE_ANNOTATION, '''
main() {
  int abc = 0;
}
''');
  }

  void test_addTypeAnnotation_local_OK_onVar() {
    _indexTestUnit('''
main() {
  var v = 0;
}
''');
    assertHasAssistAt('var ', AssistKind.ADD_TYPE_ANNOTATION, '''
main() {
  int v = 0;
}
''');
  }

  void test_addTypeAnnotation_local_wrong_hasTypeAnnotation() {
    _indexTestUnit('''
main() {
  int v = 42;
}
''');
    assertNoAssistAt(' = 42', AssistKind.ADD_TYPE_ANNOTATION);
  }

  void test_addTypeAnnotation_local_wrong_multiple() {
    _indexTestUnit('''
main() {
  var a = 1, b = '';
}
''');
    assertNoAssistAt('var ', AssistKind.ADD_TYPE_ANNOTATION);
  }

  void test_addTypeAnnotation_local_wrong_noValue() {
    verifyNoTestUnitErrors = false;
    _indexTestUnit('''
main() {
  var v;
}
''');
    assertNoAssistAt('var ', AssistKind.ADD_TYPE_ANNOTATION);
  }

  void test_addTypeAnnotation_local_wrong_null() {
    _indexTestUnit('''
main() {
  var v = null;
}
''');
    assertNoAssistAt('var ', AssistKind.ADD_TYPE_ANNOTATION);
  }

  void test_addTypeAnnotation_local_wrong_unknown() {
    verifyNoTestUnitErrors = false;
    _indexTestUnit('''
main() {
  var v = unknownVar;
}
''');
    assertNoAssistAt('var ', AssistKind.ADD_TYPE_ANNOTATION);
  }

  void test_addTypeAnnotation_topLevelField_OK_int() {
    _indexTestUnit('''
var V = 0;
''');
    assertHasAssistAt('var ', AssistKind.ADD_TYPE_ANNOTATION, '''
int V = 0;
''');
  }

  void test_addTypeAnnotation_topLevelField_wrong_multiple() {
    _indexTestUnit('''
var A = 1, V = '';
''');
    assertNoAssistAt('var ', AssistKind.ADD_TYPE_ANNOTATION);
  }

  void test_addTypeAnnotation_topLevelField_wrong_noValue() {
    _indexTestUnit('''
var V;
''');
    assertNoAssistAt('var ', AssistKind.ADD_TYPE_ANNOTATION);
  }

  String _applyEdits(String code, List<Edit> edits) {
    edits.sort((a, b) => b.offset - a.offset);
    edits.forEach((Edit edit) {
      code = code.substring(0, edit.offset) +
          edit.replacement +
          code.substring(edit.end);
    });
    return code;
  }

  /**
   * Computes assists and verifies that there is an assist of the given kind.
   */
  Assist _assertHasAssist(AssistKind kind) {
    List<Assist> assists =
        computeAssists(searchEngine, testUnit, offset, length);
    for (Assist assist in assists) {
      if (assist.kind == kind) {
        return assist;
      }
    }
    throw fail('Expected to find assist $kind in\n${assists.join('\n')}');
  }

  void _assertHasLinkedPositions(String groupId, List<String> expectedStrings) {
    List<Position> expectedPositions = _findResultPositions(expectedStrings);
    List<LinkedPositionGroup> groups = change.linkedPositionGroups;
    for (LinkedPositionGroup group in groups) {
      if (group.id == groupId) {
        List<Position> actualPositions = group.positions;
        expect(actualPositions, unorderedEquals(expectedPositions));
        return;
      }
    }
    fail('No group with ID=$groupId foind in\n${groups.join('\n')}');
  }

  void _assertHasLinkedProposals(String groupId, List<String> expected) {
    List<LinkedPositionGroup> groups = change.linkedPositionGroups;
    for (LinkedPositionGroup group in groups) {
      if (group.id == groupId) {
        expect(group.proposals, expected);
        return;
      }
    }
    fail('No group with ID=$groupId foind in\n${groups.join('\n')}');
  }

  List<Position> _findResultPositions(List<String> searchStrings) {
    List<Position> positions = <Position>[];
    for (String search in searchStrings) {
      int offset = resultCode.indexOf(search);
      int length = getLeadingIdentifierLength(search);
      positions.add(new Position(testFile, offset, length));
    }
    return positions;
  }

  void _indexTestUnit(String code) {
    resolveTestUnit(code);
    index.indexUnit(context, testUnit);
  }
}
