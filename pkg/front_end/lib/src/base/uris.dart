// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';

final Uri dartCore = Uri.parse('dart:core');
final Uri missingUri = Uri.parse('org-dartlang-internal:missing');

const String MALFORMED_URI_SCHEME = "org-dartlang-malformed-uri";

bool isNotMalformedUriScheme(Uri uri) => !uri.isScheme(MALFORMED_URI_SCHEME);

/// Translate a parts "partUri" to an actual uri with handling of invalid uris.
///
/// ```
/// DartDocTest(
///   getPartImportUri(
///     Uri.parse("package:foo/bar/parent.dart"),
///     new LibraryPart(
///       [],
///       "simple.dart",
///       Uri.parse("file://foo/lib/bar/simple.dart"),
///     ),
///   ),
///   Uri.parse("package:foo/bar/simple.dart"),
/// )
/// DartDocTest(
///   getPartImportUri(
///     Uri.parse("package:foo/bar/parent.dart"),
///     new LibraryPart(
///       [],
///       "dir/simple.dart",
///       Uri.parse("file://foo/lib/bar/dir/simple.dart"),
///     ),
///   ),
///   Uri.parse("package:foo/bar/dir/simple.dart"),
/// )
/// DartDocTest(
///   getPartImportUri(
///     Uri.parse("package:foo/bar/parent.dart"),
///     new LibraryPart(
///       [],
///       "../simple.dart",
///       Uri.parse("file://foo/lib/simple.dart"),
///     ),
///   ),
///   Uri.parse("package:foo/simple.dart"),
/// )
/// DartDocTest(
///   getPartImportUri(
///     Uri.parse("package:foo/bar/parent.dart"),
///     new LibraryPart(
///       [],
///       "file:///my/path/absolute.dart",
///       Uri.parse("file:///my/path/absolute.dart"),
///     ),
///   ),
///   Uri.parse("file:///my/path/absolute.dart"),
/// )
/// DartDocTest(
///   getPartImportUri(
///     Uri.parse("package:foo/bar/parent.dart"),
///     new LibraryPart(
///       [],
///       "package:foo/hello.dart",
///       Uri.parse("file://foo/lib/hello.dart"),
///     ),
///   ),
///   Uri.parse("package:foo/hello.dart"),
/// )
/// ```
/// And with invalid part uri:
/// ```
/// DartDocTest(
///   getPartImportUri(
///     Uri.parse("package:foo/bar/parent.dart"),
///     new LibraryPart(
///       [],
///       ":hello",
///       new Uri(
///         scheme: MALFORMED_URI_SCHEME,
///         query: Uri.encodeQueryComponent(":hello"),
///       ),
///     ),
///   ),
///   new Uri(
///     scheme: MALFORMED_URI_SCHEME,
///     query: Uri.encodeQueryComponent(":hello"),
///   ),
/// )
/// ```
Uri getPartImportUri(Uri parentImportUri, LibraryPart part) {
  try {
    return parentImportUri.resolve(part.partUri);
  }
  // Coverage-ignore(suite): Not run.
  on FormatException {
    // This is also done in [SourceLibraryBuilder.resolve]
    return new Uri(
      scheme: MALFORMED_URI_SCHEME,
      query: Uri.encodeQueryComponent(part.partUri),
    );
  }
}
