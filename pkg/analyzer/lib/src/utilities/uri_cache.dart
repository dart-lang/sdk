// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/util/resolve_relative_uri.dart';

/// The instance of [UriCache] that should be used in the analyzer.
final UriCache uriCache = UriCache();

/// The object that provides the [Uri] instance for each unique string,
/// representing either relative or absolute URI.
///
/// In a package it is usual to have multiple libraries, which import same
/// other libraries. This means that when we process import directives,
/// we get the same URIs. We don't want to create new instances of [Uri] for
/// each such URI string. So, each method of this class returns either the
/// already cached instance of [Uri], or creates a new instance, puts it into
/// the cache, and returns.
///
/// When a [Uri] instance is not used anymore, it will be garbage collected,
/// because the cache uses [WeakReference]s.
class UriCache {
  final Map<String, WeakReference<Uri>> _map = {};

  late final Finalizer<String> _finalizer = Finalizer((key) {
    var weakReference = _map[key];
    if (weakReference != null && weakReference.target == null) {
      _map.remove(key);
    }
  });

  /// Returns the [Uri] for [uriStr].
  Uri parse(String uriStr) {
    return _parse(uriStr);
  }

  /// Resolves [contained] against [base].
  Uri resolveRelative(Uri base, Uri contained) {
    if (contained.isAbsolute) {
      return contained;
    }
    var result = resolveRelativeUri(base, contained);
    return _unique(result);
  }

  /// Returns the [Uri] for [uriStr], or `null` if it cannot be parsed.
  Uri? tryParse(String uriStr) {
    var result = _map[uriStr]?.target;
    if (result == null) {
      result = Uri.tryParse(uriStr);
      if (result != null) {
        _put(uriStr, result);
      }
    }
    return result;
  }

  /// Returns the [Uri] for [uriStr], or given [uri] if provided.
  Uri _parse(String uriStr, {Uri? uri}) {
    var result = _map[uriStr]?.target;
    if (result == null) {
      result = uri ?? Uri.parse(uriStr);
      _put(uriStr, result);
    }
    return result;
  }

  void _put(String uriStr, Uri uri) {
    _map[uriStr] = WeakReference(uri);
    _finalizer.attach(uri, uriStr);
  }

  /// Returns the shared [Uri] for the given [uri].
  Uri _unique(Uri uri) {
    var uriStr = uri.toString();
    return _parse(uriStr, uri: uri);
  }
}
