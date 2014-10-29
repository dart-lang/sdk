// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This file has been automatically generated.  Please do not edit it manually.
// To regenerate the file, use the script
// "pkg/analysis_server/tool/spec/generate_files".

/**
 * Convenience methods for running integration tests
 */
library test.integration.methods;

import 'dart:async';

import 'package:analysis_server/src/protocol.dart';
import 'package:unittest/unittest.dart';

import 'integration_tests.dart';
import 'protocol_matchers.dart';


/**
 * Convenience methods for running integration tests
 */
abstract class IntegrationTestMixin {
  Server get server;

  /**
   * Return the version number of the analysis server.
   *
   * Returns
   *
   * version ( String )
   *
   *   The version number of the analysis server.
   */
  Future<ServerGetVersionResult> sendServerGetVersion() {
    return server.send("server.getVersion", null)
        .then((result) {
      ResponseDecoder decoder = new ResponseDecoder(null);
      return new ServerGetVersionResult.fromJson(decoder, 'result', result);
    });
  }

  /**
   * Cleanly shutdown the analysis server. Requests that are received after
   * this request will not be processed. Requests that were received before
   * this request, but for which a response has not yet been sent, will not be
   * responded to. No further responses or notifications will be sent after the
   * response to this request has been sent.
   */
  Future sendServerShutdown() {
    return server.send("server.shutdown", null)
        .then((result) {
      expect(result, isNull);
      return null;
    });
  }

  /**
   * Subscribe for services. All previous subscriptions are replaced by the
   * given set of services.
   *
   * It is an error if any of the elements in the list are not valid services.
   * If there is an error, then the current subscriptions will remain
   * unchanged.
   *
   * Parameters
   *
   * subscriptions ( List<ServerService> )
   *
   *   A list of the services being subscribed to.
   */
  Future sendServerSetSubscriptions(List<ServerService> subscriptions) {
    var params = new ServerSetSubscriptionsParams(subscriptions).toJson();
    return server.send("server.setSubscriptions", params)
        .then((result) {
      expect(result, isNull);
      return null;
    });
  }

  /**
   * Reports that the server is running. This notification is issued once after
   * the server has started running but before any requests are processed to
   * let the client know that it started correctly.
   *
   * It is not possible to subscribe to or unsubscribe from this notification.
   */
  Stream<ServerConnectedParams> onServerConnected;

  /**
   * Stream controller for [onServerConnected].
   */
  StreamController<ServerConnectedParams> _onServerConnected;

  /**
   * Reports that an unexpected error has occurred while executing the server.
   * This notification is not used for problems with specific requests (which
   * are returned as part of the response) but is used for exceptions that
   * occur while performing other tasks, such as analysis or preparing
   * notifications.
   *
   * It is not possible to subscribe to or unsubscribe from this notification.
   *
   * Parameters
   *
   * isFatal ( bool )
   *
   *   True if the error is a fatal error, meaning that the server will
   *   shutdown automatically after sending this notification.
   *
   * message ( String )
   *
   *   The error message indicating what kind of error was encountered.
   *
   * stackTrace ( String )
   *
   *   The stack trace associated with the generation of the error, used for
   *   debugging the server.
   */
  Stream<ServerErrorParams> onServerError;

  /**
   * Stream controller for [onServerError].
   */
  StreamController<ServerErrorParams> _onServerError;

  /**
   * Reports the current status of the server. Parameters are omitted if there
   * has been no change in the status represented by that parameter.
   *
   * This notification is not subscribed to by default. Clients can subscribe
   * by including the value "STATUS" in the list of services passed in a
   * server.setSubscriptions request.
   *
   * Parameters
   *
   * analysis ( optional AnalysisStatus )
   *
   *   The current status of analysis, including whether analysis is being
   *   performed and if so what is being analyzed.
   */
  Stream<ServerStatusParams> onServerStatus;

  /**
   * Stream controller for [onServerStatus].
   */
  StreamController<ServerStatusParams> _onServerStatus;

  /**
   * Return the errors associated with the given file. If the errors for the
   * given file have not yet been computed, or the most recently computed
   * errors for the given file are out of date, then the response for this
   * request will be delayed until they have been computed. If some or all of
   * the errors for the file cannot be computed, then the subset of the errors
   * that can be computed will be returned and the response will contain an
   * error to indicate why the errors could not be computed.
   *
   * This request is intended to be used by clients that cannot asynchronously
   * apply updated error information. Clients that can apply error information
   * as it becomes available should use the information provided by the
   * 'analysis.errors' notification.
   *
   * If a request is made for a file which does not exist, or which is not
   * currently subject to analysis (e.g. because it is not associated with any
   * analysis root specified to analysis.setAnalysisRoots), an error of type
   * GET_ERRORS_INVALID_FILE will be generated.
   *
   * Parameters
   *
   * file ( FilePath )
   *
   *   The file for which errors are being requested.
   *
   * Returns
   *
   * errors ( List<AnalysisError> )
   *
   *   The errors associated with the file.
   */
  Future<AnalysisGetErrorsResult> sendAnalysisGetErrors(String file) {
    var params = new AnalysisGetErrorsParams(file).toJson();
    return server.send("analysis.getErrors", params)
        .then((result) {
      ResponseDecoder decoder = new ResponseDecoder(null);
      return new AnalysisGetErrorsResult.fromJson(decoder, 'result', result);
    });
  }

