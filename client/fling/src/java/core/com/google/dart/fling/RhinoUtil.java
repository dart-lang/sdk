// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.fling;

import org.mozilla.javascript.ScriptableObject;

public class RhinoUtil {
  @SuppressWarnings("unchecked") public static <T> T getProperty(ScriptableObject object, String name) {
    return (T)ScriptableObject.getProperty(object, name);
  }

  public static <T> void setProperty(ScriptableObject object, String name, T value) {
    ScriptableObject.putProperty(object, name, value);
  }
}
