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
import 'package:glob/glob.dart';
import 'package:linter/src/analysis.dart';
import 'package:linter/src/config.dart';
import 'package:linter/src/io.dart';
import 'package:linter/src/project.dart';
import 'package:linter/src/pub.dart';
import 'package:linter/src/rules.dart';

void _registerLinters(Iterable<Linter> linters) {
  if (linters != null) {
    LintGenerator.LINTERS.clear();
    LintGenerator.LINTERS.addAll(linters);
  }
}

typedef Printer(String msg);

/// Describes a String in valid camel case format.
class CamelCaseString {
  static final _camelCaseMatcher = new RegExp(r'[A-Z][a-z]*');
  static final _camelCaseTester = new RegExp(r'^([_]*)([A-Z]+[a-z0-9]*)+$');

  final String value;
  CamelCaseString(this.value) {
    if (!isCamelCase(value)) {
      throw new ArgumentError('$value is not CamelCase');
    }
  }

  String get humanized => _humanize(value);

  String toString() => value;

  static bool isCamelCase(String name) => _camelCaseTester.hasMatch(name);

  static String _humanize(String camelCase) =>
      _camelCaseMatcher.allMatches(camelCase).map((m) => m.group(0)).join(' ');
}

/// Dart source linter.
abstract class DartLinter {

  /// Creates a new linter.
  factory DartLinter([LinterOptions options]) => new SourceLinter(options);

  factory DartLinter.forRules(Iterable<LintRule> ruleSet) =>
      new DartLinter(new LinterOptions(ruleSet));

  /// The total number of sources that were analyzed.  Only valid after
  /// [lintFiles] has been called.
  int get numSourcesAnalyzed;

  LinterOptions get options;

  Iterable<AnalysisErrorInfo> lintFiles(List<File> files);

  Iterable<AnalysisErrorInfo> lintPubspecSource({String contents});
}

class FileGlobFilter extends LintFilter {
  Iterable<Glob> includes;
  Iterable<Glob> excludes;

  FileGlobFilter([Iterable<String> includeGlobs, Iterable<String> excludeGlobs])
      : includes = includeGlobs.map((glob) => new Glob(glob)),
        excludes = excludeGlobs.map((glob) => new Glob(glob));

  @override
  bool filter(AnalysisError lint) {
    // TODO specify order
    return excludes.any((glob) => glob.matches(lint.source.fullName)) &&
        !includes.any((glob) => glob.matches(lint.source.fullName));
  }
}

class Group {

  /// Defined rule groups.
  static const Group pub = const Group._('pub',
      link: const Hyperlink('See the <strong>Pubspec Format</strong>',
          'https://www.dartlang.org/tools/pub/pubspec.html'));
  static const Group style = const Group._('style',
      link: const Hyperlink('See the <strong>Style Guide</strong>',
          'https://www.dartlang.org/articles/style-guide/'));

  final String name;
  final bool custom;
  final String description;
  final Hyperlink link;

