// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.metrics;

import com.google.dart.compiler.metrics.Tracer.EventType;

/**
 * Represents a type of event whose performance is tracked while running.
 */
public enum SpeedTracerEventType implements EventType {
  GC("Garbage Collection", "Plum"),
  OVERHEAD("Speedtracer Overhead","Black");

  final String cssColor;
  final String name;

  SpeedTracerEventType(String name, String cssColor) {
    this.name = name;
    this.cssColor = cssColor;
  }

  @Override
  public String getColor() {
    return cssColor;
  }

  @Override
  public String getName() {
    return name;
  }
}
