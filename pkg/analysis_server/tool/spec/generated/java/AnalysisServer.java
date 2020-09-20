/*
 * Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
 * for details. All rights reserved. Use of this source code is governed by a
 * BSD-style license that can be found in the LICENSE file.
 *
 * This file has been automatically generated. Please do not edit it manually.
 * To regenerate the file, use the script "pkg/analysis_server/tool/spec/generate_files".
 */
package com.google.dart.server.generated;

import com.google.dart.server.*;
import org.dartlang.analysis.server.protocol.*;

import java.util.List;
import java.util.Map;

/**
 * The interface {@code AnalysisServer} defines the behavior of objects that interface to an
 * analysis server.
 *
 * @coverage dart.server
 */
public interface AnalysisServer {

  /**
   * Add the given listener to the list of listeners that will receive notification when new
   * analysis results become available.
   *
   * @param listener the listener to be added
   */
  public void addAnalysisServerListener(AnalysisServerListener listener);

  /**
   * Add the given listener to the list of listeners that will receive notification when
     * requests are made by an analysis server client.
   *
   * @param listener the listener to be added
   */
  public void addRequestListener(RequestListener listener);

  /**
   * Add the given listener to the list of listeners that will receive notification when
   * responses are received by an analysis server client.
   *
   * @param listener the listener to be added
   */
  public void addResponseListener(ResponseListener listener);

  /**
   * Add the given listener to the list of listeners that will receive notification when the server
   * is not active
   *
   * @param listener the listener to be added
   */
  public void addStatusListener(AnalysisServerStatusListener listener);

  /**
   * {@code analysis.getErrors}
   *
   * Return the errors associated with the given file. If the errors for the given file have not yet
   * been computed, or the most recently computed errors for the given file are out of date, then the
   * response for this request will be delayed until they have been computed. If some or all of the
   * errors for the file cannot be computed, then the subset of the errors that can be computed will
   * be returned and the response will contain an error to indicate why the errors could not be
   * computed. If the content of the file changes after this request was received but before a
   * response could be sent, then an error of type CONTENT_MODIFIED will be generated.
   *
   * This request is intended to be used by clients that cannot asynchronously apply updated error
   * information. Clients that can apply error information as it becomes available should use the
   * information provided by the 'analysis.errors' notification.
   *
   * If a request is made for a file which does not exist, or which is not currently subject to
   * analysis (e.g. because it is not associated with any analysis root specified to
   * analysis.setAnalysisRoots), an error of type GET_ERRORS_INVALID_FILE will be generated.
   *
   * @param file The file for which errors are being requested.
   */
  public void analysis_getErrors(String file, GetErrorsConsumer consumer);

  /**
   * {@code analysis.getHover}
   *
   * Return the hover information associate with the given location. If some or all of the hover
   * information is not available at the time this request is processed the information will be
   * omitted from the response.
   *
   * @param file The file in which hover information is being requested.
   * @param offset The offset for which hover information is being requested.
   */
  public void analysis_getHover(String file, int offset, GetHoverConsumer consumer);

  /**
   * {@code analysis.getImportedElements}
   *
   * Return a description of all of the elements referenced in a given region of a given file that
   * come from imported libraries.
   *
   * If a request is made for a file that does not exist, or that is not currently subject to
   * analysis (e.g. because it is not associated with any analysis root specified via
   * analysis.setAnalysisRoots), an error of type GET_IMPORTED_ELEMENTS_INVALID_FILE will be
   * generated.
   *
   * @param file The file in which import information is being requested.
   * @param offset The offset of the region for which import information is being requested.
   * @param length The length of the region for which import information is being requested.
   */
  public void analysis_getImportedElements(String file, int offset, int length, GetImportedElementsConsumer consumer);

  /**
   * {@code analysis.getLibraryDependencies}
   *
   * Return library dependency information for use in client-side indexing and package URI
   * resolution.
   *
   * Clients that are only using the libraries field should consider using the analyzedFiles
   * notification instead.
   */
  public void analysis_getLibraryDependencies(GetLibraryDependenciesConsumer consumer);

  /**
   * {@code analysis.getNavigation}
   *
   * Return the navigation information associated with the given region of the given file. If the
   * navigation information for the given file has not yet been computed, or the most recently
   * computed navigation information for the given file is out of date, then the response for this
   * request will be delayed until it has been computed. If the content of the file changes after
   * this request was received but before a response could be sent, then an error of type
   * CONTENT_MODIFIED will be generated.
   *
   * If a navigation region overlaps (but extends either before or after) the given region of the
   * file it will be included in the result. This means that it is theoretically possible to get the
   * same navigation region in response to multiple requests. Clients can avoid this by always
   * choosing a region that starts at the beginning of a line and ends at the end of a (possibly
   * different) line in the file.
   *
   * If a request is made for a file which does not exist, or which is not currently subject to
   * analysis (e.g. because it is not associated with any analysis root specified to
   * analysis.setAnalysisRoots), an error of type GET_NAVIGATION_INVALID_FILE will be generated.
   *
   * @param file The file in which navigation information is being requested.
   * @param offset The offset of the region for which navigation information is being requested.
   * @param length The length of the region for which navigation information is being requested.
   */
  public void analysis_getNavigation(String file, int offset, int length, GetNavigationConsumer consumer);

