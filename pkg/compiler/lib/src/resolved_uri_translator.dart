// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'common.dart';
import 'elements/elements.dart' show LibraryElement;
import 'util/emptyset.dart';

/// API used by the library loader to translate internal SDK URIs into file
/// system readable URIs.
abstract class ResolvedUriTranslator {
  factory ResolvedUriTranslator(
      Map<String, Uri> sdkLibraries,
      DiagnosticReporter reporter,
      Uri platformConfigUri) = _ResolvedUriTranslator;

  /// The set of platform libraries reported as unsupported.
  ///
  /// For instance when importing 'dart:io' without '--categories=Server'.
  Set<Uri> get disallowedLibraryUris;

  /// Whether or not a mockable library has been translated.
  bool get mockableLibraryUsed;

  /// A mapping from dart: library names to their location.
  Map<String, Uri> get sdkLibraries;

  /// Translates the resolved [uri] into a readable URI.
  ///
  /// The [importingLibrary] holds the library importing [uri] or `null` if
  /// [uri] is loaded as the main library. The [importingLibrary] is used to
  /// grant access to internal libraries from platform libraries and patch
  /// libraries.
  ///
  /// If the [uri] is not accessible from [importingLibrary], this method is
  /// responsible for reporting errors.
  ///
  /// See [LibraryLoader] for terminology on URIs.
  Uri translate(LibraryElement importingLibrary, Uri uri, Spannable spannable);
}

/// A translator that forwards all methods to an internal
/// [ResolvedUriTranslator].
///
/// The translator to forward to may be set after the instance is constructed.
/// This is useful for the compiler because some tasks that are instantiated at
/// compiler construction time need a [ResolvedUriTranslator], but the data
/// required to instantiate it cannot be obtained at construction time. So a
/// [ForwardingResolvedUriTranslator] may be passed instead, and the translator
/// to forward to can be set once the required data has been retrieved.
class ForwardingResolvedUriTranslator implements ResolvedUriTranslator {
  ResolvedUriTranslator resolvedUriTranslator;

  /// Returns `true` if [resolvedUriTranslator] is not `null`.
  bool get isSet => resolvedUriTranslator != null;

  /// The opposite of [isSet].
  bool get isNotSet => resolvedUriTranslator == null;

  @override
  Uri translate(LibraryElement importingLibrary, Uri resolvedUri,
          Spannable spannable) =>
      resolvedUriTranslator.translate(importingLibrary, resolvedUri, spannable);

  @override
  Set<Uri> get disallowedLibraryUris =>
      resolvedUriTranslator?.disallowedLibraryUris ??
      const ImmutableEmptySet<Uri>();

  @override
  bool get mockableLibraryUsed => resolvedUriTranslator.mockableLibraryUsed;

  @override
  Map<String, Uri> get sdkLibraries => resolvedUriTranslator.sdkLibraries;
}

class _ResolvedUriTranslator implements ResolvedUriTranslator {
  final Map<String, Uri> _sdkLibraries;
  final DiagnosticReporter _reporter;
  final Uri _platformConfigUri;

  Set<Uri> disallowedLibraryUris = new Set<Uri>();
  bool mockableLibraryUsed = false;

  _ResolvedUriTranslator(
      this._sdkLibraries, this._reporter, this._platformConfigUri);

  Map<String, Uri> get sdkLibraries => _sdkLibraries;

  @override
  Uri translate(LibraryElement importingLibrary, Uri uri, Spannable spannable) {
    if (uri.scheme == 'dart') {
      return translateDartUri(importingLibrary, uri, spannable);
    }
    return uri;
  }

  /// Translates "resolvedUri" with scheme "dart" to a [uri] resolved relative
  /// to `options.platformConfigUri` according to the information in the file at
  /// `options.platformConfigUri`.
  ///
  /// Returns `null` and emits an error if the library could not be found or
  /// imported into [importingLibrary].
  ///
  /// Internal libraries (whose name starts with '_') can be only resolved if
  /// [importingLibrary] is a platform or patch library.
  Uri translateDartUri(
      LibraryElement importingLibrary, Uri resolvedUri, Spannable spannable) {
    Uri location = lookupLibraryUri(resolvedUri.path);

    if (location == null) {
      _reporter.reportErrorMessage(spannable, MessageKind.LIBRARY_NOT_FOUND,
          {'resolvedUri': resolvedUri});
      return null;
    }

    if (resolvedUri.path.startsWith('_')) {
      bool allowInternalLibraryAccess = importingLibrary != null &&
          (importingLibrary.isPlatformLibrary ||
              importingLibrary.isPatch ||
              importingLibrary.canonicalUri.scheme == 'memory' ||
              importingLibrary.canonicalUri.path
                  .contains('tests/compiler/dart2js_native') ||
              importingLibrary.canonicalUri.path
                  .contains('tests/compiler/dart2js_extra'));

      if (!allowInternalLibraryAccess) {
        if (importingLibrary != null) {
          _reporter.reportErrorMessage(
              spannable, MessageKind.INTERNAL_LIBRARY_FROM, {
            'resolvedUri': resolvedUri,
            'importingUri': importingLibrary.canonicalUri
          });
        } else {
          _reporter.reportErrorMessage(spannable, MessageKind.INTERNAL_LIBRARY,
              {'resolvedUri': resolvedUri});
          registerDisallowedLibraryUse(resolvedUri);
        }
        return null;
      }
    }

    if (location.scheme == "unsupported") {
      if (location.path == "") {
        _reporter.reportErrorMessage(spannable,
            MessageKind.LIBRARY_NOT_SUPPORTED, {'resolvedUri': resolvedUri});
        registerDisallowedLibraryUse(resolvedUri);
      } else {
        // If the specification includes a path, we treat it as "partially"
        // unsupported: it is allowed to be imported unconditionally, but we
        // will not expose it as being supported in the const variable
        // `dart.library.name`.
        //
        // This is a stopgap measure to support packages like `http` that need
        // to import `dart:io` conditionally. Once config-imports are supported
        // in the language, we can make it an error again to import it
        // unconditionally.
        //
        // The plaform configuration files contain a URI of the form
        // `unsupported:path/to/library.dart` to indicate this partially
        // supported mode. We resolve the path with respect to the configuration
        // file.
        return _platformConfigUri.resolve(location.path);
      }
      return null;
    }

    if (resolvedUri.path == 'html' || resolvedUri.path == 'io') {
      // TODO(ahe): Get rid of mockableLibraryUsed when test.dart
      // supports this use case better.
      mockableLibraryUsed = true;
    }
    return location;
  }

  void registerDisallowedLibraryUse(Uri uri) {
    disallowedLibraryUris.add(uri);
  }

  Uri lookupLibraryUri(String libraryName) {
    return _sdkLibraries[libraryName];
  }
}
