// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.loader;

import 'dart:async' show Future;

import 'dart:collection' show Queue;

import 'builder/builder.dart' show Builder, LibraryBuilder;

import 'deprecated_problems.dart'
    show firstSourceUri, deprecated_printUnexpected;

import 'messages.dart' show LocatedMessage, Message, templateUnspecified;

import 'target_implementation.dart' show TargetImplementation;

import 'ticker.dart' show Ticker;

abstract class Loader<L> {
  final Map<Uri, LibraryBuilder> builders = <Uri, LibraryBuilder>{};

  final Queue<LibraryBuilder> unparsedLibraries = new Queue<LibraryBuilder>();

  final List<L> libraries = <L>[];

  final TargetImplementation target;

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

  LibraryBuilder coreLibrary;

  LibraryBuilder first;

  int byteCount = 0;

  Uri currentUriForCrashReporting;

  Loader(this.target);

  Ticker get ticker => target.ticker;

  /// Look up a library builder by the name [uri], or if such doesn't
  /// exist, create one. The canonical URI of the library is [uri], and its
  /// actual location is [fileUri].
  ///
  /// Canonical URIs have schemes like "dart", or "package", and the actual
  /// location is often a file URI.
  ///
  /// The [accessor] is the library that's trying to import, export, or include
  /// as part [uri], and [charOffset] is the location of the corresponding
  /// directive. If [accessor] isn't allowed to access [uri], it's a
  /// compile-time error.
  LibraryBuilder read(Uri uri, int charOffset,
      {Uri fileUri, LibraryBuilder accessor, bool isPatch: false}) {
    firstSourceUri ??= uri;
    LibraryBuilder builder = builders.putIfAbsent(uri, () {
      if (fileUri == null) {
        switch (uri.scheme) {
          case "package":
          case "dart":
            fileUri = target.translateUri(uri);
            break;

          default:
            fileUri = uri;
            break;
        }
      }
      LibraryBuilder library =
          target.createLibraryBuilder(uri, fileUri, isPatch);
      if (uri.scheme == "dart" && uri.path == "core") {
        coreLibrary = library;
        target.loadExtraRequiredLibraries(this);
      }
      if (target.backendTarget.mayDefineRestrictedType(uri)) {
        library.mayImplementRestrictedTypes = true;
      }
      if (uri.scheme == "dart") {
        target.readPatchFiles(library);
      }
      first ??= library;
      if (library.loader == this) {
        unparsedLibraries.addLast(library);
      }
      return library;
    });
    if (accessor != null &&
        uri.scheme == "dart" &&
        uri.path.startsWith("_") &&
        accessor.uri.scheme != "dart") {
      accessor.deprecated_addCompileTimeError(
          charOffset, "Can't access platform private library.");
    }
    return builder;
  }

  void ensureCoreLibrary() {
    if (coreLibrary == null) {
      read(Uri.parse("dart:core"), -1);
      assert(coreLibrary != null);
    }
  }

  Future<Null> buildBodies() async {
    assert(coreLibrary != null);
    for (LibraryBuilder library in builders.values) {
      currentUriForCrashReporting = library.uri;
      await buildBody(library);
    }
    currentUriForCrashReporting = null;
    ticker.log((Duration elapsed, Duration sinceStart) {
      int libraryCount = builders.length;
      double ms =
          elapsed.inMicroseconds / Duration.MICROSECONDS_PER_MILLISECOND;
      String message = "Built $libraryCount compilation units";
      print("""
$sinceStart: $message ($byteCount bytes) in ${format(ms, 3, 0)}ms, that is,
${format(byteCount / ms, 3, 12)} bytes/ms, and
${format(ms / libraryCount, 3, 12)} ms/compilation unit.""");
    });
  }

  Future<Null> buildOutlines() async {
    ensureCoreLibrary();
    while (unparsedLibraries.isNotEmpty) {
      LibraryBuilder library = unparsedLibraries.removeFirst();
      currentUriForCrashReporting = library.uri;
      await buildOutline(library);
    }
    currentUriForCrashReporting = null;
    ticker.log((Duration elapsed, Duration sinceStart) {
      int libraryCount = builders.length;
      double ms =
          elapsed.inMicroseconds / Duration.MICROSECONDS_PER_MILLISECOND;
      String message = "Built outlines for $libraryCount compilation units";
      // TODO(ahe): Share this message with [buildBodies]. Also make it easy to
      // tell the difference between outlines read from a dill file or source
      // files. Currently, [libraryCount] is wrong for dill files.
      print("""
$sinceStart: $message ($byteCount bytes) in ${format(ms, 3, 0)}ms, that is,
${format(byteCount / ms, 3, 12)} bytes/ms, and
${format(ms / libraryCount, 3, 12)} ms/compilation unit.""");
    });
  }

  Future<Null> buildOutline(covariant LibraryBuilder library);

  /// Builds all the method bodies found in the given [library].
  Future<Null> buildBody(covariant LibraryBuilder library);

  /// Register [message] as a compile-time error.
  ///
  /// If [silent] is true, no error is printed as it is assumed the error has
  /// been previously reported.
  ///
  /// If [wasHandled] is true, this error is added to [handledErrors],
  /// otherwise it is added to [unhandledErrors].
  void addCompileTimeError(Message message, int charOffset, Uri fileUri,
      {bool silent: false, bool wasHandled: false}) {
    if (!silent) {
      deprecated_printUnexpected(fileUri, charOffset, message.message);
    }
    (wasHandled ? handledErrors : unhandledErrors)
        .add(message.withLocation(fileUri, charOffset));
  }

  void deprecated_addCompileTimeError(
      Uri fileUri, int charOffset, String message,
      {bool silent: false, bool wasHandled: false}) {
    if (!silent) {
      deprecated_printUnexpected(fileUri, charOffset, message);
    }
    (wasHandled ? handledErrors : unhandledErrors).add(templateUnspecified
        .withArguments(message)
        .withLocation(fileUri, charOffset));
  }

  Builder getAbstractClassInstantiationError() {
    return target.getAbstractClassInstantiationError(this);
  }

  Builder getCompileTimeError() => target.getCompileTimeError(this);

  Builder getDuplicatedFieldInitializerError() {
    return target.getDuplicatedFieldInitializerError(this);
  }

  Builder getNativeAnnotation() => target.getNativeAnnotation(this);
}

String format(double d, int fractionDigits, int width) {
  return d.toStringAsFixed(fractionDigits).padLeft(width);
}
