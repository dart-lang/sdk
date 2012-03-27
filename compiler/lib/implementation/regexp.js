// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

function native_JSSyntaxRegExp_firstMatch(str) {
  var re = $DartRegExpToJSRegExp(this);
  var m = re.exec(str);
  if (m != null) {
    var match = native_JSSyntaxMatch__new(this, str);
    match.match_ = m;
    match.lastIndex_ = re.lastIndex;
    return match;
  }
  return $Dart$Null;
}

function native_JSSyntaxRegExp_hasMatch(str) {
  return $DartRegExpToJSRegExp(this).test(str);
}

function native_JSSyntaxRegExp_stringMatch(str) {
  var m = $DartRegExpToJSRegExp(this).exec(str);
  return (m != null ? m[0] : $Dart$Null);
}

function native_JSSyntaxMatch_group(nb) {
  return this.match_[nb];
}

function native_JSSyntaxMatch_groupCount() {
  return this.match_.length;
}

function native_JSSyntaxMatch_start() {
  return this.match_.index;
}

function native_JSSyntaxMatch_end() {
  return this.lastIndex_;
}

function native__LazyAllMatchesIterator__jsInit(regExp) {
  this.re = $DartRegExpToJSRegExp(regExp);
}

// The given RegExp is only used to initialize a new Match. We use the
// cached JS regexp to compute the next match.
function native__LazyAllMatchesIterator__computeNextMatch(regExp, str) {
  var re = this.re;
  if (re === null) return $Dart$Null;
  var m = re.exec(str);
  if (m == null) {
    this.re = null;
    return $Dart$Null;
  }
  var match = native_JSSyntaxMatch__new(regExp, str);
  match.match_ = m;
  match.lastIndex_ = re.lastIndex;
  return match;
}

function $DartRegExpToJSRegExp(exp) {
  var flags = "g";
  if (native_JSSyntaxRegExp__multiLine(exp)) flags += "m";
  if (native_JSSyntaxRegExp__ignoreCase(exp)) flags += "i";
  return new RegExp(native_JSSyntaxRegExp__pattern(exp), flags);
}