  factory Group(String name, {String description, Hyperlink link}) {
    switch (name.toLowerCase()) {
      case 'style':
        return style;
      case 'pub':
        return pub;
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
  Iterable<LintRule> enabledLints;
  final bool enableLints = true;
  LintFilter filter;
  LinterOptions([this.enabledLints]) {
    if (enabledLints == null) {
      enabledLints = ruleRegistry;
    }
  }
  void configure(LintConfig config) {
    enabledLints = ruleRegistry.enabled(config);
    filter = new FileGlobFilter(config.fileIncludes, config.fileExcludes);
  }
}

/// Filtered lints are ommitted from linter output.
abstract class LintFilter {
  bool filter(AnalysisError lint);
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
  final String name;

  /// Until pubspec analysis is pushed into the analyzer proper, we need to
  /// do some extra book-keeping to keep track of details that will help us
  /// constitute AnalysisErrorInfos.
  final List<AnalysisErrorInfo> _locationInfo = <AnalysisErrorInfo>[];

  LintRule({this.name, this.group, this.kind, this.description, this.details,
      this.maturity: Maturity.stable});

  @override
  int compareTo(LintRule other) {
    var k = kind.compareTo(other.kind);
    if (k != 0) {
      return k;
    }
    return name.compareTo(other.name);
  }

  /// Return a visitor to be passed to provide access to Dart project context
  /// and to perform project-level analyses.
  ProjectVisitor getProjectVisitor() => null;

  /// Return a visitor to be passed to pubspecs to perform lint
  /// analysis.
  /// Lint errors are reported via this [Linter]'s error [reporter].
  PubspecVisitor getPubspecVisitor() => null;

  @override
  AstVisitor getVisitor() => null;

  void reportLint(AstNode node) {
    reporter.reportErrorForNode(new _LintCode(name, description), node, []);
  }

  void reportPubLint(PSNode node) {
    Source source = createSource(node.span.sourceUrl);

    // Cache error and location info for creating AnalysisErrorInfos
    // Note that error columns are 1-based
    var error = new AnalysisError.con2(source, node.span.start.column + 1,
        node.span.length, new _LintCode(name, description));

    _locationInfo.add(new AnalysisErrorInfoImpl([error], new _LineInfo(node)));

    // Then do the reporting
    if (reporter != null) {
      reporter.reportError(error);
    }
  }
}

class Maturity implements Comparable<Maturity> {
  static const Maturity stable = const Maturity._('stable', ordinal: 0);
  static const Maturity experimental =
      const Maturity._('stable', ordinal: 1);

  final String name;
  final int ordinal;

  factory Maturity(String name, {int ordinal}) {
    switch (name.toLowerCase()) {
      case 'stable':
        return stable;
      case 'experimental':
        return experimental;
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

/// Linter implementation.
class SourceLinter implements DartLinter, AnalysisErrorListener {
  final errors = <AnalysisError>[];
  final LinterOptions options;
  final Reporter reporter;

  @override
  int numSourcesAnalyzed;

  SourceLinter(this.options, {this.reporter: const PrintingReporter()});

  @override
  Iterable<AnalysisErrorInfo> lintFiles(List<File> files) {
    List<AnalysisErrorInfo> errors = [];
    _registerLinters(options.enabledLints);
    var analysisDriver = new AnalysisDriver(options);
    errors.addAll(analysisDriver.analyze(files.where((f) => isDartFile(f))));
    numSourcesAnalyzed = analysisDriver.numSourcesAnalyzed;
    files.where((f) => isPubspecFile(f)).forEach((p) {
      numSourcesAnalyzed++;
      return errors.addAll(_lintPubspecFile(p));
    });
    return errors;
  }

  @override
  Iterable<AnalysisErrorInfo> lintPubspecSource(
      {String contents, String sourceUrl}) {
    var results = <AnalysisErrorInfo>[];

    var spec = new Pubspec.parse(contents, sourceUrl: sourceUrl);

    for (Linter lint in options.enabledLints) {
      if (lint is LintRule) {
        LintRule rule = lint;
        var visitor = rule.getPubspecVisitor();
        if (visitor != null) {
          // Analyzer sets reporters; if this file is not being analyzed,
          // we need to set one ourselves.  (Needless to say, when pubspec
          // processing gets pushed down, this hack can go away.)
          if (rule.reporter == null && sourceUrl != null) {
            var source = createSource(Uri.parse(sourceUrl));
            rule.reporter = new ErrorReporter(this, source);
          }
          try {
            spec.accept(visitor);
          } on Exception catch (e) {
            reporter.exception(new LinterException(e.toString()));
          }
          if (rule._locationInfo != null && !rule._locationInfo.isEmpty) {
            results.addAll(rule._locationInfo);
            rule._locationInfo.clear();
          }
        }
      }
    }

    return results;
  }

  @override
  onError(AnalysisError error) => errors.add(error);

  Iterable<AnalysisErrorInfo> _lintPubspecFile(File sourceFile) =>
      lintPubspecSource(
          contents: sourceFile.readAsStringSync(), sourceUrl: sourceFile.path);
}

class _LineInfo implements LineInfo {
  PSNode node;
  _LineInfo(this.node);

  @override
  LineInfo_Location getLocation(int offset) => new LineInfo_Location(
      node.span.start.line + 1, node.span.start.column + 1);
}

class _LintCode extends LintCode {
  static final registry = <String, LintCode>{};

  factory _LintCode(String name, String message) => registry.putIfAbsent(
      name + message, () => new _LintCode._(name, message));

  _LintCode._(String name, String message) : super(name, message);
}
