// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/handler/legacy/legacy_handler.dart';
import 'package:analysis_server/src/protocol_server.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:dart_style/src/dart_formatter.dart';
import 'package:dart_style/src/exceptions.dart';
import 'package:dart_style/src/source_code.dart';
import 'package:pub_semver/pub_semver.dart';

/// The handler for the `edit.formatIfEnabled` request.
class EditFormatIfEnabledHandler extends LegacyHandler {
  /// Initialize a newly created handler to be able to service requests for the
  /// [server].
  EditFormatIfEnabledHandler(
      super.server, super.request, super.cancellationToken, super.performance);

  /// Format the given [file] with the given [languageVersion].
  ///
  /// Throws a [FileSystemException] if the file doesn't exist or can't be read.
  /// Throws a [FormatterException] if the code could not be formatted.
  List<SourceEdit> formatFile(File file, {Version? languageVersion}) {
    // TODO(brianwilkerson): Move this to a superclass when `edit.format` is
    //  implemented by a handler class so the code can be shared.
    var originalContent = file.readAsStringSync();
    var code = SourceCode(originalContent);

    var formatter = DartFormatter(
        languageVersion:
            languageVersion ?? DartFormatter.latestLanguageVersion);

    var formatResult = formatter.formatSource(code);
    var formattedContent = formatResult.text;

    var edits = <SourceEdit>[];
    if (formattedContent != originalContent) {
      // TODO(brianwilkerson): Replace full replacements with smaller, more
      //  targeted edits.
      var edit = SourceEdit(0, originalContent.length, formattedContent);
      edits.add(edit);
    }
    return edits;
  }

  @override
  Future<void> handle() async {
    var params = EditFormatIfEnabledParams.fromRequest(request,
        clientUriConverter: server.uriConverter);
    var collection = AnalysisContextCollectionImpl(
      includedPaths: params.directories,
      resourceProvider: server.resourceProvider,
      sdkPath: server.sdkPath,
    );
    var sourceFileEdits = <SourceFileEdit>[];
    for (var context in collection.contexts) {
      await _formatInContext(context, sourceFileEdits);
    }
    sendResult(EditFormatIfEnabledResult(sourceFileEdits));
  }

  /// Format all of the Dart files in the given [context] whose associated
  /// `codeStyleOptions` enable formatting, adding the edits to the list of
  /// [sourceFileEdits].
  Future<void> _formatInContext(DriverBasedAnalysisContext context,
      List<SourceFileEdit> sourceFileEdits) async {
    var pathContext = context.resourceProvider.pathContext;
    for (var filePath in context.contextRoot.analyzedFiles()) {
      // Skip anything but .dart files.
      if (!file_paths.isDart(pathContext, filePath)) continue;
      // TODO(pq): consider optimizing this file (re)creation
      // `analyzedFiles()` creates and disposes of a File object only for us
      // to recreate it here. It would be faster if we could get the files
      // directly from the context root.
      var resource = context.resourceProvider.getResource(filePath);
      if (resource is! File) continue;

      var options = context.getAnalysisOptionsForFile(resource);
      if (options.codeStyleOptions.useFormatter) {
        try {
          var library = await context.driver.getResolvedLibrary(filePath);
          var languageVersion = library.effectiveLanguageVersion;
          var sourceEdits =
              formatFile(resource, languageVersion: languageVersion);
          if (sourceEdits.isNotEmpty) {
            sourceFileEdits
                .add(SourceFileEdit(filePath, 0, edits: sourceEdits));
          }
        } catch (exception) {
          // Ignore files that can't be formatted.
        }
      }
    }
  }
}
