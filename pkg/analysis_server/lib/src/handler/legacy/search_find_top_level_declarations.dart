// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/handler/legacy/legacy_handler.dart';
import 'package:analysis_server/src/protocol_server.dart' as protocol;

/// The handler for the `search.findTopLevelDeclarations` request.
class SearchFindTopLevelDeclarationsHandler extends LegacyHandler {
  /// Initialize a newly created handler to be able to service requests for the
  /// [server].
  SearchFindTopLevelDeclarationsHandler(
      super.server, super.request, super.cancellationToken);

  @override
  Future<void> handle() async {
    final searchEngine = server.searchEngine;
    var params =
        protocol.SearchFindTopLevelDeclarationsParams.fromRequest(request);
    try {
      // validate the regex
      RegExp(params.pattern);
    } on FormatException catch (exception) {
      server.sendResponse(protocol.Response.invalidParameter(
          request, 'pattern', exception.message));
      return;
    }

    await server.onAnalysisComplete;
    // respond
    var searchId = (server.nextSearchId++).toString();
    sendResult(protocol.SearchFindTopLevelDeclarationsResult(searchId));
    // search
    var matches = await searchEngine.searchTopLevelDeclarations(params.pattern);
    sendSearchResults(protocol.SearchResultsParams(searchId,
        matches.map(protocol.newSearchResult_fromMatch).toList(), true));
  }
}
