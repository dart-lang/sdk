// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Super {}

class Class extends Super {
  method() {
    super.missingSuperGetter;
    super.missingSuperSetter = 42;
    --super.missingSuperProperty;
    super.missingSuperProperty++;
    super.missingSuperProperty += 42;
    super.missingSuperMethod();
    super.missingSuperMethod<int>;
    super.missingSuperIndex[42];
    super.missingSuperIndex[42] = 42;
  }

  static staticMethod() {
    Super.missingStaticGetter;
    Super.missingStaticSetter = 42;
    --Super.missingStaticProperty;
    Super.missingStaticProperty++;
    Super.missingStaticProperty += 42;
    Super.missingStaticMethod();
    Super.missingStaticMethod<int>;
    Super.missingStaticIndex[42];
    Super.missingStaticIndex[42] = 42;
  }
}

mixin Mixin on Super {
  method() {
    super.missingSuperGetter;
    super.missingSuperSetter = 42;
    --super.missingSuperProperty;
    super.missingSuperProperty++;
    super.missingSuperProperty += 42;
    super.missingSuperMethod();
    super.missingSuperMethod<int>;
    super.missingSuperIndex[42];
    super.missingSuperIndex[42] = 42;
  }

  static staticMethod() {
    Super.missingStaticGetter;
    Super.missingStaticSetter = 42;
    --Super.missingStaticProperty;
    Super.missingStaticProperty++;
    Super.missingStaticProperty += 42;
    Super.missingStaticMethod();
    Super.missingStaticMethod<int>;
    Super.missingStaticIndex[42];
    Super.missingStaticIndex[42] = 42;
  }
}
