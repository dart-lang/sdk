// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

//String.prototype.get$length = function() {
//  return this.length;
//}

// TODO(jimhug): Unify with code from compiler/lib/implementation.
class StringImplementation implements String native "String" {

  String operator[](int index) native;

  int charCodeAt(int index) native;

  final int length; //native since it's on a native type.

  bool operator ==(var other) native;

  bool endsWith(String other) native '''
  'use strict';
  if (other.length > this.length) return false;
  return other == this.substring(this.length - other.length);''';

  bool startsWith(String other) native '''
  'use strict';
  if (other.length > this.length) return false;
  return other == this.substring(0, other.length);''';

  int indexOf(String other, [int start]) native;
  int lastIndexOf(String other, [int start]) native;

  bool isEmpty() => length == 0;

  String concat(String other) native;

  String operator +(Object obj) native { obj.toString(); }

  String substring(int startIndex, [int endIndex = null]) native;

  String trim() native;

  // TODO(jmesserly): should support pattern too.
  bool contains(Pattern pattern, [int startIndex]) native
    "'use strict'; return this.indexOf(pattern, startIndex) >= 0;";

  String _replaceFirst(String from, String to) native
    "'use strict';return this.replace(from, to);";

  String _replaceRegExp(RegExp from, String to) native
    "'use strict';return this.replace(from.re, to);";

  String replaceFirst(Pattern from, String to) {
    if (from is String) return _replaceFirst(from, to);
    if (from is RegExp) return _replaceRegExp(from, to);
    for (var match in from.allMatches(this)) {
      // We just care about the first match
      return substring(0, match.start()) + to + substring(match.end());
    }
  }

  String _replaceAll(String from, String to) native @"""
'use strict';
from = new RegExp(from.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, "\\$&"), 'g');
to = to.replace(/\$/g, '$$$$'); // Escape sequences are fun!
return this.replace(from, to);""";

  String replaceAll(Pattern from, String to) {
    if (from is String) return _replaceAll(from, to);
    if (from is RegExp) return _replaceRegExp(from.dynamic._global, to);
    var buffer = new StringBuffer();
    var lastMatchEnd = 0;
    for (var match in from.allMatches(this)) {
      buffer.add(substring(lastMatchEnd, match.start()));
      buffer.add(to);
      lastMatchEnd = match.end();
    }
    buffer.add(substring(lastMatchEnd));
  }

  // TODO(jimhug): Get correct reified generic list here.
  List<String> split(Pattern pattern) {
    if (pattern is String) return _split(pattern);
    if (pattern is RegExp) return _splitRegExp(pattern);
    throw "String.split(Pattern) unimplemented.";
  }

  List<String> _split(String pattern) native
    "'use strict'; return this.split(pattern);";

  List<String> _splitRegExp(RegExp pattern) native
    "'use strict'; return this.split(pattern.re);";

  Iterable<Match> allMatches(String str) {
    throw "String.allMatches(String str) unimplemented.";
  }
  /*
  Iterable<Match> allMatches(String str) {
    List<Match> result = [];
    if (this.isEmpty()) return result;
    int length = this.length;

    int ix = 0;
    while (ix < str.length) {
      int foundIx = str.indexOf(this, ix);
      if (foundIx < 0) break;
      // Call "toString" to coerce the "this" back to a primitive string.
      result.add(new _StringMatch(foundIx, str, this.toString()));
      ix = foundIx + length;
    }
    return result;
  }
  */

  List<String> splitChars() => split('');

  List<int> charCodes() {
    int len = length;
    List<int> result = new List<int>(len);
    for (int i = 0; i < len; i++) {
      result[i] = charCodeAt(i);
    }
    return result;
  }

  String toLowerCase() native;
  String toUpperCase() native;

  // TODO(jmesserly): we might want to optimize this further.
  // This is the [Jenkins hash function][1], but with masking to keep the
  // hash in the Smi range. I did some simple microbenchmarks to verify that
  // this performs adequately on the standard words list. Letting it spill over
  // into doubles and truncating at the end was ~2x worse, letting it box was
  // ~70x worse.
  //
  // [1]: http://en.wikipedia.org/wiki/Jenkins_hash_function
  int hashCode() native '''
    'use strict';
    var hash = 0;
    for (var i = 0; i < this.length; i++) {
      hash = 0x1fffffff & (hash + this.charCodeAt(i));
      hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
      hash ^= hash >> 6;
    }

    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    hash ^= hash >> 11;
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));''';

  int compareTo(String other) native
    "'use strict'; return this == other ? 0 : this < other ? -1 : 1;";
}

/*
class _StringMatch implements Match {
  const _StringMatch(int this._start,
                     String this.str,
                     String this.pattern);

  int start() => _start;
  int end() => _start + pattern.length;
  String operator[](int g) => group(g);
  int groupCount() => 0;

  String group(int group) {
    if (group != 0) {
      throw new IndexOutOfRangeException(group);
    }
    return pattern;
  }

  List<String> groups(List<int> groups) {
    List<String> result = new List<String>();
    for (int g in groups) {
      result.add(group(g));
    }
    return result;
  }

  final int _start;
  final String str;
  final String pattern;
}
*/
