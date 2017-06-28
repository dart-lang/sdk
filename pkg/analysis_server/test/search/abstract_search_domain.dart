// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/search/search_domain.dart';
import 'package:analysis_server/src/services/index/index.dart'
    show Index, createMemoryIndex;
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';

import '../analysis_abstract.dart';

class AbstractSearchDomainTest extends AbstractAnalysisTest {
  final Map<String, _ResultSet> resultSets = {};
  String searchId;
  List<SearchResult> results = <SearchResult>[];
  SearchResult result;

  void assertHasResult(SearchResultKind kind, String search, [int length]) {
    int offset = findOffset(search);
    if (length == null) {
      length = findIdentifierLength(search);
    }
    findResult(kind, testFile, offset, length, true);
  }

  void assertNoResult(SearchResultKind kind, String search, [int length]) {
    int offset = findOffset(search);
    if (length == null) {
      length = findIdentifierLength(search);
    }
    findResult(kind, testFile, offset, length, false);
  }

  @override
  Index createIndex() {
    return createMemoryIndex();
  }

  void findResult(SearchResultKind kind, String file, int offset, int length,
      bool expected) {
    for (SearchResult result in results) {
      Location location = result.location;
      if (result.kind == kind &&
          location.file == file &&
          location.offset == offset &&
          location.length == length) {
        if (!expected) {
          fail('Unexpected result $result in\n' + results.join('\n'));
        }
        this.result = result;
        return;
      }
    }
    if (expected) {
      fail(
          'Not found: "search" kind=$kind offset=$offset length=$length\nin\n' +
              results.join('\n'));
    }
  }

  String getPathString(List<Element> path) {
    return path.map((Element element) {
      String kindName = element.kind.name;
      String name = element.name;
      if (name.isEmpty) {
        return kindName;
      } else {
        return '$kindName $name';
      }
    }).join('\n');
  }

  @override
  void processNotification(Notification notification) {
    super.processNotification(notification);
    if (notification.event == SEARCH_NOTIFICATION_RESULTS) {
      var params = new SearchResultsParams.fromNotification(notification);
      String id = params.id;
      _ResultSet resultSet = resultSets[id];
      if (resultSet == null) {
        resultSet = new _ResultSet(id);
        resultSets[id] = resultSet;
      }
      resultSet.results.addAll(params.results);
      resultSet.done = params.isLast;
    }
  }

  @override
  void setUp() {
    super.setUp();
    createProject();
    server.handlers = [
      new SearchDomainHandler(server),
    ];
  }

  Future waitForSearchResults() {
    _ResultSet resultSet = resultSets[searchId];
    if (resultSet != null && resultSet.done) {
      results = resultSet.results;
      return new Future.value();
    }
    return new Future.delayed(Duration.ZERO, waitForSearchResults);
  }
}

class _ResultSet {
  final String id;
  final List<SearchResult> results = <SearchResult>[];
  bool done = false;

  _ResultSet(this.id);
}
