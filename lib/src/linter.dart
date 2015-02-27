// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library linter.src.linter;

import 'dart:io';

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/services/lint.dart';
import 'package:linter/src/analysis.dart';
import 'package:linter/src/io.dart';
import 'package:linter/src/pub.dart';
import 'package:linter/src/rules.dart';

final _camelCaseMatcher = new RegExp(r'[A-Z][a-z]*');

final _camelCaseTester = new RegExp(r'^([_]*)([A-Z]+[a-z0-9]*)+$');

String _humanize(String camelCase) =>
    _camelCaseMatcher.allMatches(camelCase).map((m) => m.group(0)).join(' ');

void _registerLinters(Iterable<Linter> linters) {
  if (linters != null) {
    LintGenerator.LINTERS.clear();
    linters.forEach((l) => LintGenerator.LINTERS.add(l));
  }
}

typedef Printer(String msg);

/// Describes a set of enabled rules.
typedef Iterable<LintRule> RuleSet();

/// Describes a String in valid camel case format.
class CamelCaseString {
  final String value;
  CamelCaseString(this.value) {
    if (!isCamelCase(value)) {
      throw new ArgumentError('$value is not CamelCase');
    }
  }

  String get humanized => _humanize(value);

  String toString() => value;

  static bool isCamelCase(String name) => _camelCaseTester.hasMatch(name);
}

/// Dart source linter.
abstract class DartLinter {

  /// Creates a new linter.
  factory DartLinter([LinterOptions options]) => new SourceLinter(options);

  factory DartLinter.forRules(RuleSet ruleSet) =>
      new DartLinter(new LinterOptions(ruleSet));

  LinterOptions get options;

  Iterable<AnalysisErrorInfo> lintFiles(List<File> files);

  Iterable<AnalysisErrorInfo> lintPubspecSource({String contents});
}

class Group {

  /// Defined rule groups.
  static const Group PUB = const Group._('Pub',
      link: const Hyperlink('See the <strong>Pubspec Format</strong>',
          'https://www.dartlang.org/tools/pub/pubspec.html'));
  static const Group STYLE_GUIDE = const Group._('Style Guide',
      link: const Hyperlink('See the <strong>Style Guide</strong>',
          'https://www.dartlang.org/articles/style-guide/'));

  final String name;
  final bool custom;
  final String description;
  final Hyperlink link;

  factory Group(String name, {String description, Hyperlink link}) {
    switch (name) {
      case 'Styleguide':
      case 'Style Guide':
        return STYLE_GUIDE;
      case 'Pub':
        return PUB;
      default:
        return new Group._(name,
            custom: true, description: description, link: link);
    }
  }

  const Group._(this.name, {this.custom: false, this.description, this.link});
}

class Hyperlink {
  final String label;
  final String href;
  final bool bold;
  const Hyperlink(this.label, this.href, {this.bold: false});
  String get html => '<a href="$href">${_emph(label)}</a>';
  String _emph(msg) => bold ? '<strong>$msg</strong>' : msg;
}

class Kind implements Comparable<Kind> {

  /// Defined rule kinds.
  static const Kind DO = const Kind._('Do', ordinal: 0, description: '''
**DO** guidelines describe practices that should always be followed. 
There will almost never be a valid reason to stray from them.
''');
  static const Kind DONT = const Kind._("Don't", ordinal: 1, description: '''
**DON'T** guidelines are the converse: things that are almost never a good idea. 
You'll note there are few of these here. Guidelines like these in other 
languages help to avoid the pitfalls that appear over time. Dart is new enough 
that we can just fix those pitfalls directly instead of putting up ropes around 
them.
''');
  static const Kind PREFER = const Kind._('Prefer', ordinal: 2, description: '''
**PREFER** guidelines are practices that you should follow. However, there 
may be circumstances where it makes sense to do otherwise. Just make sure you 
understand the full implications of ignoring the guideline when you do.
''');
  static const Kind AVOID = const Kind._('Avoid', ordinal: 3, description: '''
**AVOID** guidelines are the dual to "prefer": stuff you shouldn't do but where 
there may be good reasons to on rare occasions.
''');
  static const Kind CONSIDER = const Kind._('Consider',
      ordinal: 4, description: '''
**CONSIDER** guidelines are practices that you might or might not want to 
follow, depending on circumstances, precedents, and your own preference.
''');

  /// List of supported kinds in priority order.
  static Iterable<Kind> get supported => [DO, DONT, PREFER, AVOID, CONSIDER];
  final String name;
  final bool custom;
  /// Description (in markdown).
  final String description;

  final int ordinal;

  factory Kind(String name, {String description, int ordinal}) {
    var label = name.toUpperCase();
    switch (label) {
      case 'DO':
        return DO;
      case 'DONT':
      case "DON'T":
        return DONT;
      case 'PREFER':
        return PREFER;
      case 'AVOID':
        return AVOID;
      case 'CONSIDER':
        return CONSIDER;
      default:
        return new Kind._(label,
            custom: true, description: description, ordinal: ordinal);
    }
  }

  const Kind._(this.name, {this.custom: false, this.description, this.ordinal});

  @override
  int compareTo(Kind other) => this.ordinal - other.ordinal;
}

/// Thrown when an error occurs in linting.
class LinterException implements Exception {

  /// A message describing the error.
  final String message;

  /// Creates a new LinterException with an optional error [message].
  const LinterException([this.message]);

  String toString() =>
      message == null ? "LinterException" : "LinterException: $message";
}

