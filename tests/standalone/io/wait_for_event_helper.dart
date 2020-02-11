// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:mirrors';
import 'dart:cli';

late void Function({Duration timeout}) waitForEvent;

void initWaitForEvent() {
  LibraryMirror lib = currentMirrorSystem().findLibrary(#dart.cli);
  for (Symbol s in lib.declarations.keys) {
    if (s.toString().contains("_WaitForUtils")) {
      DeclarationMirror d = lib.declarations[s]!;
      ClassMirror utils = (d as ClassMirror);
      for (Symbol m in utils.staticMembers.keys) {
        if (m.toString().contains("waitForEvent")) {
          waitForEvent = utils.getField(m).reflectee;
        }
      }
    }
  }
}
