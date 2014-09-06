// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Simple script to generate a page summarizing all error messages produces by
/// the polymer compiler code. The generated code will be placed directly under
/// the `polymer/lib/src/generated` folder. This script should be invoked from
/// the root of the polymer package either by doing:
///
///    dart tool/create_message_details_page.dart
///
/// or
///
///    pub run tool/create_message_details_page
library polymer.tool.create_message_details_page;

import 'dart:io';
import 'dart:mirrors';

import 'package:code_transformers/messages/messages.dart';
import 'package:code_transformers/src/messages.dart' as m1; // used via mirrors
import 'package:observe/src/messages.dart' as m2; // used via mirrors
import 'package:polymer/src/build/messages.dart' as m3; // used via mirrors
import 'package:markdown/markdown.dart';
import 'package:path/path.dart' as path;
import 'package:args/args.dart';

main(args) {
  var options = _parseOptions(args);
  var seen = {};
  var templates = [];
  _getMessagesFrom(#polymer.src.build.messages, seen, templates);
  _getMessagesFrom(#code_transformers.src.messages, seen, templates);
  _getMessagesFrom(#observe.src.messages, seen, templates);

  templates.sort((a, b) => a.id.compareTo(b.id));
  var sb = new StringBuffer();
  bool forSite = options['site'];
  var out = path.join(path.current, options['out']);
  var ext = forSite ? '.markdown' : '.html';
  if (!out.endsWith(ext)) {
    print('error: expected to have a $ext extension.');
    exit(1);
  }

  sb.write(forSite ? _SITE_HEADER : _LOCAL_HEADER);

  var lastPackage = '';
  for (var t in templates) {
    if (lastPackage != t.id.package) {
      lastPackage = t.id.package;
      var sectionTitle = '## Messages from package `$lastPackage`\n\n----\n\n';
      sb.write(forSite ? sectionTitle : markdownToHtml(sectionTitle));
    }
    _generateMessage(t, forSite, sb);
  }
  sb.write(forSite ? '' : _LOCAL_FOOTER);
  new File(out).writeAsStringSync(sb.toString());
  print('updated: ${options["out"]}');
}

final _mirrors = currentMirrorSystem();

_getMessagesFrom(Symbol libName, Map seen, List templates) {
  var lib = _mirrors.findLibrary(libName);
  lib.declarations.forEach((symbol, decl) {
    if (decl is! VariableMirror) return;
    var template = lib.getField(symbol).reflectee;
    var name = MirrorSystem.getName(symbol);
    if (template is! MessageTemplate) return;
    var id = template.id;
    if (seen.containsKey(id)) {
      print('error: duplicate id `$id`. '
          'Currently set for both `$name` and `${seen[id]}`.');
    }
    seen[id] = name;
    templates.add(template);
  });
}

_generateMessage(MessageTemplate template, bool forSite, StringBuffer sb) {
  var details = template.details == null
      ? 'No details available' : template.details;
  var id = template.id;
  var hashTag = '${id.package}_${id.id}';
  var title = '### ${template.description} [#${id.id}](#$hashTag)';
  var body = '\n$details\n\n----\n\n';
  // We add the anchor inside the <h3> title, otherwise the link doesn't work.
  if (forSite) {
    sb..write(title)
        ..write('\n{: #$hashTag}\n')
        ..write(body);
  } else {
    var html = markdownToHtml('$title$body')
        .replaceFirst('<h3>', '<h3 id="$hashTag">');
    sb.write('\n\n$html');
  }
}

_parseOptions(args) {
  var parser = new ArgParser(allowTrailingOptions: true)
      ..addOption('out', abbr: 'o',
          defaultsTo: 'lib/src/build/generated/messages.html',
          help: 'the output file path')
      ..addFlag('site', abbr: 's', negatable: false,
          help: 'generate contents for the dartlang.org site')
      ..addFlag('help', abbr: 'h', negatable: false);

  var options = parser.parse(args);
  if (options['help']) {
    var command = Platform.script.path;
    var relPath = path.relative(command, from: path.current);
    if (!relPath.startsWith('../')) command = relPath;
    print('usage: dart $command [-o path_to_output_file] [-s]');
    print(parser.getUsage());
    exit(0);
  }
  return options;
}

const _SITE_HEADER = '''
---
# WARNING: GENERATED FILE. DO NOT EDIT.
#
#   This file was generated automatically from the polymer package.
#   To regenerate this file, from the top directory of the polymer package run:
#
#     dart tool/create_message_details_page.dart -s -o path_to_this_file
layout: default
title: "Error messages"
subsite: "Polymer.dart"
description: "Details about error messages from polymer and related packages."
---

# {{ page.title }}

<style>
h3 > a {
  display: none;
}

h3:hover > a {
  display: inline;
}

</style>


This page contains a list of error messages produced during `pub build` and `pub
serve` by transformers in polymer and its related packages. You can find here
additional details that can often help you figure out how to fix the underlying
problem.


''';

const _LOCAL_HEADER = '''
<!doctype html>
<!--
  This file is autogenerated with polymer/tool/create_message_details_page.dart
-->
<html>
<style>
@font-face {
  font-family: 'Montserrat';
  font-style: normal;
  font-weight: 400;
  src: url(https://themes.googleusercontent.com/static/fonts/montserrat/v4/zhcz-_WihjSQC0oHJ9TCYL3hpw3pgy2gAi-Ip7WPMi0.woff) format('woff');
}
@font-face {
  font-family: 'Montserrat';
  font-style: normal;
  font-weight: 700;
  src: url(https://themes.googleusercontent.com/static/fonts/montserrat/v4/IQHow_FEYlDC4Gzy_m8fcnbFhgvWbfSbdVg11QabG8w.woff) format('woff');
}
@font-face {
  font-family: 'Roboto';
  font-style: normal;
  font-weight: 300;
  src: url(https://themes.googleusercontent.com/static/fonts/roboto/v10/Hgo13k-tfSpn0qi1SFdUfbO3LdcAZYWl9Si6vvxL-qU.woff) format('woff');
}
@font-face {
  font-family: 'Roboto';
  font-style: normal;
  font-weight: 400;
  src: url(https://themes.googleusercontent.com/static/fonts/roboto/v10/CrYjSnGjrRCn0pd9VQsnFOvvDin1pK8aKteLpeZ5c0A.woff) format('woff');
}

body {
  width: 80vw;
  margin: 20px;
  font-family: Roboto, sans-serif;
}

h2 {
  font-family: Montserrat, sans-serif;
  box-sizing: border-box;
  color: rgb(72, 72, 72);
  display: block;
  font-style: normal;
  font-variant: normal;
  font-weight: normal;
}

h3 {
  font-family: Montserrat, sans-serif;
  box-sizing: border-box;
  color: rgb(72, 72, 72);
  display: block;
  font-style: normal;
  font-variant: normal;
  font-weight: normal;
}

pre {
  display: block;
  padding: 9.5px;
  margin: 0 0 10px;
  color: #333;
  word-break: break-all;
  word-wrap: break-word;
  background-color: #f5f5f5;
  border: 1px solid #ccc;
  border-radius: 4px;
}

code {
   font-family: Menlo,Monaco,Consolas,"Courier New",monospace;
   box-sizing: border-box;
   padding: 0;
   font-size: 90%;
   color: #0084c5;
   white-space: nowrap;
   border-radius: 4px;
   background-color: #f9f2f4;
}

pre code {
   white-space: inherit;
   color: inherit;
   background-color: inherit;
}

a {
  color: rgb(42, 100, 150);
}

h3 > a {
  display: none;
  font-size: 0.8em;
}

h3:hover > a {
  display: inline;
}
</style>
<body>
''';

const _LOCAL_FOOTER = '''
</body>
</html>
''';
