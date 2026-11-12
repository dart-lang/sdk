// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart' as protocol;
import 'package:analysis_server/src/services/completion/dart/candidate_suggestion.dart';
import 'package:analysis_server/src/services/completion/dart/completion_manager.dart';
import 'package:analysis_server/src/services/completion/dart/probability_range.dart';
import 'package:analysis_server/src/services/completion/dart/relevance_computer.dart';
import 'package:analysis_server/src/services/completion/dart/relevance_tables.g.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer_testing/src/single_unit.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../find_element.dart';
import '../../../../find_node.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RelevanceComputerTest);
  });
}

@reflectiveTest
class RelevanceComputerTest extends SingleUnitTest
    with FindElementMixin, FindNodeMixin {
  @override
  void setUp() {
    super.setUp();
    // Use basic relevance tables so we can test both included and missing
    // locations/element kinds.
    elementKindRelevance = {
      'TestLocation': {
        protocol.ElementKind.ENUM: const ProbabilityRange(
          lower: 0.1,
          upper: 0.5,
        ),
        protocol.ElementKind.MIXIN: const ProbabilityRange(
          lower: 0.0,
          upper: 0.0,
        ),
      },
    };
  }

  @override
  Future<void> tearDown() async {
    elementKindRelevance = defaultElementKindRelevance;
    await super.tearDown();
  }

  Future<void> test_completionLocation_missing() async {
    await resolveTestCode('''
class C {}
void f() {
  ^
}
''');
    var (computer, listener) = _createComputer(completionLocation: null);
    computer.computeRelevance(
      ClassSuggestion(
        importData: null,
        element: findElement.class_('C'),
        matcherScore: 0.0,
      ),
    );

    var block = findNode.singleBlock;
    expect(listener.missingLocations, [(block, block.rightBracket)]);
    expect(listener.missingTables, isEmpty);
    expect(listener.missingEntries, isEmpty);
  }

  Future<void> test_completionLocation_present() async {
    await resolveTestCode('''
enum E { a }
void f() {
  ^
}
''');
    var suggestion = EnumSuggestion(
      importData: null,
      element: findElement.enum_('E'),
      matcherScore: 0.0,
    );
    var (computer, listener) = _createComputer(
      completionLocation: 'TestLocation',
    );
    var relevance = computer.computeRelevance(suggestion);

    expect(listener.missingLocations, isEmpty);
    expect(listener.missingTables, isEmpty);
    expect(listener.missingEntries, isEmpty);

    // Only compare relative relevances, not exact values, which change whenever
    // the feature weights or relevance tables are tuned.
    var (noLocationComputer, _) = _createComputer(completionLocation: null);
    var noLocationRelevance = noLocationComputer.computeRelevance(suggestion);
    expect(relevance, greaterThan(noLocationRelevance));
  }

  Future<void> test_elementKind_entry_missing() async {
    await resolveTestCode('''
class C {}
extension E on int {}
// extension type ET(int i) {}
void f() {
  ^
}
''');
    var (computer, listener) = _createComputer(
      completionLocation: 'TestLocation',
    );
    computer.computeRelevance(
      ClassSuggestion(
        importData: null,
        element: findElement.class_('C'),
        matcherScore: 0.0,
      ),
    );
    computer.computeRelevance(
      ExtensionSuggestion(
        importData: null,
        element: findElement.extension_('E'),
        matcherScore: 0.0,
      ),
    );
    // TODO(dantup): Enable this when `EXTENSION_TYPE` is enabled in
    //  `FeatureComputer`.
    // computer.computeRelevance(
    //   ExtensionTypeSuggestion(
    //     importData: null,
    //     element: findElement.extensionType('ET'),
    //     matcherScore: 0.0,
    //   ),
    // );

    expect(listener.missingLocations, isEmpty);
    expect(listener.missingTables, isEmpty);
    expect(listener.missingEntries, [
      ('TestLocation', protocol.ElementKind.CLASS),
      ('TestLocation', protocol.ElementKind.EXTENSION),
      // ('TestLocation', protocol.ElementKind.EXTENSION_TYPE),
    ]);
  }

  /// Check that entries both with zero and non-zero ranges are not reported
  /// as missing.
  Future<void> test_elementKind_entry_present() async {
    await resolveTestCode('''
enum E { a }
mixin M {}
void f() {
  ^
}
''');
    var (computer, listener) = _createComputer(
      completionLocation: 'TestLocation',
    );
    var enumRelevance = computer.computeRelevance(
      EnumSuggestion(
        importData: null,
        element: findElement.enum_('E'),
        matcherScore: 0.0,
      ),
    );
    var mixinRelevance = computer.computeRelevance(
      MixinSuggestion(
        importData: null,
        element: findElement.mixin('M'),
        matcherScore: 0.0,
      ),
    );

    expect(listener.missingLocations, isEmpty);
    expect(listener.missingTables, isEmpty);
    expect(listener.missingEntries, isEmpty);

    // Only compare relative relevances, not exact values, which change whenever
    // the feature weights or relevance tables are tuned.
    expect(enumRelevance, greaterThan(mixinRelevance));
  }

  Future<void> test_elementKind_table_missing() async {
    await resolveTestCode('''
class C {}
void f() {
  ^
}
''');
    var (computer, listener) = _createComputer(
      completionLocation: 'MissingLocation',
    );
    computer.computeRelevance(
      ClassSuggestion(
        importData: null,
        element: findElement.class_('C'),
        matcherScore: 0.0,
      ),
    );

    expect(listener.missingLocations, isEmpty);
    expect(listener.missingTables, ['MissingLocation']);
    expect(listener.missingEntries, isEmpty);
  }

  Future<void> test_elementKind_table_present() async {
    await resolveTestCode('''
enum E { a }
void f() {
  ^
}
''');
    var suggestion = EnumSuggestion(
      importData: null,
      element: findElement.enum_('E'),
      matcherScore: 0.0,
    );
    var (computer, listener) = _createComputer(
      completionLocation: 'TestLocation',
    );
    var relevance = computer.computeRelevance(suggestion);

    expect(listener.missingLocations, isEmpty);
    expect(listener.missingTables, isEmpty);
    expect(listener.missingEntries, isEmpty);

    // Only compare relative relevances, not exact values, which change whenever
    // the feature weights or relevance tables are tuned.
    var (missingTableComputer, _) = _createComputer(
      completionLocation: 'MissingLocation',
    );
    var missingTableRelevance = missingTableComputer.computeRelevance(
      suggestion,
    );
    expect(relevance, greaterThan(missingTableRelevance));
  }

  (RelevanceComputer, _RecordingSuggestionListener) _createComputer({
    required String? completionLocation,
  }) {
    var request = DartCompletionRequest.forResolvedUnit(
      resolvedUnit: testAnalysisResult,
      offset: parsedTestCode.position.offset,
    );
    var listener = _RecordingSuggestionListener();
    var computer = RelevanceComputer(request, listener, targetPrefix: '')
      ..completionLocation = completionLocation;
    return (computer, listener);
  }
}