  /**
   * Return the hover information associate with the given location. If some or
   * all of the hover information is not available at the time this request is
   * processed the information will be omitted from the response.
   *
   * Parameters
   *
   * file ( FilePath )
   *
   *   The file in which hover information is being requested.
   *
   * offset ( int )
   *
   *   The offset for which hover information is being requested.
   *
   * Returns
   *
   * hovers ( List<HoverInformation> )
   *
   *   The hover information associated with the location. The list will be
   *   empty if no information could be determined for the location. The list
   *   can contain multiple items if the file is being analyzed in multiple
   *   contexts in conflicting ways (such as a part that is included in
   *   multiple libraries).
   */
  Future<AnalysisGetHoverResult> sendAnalysisGetHover(String file, int offset) {
    var params = new AnalysisGetHoverParams(file, offset).toJson();
    return server.send("analysis.getHover", params)
        .then((result) {
      ResponseDecoder decoder = new ResponseDecoder(null);
      return new AnalysisGetHoverResult.fromJson(decoder, 'result', result);
    });
  }

  /**
   * Force the re-analysis of everything contained in the existing analysis
   * roots. This will cause all previously computed analysis results to be
   * discarded and recomputed, and will cause all subscribed notifications to
   * be re-sent.
   */
  Future sendAnalysisReanalyze() {
    return server.send("analysis.reanalyze", null)
        .then((result) {
      expect(result, isNull);
      return null;
    });
  }

  /**
   * Sets the root paths used to determine which files to analyze. The set of
   * files to be analyzed are all of the files in one of the root paths that
   * are not also in one of the excluded paths.
   *
   * Note that this request determines the set of requested analysis roots. The
   * actual set of analysis roots at any given time is the intersection of this
   * set with the set of files and directories actually present on the
   * filesystem. When the filesystem changes, the actual set of analysis roots
   * is automatically updated, but the set of requested analysis roots is
   * unchanged. This means that if the client sets an analysis root before the
   * root becomes visible to server in the filesystem, there is no error; once
   * the server sees the root in the filesystem it will start analyzing it.
   * Similarly, server will stop analyzing files that are removed from the file
   * system but they will remain in the set of requested roots.
   *
   * If an included path represents a file, then server will look in the
   * directory containing the file for a pubspec.yaml file. If none is found,
   * then the parents of the directory will be searched until such a file is
   * found or the root of the file system is reached. If such a file is found,
   * it will be used to resolve package: URI’s within the file.
   *
   * Parameters
   *
   * included ( List<FilePath> )
   *
   *   A list of the files and directories that should be analyzed.
   *
   * excluded ( List<FilePath> )
   *
   *   A list of the files and directories within the included directories that
   *   should not be analyzed.
   *
   * packageRoots ( optional Map<FilePath, FilePath> )
   *
   *   A mapping from source directories to target directories that should
   *   override the normal package: URI resolution mechanism. The analyzer will
   *   behave as though each source directory in the map contains a special
   *   pubspec.yaml file which resolves any package: URI to the corresponding
   *   path within the target directory. The effect is the same as specifying
   *   the target directory as a "--package_root" parameter to the Dart VM when
   *   executing any Dart file inside the source directory.
   *
   *   Files in any directories that are not overridden by this mapping have
   *   their package: URI's resolved using the normal pubspec.yaml mechanism.
   *   If this field is absent, or the empty map is specified, that indicates
   *   that the normal pubspec.yaml mechanism should always be used.
   */
  Future sendAnalysisSetAnalysisRoots(List<String> included, List<String> excluded, {Map<String, String> packageRoots}) {
    var params = new AnalysisSetAnalysisRootsParams(included, excluded, packageRoots: packageRoots).toJson();
    return server.send("analysis.setAnalysisRoots", params)
        .then((result) {
      expect(result, isNull);
      return null;
    });
  }

  /**
   * Set the priority files to the files in the given list. A priority file is
   * a file that is given priority when scheduling which analysis work to do
   * first. The list typically contains those files that are visible to the
   * user and those for which analysis results will have the biggest impact on
   * the user experience. The order of the files within the list is
   * significant: the first file will be given higher priority than the second,
   * the second higher priority than the third, and so on.
   *
   * Note that this request determines the set of requested priority files. The
   * actual set of priority files is the intersection of the requested set of
   * priority files with the set of files currently subject to analysis. (See
   * analysis.setSubscriptions for a description of files that are subject to
   * analysis.)
   *
   * If a requested priority file is a directory it is ignored, but remains in
   * the set of requested priority files so that if it later becomes a file it
   * can be included in the set of actual priority files.
   *
   * Parameters
   *
   * files ( List<FilePath> )
   *
   *   The files that are to be a priority for analysis.
   */
  Future sendAnalysisSetPriorityFiles(List<String> files) {
    var params = new AnalysisSetPriorityFilesParams(files).toJson();
    return server.send("analysis.setPriorityFiles", params)
        .then((result) {
      expect(result, isNull);
      return null;
    });
  }

