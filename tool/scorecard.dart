// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:github/github.dart';
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

Iterable<String> get registeredLintNames => registeredLints.map((r) => r.name);

void main() async {
  var scorecard = await ScoreCard.calculate();
  var details = <Detail>[
    Detail.rule,
    Detail.linter,
    Detail.sdk,
    Detail.fix,
    Detail.pedantic,
    Detail.effectiveDart,
    Detail.flutterUser,
    Detail.flutterRepo,
    Detail.status,
    Detail.bugs,
  ];

  print(scorecard.asMarkdown(details));
  var footer = buildFooter(scorecard, details);
  print(footer);
}

StringBuffer buildFooter(ScoreCard scorecard, List<Detail> details) {
  var pedanticLintCount = 0;
  var flutterUserLintCount = 0;
  var flutterRepoLintCount = 0;
  var fixCount = 0;
  var pedanticFixCount = 0;

  for (var score in scorecard.scores) {
    for (var ruleSet in score.ruleSets) {
      if (ruleSet == 'pedantic') {
        ++pedanticLintCount;
        if (score.hasFix) {
          ++pedanticFixCount;
        }
      }
      if (ruleSet == 'flutter') {
        ++flutterUserLintCount;
      }
      if (ruleSet == 'flutter_repo') {
        ++flutterRepoLintCount;
      }
    }
    if (score.hasFix) {
      ++fixCount;
    }
  }

  var footer = StringBuffer('\n_${scorecard.lintCount} lints');

  var breakdowns = StringBuffer();
  if (details.contains(Detail.pedantic)) {
    breakdowns.write('$pedanticLintCount pedantic');
  }
  if (details.contains(Detail.flutterUser)) {
    if (breakdowns.isNotEmpty) {
      breakdowns.write(', ');
    }
    breakdowns.write('$flutterUserLintCount flutter user');
  }
  if (details.contains(Detail.flutterRepo)) {
    if (breakdowns.isNotEmpty) {
      breakdowns.write(', ');
    }
    breakdowns.write('$flutterRepoLintCount flutter repo');
  }

  if (breakdowns.isNotEmpty) {
    breakdowns.write('; ');
  }
  breakdowns.write('$fixCount w/ fixes');
  if (details.contains(Detail.pedantic)) {
    breakdowns.write(' ($pedanticFixCount pedantic)');
  }

  if (breakdowns.isNotEmpty) {
    footer.write(': $breakdowns');
  }

  footer.writeln('_');
  return footer;
}

class Header {
  final String markdown;
  const Header(this.markdown);
  static const Header left = Header('| :--- ');
  static const Header center = Header('| :---: ');
}

class Detail {
  final String name;
  final Header header;
  const Detail(this.name, {this.header = Header.center});

  static const Detail rule = Detail('name', header: Header.left);
  static const Detail linter = Detail('linter', header: Header.left);
  static const Detail sdk = Detail('dart sdk', header: Header.left);
  static const Detail fix = Detail('fix');
  static const Detail pedantic = Detail('pedantic');
  static const Detail effectiveDart = Detail('effective_dart');
  static const Detail flutterUser = Detail('flutter user');
  static const Detail flutterRepo = Detail('flutter repo');
  static const Detail status = Detail('status');
  static const Detail bugs = Detail('bug refs', header: Header.left);
}

class _AssistCollector extends GeneralizingAstVisitor<void> {
  final List<String> lintNames = <String>[];
  @override
  void visitNamedExpression(NamedExpression node) {
    if (node.name.toString() == 'associatedErrorCodes:') {
      final list = node.expression as ListLiteral;
      for (var element in list.elements) {
        var name =
            element.toString().substring(1, element.toString().length - 1);
        lintNames.add(name);
        if (!registeredLintNames.contains(name)) {
          print('WARNING: unrecognized lint in assists: $name');
        }
      }
    }
  }
}

