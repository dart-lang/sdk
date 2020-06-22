// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

cneg_and(x, y) {
  if ((x && y) ? false : true) {
    return 0;
  } else {
    return 1;
  }
}

cneg_and_not(x, y) {
  if ((x && (y ? false : true)) ? false : true) {
    return 0;
  } else {
    return 1;
  }
}

cneg_not_and(x, y) {
  if (((x ? false : true) && y) ? false : true) {
    return 0;
  } else {
    return 1;
  }
}

cneg_not_and_not(x, y) {
  if (((x ? false : true) && (y ? false : true)) ? false : true) {
    return 0;
  } else {
    return 1;
  }
}

cneg_or(x, y) {
  if ((x || y) ? false : true) {
    return 0;
  } else {
    return 1;
  }
}

cneg_or_not(x, y) {
  if ((x || (y ? false : true)) ? false : true) {
    return 0;
  } else {
    return 1;
  }
}

cneg_not_or(x, y) {
  if (((x ? false : true) || y) ? false : true) {
    return 0;
  } else {
    return 1;
  }
}

cneg_not_or_not(x, y) {
  if (((x ? false : true) || (y ? false : true)) ? false : true) {
    return 0;
  } else {
    return 1;
  }
}

value_tobool(x) {
  return x ? true : false;
}

value_negate(x) {
  return x ? false : true;
}

value_and(x, y) {
  return x ? y ? true : false : false;
}

value_or(x, y) {
  return x ? true : y ? true : false;
}

value_and_not(x, y) {
  return x ? y ? false : true : false;
}

value_not_and(x, y) {
  return x ? false : y ? true : false;
}

value_not_and_not(x, y) {
  return x ? false : y ? false : true;
}

value_or_not(x, y) {
  return x ? true : y ? false : true;
}

value_not_or(x, y) {
  return x ? y ? true : false : true;
}

value_not_or_not(x, y) {
  return x ? y ? false : true : true;
}

if_negate(x) {
  if (x ? false : true) {
    return 1;
  } else {
    return 0;
  }
}

if_and(x, y) {
  if (x ? y ? true : false : false) {
    return 1;
  } else {
    return 0;
  }
}

if_or(x, y) {
  if (x ? true : y) {
    return 1;
  } else {
    return 0;
  }
}

if_and_not(x, y) {
  if (x ? y ? false : true : false) {
    return 1;
  } else {
    return 0;
  }
}

if_not_and(x, y) {
  if (x ? false : y) {
    return 1;
  } else {
    return 0;
  }
}

if_not_and_not(x, y) {
  if (x ? false : y ? false : true) {
    return 1;
  } else {
    return 0;
  }
}

if_or_not(x, y) {
  if (x ? true : y ? false : true) {
    return 1;
  } else {
    return 0;
  }
}

if_not_or(x, y) {
  if (x ? y : true) {
    return 1;
  } else {
    return 0;
  }
}

if_not_or_not(x, y) {
  if (x ? y ? false : true : true) {
    return 1;
  } else {
    return 0;
  }
}

