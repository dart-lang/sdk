// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This file has been automatically generated.  Please do not edit it manually.
// To regenerate the file, use the script
// "pkg/analysis_server/tool/spec/generate_files".

/**
 * Convenience methods for running integration tests
 */
import 'dart:async';

import 'package:analyzer_plugin/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/src/protocol/protocol_internal.dart';
import 'package:test/test.dart';

import 'integration_tests.dart';
import 'protocol_matchers.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';

/**
 * Convenience methods for running integration tests
 */
abstract class IntegrationTestMixin {
  Server get server;

  /**
   * Used to request that the plugin perform a version check to confirm that it
   * works with the version of the analysis server that is executing it.
   *
   * Parameters
   *
   * byteStorePath: FilePath
   *
   *   The path to the directory containing the on-disk byte store that is to
   *   be used by any analysis drivers that are created.
   *
   * sdkPath: FilePath
   *
   *   The path to the directory containing the SDK that is to be used by any
   *   analysis drivers that are created.
   *
   * version: String
   *
   *   The version number of the plugin spec supported by the analysis server
   *   that is executing the plugin.
   *
   * Returns
   *
   * isCompatible: bool
   *
   *   A flag indicating whether the plugin supports the same version of the
   *   plugin spec as the analysis server. If the value is false, then the
   *   plugin is expected to shutdown after returning the response.
   *
   * name: String
   *
   *   The name of the plugin. This value is only used when the server needs to
   *   identify the plugin, either to the user or for debugging purposes.
   *
   * version: String
   *
   *   The version of the plugin. This value is only used when the server needs
   *   to identify the plugin, either to the user or for debugging purposes.
   *
   * contactInfo: String (optional)
   *
   *   Information that the user can use to use to contact the maintainers of
   *   the plugin when there is a problem.
   *
   * interestingFiles: List<String>
   *
   *   The glob patterns of the files for which the plugin will provide
   *   information. This value is ignored if the isCompatible field is false.
   *   Otherwise, it will be used to identify the files for which the plugin
   *   should be notified of changes.
   */
  Future<PluginVersionCheckResult> sendPluginVersionCheck(
      String byteStorePath, String sdkPath, String version) async {
    var params =
        new PluginVersionCheckParams(byteStorePath, sdkPath, version).toJson();
    var result = await server.send("plugin.versionCheck", params);
    ResponseDecoder decoder = new ResponseDecoder(null);
    return new PluginVersionCheckResult.fromJson(decoder, 'result', result);
  }

  /**
   * Used to request that the plugin exit. The server will not send any other
   * requests after this request. The plugin should not send any responses or
   * notifications after sending the response to this request.
   */
  Future sendPluginShutdown() async {
    var result = await server.send("plugin.shutdown", null);
    outOfTestExpect(result, isNull);
    return null;
  }

  /**
   * Used to report that an unexpected error has occurred while executing the
   * plugin. This notification is not used for problems with specific requests
   * (which should be returned as part of the response) but is used for
   * exceptions that occur while performing other tasks, such as analysis or
   * preparing notifications.
   *
   * Parameters
   *
   * isFatal: bool
   *
   *   A flag indicating whether the error is a fatal error, meaning that the
   *   plugin will shutdown automatically after sending this notification. If
   *   true, the server will not expect any other responses or notifications
   *   from the plugin.
   *
   * message: String
   *
   *   The error message indicating what kind of error was encountered.
   *
   * stackTrace: String
   *
   *   The stack trace associated with the generation of the error, used for
   *   debugging the plugin.
   */
  Stream<PluginErrorParams> onPluginError;

  /**
   * Stream controller for [onPluginError].
   */
  StreamController<PluginErrorParams> _onPluginError;

