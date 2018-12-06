// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N control_flow_in_finally`

class Ok {
  double compliantMethod() {
    var i = 5;
    try {
      i = 1 / 0;
    } catch (e) {
      print(e);
    } finally {
      i = i * i; // OK
    }
    return i;
  }
}

class BadReturn {
  double nonCompliantMethod() {
    try {
      return 1 / 0;
    } catch (e) {
      print(e);
    } finally {
      return 1.0; // LINT
    }
  }
}

class GoodReturn {
  double compliantMethod() {
    try {
      return 1 / 0;
    } catch (e) {
      print(e);
    } finally {
      () {
        return 1.0; // OK
      };
    }
  }
}

class BadContinue {
  double nonCompliantMethod() {
    for (var o in [1, 2]) {
      try {
        print(o / 0);
      } catch (e) {
        print(e);
      } finally {
        continue; // LINT
      }
    }
    return 1.0;
  }
}

class GoodContinue {
  double compliantMethod() {
    try {
      print(1 / 0);
    } catch (e) {
      print(e);
    } finally {
      for (var o in [1, 2]) {
        print(o);
        if (1 > 0) {
          continue; // OK
        }
      }
    }
    return 1.0;
  }
}

class BadBreak {
  double nonCompliantMethod() {
    for (var o in [1, 2]) {
      try {
        print(o / 0);
      } catch (e) {
        print(e);
      } finally {
        if (1 > 0) {
          break; // LINT
        } else {
          print('should catch nested cases!');
        }
      }
    }
    return 1.0;
  }
}

class GoodBreak {
  double compliantMethod() {
    try {
      print(1 / 0);
    } catch (e) {
      print(e);
    } finally {
      for (var o in [1, 2]) {
        print(o);
        if (1 > 0) {
          break; // OK
        }
      }
    }
    return 1.0;
  }
}