class _RecordingSuggestionListener implements SuggestionListener {
  final List<(AstNode, SyntacticEntity)> missingLocations = [];
  final List<String> missingTables = [];
  final List<(String, protocol.ElementKind)> missingEntries = [];

  @override
  void builtCandidate(CandidateSuggestion candidate) {}

  @override
  void builtSuggestion(CompletionSuggestionBuilder suggestionBuilder) {}

  @override
  void computedFeatures({
    double contextType = 0.0,
    double elementKind = 0.0,
    double hasDeprecated = 0.0,
    double isConstant = 0.0,
    double isNoSuchMethod = 0.0,
    double isNotImported = 0.0,
    double keyword = 0.0,
    double startsWithDollar = 0.0,
    double superMatches = 0.0,
    double inheritanceDistance = 0.0,
    double localVariableDistance = 0.0,
  }) {}

  @override
  void missingCompletionLocationAt(
    AstNode containingNode,
    SyntacticEntity entity,
  ) {
    missingLocations.add((containingNode, entity));
  }

  @override
  void missingElementKindEntryFor(
    String completionLocation,
    protocol.ElementKind elementKind,
  ) {
    missingEntries.add((completionLocation, elementKind));
  }

  @override
  void missingElementKindTableFor(String completionLocation) {
    missingTables.add(completionLocation);
  }
}
