// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.string_source;

import 'package:analyzer/src/generated/engine.dart' show TimestampedData;
import 'package:analyzer/src/generated/source.dart';

/**
 * An implementation of [Source] that's based on an in-memory Dart string.
 */
class StringSource extends Source {
  /**
   * The content of the source.
   */
  final String _contents;

  @override
  final String fullName;

  @override
  final Uri uri;

  @override
  final int modificationStamp;

  StringSource(this._contents, String fullName)
      : this.fullName = fullName,
        uri = fullName == null ? null : new Uri.file(fullName),
        modificationStamp = new DateTime.now().millisecondsSinceEpoch;

  @override
  TimestampedData<String> get contents =>
      new TimestampedData(modificationStamp, _contents);

  @override
  String get encoding => uri.toString();

  @override
  int get hashCode => _contents.hashCode ^ fullName.hashCode;

  @override
  bool get isInSystemLibrary => false;

  @override
  String get shortName => fullName;

  @override
  UriKind get uriKind => UriKind.FILE_URI;

  /**
   * Return `true` if the given [object] is a string source that is equal to
   * this source.
   */
  @override
  bool operator ==(Object object) {
    return object is StringSource &&
        object._contents == _contents &&
        object.fullName == fullName;
  }

  @override
  bool exists() => true;

  @override
  String toString() => 'StringSource ($fullName)';
}
