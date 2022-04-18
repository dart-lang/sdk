// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol_generated.dart' as protocol;
import 'package:analysis_server/src/handler/legacy/legacy_handler.dart';
import 'package:analysis_server/src/search/search_domain.dart';

/// The handler for the `search.findMemberDeclarations` request.
class SearchFindMemberDeclarationsHandler extends LegacyHandler {
  /// Initialize a newly created handler to be able to service requests for the
  /// [server].
  SearchFindMemberDeclarationsHandler(
      super.server, super.request, super.cancellationToken);

  @override
  Future<void> handle() async {
    final searchEngine = server.searchEngine;
    var params =
        protocol.SearchFindMemberDeclarationsParams.fromRequest(request);
    await server.onAnalysisComplete;
    // respond
    var searchId = (server.nextSearchId++).toString();
    sendResult(protocol.SearchFindMemberDeclarationsResult(searchId));
    // search
    var matches = await searchEngine.searchMemberDeclarations(params.name);
    sendSearchResults(protocol.SearchResultsParams(
        searchId, matches.map(SearchDomainHandler.toResult).toList(), true));
  }
}
