// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/plugin/protocol/protocol_dart.dart' as protocol;
import 'package:analysis_server/protocol/protocol_generated.dart' as protocol;
import 'package:analysis_server/src/handler/legacy/legacy_handler.dart';
import 'package:analysis_server/src/search/element_references.dart';
import 'package:analyzer/dart/element/element.dart';

/// The handler for the `search.findElementReferences` request.
class SearchFindElementReferencesHandler extends LegacyHandler {
  /// Initialize a newly created handler to be able to service requests for the
  /// [server].
  SearchFindElementReferencesHandler(
      super.server, super.request, super.cancellationToken);

  @override
  Future<void> handle() async {
    final searchEngine = server.searchEngine;
    var params =
        protocol.SearchFindElementReferencesParams.fromRequest(request);
    var file = params.file;
    // prepare element
    var element = await server.getElementAtOffset(file, params.offset);
    if (element is ImportElement) {
      element = element.prefix;
    }
    if (element is FieldFormalParameterElement) {
      element = element.field;
    }
    if (element is PropertyAccessorElement) {
      element = element.variable;
    }
    // respond
    var searchId = (server.nextSearchId++).toString();
    var result = protocol.SearchFindElementReferencesResult();
    if (element != null) {
      result.id = searchId;
      var withNullability = element.library?.isNonNullableByDefault ?? false;
      result.element =
          protocol.convertElement(element, withNullability: withNullability);
    }
    sendResult(result);
    // search elements
    if (element != null) {
      var computer = ElementReferencesComputer(searchEngine);
      var results = await computer.compute(element, params.includePotential);
      sendSearchResults(
          protocol.SearchResultsParams(searchId, results.toList(), true));
    }
  }
}
