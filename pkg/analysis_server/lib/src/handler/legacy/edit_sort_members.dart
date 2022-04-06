// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/handler/legacy/legacy_handler.dart';
import 'package:analysis_server/src/services/correction/sort_members.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer/src/utilities/cancellation.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';

/// The handler for the `edit.sortMembers` request.
class EditSortMembersHandler extends LegacyHandler {
  /// Initialize a newly created handler to be able to service requests for the
  /// [server].
  EditSortMembersHandler(AnalysisServer server, Request request,
      CancellationToken cancellationToken)
      : super(server, request, cancellationToken);

  @override
  Future<void> handle() async {
    var params = EditSortMembersParams.fromRequest(request);
    var file = params.file;

    if (server.sendResponseErrorIfInvalidFilePath(request, file)) {
      return;
    }

    var pathContext = server.resourceProvider.pathContext;
    if (!file_paths.isDart(pathContext, file)) {
      sendResponse(Response.sortMembersInvalidFile(request));
      return;
    }

    // Prepare the file information.
    var result = await server.getParsedUnit(file);
    if (result == null) {
      sendResponse(Response.fileNotAnalyzed(request, file));
      return;
    }

    var fileStamp = -1;
    var code = result.content;
    var unit = result.unit;
    var errors = result.errors;
    // Check if there are scan/parse errors in the file.
    var numScanParseErrors = numberOfSyntacticErrors(errors);
    if (numScanParseErrors != 0) {
      sendResponse(
          Response.sortMembersParseErrors(request, numScanParseErrors));
      return;
    }
    // Do sort.
    var sorter = MemberSorter(code, unit, result.lineInfo);
    var edits = sorter.sort();
    var fileEdit = SourceFileEdit(file, fileStamp, edits: edits);
    sendResult(EditSortMembersResult(fileEdit));
  }
}
