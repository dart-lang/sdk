// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/src/lint/config.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:args/args.dart';
import 'package:http/http.dart' as http;
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/rules.dart';
import 'package:markdown/markdown.dart';

import 'machine.dart';
import 'since.dart';

/// Generates lint rule docs for publishing to https://dart-lang.github.io/
void main([List<String> args]) async {
  var parser = ArgParser()
    ..addOption('out', abbr: 'o', help: 'Specifies output directory.');

  var options;
  try {
    options = parser.parse(args);
  } on FormatException catch (err) {
    printUsage(parser, err.message);
    return;
  }

  var outDir = options['out'] as String;
  await generateDocs(outDir);
}

const ruleFootMatter = '''
In addition, rules can be further distinguished by *maturity*.  Unqualified
rules are considered stable, while others may be marked **experimental**
to indicate that they are under review.  Lints that are marked as **deprecated**
should not be used and are subject to removal in future Linter releases.

Rules can be selectively enabled in the analyzer using
[analysis options](https://pub.dev/packages/analyzer)
or through an
[analysis options file](https://dart.dev/guides/language/analysis-options#the-analysis-options-file). 

* **An auto-generated list enabling all options is provided [here](options/options.html).** 

As some lints may contradict each other, only a subset of these will be
enabled in practice, but this list should provide a convenient jumping-off point.

Many lints are included in various predefined rulesets:

* [pedantic](https://github.com/dart-lang/pedantic) for rules enforced internally at Google
* [effective_dart](https://github.com/tenhobi/effective_dart) for rules corresponding to the [Effective Dart](https://dart.dev/guides/language/effective-dart) style guide
* [flutter](https://github.com/flutter/flutter/blob/master/packages/flutter/lib/analysis_options_user.yaml) for rules used in <code>flutter analyze</code>

Rules included in these rulesets are badged in the documentation below.

These rules are under active development.  Feedback is
[welcome](https://github.com/dart-lang/linter/issues)!
''';

const ruleLeadMatter = 'Rules are organized into familiar rule groups.';

final effectiveDartRules = <String>[];
final flutterRules = <String>[];
final pedanticRules = <String>[];

/// Sorted list of contributed lint rules.
final List<LintRule> rules =
    List<LintRule>.from(Registry.ruleRegistry, growable: false)..sort();

Map<String, SinceInfo> sinceInfo;

Future<String> get effectiveDartLatestVersion async {
  var url =
      'https://raw.githubusercontent.com/tenhobi/effective_dart/master/lib/analysis_options.yaml';
  var client = http.Client();
  print('loading $url...');
  var req = await client.get(url);
  var parts = req.body.split('package:effective_dart/analysis_options.');
  return parts[1].split('.yaml')[0];
}

String get enumerateErrorRules => rules
    .where((r) => r.group == Group.errors)
    .map((r) => '${toDescription(r)}')
    .join('\n\n');

String get enumerateGroups => Group.builtin
    .map((Group g) =>
        '<li><strong>${g.name} -</strong> ${markdownToHtml(g.description)}</li>')
    .join('\n');

String get enumeratePubRules => rules
    .where((r) => r.group == Group.pub)
    .map((r) => '${toDescription(r)}')
    .join('\n\n');

String get enumerateStyleRules => rules
    .where((r) => r.group == Group.style)
    .map((r) => '${toDescription(r)}')
    .join('\n\n');

Future<String> get pedanticLatestVersion async {
  var url =
      'https://raw.githubusercontent.com/dart-lang/pedantic/master/lib/analysis_options.yaml';
  var client = http.Client();
  print('loading $url...');
  var req = await client.get(url);
  var parts = req.body.split('package:pedantic/analysis_options.');
  return parts[1].split('.yaml')[0];
}

String describeMaturity(LintRule r) =>
    r.maturity == Maturity.stable ? '' : ' (${r.maturity.name})';

