// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.string_source;

import 'package:analyzer/src/generated/engine.dart' show TimestampedData;
import 'package:analyzer/src/generated/source.dart';

/// An implementation of [Source] that's based on an in-memory Dart string.
class StringSource extends Source {
  final String _contents;
  final String fullName;
  final int modificationStamp;

  StringSource(this._contents, this.fullName)
      : modificationStamp = new DateTime.now().millisecondsSinceEpoch;

  TimestampedData<String> get contents =>
      new TimestampedData(modificationStamp, _contents);

  String get encoding =>
      throw new UnsupportedError("StringSource doesn't support " "encoding.");

  int get hashCode => _contents.hashCode ^ fullName.hashCode;

  bool get isInSystemLibrary => false;

  String get shortName => fullName;

  @override
  Uri get uri =>
      throw new UnsupportedError("StringSource doesn't support uri.");

  UriKind get uriKind =>
      throw new UnsupportedError("StringSource doesn't support " "uriKind.");

  bool operator ==(Object object) {
    if (object is StringSource) {
      StringSource ssObject = object;
      return ssObject._contents == _contents && ssObject.fullName == fullName;
    }
    return false;
  }

  bool exists() => true;

  Uri resolveRelativeUri(Uri relativeUri) => throw new UnsupportedError(
      "StringSource doesn't support resolveRelative.");
}
