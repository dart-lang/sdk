// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.diagnostics.source_span;

import 'spannable.dart' show Spannable;

class SourceSpan implements Spannable {
  final Uri uri;
  final int begin;
  final int end;

  const SourceSpan(this.uri, this.begin, this.end);

  @override
  int get hashCode {
    return 13 * uri.hashCode + 17 * begin.hashCode + 19 * end.hashCode;
  }

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! SourceSpan) return false;
    return uri == other.uri && begin == other.begin && end == other.end;
  }

  @override
  String toString() => 'SourceSpan($uri, $begin, $end)';
}
