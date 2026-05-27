// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

int? i = null;

void main() {
  i?.{
    1;
    return;
  };
  i?.{
    this;
    return;
  };
  i?.{
    this.isEven;
    return;
  };
  i?.{
    isEven;
    return;
  };
  i?.{
    return 1;
  };
  i?.{
    return this;
  };
  i?.{
    return this.isEven;
  };
  i?.{
    return isEven;
  };
}
