// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/util/libraries_specification.dart'
    show TargetLibrariesSpecification;
import 'package:package_config/package_config.dart';

import '../codes/cfe_codes.dart';
import 'processed_options.dart';

class UriTranslator {
  final ProcessedOptions options;
  final TargetLibrariesSpecification dartLibraries;

  final PackageConfig packages;

  UriTranslator(this.options, this.dartLibraries, this.packages);

  List<Uri>? getDartPatches(String libraryName) =>
      dartLibraries.libraryInfoFor(libraryName)?.patches;

  // Coverage-ignore(suite): Not run.
  bool isPlatformImplementation(Uri uri) {
    if (!uri.isScheme("dart")) return false;
    String path = uri.path;
    return dartLibraries.libraryInfoFor(path) == null || path.startsWith("_");
  }

  // TODO(sigmund, ahe): consider expanding this API to include an error
  // callback, so we can provide an error location when one is available. For
  // example, if the error occurs in an `import`.
  Uri? translate(Uri uri, [bool reportMessage = true]) {
    if (uri.isScheme("dart")) return _translateDartUri(uri);
    if (uri.isScheme("package")) {
      return _translatePackageUri(uri, reportMessage);
    }
    return null;
  }

  /// For a package uri, get the corresponding [Package].
  Package? getPackage(Uri uri) {
    if (!uri.isScheme("package")) return null;
    int firstSlash = uri.path.indexOf('/');
    if (firstSlash == -1) return null;
    String packageName = uri.path.substring(0, firstSlash);
    return packages[packageName];
  }

  bool isLibrarySupported(String libraryName) {
    return dartLibraries.libraryInfoFor(libraryName)?.isSupported ?? false;
  }

  Uri? _translateDartUri(Uri uri) {
    if (!uri.isScheme('dart')) return null;
    return dartLibraries.libraryInfoFor(uri.path)?.uri;
  }

  Uri? _translatePackageUri(Uri uri, bool reportMessage) {
    try {
      // TODO(sigmund): once we remove the `parse` API, we can ensure that
      // packages will never be null and get rid of `?` below.
      Uri? translated = packages.resolve(uri);
      if (translated == null) {
        return (reportMessage
            ? _packageUriNotFound
            : _packageUriNotFoundNoReport)(uri);
      }
      return translated;
    } on ArgumentError catch (e) {
      // TODO(sigmund): catch a more precise error when
      // https://github.com/dart-lang/package_config/issues/40 is fixed.
      if (reportMessage) {
        options.reportWithoutLocation(
            templateInvalidPackageUri.withArguments(uri, "${e.message}"),
            Severity.error);
      }
      return null;
    }
  }

  Uri? _packageUriNotFound(Uri uri) {
    String name = uri.pathSegments.first;
    options.reportWithoutLocation(
        templatePackageNotFound.withArguments(name, uri), Severity.error);
    // TODO(sigmund, ahe): ensure we only report an error once,
    // this null result will likely cause another error further down in the
    // compiler.
    return null;
  }

  // Coverage-ignore(suite): Not run.
  static Uri? _packageUriNotFoundNoReport(Uri uri) {
    return null;
  }
}
