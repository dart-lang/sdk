// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/src/lint/config.dart'; // ignore: implementation_imports
import 'package:analyzer/src/lint/registry.dart'; // ignore: implementation_imports
import 'package:analyzer/src/lint/state.dart'; // ignore: implementation_imports
import 'package:github/github.dart';
import 'package:http/http.dart' as http;
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/rules.dart';
import 'package:linter/src/utils.dart';

import '../parse.dart';

void main() async {
  var scorecard = await ScoreCard.calculate();
  var details = [
    Detail.rule,
    Detail.fix,
    Detail.bulk,
    // Detail.status,
    // Detail.bugs,
  ];

  int sorter(LintScore s1, LintScore s2) {
    var base = _compareRuleSets(s1.ruleSets, s2.ruleSets) * 1000;
    return s1.name.compareTo(s2.name) + base;
  }

  printToConsole(scorecard.asMarkdown(details, sorter: sorter));

  // var footer = buildFooter(scorecard, details);
  // print(footer);
}

const bulb = '💡';
const checkMark = '✅';
const consider = '🤔';
const skip = '➖';

Iterable<LintRule>? _registeredLints;

List<String>? _unfixableLints;

Iterable<String> get registeredLintNames => registeredLints!.map((r) => r.name);

Iterable<LintRule>? get registeredLints {
  if (_registeredLints == null) {
    registerLintRules();
    _registeredLints = Registry.ruleRegistry.toList()
      ..sort((l1, l2) => l1.name.compareTo(l2.name));
  }
  return _registeredLints;
}

List<String?> get unfixableLints => _unfixableLints ?? _getUnfixableLints();

StringBuffer buildFooter(ScoreCard scorecard, List<Detail> details) {
  var scoreLintCount = 0;
  var scoreFixCount = 0;

  var recommendLintCount = 0;
  var recommendFixCount = 0;

  var needsBulkFix = <String>[];
  var fixable = <String>[];

  for (var score in scorecard.scores) {
    for (var ruleSet in score.ruleSets) {
      var hasFixOrAssist = score.hasFix || score.hasAssist;
      if (ruleSet == 'core') {
        ++scoreLintCount;
        if (hasFixOrAssist) {
          ++scoreFixCount;
        }
      }
      if (ruleSet == 'recommend') {
        ++recommendLintCount;
        if (hasFixOrAssist) {
          ++recommendFixCount;
        }
      }
      var lint = score.name;
      if (hasFixOrAssist && !score.hasBulkFix) {
        needsBulkFix.add(lint);
      }
      if (!hasFixOrAssist && !unfixableLints.contains(lint)) {
        fixable.add(lint);
      }
    }
  }

  var footer = StringBuffer('\n${scorecard.lintCount} lints: ');
  footer.write('$scoreLintCount score [$scoreFixCount fixes], ');
  footer.write('rec $recommendLintCount [$recommendFixCount fixes]');

  if (needsBulkFix.isNotEmpty) {
    footer.writeln('\n\nTODO: add bulk fixes for');
    for (var lint in needsBulkFix) {
      footer.writeln('  - [ ] `$lint`');
    }
  }

  if (fixable.isNotEmpty) {
    footer.writeln('\n\nTODO: add fixes for');
    for (var lint in fixable) {
      footer.writeln('  - [ ] `$lint`');
    }
  }

  return footer;
}

int _compareRuleSets(List<String> s1, List<String> s2) {
  if (s1.contains('core')) {
    return s2.contains('core') ? 0 : -1;
  }
  if (s2.contains('core')) {
    return 1;
  }
  return 0;
}

List<String?> _getUnfixableLints() =>
    // todo(pq): update with data extracted from error_fix_status.yaml
    [];

//bool _isBug(Issue issue) => issue.labels.map((l) => l.name).contains('bug');

class Detail {
  static const Detail rule = Detail('name', header: Header.left);
  static const Detail fix = Detail('fix');
  static const Detail bulk = Detail('bulk');
  static const Detail status = Detail('status');
  static const Detail bugs = Detail('bug refs', header: Header.left);
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
  bool hasAssist;
  bool hasBulkFix;
  bool hasFix;
  State state;

  List<String> ruleSets;
  List<String> bugReferences;

  LintScore({
    required this.name,
    required this.hasAssist,
    required this.hasFix,
    required this.hasBulkFix,
    required this.state,
    required this.ruleSets,
    required this.bugReferences,
  });

