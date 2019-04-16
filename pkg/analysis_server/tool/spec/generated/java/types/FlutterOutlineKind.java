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
 * An enumeration of the kinds of FlutterOutline elements. The list of kinds might be expanded with
 * time, clients must be able to handle new kinds in some general way.
 *
 * @coverage dart.server.generated.types
 */
public class FlutterOutlineKind {

  /**
   * A dart element declaration.
   */
  public static final String DART_ELEMENT = "DART_ELEMENT";

  /**
   * A generic Flutter element, without additional information.
   */
  public static final String GENERIC = "GENERIC";

  /**
   * A new instance creation.
   */
  public static final String NEW_INSTANCE = "NEW_INSTANCE";

  /**
   * An invocation of a method, a top-level function, a function expression, etc.
   */
  public static final String INVOCATION = "INVOCATION";

  /**
   * A reference to a local variable, or a field.
   */
  public static final String VARIABLE = "VARIABLE";

  /**
   * The parent node has a required Widget. The node works as a placeholder child to drop a new
   * Widget to.
   */
  public static final String PLACEHOLDER = "PLACEHOLDER";

}