  /**
   * {@code analysis.getReachableSources}
   *
   * Return the transitive closure of reachable sources for a given file.
   *
   * If a request is made for a file which does not exist, or which is not currently subject to
   * analysis (e.g. because it is not associated with any analysis root specified to
   * analysis.setAnalysisRoots), an error of type GET_REACHABLE_SOURCES_INVALID_FILE will be
   * generated.
   *
   * @param file The file for which reachable source information is being requested.
   *
   * @deprecated
   */
  public void analysis_getReachableSources(String file, GetReachableSourcesConsumer consumer);

  /**
   * {@code analysis.getSignature}
   *
   * Return the signature information associated with the given location in the given file. If the
   * signature information for the given file has not yet been computed, or the most recently
   * computed signature information for the given file is out of date, then the response for this
   * request will be delayed until it has been computed. If a request is made for a file which does
   * not exist, or which is not currently subject to analysis (e.g. because it is not associated with
   * any analysis root specified to analysis.setAnalysisRoots), an error of type
   * GET_SIGNATURE_INVALID_FILE will be generated. If the location given is not inside the argument
   * list for a function (including method and constructor) invocation, then an error of type
   * GET_SIGNATURE_INVALID_OFFSET will be generated. If the location is inside an argument list but
   * the function is not defined or cannot be determined (such as a method invocation where the
   * target has type 'dynamic') then an error of type GET_SIGNATURE_UNKNOWN_FUNCTION will be
   * generated.
   *
   * @param file The file in which signature information is being requested.
   * @param offset The location for which signature information is being requested.
   */
  public void analysis_getSignature(String file, int offset, GetSignatureConsumer consumer);

  /**
   * {@code analysis.reanalyze}
   *
   * Force re-reading of all potentially changed files, re-resolving of all referenced URIs, and
   * corresponding re-analysis of everything affected in the current analysis roots.
   */
  public void analysis_reanalyze();

  /**
   * {@code analysis.setAnalysisRoots}
   *
   * Sets the root paths used to determine which files to analyze. The set of files to be analyzed
   * are all of the files in one of the root paths that are not either explicitly or implicitly
   * excluded. A file is explicitly excluded if it is in one of the excluded paths. A file is
   * implicitly excluded if it is in a subdirectory of one of the root paths where the name of the
   * subdirectory starts with a period (that is, a hidden directory).
   *
   * Note that this request determines the set of requested analysis roots. The actual set of
   * analysis roots at any given time is the intersection of this set with the set of files and
   * directories actually present on the filesystem. When the filesystem changes, the actual set of
   * analysis roots is automatically updated, but the set of requested analysis roots is unchanged.
   * This means that if the client sets an analysis root before the root becomes visible to server in
   * the filesystem, there is no error; once the server sees the root in the filesystem it will start
   * analyzing it. Similarly, server will stop analyzing files that are removed from the file system
   * but they will remain in the set of requested roots.
   *
   * If an included path represents a file, then server will look in the directory containing the
   * file for a pubspec.yaml file. If none is found, then the parents of the directory will be
   * searched until such a file is found or the root of the file system is reached. If such a file is
   * found, it will be used to resolve package: URI’s within the file.
   *
   * @param included A list of the files and directories that should be analyzed.
   * @param excluded A list of the files and directories within the included directories that should
   *         not be analyzed.
   * @param packageRoots A mapping from source directories to package roots that should override the
   *         normal package: URI resolution mechanism. If a package root is a file, then the analyzer
   *         will behave as though that file is a ".packages" file in the source directory. The
   *         effect is the same as specifying the file as a "--packages" parameter to the Dart VM
   *         when executing any Dart file inside the source directory. Files in any directories that
   *         are not overridden by this mapping have their package: URI's resolved using the normal
   *         pubspec.yaml mechanism. If this field is absent, or the empty map is specified, that
   *         indicates that the normal pubspec.yaml mechanism should always be used.
   */
  public void analysis_setAnalysisRoots(List<String> included, List<String> excluded, Map<String, String> packageRoots);

  /**
   * {@code analysis.setGeneralSubscriptions}
   *
   * Subscribe for general services (that is, services that are not specific to individual files).
   * All previous subscriptions are replaced by the given set of services.
   *
   * It is an error if any of the elements in the list are not valid services. If there is an error,
   * then the current subscriptions will remain unchanged.
   *
   * @param subscriptions A list of the services being subscribed to.
   */
  public void analysis_setGeneralSubscriptions(List<String> subscriptions);

  /**
   * {@code analysis.setPriorityFiles}
   *
   * Set the priority files to the files in the given list. A priority file is a file that is given
   * priority when scheduling which analysis work to do first. The list typically contains those
   * files that are visible to the user and those for which analysis results will have the biggest
   * impact on the user experience. The order of the files within the list is significant: the first
   * file will be given higher priority than the second, the second higher priority than the third,
   * and so on.
   *
   * Note that this request determines the set of requested priority files. The actual set of
   * priority files is the intersection of the requested set of priority files with the set of files
   * currently subject to analysis. (See analysis.setSubscriptions for a description of files that
   * are subject to analysis.)
   *
   * If a requested priority file is a directory it is ignored, but remains in the set of requested
   * priority files so that if it later becomes a file it can be included in the set of actual
   * priority files.
   *
   * @param files The files that are to be a priority for analysis.
   */
  public void analysis_setPriorityFiles(List<String> files);

