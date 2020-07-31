// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

class A {}

class B {}

main() {
  ifThen(null);
  ifThenSequence(null);
  ifThenElse(null);
  ifThenElseSequence(null);
  ifNotReturn(null);
  nestedIf(null);
  nestedIf2(null);
  nestedIfNotReturn(null);
}

ifThen(o) {
  /*{}*/ o;
  if (/*{}*/ o is A) {
    /*{o:[{true:A}|A]}*/ o;
  }
  /*{}*/ o;
}

ifThenSequence(o) {
  /*{}*/ o;
  if (/*{}*/ o is A) {
    /*{o:[{true:A}|A]}*/ o;
  }
  /*{}*/ o;
  if (/*{}*/ o is B) {
    /*{o:[{true:B}|B]}*/ o;
  }
  /*{}*/ o;
}

ifThenElse(o) {
  /*{}*/ o;
  if (/*{}*/ o is A) {
    /*{o:[{true:A}|A]}*/ o;
  } else {
    /*{o:[{false:A}|A]}*/ o;
  }
  /*{}*/ o;
}

ifThenElseSequence(o) {
  /*{}*/ o;
  if (/*{}*/ o is A) {
    /*{o:[{true:A}|A]}*/ o;
  } else {
    /*{o:[{false:A}|A]}*/ o;
  }
  /*{}*/ o;
  if (/*{}*/ o is B) {
    /*{o:[{true:B}|B]}*/ o;
  } else {
    /*{o:[{false:B}|B]}*/ o;
  }
  /*{}*/ o;
}

ifNotReturn(o) {
  /*{}*/ o;
  if (/*{}*/ o is! A) {
    return /*{o:[{false:A}|A]}*/ o;
  }
  /*{o:[{true:A}|A]}*/ o;
}

nestedIf(o) {
  if (/*{}*/ o is A) {
    if (/*{o:[{true:A}|A]}*/ o is B) {
      return /*{o:[{true:A,B}|A,B]}*/ o;
    }
  }
  /*{}*/ o;
}

nestedIf2(o) {
  if (/*{}*/ o is A) {
    if (/*{o:[{true:A}|A]}*/ o is B) {
      return /*{o:[{true:A,B}|A,B]}*/ o;
    }
  } else if (/*{o:[{false:A}|A]}*/ o is B) {
    /*{o:[{true:B,false:A}|A,B]}*/ o;
  }
  /*{}*/ o;
}

nestedIfNotReturn(o) {
  if (/*{}*/ o is A) {
    if (/*{o:[{true:A}|A]}*/ o is! B) {
      return /*{o:[{true:A,false:B}|A,B]}*/ o;
    }
    /*{o:[{true:A,B}|A,B]}*/ o;
  }
  /*{}*/ o;
}