  /**
   * Subscribe for services. All previous subscriptions are replaced by the
   * current set of subscriptions. If a given service is not included as a key
   * in the map then no files will be subscribed to the service, exactly as if
   * the service had been included in the map with an explicit empty list of
   * files.
   *
   * Note that this request determines the set of requested subscriptions. The
   * actual set of subscriptions at any given time is the intersection of this
   * set with the set of files currently subject to analysis. The files
   * currently subject to analysis are the set of files contained within an
   * actual analysis root but not excluded, plus all of the files transitively
   * reachable from those files via import, export and part directives. (See
   * analysis.setAnalysisRoots for an explanation of how the actual analysis
   * roots are determined.) When the actual analysis roots change, the actual
   * set of subscriptions is automatically updated, but the set of requested
   * subscriptions is unchanged.
   *
   * If a requested subscription is a directory it is ignored, but remains in
   * the set of requested subscriptions so that if it later becomes a file it
   * can be included in the set of actual subscriptions.
   *
   * It is an error if any of the keys in the map are not valid services. If
   * there is an error, then the existing subscriptions will remain unchanged.
   *
   * Parameters
   *
   * subscriptions ( Map<AnalysisService, List<FilePath>> )
   *
   *   A table mapping services to a list of the files being subscribed to the
   *   service.
   */
  Future sendAnalysisSetSubscriptions(Map<AnalysisService, List<String>> subscriptions) {
    var params = new AnalysisSetSubscriptionsParams(subscriptions).toJson();
    return server.send("analysis.setSubscriptions", params)
        .then((result) {
      expect(result, isNull);
      return null;
    });
  }

  /**
   * Update the content of one or more files. Files that were previously
   * updated but not included in this update remain unchanged. This effectively
   * represents an overlay of the filesystem. The files whose content is
   * overridden are therefore seen by server as being files with the given
   * content, even if the files do not exist on the filesystem or if the file
   * path represents the path to a directory on the filesystem.
   *
   * Parameters
   *
   * files ( Map<FilePath, AddContentOverlay | ChangeContentOverlay |
   * RemoveContentOverlay> )
   *
   *   A table mapping the files whose content has changed to a description of
   *   the content change.
   */
  Future sendAnalysisUpdateContent(Map<String, dynamic> files) {
    var params = new AnalysisUpdateContentParams(files).toJson();
    return server.send("analysis.updateContent", params)
        .then((result) {
      expect(result, isNull);
      return null;
    });
  }

  /**
   * Update the options controlling analysis based on the given set of options.
   * Any options that are not included in the analysis options will not be
   * changed. If there are options in the analysis options that are not valid,
   * they will be silently ignored.
   *
   * Parameters
   *
   * options ( AnalysisOptions )
   *
   *   The options that are to be used to control analysis.
   */
  Future sendAnalysisUpdateOptions(AnalysisOptions options) {
    var params = new AnalysisUpdateOptionsParams(options).toJson();
    return server.send("analysis.updateOptions", params)
        .then((result) {
      expect(result, isNull);
      return null;
    });
  }

  /**
   * Reports the errors associated with a given file. The set of errors
   * included in the notification is always a complete list that supersedes any
   * previously reported errors.
   *
   * It is only possible to unsubscribe from this notification by using the
   * command-line flag --no-error-notification.
   *
   * Parameters
   *
   * file ( FilePath )
   *
   *   The file containing the errors.
   *
   * errors ( List<AnalysisError> )
   *
   *   The errors contained in the file.
   */
  Stream<AnalysisErrorsParams> onAnalysisErrors;

  /**
   * Stream controller for [onAnalysisErrors].
   */
  StreamController<AnalysisErrorsParams> _onAnalysisErrors;

  /**
   * Reports that any analysis results that were previously associated with the
   * given files should be considered to be invalid because those files are no
   * longer being analyzed, either because the analysis root that contained it
   * is no longer being analyzed or because the file no longer exists.
   *
   * If a file is included in this notification and at some later time a
   * notification with results for the file is received, clients should assume
   * that the file is once again being analyzed and the information should be
   * processed.
   *
   * It is not possible to subscribe to or unsubscribe from this notification.
   *
   * Parameters
   *
   * files ( List<FilePath> )
   *
   *   The files that are no longer being analyzed.
   */
  Stream<AnalysisFlushResultsParams> onAnalysisFlushResults;

  /**
   * Stream controller for [onAnalysisFlushResults].
   */
  StreamController<AnalysisFlushResultsParams> _onAnalysisFlushResults;

  /**
   * Reports the folding regions associated with a given file. Folding regions
   * can be nested, but will not be overlapping. Nesting occurs when a foldable
   * element, such as a method, is nested inside another foldable element such
   * as a class.
   *
   * This notification is not subscribed to by default. Clients can subscribe
   * by including the value "FOLDING" in the list of services passed in an
   * analysis.setSubscriptions request.
   *
   * Parameters
   *
   * file ( FilePath )
   *
   *   The file containing the folding regions.
   *
   * regions ( List<FoldingRegion> )
   *
   *   The folding regions contained in the file.
   */
  Stream<AnalysisFoldingParams> onAnalysisFolding;

  /**
   * Stream controller for [onAnalysisFolding].
   */
  StreamController<AnalysisFoldingParams> _onAnalysisFolding;

  /**
   * Reports the highlight regions associated with a given file.
   *
   * This notification is not subscribed to by default. Clients can subscribe
   * by including the value "HIGHLIGHTS" in the list of services passed in an
   * analysis.setSubscriptions request.
   *
   * Parameters
   *
   * file ( FilePath )
   *
   *   The file containing the highlight regions.
   *
   * regions ( List<HighlightRegion> )
   *
   *   The highlight regions contained in the file. Each highlight region
   *   represents a particular syntactic or semantic meaning associated with
   *   some range. Note that the highlight regions that are returned can
   *   overlap other highlight regions if there is more than one meaning
   *   associated with a particular region.
   */
  Stream<AnalysisHighlightsParams> onAnalysisHighlights;

  /**
   * Stream controller for [onAnalysisHighlights].
   */
  StreamController<AnalysisHighlightsParams> _onAnalysisHighlights;