  /**
   * {@code analysis.setSubscriptions}
   *
   * Subscribe for services that are specific to individual files. All previous subscriptions are
   * replaced by the current set of subscriptions. If a given service is not included as a key in the
   * map then no files will be subscribed to the service, exactly as if the service had been included
   * in the map with an explicit empty list of files.
   *
   * Note that this request determines the set of requested subscriptions. The actual set of
   * subscriptions at any given time is the intersection of this set with the set of files currently
   * subject to analysis. The files currently subject to analysis are the set of files contained
   * within an actual analysis root but not excluded, plus all of the files transitively reachable
   * from those files via import, export and part directives. (See analysis.setAnalysisRoots for an
   * explanation of how the actual analysis roots are determined.) When the actual analysis roots
   * change, the actual set of subscriptions is automatically updated, but the set of requested
   * subscriptions is unchanged.
   *
   * If a requested subscription is a directory it is ignored, but remains in the set of requested
   * subscriptions so that if it later becomes a file it can be included in the set of actual
   * subscriptions.
   *
   * It is an error if any of the keys in the map are not valid services. If there is an error, then
   * the existing subscriptions will remain unchanged.
   *
   * @param subscriptions A table mapping services to a list of the files being subscribed to the
   *         service.
   */
  public void analysis_setSubscriptions(Map<String, List<String>> subscriptions);

  /**
   * {@code analysis.updateContent}
   *
   * Update the content of one or more files. Files that were previously updated but not included in
   * this update remain unchanged. This effectively represents an overlay of the filesystem. The
   * files whose content is overridden are therefore seen by server as being files with the given
   * content, even if the files do not exist on the filesystem or if the file path represents the
   * path to a directory on the filesystem.
   *
   * @param files A table mapping the files whose content has changed to a description of the content
   *         change.
   */
  public void analysis_updateContent(Map<String, Object> files, UpdateContentConsumer consumer);

  /**
   * {@code analysis.updateOptions}
   *
   * Deprecated: all of the options can be set by users in an analysis options file.
   *
   * Update the options controlling analysis based on the given set of options. Any options that are
   * not included in the analysis options will not be changed. If there are options in the analysis
   * options that are not valid, they will be silently ignored.
   *
   * @param options The options that are to be used to control analysis.
   *
   * @deprecated
   */
  public void analysis_updateOptions(AnalysisOptions options);

  /**
   * {@code analytics.enable}
   *
   * Enable or disable the sending of analytics data. Note that there are other ways for users to
   * change this setting, so clients cannot assume that they have complete control over this setting.
   * In particular, there is no guarantee that the result returned by the isEnabled request will
   * match the last value set via this request.
   *
   * @param value Enable or disable analytics.
   */
  public void analytics_enable(boolean value);

  /**
   * {@code analytics.isEnabled}
   *
   * Query whether analytics is enabled.
   *
   * This flag controls whether the analysis server sends any analytics data to the cloud. If
   * disabled, the analysis server does not send any analytics data, and any data sent to it by
   * clients (from sendEvent and sendTiming) will be ignored.
   *
   * The value of this flag can be changed by other tools outside of the analysis server's process.
   * When you query the flag, you get the value of the flag at a given moment. Clients should not use
   * the value returned to decide whether or not to send the sendEvent and sendTiming requests. Those
   * requests should be used unconditionally and server will determine whether or not it is
   * appropriate to forward the information to the cloud at the time each request is received.
   */
  public void analytics_isEnabled(IsEnabledConsumer consumer);

  /**
   * {@code analytics.sendEvent}
   *
   * Send information about client events.
   *
   * Ask the analysis server to include the fact that an action was performed in the client as part
   * of the analytics data being sent. The data will only be included if the sending of analytics
   * data is enabled at the time the request is processed. The action that was performed is indicated
   * by the value of the action field.
   *
   * The value of the action field should not include the identity of the client. The analytics data
   * sent by server will include the client id passed in using the --client-id command-line argument.
   * The request will be ignored if the client id was not provided when server was started.
   *
   * @param action The value used to indicate which action was performed.
   */
  public void analytics_sendEvent(String action);

  /**
   * {@code analytics.sendTiming}
   *
   * Send timing information for client events (e.g. code completions).
   *
   * Ask the analysis server to include the fact that a timed event occurred as part of the analytics
   * data being sent. The data will only be included if the sending of analytics data is enabled at
   * the time the request is processed.
   *
   * The value of the event field should not include the identity of the client. The analytics data
   * sent by server will include the client id passed in using the --client-id command-line argument.
   * The request will be ignored if the client id was not provided when server was started.
   *
   * @param event The name of the event.
   * @param millis The duration of the event in milliseconds.
   */
  public void analytics_sendTiming(String event, int millis);

