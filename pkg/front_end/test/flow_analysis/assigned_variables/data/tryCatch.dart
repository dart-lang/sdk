// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: tryCatch:declared={a, b, d}, assigned={a, b}*/
tryCatch(int a, int b) {
  try /*declared={c}, assigned={a}*/ {
    a = 0;
    var c;
  } on String {
    b = 0;
    var d;
  }
}

/*member: catchClause:declared={e}*/
catchClause() {
  try {} catch (e) {}
}

/*member: onCatch:declared={e}*/
onCatch() {
  try {} on String catch (e) {}
}

/*member: catchStackTrace:declared={e, st}*/
catchStackTrace() {
  try {} catch (e, st) {}
}

/*member: onCatchStackTrace:declared={e, st}*/
onCatchStackTrace() {
  try {} on String catch (e, st) {}
}
