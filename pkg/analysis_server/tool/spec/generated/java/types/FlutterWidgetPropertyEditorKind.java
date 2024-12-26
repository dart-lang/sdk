/*
 * Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
 * for details. All rights reserved. Use of this source code is governed by a
 * BSD-style license that can be found in the LICENSE file.
 *
 * This file has been automatically generated. Please do not edit it manually.
 * To regenerate the file, use the script "pkg/analysis_server/tool/spec/generate_files".
 */
package org.dartlang.analysis.server.protocol;

/**
 * An enumeration of the kinds of property editors.
 *
 * @coverage dart.server.generated.types
 */
public class FlutterWidgetPropertyEditorKind {

  /**
   * The editor for a property of type <code>bool</code>.
   */
  public static final String BOOL = "BOOL";

  /**
   * The editor for a property of the type <code>double</code>.
   */
  public static final String DOUBLE = "DOUBLE";

  /**
   * The editor for choosing an item of an enumeration, see the <code>enumItems</code> field of
   * <code>FlutterWidgetPropertyEditor</code>.
   */
  public static final String ENUM = "ENUM";

  /**
   * The editor for either choosing a pre-defined item from a list of provided static field
   * references (like <code>ENUM</code>), or specifying a free-form expression.
   */
  public static final String ENUM_LIKE = "ENUM_LIKE";

  /**
   * The editor for a property of type <code>int</code>.
   */
  public static final String INT = "INT";

  /**
   * The editor for a property of the type <code>String</code>.
   */
  public static final String STRING = "STRING";

}
