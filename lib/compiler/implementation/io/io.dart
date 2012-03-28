// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("io");

#import("dart:io");

String join(List<String> strings) => Strings.join(strings, '/');

String getCurrentDirectory() {
  String dir = new File(".").fullPathSync();
  if (dir.endsWith("/")) return dir;
  return "$dir/";
}