Future<void> fetchBadgeInfo() async {
  var latestPedantic = await pedanticLatestVersion;
  var latestEffectiveDart = await effectiveDartLatestVersion;

  var pedantic = await fetchConfig(
      'https://raw.githubusercontent.com/dart-lang/pedantic/master/lib/analysis_options.$latestPedantic.yaml');
  for (var ruleConfig in pedantic.ruleConfigs) {
    pedanticRules.add(ruleConfig.name);
  }

  var effectiveDart = await fetchConfig(
      'https://raw.githubusercontent.com/tenhobi/effective_dart/master/lib/analysis_options.$latestEffectiveDart.yaml');
  for (var ruleConfig in effectiveDart.ruleConfigs) {
    effectiveDartRules.add(ruleConfig.name);
  }

  var flutter = await fetchConfig(
      'https://raw.githubusercontent.com/flutter/flutter/master/packages/flutter/lib/analysis_options_user.yaml');
  for (var ruleConfig in flutter.ruleConfigs) {
    flutterRules.add(ruleConfig.name);
  }
}

Future<LintConfig> fetchConfig(String url) async {
  var client = http.Client();
  print('loading $url...');
  var req = await client.get(url);
  return processAnalysisOptionsFile(req.body);
}

Future<void> fetchSinceInfo() async {
  sinceInfo = await sinceMap;
}

Future<void> generateDocs(String dir) async {
  var outDir = dir;
  if (outDir != null) {
    final d = Directory(outDir);
    if (!d.existsSync()) {
      print("Directory '${d.path}' does not exist");
      return;
    }
    if (!File('$outDir/options').existsSync()) {
      final lintsChildDir = Directory('$outDir/lints');
      if (lintsChildDir.existsSync()) {
        outDir = lintsChildDir.path;
      }
    }
  }

  registerLintRules();

  // Generate lint count badge.
  await CountBadger(Registry.ruleRegistry).generate(outDir);

  // Fetch info for lint group/style badge generation.
  await fetchBadgeInfo();

  // Fetch since info.
  await fetchSinceInfo();

  // Generate rule files.
  rules.forEach((l) {
    RuleHtmlGenerator(l).generate(outDir);
    RuleMarkdownGenerator(l).generate(filePath: outDir);
  });

  // Generate index.
  HtmlIndexer(Registry.ruleRegistry).generate(outDir);
  MarkdownIndexer(Registry.ruleRegistry).generate(filePath: outDir);

  // Generate options samples.
  OptionsSample(rules).generate(outDir);

  // Generate a machine-readable summary of rules.
  MachineSummaryGenerator(Registry.ruleRegistry).generate(outDir);
}

String getBadges(String rule) {
  var sb = StringBuffer();
  if (flutterRules.contains(rule)) {
    sb.write(
        '<a class="style-type" href="https://github.com/flutter/flutter/blob/master/packages/flutter/lib/analysis_options_user.yaml">'
        '<!--suppress HtmlUnknownTarget --><img alt="flutter" src="style-flutter.svg"></a>');
  }
  if (pedanticRules.contains(rule)) {
    sb.write(
        '<a class="style-type" href="https://github.com/dart-lang/pedantic/#enabled-lints">'
        '<!--suppress HtmlUnknownTarget --><img alt="pedantic" src="style-pedantic.svg"></a>');
  }
  if (effectiveDartRules.contains(rule)) {
    sb.write(
        '<a class="style-type" href="https://github.com/tenhobi/effective_dart">'
        '<!--suppress HtmlUnknownTarget --><img alt="effective dart" src="style-effective_dart.svg"></a>');
  }
  return sb.toString();
}

void printUsage(ArgParser parser, [String error]) {
  var message = 'Generates lint docs.';
  if (error != null) {
    message = error;
  }

  stdout.write('''$message
Usage: doc
${parser.usage}
''');
}

String qualify(LintRule r) => r.name.toString() + describeMaturity(r);

String toDescription(LintRule r) =>
    '<!--suppress HtmlUnknownTarget --><strong><a href = "${r.name}.html">${qualify(r)}</a></strong><br/> ${getBadges(r.name)} ${markdownToHtml(r.description)}';

class CountBadger {
  Iterable<LintRule> rules;

  CountBadger(this.rules);

  Future<void> generate(String dirPath) async {
    var lintCount = rules.length;

    var client = http.Client();
    var req = await client.get(
        Uri.parse('https://img.shields.io/badge/lints-$lintCount-blue.svg'));
    var bytes = req.bodyBytes;
    await File('$dirPath/count-badge.svg').writeAsBytes(bytes);
  }
}

class HtmlIndexer {
  final Iterable<LintRule> rules;

  HtmlIndexer(this.rules);