  /**
   * Reports the navigation targets associated with a given file.
   *
   * This notification is not subscribed to by default. Clients can subscribe
   * by including the value "NAVIGATION" in the list of services passed in an
   * analysis.setSubscriptions request.
   *
   * Parameters
   *
   * file ( FilePath )
   *
   *   The file containing the navigation regions.
   *
   * regions ( List<NavigationRegion> )
   *
   *   The navigation regions contained in the file. The regions are sorted by
   *   their offsets. Each navigation region represents a list of targets
   *   associated with some range. The lists will usually contain a single
   *   target, but can contain more in the case of a part that is included in
   *   multiple libraries or in Dart code that is compiled against multiple
   *   versions of a package. Note that the navigation regions that are
   *   returned do not overlap other navigation regions.
   */
  Stream<AnalysisNavigationParams> onAnalysisNavigation;

  /**
   * Stream controller for [onAnalysisNavigation].
   */
  StreamController<AnalysisNavigationParams> _onAnalysisNavigation;

  /**
   * Reports the occurrences of references to elements within a single file.
   *
   * This notification is not subscribed to by default. Clients can subscribe
   * by including the value "OCCURRENCES" in the list of services passed in an
   * analysis.setSubscriptions request.
   *
   * Parameters
   *
   * file ( FilePath )
   *
   *   The file in which the references occur.
   *
   * occurrences ( List<Occurrences> )
   *
   *   The occurrences of references to elements within the file.
   */
  Stream<AnalysisOccurrencesParams> onAnalysisOccurrences;

  /**
   * Stream controller for [onAnalysisOccurrences].
   */
  StreamController<AnalysisOccurrencesParams> _onAnalysisOccurrences;

  /**
   * Reports the outline associated with a single file.
   *
   * This notification is not subscribed to by default. Clients can subscribe
   * by including the value "OUTLINE" in the list of services passed in an
   * analysis.setSubscriptions request.
   *
   * Parameters
   *
   * file ( FilePath )
   *
   *   The file with which the outline is associated.
   *
   * outline ( Outline )
   *
   *   The outline associated with the file.
   */
  Stream<AnalysisOutlineParams> onAnalysisOutline;

  /**
   * Stream controller for [onAnalysisOutline].
   */
  StreamController<AnalysisOutlineParams> _onAnalysisOutline;

  /**
   * Reports the overridding members in a file.
   *
   * This notification is not subscribed to by default. Clients can subscribe
   * by including the value "OVERRIDES" in the list of services passed in an
   * analysis.setSubscriptions request.
   *
   * Parameters
   *
   * file ( FilePath )
   *
   *   The file with which the overrides are associated.
   *
   * overrides ( List<Override> )
   *
   *   The overrides associated with the file.
   */
  Stream<AnalysisOverridesParams> onAnalysisOverrides;

  /**
   * Stream controller for [onAnalysisOverrides].
   */
  StreamController<AnalysisOverridesParams> _onAnalysisOverrides;

  /**
   * Request that completion suggestions for the given offset in the given file
   * be returned.
   *
   * Parameters
   *
   * file ( FilePath )
   *
   *   The file containing the point at which suggestions are to be made.
   *
   * offset ( int )
   *
   *   The offset within the file at which suggestions are to be made.
   *
   * Returns
   *
   * id ( CompletionId )
   *
   *   The identifier used to associate results with this completion request.
   */
  Future<CompletionGetSuggestionsResult> sendCompletionGetSuggestions(String file, int offset) {
    var params = new CompletionGetSuggestionsParams(file, offset).toJson();
    return server.send("completion.getSuggestions", params)
        .then((result) {
      ResponseDecoder decoder = new ResponseDecoder(null);
      return new CompletionGetSuggestionsResult.fromJson(decoder, 'result', result);
    });
  }

  /**
   * Reports the completion suggestions that should be presented to the user.
   * The set of suggestions included in the notification is always a complete
   * list that supersedes any previously reported suggestions.
   *
   * Parameters
   *
   * id ( CompletionId )
   *
   *   The id associated with the completion.
   *
   * replacementOffset ( int )
   *
   *   The offset of the start of the text to be replaced. This will be
   *   different than the offset used to request the completion suggestions if
   *   there was a portion of an identifier before the original offset. In
   *   particular, the replacementOffset will be the offset of the beginning of
   *   said identifier.
   *
   * replacementLength ( int )
   *
   *   The length of the text to be replaced if the remainder of the identifier
   *   containing the cursor is to be replaced when the suggestion is applied
   *   (that is, the number of characters in the existing identifier).
   *
   * results ( List<CompletionSuggestion> )
   *
   *   The completion suggestions being reported. The notification contains all
   *   possible completions at the requested cursor position, even those that
   *   do not match the characters the user has already typed. This allows the
   *   client to respond to further keystrokes from the user without having to
   *   make additional requests.
   *
   * isLast ( bool )
   *
   *   True if this is that last set of results that will be returned for the
   *   indicated completion.
   */
  Stream<CompletionResultsParams> onCompletionResults;

  /**
   * Stream controller for [onCompletionResults].
   */
  StreamController<CompletionResultsParams> _onCompletionResults;