  bool get inCore => ruleSets.contains('core');
  bool get inFlutter => ruleSets.contains('flutter');
  bool get inRecommended => ruleSets.contains('recommended');

  String get _ruleSets => ruleSets.isNotEmpty ? ' $ruleSets' : '';

  String toMarkdown(List<Detail> details) {
    var sb = StringBuffer('| ');
    for (var detail in details) {
      switch (detail) {
        case Detail.rule:
          sb.write(
              ' [`$name`](https://dart-lang.github.io/linter/lints/$name.html) |');
        case Detail.fix:
          var status = unfixableLints.contains(name)
              ? skip
              : (hasFix ? checkMark : consider);
          sb.write(' $status |');
        case Detail.bulk:
          var status = unfixableLints.contains(name)
              ? skip
              : (hasBulkFix ? checkMark : consider);
          sb.write(' $status |');
        case Detail.status:
          sb.write('${!state.isStable ? ' **${state.label}** ' : ""} |');
        case Detail.bugs:
          sb.write(' ${bugReferences.join(", ")} |');
      }
    }
    return sb.toString();
  }

  @override
  String toString() => '$name$_ruleSets${hasFix ? " $checkMark" : ""}';
}

class ScoreCard {
  List<LintScore> scores = <LintScore>[];

  int get lintCount => scores.length;

  void add(LintScore score) {
    scores.add(score);
  }

  String asMarkdown(List<Detail> details,
      {int Function(LintScore s1, LintScore s2)? sorter}) {
    // Header.
    var sb = StringBuffer();
    void writeHeader(StringBuffer sb) {
      for (var detail in details) {
        sb.write('| ${detail.name} ');
      }
      sb.write('|\n');
      for (var detail in details) {
        sb.write(detail.header.markdown);
      }
      sb.write(' |\n');
    }

    if (sorter != null) {
      scores.sort(sorter);
    }

    void writeLints(String label, bool Function(LintScore lint) predicate) {
      sb.writeln('\n## $label\n');
      writeHeader(sb);
      forEach((lint) {
        if (predicate(lint)) {
          sb.write('${lint.toMarkdown(details)}\n');
        }
      });
    }

    // Body.
    writeLints('Core Lints', (lint) => lint.inCore);
    writeLints('Recommended Lints', (lint) => lint.inRecommended);
    writeLints('Flutter Lints', (lint) => lint.inFlutter);

    return sb.toString();
  }

  void forEach(void Function(LintScore element) f) {
    scores.forEach(f);
  }

  void removeWhere(bool Function(LintScore element) test) {
    scores.removeWhere(test);
  }

  static Future<ScoreCard> calculate() async {
    var lintsWithAssists = _getLintsWithAssists();
    var lintsWithFixes = await _getLintsWithFixes();
    var lintsWithBulkFixes = await _getLintsWithBulkFixes();
    // var issues = await _getIssues();
    // var bugs = issues.where(_isBug).toList();
    var bugs = <Issue>[];

    var coreRuleset = await _readCoreLints();
    var recommendedRuleset = await _readRecommendedLints();
    var flutterRuleset = await _readFlutterLints();

    var scorecard = ScoreCard();
    for (var lint in registeredLints!) {
      var ruleSets = <String>[];
      if (coreRuleset.contains(lint.name)) {
        ruleSets.add('core');
      }
      if (recommendedRuleset.contains(lint.name)) {
        ruleSets.add('recommended');
      }
      if (flutterRuleset.contains(lint.name)) {
        ruleSets.add('flutter');
      }

      if (ruleSets.isEmpty) {
        continue;
      }

      var bugReferences = <String>[];
      for (var bug in bugs) {
        var title = bug.title;
        if (title.contains(lint.name)) {
          bugReferences.add('#${bug.number}');
        }
      }

      var lintName = lint.name;
      scorecard.add(LintScore(
        name: lintName,
        hasAssist: lintsWithAssists.contains(lintName),
        hasFix: lintsWithFixes.contains(lintName),
        hasBulkFix: lintsWithBulkFixes.contains(lintName),
        state: lint.state,
        ruleSets: ruleSets,
        bugReferences: bugReferences,
      ));
    }

    return scorecard;
  }

