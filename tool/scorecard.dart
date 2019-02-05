// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/lint/registry.dart';

import 'package:github/server.dart';
import 'package:http/http.dart' as http;
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/rules.dart';

import 'crawl.dart';
import 'parse.dart';
import 'since.dart';

const bulb = '💡';
const checkMark = '✅';

Iterable<LintRule> _registeredLints;

Iterable<LintRule> get registeredLints {
  if (_registeredLints == null) {
    registerLintRules();
    _registeredLints = Registry.ruleRegistry.toList()
      ..sort((l1, l2) => l1.name.compareTo(l2.name));
  }
  return _registeredLints;
}

main() async {
  // Lens on just ruleset comparisons.
  // See: https://github.com/dart-lang/linter/issues/1365.
  var ruleSetLens = false;

  var scorecard = await ScoreCard.calculate();
  var totalLintCount = scorecard.lintCount;

  if (ruleSetLens) {
    scorecard.removeWhere((LintScore score) =>
        score.ruleSets.isEmpty ||
        (ruleSetLens &&
            score.ruleSets.length == 1 &&
            score.ruleSets[0] == 'flutter_repo'));
  }

  //printAll(scorecard);
  printMarkdownTable(scorecard, justRules: ruleSetLens);

  var footer = new StringBuffer('\n_$totalLintCount lints');
  if (ruleSetLens) {
    var filteredCount = totalLintCount - scorecard.lintCount;
    footer.write(' ($filteredCount w/o rulesets not shown)');
  }
  footer.writeln('_');

  print(footer);
}

void printAll(ScoreCard scorecard) {
  print('-- ALL -----------------------------------------');
  scorecard.forEach(print);
}

const allHeader = [
  '| name | linter | dart sdk | fix | pedantic |  flutter user | flutter repo | status | bug refs |',
  '| :--- | :--- | :--- | :---: | :---:|  :---: | :---: | :---: | :--- |'
];

/// https://github.com/dart-lang/linter/issues/1365
const justRuleSetsHeader = [
  '| name | pedantic | flutter user |',
  '| :--- | :---: | :---: |'
];

void printMarkdownTable(ScoreCard scorecard, {bool justRules = false}) {
  print(justRules ? justRuleSetsHeader[0] : allHeader[0]);
  print(justRules ? justRuleSetsHeader[1] : allHeader[1]);
  scorecard.forEach((lint) {
    var sb = StringBuffer('| `${lint.name}` |');
    if (!justRules) {
      sb.write(' ${lint.since.sinceLinter} |');
      sb.write(' ${lint.since.sinceDartSdk} |');
      sb.write('${lint.hasFix ? " $bulb" : ""} |');
    }
    sb.write('${lint.ruleSets.contains('pedantic') ? " $checkMark" : ""} |');
    sb.write('${lint.ruleSets.contains('flutter') ? " $checkMark" : ""} |');
    if (!justRules) {
      sb.write(
          '${lint.ruleSets.contains('flutter_repo') ? " $checkMark" : ""} |');
      sb.write(
          '${lint.maturity != 'stable' ? ' **${lint.maturity}** ' : ""} |');
      sb.write(' ${lint.bugReferences.join(", ")} |');
    }
    print(sb.toString());
  });
}

class _AssistCollector extends GeneralizingAstVisitor<void> {
  final List<String> lintNames = <String>[];
  @override
  void visitNamedExpression(NamedExpression node) {
    if (node.name.toString() == 'associatedErrorCodes:') {
      ListLiteral list = node.expression;
      for (var element in list.elements) {
        var name =
            element.toString().substring(1, element.toString().length - 1);
        lintNames.add(name);
      }
    }
  }
}

class ScoreCard {
  int get lintCount => scores.length;

  List<LintScore> scores = <LintScore>[];

  void add(LintScore score) {
    scores.add(score);
  }

  void forEach(void f(LintScore element)) {
    scores.forEach(f);
  }

  static Future<List<String>> _getLintsWithFixes() async {
    var client = http.Client();
    var req = await client.get(
        'https://raw.githubusercontent.com/dart-lang/sdk/master/pkg/analysis_server/lib/src/services/correction/fix_internal.dart');
    var lintsWithFixes = <String>[];
    for (var word in req.body.split(RegExp('\\s+'))) {
      if (word.startsWith('LintNames.')) {
        var lintName = word.substring(10);
        if (lintName.endsWith(')')) {
          lintName = lintName.substring(0, lintName.length - 1);
        }
        lintsWithFixes.add(lintName);
      }
    }
    return lintsWithFixes;
  }

  static Future<List<String>> _getLintsWithAssists() async {
    var client = http.Client();
    var req = await client.get(
        'https://raw.githubusercontent.com/dart-lang/sdk/master/pkg/analysis_server/lib/src/services/correction/assist.dart');
    var parser = new CompilationUnitParser();
    var cu = parser.parse(contents: req.body, name: 'assist.dart');
    var assistKindClass = cu.declarations.firstWhere(
        (m) => m is ClassDeclaration && m.name.name == 'DartAssistKind');

    var collector = new _AssistCollector();
    assistKindClass.accept(collector);
    return collector.lintNames;
  }

  static Future<List<Issue>> _getIssues() async {
    var github = createGitHubClient();
    var slug = RepositorySlug('dart-lang', 'linter');
    return github.issues.listByRepo(slug).toList();
  }

  static Future<ScoreCard> calculate() async {
    var lintsWithFixes = await _getLintsWithFixes();
    var lintsWithAssists = await _getLintsWithAssists();
    var flutterRuleset = await flutterRules;
    var flutterRepoRuleset = await flutterRepoRules;
    var pedanticRuleset = await pedanticRules;
    var stagehandRuleset = await stagehandRules;

    var issues = await _getIssues();
    var bugs = issues.where(_isBug).toList();
    var sinceInfo = await sinceMap;

    var scorecard = ScoreCard();
    for (var lint in registeredLints) {
      var ruleSets = <String>[];
      if (flutterRuleset.contains(lint.name)) {
        ruleSets.add('flutter');
      }
      if (flutterRepoRuleset.contains(lint.name)) {
        ruleSets.add('flutter_repo');
      }
      if (pedanticRuleset.contains(lint.name)) {
        ruleSets.add('pedantic');
      }
      var bugReferences = <String>[];
      for (var bug in bugs) {
        if (bug.title.contains(lint.name)) {
          bugReferences.add('#${bug.number.toString()}');
        }
      }

      scorecard.add(LintScore(
          name: lint.name,
          hasFix: lintsWithFixes.contains(lint.name) ||
              lintsWithAssists.contains(lint.name),
          maturity: lint.maturity.name,
          ruleSets: ruleSets,
          since: sinceInfo[lint.name],
          bugReferences: bugReferences));
    }

    return scorecard;
  }

  void removeWhere(bool test(LintScore element)) {
    scores.removeWhere(test);
  }
}

bool _isBug(Issue issue) => issue.labels.map((l) => l.name).contains('bug');

class LintScore {
  String name;
  bool hasFix;
  String maturity;
  SinceInfo since;

  List<String> ruleSets;
  List<String> bugReferences;

  LintScore(
      {this.name,
      this.hasFix,
      this.maturity,
      this.ruleSets,
      this.bugReferences,
      this.since});

  String get _ruleSets => ruleSets.isNotEmpty ? ' ${ruleSets.toString()}' : '';

  @override
  String toString() => '$name$_ruleSets${hasFix ? " 💡" : ""}';
}
