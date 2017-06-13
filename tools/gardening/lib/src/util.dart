// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';

import 'cache.dart';

/// Split [text] using [infixes] as infix markers.
List<String> split(String text, List<String> infixes) {
  List<String> result = <String>[];
  int start = 0;
  for (String infix in infixes) {
    int index = text.indexOf(infix, start);
    if (index == -1)
      throw "'$infix' not found in '$text' from offset ${start}.";
    result.add(text.substring(start, index));
    start = index + infix.length;
  }
  result.add(text.substring(start));
  return result;
}

/// Pad [text] with spaces to the right to fit [length].
String padRight(String text, int length) {
  if (text.length < length) return '${text}${' ' * (length - text.length)}';
  return text;
}

/// Pad [text] with spaces to the left to fit [length].
String padLeft(String text, int length) {
  if (text.length < length) return '${' ' * (length - text.length)}${text}';
  return text;
}

bool LOG = const bool.fromEnvironment('LOG', defaultValue: false);

void log(Object text) {
  if (LOG) print(text);
}

/// Reads the content of [uri] as text.
Future<String> readUriAsText(HttpClient client, Uri uri) async {
  HttpClientRequest request = await client.getUrl(uri);
  HttpClientResponse response = await request.close();
  return await response.transform(UTF8.decoder).join();
}

ArgParser createArgParser() {
  ArgParser argParser = new ArgParser(allowTrailingOptions: true);
  argParser.addFlag('help', help: "Help");
  argParser.addFlag('verbose',
      abbr: 'v', negatable: false, help: "Turn on logging output.");
  argParser.addFlag('no-cache', help: "Disable caching.");
  argParser.addOption('cache',
      help: "Use <dir> for caching test output.\n"
          "Defaults to 'temp/gardening-cache/'.");
  argParser.addFlag('logdog',
      negatable: false, help: "Pull test results from logdog.");
  return argParser;
}

void processArgResults(ArgResults argResults) {
  if (argResults['verbose']) {
    LOG = true;
  }
  if (argResults['cache'] != null) {
    cache.base = Uri.base.resolve('${argResults['cache']}/');
  }
  if (argResults['no-cache']) {
    cache.base = null;
  }
}
