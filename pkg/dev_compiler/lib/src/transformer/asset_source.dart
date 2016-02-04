// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart' show Source, UriKind;
import 'package:barback/barback.dart' show Asset, TimestampedData;
import 'package:path/path.dart' as path;

class AssetSource implements Source {
  final Uri uri;
  final Asset asset;
  final String contentString;
  AssetSource(this.uri, this.asset, this.contentString);

  @override toString() => 'AssetSource($uri, ${asset.id})';

  @override
  TimestampedData<String> get contents =>
      new TimestampedData(modificationStamp, contentString);

  @override
  String get encoding => null;

  @override
  bool exists() => true;

  @override
  String get fullName => uri.toString();

  @override
  bool get isInSystemLibrary => uriKind == UriKind.DART_URI;

  @override
  int get modificationStamp => 0;

  @override
  Uri resolveRelativeUri(Uri relativeUri) {
    var resolvedPath = path.join(path.dirname(uri.path), relativeUri.path);
    return new Uri(scheme: uri.scheme, path: resolvedPath);
  }

  @override
  String get shortName => uri.toString();

  @override
  Source get source => this;

  @override
  UriKind get uriKind {
    switch (uri.scheme) {
      case 'package':
        return UriKind.PACKAGE_URI;

      case 'dart':
        return UriKind.DART_URI;

      case 'file':
        return UriKind.FILE_URI;

      default:
        throw new StateError(uri.toString());
    }
  }
}
