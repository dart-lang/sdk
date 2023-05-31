// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:linter/src/utils.dart';

void main() async {
  printToConsole('Getting latest linter package info from pub...');
  var packageInfo =
      jsonDecode(await getBody('https://pub.dev/api/packages/linter'));
  var latestVersion = packageInfo['latest']['pubspec']['version'];
  printToConsole('Found: $latestVersion.');
  printToConsole(
      'Checking for a git release tag corresponding to $latestVersion...');

  var client = http.Client();
  var req = await client.get(Uri.parse(
      'https://github.com/dart-lang/linter/releases/tag/$latestVersion'));

  if (req.statusCode == 404) {
    printToConsole(
        'No tagged release for $latestVersion found; this will cause problems when included in SDK DEPS.');
    printToConsole(
        'Be sure a $latestVersion release is tagged in https://github.com/dart-lang/linter/releases and re-run.');
    exit(1);
  } else {
    printToConsole('Tag found 👍.');
  }
}

final _client = http.Client();

Future<String> getBody(String url) async => (await getResponse(url)).body;

Future<http.Response> getResponse(String url) async =>
    _client.get(Uri.parse(url));
