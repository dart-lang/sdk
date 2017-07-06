// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "core.dart";

/// Prints a string representation of the object to the console.
void print(Object object) {
  String line = "$object";
  if (printToZone == null) {
    printToConsole(line);
  } else {
    printToZone(line);
  }
}
