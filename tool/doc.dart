// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library docgen;

import 'dart:io';

import 'package:args/args.dart';
import 'package:linter/src/linter.dart';
import 'package:linter/src/rules.dart';
import 'package:markdown/markdown.dart';

/// Generates lint rule docs for publishing to http://dart-lang.github.io/
void main([args]) {
  var parser = new ArgParser(allowTrailingOptions: true);

  parser.addOption('out', abbr: 'o', help: 'Specifies output directory.');

  var options;
  try {
    options = parser.parse(args);
  } on FormatException catch (err) {
    printUsage(parser, err.message);
    return;
  }

  var outDir = options['out'];

  if (outDir != null) {
    Directory d = new Directory(outDir);
    if (!d.existsSync()) {
      print("Directory '${d.path}' does not exist");
      return;
    }
  }

  var rules = ruleMap.values;

  // Generate index
  new Indexer(rules).generate(outDir);

  // Generate rule files
  rules.forEach((l) => new Generator(l).generate(outDir));
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

class Generator {
  LintRule rule;
  Generator(this.rule);

  String get details => rule.details != null ? rule.details : '';
  String get group => rule.group.name;
  String get humanReadableName => rule.name.humanized;
  String get kind => rule.kind.name;
  String get maturity => rule.maturity.name;
  String get name => rule.name.value;

  generate([String filePath]) {
    var generated = _generate();
    if (filePath != null) {
      var outPath = '$filePath/$name.html';
      print('Writing to $outPath');
      new File(outPath).writeAsStringSync(generated);
    } else {
      print(generated);
    }
  }

  String _generate() => '''
<!doctype html>
<html>
   <head>
      <meta charset="utf-8">
      <meta http-equiv="X-UA-Compatible" content="chrome=1">
      <title>$name</title>
      <link rel="stylesheet" href="../stylesheets/styles.css">
      <link rel="stylesheet" href="../stylesheets/pygment_trac.css">
      <script src="../javascripts/scale.fix.js"></script>
      <meta name="viewport" content="width=device-width, initial-scale=1, user-scalable=no">
      <!--[if lt IE 9]>
      <script src="//html5shiv.googlecode.com/svn/trunk/html5.js"></script>
      <![endif]-->
   </head>
   <body>
      <div class="wrapper">
         <header>
            <h1>$humanReadableName</h1>
            <p>Group: $group</p>
            <p>Kind: $kind</p>
            <p>Maturity: $maturity</p>
            <p class="view"><a href="https://github.com/dart-lang/linter">View the Project on GitHub <small>dart-lang/linter</small></a></p>
            <ul>
               <li><a href="https://www.dartlang.org/articles/style-guide/">See the <strong>Style Guide</strong></a></li>
               <li><a href="http://dart-lang.github.io/linter/lints/">List of <strong>Lint Rules</strong></a></li>
            </ul>
         </header>
         <section>
  
            ${markdownToHtml(details)}
          
         </section>
      </div>
      <footer>
         <p>Project maintained by <a href="https://github.com/dart-lang">dart-lang</a></p>
         <p>Hosted on GitHub Pages &mdash; Theme by <a href="https://github.com/orderedlist">orderedlist</a></p>
      </footer>
      <!--[if !IE]><script>fixScale(document);</script><![endif]-->
   </body>
</html>
''';
}

const ruleLeadMatter = '''
Lint rules are grouped by imperatives inline with the Dart 
[style guide] (https://www.dartlang.org/articles/style-guide/).

In summary:
''';

const ruleFootMatter = '''
In addition, rules can be further distinguished by *maturity*.  Unqualified
rules are considered stable, while others may be marked **EXPERIMENTAL** 
to indicate that they are under review.

These rules are under active development.  Feedback is 
[welcome](https://github.com/dart-lang/linter/issues)!
''';

String get enumerateKinds => Kind.supported
    .map((Kind k) => '<li>${markdownToHtml(k.description)}</li>')
    .join('\n');

String get enumeratePubRules =>
rules.where((r) => r.group == Group.PUB).map((r) => '${toDescription(r)}').join('\n\n');

String get enumerateStyleGuideRules =>
  rules.where((r) => r.group == Group.STYLE_GUIDE).map((r) => '${toDescription(r)}').join('\n\n');

String toDescription(LintRule r) =>
    '<strong><a href = "${r.name}.html">${qualify(r)}</a></strong><br/>${markdownToHtml(r.description)}';

String qualify(LintRule r) => r.name.toString() +
    (r.maturity == Maturity.STABLE ? '' : ' (${r.maturity.name})');

class Indexer {
  Iterable<LintRule> rules;
  Indexer(this.rules);

  generate(String filePath) {
    var generated = _generate();
    if (filePath != null) {
      var outPath = '$filePath/index.html';
      print('Writing to $outPath');
      new File(outPath).writeAsStringSync(generated);
    } else {
      print(generated);
    }
  }

  String _generate() => '''
<!doctype html>
<html>
   <head>
      <meta charset="utf-8">
      <meta http-equiv="X-UA-Compatible" content="chrome=1">
      <title>Dart Lint</title>
      <link rel="stylesheet" href="../stylesheets/styles.css">
      <link rel="stylesheet" href="../stylesheets/pygment_trac.css">
      <script src="javascripts/scale.fix.js"></script>
      <meta name="viewport" content="width=device-width, initial-scale=1, user-scalable=no">
      <!--[if lt IE 9]>
      <script src="//html5shiv.googlecode.com/svn/trunk/html5.js"></script>
      <![endif]-->
   </head>
   <body>
      <div class="wrapper">
         <header>
            <a href="http://dart-lang.github.io/linter/">
               <h1>Dart Lint</h1>
            </a>
            <p>Lint Rules</p>
            <p class="view"><a href="https://github.com/dart-lang/linter">View the Project on GitHub <small>dartlang/linter</small></a></p>
            <ul>
               <li><a href="https://github.com/dart-lang/linter">View On <strong>GitHub</strong></a></li>
            </ul>
         </header>
         <section>

            <h1 id="supported-lints">Supported Lint Rules</h1>
            <p>
               This list is auto-generated from our sources.
            </p>
            <p>
               ${markdownToHtml(ruleLeadMatter)}
            </p>
            <ul>
               <p>
                  $enumerateKinds
               </p>
            </ul>
            <p>
               ${markdownToHtml(ruleFootMatter)}
            </p>

            <h2 id="styleguide-rules">Style Guide Rules</h2>

               $enumerateStyleGuideRules

            <h2 id="styleguide-rules">Pub Rules</h2>

               $enumeratePubRules
            
         </section>
      </div>
      <footer>
         <p>Project maintained by <a href="https://github.com/google">google</a></p>
         <p>Hosted on GitHub Pages &mdash; Theme by <a href="https://github.com/orderedlist">orderedlist</a></p>
      </footer>
      <!--[if !IE]><script>fixScale(document);</script><![endif]-->
      <script type="text/javascript">
         var gaJsHost = (("https:" == document.location.protocol) ? "https://ssl." : "http://www.");
         document.write(unescape("%3Cscript src='" + gaJsHost + "google-analytics.com/ga.js' type='text/javascript'%3E%3C/script%3E"));
      </script>
      <script type="text/javascript">
         try {
           var pageTracker = _gat._getTracker("UA-34425814-2");
         pageTracker._trackPageview();
         } catch(err) {}
      </script>
   </body>
</html>
''';
}
