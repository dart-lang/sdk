// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Element {}

class Class<E extends Element?> {
  E? element;

  Class(this.element);

  void setElement(E? element) {
    if (this.element != element) {
      this.element = element;
      Set<Element> elements = new Set<Element>();
      if (element != null) {
        elements.add(element);
      }
      if (this.element != null) {
        elements.add(this.element!);
      }
    }
  }
}

main() {}