  /**
   * {@code completion.getSuggestionDetails}
   *
   * Clients must make this request when the user has selected a completion suggestion from an
   * AvailableSuggestionSet. Analysis server will respond with the text to insert as well as any
   * SourceChange that needs to be applied in case the completion requires an additional import to be
   * added. It is an error if the id is no longer valid, for instance if the library has been removed
   * after the completion suggestion is accepted.
   *
   * @param file The path of the file into which this completion is being inserted.
   * @param id The identifier of the AvailableSuggestionSet containing the selected label.
   * @param label The label from the AvailableSuggestionSet with the `id` for which insertion
   *         information is requested.
   * @param offset The offset in the file where the completion will be inserted.
   */
  public void completion_getSuggestionDetails(String file, int id, String label, int offset, GetSuggestionDetailsConsumer consumer);

  /**
   * {@code completion.getSuggestions}
   *
   * Request that completion suggestions for the given offset in the given file be returned.
   *
   * @param file The file containing the point at which suggestions are to be made.
   * @param offset The offset within the file at which suggestions are to be made.
   */
  public void completion_getSuggestions(String file, int offset, GetSuggestionsConsumer consumer);

  /**
   * {@code completion.listTokenDetails}
   *
   * Inspect analysis server's knowledge about all of a file's tokens including their lexeme, type,
   * and what element kinds would have been appropriate for the token's program location.
   *
   * @param file The path to the file from which tokens should be returned.
   */
  public void completion_listTokenDetails(String file, ListTokenDetailsConsumer consumer);

  /**
   * {@code completion.registerLibraryPaths}
   *
   * The client can make this request to express interest in certain libraries to receive completion
   * suggestions from based on the client path. If this request is received before the client has
   * used 'completion.setSubscriptions' to subscribe to the AVAILABLE_SUGGESTION_SETS service, then
   * an error of type NOT_SUBSCRIBED_TO_AVAILABLE_SUGGESTION_SETS will be generated. All previous
   * paths are replaced by the given set of paths.
   *
   * @param paths A list of objects each containing a path and the additional libraries from which
   *         the client is interested in receiving completion suggestions. If one configured path is
   *         beneath another, the descendent will override the ancestors' configured libraries of
   *         interest.
   *
   * @deprecated
   */
  public void completion_registerLibraryPaths(List<LibraryPathSet> paths);

  /**
   * {@code completion.setSubscriptions}
   *
   * Subscribe for completion services. All previous subscriptions are replaced by the given set of
   * services.
   *
   * It is an error if any of the elements in the list are not valid services. If there is an error,
   * then the current subscriptions will remain unchanged.
   *
   * @param subscriptions A list of the services being subscribed to.
   */
  public void completion_setSubscriptions(List<String> subscriptions);

  /**
   * {@code diagnostic.getDiagnostics}
   *
   * Return server diagnostics.
   */
  public void diagnostic_getDiagnostics(GetDiagnosticsConsumer consumer);

  /**
   * {@code diagnostic.getServerPort}
   *
   * Return the port of the diagnostic web server. If the server is not running this call will start
   * the server. If unable to start the diagnostic web server, this call will return an error of
   * DEBUG_PORT_COULD_NOT_BE_OPENED.
   */
  public void diagnostic_getServerPort(GetServerPortConsumer consumer);

  /**
   * {@code edit.bulkFixes}
   *
   * Analyze the specified sources for fixes that can be applied in bulk and return a set of
   * suggested edits for those sources. These edits may include changes to sources outside the set of
   * specified sources if a change in a specified source requires it.
   *
   * @param included A list of the files and directories for which edits should be suggested. If a
   *         request is made with a path that is invalid, e.g. is not absolute and normalized, an
   *         error of type INVALID_FILE_PATH_FORMAT will be generated. If a request is made for a
   *         file which does not exist, or which is not currently subject to analysis (e.g. because
   *         it is not associated with any analysis root specified to analysis.setAnalysisRoots), an
   *         error of type FILE_NOT_ANALYZED will be generated.
   */
  public void edit_bulkFixes(List<String> included, BulkFixesConsumer consumer);

  /**
   * {@code edit.dartfix}
   *
   * Analyze the specified sources for recommended changes and return a set of suggested edits for
   * those sources. These edits may include changes to sources outside the set of specified sources
   * if a change in a specified source requires it.
   *
   * If includedFixes is specified, then those fixes will be applied. If includePedanticFixes is
   * specified, then fixes associated with the pedantic rule set will be applied in addition to
   * whatever fixes are specified in includedFixes if any. If neither includedFixes nor
   * includePedanticFixes is specified, then no fixes will be applied. If excludedFixes is specified,
   * then those fixes will not be applied regardless of whether they are specified in includedFixes.
   *
   * @param included A list of the files and directories for which edits should be suggested. If a
   *         request is made with a path that is invalid, e.g. is not absolute and normalized, an
   *         error of type INVALID_FILE_PATH_FORMAT will be generated. If a request is made for a
   *         file which does not exist, or which is not currently subject to analysis (e.g. because
   *         it is not associated with any analysis root specified to analysis.setAnalysisRoots), an
   *         error of type FILE_NOT_ANALYZED will be generated.
   * @param includedFixes A list of names indicating which fixes should be applied. If a name is
   *         specified that does not match the name of a known fix, an error of type UNKNOWN_FIX will
   *         be generated.
   * @param includePedanticFixes A flag indicating whether "pedantic" fixes should be applied.
   * @param excludedFixes A list of names indicating which fixes should not be applied. If a name is
   *         specified that does not match the name of a known fix, an error of type UNKNOWN_FIX will
   *         be generated.
   * @param port Deprecated: This field is now ignored by server.
   * @param outputDir Deprecated: This field is now ignored by server.
   */
  public void edit_dartfix(List<String> included, List<String> includedFixes, boolean includePedanticFixes, List<String> excludedFixes, int port, String outputDir, DartfixConsumer consumer);

