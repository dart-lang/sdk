// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.metrics;

import com.google.dart.compiler.metrics.Tracer.EventType;

/**
 * Dart events for SpeedTracer.
 */
public enum DartEventType implements EventType {
  ADD_OUTOFDATE("MistyRose"),
  BUILD_LIB_SCOPES("violet"),
  COMPILE("green"),
  COMPILE_APP("gray"),
  COMPILE_LIBRARIES("brown"),
  EXEC_PHASE("blue"),
  IMPORT_EMBEDDED_LIBRARIES("purple"),
  IS_SOURCE_OUTOFDATE("Chartreuse"),
  SCANNER("GoldenRod"),
  PARSE("red"),
  PARSE_OUTOFDATE("LightCoral"),
  RESOLVE_LIBRARIES("black"),
  TIMESTAMP_OUTOFDATE("LightSteelBlue"),
  UPDATE_LIBRARIES("yellow"),
  UPDATE_RESOLVE("orange"),
  WRITE_METRICS("LightChiffon");

  final String cssColor;
  final String name;

  DartEventType(String cssColor) {
    this(null, cssColor);
  }

  DartEventType(String name, String cssColor) {
    this.name = name;
    this.cssColor = cssColor;
  }

  @Override
  public String getColor() {
    return cssColor;
  }

  @Override
  public String getName() {
    return name == null ? toString() : name;
  }
}