  /**
   * Perform a search for references to the element defined or referenced at
   * the given offset in the given file.
   *
   * An identifier is returned immediately, and individual results will be
   * returned via the search.results notification as they become available.
   *
   * Parameters
   *
   * file ( FilePath )
   *
   *   The file containing the declaration of or reference to the element used
   *   to define the search.
   *
   * offset ( int )
   *
   *   The offset within the file of the declaration of or reference to the
   *   element.
   *
   * includePotential ( bool )
   *
   *   True if potential matches are to be included in the results.
   *
   * Returns
   *
   * id ( optional SearchId )
   *
   *   The identifier used to associate results with this search request.
   *
   *   If no element was found at the given location, this field will be
   *   absent, and no results will be reported via the search.results
   *   notification.
   *
   * element ( optional Element )
   *
   *   The element referenced or defined at the given offset and whose
   *   references will be returned in the search results.
   *
   *   If no element was found at the given location, this field will be
   *   absent.
   */
  Future<SearchFindElementReferencesResult> sendSearchFindElementReferences(String file, int offset, bool includePotential) {
    var params = new SearchFindElementReferencesParams(file, offset, includePotential).toJson();
    return server.send("search.findElementReferences", params)
        .then((result) {
      ResponseDecoder decoder = new ResponseDecoder(null);
      return new SearchFindElementReferencesResult.fromJson(decoder, 'result', result);
    });
  }

  /**
   * Perform a search for declarations of members whose name is equal to the
   * given name.
   *
   * An identifier is returned immediately, and individual results will be
   * returned via the search.results notification as they become available.
   *
   * Parameters
   *
   * name ( String )
   *
   *   The name of the declarations to be found.
   *
   * Returns
   *
   * id ( SearchId )
   *
   *   The identifier used to associate results with this search request.
   */
  Future<SearchFindMemberDeclarationsResult> sendSearchFindMemberDeclarations(String name) {
    var params = new SearchFindMemberDeclarationsParams(name).toJson();
    return server.send("search.findMemberDeclarations", params)
        .then((result) {
      ResponseDecoder decoder = new ResponseDecoder(null);
      return new SearchFindMemberDeclarationsResult.fromJson(decoder, 'result', result);
    });
  }

  /**
   * Perform a search for references to members whose name is equal to the
   * given name. This search does not check to see that there is a member
   * defined with the given name, so it is able to find references to undefined
   * members as well.
   *
   * An identifier is returned immediately, and individual results will be
   * returned via the search.results notification as they become available.
   *
   * Parameters
   *
   * name ( String )
   *
   *   The name of the references to be found.
   *
   * Returns
   *
   * id ( SearchId )
   *
   *   The identifier used to associate results with this search request.
   */
  Future<SearchFindMemberReferencesResult> sendSearchFindMemberReferences(String name) {
    var params = new SearchFindMemberReferencesParams(name).toJson();
    return server.send("search.findMemberReferences", params)
        .then((result) {
      ResponseDecoder decoder = new ResponseDecoder(null);
      return new SearchFindMemberReferencesResult.fromJson(decoder, 'result', result);
    });
  }

  /**
   * Perform a search for declarations of top-level elements (classes,
   * typedefs, getters, setters, functions and fields) whose name matches the
   * given pattern.
   *
   * An identifier is returned immediately, and individual results will be
   * returned via the search.results notification as they become available.
   *
   * Parameters
   *
   * pattern ( String )
   *
   *   The regular expression used to match the names of the declarations to be
   *   found.
   *
   * Returns
   *
   * id ( SearchId )
   *
   *   The identifier used to associate results with this search request.
   */
  Future<SearchFindTopLevelDeclarationsResult> sendSearchFindTopLevelDeclarations(String pattern) {
    var params = new SearchFindTopLevelDeclarationsParams(pattern).toJson();
    return server.send("search.findTopLevelDeclarations", params)
        .then((result) {
      ResponseDecoder decoder = new ResponseDecoder(null);
      return new SearchFindTopLevelDeclarationsResult.fromJson(decoder, 'result', result);
    });
  }

  /**
   * Return the type hierarchy of the class declared or referenced at the given
   * location.
   *
   * Parameters
   *
   * file ( FilePath )
   *
   *   The file containing the declaration or reference to the type for which a
   *   hierarchy is being requested.
   *
   * offset ( int )
   *
   *   The offset of the name of the type within the file.
   *
   * Returns
   *
   * hierarchyItems ( optional List<TypeHierarchyItem> )
   *
   *   A list of the types in the requested hierarchy. The first element of the
   *   list is the item representing the type for which the hierarchy was
   *   requested. The index of other elements of the list is unspecified, but
   *   correspond to the integers used to reference supertype and subtype items
   *   within the items.
   *
   *   This field will be absent if the code at the given file and offset does
   *   not represent a type, or if the file has not been sufficiently analyzed
   *   to allow a type hierarchy to be produced.
   */
  Future<SearchGetTypeHierarchyResult> sendSearchGetTypeHierarchy(String file, int offset) {
    var params = new SearchGetTypeHierarchyParams(file, offset).toJson();
    return server.send("search.getTypeHierarchy", params)
        .then((result) {
      ResponseDecoder decoder = new ResponseDecoder(null);
      return new SearchGetTypeHierarchyResult.fromJson(decoder, 'result', result);
    });
  }

  /**
   * Reports some or all of the results of performing a requested search.
   * Unlike other notifications, this notification contains search results that
   * should be added to any previously received search results associated with
   * the same search id.
   *
   * Parameters
   *
   * id ( SearchId )
   *
   *   The id associated with the search.
   *
   * results ( List<SearchResult> )
   *
   *   The search results being reported.
   *
   * isLast ( bool )
   *
   *   True if this is that last set of results that will be returned for the
   *   indicated search.
   */
  Stream<SearchResultsParams> onSearchResults;

  /**
   * Stream controller for [onSearchResults].
   */
  StreamController<SearchResultsParams> _onSearchResults;

