// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

exhaustiveBoundedTypeVariableByValue<T extends bool>(T x1, T x2) {
  switch (x1) /* Ok */ {
    case true:
    case false:
      break;
  }
  return switch (x2) /* Ok */ {
    true => 0,
    false => 1,
  };
}

exhaustiveBoundedTypeVariableByType<T extends bool>(T x1, T x2) {
  switch (x1) /* Ok */ {
    case T():
      break;
  }
  return switch (x2) /* Ok */ {
    T() => 0,
  };
}

nonExhaustiveBoundedTypeVariable<T extends bool>(T x1, T x2) {
  switch (x1) /* Error */ {
    case true:
      break;
  }
  return switch (x2) /* Error */ {
    true => 0,
  };
}

exhaustiveBoundedTypeVariableByBound<T extends bool>(T x1, T x2) {
  switch (x1) /* Ok */ {
    case bool():
      break;
  }
  return switch (x2) /* Ok */ {
    bool() => 0,
  };
}

nonExhaustiveBoundedTypeVariableByOtherType<T extends bool, S extends bool>(
    T x1, T x2) {
  switch (x1) /* Error */ {
    case S():
      break;
  }
  return switch (x2) /* Error */ {
    S() => 0,
  };
}

exhaustivePromotedTypeVariableByValue<T>(T x1, T x2) {
  if (x1 is bool) {
    switch (x1) /* Ok */ {
      case true:
      case false:
        break;
    }
  }
  if (x2 is bool) {
    var a = switch (x2) /* Ok */ {
      true => 0,
      false => 1,
    };
  }
}

exhaustivePromotedTypeVariableByType<T>(T x1, T x2) {
  if (x1 is bool) {
    switch (x1) /* Ok */ {
      case T():
        break;
    }
  }
  if (x2 is bool) {
    var a = switch (x2) /* Ok */ {
      T() => 0,
    };
  }
}

nonExhaustivePromotedTypeVariable<T>(T x1, T x2) {
  if (x1 is bool) {
    switch (x1) /* Error */ {
      case true:
        break;
    }
  }
  if (x2 is bool) {
    var a = switch (x2) /* Error */ {
      true => 0,
    };
  }
}

exhaustivePromotedTypeVariableByBound1<T>(T x1, T x2) {
  if (x1 is bool) {
    switch (x1) /* Ok */ {
      case bool():
        break;
    }
  }
  if (x2 is bool) {
    var a = switch (x2) /* Ok */ {
      bool() => 0,
    };
  }
}

nonExhaustivePromotedTypeVariableByOtherType<T, S extends bool>(T x1, T x2) {
  if (x1 is bool) {
    switch (x1) /* Error */ {
      case S():
        break;
    }
  }
  if (x2 is bool) {
    var a = switch (x2) /* Error */ {
      S() => 0,
    };
  }
}
