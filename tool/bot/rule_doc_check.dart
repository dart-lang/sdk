// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:linter/src/utils.dart';
import 'package:test/test.dart';

import '../crawl.dart';

void main() async {
  printToConsole('Getting latest linter package info from pub...');

  var packageInfo =
      jsonDecode(await getBody('https://pub.dev/api/packages/linter'));
  var latestVersion = packageInfo['latest']['pubspec']['version'];
  printToConsole('Found: $latestVersion.');
  if (latestVersion is String) {
    var minor = latestVersion.split('.').last;
    var latestRules = await fetchRulesForVersion('0.1.$minor');
    printToConsole('Checking to ensure rules have published docs...');
    printToConsole('');

    group('validate url:', () {
      for (var rule in latestRules) {
        test(rule, () async {
          // todo (pq): consider replacing w/ lintCode.url
          // see: https://github.com/dart-lang/linter/issues/2034
          var response = await http.head(
              Uri.parse('https://dart-lang.github.io/linter/lints/$rule.html'));
          expect(response.statusCode, 200);
        });
      }
    });
  } else {
    fail('version fetch from pub failed');
  }
}

final _client = http.Client();

Future<String> getBody(String url) async => (await getResponse(url)).body;

Future<http.Response> getResponse(String url) async =>
    _client.get(Uri.parse(url));
