// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.dill_loader;

import 'package:_fe_analyzer_shared/src/messages/severity.dart' show Severity;

import 'package:kernel/ast.dart' show Class, Component, DartType, Library;

import '../builder/class_builder.dart';
import '../builder/library_builder.dart';
import '../builder/type_builder.dart';

import '../crash.dart' show firstSourceUri;

import '../fasta_codes.dart'
    show SummaryTemplate, Template, templateDillOutlineSummary;

import '../kernel/type_builder_computer.dart' show TypeBuilderComputer;

import '../loader.dart';

import '../messages.dart'
    show
        FormattedMessage,
        LocatedMessage,
        Message,
        noLength,
        SummaryTemplate,
        Template,
        messagePlatformPrivateLibraryAccess,
        templateInternalProblemContextSeverity;

import '../problems.dart' show internalProblem, unhandled;

import '../source/source_loader.dart' show SourceLoader;

import '../ticker.dart' show Ticker;

import '../uris.dart';

import 'dill_library_builder.dart' show DillLibraryBuilder;

import 'dill_target.dart' show DillTarget;

import 'dart:collection' show Queue;

class DillLoader extends Loader {
  SourceLoader? currentSourceLoader;

  final Map<Uri, DillLibraryBuilder> _knownLibraryBuilders =
      <Uri, DillLibraryBuilder>{};

  final Map<Uri, DillLibraryBuilder> _builders = <Uri, DillLibraryBuilder>{};

  final Queue<DillLibraryBuilder> _unparsedLibraries =
      new Queue<DillLibraryBuilder>();

  final List<Library> libraries = <Library>[];

  @override
  final DillTarget target;

  /// List of all handled compile-time errors seen so far by libraries loaded
  /// by this loader.
  ///
  /// A handled error is an error that has been added to the generated AST
  /// already, for example, as a throw expression.
  final List<LocatedMessage> handledErrors = <LocatedMessage>[];

  /// List of all unhandled compile-time errors seen so far by libraries loaded
  /// by this loader.
  ///
  /// An unhandled error is an error that hasn't been handled, see
  /// [handledErrors].
  final List<LocatedMessage> unhandledErrors = <LocatedMessage>[];

  final Set<String> seenMessages = new Set<String>();

  LibraryBuilder? _coreLibrary;

  /// The first library loaded by this [DillLoader].
  // TODO(johnniwinther): Do we need this?
  LibraryBuilder? first;

  int byteCount = 0;

  DillLoader(this.target);

  @override
  LibraryBuilder get coreLibrary => _coreLibrary!;

  Ticker get ticker => target.ticker;

  void registerKnownLibrary(Library library) {
    _knownLibraryBuilders[library.importUri] =
        new DillLibraryBuilder(library, this);
  }

  // TODO(johnniwinther): This is never called!?!
  void releaseAncillaryResources() {
    _knownLibraryBuilders.clear();
  }

  /// Look up a library builder by the [uri], or if such doesn't exist, create
  /// one. The canonical URI of the library is [uri], and its actual location is
  /// [fileUri].
  ///
  /// Canonical URIs have schemes like "dart", or "package", and the actual
  /// location is often a file URI.
  ///
  /// The [accessor] is the library that's trying to import, export, or include
  /// as part [uri], and [charOffset] is the location of the corresponding
  /// directive. If [accessor] isn't allowed to access [uri], it's a
  /// compile-time error.
  DillLibraryBuilder read(Uri uri, int charOffset, {LibraryBuilder? accessor}) {
    DillLibraryBuilder? libraryBuilder = _builders[uri];
    if (libraryBuilder == null) {
      libraryBuilder = _knownLibraryBuilders.remove(uri);
      // ignore: unnecessary_null_comparison
      assert(libraryBuilder != null, "No library found for $uri.");
      _builders[uri] = libraryBuilder!;
      assert(libraryBuilder.loader == this);
      if (uri.isScheme("dart")) {
        if (uri.path == "core") {
          _coreLibrary = libraryBuilder;
        }
      }
      {
        // Add any additional logic after this block. Setting the
        // firstSourceUri and first library should be done as early as
        // possible.
        firstSourceUri ??= uri;
        first ??= libraryBuilder;
      }
      if (_coreLibrary == libraryBuilder) {
        target.loadExtraRequiredLibraries(this);
      }
      if (target.backendTarget.mayDefineRestrictedType(uri)) {
        libraryBuilder.mayImplementRestrictedTypes = true;
      }
      _unparsedLibraries.addLast(libraryBuilder);
    }
    if (accessor != null) {
      libraryBuilder.recordAccess(
          accessor, charOffset, noLength, accessor.fileUri);
      if (!accessor.isPatch &&
          !accessor.isPart &&
          !target.backendTarget
              .allowPlatformPrivateLibraryAccess(accessor.importUri, uri)) {
        accessor.addProblem(messagePlatformPrivateLibraryAccess, charOffset,
            noLength, accessor.fileUri);
      }
    }
    return libraryBuilder;
  }

