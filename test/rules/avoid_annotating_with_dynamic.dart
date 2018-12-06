// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N avoid_annotating_with_dynamic`

dynamic bad1(defaultValue) { // OK but could change in the future
  return null;
}

bad2(dynamic defaultValue) { // LINT
  return null;
}

bad3([dynamic defaultValue]) { // LINT
  return null;
}

bad4({dynamic defaultValue}) { // LINT
  return null;
}

good(defaultValue) { // OK
  return null;
}

class NonStaticMethods {
  dynamic bad1(defaultValue) { // OK but could change in the future
    return null;
  }

  bad2(dynamic defaultValue) { // LINT
    return null;
  }

  bad3([dynamic defaultValue]) { // LINT
    return null;
  }

  bad4({dynamic defaultValue}) { // LINT
    return null;
  }

  good(defaultValue) { // OK
    return null;
  }
}

class StaticMethods {
  static dynamic bad1(defaultValue) { // OK but could change in the future
    return null;
  }

  static bad2(dynamic defaultValue) { // LINT
    return null;
  }

  static bad3([dynamic defaultValue]) { // LINT
    return null;
  }

  static bad4({dynamic defaultValue}) { // LINT
    return null;
  }

  static good(defaultValue) { // OK
    return null;
  }
}

class Constructors {

  Constructors.bad1(dynamic defaultValue); // LINT

  Constructors.bad2([dynamic defaultValue]); // LINT

  Constructors.bad3({dynamic defaultValue}); // LINT

  Constructors.good(defaultValue); // OK
}