  /**
   * {@code edit.format}
   *
   * Format the contents of a single file. The currently selected region of text is passed in so that
   * the selection can be preserved across the formatting operation. The updated selection will be as
   * close to matching the original as possible, but whitespace at the beginning or end of the
   * selected region will be ignored. If preserving selection information is not required, zero (0)
   * can be specified for both the selection offset and selection length.
   *
   * If a request is made for a file which does not exist, or which is not currently subject to
   * analysis (e.g. because it is not associated with any analysis root specified to
   * analysis.setAnalysisRoots), an error of type FORMAT_INVALID_FILE will be generated. If the
   * source contains syntax errors, an error of type FORMAT_WITH_ERRORS will be generated.
   *
   * @param file The file containing the code to be formatted.
   * @param selectionOffset The offset of the current selection in the file.
   * @param selectionLength The length of the current selection in the file.
   * @param lineLength The line length to be used by the formatter.
   */
  public void edit_format(String file, int selectionOffset, int selectionLength, int lineLength, FormatConsumer consumer);

  /**
   * {@code edit.getAssists}
   *
   * Return the set of assists that are available at the given location. An assist is distinguished
   * from a refactoring primarily by the fact that it affects a single file and does not require user
   * input in order to be performed.
   *
   * @param file The file containing the code for which assists are being requested.
   * @param offset The offset of the code for which assists are being requested.
   * @param length The length of the code for which assists are being requested.
   */
  public void edit_getAssists(String file, int offset, int length, GetAssistsConsumer consumer);

  /**
   * {@code edit.getAvailableRefactorings}
   *
   * Get a list of the kinds of refactorings that are valid for the given selection in the given
   * file.
   *
   * @param file The file containing the code on which the refactoring would be based.
   * @param offset The offset of the code on which the refactoring would be based.
   * @param length The length of the code on which the refactoring would be based.
   */
  public void edit_getAvailableRefactorings(String file, int offset, int length, GetAvailableRefactoringsConsumer consumer);

  /**
   * {@code edit.getDartfixInfo}
   *
   * Request information about edit.dartfix such as the list of known fixes that can be specified in
   * an edit.dartfix request.
   */
  public void edit_getDartfixInfo(GetDartfixInfoConsumer consumer);

  /**
   * {@code edit.getFixes}
   *
   * Return the set of fixes that are available for the errors at a given offset in a given file.
   *
   * @param file The file containing the errors for which fixes are being requested.
   * @param offset The offset used to select the errors for which fixes will be returned.
   */
  public void edit_getFixes(String file, int offset, GetFixesConsumer consumer);

  /**
   * {@code edit.getPostfixCompletion}
   *
   * Get the changes required to convert the postfix template at the given location into the
   * template's expanded form.
   *
   * @param file The file containing the postfix template to be expanded.
   * @param key The unique name that identifies the template in use.
   * @param offset The offset used to identify the code to which the template will be applied.
   */
  public void edit_getPostfixCompletion(String file, String key, int offset, GetPostfixCompletionConsumer consumer);

  /**
   * {@code edit.getRefactoring}
   *
   * Get the changes required to perform a refactoring.
   *
   * If another refactoring request is received during the processing of this one, an error of type
   * REFACTORING_REQUEST_CANCELLED will be generated.
   *
   * @param kind The kind of refactoring to be performed.
   * @param file The file containing the code involved in the refactoring.
   * @param offset The offset of the region involved in the refactoring.
   * @param length The length of the region involved in the refactoring.
   * @param validateOnly True if the client is only requesting that the values of the options be
   *         validated and no change be generated.
   * @param options Data used to provide values provided by the user. The structure of the data is
   *         dependent on the kind of refactoring being performed. The data that is expected is
   *         documented in the section titled Refactorings, labeled as "Options". This field can be
   *         omitted if the refactoring does not require any options or if the values of those
   *         options are not known.
   */
  public void edit_getRefactoring(String kind, String file, int offset, int length, boolean validateOnly, RefactoringOptions options, GetRefactoringConsumer consumer);

  /**
   * {@code edit.getStatementCompletion}
   *
   * Get the changes required to convert the partial statement at the given location into a
   * syntactically valid statement. If the current statement is already valid the change will insert
   * a newline plus appropriate indentation at the end of the line containing the offset. If a change
   * that makes the statement valid cannot be determined (perhaps because it has not yet been
   * implemented) the statement will be considered already valid and the appropriate change returned.
   *
   * @param file The file containing the statement to be completed.
   * @param offset The offset used to identify the statement to be completed.
   */
  public void edit_getStatementCompletion(String file, int offset, GetStatementCompletionConsumer consumer);

