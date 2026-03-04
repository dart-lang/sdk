// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_utilities/src/api_summary/src/extensions.dart';

/// URI categorization used by [UriSortKey].
enum UriCategory { inPackage, notInPackage }

/// Sort key used to sort libraries in the output.
///
/// Libraries in the specified package will be output first (sorted by URI),
/// followed by libraries not in the package.
class UriSortKey implements Comparable<UriSortKey> {
  final UriCategory _category;
  final String _uriString;

  UriSortKey(Uri uri, String pkgName)
    : _category = uri.isIn(pkgName)
          ? UriCategory.inPackage
          : UriCategory.notInPackage,
      _uriString = uri.toString();

  @override
  int compareTo(UriSortKey other) {
    if (_category.index.compareTo(other._category.index) case var value
        when value != 0) {
      return value;
    }
    return _uriString.compareTo(other._uriString);
  }
}
