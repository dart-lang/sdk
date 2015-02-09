// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library docgen;

import 'dart:io';

import 'package:args/args.dart';
import 'package:dart_lint/src/linter.dart';
import 'package:dart_lint/src/rules.dart';
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

  ruleMap.values.forEach((l) => new Generator(l).generate(outDir));
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
            <p class="view"><a href="https://github.com/dart-lang/dart_lint">View the Project on GitHub <small>dart-lang/dart_lint</small></a></p>
            <ul>
               <li><a href="https://www.dartlang.org/articles/style-guide/">See the <strong>Style Guide</strong></a></li>
               <li><a href="https://github.com/dart-lang/dart_lint">View On <strong>GitHub</strong></a></li>
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