  /**
   * {@code edit.importElements}
   *
   * Return a list of edits that would need to be applied in order to ensure that all of the elements
   * in the specified list of imported elements are accessible within the library.
   *
   * If a request is made for a file that does not exist, or that is not currently subject to
   * analysis (e.g. because it is not associated with any analysis root specified via
   * analysis.setAnalysisRoots), an error of type IMPORT_ELEMENTS_INVALID_FILE will be generated.
   *
   * @param file The file in which the specified elements are to be made accessible.
   * @param elements The elements to be made accessible in the specified file.
   * @param offset The offset at which the specified elements need to be made accessible. If
   *         provided, this is used to guard against adding imports for text that would be inserted
   *         into a comment, string literal, or other location where the imports would not be
   *         necessary.
   */
  public void edit_importElements(String file, List<ImportedElements> elements, int offset, ImportElementsConsumer consumer);

  /**
   * {@code edit.isPostfixCompletionApplicable}
   *
   * Determine if the request postfix completion template is applicable at the given location in the
   * given file.
   *
   * @param file The file containing the postfix template to be expanded.
   * @param key The unique name that identifies the template in use.
   * @param offset The offset used to identify the code to which the template will be applied.
   */
  public void edit_isPostfixCompletionApplicable(String file, String key, int offset, IsPostfixCompletionApplicableConsumer consumer);

  /**
   * {@code edit.listPostfixCompletionTemplates}
   *
   * Return a list of all postfix templates currently available.
   */
  public void edit_listPostfixCompletionTemplates(ListPostfixCompletionTemplatesConsumer consumer);

  /**
   * {@code edit.organizeDirectives}
   *
   * Organizes all of the directives - removes unused imports and sorts directives of the given Dart
   * file according to the Dart Style Guide.
   *
   * If a request is made for a file that does not exist, does not belong to an analysis root or is
   * not a Dart file, FILE_NOT_ANALYZED will be generated.
   *
   * If directives of the Dart file cannot be organized, for example because it has scan or parse
   * errors, or by other reasons, ORGANIZE_DIRECTIVES_ERROR will be generated. The message will
   * provide details about the reason.
   *
   * @param file The Dart file to organize directives in.
   */
  public void edit_organizeDirectives(String file, OrganizeDirectivesConsumer consumer);

  /**
   * {@code edit.sortMembers}
   *
   * Sort all of the directives, unit and class members of the given Dart file.
   *
   * If a request is made for a file that does not exist, does not belong to an analysis root or is
   * not a Dart file, SORT_MEMBERS_INVALID_FILE will be generated.
   *
   * If the Dart file has scan or parse errors, SORT_MEMBERS_PARSE_ERRORS will be generated.
   *
   * @param file The Dart file to sort.
   */
  public void edit_sortMembers(String file, SortMembersConsumer consumer);

  /**
   * {@code execution.createContext}
   *
   * Create an execution context for the executable file with the given path. The context that is
   * created will persist until execution.deleteContext is used to delete it. Clients, therefore, are
   * responsible for managing the lifetime of execution contexts.
   *
   * @param contextRoot The path of the Dart or HTML file that will be launched, or the path of the
   *         directory containing the file.
   */
  public void execution_createContext(String contextRoot, CreateContextConsumer consumer);

  /**
   * {@code execution.deleteContext}
   *
   * Delete the execution context with the given identifier. The context id is no longer valid after
   * this command. The server is allowed to re-use ids when they are no longer valid.
   *
   * @param id The identifier of the execution context that is to be deleted.
   */
  public void execution_deleteContext(String id);

  /**
   * {@code execution.getSuggestions}
   *
   * Request completion suggestions for the given runtime context.
   *
   * It might take one or two requests of this type to get completion suggestions. The first request
   * should have only "code", "offset", and "variables", but not "expressions". If there are
   * sub-expressions that can have different runtime types, and are considered to be safe to evaluate
   * at runtime (e.g. getters), so using their actual runtime types can improve completion results,
   * the server will not include the "suggestions" field in the response, and instead will return the
   * "expressions" field. The client will use debug API to get current runtime types for these
   * sub-expressions and send another request, this time with "expressions". If there are no
   * interesting sub-expressions to get runtime types for, or when the "expressions" field is
   * provided by the client, the server will return "suggestions" in the response.
   *
   * @param code The code to get suggestions in.
   * @param offset The offset within the code to get suggestions at.
   * @param contextFile The path of the context file, e.g. the file of the current debugger frame.
   *         The combination of the context file and context offset can be used to ensure that all
   *         variables of the context are available for completion (with their static types).
   * @param contextOffset The offset in the context file, e.g. the line offset in the current
   *         debugger frame.
   * @param variables The runtime context variables that are potentially referenced in the code.
   * @param expressions The list of sub-expressions in the code for which the client wants to provide
   *         runtime types. It does not have to be the full list of expressions requested by the
   *         server, for missing expressions their static types will be used. When this field is
   *         omitted, the server will return completion suggestions only when there are no
   *         interesting sub-expressions in the given code. The client may provide an empty list, in
   *         this case the server will return completion suggestions.
   */
  public void execution_getSuggestions(String code, int offset, String contextFile, int contextOffset, List<RuntimeCompletionVariable> variables, List<RuntimeCompletionExpression> expressions, GetSuggestionsConsumer consumer);