  void generate(String filePath) {
    var generated = _generate();
    if (filePath != null) {
      var outPath = '$filePath/index.html';
      print('Writing to $outPath');
      File(outPath).writeAsStringSync(generated);
    } else {
      print(generated);
    }
  }

  String _generate() => '''
<!DOCTYPE html>
<html lang="en">
   <head>
      <meta charset="utf-8">
      <link rel="shortcut icon" href="../dart-192.png">
      <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
      <meta name="mobile-web-app-capable" content="yes">
      <meta name="apple-mobile-web-app-capable" content="yes">
      <link rel="stylesheet" href="../styles.css">
      <title>Linter for Dart</title>
   </head>
   <body>
      <div class="wrapper">
         <header>
            <a href="../index.html">
               <h1>Linter for Dart</h1>
            </a>
            <p>Lint Rules</p>
            <ul>
              <li><a href="https://dart.dev/guides/language/analysis-options#enabling-linter-rules">Using the <strong>Linter</strong></a></li>
            </ul>
            <p><a class="overflow-link" href="https://dart.dev/guides/language/analysis-options#enabling-linter-rules">Using the <strong>Linter</strong></a></p>
         </header>
         <section>

            <h1>Supported Lint Rules</h1>
            <p>
               This list is auto-generated from our sources.
            </p>
            ${markdownToHtml(ruleLeadMatter)}
            <ul>
               $enumerateGroups
            </ul>
            ${markdownToHtml(ruleFootMatter)}

            <h2>Error Rules</h2>

               $enumerateErrorRules

            <h2>Style Rules</h2>

               $enumerateStyleRules

            <h2>Pub Rules</h2>

               $enumeratePubRules

         </section>
      </div>
      <footer>
         <p>Maintained by the <a href="https://dart.dev/">Dart Team</a></p>
         <p>Visit us on <a href="https://github.com/dart-lang/linter">Github</a></p>
      </footer>
   </body>
</html>
''';
}

class MachineSummaryGenerator {
  final Iterable<LintRule> rules;

  MachineSummaryGenerator(this.rules);

  void generate(String filePath) {
    var generated = getMachineListing(rules);
    if (filePath != null) {
      var outPath = '$filePath/machine/rules.json';
      print('Writing to $outPath');
      File(outPath).writeAsStringSync(generated);
    } else {
      print(generated);
    }
  }
}

class MarkdownIndexer {
  final Iterable<LintRule> rules;

  MarkdownIndexer(this.rules);

  void generate({String filePath}) {
    final buffer = StringBuffer();

    buffer.writeln('# Linter for Dart');
    buffer.writeln();
    buffer.writeln('## Lint Rules');
    buffer.writeln();
    buffer.writeln(
        '[Using the Linter](https://dart.dev/guides/language/analysis-options#enabling-linter-rules)');
    buffer.writeln();
    buffer.writeln('## Supported Lint Rules');
    buffer.writeln();
    buffer.writeln('This list is auto-generated from our sources.');
    buffer.writeln();
    buffer.writeln(ruleLeadMatter);
    buffer.writeln();

    for (var group in Group.builtin) {
      buffer.writeln('- **${group.name}** - ${group.description}');
      buffer.writeln();
    }

    buffer.writeln(ruleFootMatter);
    buffer.writeln();

    var emit = (LintRule rule) {
      buffer
          .writeln('**[${rule.name}](${rule.name}.md)** - ${rule.description}');
      if (flutterRules.contains(rule.name)) {
        buffer.writeln('[![flutter](style-flutter.svg)]'
            '(https://github.com/flutter/flutter/blob/master/packages/'
            'flutter/lib/analysis_options_user.yaml)');
      }
      if (pedanticRules.contains(rule.name)) {
        buffer.writeln('[![pedantic](style-pedantic.svg)]'
            '(https://github.com/dart-lang/pedantic/#enabled-lints)');
      }
      if (effectiveDartRules.contains(rule.name)) {
        buffer.writeln('[![effective dart](style-effective_dart.svg)]'
            '(https://github.com/tenhobi/effective_dart)');
      }
      buffer.writeln();
    };

    buffer.writeln('## Error Rules');
    buffer.writeln();
    // ignore: prefer_foreach
    for (var rule in rules.where((rule) => rule.group == Group.errors)) {
      emit(rule);
    }

    buffer.writeln('## Style Rules');
    buffer.writeln();
    // ignore: prefer_foreach
    for (var rule in rules.where((rule) => rule.group == Group.style)) {
      emit(rule);
    }

    buffer.writeln('## Pub Rules');
    buffer.writeln();
    // ignore: prefer_foreach
    for (var rule in rules.where((rule) => rule.group == Group.pub)) {
      emit(rule);
    }

    if (filePath == null) {
      print(buffer.toString());
    } else {
      File('$filePath/index.md').writeAsStringSync(buffer.toString());
    }
  }
}