  /**
   * Return the set of assists that are available at the given location. An
   * assist is distinguished from a refactoring primarily by the fact that it
   * affects a single file and does not require user input in order to be
   * performed.
   *
   * Parameters
   *
   * file ( FilePath )
   *
   *   The file containing the code for which assists are being requested.
   *
   * offset ( int )
   *
   *   The offset of the code for which assists are being requested.
   *
   * length ( int )
   *
   *   The length of the code for which assists are being requested.
   *
   * Returns
   *
   * assists ( List<SourceChange> )
   *
   *   The assists that are available at the given location.
   */
  Future<EditGetAssistsResult> sendEditGetAssists(String file, int offset, int length) {
    var params = new EditGetAssistsParams(file, offset, length).toJson();
    return server.send("edit.getAssists", params)
        .then((result) {
      ResponseDecoder decoder = new ResponseDecoder(null);
      return new EditGetAssistsResult.fromJson(decoder, 'result', result);
    });
  }

  /**
   * Get a list of the kinds of refactorings that are valid for the given
   * selection in the given file.
   *
   * Parameters
   *
   * file ( FilePath )
   *
   *   The file containing the code on which the refactoring would be based.
   *
   * offset ( int )
   *
   *   The offset of the code on which the refactoring would be based.
   *
   * length ( int )
   *
   *   The length of the code on which the refactoring would be based.
   *
   * Returns
   *
   * kinds ( List<RefactoringKind> )
   *
   *   The kinds of refactorings that are valid for the given selection.
   */
  Future<EditGetAvailableRefactoringsResult> sendEditGetAvailableRefactorings(String file, int offset, int length) {
    var params = new EditGetAvailableRefactoringsParams(file, offset, length).toJson();
    return server.send("edit.getAvailableRefactorings", params)
        .then((result) {
      ResponseDecoder decoder = new ResponseDecoder(null);
      return new EditGetAvailableRefactoringsResult.fromJson(decoder, 'result', result);
    });
  }

  /**
   * Return the set of fixes that are available for the errors at a given
   * offset in a given file.
   *
   * Parameters
   *
   * file ( FilePath )
   *
   *   The file containing the errors for which fixes are being requested.
   *
   * offset ( int )
   *
   *   The offset used to select the errors for which fixes will be returned.
   *
   * Returns
   *
   * fixes ( List<AnalysisErrorFixes> )
   *
   *   The fixes that are available for the errors at the given offset.
   */
  Future<EditGetFixesResult> sendEditGetFixes(String file, int offset) {
    var params = new EditGetFixesParams(file, offset).toJson();
    return server.send("edit.getFixes", params)
        .then((result) {
      ResponseDecoder decoder = new ResponseDecoder(null);
      return new EditGetFixesResult.fromJson(decoder, 'result', result);
    });
  }

  /**
   * Get the changes required to perform a refactoring.
   *
   * Parameters
   *
   * kind ( RefactoringKind )
   *
   *   The kind of refactoring to be performed.
   *
   * file ( FilePath )
   *
   *   The file containing the code involved in the refactoring.
   *
   * offset ( int )
   *
   *   The offset of the region involved in the refactoring.
   *
   * length ( int )
   *
   *   The length of the region involved in the refactoring.
   *
   * validateOnly ( bool )
   *
   *   True if the client is only requesting that the values of the options be
   *   validated and no change be generated.
   *
   * options ( optional RefactoringOptions )
   *
   *   Data used to provide values provided by the user. The structure of the
   *   data is dependent on the kind of refactoring being performed. The data
   *   that is expected is documented in the section titled Refactorings,
   *   labeled as “Options”. This field can be omitted if the refactoring does
   *   not require any options or if the values of those options are not known.
   *
   * Returns
   *
   * initialProblems ( List<RefactoringProblem> )
   *
   *   The initial status of the refactoring, i.e. problems related to the
   *   context in which the refactoring is requested. The array will be empty
   *   if there are no known problems.
   *
   * optionsProblems ( List<RefactoringProblem> )
   *
   *   The options validation status, i.e. problems in the given options, such
   *   as light-weight validation of a new name, flags compatibility, etc. The
   *   array will be empty if there are no known problems.
   *
   * finalProblems ( List<RefactoringProblem> )
   *
   *   The final status of the refactoring, i.e. problems identified in the
   *   result of a full, potentially expensive validation and / or change
   *   creation. The array will be empty if there are no known problems.
   *
   * feedback ( optional RefactoringFeedback )
   *
   *   Data used to provide feedback to the user. The structure of the data is
   *   dependent on the kind of refactoring being created. The data that is
   *   returned is documented in the section titled Refactorings, labeled as
   *   “Feedback”.
   *
   * change ( optional SourceChange )
   *
   *   The changes that are to be applied to affect the refactoring. This field
   *   will be omitted if there are problems that prevent a set of changes from
   *   being computed, such as having no options specified for a refactoring
   *   that requires them, or if only validation was requested.
   *
   * potentialEdits ( optional List<String> )
   *
   *   The ids of source edits that are not known to be valid. An edit is not
   *   known to be valid if there was insufficient type information for the
   *   server to be able to determine whether or not the code needs to be
   *   modified, such as when a member is being renamed and there is a
   *   reference to a member from an unknown type. This field will be omitted
   *   if the change field is omitted or if there are no potential edits for
   *   the refactoring.
   */
  Future<EditGetRefactoringResult> sendEditGetRefactoring(RefactoringKind kind, String file, int offset, int length, bool validateOnly, {RefactoringOptions options}) {
    var params = new EditGetRefactoringParams(kind, file, offset, length, validateOnly, options: options).toJson();
    return server.send("edit.getRefactoring", params)
        .then((result) {
      ResponseDecoder decoder = new ResponseDecoder(kind);
      return new EditGetRefactoringResult.fromJson(decoder, 'result', result);
    });
  }

