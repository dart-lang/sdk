// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

main() {
  ifNull(null);
  ifNullElse(null);
  ifNotNull(null);
  ifNotNullElse(null);
}

ifNull(o) {
  /*{}*/ o;
  if (/*{}*/ o == null) {
    /*{o:[{false:dynamic}|dynamic]}*/ o;
  }
  /*{}*/ o;
}

ifNullElse(o) {
  /*{}*/ o;
  if (/*{}*/ o == null) {
    /*{o:[{false:dynamic}|dynamic]}*/ o;
  } else {
    /*{o:[{true:dynamic}|dynamic]}*/ o;
  }
  /*{}*/ o;
}

ifNotNull(o) {
  /*{}*/ o;
  if (/*{}*/ o != null) {
    /*{o:[{true:dynamic}|dynamic]}*/ o;
  }
  /*{}*/ o;
}

ifNotNullElse(o) {
  /*{}*/ o;
  if (/*{}*/ o != null) {
    /*{o:[{true:dynamic}|dynamic]}*/ o;
  } else {
    /*{o:[{false:dynamic}|dynamic]}*/ o;
  }
  /*{}*/ o;
}
