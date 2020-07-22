// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that variables assigned in switch statements are not de-promoted if
// the assignment cannot possibly happen prior to the read.

void switchDefaultWithoutLabel(Object x) {
  if (x is int) {
    switch (x = 0) {
      case 1:
        break;
      default:
        // The assignment to x does not de-promote x because there is no label,
        // and it assigns an int (which is compatible with the promoted type).
        x.isEven;
        break;
    }
  }
}

void switchCaseWithoutLabel(Object x) {
  if (x is int) {
    switch (x = 0) {
      case 1:
        break;
      case 0:
        // The assignment to x does not de-promote x because there is no label,
        // and it assigns an int (which is compatible with the promoted type).
        x.isEven;
        break;
    }
  }
}

void switchDefaultWithoutLabelAssignInDefault(Object x) {
  if (x is int) {
    switch (x) {
      default:
        // The assignment to x does not de-promote x because there is no label.
        x.isEven;
        x = 0;
        break;
    }
  }
}

void switchCaseWithoutLabelAssignInCase(Object x) {
  if (x is int) {
    switch (x) {
      case 0:
        // The assignment to x does not de-promote x because there is no label.
        x.isEven;
        x = 0;
        break;
    }
  }
}

void switchDefaultWithLabel(Object x) {
  if (x is int) {
    switch (x = 0) {
      case 1:
        continue L;
      L:
      default:
        // The assignment to x does not de-promote x because it happens before
        // the label, and it assigns an int (which is compatible with the
        // promoted type).
        x.isEven;
        break;
    }
  }
}

void switchCaseWithLabel(Object x) {
  if (x is int) {
    switch (x = 0) {
      case 1:
        continue L;
      L:
      case 0:
        // The assignment to x does not de-promote x because it happens before
        // the label, and it assigns an int (which is compatible with the
        // promoted type).
        x.isEven;
        break;
    }
  }
}

main() {
  switchDefaultWithoutLabel(0);
  switchCaseWithoutLabel(0);
  switchDefaultWithoutLabelAssignInDefault(0);
  switchCaseWithoutLabelAssignInCase(0);
  switchDefaultWithLabel(0);
  switchCaseWithLabel(0);
}
