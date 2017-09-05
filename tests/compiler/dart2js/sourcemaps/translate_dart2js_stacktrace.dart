// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:args/args.dart';
import 'package:http/http.dart' as http;
import 'package:source_maps/source_maps.dart';

ArgParser parser = new ArgParser()
  ..addFlag('inline',
      abbr: 'i',
      negatable: true,
      help: 'Inline untranslatable parts..',
      defaultsTo: false);

main(List<String> arguments) async {
  ArgResults options = parser.parse(arguments);

  if (options.rest.length != 1) {
    print('Usage: <script.dart> [<options>] <file or url for source map file>\n'
        'Options:\n'
        '${parser.usage}');
    exit(2);
  }

  String url = options.rest[0];
  String data;
  if (url.startsWith("http://") || url.startsWith("https://")) {
    data = (await http.get(url)).body;
  } else {
    data = new File(url).readAsStringSync();
  }

  SingleMapping sourceMap = parse(data);

  print("Now paste the stacktrace here. Finish with at least 3 empty lines...");

  int emptyInARow = 0;
  List<String> lines = [];
  while (true) {
    String line = stdin.readLineSync();
    if (line == null) break;
    if (line == "") {
      ++emptyInARow;
    } else {
      lines.add(line);
      emptyInARow = 0;
    }

    if (emptyInARow >= 3) break;
  }

  List<String> tailMessages = [];

  for (String line in lines) {
    Iterable<Match> ms = new RegExp(r"(\d+):(\d+)").allMatches(line);
    if (ms.isEmpty) {
      if (options['inline']) {
        print("----- (unparseable) -----");
      } else {
        tailMessages.add("Unparseable line: $line");
      }
      continue;
    }
    Match m = ms.first;
    int l = int.parse(m.group(1));
    int c = int.parse(m.group(2));
    SourceMapSpan span = sourceMap.spanFor(l, c);
    if (span?.start == null) {
      if (options['inline']) {
        print("----- (unparseable) -----");
      } else {
        tailMessages.add("No sourcemap entry for line line: $line");
      }
      continue;
    }
    print(span.start.toolString);
  }

  if (tailMessages.isNotEmpty) {
    print("");
    print("Messages:");
    print("");
    for (String line in tailMessages) {
      print(line);
    }
  }
}