class OptionsSample {
  Iterable<LintRule> rules;

  OptionsSample(this.rules);

  void generate(String filePath) {
    var generated = _generate();
    if (filePath != null) {
      var outPath = '$filePath/options/options.html';
      print('Writing to $outPath');
      File(outPath).writeAsStringSync(generated);
    } else {
      print(generated);
    }
  }

  String generateOptions() {
    final sb = StringBuffer('''
```
linter:
  rules:
''');

    var sortedRules = rules
        .where((r) => r.maturity != Maturity.deprecated)
        .map((r) => r.name)
        .toList()
          ..sort();
    for (var rule in sortedRules) {
      sb.write('    - $rule\n');
    }
    sb.write('```');

    return sb.toString();
  }

  String _generate() => '''
<!DOCTYPE html>
<html lang="en">
   <head>
      <meta charset="utf-8">
      <link rel="shortcut icon" href="../../dart-192.png">
      <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
      <meta name="mobile-web-app-capable" content="yes">
      <meta name="apple-mobile-web-app-capable" content="yes">
      <link rel="stylesheet" href="../../styles.css">
      <title>Analysis Options</title>
   </head>
  <body>
      <div class="wrapper">
         <header>
            <a href="../../index.html">
               <h1>Linter for Dart</h1>
            </a>
            <p>Analysis Options</p>
            <ul>
              <li><a href="../index.html">View all <strong>Lint Rules</strong></a></li>
              <li><a href="https://dart.dev/guides/language/analysis-options#enabling-linter-rules">Using the <strong>Linter</strong></a></li>
            </ul>
            <p><a class="overflow-link" href="../index.html">View all <strong>Lint Rules</strong></a></p>
            <p><a class="overflow-link" href="https://dart.dev/guides/language/analysis-options#enabling-linter-rules">Using the <strong>Linter</strong></a></p>
         </header>
         <section>

            <h1 id="analysis-options">Analysis Options</h1>
            <p>
               Auto-generated options enabling all lints.
               Add these to your
               <a href="https://dart.dev/guides/language/analysis-options#the-analysis-options-file">analysis_options.yaml file</a>
               and tailor to fit!
            </p>

            ${markdownToHtml(generateOptions())}

         </section>
      </div>
      <footer>
         <p>Maintained by the <a href="https://dart.dev/">Dart Team</a></p>
         <p>Visit us on <a href="https://github.com/dart-lang/linter">Github</a></p>
      </footer>
   </body>
</html>
''';
}

class RuleHtmlGenerator {
  final LintRule rule;

  RuleHtmlGenerator(this.rule);

  String get details => rule.details ?? '';

  String get group => rule.group.name;

  String get humanReadableName => rule.name;

  String get incompatibleRuleDetails {
    final sb = StringBuffer();
    var incompatibleRules = rule.incompatibleRules;
    if (incompatibleRules.isNotEmpty) {
      sb.writeln('<p>');
      sb.write('Incompatible with: ');
      var rule = incompatibleRules.first;
      sb.write(
          '<!--suppress HtmlUnknownTarget --><a href = "$rule.html" >$rule</a>');
      for (var i = 1; i < incompatibleRules.length; ++i) {
        rule = incompatibleRules[i];
        sb.write(', <a href = "$rule.html" >$rule</a>');
      }
      sb.writeln('.');
      sb.writeln('</p>');
    }
    return sb.toString();
  }

  String get maturity => rule.maturity.name;

  String get maturityString {
    switch (rule.maturity) {
      case Maturity.deprecated:
        return '<span style="color:orangered;font-weight:bold;" >$maturity</span>';
      case Maturity.experimental:
        return '<span style="color:hotpink;font-weight:bold;" >$maturity</span>';
      default:
        return maturity;
    }
  }

