// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.search.abstract_search_domain;

import 'dart:async';

import 'package:analysis_server/src/computer/element.dart';
import 'package:analysis_server/src/constants.dart';
import 'package:analysis_server/src/protocol.dart';
import 'package:analysis_server/src/search/search_domain.dart';
import 'package:analysis_server/src/search/search_result.dart';
import 'package:analysis_services/index/index.dart' show Index;
import 'package:analysis_services/index/local_memory_index.dart';
import 'package:unittest/unittest.dart';

import '../analysis_abstract.dart';


class AbstractSearchDomainTest extends AbstractAnalysisTest {
  String searchId;
  bool searchDone = false;
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
    return createLocalMemoryIndex();
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
      return '${element.kind} ${element.name}';
    }).join('\n');
  }

  void processNotification(Notification notification) {
    if (notification.event == SEARCH_RESULTS) {
      String id = notification.getParameter(ID);
      if (id == searchId) {
        for (Map<String, Object> json in notification.getParameter(RESULTS)) {
          results.add(new SearchResult.fromJson(json));
        }
        searchDone = notification.getParameter(LAST);
      }
    }
  }

  @override
  void setUp() {
    super.setUp();
    createProject();
    handler = new SearchDomainHandler(server);
  }

  Future waitForSearchResults() {
    if (searchDone) {
      return new Future.value();
    }
    return new Future.delayed(Duration.ZERO, waitForSearchResults);
  }
}
