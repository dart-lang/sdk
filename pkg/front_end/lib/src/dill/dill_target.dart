// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/messages/severity.dart' show Severity;
import 'package:kernel/ast.dart' show Source;
import 'package:kernel/target/targets.dart' show Target;

import '../base/compiler_context.dart' show CompilerContext;
import '../base/messages.dart' show FormattedMessage, LocatedMessage, Message;
import '../base/processed_options.dart' show ProcessedOptions;
import '../base/ticker.dart' show Ticker;
import '../base/uri_translator.dart' show UriTranslator;
import '../kernel/benchmarker.dart' show BenchmarkPhases, Benchmarker;
import 'dill_loader.dart' show DillLoader;

class DillTarget {
  final Ticker ticker;

  bool isLoaded = false;

  late final DillLoader loader;

  final UriTranslator uriTranslator;

  final Target backendTarget;

  final CompilerContext context;

  /// Shared with [CompilerContext].
  Map<Uri, Source> get uriToSource => context.uriToSource;

  final Benchmarker? benchmarker;

  DillTarget(this.context, this.ticker, this.uriTranslator, this.backendTarget,
      {this.benchmarker}) {
    loader = new DillLoader(this);
  }

  void loadExtraRequiredLibraries(DillLoader loader) {
    for (String uri in backendTarget.extraRequiredLibraries) {
      loader.read(Uri.parse(uri), 0,
          accessor: loader.coreLibraryCompilationUnit);
    }
    if (context.compilingPlatform) {
      // Coverage-ignore-block(suite): Not run.
      for (String uri in backendTarget.extraRequiredLibrariesPlatform) {
        loader.read(Uri.parse(uri), 0,
            accessor: loader.coreLibraryCompilationUnit);
      }
    }
  }

  FormattedMessage createFormattedMessage(
      Message message,
      int charOffset,
      int length,
      Uri? fileUri,
      List<LocatedMessage>? messageContext,
      Severity severity,
      {List<Uri>? involvedFiles}) {
    ProcessedOptions processedOptions = context.options;
    return processedOptions.format(
        context,
        fileUri != null
            ? message.withLocation(fileUri, charOffset, length)
            :
            // Coverage-ignore(suite): Not run.
            message.withoutLocation(),
        severity,
        messageContext,
        involvedFiles: involvedFiles);
  }

  void buildOutlines({bool suppressFinalizationErrors = false}) {
    if (loader.libraries.isNotEmpty) {
      benchmarker
          // Coverage-ignore(suite): Not run.
          ?.enterPhase(BenchmarkPhases.dill_buildOutlines);
      loader.buildOutlines();
      benchmarker
          // Coverage-ignore(suite): Not run.
          ?.enterPhase(BenchmarkPhases.dill_finalizeExports);
      loader.finalizeExports(
          suppressFinalizationErrors: suppressFinalizationErrors);
      benchmarker
          // Coverage-ignore(suite): Not run.
          ?.enterPhase(BenchmarkPhases.unknownDillTarget);
    }
    isLoaded = true;
  }
}