  /**
   * {@code execution.mapUri}
   *
   * Map a URI from the execution context to the file that it corresponds to, or map a file to the
   * URI that it corresponds to in the execution context.
   *
   * Exactly one of the file and uri fields must be provided. If both fields are provided, then an
   * error of type INVALID_PARAMETER will be generated. Similarly, if neither field is provided, then
   * an error of type INVALID_PARAMETER will be generated.
   *
   * If the file field is provided and the value is not the path of a file (either the file does not
   * exist or the path references something other than a file), then an error of type
   * INVALID_PARAMETER will be generated.
   *
   * If the uri field is provided and the value is not a valid URI or if the URI references something
   * that is not a file (either a file that does not exist or something other than a file), then an
   * error of type INVALID_PARAMETER will be generated.
   *
   * If the contextRoot used to create the execution context does not exist, then an error of type
   * INVALID_EXECUTION_CONTEXT will be generated.
   *
   * @param id The identifier of the execution context in which the URI is to be mapped.
   * @param file The path of the file to be mapped into a URI.
   * @param uri The URI to be mapped into a file path.
   */
  public void execution_mapUri(String id, String file, String uri, MapUriConsumer consumer);

  /**
   * {@code execution.setSubscriptions}
   *
   * Deprecated: the analysis server no longer fires LAUNCH_DATA events.
   *
   * Subscribe for services. All previous subscriptions are replaced by the given set of services.
   *
   * It is an error if any of the elements in the list are not valid services. If there is an error,
   * then the current subscriptions will remain unchanged.
   *
   * @param subscriptions A list of the services being subscribed to.
   *
   * @deprecated
   */
  public void execution_setSubscriptions(List<String> subscriptions);

  /**
   * {@code flutter.getWidgetDescription}
   *
   * Return the description of the widget instance at the given location.
   *
   * If the location does not have a support widget, an error of type
   * FLUTTER_GET_WIDGET_DESCRIPTION_NO_WIDGET will be generated.
   *
   * If a change to a file happens while widget descriptions are computed, an error of type
   * FLUTTER_GET_WIDGET_DESCRIPTION_CONTENT_MODIFIED will be generated.
   *
   * @param file The file where the widget instance is created.
   * @param offset The offset in the file where the widget instance is created.
   */
  public void flutter_getWidgetDescription(String file, int offset, GetWidgetDescriptionConsumer consumer);

  /**
   * {@code flutter.setSubscriptions}
   *
   * Subscribe for services that are specific to individual files. All previous subscriptions are
   * replaced by the current set of subscriptions. If a given service is not included as a key in the
   * map then no files will be subscribed to the service, exactly as if the service had been included
   * in the map with an explicit empty list of files.
   *
   * Note that this request determines the set of requested subscriptions. The actual set of
   * subscriptions at any given time is the intersection of this set with the set of files currently
   * subject to analysis. The files currently subject to analysis are the set of files contained
   * within an actual analysis root but not excluded, plus all of the files transitively reachable
   * from those files via import, export and part directives. (See analysis.setAnalysisRoots for an
   * explanation of how the actual analysis roots are determined.) When the actual analysis roots
   * change, the actual set of subscriptions is automatically updated, but the set of requested
   * subscriptions is unchanged.
   *
   * If a requested subscription is a directory it is ignored, but remains in the set of requested
   * subscriptions so that if it later becomes a file it can be included in the set of actual
   * subscriptions.
   *
   * It is an error if any of the keys in the map are not valid services. If there is an error, then
   * the existing subscriptions will remain unchanged.
   *
   * @param subscriptions A table mapping services to a list of the files being subscribed to the
   *         service.
   */
  public void flutter_setSubscriptions(Map<String, List<String>> subscriptions);

  /**
   * {@code flutter.setWidgetPropertyValue}
   *
   * Set the value of a property, or remove it.
   *
   * The server will generate a change that the client should apply to the project to get the value
   * of the property set to the new value. The complexity of the change might be from updating a
   * single literal value in the code, to updating multiple files to get libraries imported, and new
   * intermediate widgets instantiated.
   *
   * @param id The identifier of the property, previously returned as a part of a
   *         FlutterWidgetProperty. An error of type FLUTTER_SET_WIDGET_PROPERTY_VALUE_INVALID_ID is
   *         generated if the identifier is not valid.
   * @param value The new value to set for the property. If absent, indicates that the property
   *         should be removed. If the property corresponds to an optional parameter, the
   *         corresponding named argument is removed. If the property isRequired is true,
   *         FLUTTER_SET_WIDGET_PROPERTY_VALUE_IS_REQUIRED error is generated. If the expression is
   *         not a syntactically valid Dart code, then
   *         FLUTTER_SET_WIDGET_PROPERTY_VALUE_INVALID_EXPRESSION is reported.
   */
  public void flutter_setWidgetPropertyValue(int id, FlutterWidgetPropertyValue value, SetWidgetPropertyValueConsumer consumer);