  void _ensureCoreLibrary() {
    if (_coreLibrary == null) {
      read(Uri.parse("dart:core"), 0, accessor: first);
      // TODO(askesc): When all backends support set literals, we no longer
      // need to index dart:collection, as it is only needed for desugaring of
      // const sets. We can remove it from this list at that time.
      read(Uri.parse("dart:collection"), 0, accessor: first);
      assert(_coreLibrary != null);
    }
  }

  void buildOutlines() {
    _ensureCoreLibrary();
    while (_unparsedLibraries.isNotEmpty) {
      DillLibraryBuilder library = _unparsedLibraries.removeFirst();
      buildOutline(library);
    }
    _logSummary(outlineSummaryTemplate);
  }

  void _logSummary(Template<SummaryTemplate> template) {
    ticker.log((Duration elapsed, Duration sinceStart) {
      int libraryCount = 0;
      for (DillLibraryBuilder library in libraryBuilders) {
        assert(library.loader == this);
        libraryCount++;
      }
      double ms = elapsed.inMicroseconds / Duration.microsecondsPerMillisecond;
      Message message = template.withArguments(
          libraryCount, byteCount, ms, byteCount / ms, ms / libraryCount);
      print("$sinceStart: ${message.problemMessage}");
    });
  }

  /// Register [message] as a problem with a severity determined by the
  /// intrinsic severity of the message.
  // TODO(johnniwinther): Avoid the need for this. If this is ever used, it is
  // inconsistent with messages reported through the [SourceLoader] since they
  // each have their own list of unhandled/unhandled errors and seen messages,
  // and only those of the [SourceLoader] are used elsewhere. Use
  // [currentSourceLoader] to forward messages to the [SourceLoader] instead.
  @override
  FormattedMessage? addProblem(
      Message message, int charOffset, int length, Uri? fileUri,
      {bool wasHandled = false,
      List<LocatedMessage>? context,
      Severity? severity,
      bool problemOnLibrary = false,
      List<Uri>? involvedFiles}) {
    return _addMessage(message, charOffset, length, fileUri, severity,
        wasHandled: wasHandled,
        context: context,
        problemOnLibrary: problemOnLibrary,
        involvedFiles: involvedFiles);
  }

  /// All messages reported by the compiler (errors, warnings, etc.) are routed
  /// through this method.
  ///
  /// Returns a FormattedMessage if the message is new, that is, not previously
  /// reported. This is important as some parser errors may be reported up to
  /// three times by `OutlineBuilder`, `DietListener`, and `BodyBuilder`.
  /// If the message is not new, [null] is reported.
  ///
  /// If [severity] is `Severity.error`, the message is added to
  /// [handledErrors] if [wasHandled] is true or to [unhandledErrors] if
  /// [wasHandled] is false.
  FormattedMessage? _addMessage(Message message, int charOffset, int length,
      Uri? fileUri, Severity? severity,
      {bool wasHandled = false,
      List<LocatedMessage>? context,
      bool problemOnLibrary = false,
      List<Uri>? involvedFiles}) {
    assert(
        fileUri != missingUri, "Message unexpectedly reported on missing uri.");
    severity ??= message.code.severity;
    if (severity == Severity.ignored) return null;
    String trace = """
message: ${message.problemMessage}
charOffset: $charOffset
fileUri: $fileUri
severity: $severity
""";
    if (!seenMessages.add(trace)) return null;
    if (message.code.severity == Severity.context) {
      internalProblem(
          templateInternalProblemContextSeverity
              .withArguments(message.code.name),
          charOffset,
          fileUri);
    }
    target.context.report(
        fileUri != null
            ? message.withLocation(fileUri, charOffset, length)
            : message.withoutLocation(),
        severity,
        context: context,
        involvedFiles: involvedFiles);
    if (severity == Severity.error) {
      (wasHandled ? handledErrors : unhandledErrors).add(fileUri != null
          ? message.withLocation(fileUri, charOffset, length)
          : message.withoutLocation());
    }
    FormattedMessage formattedMessage = target.createFormattedMessage(
        message, charOffset, length, fileUri, context, severity,
        involvedFiles: involvedFiles);
    return formattedMessage;
  }

