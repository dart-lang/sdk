// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.uri_translator_impl;

import 'package:front_end/src/base/libraries_specification.dart'
    show TargetLibrariesSpecification;
import 'package:front_end/src/fasta/compiler_context.dart' show CompilerContext;
import 'package:front_end/src/fasta/fasta_codes.dart';
import 'package:front_end/src/fasta/severity.dart' show Severity;
import 'package:front_end/src/fasta/uri_translator.dart';
import 'package:package_config/packages.dart' show Packages;

/// Implementation of [UriTranslator] for absolute `dart` and `package` URIs.
class UriTranslatorImpl implements UriTranslator {
  /// Library information for platform libraries.
  final TargetLibrariesSpecification dartLibraries;

  /// Mapping from package names (e.g. `angular`) to the file URIs.
  final Packages packages;

  UriTranslatorImpl(this.dartLibraries, this.packages);

  @override
  List<Uri> getDartPatches(String libraryName) =>
      dartLibraries.libraryInfoFor(libraryName)?.patches;

  @override
  bool isPlatformImplementation(Uri uri) {
    if (uri.scheme != "dart") return false;
    String path = uri.path;
    return dartLibraries.libraryInfoFor(path) == null || path.startsWith("_");
  }

  @override
  // TODO(sigmund, ahe): consider expanding this API to include an error
  // callback, so we can provide an error location when one is available. For
  // example, if the error occurs in an `import`.
  Uri translate(Uri uri, [bool reportMessage = true]) {
    if (uri.scheme == "dart") return _translateDartUri(uri);
    if (uri.scheme == "package") {
      return _translatePackageUri(uri, reportMessage);
    }
    return null;
  }

  @override
  bool isLibrarySupported(String libraryName) {
    // TODO(sigmund): change this to `?? false` when all backends provide the
    // `libraries.json` file by default (Issue #32657).
    return dartLibraries.libraryInfoFor(libraryName)?.isSupported ?? true;
  }

  /// Return the file URI that corresponds to the given `dart` URI, or `null`
  /// if there is no corresponding Dart library registered.
  Uri _translateDartUri(Uri uri) {
    if (!uri.isScheme('dart')) return null;
    return dartLibraries.libraryInfoFor(uri.path)?.uri;
  }

  /// Return the file URI that corresponds to the given `package` URI, or
  /// `null` if the `package` [uri] format is invalid, or there is no
  /// corresponding package registered.
  Uri _translatePackageUri(Uri uri, bool reportMessage) {
    try {
      // TODO(sigmund): once we remove the `parse` API, we can ensure that
      // packages will never be null and get rid of `?` below.
      return packages?.resolve(uri,
          notFound: reportMessage
              ? _packageUriNotFound
              : _packageUriNotFoundNoReport);
    } on ArgumentError catch (e) {
      // TODO(sigmund): catch a more precise error when
      // https://github.com/dart-lang/package_config/issues/40 is fixed.
      if (reportMessage) {
        CompilerContext.current.reportWithoutLocation(
            templateInvalidPackageUri.withArguments(uri, '$e'), Severity.error);
      }
      return null;
    }
  }

  static Uri _packageUriNotFound(Uri uri) {
    String name = uri.pathSegments.first;
    CompilerContext.current.reportWithoutLocation(
        templatePackageNotFound.withArguments(name, uri), Severity.error);
    // TODO(sigmund, ahe): ensure we only report an error once,
    // this null result will likely cause another error further down in the
    // compiler.
    return null;
  }

  static Uri _packageUriNotFoundNoReport(Uri uri) {
    return null;
  }
}