  /**
   * Return {@code true} if the socket is open.
   */
  public boolean isSocketOpen();

  /**
   * {@code kythe.getKytheEntries}
   *
   * Return the list of KytheEntry objects for some file, given the current state of the file system
   * populated by "analysis.updateContent".
   *
   * If a request is made for a file that does not exist, or that is not currently subject to
   * analysis (e.g. because it is not associated with any analysis root specified to
   * analysis.setAnalysisRoots), an error of type GET_KYTHE_ENTRIES_INVALID_FILE will be generated.
   *
   * @param file The file containing the code for which the Kythe Entry objects are being requested.
   */
  public void kythe_getKytheEntries(String file, GetKytheEntriesConsumer consumer);

  /**
   * Remove the given listener from the list of listeners that will receive notification when new
     * analysis results become available.
   *
   * @param listener the listener to be removed
   */
  public void removeAnalysisServerListener(AnalysisServerListener listener);

  /**
   * Remove the given listener from the list of listeners that will receive notification when
     * requests are made by an analysis server client.
   *
   * @param listener the listener to be removed
   */
  public void removeRequestListener(RequestListener listener);

  /**
   * Remove the given listener from the list of listeners that will receive notification when
     * responses are received by an analysis server client.
   *
   * @param listener the listener to be removed
   */
  public void removeResponseListener(ResponseListener listener);

  /**
   * {@code search.findElementReferences}
   *
   * Perform a search for references to the element defined or referenced at the given offset in the
   * given file.
   *
   * An identifier is returned immediately, and individual results will be returned via the
   * search.results notification as they become available.
   *
   * @param file The file containing the declaration of or reference to the element used to define
   *         the search.
   * @param offset The offset within the file of the declaration of or reference to the element.
   * @param includePotential True if potential matches are to be included in the results.
   */
  public void search_findElementReferences(String file, int offset, boolean includePotential, FindElementReferencesConsumer consumer);

  /**
   * {@code search.findMemberDeclarations}
   *
   * Perform a search for declarations of members whose name is equal to the given name.
   *
   * An identifier is returned immediately, and individual results will be returned via the
   * search.results notification as they become available.
   *
   * @param name The name of the declarations to be found.
   */
  public void search_findMemberDeclarations(String name, FindMemberDeclarationsConsumer consumer);

  /**
   * {@code search.findMemberReferences}
   *
   * Perform a search for references to members whose name is equal to the given name. This search
   * does not check to see that there is a member defined with the given name, so it is able to find
   * references to undefined members as well.
   *
   * An identifier is returned immediately, and individual results will be returned via the
   * search.results notification as they become available.
   *
   * @param name The name of the references to be found.
   */
  public void search_findMemberReferences(String name, FindMemberReferencesConsumer consumer);

  /**
   * {@code search.findTopLevelDeclarations}
   *
   * Perform a search for declarations of top-level elements (classes, typedefs, getters, setters,
   * functions and fields) whose name matches the given pattern.
   *
   * An identifier is returned immediately, and individual results will be returned via the
   * search.results notification as they become available.
   *
   * @param pattern The regular expression used to match the names of the declarations to be found.
   */
  public void search_findTopLevelDeclarations(String pattern, FindTopLevelDeclarationsConsumer consumer);

  /**
   * {@code search.getElementDeclarations}
   *
   * Return top-level and class member declarations.
   *
   * @param file If this field is provided, return only declarations in this file. If this field is
   *         missing, return declarations in all files.
   * @param pattern The regular expression used to match the names of declarations. If this field is
   *         missing, return all declarations.
   * @param maxResults The maximum number of declarations to return. If this field is missing, return
   *         all matching declarations.
   */
  public void search_getElementDeclarations(String file, String pattern, int maxResults, GetElementDeclarationsConsumer consumer);

  /**
   * {@code search.getTypeHierarchy}
   *
   * Return the type hierarchy of the class declared or referenced at the given location.
   *
   * @param file The file containing the declaration or reference to the type for which a hierarchy
   *         is being requested.
   * @param offset The offset of the name of the type within the file.
   * @param superOnly True if the client is only requesting superclasses and interfaces hierarchy.
   */
  public void search_getTypeHierarchy(String file, int offset, boolean superOnly, GetTypeHierarchyConsumer consumer);

  /**
   * {@code server.getVersion}
   *
   * Return the version number of the analysis server.
   */
  public void server_getVersion(GetVersionConsumer consumer);

  /**
   * {@code server.setSubscriptions}
   *
   * Subscribe for services. All previous subscriptions are replaced by the given set of services.
   *
   * It is an error if any of the elements in the list are not valid services. If there is an error,
   * then the current subscriptions will remain unchanged.
   *
   * @param subscriptions A list of the services being subscribed to.
   */
  public void server_setSubscriptions(List<String> subscriptions);

  /**
   * {@code server.shutdown}
   *
   * Cleanly shutdown the analysis server. Requests that are received after this request will not be
   * processed. Requests that were received before this request, but for which a response has not yet
   * been sent, will not be responded to. No further responses or notifications will be sent after
   * the response to this request has been sent.
   */
  public void server_shutdown();

  /**
   * Start the analysis server.
   */
  public void start() throws Exception;

}