  /**
   * Return the navigation information associated with the given region of the
   * given file. If the navigation information for the given file has not yet
   * been computed, or the most recently computed navigation information for
   * the given file is out of date, then the response for this request will be
   * delayed until it has been computed. If the content of the file changes
   * after this request was received but before a response could be sent, then
   * an error of type CONTENT_MODIFIED will be generated.
   *
   * If a navigation region overlaps (but extends either before or after) the
   * given region of the file it will be included in the result. This means
   * that it is theoretically possible to get the same navigation region in
   * response to multiple requests. Clients can avoid this by always choosing a
   * region that starts at the beginning of a line and ends at the end of a
   * (possibly different) line in the file.
   *
   * Parameters
   *
   * file: FilePath
   *
   *   The file in which navigation information is being requested.
   *
   * offset: int
   *
   *   The offset of the region for which navigation information is being
   *   requested.
   *
   * length: int
   *
   *   The length of the region for which navigation information is being
   *   requested.
   *
   * Returns
   *
   * files: List<FilePath>
   *
   *   A list of the paths of files that are referenced by the navigation
   *   targets.
   *
   * targets: List<NavigationTarget>
   *
   *   A list of the navigation targets that are referenced by the navigation
   *   regions.
   *
   * regions: List<NavigationRegion>
   *
   *   A list of the navigation regions within the requested region of the
   *   file.
   */
  Future<AnalysisGetNavigationResult> sendAnalysisGetNavigation(
      String file, int offset, int length) async {
    var params = new AnalysisGetNavigationParams(file, offset, length).toJson();
    var result = await server.send("analysis.getNavigation", params);
    ResponseDecoder decoder = new ResponseDecoder(null);
    return new AnalysisGetNavigationResult.fromJson(decoder, 'result', result);
  }

  /**
   * Used to inform the plugin of changes to files in the file system. Only
   * events associated with files that match the interestingFiles glob patterns
   * will be forwarded to the plugin.
   *
   * Parameters
   *
   * events: List<WatchEvent>
   *
   *   The watch events that the plugin should handle.
   */
  Future sendAnalysisHandleWatchEvents(List<WatchEvent> events) async {
    var params = new AnalysisHandleWatchEventsParams(events).toJson();
    var result = await server.send("analysis.handleWatchEvents", params);
    outOfTestExpect(result, isNull);
    return null;
  }

  /**
   * Set the list of context roots that should be analyzed.
   *
   * Parameters
   *
   * roots: List<ContextRoot>
   *
   *   A list of the context roots that should be analyzed.
   */
  Future sendAnalysisSetContextRoots(List<ContextRoot> roots) async {
    var params = new AnalysisSetContextRootsParams(roots).toJson();
    var result = await server.send("analysis.setContextRoots", params);
    outOfTestExpect(result, isNull);
    return null;
  }

  /**
   * Used to set the priority files to the files in the given list. A priority
   * file is a file that should be given priority when scheduling which
   * analysis work to do first. The list typically contains those files that
   * are visible to the user and those for which analysis results will have the
   * biggest impact on the user experience. The order of the files within the
   * list is significant: the first file will be given higher priority than the
   * second, the second higher priority than the third, and so on.
   *
   * Parameters
   *
   * files: List<FilePath>
   *
   *   The files that are to be a priority for analysis.
   */
  Future sendAnalysisSetPriorityFiles(List<String> files) async {
    var params = new AnalysisSetPriorityFilesParams(files).toJson();
    var result = await server.send("analysis.setPriorityFiles", params);
    outOfTestExpect(result, isNull);
    return null;
  }

  /**
   * Used to subscribe for services that are specific to individual files. All
   * previous subscriptions should be replaced by the current set of
   * subscriptions. If a given service is not included as a key in the map then
   * no files should be subscribed to the service, exactly as if the service
   * had been included in the map with an explicit empty list of files.
   *
   * Parameters
   *
   * subscriptions: Map<AnalysisService, List<FilePath>>
   *
   *   A table mapping services to a list of the files being subscribed to the
   *   service.
   */
  Future sendAnalysisSetSubscriptions(
      Map<AnalysisService, List<String>> subscriptions) async {
    var params = new AnalysisSetSubscriptionsParams(subscriptions).toJson();
    var result = await server.send("analysis.setSubscriptions", params);
    outOfTestExpect(result, isNull);
    return null;
  }

  /**
   * Used to update the content of one or more files. Files that were
   * previously updated but not included in this update remain unchanged. This
   * effectively represents an overlay of the filesystem. The files whose
   * content is overridden are therefore seen by the plugin as being files with
   * the given content, even if the files do not exist on the filesystem or if
   * the file path represents the path to a directory on the filesystem.
   *
   * Parameters
   *
   * files: Map<FilePath, AddContentOverlay | ChangeContentOverlay |
   * RemoveContentOverlay>
   *
   *   A table mapping the files whose content has changed to a description of
   *   the content change.
   */
  Future sendAnalysisUpdateContent(Map<String, dynamic> files) async {
    var params = new AnalysisUpdateContentParams(files).toJson();
    var result = await server.send("analysis.updateContent", params);
    outOfTestExpect(result, isNull);
    return null;
  }

