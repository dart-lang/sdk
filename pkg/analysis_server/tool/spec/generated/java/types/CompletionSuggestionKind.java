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
 * An enumeration of the kinds of elements that can be included in a completion suggestion.
 *
 * @coverage dart.server.generated.types
 */
public class CompletionSuggestionKind {

  /**
   * A list of arguments for the method or function that is being invoked. For this suggestion kind,
   * the completion field is a textual representation of the invocation and the parameterNames,
   * parameterTypes, and requiredParameterCount attributes are defined.
   */
  public static final String ARGUMENT_LIST = "ARGUMENT_LIST";

  public static final String IMPORT = "IMPORT";

  /**
   * The element identifier should be inserted at the completion location. For example "someMethod"
   * in import 'myLib.dart' show someMethod;. For suggestions of this kind, the element attribute is
   * defined and the completion field is the element's identifier.
   */
  public static final String IDENTIFIER = "IDENTIFIER";

  /**
   * The element is being invoked at the completion location. For example, 'someMethod' in
   * x.someMethod();. For suggestions of this kind, the element attribute is defined and the
   * completion field is the element's identifier.
   */
  public static final String INVOCATION = "INVOCATION";

  /**
   * A keyword is being suggested. For suggestions of this kind, the completion is the keyword.
   */
  public static final String KEYWORD = "KEYWORD";

  /**
   * A named argument for the current call site is being suggested. For suggestions of this kind, the
   * completion is the named argument identifier including a trailing ':' and a space.
   */
  public static final String NAMED_ARGUMENT = "NAMED_ARGUMENT";

  public static final String OPTIONAL_ARGUMENT = "OPTIONAL_ARGUMENT";

  /**
   * An overriding implementation of a class member is being suggested.
   */
  public static final String OVERRIDE = "OVERRIDE";

  public static final String PARAMETER = "PARAMETER";

  /**
   * The name of a pub package is being suggested.
   */
  public static final String PACKAGE_NAME = "PACKAGE_NAME";

}
