// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/src/lint/registry.dart';
import 'package:github/server.dart';
import 'package:http/http.dart' as http;
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/rules.dart';

import 'crawl.dart';
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
  var scorecard = await ScoreCard.calculate();

  //printAll(scorecard);
  printMarkdownTable(scorecard);
}

void printAll(ScoreCard scorecard) {
  print('-- ALL -----------------------------------------');
  scorecard.forEach(print);
}

void printMarkdownTable(ScoreCard scorecard) {
  print(
      '| name | linter | dart sdk | fix | flutter user | flutter repo | pedantic | stagehand | status | bug refs |');
  print(
      '| :--- | :--- | :--- | :---: | :---:| :---: | :---: | :---: | :---: | :--- |');
  scorecard.forEach((lint) {
    var sb = StringBuffer('| `${lint.name}` |');
    sb.write(' ${lint.since.sinceLinter} |');
    sb.write(' ${lint.since.sinceDartSdk} |');
    sb.write('${lint.hasFix ? " $bulb" : ""} |');
    sb.write('${lint.ruleSets.contains('flutter') ? " $checkMark" : ""} |');
    sb.write(
        '${lint.ruleSets.contains('flutter_repo') ? " $checkMark" : ""} |');
    sb.write('${lint.ruleSets.contains('pedantic') ? " $checkMark" : ""} |');
    sb.write('${lint.ruleSets.contains('stagehand') ? " $checkMark" : ""} |');
    sb.write('${lint.maturity != 'stable' ? ' **${lint.maturity}** ' : ""} |');
    sb.write(' ${lint.bugReferences.join(", ")} |');
    print(sb.toString());
  });
}

class ScoreCard {
  int get lintCount => registeredLints.length;

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

  static Future<List<Issue>> _getIssues() async {
    var github = createGitHubClient();
    var slug = RepositorySlug('dart-lang', 'linter');
    return github.issues.listByRepo(slug).toList();
  }

  static Future<ScoreCard> calculate() async {
    var lintsWithFixes = await _getLintsWithFixes();
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
      if (stagehandRuleset.contains(lint.name)) {
        ruleSets.add('stagehand');
      }
      var bugReferences = <String>[];
      for (var bug in bugs) {
        if (bug.title.contains(lint.name)) {
          bugReferences.add('#${bug.number.toString()}');
        }
      }

      scorecard.add(LintScore(
          name: lint.name,
          hasFix: lintsWithFixes.contains(lint.name),
          maturity: lint.maturity.name,
          ruleSets: ruleSets,
          since: sinceInfo[lint.name],
          bugReferences: bugReferences));
    }

    return scorecard;
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