class _FixCollector extends GeneralizingAstVisitor<void> {
  final List<String> lintNames = <String>[];

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    for (var v in node.fields.variables) {
      var name = v.name.name;
      lintNames.add(name);
      if (!registeredLintNames.contains(name)) {
        print('WARNING: unrecognized lint in fixes: $name');
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

  void forEach(void Function(LintScore element) f) {
    scores.forEach(f);
  }

  String asMarkdown(List<Detail> details) {
    // Header.
    var sb = StringBuffer();
    details.forEach((detail) => sb.write('| ${detail.name} '));
    sb.write('|\n');
    details.forEach((detail) => sb.write(detail.header.markdown));
    sb.write(' |\n');

    // Body.
    forEach((lint) => sb.write('${lint.toMarkdown(details)}\n'));
    return sb.toString();
  }

  static Future<List<String>> _getLintsWithFixes() async {
    var client = http.Client();
    var req = await client.get(
        'https://raw.githubusercontent.com/dart-lang/sdk/master/pkg/analysis_server/lib/src/services/linter/lint_names.dart');

    var parser = CompilationUnitParser();
    var cu = parser.parse(contents: req.body, name: 'lint_names.dart');
    var lintNamesClass = cu.declarations
        .firstWhere((m) => m is ClassDeclaration && m.name.name == 'LintNames');

    var collector = _FixCollector();
    lintNamesClass.accept(collector);
    return collector.lintNames;
  }

  static Future<List<String>> _getLintsWithAssists() async {
    var client = http.Client();
    var req = await client.get(
        'https://raw.githubusercontent.com/dart-lang/sdk/master/pkg/analysis_server/lib/src/services/correction/assist.dart');
    var parser = CompilationUnitParser();
    var cu = parser.parse(contents: req.body, name: 'assist.dart');
    var assistKindClass = cu.declarations.firstWhere(
        (m) => m is ClassDeclaration && m.name.name == 'DartAssistKind');

    var collector = _AssistCollector();
    assistKindClass.accept(collector);
    return collector.lintNames;
  }

  static Future<List<Issue>> _getIssues() async {
    var github = GitHub();
    var slug = RepositorySlug('dart-lang', 'linter');
    try {
      return github.issues.listByRepo(slug).toList();
    } on Exception catch (e) {
      print('exception caught fetching github issues');
      print(e);
      print('(defaulting to an empty list)');
      return Future.value(<Issue>[]);
    }
  }

  static Future<ScoreCard> calculate() async {
    var lintsWithFixes = await _getLintsWithFixes();
    var lintsWithAssists = await _getLintsWithAssists();
    var flutterRuleset = await flutterRules;
    var flutterRepoRuleset = await flutterRepoRules;
    var pedanticRuleset = await pedanticRules;
    var effectiveDartRuleset = await effectiveDartRules;

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
      if (effectiveDartRuleset.contains(lint.name)) {
        ruleSets.add('effective_dart');
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

  void removeWhere(bool Function(LintScore element) test) {
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
  String toString() => '$name$_ruleSets${hasFix ? " $bulb" : ""}';

  String toMarkdown(List<Detail> details) {
    var sb = StringBuffer('| ');
    for (var detail in details) {
      switch (detail) {
        case Detail.rule:
          sb.write(
              ' [$name](https://dart-lang.github.io/linter/lints/$name.html) |');
          break;
        case Detail.linter:
          sb.write(' ${since.sinceLinter} |');
          break;
        case Detail.sdk:
          sb.write(' ${since.sinceDartSdk} |');
          break;
        case Detail.fix:
          sb.write('${hasFix ? " $bulb" : ""} |');
          break;
        case Detail.pedantic:
          sb.write('${ruleSets.contains('pedantic') ? " $checkMark" : ""} |');
          break;
        case Detail.effectiveDart:
          sb.write(
              '${ruleSets.contains('effective_dart') ? " $checkMark" : ""} |');
          break;
        case Detail.flutterUser:
          sb.write('${ruleSets.contains('flutter') ? " $checkMark" : ""} |');
          break;
        case Detail.flutterRepo:
          sb.write(
              '${ruleSets.contains('flutter_repo') ? " $checkMark" : ""} |');
          break;
        case Detail.status:
          sb.write('${maturity != 'stable' ? ' **$maturity** ' : ""} |');
          break;
        case Detail.bugs:
          sb.write(' ${bugReferences.join(", ")} |');
          break;
      }
    }
    return sb.toString();
  }
}