/// Linter options.
class LinterOptions extends DriverOptions {
  final RuleSet _enabledLints;
  final bool enableLints = true;
  LinterOptions(this._enabledLints);
  Iterable<Linter> get enabledLints => _enabledLints();
}

/// Describes a lint rule.
abstract class LintRule extends Linter implements Comparable<LintRule> {

  /// Description (in markdown format) suitable for display in a detailed lint
  /// description.
  final String details;
  /// Short description suitable for display in console output.
  final String description;
  /// Lint group (for example, 'Style Guide')
  final Group group;
  /// Lint kind (DO|DON'T|PREFER|AVOID|CONSIDER).
  final Kind kind;
  /// Lint maturity (STABLE|EXPERIMENTAL).
  final Maturity maturity;
  /// Lint name.
  final CamelCaseString name;

  /// Until pubspec analysis is pushed into the analyzer proper, we need to
  /// do some extra book-keeping to keep track of details that will help us
  /// constitute AnalysisErrorInfos.
  final List<AnalysisErrorInfo> _locationInfo = <AnalysisErrorInfo>[];

  LintRule({String name, this.group, this.kind, this.description, this.details,
      this.maturity: Maturity.STABLE})
      : name = new CamelCaseString(name);

  @override
  int compareTo(LintRule other) {
    var k = kind.compareTo(other.kind);
    if (k != 0) {
      return k;
    }
    return name.value.compareTo(other.name.value);
  }

  /// Return a visitor to be passed to pubspecs to perform lint
  /// analysis.
  /// Lint errors are reported via this [Linter]'s error [reporter].
  PubSpecVisitor getPubspecVisitor() => null;

  @override
  AstVisitor getVisitor() => null;

  void reportLint(AstNode node) {
    reporter.reportErrorForNode(
        new LintCode(name.value, description), node, []);
  }

  void reportPubLint(PSNode node) {
    // Cache error and location info for creating AnalysisErrorInfos
    var error = new AnalysisError.con2(reporter.source, node.span.start.offset,
        node.span.length, new LintCode(name.value, description));

    _locationInfo.add(new AnalysisErrorInfoImpl([error], new _LineInfo(node)));

    // Then do the reporting
    reporter.reportError(error);
  }
}

class Maturity implements Comparable<Maturity> {
  static const Maturity STABLE = const Maturity._('STABLE', ordinal: 0);
  static const Maturity EXPERIMENTAL =
      const Maturity._('EXPERIMENTAL', ordinal: 1);

  final String name;
  final int ordinal;

  factory Maturity(String name, {int ordinal}) {
    var normalized = name.toUpperCase();
    switch (normalized) {
      case 'STABLE':
        return STABLE;
      case 'EXPERIMENTAL':
        return EXPERIMENTAL;
      default:
        return new Maturity._(name, ordinal: ordinal);
    }
  }

  const Maturity._(this.name, {this.ordinal});

  @override
  int compareTo(Maturity other) => this.ordinal - other.ordinal;
}

class PrintingReporter implements Reporter, Logger {
  final Printer _print;

  const PrintingReporter([this._print = print]);

  @override
  void exception(LinterException exception) {
    _print('EXCEPTION: $exception');
  }

  @override
  void logError(String message, [CaughtException exception]) {
    _print('ERROR: $message');
  }

  @override
  void logError2(String message, Object exception) {
    _print('ERROR: $message');
  }

  @override
  void logInformation(String message, [CaughtException exception]) {
    _print('INFO: $message');
  }

  @override
  void logInformation2(String message, Object exception) {
    _print('INFO: $message');
  }

  @override
  void warn(String message) {
    _print('WARN: $message');
  }
}
abstract class Reporter {
  void exception(LinterException exception);
  void warn(String message);
}

/// Linter implementation
class SourceLinter implements DartLinter, AnalysisErrorListener {
  final errors = <AnalysisError>[];
  final LinterOptions options;
  final Reporter reporter;
  SourceLinter(LinterOptions options, {this.reporter: const PrintingReporter()})
      : this.options = options != null ? options : _defaultOptions();

  @override
  Iterable<AnalysisErrorInfo> lintFiles(List<File> files) {
    List<AnalysisErrorInfo> errors = [];
    _registerLinters(options.enabledLints);
    errors.addAll(
        new AnalysisDriver(options).analyze(files.where((f) => isDartFile(f))));
    files
        .where((f) => isPubspecFile(f))
        .forEach((p) => errors.addAll(_lintPubspecFile(p)));
    return errors;
  }

  @override
  Iterable<AnalysisErrorInfo> lintPubspecSource({String contents}) {
    var results = <AnalysisErrorInfo>[];

    //TODO: error handling
    var spec = new PubSpec.parse(contents);

    for (Linter lint in options.enabledLints) {
      if (lint is LintRule) {
        LintRule rule = lint;
        var visitor = rule.getPubspecVisitor();
        if (visitor != null) {
          try {
            spec.accept(visitor);
          } on Exception catch (e) {
            reporter.exception(new LinterException(e.toString()));
          }
          results.addAll(rule._locationInfo);
        }
      }
    }

    return results;
  }

  @override
  onError(AnalysisError error) => errors.add(error);

  Iterable<AnalysisErrorInfo> _lintPubspecFile(File sourceFile) =>
      lintPubspecSource(contents: sourceFile.readAsStringSync());

  static LinterOptions _defaultOptions() =>
      new LinterOptions(() => ruleMap.values);
}

class _LineInfo implements LineInfo {
  PSNode node;
  _LineInfo(this.node);

  @override
  LineInfo_Location getLocation(int offset) =>
      new LineInfo_Location(node.span.start.line + 1, node.span.start.column);
}
