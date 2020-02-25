// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:html/parser.dart' show parse;
import 'package:http/http.dart' as http;

Future<void> main() async {
  // (Re) generate the list of github repos on itsallwidgets.com
  final repos = await RepoList.fromItsAllWidgetsRssFeed();
  File('itsallwidgets_repos.txt').writeAsStringSync(repos.join('\n'));
}

const itsallwidgetsRssFeed = 'https://itsallwidgets.com/app/feed';

final _client = http.Client();

Future<String> _getBody(String url) async => (await _getResponse(url)).body;

Future<http.Response> _getResponse(String url) async => _client
    .get(url, headers: const {'User-Agent': 'dart.pkg.completion_metrics'});

class RepoList {
  static Future<List<String>> fromItsAllWidgetsRssFeed() async {
    final repos = <String>{};

    final body = await _getBody(itsallwidgetsRssFeed);
    final doc = parse(body);
    final entries = doc.querySelectorAll('entry');
    for (var entry in entries) {
      final link = entry.querySelector('link');
      final href = link.attributes['href'];
      final body = await _getBody(href);
      final doc = parse(body);
      final links = doc.querySelectorAll('a');
      for (var link in links) {
        final href = link.attributes['href'];
        if (href != null && href.startsWith('https://github.com/')) {
          print(href);
          repos.add(href);
          continue;
        }
      }
    }
    return repos.toList();
  }
}
