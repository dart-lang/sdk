// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol.dart' as protocol;
import 'package:analysis_server/protocol/protocol_generated.dart' as protocol;
import 'package:analysis_server/src/handler/legacy/legacy_handler.dart';
import 'package:analysis_server/src/search/type_hierarchy.dart';

/// The handler for the `search.getTypeHierarchy` request.
class SearchGetTypeHierarchyHandler extends LegacyHandler {
  /// Initialize a newly created handler to be able to service requests for the
  /// [server].
  SearchGetTypeHierarchyHandler(
      super.server, super.request, super.cancellationToken);

  @override
  Future<void> handle() async {
    final searchEngine = server.searchEngine;
    var params = protocol.SearchGetTypeHierarchyParams.fromRequest(request);
    var file = params.file;
    // prepare element
    var element = await server.getElementAtOffset(file, params.offset);
    if (element == null) {
      _sendTypeHierarchyNull(request);
      return;
    }
    // maybe supertype hierarchy only
    if (params.superOnly == true) {
      var computer = TypeHierarchyComputer(searchEngine, element);
      var items = computer.computeSuper();
      var response =
          protocol.SearchGetTypeHierarchyResult(hierarchyItems: items)
              .toResponse(request.id);
      server.sendResponse(response);
      return;
    }
    // prepare type hierarchy
    var computer = TypeHierarchyComputer(searchEngine, element);
    var items = await computer.compute();
    var response = protocol.SearchGetTypeHierarchyResult(hierarchyItems: items)
        .toResponse(request.id);
    server.sendResponse(response);
  }

  void _sendTypeHierarchyNull(protocol.Request request) {
    var response =
        protocol.SearchGetTypeHierarchyResult().toResponse(request.id);
    server.sendResponse(response);
  }
}
