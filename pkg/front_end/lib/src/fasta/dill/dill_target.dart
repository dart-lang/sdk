// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/messages/severity.dart' show Severity;

import 'package:kernel/ast.dart' show Library, Source;

import 'package:kernel/target/targets.dart' show Target;

import '../../base/processed_options.dart' show ProcessedOptions;

import '../compiler_context.dart' show CompilerContext;

import '../messages.dart' show FormattedMessage, LocatedMessage, Message;

import '../ticker.dart' show Ticker;

import '../uri_translator.dart' show UriTranslator;

import '../target_implementation.dart' show TargetImplementation;

import 'dill_library_builder.dart' show DillLibraryBuilder;

import 'dill_loader.dart' show DillLoader;

class DillTarget extends TargetImplementation {
  final Ticker ticker;

  final Map<Uri, DillLibraryBuilder> _knownLibraryBuilders =
      <Uri, DillLibraryBuilder>{};

  bool isLoaded = false;

  late final DillLoader loader;

  final UriTranslator uriTranslator;

  @override
  final Target backendTarget;

  @override
  final CompilerContext context = CompilerContext.current;

  /// Shared with [CompilerContext].
  final Map<Uri, Source> uriToSource = CompilerContext.current.uriToSource;

  DillTarget(this.ticker, this.uriTranslator, this.backendTarget)
      // ignore: unnecessary_null_comparison
      : assert(ticker != null),
        // ignore: unnecessary_null_comparison
        assert(uriTranslator != null),
        // ignore: unnecessary_null_comparison
        assert(backendTarget != null) {
    loader = new DillLoader(this);
  }

  void loadExtraRequiredLibraries(DillLoader loader) {
    for (String uri in backendTarget.extraRequiredLibraries) {
      loader.read(Uri.parse(uri), 0, accessor: loader.coreLibrary);
    }
    if (context.compilingPlatform) {
      for (String uri in backendTarget.extraRequiredLibrariesPlatform) {
        loader.read(Uri.parse(uri), 0, accessor: loader.coreLibrary);
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
        fileUri != null
            ? message.withLocation(fileUri, charOffset, length)
            : message.withoutLocation(),
        severity,
        messageContext,
        involvedFiles: involvedFiles);
  }

  void buildOutlines({bool suppressFinalizationErrors: false}) {
    if (loader.libraries.isNotEmpty) {
      loader.buildOutlines();
      loader.finalizeExports(
          suppressFinalizationErrors: suppressFinalizationErrors);
    }
    isLoaded = true;
  }

  /// Returns the [DillLibraryBuilder] corresponding to [uri].
  ///
  /// The [DillLibraryBuilder] is pulled from [_knownLibraryBuilders].
  DillLibraryBuilder createLibraryBuilder(Uri uri) {
    DillLibraryBuilder libraryBuilder =
        _knownLibraryBuilders.remove(uri) as DillLibraryBuilder;
    // ignore: unnecessary_null_comparison
    assert(libraryBuilder != null, "No library found for $uri.");
    return libraryBuilder;
  }

  void registerLibrary(Library library) {
    _knownLibraryBuilders[library.importUri] =
        new DillLibraryBuilder(library, loader);
  }

  void releaseAncillaryResources() {
    _knownLibraryBuilders.clear();
  }
}
