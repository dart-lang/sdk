// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

augment void topLevelMethod() {
  augment super();
  augment super;
}

augment void topLevelMethodErrors() {
  augment int local; // Error
  augment; // Error
}

augment List<int> get topLevelProperty {
  return [... augment super,
    // TODO(johnniwinther): Support indexed access.
    /*augment super[0]*/];
}

augment void set topLevelProperty(List<int> value) {
  // TODO(johnniwinther): Support indexed access.
  //augment super[0] = value[1];
  augment super = value;
  augment super; // Error
  augment super(); // Error
}

augment List<int>? get nullableTopLevelProperty {
  return [
    // TODO(johnniwinther): Support this syntax.
    /*... ?augment super,*/
    // TODO(johnniwinther): Support indexed access.
    /*augment super?[0]*/];
}

augment void set nullableTopLevelProperty(List<int>? value) {
  // TODO(johnniwinther): Support indexed access.
  //augment super?[0] = value?[1];
  augment super ??= value;
}

void injectedTopLevelMethod() {
  augment super(); // Error
  augment super; // Error
  augment int local; // Error
  augment; // Error
}

augment class Class {
  augment void instanceMethod() {
    augment super();
    augment super; // Error
  }

  augment void instanceMethodErrors() {
    augment int local; // Error
    augment; // Error
  }

  augment int get instanceProperty {
    augment super++; // Error
    --augment super; // Error
    augment super += 1; // Error
    return -augment super;
  }

  augment void set instanceProperty(int value) {
    augment super = value;
    augment super; // Error
    augment super(); // Error
  }

  augment int? get nullableInstanceProperty {
    augment super ??= 1; // Error
    return augment super;
  }

  augment void set nullableInstanceProperty(int? value) {
    augment super = value;
  }

  void injectedInstanceMethod() {
    augment super(); // Error
    augment super; // Error
    augment int local; // Error
    augment; // Error
  }
}