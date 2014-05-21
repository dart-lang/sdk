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
}