  String get name => rule.name;

  String get since {
    var info = sinceInfo[name];
    var version = info.sinceDartSdk != null
        ? '>= ${info.sinceDartSdk}'
        : '<strong>unreleased</strong>';
    return 'Dart SDK: $version • <small>(Linter v${info.sinceLinter})</small>';
  }

  void generate([String filePath]) {
    var generated = _generate();
    if (filePath != null) {
      var outPath = '$filePath/$name.html';
      print('Writing to $outPath');
      File(outPath).writeAsStringSync(generated);
    } else {
      print(generated);
    }
  }

  String _generate() => '''
<!DOCTYPE html>
<html lang="en">
   <head>
      <meta charset="utf-8">
      <link rel="shortcut icon" href="../dart-192.png">
      <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
      <meta name="mobile-web-app-capable" content="yes">
      <meta name="apple-mobile-web-app-capable" content="yes">
      <title>$name</title>
      <link rel="stylesheet" href="../styles.css">
   </head>
   <body>
      <div class="wrapper">
         <header>
            <h1>$humanReadableName</h1>
            <p>Group: $group</p>
            <p>Maturity: $maturityString</p>
            <div class="tooltip">
               <p>$since</p>
               <span class="tooltip-content">Since info is static, may be stale</span>
            </div>
            ${getBadges(name)}
            <ul>
               <li><a href="index.html">View all <strong>Lint Rules</strong></a></li>
               <li><a href="https://dart.dev/guides/language/analysis-options#enabling-linter-rules">Using the <strong>Linter</strong></a></li>
            </ul>
            <p><a class="overflow-link" href="index.html">View all <strong>Lint Rules</strong></a></p>
            <p><a class="overflow-link" href="https://dart.dev/guides/language/analysis-options#enabling-linter-rules">Using the <strong>Linter</strong></a></p>
         </header>
         <section>

            ${markdownToHtml(details)}
            $incompatibleRuleDetails
         </section>
      </div>
      <footer>
         <p>Maintained by the <a href="https://dart.dev/">Dart Team</a></p>
         <p>Visit us on <a href="https://github.com/dart-lang/linter">Github</a></p>
      </footer>
   </body>
</html>
''';
}

class RuleMarkdownGenerator {
  final LintRule rule;

  RuleMarkdownGenerator(this.rule);

  String get details => rule.details ?? '';

  String get group => rule.group.name;

  String get maturity => rule.maturity.name;

  String get name => rule.name;

  String get since {
    var info = sinceInfo[name];
    var version = info.sinceDartSdk != null
        ? '>= ${info.sinceDartSdk}'
        : '**unreleased**';
    return 'Dart SDK: $version • (Linter v${info.sinceLinter})';
  }

  void generate({String filePath}) {
    final buffer = StringBuffer();

    buffer.writeln('# Rule $name');
    buffer.writeln();
    buffer.writeln('**Group**: $group\\');
    buffer.writeln('**Maturity**: $maturity\\');
    buffer.writeln('**Since**: $since\\');
    buffer.writeln();

    // badges
    if (flutterRules.contains(name)) {
      buffer.writeln('[![flutter](style-flutter.svg)]'
          '(https://github.com/flutter/flutter/blob/master/packages/'
          'flutter/lib/analysis_options_user.yaml)');
    }
    if (pedanticRules.contains(name)) {
      buffer.writeln('[![pedantic](style-pedantic.svg)]'
          '(https://github.com/dart-lang/pedantic/#enabled-lints)');
    }
    if (effectiveDartRules.contains(name)) {
      buffer.writeln('[![effective dart](style-effective_dart.svg)]'
          '(https://github.com/tenhobi/effective_dart)');
    }

    buffer.writeln();

    buffer.writeln('## Description');
    buffer.writeln();
    buffer.writeln('${details.trim()}');

    // incompatible rules
    final incompatibleRules = rule.incompatibleRules;
    if (incompatibleRules.isNotEmpty) {
      buffer.writeln('## Incompatible With');
      buffer.writeln();
      for (var rule in incompatibleRules) {
        buffer.writeln('- [$rule]($rule.md)');
      }
      buffer.writeln();
    }

    if (filePath == null) {
      print(buffer.toString());
    } else {
      File('$filePath/$name.md').writeAsStringSync(buffer.toString());
    }
  }
}
