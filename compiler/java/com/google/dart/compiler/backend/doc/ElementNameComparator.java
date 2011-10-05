// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.backend.doc;

import com.google.dart.compiler.resolver.Element;

import java.util.Comparator;

class ElementNameComparator implements Comparator<Element> {
  @Override
  public int compare(Element e1, Element e2) {
    String name1 = e1.getName();
    String name2 = e2.getName();
    return name1.compareTo(name2);
  }
}
