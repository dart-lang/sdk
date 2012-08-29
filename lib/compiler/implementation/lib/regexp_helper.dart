// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

List regExpExec(JSSyntaxRegExp regExp, String str) {
  var nativeRegExp = regExpGetNative(regExp);
  var result = JS('List', @'#.exec(#)', nativeRegExp, str);
  if (JS('bool', @'# === null', result)) return null;
  return result; 
}

bool regExpTest(JSSyntaxRegExp regExp, String str) {
  var nativeRegExp = regExpGetNative(regExp);
  return JS('bool', @'#.test(#)', nativeRegExp, str);
}

regExpGetNative(JSSyntaxRegExp regExp) {
  var r = JS('var', @'#._re', regExp);
  if (r === null) {
    r = JS('var', @'#._re = #', regExp, regExpMakeNative(regExp));
  }
  return r;
}

regExpAttachGlobalNative(JSSyntaxRegExp regExp) {
  JS('var', @'#._re = #', regExp, regExpMakeNative(regExp, global: true));
}

regExpMakeNative(JSSyntaxRegExp regExp, [bool global = false]) {
  String pattern = regExp.pattern;
  bool multiLine = regExp.multiLine;
  bool ignoreCase = regExp.ignoreCase;
  checkString(pattern);
  StringBuffer sb = new StringBuffer();
  if (multiLine) sb.add('m');
  if (ignoreCase) sb.add('i');
  if (global) sb.add('g');
  try {
    return JS('Object', @'new RegExp(#, #)', pattern, sb.toString());
  } catch (e) {
    throw new IllegalJSRegExpException(pattern,
                                       JS('String', @'String(#)', e));
  }
}

int regExpMatchStart(m) => JS('int', @'#.index', m);
