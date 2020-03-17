// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

void main() async {
  print('Getting latest linter package info from pub...');
  final packageInfo =
      jsonDecode(await getBody('https://pub.dev/api/packages/linter'));
  final latestVersion = packageInfo['latest']['pubspec']['version'];
  print('Found: $latestVersion.');
  print('Checking for a git release tag corresponding to $latestVersion...');

  var client = http.Client();
  var req = await client
      .get('https://github.com/dart-lang/linter/releases/tag/$latestVersion');

  if (req.statusCode == 404) {
    print(
        'No tagged release for $latestVersion found; this will cause problems when included in SDK DEPS.');
    print(
        'Be sure a $latestVersion release is tagged in https://github.com/dart-lang/linter/releases and re-run.');
    exit(1);
  } else {
    print('Tag found 👍.');
  }
}

final _client = http.Client();

Future<String> getBody(String url) async => (await getResponse(url)).body;

Future<http.Response> getResponse(String url) async => _client.get(url);
