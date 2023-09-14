// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension type Class1(int it) {
  Class1.named1(this.it, int additional);

  Class1.named2(int this.it, int additional) {
    print(additional);
  }

  Class1.named3(int it) : this.it = it;

  Class1.named4(int additional, int it) : this.it = it;

  Class1.named5(int additional, int it) : this.it = it {
    print(additional);
  }

  Class1.named6(String text) : it = text.length;
}

extension type Class2<T>(T it) {
  Class2.named1(this.it, int additional);

  Class2.named2(T this.it, int additional) {
    print(additional);
  }

  Class2.named3(T it) : this.it = it;

  Class2.named4(int additional, T it) : this.it = it;

  Class2.named5(int additional, T it) : this.it = it {
    print(additional);
  }

  Class2.named6(List<T> list) : it = list.first;
}