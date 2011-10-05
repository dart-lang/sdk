// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.backend.doc;

public class LinkInformation {
  public String libName;
  public String className;
  public String elementName;
  
  public LinkInformation(String libName, String className, String elementName) {
    this.libName = libName;
    this.className = className;
    this.elementName = elementName;
  }
  
  @Override
  public boolean equals(Object other) {
    if (other instanceof LinkInformation) {
      LinkInformation otherLink = (LinkInformation) other;
      return libName.equals(otherLink.libName) &&
          className.equals(otherLink.className) &&
          elementName.equals(otherLink.elementName);
    } else {
      return false;
    }
  }

  @Override
  public int hashCode() {
    return elementName.hashCode();
  }

  public String anchorReferenceStartTag() {
    return "<a href='" + className + ".html#" + elementName + "'>";
  }

  public String anchorStartTag() {
    return "<a name='" + elementName + "'>";
  }
}
