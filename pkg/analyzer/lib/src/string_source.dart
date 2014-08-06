// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.string_source;

import 'generated/source.dart';
import 'generated/engine.dart' show TimestampedData;

/// An implementation of [Source] that's based on an in-memory Dart string.
class StringSource implements Source {
  final String _contents;
  final String fullName;
  final int modificationStamp;

  StringSource(this._contents, this.fullName)
      : modificationStamp = new DateTime.now().millisecondsSinceEpoch;

  bool operator==(Object object) {
    if (object is StringSource) {
      StringSource ssObject = object;
      return ssObject._contents == _contents && ssObject.fullName == fullName;
    }
    return false;
  }

  bool exists() => true;

  TimestampedData<String> get contents => new TimestampedData(modificationStamp, _contents);

  String get encoding => throw new UnsupportedError("StringSource doesn't support "
      "encoding.");

  String get shortName => fullName;

  UriKind get uriKind => throw new UnsupportedError("StringSource doesn't support "
      "uriKind.");

  int get hashCode => _contents.hashCode ^ fullName.hashCode;

  bool get isInSystemLibrary => false;

  @override
  Uri get uri => throw new UnsupportedError(
      "StringSource doesn't support uri.");

  Uri resolveRelativeUri(Uri relativeUri) => throw new UnsupportedError(
      "StringSource doesn't support resolveRelative.");
}