main() {
  Expect.equals(1, cneg_and(true, true));
  Expect.equals(0, cneg_and(true, false));
  Expect.equals(0, cneg_and(false, true));
  Expect.equals(0, cneg_and(false, false));

  Expect.equals(0, cneg_and_not(true, true));
  Expect.equals(1, cneg_and_not(true, false));
  Expect.equals(0, cneg_and_not(false, true));
  Expect.equals(0, cneg_and_not(false, false));

  Expect.equals(0, cneg_not_and(true, true));
  Expect.equals(0, cneg_not_and(true, false));
  Expect.equals(1, cneg_not_and(false, true));
  Expect.equals(0, cneg_not_and(false, false));

  Expect.equals(0, cneg_not_and_not(true, true));
  Expect.equals(0, cneg_not_and_not(true, false));
  Expect.equals(0, cneg_not_and_not(false, true));
  Expect.equals(1, cneg_not_and_not(false, false));

  Expect.equals(1, cneg_or(true, true));
  Expect.equals(1, cneg_or(true, false));
  Expect.equals(1, cneg_or(false, true));
  Expect.equals(0, cneg_or(false, false));

  Expect.equals(1, cneg_or_not(true, true));
  Expect.equals(1, cneg_or_not(true, false));
  Expect.equals(0, cneg_or_not(false, true));
  Expect.equals(1, cneg_or_not(false, false));

  Expect.equals(1, cneg_not_or(true, true));
  Expect.equals(0, cneg_not_or(true, false));
  Expect.equals(1, cneg_not_or(false, true));
  Expect.equals(1, cneg_not_or(false, false));

  Expect.equals(0, cneg_not_or_not(true, true));
  Expect.equals(1, cneg_not_or_not(true, false));
  Expect.equals(1, cneg_not_or_not(false, true));
  Expect.equals(1, cneg_not_or_not(false, false));

  Expect.equals(true, value_tobool(true));
  Expect.equals(false, value_tobool(false));

  Expect.equals(false, value_negate(true));
  Expect.equals(true, value_negate(false));

  Expect.equals(true, value_and(true, true));
  Expect.equals(false, value_and(true, false));
  Expect.equals(false, value_and(false, true));
  Expect.equals(false, value_and(false, false));

  Expect.equals(false, value_and_not(true, true));
  Expect.equals(true, value_and_not(true, false));
  Expect.equals(false, value_and_not(false, true));
  Expect.equals(false, value_and_not(false, false));

  Expect.equals(false, value_not_and(true, true));
  Expect.equals(false, value_not_and(true, false));
  Expect.equals(true, value_not_and(false, true));
  Expect.equals(false, value_not_and(false, false));

  Expect.equals(false, value_not_and_not(true, true));
  Expect.equals(false, value_not_and_not(true, false));
  Expect.equals(false, value_not_and_not(false, true));
  Expect.equals(true, value_not_and_not(false, false));

  Expect.equals(true, value_or(true, true));
  Expect.equals(true, value_or(true, false));
  Expect.equals(true, value_or(false, true));
  Expect.equals(false, value_or(false, false));

  Expect.equals(true, value_or_not(true, true));
  Expect.equals(true, value_or_not(true, false));
  Expect.equals(false, value_or_not(false, true));
  Expect.equals(true, value_or_not(false, false));

  Expect.equals(true, value_not_or(true, true));
  Expect.equals(false, value_not_or(true, false));
  Expect.equals(true, value_not_or(false, true));
  Expect.equals(true, value_not_or(false, false));

  Expect.equals(false, value_not_or_not(true, true));
  Expect.equals(true, value_not_or_not(true, false));
  Expect.equals(true, value_not_or_not(false, true));
  Expect.equals(true, value_not_or_not(false, false));

  Expect.equals(0, if_negate(true));
  Expect.equals(1, if_negate(false));

  Expect.equals(1, if_and(true, true));
  Expect.equals(0, if_and(true, false));
  Expect.equals(0, if_and(false, true));
  Expect.equals(0, if_and(false, false));

  Expect.equals(0, if_and_not(true, true));
  Expect.equals(1, if_and_not(true, false));
  Expect.equals(0, if_and_not(false, true));
  Expect.equals(0, if_and_not(false, false));

  Expect.equals(0, if_not_and(true, true));
  Expect.equals(0, if_not_and(true, false));
  Expect.equals(1, if_not_and(false, true));
  Expect.equals(0, if_not_and(false, false));

  Expect.equals(0, if_not_and_not(true, true));
  Expect.equals(0, if_not_and_not(true, false));
  Expect.equals(0, if_not_and_not(false, true));
  Expect.equals(1, if_not_and_not(false, false));

  Expect.equals(1, if_or(true, true));
  Expect.equals(1, if_or(true, false));
  Expect.equals(1, if_or(false, true));
  Expect.equals(0, if_or(false, false));

  Expect.equals(1, if_or_not(true, true));
  Expect.equals(1, if_or_not(true, false));
  Expect.equals(0, if_or_not(false, true));
  Expect.equals(1, if_or_not(false, false));

  Expect.equals(1, if_not_or(true, true));
  Expect.equals(0, if_not_or(true, false));
  Expect.equals(1, if_not_or(false, true));
  Expect.equals(1, if_not_or(false, false));

  Expect.equals(0, if_not_or_not(true, true));
  Expect.equals(1, if_not_or_not(true, false));
  Expect.equals(1, if_not_or_not(false, true));
  Expect.equals(1, if_not_or_not(false, false));
}
