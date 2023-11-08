// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer/src/lint/state.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/rules.dart';
import 'package:linter/src/utils.dart';

import '../test/test_constants.dart';
import 'crawl.dart';
import 'parse.dart';
import 'since.dart';

void main() async {
  var scorecard = await ScoreCard.calculate();
  var details = <Detail>[
    Detail.rule,
    Detail.sdk,
    Detail.fix,
    Detail.flutterUser,
    Detail.flutterRepo,
    Detail.status,
  ];

  printToConsole(scorecard.asMarkdown(details));
  var footer = buildFooter(scorecard, details);
  printToConsole(footer);
}

const bulb = '💡';

const checkMark = '✅';

Iterable<LintRule>? _registeredLints;

Iterable<String> get registeredLintNames => registeredLints!.map((r) => r.name);

Iterable<LintRule>? get registeredLints {
  if (_registeredLints == null) {
    registerLintRules();
    _registeredLints = Registry.ruleRegistry.toList()
      ..sort((l1, l2) => l1.name.compareTo(l2.name));
  }
  return _registeredLints;
}

StringBuffer buildFooter(ScoreCard scorecard, List<Detail> details) {
  var flutterUserLintCount = 0;
  var flutterRepoLintCount = 0;
  var fixCount = 0;

  for (var score in scorecard.scores) {
    for (var ruleSet in score.ruleSets) {
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

  if (breakdowns.isNotEmpty) {
    footer.write(': $breakdowns');
  }

  footer.writeln('_');
  return footer;
}

class Detail {
  static const Detail rule = Detail('name', header: Header.left);
  static const Detail sdk = Detail('dart sdk', header: Header.left);
  static const Detail fix = Detail('fix');
  static const Detail flutterUser = Detail('flutter user');
  static const Detail flutterRepo = Detail('flutter repo');
  static const Detail status = Detail('status');
  final String name;
  final Header header;
  const Detail(this.name, {this.header = Header.center});
}

class Header {
  static const Header left = Header('| :--- ');

  static const Header center = Header('| :---: ');

  final String markdown;
  const Header(this.markdown);
}

class LintScore {
  String name;
  bool hasFix;
  State state;
  SinceInfo? since;

  List<String> ruleSets;

  LintScore(
      {required this.name,
      required this.hasFix,
      required this.state,
      required this.ruleSets,
      this.since});

  String get _ruleSets => ruleSets.isNotEmpty ? ' $ruleSets' : '';

  String toMarkdown(List<Detail> details) {
    var sb = StringBuffer('| ');
    for (var detail in details) {
      switch (detail) {
        case Detail.rule:
          sb.write(' [$name](https://dart.dev/lints/$name) |');
        case Detail.sdk:
          sb.write(' ${since!.sinceDartSdk} |');
        case Detail.fix:
          sb.write('${hasFix ? " $bulb" : ""} |');
        case Detail.flutterUser:
          sb.write('${ruleSets.contains('flutter') ? " $checkMark" : ""} |');
        case Detail.flutterRepo:
          sb.write(
              '${ruleSets.contains('flutter_repo') ? " $checkMark" : ""} |');
        case Detail.status:
          sb.write('${!state.isStable ? ' **${state.label}** ' : ""} |');
      }
    }
    return sb.toString();
  }

  @override
  String toString() => '$name$_ruleSets${hasFix ? " $bulb" : ""}';
}

class ScoreCard {
  List<LintScore> scores = <LintScore>[];

  int get lintCount => scores.length;

  void add(LintScore score) {
    scores.add(score);
  }

  String asMarkdown(List<Detail> details) {
    // Header.
    var sb = StringBuffer();
    for (var detail in details) {
      sb.write('| ${detail.name} ');
    }
    sb.write('|\n');
    for (var detail in details) {
      sb.write(detail.header.markdown);
    }
    sb.write(' |\n');

    // Body.
    forEach((lint) => sb.write('${lint.toMarkdown(details)}\n'));
    return sb.toString();
  }

  void forEach(void Function(LintScore element) f) {
    scores.forEach(f);
  }

  static Future<ScoreCard> calculate() async {
    var lintsWithFixes = _getLintsWithFixes();
    var lintsWithAssists = _getLintsWithAssists();
    var flutterRuleset = await flutterRules;
    var flutterRepoRuleset = await flutterRepoRules;

    var scorecard = ScoreCard();
    for (var lint in registeredLints!) {
      var ruleSets = <String>[];
      if (flutterRuleset.contains(lint.name)) {
        ruleSets.add('flutter');
      }
      if (flutterRepoRuleset.contains(lint.name)) {
        ruleSets.add('flutter_repo');
      }

      scorecard.add(LintScore(
          name: lint.name,
          hasFix: lintsWithFixes.contains(lint.name) ||
              lintsWithAssists.contains(lint.name),
          state: lint.state,
          ruleSets: ruleSets,
          since: sinceMap[lint.name]));
    }

    return scorecard;
  }

  static List<String> _getLintsWithAssists() {
    var assistFilePath = pathRelativeToPkgDir([
      'analysis_server',
      'lib',
      'src',
      'services',
      'correction',
      'assist.dart'
    ]);
    var contents = File(assistFilePath).readAsStringSync();

    var parser = CompilationUnitParser();
    var cu = parser.parse(contents: contents, name: 'assist.dart');
    var assistKindClass = cu.declarations.firstWhere(
        (m) => m is ClassDeclaration && m.name.lexeme == 'DartAssistKind');

    var collector = _AssistCollector();
    assistKindClass.accept(collector);
    return collector.lintNames;
  }

  static List<String> _getLintsWithFixes() {
    var lintNamesFilePath = pathRelativeToPkgDir([
      'analysis_server',
      'lib',
      'src',
      'services',
      'linter',
      'lint_names.dart'
    ]);
    var contents = File(lintNamesFilePath).readAsStringSync();

    var parser = CompilationUnitParser();
    var cu = parser.parse(contents: contents, name: 'lint_names.dart');
    var lintNamesClass = cu.declarations.firstWhere(
        (m) => m is ClassDeclaration && m.name.lexeme == 'LintNames');

    var collector = _FixCollector();
    lintNamesClass.accept(collector);
    return collector.lintNames;
  }
}

class _AssistCollector extends GeneralizingAstVisitor<void> {
  final List<String> lintNames = <String>[];

  @override
  void visitNamedExpression(NamedExpression node) {
    if (node.name.toString() == 'associatedErrorCodes:') {
      var list = node.expression as ListLiteral;
      for (var element in list.elements) {
        var name =
            element.toString().substring(1, element.toString().length - 1);
        lintNames.add(name);
        if (!registeredLintNames.contains(name)) {
          printToConsole('WARNING: unrecognized lint in assists: $name');
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
      var name = v.name.lexeme;
      lintNames.add(name);
      if (!registeredLintNames.contains(name)) {
        printToConsole('WARNING: unrecognized lint in fixes: $name');
      }
    }
  }
}