  Template<SummaryTemplate> get outlineSummaryTemplate =>
      templateDillOutlineSummary;

  /// Append compiled libraries from the given [component]. If the [filter] is
  /// provided, append only libraries whose [Uri] is accepted by the [filter].
  List<DillLibraryBuilder> appendLibraries(Component component,
      {bool Function(Uri uri)? filter, int byteCount = 0}) {
    List<Library> componentLibraries = component.libraries;
    List<Uri> requestedLibraries = <Uri>[];
    for (int i = 0; i < componentLibraries.length; i++) {
      Library library = componentLibraries[i];
      Uri uri = library.importUri;
      if (filter == null || filter(library.importUri)) {
        libraries.add(library);
        registerKnownLibrary(library);
        requestedLibraries.add(uri);
      }
    }
    List<DillLibraryBuilder> result = <DillLibraryBuilder>[];
    for (int i = 0; i < requestedLibraries.length; i++) {
      result.add(read(requestedLibraries[i], -1));
    }
    target.uriToSource.addAll(component.uriToSource);
    this.byteCount += byteCount;
    return result;
  }

  /// Append single compiled library.
  ///
  /// Note that as this only takes a library, no new sources is added to the
  /// uriToSource map.
  DillLibraryBuilder appendLibrary(Library library) {
    // Add to list of libraries in the loader, used for e.g. linking.
    libraries.add(library);

    // Weird interaction begins.
    //
    // Create dill library builder (adds it to a map where it's fetched
    // again momentarily).
    registerKnownLibrary(library);
    // Set up the dill library builder (fetch it from the map again, add it to
    // another map and setup some auxiliary things).
    return read(library.importUri, -1);
  }

  void buildOutline(DillLibraryBuilder builder) {
    // ignore: unnecessary_null_comparison
    if (builder.library == null) {
      unhandled("null", "builder.library", 0, builder.fileUri);
    }
    builder.markAsReadyToBuild();
  }

  void finalizeExports({bool suppressFinalizationErrors = false}) {
    for (DillLibraryBuilder builder in libraryBuilders) {
      builder.markAsReadyToFinalizeExports(
          suppressFinalizationErrors: suppressFinalizationErrors);
    }
  }

  @override
  ClassBuilder computeClassBuilderFromTargetClass(Class cls) {
    Library kernelLibrary = cls.enclosingLibrary;
    LibraryBuilder? library = lookupLibraryBuilder(kernelLibrary.importUri);
    if (library == null) {
      library =
          currentSourceLoader?.lookupLibraryBuilder(kernelLibrary.importUri);
    }
    return library!.lookupLocalMember(cls.name, required: true) as ClassBuilder;
  }

  late TypeBuilderComputer _typeBuilderComputer = new TypeBuilderComputer(this);

  @override
  TypeBuilder computeTypeBuilder(DartType type) {
    return type.accept(_typeBuilderComputer);
  }

  bool containsLibraryBuilder(Uri importUri) =>
      _builders.containsKey(importUri);

  @override
  DillLibraryBuilder? lookupLibraryBuilder(Uri importUri) =>
      _builders[importUri];

  Iterable<DillLibraryBuilder> get libraryBuilders => _builders.values;

  Iterable<Uri> get libraryImportUris => _builders.keys;

  void registerLibraryBuilder(DillLibraryBuilder libraryBuilder) {
    Uri importUri = libraryBuilder.importUri;
    libraryBuilder.loader = this;
    if (importUri.isScheme("dart") && importUri.path == "core") {
      _coreLibrary = libraryBuilder;
    }
    _builders[importUri] = libraryBuilder;
  }

  DillLibraryBuilder? deregisterLibraryBuilder(Uri importUri) {
    return _builders.remove(importUri);
  }
}