  /**
   * Used to report the errors associated with a given file. The set of errors
   * included in the notification is always a complete list that supersedes any
   * previously reported errors.
   *
   * Parameters
   *
   * file: FilePath
   *
   *   The file containing the errors.
   *
   * errors: List<AnalysisError>
   *
   *   The errors contained in the file.
   */
  Stream<AnalysisErrorsParams> onAnalysisErrors;

  /**
   * Stream controller for [onAnalysisErrors].
   */
  StreamController<AnalysisErrorsParams> _onAnalysisErrors;

  /**
   * Used to report the folding regions associated with a given file. Folding
   * regions can be nested, but cannot be overlapping. Nesting occurs when a
   * foldable element, such as a method, is nested inside another foldable
   * element such as a class.
   *
   * Folding regions that overlap a folding region computed by the server, or
   * by one of the other plugins that are currently running, might be dropped
   * by the server in order to present a consistent view to the client.
   *
   * This notification should only be sent if the server has subscribed to it
   * by including the value "FOLDING" in the list of services passed in an
   * analysis.setSubscriptions request.
   *
   * Parameters
   *
   * file: FilePath
   *
   *   The file containing the folding regions.
   *
   * regions: List<FoldingRegion>
   *
   *   The folding regions contained in the file.
   */
  Stream<AnalysisFoldingParams> onAnalysisFolding;

  /**
   * Stream controller for [onAnalysisFolding].
   */
  StreamController<AnalysisFoldingParams> _onAnalysisFolding;

  /**
   * Used to report the highlight regions associated with a given file. Each
   * highlight region represents a particular syntactic or semantic meaning
   * associated with some range. Note that the highlight regions that are
   * returned can overlap other highlight regions if there is more than one
   * meaning associated with a particular region.
   *
   * This notification should only be sent if the server has subscribed to it
   * by including the value "HIGHLIGHTS" in the list of services passed in an
   * analysis.setSubscriptions request.
   *
   * Parameters
   *
   * file: FilePath
   *
   *   The file containing the highlight regions.
   *
   * regions: List<HighlightRegion>
   *
   *   The highlight regions contained in the file.
   */
  Stream<AnalysisHighlightsParams> onAnalysisHighlights;

  /**
   * Stream controller for [onAnalysisHighlights].
   */
  StreamController<AnalysisHighlightsParams> _onAnalysisHighlights;

  /**
   * Used to report the navigation regions associated with a given file. Each
   * navigation region represents a list of targets associated with some range.
   * The lists will usually contain a single target, but can contain more in
   * the case of a part that is included in multiple libraries or in Dart code
   * that is compiled against multiple versions of a package. Note that the
   * navigation regions that are returned should not overlap other navigation
   * regions.
   *
   * Navigation regions that overlap a navigation region computed by the
   * server, or by one of the other plugins that are currently running, might
   * be dropped or modified by the server in order to present a consistent view
   * to the client.
   *
   * This notification should only be sent if the server has subscribed to it
   * by including the value "NAVIGATION" in the list of services passed in an
   * analysis.setSubscriptions request.
   *
   * Parameters
   *
   * file: FilePath
   *
   *   The file containing the navigation regions.
   *
   * regions: List<NavigationRegion>
   *
   *   The navigation regions contained in the file.
   *
   * targets: List<NavigationTarget>
   *
   *   The navigation targets referenced in the file. They are referenced by
   *   NavigationRegions by their index in this array.
   *
   * files: List<FilePath>
   *
   *   The files containing navigation targets referenced in the file. They are
   *   referenced by NavigationTargets by their index in this array.
   */
  Stream<AnalysisNavigationParams> onAnalysisNavigation;

  /**
   * Stream controller for [onAnalysisNavigation].
   */
  StreamController<AnalysisNavigationParams> _onAnalysisNavigation;

  /**
   * Used to report the occurrences of references to elements within a single
   * file. None of the occurrence regions should overlap.
   *
   * Occurrence regions that overlap an occurrence region computed by the
   * server, or by one of the other plugins that are currently running, might
   * be dropped or modified by the server in order to present a consistent view
   * to the client.
   *
   * This notification should only be sent if the server has subscribed to it
   * by including the value "OCCURRENCES" in the list of services passed in an
   * analysis.setSubscriptions request.
   *
   * Parameters
   *
   * file: FilePath
   *
   *   The file in which the references occur.
   *
   * occurrences: List<Occurrences>
   *
   *   The occurrences of references to elements within the file.
   */
  Stream<AnalysisOccurrencesParams> onAnalysisOccurrences;