  // static Future<List<Issue>> _getIssues() async {
  //   var github = GitHub();
  //   var slug = RepositorySlug('dart-lang', 'linter');
  //   try {
  //     return github.issues.listByRepo(slug).toList();
  //   } on Exception catch (e) {
  //     print('exception caught fetching github issues');
  //     print(e);
  //     print('(defaulting to an empty list)');
  //     return Future.value(<Issue>[]);
  //   }
  // }

  static Future<List<String>> _fetchLints(String url) async {
    var client = http.Client();
    var req = await client.get(Uri.parse(url));
    return _readLints(req.body);
  }

  static List<String?> _getLintsWithAssists() {
    var assists = File('tool/canonical/assists.json');
    var contents = assists.readAsStringSync();
    var json = jsonDecode(contents) as Iterable;
    var lints = <String?>[];
    for (var entry in json) {
      lints.add(entry['lint'] as String?);
    }
    return lints;
  }

  static Future<List<String>> _getLintsWithBulkFixes() async {
    var client = http.Client();
    var req = await client.get(Uri.parse(
        'https://raw.githubusercontent.com/dart-lang/sdk/main/pkg/analysis_server/lib/src/services/correction/fix_internal.dart'));

    var parser = CompilationUnitParser();
    var cu = parser.parse(contents: req.body, name: 'fix_internal.dart');
    var fixProcessor = cu.declarations.firstWhere(
        (m) => m is ClassDeclaration && m.name.lexeme == 'FixProcessor');

    var collector = _BulkFixCollector();
    fixProcessor.accept(collector);
    return collector.lintNames;
  }

  static Future<List<String>> _getLintsWithFixes() async {
    var client = http.Client();
    var req = await client.get(Uri.parse(
        'https://raw.githubusercontent.com/dart-lang/sdk/main/pkg/analysis_server/lib/src/services/linter/lint_names.dart'));

    var parser = CompilationUnitParser();
    var cu = parser.parse(contents: req.body, name: 'lint_names.dart');
    var lintNamesClass = cu.declarations.firstWhere(
        (m) => m is ClassDeclaration && m.name.lexeme == 'LintNames');

    var collector = _FixCollector();
    lintNamesClass.accept(collector);
    return collector.lintNames;
  }

  static Future<List<String>> _readCoreLints() async => _fetchLints(
      'https://raw.githubusercontent.com/dart-lang/lints/main/lib/core.yaml');

  static Future<List<String>> _readFlutterLints() async => _fetchLints(
      'https://raw.githubusercontent.com/flutter/packages/main/packages/flutter_lints/lib/flutter.yaml');

  static List<String> _readLints(String contents) {
    var lintConfigs = processAnalysisOptionsFile(contents);
    if (lintConfigs == null) {
      return [];
    }
    return lintConfigs.ruleConfigs.map((c) => c.name ?? '<unknown>').toList();
  }

  static Future<List<String>> _readRecommendedLints() async => _fetchLints(
      'https://raw.githubusercontent.com/dart-lang/lints/main/lib/recommended.yaml');
}

class _BulkFixCollector extends _LintNameCollector {
  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    for (var field in node.fields.variables) {
      if (field.name.lexeme == 'lintProducerMap') {
        var initializer = field.initializer;
        if (initializer is SetOrMapLiteral) {
          for (var element in initializer.elements) {
            var entry = element as MapLiteralEntry;
            var key = entry.key;
            var value = entry.value;
            if (key is PrefixedIdentifier &&
                key.prefix.name == 'LintNames' &&
                value is ListLiteral) {
              for (var element in value.elements) {
                if (element is MethodInvocation) {
                  var args = element.argumentList.arguments;
                  for (var arg in args) {
                    if (arg is NamedExpression) {
                      if (arg.name.label.name == 'canBeBulkApplied') {
                        var value = arg.expression;
                        if (value is BooleanLiteral &&
                            value.literal.type == Keyword.TRUE) {
                          addLint(key.identifier.name);
                        }
                      }
                    }
                  }
                }
              }
              addLint(key.identifier.name);
            }
          }
        }
      }
    }
  }
}

class _FixCollector extends _LintNameCollector {
  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    for (var v in node.fields.variables) {
      addLint(v.name.lexeme);
    }
  }
}

class _LintNameCollector extends GeneralizingAstVisitor<void> {
  final List<String> lintNames = <String>[];

  void addLint(String name) {
    lintNames.add(name);
    if (!registeredLintNames.contains(name)) {
      printToConsole('WARNING: unrecognized lint in fixes: $name');
    }
  }
}
