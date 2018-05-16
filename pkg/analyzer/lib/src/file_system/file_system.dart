// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/file_system/file_system.dart';

/**
 * A [UriResolver] for [Resource]s.
 */
class ResourceUriResolver extends UriResolver {
  /**
   * The name of the `file` scheme.
   */
  static final String FILE_SCHEME = "file";

  final ResourceProvider _provider;

  ResourceUriResolver(this._provider);

  ResourceProvider get provider => _provider;

  @override
  Source resolveAbsolute(Uri uri, [Uri actualUri]) {
    if (!isFileUri(uri)) {
      return null;
    }
    String path = _provider.pathContext.fromUri(uri);
    Resource resource = _provider.getResource(path);
    if (resource is File) {
      return resource.createSource(actualUri ?? uri);
    }
    return null;
  }

  @override
  Uri restoreAbsolute(Source source) =>
      _provider.pathContext.toUri(source.fullName);

  /**
   * Return `true` if the given [uri] is a `file` URI.
   */
  static bool isFileUri(Uri uri) => uri.scheme == FILE_SCHEME;
}