  /**
   * Stream controller for [onAnalysisOccurrences].
   */
  StreamController<AnalysisOccurrencesParams> _onAnalysisOccurrences;

  /**
   * Used to report the outline fragments associated with a single file.
   *
   * The outline fragments will be merged with any outline produced by the
   * server and with any fragments produced by other plugins. If the server
   * cannot create a coherent outline, some fragments might be dropped.
   *
   * This notification should only be sent if the server has subscribed to it
   * by including the value "OUTLINE" in the list of services passed in an
   * analysis.setSubscriptions request.
   *
   * Parameters
   *
   * file: FilePath
   *
   *   The file with which the outline is associated.
   *
   * outline: List<Outline>
   *
   *   The outline fragments associated with the file.
   */
  Stream<AnalysisOutlineParams> onAnalysisOutline;

  /**
   * Stream controller for [onAnalysisOutline].
   */
  StreamController<AnalysisOutlineParams> _onAnalysisOutline;

  /**
   * Used to request that completion suggestions for the given offset in the
   * given file be returned.
   *
   * Parameters
   *
   * file: FilePath
   *
   *   The file containing the point at which suggestions are to be made.
   *
   * offset: int
   *
   *   The offset within the file at which suggestions are to be made.
   *
   * Returns
   *
   * replacementOffset: int
   *
   *   The offset of the start of the text to be replaced. This will be
   *   different than the offset used to request the completion suggestions if
   *   there was a portion of an identifier before the original offset. In
   *   particular, the replacementOffset will be the offset of the beginning of
   *   said identifier.
   *
   * replacementLength: int
   *
   *   The length of the text to be replaced if the remainder of the identifier
   *   containing the cursor is to be replaced when the suggestion is applied
   *   (that is, the number of characters in the existing identifier).
   *
   * results: List<CompletionSuggestion>
   *
   *   The completion suggestions being reported. The notification contains all
   *   possible completions at the requested cursor position, even those that
   *   do not match the characters the user has already typed. This allows the
   *   client to respond to further keystrokes from the user without having to
   *   make additional requests.
   */
  Future<CompletionGetSuggestionsResult> sendCompletionGetSuggestions(
      String file, int offset) async {
    var params = new CompletionGetSuggestionsParams(file, offset).toJson();
    var result = await server.send("completion.getSuggestions", params);
    ResponseDecoder decoder = new ResponseDecoder(null);
    return new CompletionGetSuggestionsResult.fromJson(
        decoder, 'result', result);
  }

  /**
   * Used to request the set of assists that are available at the given
   * location. An assist is distinguished from a refactoring primarily by the
   * fact that it affects a single file and does not require user input in
   * order to be performed.
   *
   * Parameters
   *
   * file: FilePath
   *
   *   The file containing the code for which assists are being requested.
   *
   * offset: int
   *
   *   The offset of the code for which assists are being requested.
   *
   * length: int
   *
   *   The length of the code for which assists are being requested.
   *
   * Returns
   *
   * assists: List<PrioritizedSourceChange>
   *
   *   The assists that are available at the given location.
   */
  Future<EditGetAssistsResult> sendEditGetAssists(
      String file, int offset, int length) async {
    var params = new EditGetAssistsParams(file, offset, length).toJson();
    var result = await server.send("edit.getAssists", params);
    ResponseDecoder decoder = new ResponseDecoder(null);
    return new EditGetAssistsResult.fromJson(decoder, 'result', result);
  }

  /**
   * Used to request a list of the kinds of refactorings that are valid for the
   * given selection in the given file.
   *
   * Parameters
   *
   * file: FilePath
   *
   *   The file containing the code on which the refactoring would be based.
   *
   * offset: int
   *
   *   The offset of the code on which the refactoring would be based.
   *
   * length: int
   *
   *   The length of the code on which the refactoring would be based.
   *
   * Returns
   *
   * kinds: List<RefactoringKind>
   *
   *   The kinds of refactorings that are valid for the given selection.
   *
   *   The list of refactoring kinds is currently limited to those defined by
   *   the server API, preventing plugins from adding their own refactorings.
   *   However, plugins can support pre-defined refactorings, such as a rename
   *   refactoring, at locations not supported by server.
   */
  Future<EditGetAvailableRefactoringsResult> sendEditGetAvailableRefactorings(
      String file, int offset, int length) async {
    var params =
        new EditGetAvailableRefactoringsParams(file, offset, length).toJson();
    var result = await server.send("edit.getAvailableRefactorings", params);
    ResponseDecoder decoder = new ResponseDecoder(null);
    return new EditGetAvailableRefactoringsResult.fromJson(
        decoder, 'result', result);
  }

