// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class StringBase {
  // TODO(jmesserly): this array copy is really unfortunate
  // TODO(jmesserly): check the performance of String.fromCharCode.apply
  // TODO(jmesserly): fix the generated JS name of factory ctors,
  // they shouldn't be duplicating the name.
  static String createFromCharCodes(List<int> charCodes) native @'''
if (Object.getPrototypeOf(charCodes) !== Array.prototype) {
  charCodes = new ListFactory.ListFactory$from$factory(charCodes);
}
return String.fromCharCode.apply(null, charCodes);
''' {
   // we may need to iterate over charCodes
    var i = charCodes.iterator();  i.next(); i.hasNext();
    new ListFactory.from(charCodes); // ensure List.from is generated
  }

  static String join(List<String> strings, String separator) {
    if (strings.length == 0) return '';
    String s = strings[0];
    for (int i = 1; i < strings.length; i++) {
      s = s + separator + strings[i];
    }
    return s;
  }

  static String concatAll(List<String> strings) => join(strings, "");
}