  /**
   * Sort all of the directives, unit and class members of the given Dart file.
   *
   * If a request is made for a file that does not exist, does not belong to an
   * analysis root or is not a Dart file, SORT_MEMBERS_INVALID_FILE will be
   * generated.
   *
   * If the Dart file has scan or parse errors, SORT_MEMBERS_PARSE_ERRORS will
   * be generated.
   *
   * Parameters
   *
   * file ( FilePath )
   *
   *   The Dart file to sort.
   *
   * Returns
   *
   * edit ( SourceFileEdit )
   *
   *   The file edit that is to be applied to the given file to effect the
   *   sorting.
   */
  Future<EditSortMembersResult> sendEditSortMembers(String file) {
    var params = new EditSortMembersParams(file).toJson();
    return server.send("edit.sortMembers", params)
        .then((result) {
      ResponseDecoder decoder = new ResponseDecoder(null);
      return new EditSortMembersResult.fromJson(decoder, 'result', result);
    });
  }

  /**
   * Create an execution context for the executable file with the given path.
   * The context that is created will persist until execution.deleteContext is
   * used to delete it. Clients, therefore, are responsible for managing the
   * lifetime of execution contexts.
   *
   * Parameters
   *
   * contextRoot ( FilePath )
   *
   *   The path of the Dart or HTML file that will be launched.
   *
   * Returns
   *
   * id ( ExecutionContextId )
   *
   *   The identifier used to refer to the execution context that was created.
   */
  Future<ExecutionCreateContextResult> sendExecutionCreateContext(String contextRoot) {
    var params = new ExecutionCreateContextParams(contextRoot).toJson();
    return server.send("execution.createContext", params)
        .then((result) {
      ResponseDecoder decoder = new ResponseDecoder(null);
      return new ExecutionCreateContextResult.fromJson(decoder, 'result', result);
    });
  }

  /**
   * Delete the execution context with the given identifier. The context id is
   * no longer valid after this command. The server is allowed to re-use ids
   * when they are no longer valid.
   *
   * Parameters
   *
   * id ( ExecutionContextId )
   *
   *   The identifier of the execution context that is to be deleted.
   */
  Future sendExecutionDeleteContext(String id) {
    var params = new ExecutionDeleteContextParams(id).toJson();
    return server.send("execution.deleteContext", params)
        .then((result) {
      expect(result, isNull);
      return null;
    });
  }

  /**
   * Map a URI from the execution context to the file that it corresponds to,
   * or map a file to the URI that it corresponds to in the execution context.
   *
   * Exactly one of the file and uri fields must be provided.
   *
   * Parameters
   *
   * id ( ExecutionContextId )
   *
   *   The identifier of the execution context in which the URI is to be
   *   mapped.
   *
   * file ( optional FilePath )
   *
   *   The path of the file to be mapped into a URI.
   *
   * uri ( optional String )
   *
   *   The URI to be mapped into a file path.
   *
   * Returns
   *
   * file ( optional FilePath )
   *
   *   The file to which the URI was mapped. This field is omitted if the uri
   *   field was not given in the request.
   *
   * uri ( optional String )
   *
   *   The URI to which the file path was mapped. This field is omitted if the
   *   file field was not given in the request.
   */
  Future<ExecutionMapUriResult> sendExecutionMapUri(String id, {String file, String uri}) {
    var params = new ExecutionMapUriParams(id, file: file, uri: uri).toJson();
    return server.send("execution.mapUri", params)
        .then((result) {
      ResponseDecoder decoder = new ResponseDecoder(null);
      return new ExecutionMapUriResult.fromJson(decoder, 'result', result);
    });
  }

  /**
   * Subscribe for services. All previous subscriptions are replaced by the
   * given set of services.
   *
   * It is an error if any of the elements in the list are not valid services.
   * If there is an error, then the current subscriptions will remain
   * unchanged.
   *
   * Parameters
   *
   * subscriptions ( List<ExecutionService> )
   *
   *   A list of the services being subscribed to.
   */
  Future sendExecutionSetSubscriptions(List<ExecutionService> subscriptions) {
    var params = new ExecutionSetSubscriptionsParams(subscriptions).toJson();
    return server.send("execution.setSubscriptions", params)
        .then((result) {
      expect(result, isNull);
      return null;
    });
  }

  /**
   * Reports information needed to allow a single file to be launched.
   *
   * This notification is not subscribed to by default. Clients can subscribe
   * by including the value "LAUNCH_DATA" in the list of services passed in an
   * execution.setSubscriptions request.
   *
   * Parameters
   *
   * file ( FilePath )
   *
   *   The file for which launch data is being provided. This will either be a
   *   Dart library or an HTML file.
   *
   * kind ( optional ExecutableKind )
   *
   *   The kind of the executable file. This field is omitted if the file is
   *   not a Dart file.
   *
   * referencedFiles ( optional List<FilePath> )
   *
   *   A list of the Dart files that are referenced by the file. This field is
   *   omitted if the file is not an HTML file.
   */
  Stream<ExecutionLaunchDataParams> onExecutionLaunchData;

  /**
   * Stream controller for [onExecutionLaunchData].
   */
  StreamController<ExecutionLaunchDataParams> _onExecutionLaunchData;

