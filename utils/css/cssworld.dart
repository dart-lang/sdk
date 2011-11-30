// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class CssWorld {
  List<String> classes;
  List<String> ids;

  CssWorld(this.classes, this.ids) {
    // Insure no private class names in our CSS world (._foo).
    for (aClass in classes) {
      if (aClass.startsWith('_')) {
        throw new CssSelectorException(
            "private class ('_' prefix) not valid for CssWorld $aClass)");
      }
    }

    // Insure no private element ids in our CSS world (#_foo).
    for (id in ids) {
      if (id.startsWith('_')) {
        throw new CssSelectorException(
            "private id ('_' prefix) not valid for CssWorld $id)");
      }
    }
  }
}
