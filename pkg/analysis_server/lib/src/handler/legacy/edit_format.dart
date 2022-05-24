// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/handler/legacy/legacy_handler.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:dart_style/src/dart_formatter.dart';
import 'package:dart_style/src/exceptions.dart';
import 'package:dart_style/src/source_code.dart';

/// The handler for the `edit.format` request.
class EditFormatHandler extends LegacyHandler {
  /// Initialize a newly created handler to be able to service requests for the
  /// [server].
  EditFormatHandler(super.server, super.request, super.cancellationToken);

  @override
  Future<void> handle() async {
    server.options.analytics?.sendEvent('edit', 'format');

    var params = EditFormatParams.fromRequest(request);
    var file = params.file;
//
    String unformattedCode;
    try {
      var resource = server.resourceProvider.getFile(file);
      unformattedCode = resource.readAsStringSync();
    } catch (e) {
      sendResponse(Response.formatInvalidFile(request));
      return;
    }

    int? start = params.selectionOffset;
    int? length = params.selectionLength;

    // No need to preserve 0,0 selection
    if (start == 0 && length == 0) {
      start = null;
      length = null;
    }

    var code = SourceCode(unformattedCode,
        uri: null,
        isCompilationUnit: true,
        selectionStart: start,
        selectionLength: length);
    var formatter = DartFormatter(pageWidth: params.lineLength);
    SourceCode formattedResult;
    try {
      formattedResult = formatter.formatSource(code);
    } on FormatterException {
      sendResponse(Response.formatWithErrors(request));
      return;
    }
    var formattedSource = formattedResult.text;

    var edits = <SourceEdit>[];

    if (formattedSource != unformattedCode) {
      //TODO: replace full replacements with smaller, more targeted edits
      var edit = SourceEdit(0, unformattedCode.length, formattedSource);
      edits.add(edit);
    }

    var newStart = formattedResult.selectionStart;
    var newLength = formattedResult.selectionLength;

    // Sending null start/length values would violate protocol, so convert back
    // to 0.
    newStart ??= 0;
    newLength ??= 0;

    sendResult(EditFormatResult(edits, newStart, newLength));
  }
}
