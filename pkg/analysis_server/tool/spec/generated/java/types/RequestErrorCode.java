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
 * An enumeration of the types of errors that can occur in the execution of the server.
 *
 * @coverage dart.server.generated.types
 */
public class RequestErrorCode {

  /**
   * An "analysis.getErrors" or "analysis.getNavigation" request could not be satisfied because the
   * content of the file changed before the requested results could be computed.
   */
  public static final String CONTENT_MODIFIED = "CONTENT_MODIFIED";

  /**
   * The server was unable to open a port for the diagnostic server.
   */
  public static final String DEBUG_PORT_COULD_NOT_BE_OPENED = "DEBUG_PORT_COULD_NOT_BE_OPENED";

  /**
   * A request specified a FilePath which does not match a file in an analysis root, or the requested
   * operation is not available for the file.
   */
  public static final String FILE_NOT_ANALYZED = "FILE_NOT_ANALYZED";

  /**
   * A file was change while widget descriptions were being computed.
   */
  public static final String FLUTTER_GET_WIDGET_DESCRIPTION_CONTENT_MODIFIED = "FLUTTER_GET_WIDGET_DESCRIPTION_CONTENT_MODIFIED";

  /**
   * The given location does not have a supported widget.
   */
  public static final String FLUTTER_GET_WIDGET_DESCRIPTION_NO_WIDGET = "FLUTTER_GET_WIDGET_DESCRIPTION_NO_WIDGET";

  /**
   * The given property expression is invalid, e.g. has a syntax error.
   */
  public static final String FLUTTER_SET_WIDGET_PROPERTY_VALUE_INVALID_EXPRESSION = "FLUTTER_SET_WIDGET_PROPERTY_VALUE_INVALID_EXPRESSION";

  /**
   * The given property identifier is not valid. It might have never been valid, or a change to code
   * invalidated it, or its TTL was exceeded.
   */
  public static final String FLUTTER_SET_WIDGET_PROPERTY_VALUE_INVALID_ID = "FLUTTER_SET_WIDGET_PROPERTY_VALUE_INVALID_ID";

  /**
   * The value of the property cannot be removed, for example because the corresponding constructor
   * argument is required, and the server does not know what default value to use.
   */
  public static final String FLUTTER_SET_WIDGET_PROPERTY_VALUE_IS_REQUIRED = "FLUTTER_SET_WIDGET_PROPERTY_VALUE_IS_REQUIRED";

  /**
   * An "edit.format" request specified a FilePath which does not match a Dart file in an analysis
   * root.
   */
  public static final String FORMAT_INVALID_FILE = "FORMAT_INVALID_FILE";

  /**
   * An "edit.format" request specified a file that contains syntax errors.
   */
  public static final String FORMAT_WITH_ERRORS = "FORMAT_WITH_ERRORS";

  /**
   * An "analysis.getErrors" request specified a FilePath which does not match a file currently
   * subject to analysis.
   */
  public static final String GET_ERRORS_INVALID_FILE = "GET_ERRORS_INVALID_FILE";

  /**
   * An "edit.getFixes" request specified a FilePath which does not match a file currently subject to
   * analysis.
   */
  public static final String GET_FIXES_INVALID_FILE = "GET_FIXES_INVALID_FILE";

  /**
   * An "analysis.getImportedElements" request specified a FilePath that does not match a file
   * currently subject to analysis.
   */
  public static final String GET_IMPORTED_ELEMENTS_INVALID_FILE = "GET_IMPORTED_ELEMENTS_INVALID_FILE";

  /**
   * An "analysis.getKytheEntries" request specified a FilePath that does not match a file that is
   * currently subject to analysis.
   */
  public static final String GET_KYTHE_ENTRIES_INVALID_FILE = "GET_KYTHE_ENTRIES_INVALID_FILE";

  /**
   * An "analysis.getNavigation" request specified a FilePath which does not match a file currently
   * subject to analysis.
   */
  public static final String GET_NAVIGATION_INVALID_FILE = "GET_NAVIGATION_INVALID_FILE";

