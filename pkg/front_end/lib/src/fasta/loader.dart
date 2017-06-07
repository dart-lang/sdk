// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.loader;

import 'dart:async' show Future;

import 'dart:collection' show Queue;

import 'builder/builder.dart' show Builder, LibraryBuilder;

import 'errors.dart' show InputError, firstSourceUri, printUnexpected;

import 'target_implementation.dart' show TargetImplementation;

import 'ticker.dart' show Ticker;

abstract class Loader<L> {
  final Map<Uri, LibraryBuilder> builders = <Uri, LibraryBuilder>{};

  final Queue<LibraryBuilder> unparsedLibraries = new Queue<LibraryBuilder>();

  final List<L> libraries = <L>[];

  final TargetImplementation target;

  final List<InputError> errors = <InputError>[];

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
      const String message = "Can't access platform private library.";
      printUnexpected(accessor.fileUri, charOffset, message);
      errors.add(new InputError(accessor.fileUri, charOffset, message));
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

  List<InputError> collectCompileTimeErrors() {
    List<InputError> errors = <InputError>[]..addAll(this.errors);
    for (LibraryBuilder library in builders.values) {
      if (library.loader == this) {
        errors.addAll(library.compileTimeErrors);
      }
    }
    return errors;
  }

  Builder getAbstractClassInstantiationError() {
    return target.getAbstractClassInstantiationError(this);
  }

  Builder getCompileTimeError() => target.getCompileTimeError(this);

  Builder getDuplicatedFieldInitializerError() {
    return target.getDuplicatedFieldInitializerError(this);
  }

  Builder getFallThroughError() => target.getFallThroughError(this);

  Builder getNativeAnnotation() => target.getNativeAnnotation(this);
}

String format(double d, int fractionDigits, int width) {
  return d.toStringAsFixed(fractionDigits).padLeft(width);
}