  /**
   * Used to request the set of fixes that are available for the errors at a
   * given offset in a given file.
   *
   * Parameters
   *
   * file: FilePath
   *
   *   The file containing the errors for which fixes are being requested.
   *
   * offset: int
   *
   *   The offset used to select the errors for which fixes will be returned.
   *
   * Returns
   *
   * fixes: List<AnalysisErrorFixes>
   *
   *   The fixes that are available for the errors at the given offset.
   */
  Future<EditGetFixesResult> sendEditGetFixes(String file, int offset) async {
    var params = new EditGetFixesParams(file, offset).toJson();
    var result = await server.send("edit.getFixes", params);
    ResponseDecoder decoder = new ResponseDecoder(null);
    return new EditGetFixesResult.fromJson(decoder, 'result', result);
  }

  /**
   * Used to request the changes required to perform a refactoring.
   *
   * Parameters
   *
   * kind: RefactoringKind
   *
   *   The kind of refactoring to be performed.
   *
   * file: FilePath
   *
   *   The file containing the code involved in the refactoring.
   *
   * offset: int
   *
   *   The offset of the region involved in the refactoring.
   *
   * length: int
   *
   *   The length of the region involved in the refactoring.
   *
   * validateOnly: bool
   *
   *   True if the client is only requesting that the values of the options be
   *   validated and no change be generated.
   *
   * options: RefactoringOptions (optional)
   *
   *   Data used to provide values provided by the user. The structure of the
   *   data is dependent on the kind of refactoring being performed. The data
   *   that is expected is documented in the section titled Refactorings,
   *   labeled as "Options". This field can be omitted if the refactoring does
   *   not require any options or if the values of those options are not known.
   *
   * Returns
   *
   * initialProblems: List<RefactoringProblem>
   *
   *   The initial status of the refactoring, that is, problems related to the
   *   context in which the refactoring is requested. The list should be empty
   *   if there are no known problems.
   *
   * optionsProblems: List<RefactoringProblem>
   *
   *   The options validation status, that is, problems in the given options,
   *   such as light-weight validation of a new name, flags compatibility, etc.
   *   The list should be empty if there are no known problems.
   *
   * finalProblems: List<RefactoringProblem>
   *
   *   The final status of the refactoring, that is, problems identified in the
   *   result of a full, potentially expensive validation and / or change
   *   creation. The list should be empty if there are no known problems.
   *
   * feedback: RefactoringFeedback (optional)
   *
   *   Data used to provide feedback to the user. The structure of the data is
   *   dependent on the kind of refactoring being created. The data that is
   *   returned is documented in the section titled Refactorings, labeled as
   *   "Feedback".
   *
   * change: SourceChange (optional)
   *
   *   The changes that are to be applied to affect the refactoring. This field
   *   can be omitted if there are problems that prevent a set of changes from
   *   being computed, such as having no options specified for a refactoring
   *   that requires them, or if only validation was requested.
   *
   * potentialEdits: List<String> (optional)
   *
   *   The ids of source edits that are not known to be valid. An edit is not
   *   known to be valid if there was insufficient type information for the
   *   plugin to be able to determine whether or not the code needs to be
   *   modified, such as when a member is being renamed and there is a
   *   reference to a member from an unknown type. This field can be omitted if
   *   the change field is omitted or if there are no potential edits for the
   *   refactoring.
   */
  Future<EditGetRefactoringResult> sendEditGetRefactoring(RefactoringKind kind,
      String file, int offset, int length, bool validateOnly,
      {RefactoringOptions options}) async {
    var params = new EditGetRefactoringParams(
            kind, file, offset, length, validateOnly,
            options: options)
        .toJson();
    var result = await server.send("edit.getRefactoring", params);
    ResponseDecoder decoder = new ResponseDecoder(kind);
    return new EditGetRefactoringResult.fromJson(decoder, 'result', result);
  }

