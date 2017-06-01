// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void set onlySetter(value) {
  print("onlySetter called with $value.");
}

class C {
  void set onlySetter(value) {
    print("C.onlySetter called with $value.");
  }

  testC() {
    try {
      print(onlySetter);
      throw "No error thrown";
    } on NoSuchMethodError catch (e) {
      print("Expected error: $e");
    }
    onlySetter = "hest";
  }

  testD() {
    print(onlySetter);
    onlySetter = "hest";
  }
}

class D extends C {
  String get onlySetter => "D.onlySetter called.";

  void set onlySetter(value) {
    print("D.onlySetter called with $value.");
  }
}

main() {
  try {
    print(onlySetter);
    throw "No error thrown";
  } on NoSuchMethodError catch (e) {
    print("Expected error: $e");
  }
  onlySetter = "fisk";
  new C().testC();
  new D().testD();
}