  /**
   * An "analysis.getReachableSources" request specified a FilePath which does not match a file
   * currently subject to analysis.
   */
  public static final String GET_REACHABLE_SOURCES_INVALID_FILE = "GET_REACHABLE_SOURCES_INVALID_FILE";

  /**
   * An "analysis.getSignature" request specified a FilePath which does not match a file currently
   * subject to analysis.
   */
  public static final String GET_SIGNATURE_INVALID_FILE = "GET_SIGNATURE_INVALID_FILE";

  /**
   * An "analysis.getSignature" request specified an offset which is not a valid location within for
   * the contents of the file specified FilePath.
   */
  public static final String GET_SIGNATURE_INVALID_OFFSET = "GET_SIGNATURE_INVALID_OFFSET";

  /**
   * An "analysis.getSignature" request specified an offset that could not be matched to a function
   * call.
   */
  public static final String GET_SIGNATURE_UNKNOWN_FUNCTION = "GET_SIGNATURE_UNKNOWN_FUNCTION";

  /**
   * An "edit.importElements" request specified a FilePath that does not match a file currently
   * subject to analysis.
   */
  public static final String IMPORT_ELEMENTS_INVALID_FILE = "IMPORT_ELEMENTS_INVALID_FILE";

  /**
   * A path passed as an argument to a request (such as analysis.reanalyze) is required to be an
   * analysis root, but isn't.
   */
  public static final String INVALID_ANALYSIS_ROOT = "INVALID_ANALYSIS_ROOT";

  /**
   * The context root used to create an execution context does not exist.
   */
  public static final String INVALID_EXECUTION_CONTEXT = "INVALID_EXECUTION_CONTEXT";

  /**
   * The format of the given file path is invalid, e.g. is not absolute and normalized.
   */
  public static final String INVALID_FILE_PATH_FORMAT = "INVALID_FILE_PATH_FORMAT";

  /**
   * An "analysis.updateContent" request contained a ChangeContentOverlay object which can't be
   * applied, due to an edit having an offset or length that is out of range.
   */
  public static final String INVALID_OVERLAY_CHANGE = "INVALID_OVERLAY_CHANGE";

  /**
   * One of the method parameters was invalid.
   */
  public static final String INVALID_PARAMETER = "INVALID_PARAMETER";

  /**
   * A malformed request was received.
   */
  public static final String INVALID_REQUEST = "INVALID_REQUEST";

  /**
   * An "edit.organizeDirectives" request specified a Dart file that cannot be analyzed. The reason
   * is described in the message.
   */
  public static final String ORGANIZE_DIRECTIVES_ERROR = "ORGANIZE_DIRECTIVES_ERROR";

  /**
   * Another refactoring request was received during processing of this one.
   */
  public static final String REFACTORING_REQUEST_CANCELLED = "REFACTORING_REQUEST_CANCELLED";

  /**
   * The analysis server has already been started (and hence won't accept new connections).
   *
   * This error is included for future expansion; at present the analysis server can only speak to
   * one client at a time so this error will never occur.
   */
  public static final String SERVER_ALREADY_STARTED = "SERVER_ALREADY_STARTED";

  /**
   * An internal error occurred in the analysis server. Also see the server.error notification.
   */
  public static final String SERVER_ERROR = "SERVER_ERROR";

  /**
   * An "edit.sortMembers" request specified a FilePath which does not match a Dart file in an
   * analysis root.
   */
  public static final String SORT_MEMBERS_INVALID_FILE = "SORT_MEMBERS_INVALID_FILE";

  /**
   * An "edit.sortMembers" request specified a Dart file that has scan or parse errors.
   */
  public static final String SORT_MEMBERS_PARSE_ERRORS = "SORT_MEMBERS_PARSE_ERRORS";

  /**
   * A request was received which the analysis server does not recognize, or cannot handle in its
   * current configuration.
   */
  public static final String UNKNOWN_REQUEST = "UNKNOWN_REQUEST";

  /**
   * The analysis server was requested to perform an action which is not supported.
   *
   * This is a legacy error; it will be removed before the API reaches version 1.0.
   */
  public static final String UNSUPPORTED_FEATURE = "UNSUPPORTED_FEATURE";

}