  /**
   * Return the list of KytheEntry objects for some file, given the current
   * state of the file system populated by "analysis.updateContent".
   *
   * Parameters
   *
   * file: FilePath
   *
   *   The file containing the code for which the Kythe Entry objects are being
   *   requested.
   *
   * Returns
   *
   * entries: List<KytheEntry>
   *
   *   The list of KytheEntry objects for the queried file.
   *
   * files: List<FilePath>
   *
   *   The set of files paths that were required, but not in the file system,
   *   to give a complete and accurate Kythe graph for the file. This could be
   *   due to a referenced file that does not exist or generated files not
   *   being generated or passed before the call to "getKytheEntries".
   */
  Future<KytheGetKytheEntriesResult> sendKytheGetKytheEntries(
      String file) async {
    var params = new KytheGetKytheEntriesParams(file).toJson();
    var result = await server.send("kythe.getKytheEntries", params);
    ResponseDecoder decoder = new ResponseDecoder(null);
    return new KytheGetKytheEntriesResult.fromJson(decoder, 'result', result);
  }

  /**
   * Initialize the fields in InttestMixin, and ensure that notifications will
   * be handled.
   */
  void initializeInttestMixin() {
    _onPluginError = new StreamController<PluginErrorParams>(sync: true);
    onPluginError = _onPluginError.stream.asBroadcastStream();
    _onAnalysisErrors = new StreamController<AnalysisErrorsParams>(sync: true);
    onAnalysisErrors = _onAnalysisErrors.stream.asBroadcastStream();
    _onAnalysisFolding =
        new StreamController<AnalysisFoldingParams>(sync: true);
    onAnalysisFolding = _onAnalysisFolding.stream.asBroadcastStream();
    _onAnalysisHighlights =
        new StreamController<AnalysisHighlightsParams>(sync: true);
    onAnalysisHighlights = _onAnalysisHighlights.stream.asBroadcastStream();
    _onAnalysisNavigation =
        new StreamController<AnalysisNavigationParams>(sync: true);
    onAnalysisNavigation = _onAnalysisNavigation.stream.asBroadcastStream();
    _onAnalysisOccurrences =
        new StreamController<AnalysisOccurrencesParams>(sync: true);
    onAnalysisOccurrences = _onAnalysisOccurrences.stream.asBroadcastStream();
    _onAnalysisOutline =
        new StreamController<AnalysisOutlineParams>(sync: true);
    onAnalysisOutline = _onAnalysisOutline.stream.asBroadcastStream();
  }

  /**
   * Dispatch the notification named [event], and containing parameters
   * [params], to the appropriate stream.
   */
  void dispatchNotification(String event, params) {
    ResponseDecoder decoder = new ResponseDecoder(null);
    switch (event) {
      case "plugin.error":
        outOfTestExpect(params, isPluginErrorParams);
        _onPluginError
            .add(new PluginErrorParams.fromJson(decoder, 'params', params));
        break;
      case "analysis.errors":
        outOfTestExpect(params, isAnalysisErrorsParams);
        _onAnalysisErrors
            .add(new AnalysisErrorsParams.fromJson(decoder, 'params', params));
        break;
      case "analysis.folding":
        outOfTestExpect(params, isAnalysisFoldingParams);
        _onAnalysisFolding
            .add(new AnalysisFoldingParams.fromJson(decoder, 'params', params));
        break;
      case "analysis.highlights":
        outOfTestExpect(params, isAnalysisHighlightsParams);
        _onAnalysisHighlights.add(
            new AnalysisHighlightsParams.fromJson(decoder, 'params', params));
        break;
      case "analysis.navigation":
        outOfTestExpect(params, isAnalysisNavigationParams);
        _onAnalysisNavigation.add(
            new AnalysisNavigationParams.fromJson(decoder, 'params', params));
        break;
      case "analysis.occurrences":
        outOfTestExpect(params, isAnalysisOccurrencesParams);
        _onAnalysisOccurrences.add(
            new AnalysisOccurrencesParams.fromJson(decoder, 'params', params));
        break;
      case "analysis.outline":
        outOfTestExpect(params, isAnalysisOutlineParams);
        _onAnalysisOutline
            .add(new AnalysisOutlineParams.fromJson(decoder, 'params', params));
        break;
      default:
        fail('Unexpected notification: $event');
        break;
    }
  }
}
