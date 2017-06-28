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

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/protocol/protocol_internal.dart';
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
   * Return the version number of the analysis server.
   *
   * Returns
   *
   * version: String
   *
   *   The version number of the analysis server.
   */
  Future<ServerGetVersionResult> sendServerGetVersion() async {
    var result = await server.send("server.getVersion", null);
    ResponseDecoder decoder = new ResponseDecoder(null);
    return new ServerGetVersionResult.fromJson(decoder, 'result', result);
  }

  /**
   * Cleanly shutdown the analysis server. Requests that are received after
   * this request will not be processed. Requests that were received before
   * this request, but for which a response has not yet been sent, will not be
   * responded to. No further responses or notifications will be sent after the
   * response to this request has been sent.
   */
  Future sendServerShutdown() async {
    var result = await server.send("server.shutdown", null);
    outOfTestExpect(result, isNull);
    return null;
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
   * subscriptions: List<ServerService>
   *
   *   A list of the services being subscribed to.
   */
  Future sendServerSetSubscriptions(List<ServerService> subscriptions) async {
    var params = new ServerSetSubscriptionsParams(subscriptions).toJson();
    var result = await server.send("server.setSubscriptions", params);
    outOfTestExpect(result, isNull);
    return null;
  }

  /**
   * Reports that the server is running. This notification is issued once after
   * the server has started running but before any requests are processed to
   * let the client know that it started correctly.
   *
   * It is not possible to subscribe to or unsubscribe from this notification.
   *
   * Parameters
   *
   * version: String
   *
   *   The version number of the analysis server.
   *
   * pid: int
   *
   *   The process id of the analysis server process.
   *
   * sessionId: String (optional)
   *
   *   The session id for this session.
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
   * isFatal: bool
   *
   *   True if the error is a fatal error, meaning that the server will
   *   shutdown automatically after sending this notification.
   *
   * message: String
   *
   *   The error message indicating what kind of error was encountered.
   *
   * stackTrace: String
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
   * analysis: AnalysisStatus (optional)
   *
   *   The current status of analysis, including whether analysis is being
   *   performed and if so what is being analyzed.
   *
   * pub: PubStatus (optional)
   *
   *   The current status of pub execution, indicating whether we are currently
   *   running pub.
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
   * error to indicate why the errors could not be computed. If the content of
   * the file changes after this request was received but before a response
   * could be sent, then an error of type CONTENT_MODIFIED will be generated.
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
   * file: FilePath
   *
   *   The file for which errors are being requested.
   *
   * Returns
   *
   * errors: List<AnalysisError>
   *
   *   The errors associated with the file.
   */
  Future<AnalysisGetErrorsResult> sendAnalysisGetErrors(String file) async {
    var params = new AnalysisGetErrorsParams(file).toJson();
    var result = await server.send("analysis.getErrors", params);
    ResponseDecoder decoder = new ResponseDecoder(null);
    return new AnalysisGetErrorsResult.fromJson(decoder, 'result', result);
  }

  /**
   * Return the hover information associate with the given location. If some or
   * all of the hover information is not available at the time this request is
   * processed the information will be omitted from the response.
   *
   * Parameters
   *
   * file: FilePath
   *
   *   The file in which hover information is being requested.
   *
   * offset: int
   *
   *   The offset for which hover information is being requested.
   *
   * Returns
   *
   * hovers: List<HoverInformation>
   *
   *   The hover information associated with the location. The list will be
   *   empty if no information could be determined for the location. The list
   *   can contain multiple items if the file is being analyzed in multiple
   *   contexts in conflicting ways (such as a part that is included in
   *   multiple libraries).
   */
  Future<AnalysisGetHoverResult> sendAnalysisGetHover(
      String file, int offset) async {
    var params = new AnalysisGetHoverParams(file, offset).toJson();
    var result = await server.send("analysis.getHover", params);
    ResponseDecoder decoder = new ResponseDecoder(null);
    return new AnalysisGetHoverResult.fromJson(decoder, 'result', result);
  }

  /**
   * Return the transitive closure of reachable sources for a given file.
   *
   * If a request is made for a file which does not exist, or which is not
   * currently subject to analysis (e.g. because it is not associated with any
   * analysis root specified to analysis.setAnalysisRoots), an error of type
   * GET_REACHABLE_SOURCES_INVALID_FILE will be generated.
   *
   * Parameters
   *
   * file: FilePath
   *
   *   The file for which reachable source information is being requested.
   *
   * Returns
   *
   * sources: Map<String, List<String>>
   *
   *   A mapping from source URIs to directly reachable source URIs. For
   *   example, a file "foo.dart" that imports "bar.dart" would have the
   *   corresponding mapping { "file:///foo.dart" : ["file:///bar.dart"] }. If
   *   "bar.dart" has further imports (or exports) there will be a mapping from
   *   the URI "file:///bar.dart" to them. To check if a specific URI is
   *   reachable from a given file, clients can check for its presence in the
   *   resulting key set.
   */
  Future<AnalysisGetReachableSourcesResult> sendAnalysisGetReachableSources(
      String file) async {
    var params = new AnalysisGetReachableSourcesParams(file).toJson();
    var result = await server.send("analysis.getReachableSources", params);
    ResponseDecoder decoder = new ResponseDecoder(null);
    return new AnalysisGetReachableSourcesResult.fromJson(
        decoder, 'result', result);
  }

  /**
   * Return library dependency information for use in client-side indexing and
   * package URI resolution.
   *
   * Clients that are only using the libraries field should consider using the
   * analyzedFiles notification instead.
   *
   * Returns
   *
   * libraries: List<FilePath>
   *
   *   A list of the paths of library elements referenced by files in existing
   *   analysis roots.
   *
   * packageMap: Map<String, Map<String, List<FilePath>>>
   *
   *   A mapping from context source roots to package maps which map package
   *   names to source directories for use in client-side package URI
   *   resolution.
   */
  Future<AnalysisGetLibraryDependenciesResult>
      sendAnalysisGetLibraryDependencies() async {
    var result = await server.send("analysis.getLibraryDependencies", null);
    ResponseDecoder decoder = new ResponseDecoder(null);
    return new AnalysisGetLibraryDependenciesResult.fromJson(
        decoder, 'result', result);
  }

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
   * If a request is made for a file which does not exist, or which is not
   * currently subject to analysis (e.g. because it is not associated with any
   * analysis root specified to analysis.setAnalysisRoots), an error of type
   * GET_NAVIGATION_INVALID_FILE will be generated.
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
   * Force the re-analysis of everything contained in the specified analysis
   * roots. This will cause all previously computed analysis results to be
   * discarded and recomputed, and will cause all subscribed notifications to
   * be re-sent.
   *
   * If no analysis roots are provided, then all current analysis roots will be
   * re-analyzed. If an empty list of analysis roots is provided, then nothing
   * will be re-analyzed. If the list contains one or more paths that are not
   * currently analysis roots, then an error of type INVALID_ANALYSIS_ROOT will
   * be generated.
   *
   * Parameters
   *
   * roots: List<FilePath> (optional)
   *
   *   A list of the analysis roots that are to be re-analyzed.
   */
  Future sendAnalysisReanalyze({List<String> roots}) async {
    var params = new AnalysisReanalyzeParams(roots: roots).toJson();
    var result = await server.send("analysis.reanalyze", params);
    outOfTestExpect(result, isNull);
    return null;
  }

  /**
   * Sets the root paths used to determine which files to analyze. The set of
   * files to be analyzed are all of the files in one of the root paths that
   * are not either explicitly or implicitly excluded. A file is explicitly
   * excluded if it is in one of the excluded paths. A file is implicitly
   * excluded if it is in a subdirectory of one of the root paths where the
   * name of the subdirectory starts with a period (that is, a hidden
   * directory).
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
   * included: List<FilePath>
   *
   *   A list of the files and directories that should be analyzed.
   *
   * excluded: List<FilePath>
   *
   *   A list of the files and directories within the included directories that
   *   should not be analyzed.
   *
   * packageRoots: Map<FilePath, FilePath> (optional)
   *
   *   A mapping from source directories to package roots that should override
   *   the normal package: URI resolution mechanism.
   *
   *   If a package root is a directory, then the analyzer will behave as
   *   though the associated source directory in the map contains a special
   *   pubspec.yaml file which resolves any package: URI to the corresponding
   *   path within that package root directory. The effect is the same as
   *   specifying the package root directory as a "--package_root" parameter to
   *   the Dart VM when executing any Dart file inside the source directory.
   *
   *   If a package root is a file, then the analyzer will behave as though
   *   that file is a ".packages" file in the source directory. The effect is
   *   the same as specifying the file as a "--packages" parameter to the Dart
   *   VM when executing any Dart file inside the source directory.
   *
   *   Files in any directories that are not overridden by this mapping have
   *   their package: URI's resolved using the normal pubspec.yaml mechanism.
   *   If this field is absent, or the empty map is specified, that indicates
   *   that the normal pubspec.yaml mechanism should always be used.
   */
  Future sendAnalysisSetAnalysisRoots(
      List<String> included, List<String> excluded,
      {Map<String, String> packageRoots}) async {
    var params = new AnalysisSetAnalysisRootsParams(included, excluded,
            packageRoots: packageRoots)
        .toJson();
    var result = await server.send("analysis.setAnalysisRoots", params);
    outOfTestExpect(result, isNull);
    return null;
  }

  /**
   * Subscribe for general services (that is, services that are not specific to
   * individual files). All previous subscriptions are replaced by the given
   * set of services.
   *
   * It is an error if any of the elements in the list are not valid services.
   * If there is an error, then the current subscriptions will remain
   * unchanged.
   *
   * Parameters
   *
   * subscriptions: List<GeneralAnalysisService>
   *
   *   A list of the services being subscribed to.
   */
  Future sendAnalysisSetGeneralSubscriptions(
      List<GeneralAnalysisService> subscriptions) async {
    var params =
        new AnalysisSetGeneralSubscriptionsParams(subscriptions).toJson();
    var result = await server.send("analysis.setGeneralSubscriptions", params);
    outOfTestExpect(result, isNull);
    return null;
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
   * Subscribe for services that are specific to individual files. All previous
   * subscriptions are replaced by the current set of subscriptions. If a given
   * service is not included as a key in the map then no files will be
   * subscribed to the service, exactly as if the service had been included in
   * the map with an explicit empty list of files.
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
   * Update the content of one or more files. Files that were previously
   * updated but not included in this update remain unchanged. This effectively
   * represents an overlay of the filesystem. The files whose content is
   * overridden are therefore seen by server as being files with the given
   * content, even if the files do not exist on the filesystem or if the file
   * path represents the path to a directory on the filesystem.
   *
   * Parameters
   *
   * files: Map<FilePath, AddContentOverlay | ChangeContentOverlay |
   * RemoveContentOverlay>
   *
   *   A table mapping the files whose content has changed to a description of
   *   the content change.
   *
   * Returns
   */
  Future<AnalysisUpdateContentResult> sendAnalysisUpdateContent(
      Map<String, dynamic> files) async {
    var params = new AnalysisUpdateContentParams(files).toJson();
    var result = await server.send("analysis.updateContent", params);
    ResponseDecoder decoder = new ResponseDecoder(null);
    return new AnalysisUpdateContentResult.fromJson(decoder, 'result', result);
  }

  /**
   * Deprecated: all of the options can be set by users in an analysis options
   * file.
   *
   * Update the options controlling analysis based on the given set of options.
   * Any options that are not included in the analysis options will not be
   * changed. If there are options in the analysis options that are not valid,
   * they will be silently ignored.
   *
   * Parameters
   *
   * options: AnalysisOptions
   *
   *   The options that are to be used to control analysis.
   */
  @deprecated
  Future sendAnalysisUpdateOptions(AnalysisOptions options) async {
    var params = new AnalysisUpdateOptionsParams(options).toJson();
    var result = await server.send("analysis.updateOptions", params);
    outOfTestExpect(result, isNull);
    return null;
  }

  /**
   * Reports the paths of the files that are being analyzed.
   *
   * This notification is not subscribed to by default. Clients can subscribe
   * by including the value "ANALYZED_FILES" in the list of services passed in
   * an analysis.setGeneralSubscriptions request.
   *
   * Parameters
   *
   * directories: List<FilePath>
   *
   *   A list of the paths of the files that are being analyzed.
   */
  Stream<AnalysisAnalyzedFilesParams> onAnalysisAnalyzedFiles;

  /**
   * Stream controller for [onAnalysisAnalyzedFiles].
   */
  StreamController<AnalysisAnalyzedFilesParams> _onAnalysisAnalyzedFiles;

  /**
   * Reports the errors associated with a given file. The set of errors
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
   * files: List<FilePath>
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
   * Reports the highlight regions associated with a given file.
   *
   * This notification is not subscribed to by default. Clients can subscribe
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
   * Reports the classes that are implemented or extended and class members
   * that are implemented or overridden in a file.
   *
   * This notification is not subscribed to by default. Clients can subscribe
   * by including the value "IMPLEMENTED" in the list of services passed in an
   * analysis.setSubscriptions request.
   *
   * Parameters
   *
   * file: FilePath
   *
   *   The file with which the implementations are associated.
   *
   * classes: List<ImplementedClass>
   *
   *   The classes defined in the file that are implemented or extended.
   *
   * members: List<ImplementedMember>
   *
   *   The member defined in the file that are implemented or overridden.
   */
  Stream<AnalysisImplementedParams> onAnalysisImplemented;

  /**
   * Stream controller for [onAnalysisImplemented].
   */
  StreamController<AnalysisImplementedParams> _onAnalysisImplemented;

  /**
   * Reports that the navigation information associated with a region of a
   * single file has become invalid and should be re-requested.
   *
   * This notification is not subscribed to by default. Clients can subscribe
   * by including the value "INVALIDATE" in the list of services passed in an
   * analysis.setSubscriptions request.
   *
   * Parameters
   *
   * file: FilePath
   *
   *   The file whose information has been invalidated.
   *
   * offset: int
   *
   *   The offset of the invalidated region.
   *
   * length: int
   *
   *   The length of the invalidated region.
   *
   * delta: int
   *
   *   The delta to be applied to the offsets in information that follows the
   *   invalidated region in order to update it so that it doesn't need to be
   *   re-requested.
   */
  Stream<AnalysisInvalidateParams> onAnalysisInvalidate;

  /**
   * Stream controller for [onAnalysisInvalidate].
   */
  StreamController<AnalysisInvalidateParams> _onAnalysisInvalidate;

  /**
   * Reports the navigation targets associated with a given file.
   *
   * This notification is not subscribed to by default. Clients can subscribe
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
   *   The navigation regions contained in the file. The regions are sorted by
   *   their offsets. Each navigation region represents a list of targets
   *   associated with some range. The lists will usually contain a single
   *   target, but can contain more in the case of a part that is included in
   *   multiple libraries or in Dart code that is compiled against multiple
   *   versions of a package. Note that the navigation regions that are
   *   returned do not overlap other navigation regions.
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
   * Reports the occurrences of references to elements within a single file.
   *
   * This notification is not subscribed to by default. Clients can subscribe
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
   * Reports the outline associated with a single file.
   *
   * This notification is not subscribed to by default. Clients can subscribe
   * by including the value "OUTLINE" in the list of services passed in an
   * analysis.setSubscriptions request.
   *
   * Parameters
   *
   * file: FilePath
   *
   *   The file with which the outline is associated.
   *
   * kind: FileKind
   *
   *   The kind of the file.
   *
   * libraryName: String (optional)
   *
   *   The name of the library defined by the file using a "library" directive,
   *   or referenced by a "part of" directive. If both "library" and "part of"
   *   directives are present, then the "library" directive takes precedence.
   *   This field will be omitted if the file has neither "library" nor "part
   *   of" directives.
   *
   * outline: Outline
   *
   *   The outline associated with the file.
   */
  Stream<AnalysisOutlineParams> onAnalysisOutline;

  /**
   * Stream controller for [onAnalysisOutline].
   */
  StreamController<AnalysisOutlineParams> _onAnalysisOutline;

  /**
   * Reports the overriding members in a file.
   *
   * This notification is not subscribed to by default. Clients can subscribe
   * by including the value "OVERRIDES" in the list of services passed in an
   * analysis.setSubscriptions request.
   *
   * Parameters
   *
   * file: FilePath
   *
   *   The file with which the overrides are associated.
   *
   * overrides: List<Override>
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
   * id: CompletionId
   *
   *   The identifier used to associate results with this completion request.
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
   * Reports the completion suggestions that should be presented to the user.
   * The set of suggestions included in the notification is always a complete
   * list that supersedes any previously reported suggestions.
   *
   * Parameters
   *
   * id: CompletionId
   *
   *   The id associated with the completion.
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
   *
   * isLast: bool
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
   * file: FilePath
   *
   *   The file containing the declaration of or reference to the element used
   *   to define the search.
   *
   * offset: int
   *
   *   The offset within the file of the declaration of or reference to the
   *   element.
   *
   * includePotential: bool
   *
   *   True if potential matches are to be included in the results.
   *
   * Returns
   *
   * id: SearchId (optional)
   *
   *   The identifier used to associate results with this search request.
   *
   *   If no element was found at the given location, this field will be
   *   absent, and no results will be reported via the search.results
   *   notification.
   *
   * element: Element (optional)
   *
   *   The element referenced or defined at the given offset and whose
   *   references will be returned in the search results.
   *
   *   If no element was found at the given location, this field will be
   *   absent.
   */
  Future<SearchFindElementReferencesResult> sendSearchFindElementReferences(
      String file, int offset, bool includePotential) async {
    var params =
        new SearchFindElementReferencesParams(file, offset, includePotential)
            .toJson();
    var result = await server.send("search.findElementReferences", params);
    ResponseDecoder decoder = new ResponseDecoder(null);
    return new SearchFindElementReferencesResult.fromJson(
        decoder, 'result', result);
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
   * name: String
   *
   *   The name of the declarations to be found.
   *
   * Returns
   *
   * id: SearchId
   *
   *   The identifier used to associate results with this search request.
   */
  Future<SearchFindMemberDeclarationsResult> sendSearchFindMemberDeclarations(
      String name) async {
    var params = new SearchFindMemberDeclarationsParams(name).toJson();
    var result = await server.send("search.findMemberDeclarations", params);
    ResponseDecoder decoder = new ResponseDecoder(null);
    return new SearchFindMemberDeclarationsResult.fromJson(
        decoder, 'result', result);
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
   * name: String
   *
   *   The name of the references to be found.
   *
   * Returns
   *
   * id: SearchId
   *
   *   The identifier used to associate results with this search request.
   */
  Future<SearchFindMemberReferencesResult> sendSearchFindMemberReferences(
      String name) async {
    var params = new SearchFindMemberReferencesParams(name).toJson();
    var result = await server.send("search.findMemberReferences", params);
    ResponseDecoder decoder = new ResponseDecoder(null);
    return new SearchFindMemberReferencesResult.fromJson(
        decoder, 'result', result);
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
   * pattern: String
   *
   *   The regular expression used to match the names of the declarations to be
   *   found.
   *
   * Returns
   *
   * id: SearchId
   *
   *   The identifier used to associate results with this search request.
   */
  Future<SearchFindTopLevelDeclarationsResult>
      sendSearchFindTopLevelDeclarations(String pattern) async {
    var params = new SearchFindTopLevelDeclarationsParams(pattern).toJson();
    var result = await server.send("search.findTopLevelDeclarations", params);
    ResponseDecoder decoder = new ResponseDecoder(null);
    return new SearchFindTopLevelDeclarationsResult.fromJson(
        decoder, 'result', result);
  }

  /**
   * Return the type hierarchy of the class declared or referenced at the given
   * location.
   *
   * Parameters
   *
   * file: FilePath
   *
   *   The file containing the declaration or reference to the type for which a
   *   hierarchy is being requested.
   *
   * offset: int
   *
   *   The offset of the name of the type within the file.
   *
   * superOnly: bool (optional)
   *
   *   True if the client is only requesting superclasses and interfaces
   *   hierarchy.
   *
   * Returns
   *
   * hierarchyItems: List<TypeHierarchyItem> (optional)
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
  Future<SearchGetTypeHierarchyResult> sendSearchGetTypeHierarchy(
      String file, int offset,
      {bool superOnly}) async {
    var params =
        new SearchGetTypeHierarchyParams(file, offset, superOnly: superOnly)
            .toJson();
    var result = await server.send("search.getTypeHierarchy", params);
    ResponseDecoder decoder = new ResponseDecoder(null);
    return new SearchGetTypeHierarchyResult.fromJson(decoder, 'result', result);
  }

  /**
   * Reports some or all of the results of performing a requested search.
   * Unlike other notifications, this notification contains search results that
   * should be added to any previously received search results associated with
   * the same search id.
   *
   * Parameters
   *
   * id: SearchId
   *
   *   The id associated with the search.
   *
   * results: List<SearchResult>
   *
   *   The search results being reported.
   *
   * isLast: bool
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
   * Format the contents of a single file. The currently selected region of
   * text is passed in so that the selection can be preserved across the
   * formatting operation. The updated selection will be as close to matching
   * the original as possible, but whitespace at the beginning or end of the
   * selected region will be ignored. If preserving selection information is
   * not required, zero (0) can be specified for both the selection offset and
   * selection length.
   *
   * If a request is made for a file which does not exist, or which is not
   * currently subject to analysis (e.g. because it is not associated with any
   * analysis root specified to analysis.setAnalysisRoots), an error of type
   * FORMAT_INVALID_FILE will be generated. If the source contains syntax
   * errors, an error of type FORMAT_WITH_ERRORS will be generated.
   *
   * Parameters
   *
   * file: FilePath
   *
   *   The file containing the code to be formatted.
   *
   * selectionOffset: int
   *
   *   The offset of the current selection in the file.
   *
   * selectionLength: int
   *
   *   The length of the current selection in the file.
   *
   * lineLength: int (optional)
   *
   *   The line length to be used by the formatter.
   *
   * Returns
   *
   * edits: List<SourceEdit>
   *
   *   The edit(s) to be applied in order to format the code. The list will be
   *   empty if the code was already formatted (there are no changes).
   *
   * selectionOffset: int
   *
   *   The offset of the selection after formatting the code.
   *
   * selectionLength: int
   *
   *   The length of the selection after formatting the code.
   */
  Future<EditFormatResult> sendEditFormat(
      String file, int selectionOffset, int selectionLength,
      {int lineLength}) async {
    var params = new EditFormatParams(file, selectionOffset, selectionLength,
            lineLength: lineLength)
        .toJson();
    var result = await server.send("edit.format", params);
    ResponseDecoder decoder = new ResponseDecoder(null);
    return new EditFormatResult.fromJson(decoder, 'result', result);
  }

  /**
   * Return the set of assists that are available at the given location. An
   * assist is distinguished from a refactoring primarily by the fact that it
   * affects a single file and does not require user input in order to be
   * performed.
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
   * assists: List<SourceChange>
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
   * Get a list of the kinds of refactorings that are valid for the given
   * selection in the given file.
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
   * Return the set of fixes that are available for the errors at a given
   * offset in a given file.
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
   * Get the changes required to convert the postfix template at the given
   * location into the template's expanded form.
   *
   * Parameters
   *
   * file: FilePath
   *
   *   The file containing the postfix template to be expanded.
   *
   * key: String
   *
   *   The unique name that identifies the template in use.
   *
   * offset: int
   *
   *   The offset used to identify the code to which the template will be
   *   applied.
   *
   * Returns
   *
   * change: SourceChange
   *
   *   The change to be applied in order to complete the statement.
   */
  Future<EditGetPostfixCompletionResult> sendEditGetPostfixCompletion(
      String file, String key, int offset) async {
    var params = new EditGetPostfixCompletionParams(file, key, offset).toJson();
    var result = await server.send("edit.getPostfixCompletion", params);
    ResponseDecoder decoder = new ResponseDecoder(null);
    return new EditGetPostfixCompletionResult.fromJson(
        decoder, 'result', result);
  }

  /**
   * Get the changes required to perform a refactoring.
   *
   * If another refactoring request is received during the processing of this
   * one, an error of type REFACTORING_REQUEST_CANCELLED will be generated.
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
   *   The initial status of the refactoring, i.e. problems related to the
   *   context in which the refactoring is requested. The array will be empty
   *   if there are no known problems.
   *
   * optionsProblems: List<RefactoringProblem>
   *
   *   The options validation status, i.e. problems in the given options, such
   *   as light-weight validation of a new name, flags compatibility, etc. The
   *   array will be empty if there are no known problems.
   *
   * finalProblems: List<RefactoringProblem>
   *
   *   The final status of the refactoring, i.e. problems identified in the
   *   result of a full, potentially expensive validation and / or change
   *   creation. The array will be empty if there are no known problems.
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
   *   will be omitted if there are problems that prevent a set of changes from
   *   being computed, such as having no options specified for a refactoring
   *   that requires them, or if only validation was requested.
   *
   * potentialEdits: List<String> (optional)
   *
   *   The ids of source edits that are not known to be valid. An edit is not
   *   known to be valid if there was insufficient type information for the
   *   server to be able to determine whether or not the code needs to be
   *   modified, such as when a member is being renamed and there is a
   *   reference to a member from an unknown type. This field will be omitted
   *   if the change field is omitted or if there are no potential edits for
   *   the refactoring.
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
   * Get the changes required to convert the partial statement at the given
   * location into a syntactically valid statement. If the current statement is
   * already valid the change will insert a newline plus appropriate
   * indentation at the end of the line containing the offset. If a change that
   * makes the statement valid cannot be determined (perhaps because it has not
   * yet been implemented) the statement will be considered already valid and
   * the appropriate change returned.
   *
   * Parameters
   *
   * file: FilePath
   *
   *   The file containing the statement to be completed.
   *
   * offset: int
   *
   *   The offset used to identify the statement to be completed.
   *
   * Returns
   *
   * change: SourceChange
   *
   *   The change to be applied in order to complete the statement.
   *
   * whitespaceOnly: bool
   *
   *   Will be true if the change contains nothing but whitespace characters,
   *   or is empty.
   */
  Future<EditGetStatementCompletionResult> sendEditGetStatementCompletion(
      String file, int offset) async {
    var params = new EditGetStatementCompletionParams(file, offset).toJson();
    var result = await server.send("edit.getStatementCompletion", params);
    ResponseDecoder decoder = new ResponseDecoder(null);
    return new EditGetStatementCompletionResult.fromJson(
        decoder, 'result', result);
  }

  /**
   * Determine if the request postfix completion template is applicable at the
   * given location in the given file.
   *
   * Parameters
   *
   * file: FilePath
   *
   *   The file containing the postfix template to be expanded.
   *
   * key: String
   *
   *   The unique name that identifies the template in use.
   *
   * offset: int
   *
   *   The offset used to identify the code to which the template will be
   *   applied.
   *
   * Returns
   *
   * value: bool
   *
   *   True if the template can be expanded at the given location.
   */
  Future<EditIsPostfixCompletionApplicableResult>
      sendEditIsPostfixCompletionApplicable(
          String file, String key, int offset) async {
    var params =
        new EditIsPostfixCompletionApplicableParams(file, key, offset).toJson();
    var result =
        await server.send("edit.isPostfixCompletionApplicable", params);
    ResponseDecoder decoder = new ResponseDecoder(null);
    return new EditIsPostfixCompletionApplicableResult.fromJson(
        decoder, 'result', result);
  }

  /**
   * Return a list of all postfix templates currently available.
   *
   * Returns
   *
   * templates: List<PostfixTemplateDescriptor>
   *
   *   The list of available templates.
   */
  Future<EditListPostfixCompletionTemplatesResult>
      sendEditListPostfixCompletionTemplates() async {
    var result = await server.send("edit.listPostfixCompletionTemplates", null);
    ResponseDecoder decoder = new ResponseDecoder(null);
    return new EditListPostfixCompletionTemplatesResult.fromJson(
        decoder, 'result', result);
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
   * file: FilePath
   *
   *   The Dart file to sort.
   *
   * Returns
   *
   * edit: SourceFileEdit
   *
   *   The file edit that is to be applied to the given file to effect the
   *   sorting.
   */
  Future<EditSortMembersResult> sendEditSortMembers(String file) async {
    var params = new EditSortMembersParams(file).toJson();
    var result = await server.send("edit.sortMembers", params);
    ResponseDecoder decoder = new ResponseDecoder(null);
    return new EditSortMembersResult.fromJson(decoder, 'result', result);
  }

  /**
   * Organizes all of the directives - removes unused imports and sorts
   * directives of the given Dart file according to the Dart Style Guide.
   *
   * If a request is made for a file that does not exist, does not belong to an
   * analysis root or is not a Dart file, FILE_NOT_ANALYZED will be generated.
   *
   * If directives of the Dart file cannot be organized, for example because it
   * has scan or parse errors, or by other reasons, ORGANIZE_DIRECTIVES_ERROR
   * will be generated. The message will provide details about the reason.
   *
   * Parameters
   *
   * file: FilePath
   *
   *   The Dart file to organize directives in.
   *
   * Returns
   *
   * edit: SourceFileEdit
   *
   *   The file edit that is to be applied to the given file to effect the
   *   organizing.
   */
  Future<EditOrganizeDirectivesResult> sendEditOrganizeDirectives(
      String file) async {
    var params = new EditOrganizeDirectivesParams(file).toJson();
    var result = await server.send("edit.organizeDirectives", params);
    ResponseDecoder decoder = new ResponseDecoder(null);
    return new EditOrganizeDirectivesResult.fromJson(decoder, 'result', result);
  }

  /**
   * Create an execution context for the executable file with the given path.
   * The context that is created will persist until execution.deleteContext is
   * used to delete it. Clients, therefore, are responsible for managing the
   * lifetime of execution contexts.
   *
   * Parameters
   *
   * contextRoot: FilePath
   *
   *   The path of the Dart or HTML file that will be launched, or the path of
   *   the directory containing the file.
   *
   * Returns
   *
   * id: ExecutionContextId
   *
   *   The identifier used to refer to the execution context that was created.
   */
  Future<ExecutionCreateContextResult> sendExecutionCreateContext(
      String contextRoot) async {
    var params = new ExecutionCreateContextParams(contextRoot).toJson();
    var result = await server.send("execution.createContext", params);
    ResponseDecoder decoder = new ResponseDecoder(null);
    return new ExecutionCreateContextResult.fromJson(decoder, 'result', result);
  }

  /**
   * Delete the execution context with the given identifier. The context id is
   * no longer valid after this command. The server is allowed to re-use ids
   * when they are no longer valid.
   *
   * Parameters
   *
   * id: ExecutionContextId
   *
   *   The identifier of the execution context that is to be deleted.
   */
  Future sendExecutionDeleteContext(String id) async {
    var params = new ExecutionDeleteContextParams(id).toJson();
    var result = await server.send("execution.deleteContext", params);
    outOfTestExpect(result, isNull);
    return null;
  }

  /**
   * Map a URI from the execution context to the file that it corresponds to,
   * or map a file to the URI that it corresponds to in the execution context.
   *
   * Exactly one of the file and uri fields must be provided. If both fields
   * are provided, then an error of type INVALID_PARAMETER will be generated.
   * Similarly, if neither field is provided, then an error of type
   * INVALID_PARAMETER will be generated.
   *
   * If the file field is provided and the value is not the path of a file
   * (either the file does not exist or the path references something other
   * than a file), then an error of type INVALID_PARAMETER will be generated.
   *
   * If the uri field is provided and the value is not a valid URI or if the
   * URI references something that is not a file (either a file that does not
   * exist or something other than a file), then an error of type
   * INVALID_PARAMETER will be generated.
   *
   * If the contextRoot used to create the execution context does not exist,
   * then an error of type INVALID_EXECUTION_CONTEXT will be generated.
   *
   * Parameters
   *
   * id: ExecutionContextId
   *
   *   The identifier of the execution context in which the URI is to be
   *   mapped.
   *
   * file: FilePath (optional)
   *
   *   The path of the file to be mapped into a URI.
   *
   * uri: String (optional)
   *
   *   The URI to be mapped into a file path.
   *
   * Returns
   *
   * file: FilePath (optional)
   *
   *   The file to which the URI was mapped. This field is omitted if the uri
   *   field was not given in the request.
   *
   * uri: String (optional)
   *
   *   The URI to which the file path was mapped. This field is omitted if the
   *   file field was not given in the request.
   */
  Future<ExecutionMapUriResult> sendExecutionMapUri(String id,
      {String file, String uri}) async {
    var params = new ExecutionMapUriParams(id, file: file, uri: uri).toJson();
    var result = await server.send("execution.mapUri", params);
    ResponseDecoder decoder = new ResponseDecoder(null);
    return new ExecutionMapUriResult.fromJson(decoder, 'result', result);
  }

  /**
   * Deprecated: the analysis server no longer fires LAUNCH_DATA events.
   *
   * Subscribe for services. All previous subscriptions are replaced by the
   * given set of services.
   *
   * It is an error if any of the elements in the list are not valid services.
   * If there is an error, then the current subscriptions will remain
   * unchanged.
   *
   * Parameters
   *
   * subscriptions: List<ExecutionService>
   *
   *   A list of the services being subscribed to.
   */
  @deprecated
  Future sendExecutionSetSubscriptions(
      List<ExecutionService> subscriptions) async {
    var params = new ExecutionSetSubscriptionsParams(subscriptions).toJson();
    var result = await server.send("execution.setSubscriptions", params);
    outOfTestExpect(result, isNull);
    return null;
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
   * file: FilePath
   *
   *   The file for which launch data is being provided. This will either be a
   *   Dart library or an HTML file.
   *
   * kind: ExecutableKind (optional)
   *
   *   The kind of the executable file. This field is omitted if the file is
   *   not a Dart file.
   *
   * referencedFiles: List<FilePath> (optional)
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
   * Return server diagnostics.
   *
   * Returns
   *
   * contexts: List<ContextData>
   *
   *   The list of analysis contexts.
   */
  Future<DiagnosticGetDiagnosticsResult> sendDiagnosticGetDiagnostics() async {
    var result = await server.send("diagnostic.getDiagnostics", null);
    ResponseDecoder decoder = new ResponseDecoder(null);
    return new DiagnosticGetDiagnosticsResult.fromJson(
        decoder, 'result', result);
  }

  /**
   * Return the port of the diagnostic web server. If the server is not running
   * this call will start the server. If unable to start the diagnostic web
   * server, this call will return an error of DEBUG_PORT_COULD_NOT_BE_OPENED.
   *
   * Returns
   *
   * port: int
   *
   *   The diagnostic server port.
   */
  Future<DiagnosticGetServerPortResult> sendDiagnosticGetServerPort() async {
    var result = await server.send("diagnostic.getServerPort", null);
    ResponseDecoder decoder = new ResponseDecoder(null);
    return new DiagnosticGetServerPortResult.fromJson(
        decoder, 'result', result);
  }

  /**
   * Query whether analytics is enabled.
   *
   * This flag controls whether the analysis server sends any analytics data to
   * the cloud. If disabled, the analysis server does not send any analytics
   * data, and any data sent to it by clients (from sendEvent and sendTiming)
   * will be ignored.
   *
   * The value of this flag can be changed by other tools outside of the
   * analysis server's process. When you query the flag, you get the value of
   * the flag at a given moment. Clients should not use the value returned to
   * decide whether or not to send the sendEvent and sendTiming requests. Those
   * requests should be used unconditionally and server will determine whether
   * or not it is appropriate to forward the information to the cloud at the
   * time each request is received.
   *
   * Returns
   *
   * enabled: bool
   *
   *   Whether sending analytics is enabled or not.
   */
  Future<AnalyticsIsEnabledResult> sendAnalyticsIsEnabled() async {
    var result = await server.send("analytics.isEnabled", null);
    ResponseDecoder decoder = new ResponseDecoder(null);
    return new AnalyticsIsEnabledResult.fromJson(decoder, 'result', result);
  }

  /**
   * Enable or disable the sending of analytics data. Note that there are other
   * ways for users to change this setting, so clients cannot assume that they
   * have complete control over this setting. In particular, there is no
   * guarantee that the result returned by the isEnabled request will match the
   * last value set via this request.
   *
   * Parameters
   *
   * value: bool
   *
   *   Enable or disable analytics.
   */
  Future sendAnalyticsEnable(bool value) async {
    var params = new AnalyticsEnableParams(value).toJson();
    var result = await server.send("analytics.enable", params);
    outOfTestExpect(result, isNull);
    return null;
  }

  /**
   * Send information about client events.
   *
   * Ask the analysis server to include the fact that an action was performed
   * in the client as part of the analytics data being sent. The data will only
   * be included if the sending of analytics data is enabled at the time the
   * request is processed. The action that was performed is indicated by the
   * value of the action field.
   *
   * The value of the action field should not include the identity of the
   * client. The analytics data sent by server will include the client id
   * passed in using the --client-id command-line argument. The request will be
   * ignored if the client id was not provided when server was started.
   *
   * Parameters
   *
   * action: String
   *
   *   The value used to indicate which action was performed.
   */
  Future sendAnalyticsSendEvent(String action) async {
    var params = new AnalyticsSendEventParams(action).toJson();
    var result = await server.send("analytics.sendEvent", params);
    outOfTestExpect(result, isNull);
    return null;
  }

  /**
   * Send timing information for client events (e.g. code completions).
   *
   * Ask the analysis server to include the fact that a timed event occurred as
   * part of the analytics data being sent. The data will only be included if
   * the sending of analytics data is enabled at the time the request is
   * processed.
   *
   * The value of the event field should not include the identity of the
   * client. The analytics data sent by server will include the client id
   * passed in using the --client-id command-line argument. The request will be
   * ignored if the client id was not provided when server was started.
   *
   * Parameters
   *
   * event: String
   *
   *   The name of the event.
   *
   * millis: int
   *
   *   The duration of the event in milliseconds.
   */
  Future sendAnalyticsSendTiming(String event, int millis) async {
    var params = new AnalyticsSendTimingParams(event, millis).toJson();
    var result = await server.send("analytics.sendTiming", params);
    outOfTestExpect(result, isNull);
    return null;
  }

  /**
   * Initialize the fields in InttestMixin, and ensure that notifications will
   * be handled.
   */
  void initializeInttestMixin() {
    _onServerConnected =
        new StreamController<ServerConnectedParams>(sync: true);
    onServerConnected = _onServerConnected.stream.asBroadcastStream();
    _onServerError = new StreamController<ServerErrorParams>(sync: true);
    onServerError = _onServerError.stream.asBroadcastStream();
    _onServerStatus = new StreamController<ServerStatusParams>(sync: true);
    onServerStatus = _onServerStatus.stream.asBroadcastStream();
    _onAnalysisAnalyzedFiles =
        new StreamController<AnalysisAnalyzedFilesParams>(sync: true);
    onAnalysisAnalyzedFiles =
        _onAnalysisAnalyzedFiles.stream.asBroadcastStream();
    _onAnalysisErrors = new StreamController<AnalysisErrorsParams>(sync: true);
    onAnalysisErrors = _onAnalysisErrors.stream.asBroadcastStream();
    _onAnalysisFlushResults =
        new StreamController<AnalysisFlushResultsParams>(sync: true);
    onAnalysisFlushResults = _onAnalysisFlushResults.stream.asBroadcastStream();
    _onAnalysisFolding =
        new StreamController<AnalysisFoldingParams>(sync: true);
    onAnalysisFolding = _onAnalysisFolding.stream.asBroadcastStream();
    _onAnalysisHighlights =
        new StreamController<AnalysisHighlightsParams>(sync: true);
    onAnalysisHighlights = _onAnalysisHighlights.stream.asBroadcastStream();
    _onAnalysisImplemented =
        new StreamController<AnalysisImplementedParams>(sync: true);
    onAnalysisImplemented = _onAnalysisImplemented.stream.asBroadcastStream();
    _onAnalysisInvalidate =
        new StreamController<AnalysisInvalidateParams>(sync: true);
    onAnalysisInvalidate = _onAnalysisInvalidate.stream.asBroadcastStream();
    _onAnalysisNavigation =
        new StreamController<AnalysisNavigationParams>(sync: true);
    onAnalysisNavigation = _onAnalysisNavigation.stream.asBroadcastStream();
    _onAnalysisOccurrences =
        new StreamController<AnalysisOccurrencesParams>(sync: true);
    onAnalysisOccurrences = _onAnalysisOccurrences.stream.asBroadcastStream();
    _onAnalysisOutline =
        new StreamController<AnalysisOutlineParams>(sync: true);
    onAnalysisOutline = _onAnalysisOutline.stream.asBroadcastStream();
    _onAnalysisOverrides =
        new StreamController<AnalysisOverridesParams>(sync: true);
    onAnalysisOverrides = _onAnalysisOverrides.stream.asBroadcastStream();
    _onCompletionResults =
        new StreamController<CompletionResultsParams>(sync: true);
    onCompletionResults = _onCompletionResults.stream.asBroadcastStream();
    _onSearchResults = new StreamController<SearchResultsParams>(sync: true);
    onSearchResults = _onSearchResults.stream.asBroadcastStream();
    _onExecutionLaunchData =
        new StreamController<ExecutionLaunchDataParams>(sync: true);
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
        outOfTestExpect(params, isServerConnectedParams);
        _onServerConnected
            .add(new ServerConnectedParams.fromJson(decoder, 'params', params));
        break;
      case "server.error":
        outOfTestExpect(params, isServerErrorParams);
        _onServerError
            .add(new ServerErrorParams.fromJson(decoder, 'params', params));
        break;
      case "server.status":
        outOfTestExpect(params, isServerStatusParams);
        _onServerStatus
            .add(new ServerStatusParams.fromJson(decoder, 'params', params));
        break;
      case "analysis.analyzedFiles":
        outOfTestExpect(params, isAnalysisAnalyzedFilesParams);
        _onAnalysisAnalyzedFiles.add(new AnalysisAnalyzedFilesParams.fromJson(
            decoder, 'params', params));
        break;
      case "analysis.errors":
        outOfTestExpect(params, isAnalysisErrorsParams);
        _onAnalysisErrors
            .add(new AnalysisErrorsParams.fromJson(decoder, 'params', params));
        break;
      case "analysis.flushResults":
        outOfTestExpect(params, isAnalysisFlushResultsParams);
        _onAnalysisFlushResults.add(
            new AnalysisFlushResultsParams.fromJson(decoder, 'params', params));
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
      case "analysis.implemented":
        outOfTestExpect(params, isAnalysisImplementedParams);
        _onAnalysisImplemented.add(
            new AnalysisImplementedParams.fromJson(decoder, 'params', params));
        break;
      case "analysis.invalidate":
        outOfTestExpect(params, isAnalysisInvalidateParams);
        _onAnalysisInvalidate.add(
            new AnalysisInvalidateParams.fromJson(decoder, 'params', params));
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
      case "analysis.overrides":
        outOfTestExpect(params, isAnalysisOverridesParams);
        _onAnalysisOverrides.add(
            new AnalysisOverridesParams.fromJson(decoder, 'params', params));
        break;
      case "completion.results":
        outOfTestExpect(params, isCompletionResultsParams);
        _onCompletionResults.add(
            new CompletionResultsParams.fromJson(decoder, 'params', params));
        break;
      case "search.results":
        outOfTestExpect(params, isSearchResultsParams);
        _onSearchResults
            .add(new SearchResultsParams.fromJson(decoder, 'params', params));
        break;
      case "execution.launchData":
        outOfTestExpect(params, isExecutionLaunchDataParams);
        _onExecutionLaunchData.add(
            new ExecutionLaunchDataParams.fromJson(decoder, 'params', params));
        break;
      default:
        fail('Unexpected notification: $event');
        break;
    }
  }
}