  /**
   * Initialize the fields in InttestMixin, and ensure that notifications will
   * be handled.
   */
  void initializeInttestMixin() {
    _onServerConnected = new StreamController<ServerConnectedParams>(sync: true);
    onServerConnected = _onServerConnected.stream.asBroadcastStream();
    _onServerError = new StreamController<ServerErrorParams>(sync: true);
    onServerError = _onServerError.stream.asBroadcastStream();
    _onServerStatus = new StreamController<ServerStatusParams>(sync: true);
    onServerStatus = _onServerStatus.stream.asBroadcastStream();
    _onAnalysisErrors = new StreamController<AnalysisErrorsParams>(sync: true);
    onAnalysisErrors = _onAnalysisErrors.stream.asBroadcastStream();
    _onAnalysisFlushResults = new StreamController<AnalysisFlushResultsParams>(sync: true);
    onAnalysisFlushResults = _onAnalysisFlushResults.stream.asBroadcastStream();
    _onAnalysisFolding = new StreamController<AnalysisFoldingParams>(sync: true);
    onAnalysisFolding = _onAnalysisFolding.stream.asBroadcastStream();
    _onAnalysisHighlights = new StreamController<AnalysisHighlightsParams>(sync: true);
    onAnalysisHighlights = _onAnalysisHighlights.stream.asBroadcastStream();
    _onAnalysisNavigation = new StreamController<AnalysisNavigationParams>(sync: true);
    onAnalysisNavigation = _onAnalysisNavigation.stream.asBroadcastStream();
    _onAnalysisOccurrences = new StreamController<AnalysisOccurrencesParams>(sync: true);
    onAnalysisOccurrences = _onAnalysisOccurrences.stream.asBroadcastStream();
    _onAnalysisOutline = new StreamController<AnalysisOutlineParams>(sync: true);
    onAnalysisOutline = _onAnalysisOutline.stream.asBroadcastStream();
    _onAnalysisOverrides = new StreamController<AnalysisOverridesParams>(sync: true);
    onAnalysisOverrides = _onAnalysisOverrides.stream.asBroadcastStream();
    _onCompletionResults = new StreamController<CompletionResultsParams>(sync: true);
    onCompletionResults = _onCompletionResults.stream.asBroadcastStream();
    _onSearchResults = new StreamController<SearchResultsParams>(sync: true);
    onSearchResults = _onSearchResults.stream.asBroadcastStream();
    _onExecutionLaunchData = new StreamController<ExecutionLaunchDataParams>(sync: true);
    onExecutionLaunchData = _onExecutionLaunchData.stream.asBroadcastStream();
  }

  /**
   * Dispatch the notification named [event], and containing parameters
   * [params], to the appropriate stream.
   */
  void dispatchNotification(String event, params) {
    ResponseDecoder decoder = new ResponseDecoder(null);
    switch (event) {
      case "server.connected":
        expect(params, isServerConnectedParams);
        _onServerConnected.add(new ServerConnectedParams());
        break;
      case "server.error":
        expect(params, isServerErrorParams);
        _onServerError.add(new ServerErrorParams.fromJson(decoder, 'params', params));
        break;
      case "server.status":
        expect(params, isServerStatusParams);
        _onServerStatus.add(new ServerStatusParams.fromJson(decoder, 'params', params));
        break;
      case "analysis.errors":
        expect(params, isAnalysisErrorsParams);
        _onAnalysisErrors.add(new AnalysisErrorsParams.fromJson(decoder, 'params', params));
        break;
      case "analysis.flushResults":
        expect(params, isAnalysisFlushResultsParams);
        _onAnalysisFlushResults.add(new AnalysisFlushResultsParams.fromJson(decoder, 'params', params));
        break;
      case "analysis.folding":
        expect(params, isAnalysisFoldingParams);
        _onAnalysisFolding.add(new AnalysisFoldingParams.fromJson(decoder, 'params', params));
        break;
      case "analysis.highlights":
        expect(params, isAnalysisHighlightsParams);
        _onAnalysisHighlights.add(new AnalysisHighlightsParams.fromJson(decoder, 'params', params));
        break;
      case "analysis.navigation":
        expect(params, isAnalysisNavigationParams);
        _onAnalysisNavigation.add(new AnalysisNavigationParams.fromJson(decoder, 'params', params));
        break;
      case "analysis.occurrences":
        expect(params, isAnalysisOccurrencesParams);
        _onAnalysisOccurrences.add(new AnalysisOccurrencesParams.fromJson(decoder, 'params', params));
        break;
      case "analysis.outline":
        expect(params, isAnalysisOutlineParams);
        _onAnalysisOutline.add(new AnalysisOutlineParams.fromJson(decoder, 'params', params));
        break;
      case "analysis.overrides":
        expect(params, isAnalysisOverridesParams);
        _onAnalysisOverrides.add(new AnalysisOverridesParams.fromJson(decoder, 'params', params));
        break;
      case "completion.results":
        expect(params, isCompletionResultsParams);
        _onCompletionResults.add(new CompletionResultsParams.fromJson(decoder, 'params', params));
        break;
      case "search.results":
        expect(params, isSearchResultsParams);
        _onSearchResults.add(new SearchResultsParams.fromJson(decoder, 'params', params));
        break;
      case "execution.launchData":
        expect(params, isExecutionLaunchDataParams);
        _onExecutionLaunchData.add(new ExecutionLaunchDataParams.fromJson(decoder, 'params', params));
        break;
      default:
        fail('Unexpected notification: $event');
        break;
    }
  }
}
