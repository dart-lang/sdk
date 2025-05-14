// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/handler/legacy/legacy_handler.dart';
import 'package:analysis_server/src/utilities/extensions/formatter_options.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:dart_style/dart_style.dart' hide TrailingCommas;

/// The handler for the `edit.format` request.
class EditFormatHandler extends LegacyHandler {
  /// Initialize a newly created handler to be able to service requests for the
  /// [server].
  EditFormatHandler(
    super.server,
    super.request,
    super.cancellationToken,
    super.performance,
  );

  @override
  Future<void> handle() async {
    var params = EditFormatParams.fromRequest(
      request,
      clientUriConverter: server.uriConverter,
    );
    var file = params.file;

    var driver = server.getAnalysisDriver(file);
    var unit = driver?.parseFileSync(file);
    if (unit is! ParsedUnitResult) {
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

    var unformattedCode = unit.content;
    var code = SourceCode(
      unformattedCode,
      selectionStart: start,
      selectionLength: length,
    );

    var formatterOptions = unit.analysisOptions.formatterOptions;
    var effectivePageWidth = formatterOptions.pageWidth ?? params.lineLength;
    var effectiveTrailingCommas = formatterOptions.dartStyleTrailingCommas;
    var effectiveLanguageVersion = unit.unit.languageVersion.effective;
    var formatter = DartFormatter(
      pageWidth: effectivePageWidth,
      trailingCommas: effectiveTrailingCommas,
      languageVersion: effectiveLanguageVersion,
    );
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
      // TODO(brianwilkerson): replace full replacements with smaller, more targeted edits
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
