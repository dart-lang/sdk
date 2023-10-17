// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This file has been automatically generated. Please do not edit it manually.
// To regenerate the file, use the script
// "pkg/analysis_server/tool/spec/generate_files".

/// Convenience methods for running integration tests.
library;

import 'dart:async';

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/protocol/protocol_internal.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';

import 'integration_tests.dart';
import 'protocol_matchers.dart';

/// Base implementation for running integration tests.
abstract class IntegrationTest {
  Server get server;

  /// Return the version number of the analysis server.
  ///
  /// Returns
  ///
  /// version: String
  ///
  ///   The version number of the analysis server.
  Future<ServerGetVersionResult> sendServerGetVersion() async {
    var result = await server.send('server.getVersion', null);
    var decoder = ResponseDecoder(null);
    return ServerGetVersionResult.fromJson(decoder, 'result', result);
  }

  /// Cleanly shutdown the analysis server. Requests that are received after
  /// this request will not be processed. Requests that were received before
  /// this request, but for which a response has not yet been sent, will not be
  /// responded to. No further responses or notifications will be sent after
  /// the response to this request has been sent.
  Future<void> sendServerShutdown() async {
    var result = await server.send('server.shutdown', null);
    outOfTestExpect(result, isNull);
  }

  /// Subscribe for services. All previous subscriptions are replaced by the
  /// given set of services.
  ///
  /// It is an error if any of the elements in the list are not valid services.
  /// If there is an error, then the current subscriptions will remain
  /// unchanged.
  ///
  /// Parameters
  ///
  /// subscriptions: List<ServerService>
  ///
  ///   A list of the services being subscribed to.
  Future<void> sendServerSetSubscriptions(
      List<ServerService> subscriptions) async {
    var params = ServerSetSubscriptionsParams(subscriptions).toJson();
    var result = await server.send('server.setSubscriptions', params);
    outOfTestExpect(result, isNull);
  }

  /// Requests cancellation of a request sent by the client by id. This is
  /// provided on a best-effort basis and there is no guarantee the server will
  /// be able to cancel any specific request. The server will still always
  /// produce a response to the request even in the case of cancellation, but
  /// clients should discard any results of any cancelled request because they
  /// may be incomplete or inaccurate. This request always completes without
  /// error regardless of whether the request is successfully cancelled.
  ///
  /// Parameters
  ///
  /// id: String
  ///
  ///   The id of the request that should be cancelled.
  Future<void> sendServerCancelRequest(String id) async {
    var params = ServerCancelRequestParams(id).toJson();
    var result = await server.send('server.cancelRequest', params);
    outOfTestExpect(result, isNull);
  }

  /// Record the capabilities supported by the client. The default values,
  /// documented below, will be assumed until this request is received.
  ///
  /// Parameters
  ///
  /// requests: List<String>
  ///
  ///   The names of the requests that the server can safely send to the
  ///   client. Only requests whose name is in the list will be sent.
  ///
  ///   A request should only be included in the list if the client will
  ///   unconditionally honor the request.
  ///
  ///   The default, used before this request is received, is an empty list.
  ///
  ///   The following is a list of the names of the requests that can be
  ///   specified:
  ///
  ///   - openUrlRequest
  ///   - showMessageRequest
  Future<void> sendServerSetClientCapabilities(List<String> requests) async {
    var params = ServerSetClientCapabilitiesParams(requests).toJson();
    var result = await server.send('server.setClientCapabilities', params);
    outOfTestExpect(result, isNull);
  }

  /// Note: This is a request from the server to the client.
  ///
  /// Request that a URL be opened.
  ///
  /// The client is expected to open the URL, either within the client's UI or
  /// in the default browser.
  ///
  /// The request will only be sent from the server to the client if the client
  /// has indicated that it supports this request by using the
  /// setClientCapabilities request.
  ///
  /// Parameters
  ///
  /// url: String
  ///
  ///   The URL to be opened.
  Future<void> sendServerOpenUrlRequest(String url) async {
    var params = ServerOpenUrlRequestParams(url).toJson();
    var result = await server.send('server.openUrlRequest', params);
    outOfTestExpect(result, isNull);
  }

  /// Note: This is a request from the server to the client.
  ///
  /// Request that a message be displayed to the user.
  ///
  /// The client is expected to display the message to the user with one or
  /// more buttons with the specified labels, and to return a response
  /// consisting of the label of the button that was clicked.
  ///
  /// The request will only be sent from the server to the client if the client
  /// has indicated that it supports this request by using the
  /// setClientCapabilities request.
  ///
  /// This request is modeled after the same request from the LSP
  /// specification.
  ///
  /// Parameters
  ///
  /// type: MessageType
  ///
  ///   The type of the message.
  ///
  /// message: String
  ///
  ///   The message to be displayed.
  ///
  /// actions: List<MessageAction>
  ///
  ///   The labels of the buttons by which the user can dismiss the message.
  ///
  /// Returns
  ///
  /// action: String (optional)
  ///
  ///   The label of the action that was selected by the user. May be omitted
  ///   or `null` if the user dismissed the message without clicking an action
  ///   button.
  Future<ServerShowMessageRequestResult> sendServerShowMessageRequest(
      MessageType type, String message, List<MessageAction> actions) async {
    var params =
        ServerShowMessageRequestParams(type, message, actions).toJson();
    var result = await server.send('server.showMessageRequest', params);
    var decoder = ResponseDecoder(null);
    return ServerShowMessageRequestResult.fromJson(decoder, 'result', result);
  }

  /// Reports that the server is running. This notification is issued once
  /// after the server has started running but before any requests are
  /// processed to let the client know that it started correctly.
  ///
  /// It is not possible to subscribe to or unsubscribe from this notification.
  ///
  /// Parameters
  ///
  /// version: String
  ///
  ///   The version number of the analysis server.
  ///
  /// pid: int
  ///
  ///   The process id of the analysis server process.
  late final Stream<ServerConnectedParams> onServerConnected =
      _onServerConnected.stream.asBroadcastStream();

  /// Stream controller for [onServerConnected].
  final _onServerConnected =
      StreamController<ServerConnectedParams>(sync: true);

  /// Reports that an unexpected error has occurred while executing the server.
  /// This notification is not used for problems with specific requests (which
  /// are returned as part of the response) but is used for exceptions that
  /// occur while performing other tasks, such as analysis or preparing
  /// notifications.
  ///
  /// It is not possible to subscribe to or unsubscribe from this notification.
  ///
  /// Parameters
  ///
  /// isFatal: bool
  ///
  ///   True if the error is a fatal error, meaning that the server will
  ///   shutdown automatically after sending this notification.
  ///
  /// message: String
  ///
  ///   The error message indicating what kind of error was encountered.
  ///
  /// stackTrace: String
  ///
  ///   The stack trace associated with the generation of the error, used for
  ///   debugging the server.
  late final Stream<ServerErrorParams> onServerError =
      _onServerError.stream.asBroadcastStream();

  /// Stream controller for [onServerError].
  final _onServerError = StreamController<ServerErrorParams>(sync: true);

  /// The stream of entries describing events happened in the server.
  ///
  /// Parameters
  ///
  /// entry: ServerLogEntry
  late final Stream<ServerLogParams> onServerLog =
      _onServerLog.stream.asBroadcastStream();

  /// Stream controller for [onServerLog].
  final _onServerLog = StreamController<ServerLogParams>(sync: true);

  /// Reports the current status of the server. Parameters are omitted if there
  /// has been no change in the status represented by that parameter.
  ///
  /// This notification is not subscribed to by default. Clients can subscribe
  /// by including the value "STATUS" in the list of services passed in a
  /// server.setSubscriptions request.
  ///
  /// Parameters
  ///
  /// analysis: AnalysisStatus (optional)
  ///
  ///   The current status of analysis, including whether analysis is being
  ///   performed and if so what is being analyzed.
  ///
  /// pub: PubStatus (optional)
  ///
  ///   The current status of pub execution, indicating whether we are
  ///   currently running pub.
  ///
  ///   Note: this status type is deprecated, and is no longer sent by the
  ///   server.
  late final Stream<ServerStatusParams> onServerStatus =
      _onServerStatus.stream.asBroadcastStream();

  /// Stream controller for [onServerStatus].
  final _onServerStatus = StreamController<ServerStatusParams>(sync: true);

  /// Return the errors associated with the given file. If the errors for the
  /// given file have not yet been computed, or the most recently computed
  /// errors for the given file are out of date, then the response for this
  /// request will be delayed until they have been computed. If some or all of
  /// the errors for the file cannot be computed, then the subset of the errors
  /// that can be computed will be returned and the response will contain an
  /// error to indicate why the errors could not be computed. If the content of
  /// the file changes after this request was received but before a response
  /// could be sent, then an error of type CONTENT_MODIFIED will be generated.
  ///
  /// This request is intended to be used by clients that cannot asynchronously
  /// apply updated error information. Clients that can apply error information
  /// as it becomes available should use the information provided by the
  /// 'analysis.errors' notification.
  ///
  /// If a request is made for a file which does not exist, or which is not
  /// currently subject to analysis (e.g. because it is not associated with any
  /// analysis root specified to analysis.setAnalysisRoots), an error of type
  /// GET_ERRORS_INVALID_FILE will be generated.
  ///
  /// Parameters
  ///
  /// file: FilePath
  ///
  ///   The file for which errors are being requested.
  ///
  /// Returns
  ///
  /// errors: List<AnalysisError>
  ///
  ///   The errors associated with the file.
  Future<AnalysisGetErrorsResult> sendAnalysisGetErrors(String file) async {
    var params = AnalysisGetErrorsParams(file).toJson();
    var result = await server.send('analysis.getErrors', params);
    var decoder = ResponseDecoder(null);
    return AnalysisGetErrorsResult.fromJson(decoder, 'result', result);
  }

  /// Return the hover information associate with the given location. If some
  /// or all of the hover information is not available at the time this request
  /// is processed the information will be omitted from the response.
  ///
  /// Parameters
  ///
  /// file: FilePath
  ///
  ///   The file in which hover information is being requested.
  ///
  /// offset: int
  ///
  ///   The offset for which hover information is being requested.
  ///
  /// Returns
  ///
  /// hovers: List<HoverInformation>
  ///
  ///   The hover information associated with the location. The list will be
  ///   empty if no information could be determined for the location. The list
  ///   can contain multiple items if the file is being analyzed in multiple
  ///   contexts in conflicting ways (such as a part that is included in
  ///   multiple libraries).
  Future<AnalysisGetHoverResult> sendAnalysisGetHover(
      String file, int offset) async {
    var params = AnalysisGetHoverParams(file, offset).toJson();
    var result = await server.send('analysis.getHover', params);
    var decoder = ResponseDecoder(null);
    return AnalysisGetHoverResult.fromJson(decoder, 'result', result);
  }

  /// Return a description of all of the elements referenced in a given region
  /// of a given file that come from imported libraries.
  ///
  /// If a request is made for a file that does not exist, or that is not
  /// currently subject to analysis (e.g. because it is not associated with any
  /// analysis root specified via analysis.setAnalysisRoots), an error of type
  /// GET_IMPORTED_ELEMENTS_INVALID_FILE will be generated.
  ///
  /// Parameters
  ///
  /// file: FilePath
  ///
  ///   The file in which import information is being requested.
  ///
  /// offset: int
  ///
  ///   The offset of the region for which import information is being
  ///   requested.
  ///
  /// length: int
  ///
  ///   The length of the region for which import information is being
  ///   requested.
  ///
  /// Returns
  ///
  /// elements: List<ImportedElements>
  ///
  ///   The information about the elements that are referenced in the specified
  ///   region of the specified file that come from imported libraries.
  Future<AnalysisGetImportedElementsResult> sendAnalysisGetImportedElements(
      String file, int offset, int length) async {
    var params =
        AnalysisGetImportedElementsParams(file, offset, length).toJson();
    var result = await server.send('analysis.getImportedElements', params);
    var decoder = ResponseDecoder(null);
    return AnalysisGetImportedElementsResult.fromJson(
        decoder, 'result', result);
  }

  /// Return library dependency information for use in client-side indexing and
  /// package URI resolution.
  ///
  /// Clients that are only using the libraries field should consider using the
  /// analyzedFiles notification instead.
  ///
  /// Returns
  ///
  /// libraries: List<FilePath>
  ///
  ///   A list of the paths of library elements referenced by files in existing
  ///   analysis roots.
  ///
  /// packageMap: Map<String, Map<String, List<FilePath>>>
  ///
  ///   A mapping from context source roots to package maps which map package
  ///   names to source directories for use in client-side package URI
  ///   resolution.
  Future<AnalysisGetLibraryDependenciesResult>
      sendAnalysisGetLibraryDependencies() async {
    var result = await server.send('analysis.getLibraryDependencies', null);
    var decoder = ResponseDecoder(null);
    return AnalysisGetLibraryDependenciesResult.fromJson(
        decoder, 'result', result);
  }

  /// Return the navigation information associated with the given region of the
  /// given file. If the navigation information for the given file has not yet
  /// been computed, or the most recently computed navigation information for
  /// the given file is out of date, then the response for this request will be
  /// delayed until it has been computed. If the content of the file changes
  /// after this request was received but before a response could be sent, then
  /// an error of type CONTENT_MODIFIED will be generated.
  ///
  /// If a navigation region overlaps (but extends either before or after) the
  /// given region of the file it will be included in the result. This means
  /// that it is theoretically possible to get the same navigation region in
  /// response to multiple requests. Clients can avoid this by always choosing
  /// a region that starts at the beginning of a line and ends at the end of a
  /// (possibly different) line in the file.
  ///
  /// If a request is made for a file which does not exist, or which is not
  /// currently subject to analysis (e.g. because it is not associated with any
  /// analysis root specified to analysis.setAnalysisRoots), an error of type
  /// GET_NAVIGATION_INVALID_FILE will be generated.
  ///
  /// Parameters
  ///
  /// file: FilePath
  ///
  ///   The file in which navigation information is being requested.
  ///
  /// offset: int
  ///
  ///   The offset of the region for which navigation information is being
  ///   requested.
  ///
  /// length: int
  ///
  ///   The length of the region for which navigation information is being
  ///   requested.
  ///
  /// Returns
  ///
  /// files: List<FilePath>
  ///
  ///   A list of the paths of files that are referenced by the navigation
  ///   targets.
  ///
  /// targets: List<NavigationTarget>
  ///
  ///   A list of the navigation targets that are referenced by the navigation
  ///   regions.
  ///
  /// regions: List<NavigationRegion>
  ///
  ///   A list of the navigation regions within the requested region of the
  ///   file.
  Future<AnalysisGetNavigationResult> sendAnalysisGetNavigation(
      String file, int offset, int length) async {
    var params = AnalysisGetNavigationParams(file, offset, length).toJson();
    var result = await server.send('analysis.getNavigation', params);
    var decoder = ResponseDecoder(null);
    return AnalysisGetNavigationResult.fromJson(decoder, 'result', result);
  }

  /// Return the transitive closure of reachable sources for a given file.
  ///
  /// If a request is made for a file which does not exist, or which is not
  /// currently subject to analysis (e.g. because it is not associated with any
  /// analysis root specified to analysis.setAnalysisRoots), an error of type
  /// GET_REACHABLE_SOURCES_INVALID_FILE will be generated.
  ///
  /// Parameters
  ///
  /// file: FilePath
  ///
  ///   The file for which reachable source information is being requested.
  ///
  /// Returns
  ///
  /// sources: Map<String, List<String>>
  ///
  ///   A mapping from source URIs to directly reachable source URIs. For
  ///   example, a file "foo.dart" that imports "bar.dart" would have the
  ///   corresponding mapping { "file:///foo.dart" : ["file:///bar.dart"] }. If
  ///   "bar.dart" has further imports (or exports) there will be a mapping
  ///   from the URI "file:///bar.dart" to them. To check if a specific URI is
  ///   reachable from a given file, clients can check for its presence in the
  ///   resulting key set.
  // TODO(srawlins): Provide a deprecation message, or remove.
  // ignore: provide_deprecation_message
  @deprecated
  Future<AnalysisGetReachableSourcesResult> sendAnalysisGetReachableSources(
      String file) async {
    var params = AnalysisGetReachableSourcesParams(file).toJson();
    var result = await server.send('analysis.getReachableSources', params);
    var decoder = ResponseDecoder(null);
    return AnalysisGetReachableSourcesResult.fromJson(
        decoder, 'result', result);
  }

  /// Return the signature information associated with the given location in
  /// the given file. If the signature information for the given file has not
  /// yet been computed, or the most recently computed signature information
  /// for the given file is out of date, then the response for this request
  /// will be delayed until it has been computed. If a request is made for a
  /// file which does not exist, or which is not currently subject to analysis
  /// (e.g. because it is not associated with any analysis root specified to
  /// analysis.setAnalysisRoots), an error of type GET_SIGNATURE_INVALID_FILE
  /// will be generated. If the location given is not inside the argument list
  /// for a function (including method and constructor) invocation, then an
  /// error of type GET_SIGNATURE_INVALID_OFFSET will be generated. If the
  /// location is inside an argument list but the function is not defined or
  /// cannot be determined (such as a method invocation where the target has
  /// type 'dynamic') then an error of type GET_SIGNATURE_UNKNOWN_FUNCTION will
  /// be generated.
  ///
  /// Parameters
  ///
  /// file: FilePath
  ///
  ///   The file in which signature information is being requested.
  ///
  /// offset: int
  ///
  ///   The location for which signature information is being requested.
  ///
  /// Returns
  ///
  /// name: String
  ///
  ///   The name of the function being invoked at the given offset.
  ///
  /// parameters: List<ParameterInfo>
  ///
  ///   A list of information about each of the parameters of the function
  ///   being invoked.
  ///
  /// dartdoc: String (optional)
  ///
  ///   The dartdoc associated with the function being invoked. Other than the
  ///   removal of the comment delimiters, including leading asterisks in the
  ///   case of a block comment, the dartdoc is unprocessed markdown. This data
  ///   is omitted if there is no referenced element, or if the element has no
  ///   dartdoc.
  Future<AnalysisGetSignatureResult> sendAnalysisGetSignature(
      String file, int offset) async {
    var params = AnalysisGetSignatureParams(file, offset).toJson();
    var result = await server.send('analysis.getSignature', params);
    var decoder = ResponseDecoder(null);
    return AnalysisGetSignatureResult.fromJson(decoder, 'result', result);
  }

  /// Force re-reading of all potentially changed files, re-resolving of all
  /// referenced URIs, and corresponding re-analysis of everything affected in
  /// the current analysis roots.
  Future<void> sendAnalysisReanalyze() async {
    var result = await server.send('analysis.reanalyze', null);
    outOfTestExpect(result, isNull);
  }

  /// Sets the root paths used to determine which files to analyze. The set of
  /// files to be analyzed are all of the files in one of the root paths that
  /// are not either explicitly or implicitly excluded. A file is explicitly
  /// excluded if it is in one of the excluded paths. A file is implicitly
  /// excluded if it is in a subdirectory of one of the root paths where the
  /// name of the subdirectory starts with a period (that is, a hidden
  /// directory).
  ///
  /// Note that this request determines the set of requested analysis roots.
  /// The actual set of analysis roots at any given time is the intersection of
  /// this set with the set of files and directories actually present on the
  /// filesystem. When the filesystem changes, the actual set of analysis roots
  /// is automatically updated, but the set of requested analysis roots is
  /// unchanged. This means that if the client sets an analysis root before the
  /// root becomes visible to server in the filesystem, there is no error; once
  /// the server sees the root in the filesystem it will start analyzing it.
  /// Similarly, server will stop analyzing files that are removed from the
  /// file system but they will remain in the set of requested roots.
  ///
  /// If an included path represents a file, then server will look in the
  /// directory containing the file for a pubspec.yaml file. If none is found,
  /// then the parents of the directory will be searched until such a file is
  /// found or the root of the file system is reached. If such a file is found,
  /// it will be used to resolve package: URI's within the file.
  ///
  /// Parameters
  ///
  /// included: List<FilePath>
  ///
  ///   A list of the files and directories that should be analyzed.
  ///
  /// excluded: List<FilePath>
  ///
  ///   A list of the files and directories within the included directories
  ///   that should not be analyzed.
  ///
  /// packageRoots: Map<FilePath, FilePath> (optional)
  ///
  ///   A mapping from source directories to package roots that should override
  ///   the normal package: URI resolution mechanism.
  ///
  ///   If a package root is a file, then the analyzer will behave as though
  ///   that file is a ".dart_tool/package_config.json" file in the source
  ///   directory. The effect is the same as specifying the file as a
  ///   "--packages" parameter to the Dart VM when executing any Dart file
  ///   inside the source directory.
  ///
  ///   Files in any directories that are not overridden by this mapping have
  ///   their package: URI's resolved using the normal pubspec.yaml mechanism.
  ///   If this field is absent, or the empty map is specified, that indicates
  ///   that the normal pubspec.yaml mechanism should always be used.
  Future<void> sendAnalysisSetAnalysisRoots(
      List<String> included, List<String> excluded,
      {Map<String, String>? packageRoots}) async {
    var params = AnalysisSetAnalysisRootsParams(included, excluded,
            packageRoots: packageRoots)
        .toJson();
    var result = await server.send('analysis.setAnalysisRoots', params);
    outOfTestExpect(result, isNull);
  }

  /// Subscribe for general services (that is, services that are not specific
  /// to individual files). All previous subscriptions are replaced by the
  /// given set of services.
  ///
  /// It is an error if any of the elements in the list are not valid services.
  /// If there is an error, then the current subscriptions will remain
  /// unchanged.
  ///
  /// Parameters
  ///
  /// subscriptions: List<GeneralAnalysisService>
  ///
  ///   A list of the services being subscribed to.
  Future<void> sendAnalysisSetGeneralSubscriptions(
      List<GeneralAnalysisService> subscriptions) async {
    var params = AnalysisSetGeneralSubscriptionsParams(subscriptions).toJson();
    var result = await server.send('analysis.setGeneralSubscriptions', params);
    outOfTestExpect(result, isNull);
  }

  /// Set the priority files to the files in the given list. A priority file is
  /// a file that is given priority when scheduling which analysis work to do
  /// first. The list typically contains those files that are visible to the
  /// user and those for which analysis results will have the biggest impact on
  /// the user experience. The order of the files within the list is
  /// significant: the first file will be given higher priority than the
  /// second, the second higher priority than the third, and so on.
  ///
  /// Note that this request determines the set of requested priority files.
  /// The actual set of priority files is the intersection of the requested set
  /// of priority files with the set of files currently subject to analysis.
  /// (See analysis.setSubscriptions for a description of files that are
  /// subject to analysis.)
  ///
  /// If a requested priority file is a directory it is ignored, but remains in
  /// the set of requested priority files so that if it later becomes a file it
  /// can be included in the set of actual priority files.
  ///
  /// Parameters
  ///
  /// files: List<FilePath>
  ///
  ///   The files that are to be a priority for analysis.
  Future<void> sendAnalysisSetPriorityFiles(List<String> files) async {
    var params = AnalysisSetPriorityFilesParams(files).toJson();
    var result = await server.send('analysis.setPriorityFiles', params);
    outOfTestExpect(result, isNull);
  }

  /// Subscribe for services that are specific to individual files. All
  /// previous subscriptions are replaced by the current set of subscriptions.
  /// If a given service is not included as a key in the map then no files will
  /// be subscribed to the service, exactly as if the service had been included
  /// in the map with an explicit empty list of files.
  ///
  /// Note that this request determines the set of requested subscriptions. The
  /// actual set of subscriptions at any given time is the intersection of this
  /// set with the set of files currently subject to analysis. The files
  /// currently subject to analysis are the set of files contained within an
  /// actual analysis root but not excluded, plus all of the files transitively
  /// reachable from those files via import, export and part directives. (See
  /// analysis.setAnalysisRoots for an explanation of how the actual analysis
  /// roots are determined.) When the actual analysis roots change, the actual
  /// set of subscriptions is automatically updated, but the set of requested
  /// subscriptions is unchanged.
  ///
  /// If a requested subscription is a directory it is ignored, but remains in
  /// the set of requested subscriptions so that if it later becomes a file it
  /// can be included in the set of actual subscriptions.
  ///
  /// It is an error if any of the keys in the map are not valid services. If
  /// there is an error, then the existing subscriptions will remain unchanged.
  ///
  /// Parameters
  ///
  /// subscriptions: Map<AnalysisService, List<FilePath>>
  ///
  ///   A table mapping services to a list of the files being subscribed to the
  ///   service.
  Future<void> sendAnalysisSetSubscriptions(
      Map<AnalysisService, List<String>> subscriptions) async {
    var params = AnalysisSetSubscriptionsParams(subscriptions).toJson();
    var result = await server.send('analysis.setSubscriptions', params);
    outOfTestExpect(result, isNull);
  }

  /// Update the content of one or more files. Files that were previously
  /// updated but not included in this update remain unchanged. This
  /// effectively represents an overlay of the filesystem. The files whose
  /// content is overridden are therefore seen by server as being files with
  /// the given content, even if the files do not exist on the filesystem or if
  /// the file path represents the path to a directory on the filesystem.
  ///
  /// Parameters
  ///
  /// files: Map<FilePath, AddContentOverlay | ChangeContentOverlay |
  /// RemoveContentOverlay>
  ///
  ///   A table mapping the files whose content has changed to a description of
  ///   the content change.
  ///
  /// Returns
  Future<AnalysisUpdateContentResult> sendAnalysisUpdateContent(
      Map<String, Object> files) async {
    var params = AnalysisUpdateContentParams(files).toJson();
    var result = await server.send('analysis.updateContent', params);
    var decoder = ResponseDecoder(null);
    return AnalysisUpdateContentResult.fromJson(decoder, 'result', result);
  }

  /// Deprecated: all of the options can be set by users in an analysis options
  /// file.
  ///
  /// Update the options controlling analysis based on the given set of
  /// options. Any options that are not included in the analysis options will
  /// not be changed. If there are options in the analysis options that are not
  /// valid, they will be silently ignored.
  ///
  /// Parameters
  ///
  /// options: AnalysisOptions
  ///
  ///   The options that are to be used to control analysis.
  // TODO(srawlins): Provide a deprecation message, or remove.
  // ignore: provide_deprecation_message
  @deprecated
  Future<void> sendAnalysisUpdateOptions(AnalysisOptions options) async {
    var params = AnalysisUpdateOptionsParams(options).toJson();
    var result = await server.send('analysis.updateOptions', params);
    outOfTestExpect(result, isNull);
  }

  /// Reports the paths of the files that are being analyzed.
  ///
  /// This notification is not subscribed to by default. Clients can subscribe
  /// by including the value "ANALYZED_FILES" in the list of services passed in
  /// an analysis.setGeneralSubscriptions request.
  ///
  /// Parameters
  ///
  /// directories: List<FilePath>
  ///
  ///   A list of the paths of the files that are being analyzed.
  late final Stream<AnalysisAnalyzedFilesParams> onAnalysisAnalyzedFiles =
      _onAnalysisAnalyzedFiles.stream.asBroadcastStream();

  /// Stream controller for [onAnalysisAnalyzedFiles].
  final _onAnalysisAnalyzedFiles =
      StreamController<AnalysisAnalyzedFilesParams>(sync: true);

  /// Reports closing labels relevant to a given file.
  ///
  /// This notification is not subscribed to by default. Clients can subscribe
  /// by including the value "CLOSING_LABELS" in the list of services passed in
  /// an analysis.setSubscriptions request.
  ///
  /// Parameters
  ///
  /// file: FilePath
  ///
  ///   The file the closing labels relate to.
  ///
  /// labels: List<ClosingLabel>
  ///
  ///   Closing labels relevant to the file. Each item represents a useful
  ///   label associated with some range with may be useful to display to the
  ///   user within the editor at the end of the range to indicate what
  ///   construct is closed at that location. Closing labels include
  ///   constructor/method calls and List arguments that span multiple lines.
  ///   Note that the ranges that are returned can overlap each other because
  ///   they may be associated with constructs that can be nested.
  late final Stream<AnalysisClosingLabelsParams> onAnalysisClosingLabels =
      _onAnalysisClosingLabels.stream.asBroadcastStream();

  /// Stream controller for [onAnalysisClosingLabels].
  final _onAnalysisClosingLabels =
      StreamController<AnalysisClosingLabelsParams>(sync: true);

  /// Reports the errors associated with a given file. The set of errors
  /// included in the notification is always a complete list that supersedes
  /// any previously reported errors.
  ///
  /// Parameters
  ///
  /// file: FilePath
  ///
  ///   The file containing the errors.
  ///
  /// errors: List<AnalysisError>
  ///
  ///   The errors contained in the file.
  late final Stream<AnalysisErrorsParams> onAnalysisErrors =
      _onAnalysisErrors.stream.asBroadcastStream();

  /// Stream controller for [onAnalysisErrors].
  final _onAnalysisErrors = StreamController<AnalysisErrorsParams>(sync: true);

  /// Reports that any analysis results that were previously associated with
  /// the given files should be considered to be invalid because those files
  /// are no longer being analyzed, either because the analysis root that
  /// contained it is no longer being analyzed or because the file no longer
  /// exists.
  ///
  /// If a file is included in this notification and at some later time a
  /// notification with results for the file is received, clients should assume
  /// that the file is once again being analyzed and the information should be
  /// processed.
  ///
  /// It is not possible to subscribe to or unsubscribe from this notification.
  ///
  /// Parameters
  ///
  /// files: List<FilePath>
  ///
  ///   The files that are no longer being analyzed.
  late final Stream<AnalysisFlushResultsParams> onAnalysisFlushResults =
      _onAnalysisFlushResults.stream.asBroadcastStream();

  /// Stream controller for [onAnalysisFlushResults].
  final _onAnalysisFlushResults =
      StreamController<AnalysisFlushResultsParams>(sync: true);

  /// Reports the folding regions associated with a given file. Folding regions
  /// can be nested, but will not be overlapping. Nesting occurs when a
  /// foldable element, such as a method, is nested inside another foldable
  /// element such as a class.
  ///
  /// This notification is not subscribed to by default. Clients can subscribe
  /// by including the value "FOLDING" in the list of services passed in an
  /// analysis.setSubscriptions request.
  ///
  /// Parameters
  ///
  /// file: FilePath
  ///
  ///   The file containing the folding regions.
  ///
  /// regions: List<FoldingRegion>
  ///
  ///   The folding regions contained in the file.
  late final Stream<AnalysisFoldingParams> onAnalysisFolding =
      _onAnalysisFolding.stream.asBroadcastStream();

  /// Stream controller for [onAnalysisFolding].
  final _onAnalysisFolding =
      StreamController<AnalysisFoldingParams>(sync: true);

  /// Reports the highlight regions associated with a given file.
  ///
  /// This notification is not subscribed to by default. Clients can subscribe
  /// by including the value "HIGHLIGHTS" in the list of services passed in an
  /// analysis.setSubscriptions request.
  ///
  /// Parameters
  ///
  /// file: FilePath
  ///
  ///   The file containing the highlight regions.
  ///
  /// regions: List<HighlightRegion>
  ///
  ///   The highlight regions contained in the file. Each highlight region
  ///   represents a particular syntactic or semantic meaning associated with
  ///   some range. Note that the highlight regions that are returned can
  ///   overlap other highlight regions if there is more than one meaning
  ///   associated with a particular region.
  late final Stream<AnalysisHighlightsParams> onAnalysisHighlights =
      _onAnalysisHighlights.stream.asBroadcastStream();

  /// Stream controller for [onAnalysisHighlights].
  final _onAnalysisHighlights =
      StreamController<AnalysisHighlightsParams>(sync: true);

  /// Reports the classes that are implemented or extended and class members
  /// that are implemented or overridden in a file.
  ///
  /// This notification is not subscribed to by default. Clients can subscribe
  /// by including the value "IMPLEMENTED" in the list of services passed in an
  /// analysis.setSubscriptions request.
  ///
  /// Parameters
  ///
  /// file: FilePath
  ///
  ///   The file with which the implementations are associated.
  ///
  /// classes: List<ImplementedClass>
  ///
  ///   The classes defined in the file that are implemented or extended.
  ///
  /// members: List<ImplementedMember>
  ///
  ///   The member defined in the file that are implemented or overridden.
  late final Stream<AnalysisImplementedParams> onAnalysisImplemented =
      _onAnalysisImplemented.stream.asBroadcastStream();

  /// Stream controller for [onAnalysisImplemented].
  final _onAnalysisImplemented =
      StreamController<AnalysisImplementedParams>(sync: true);

  /// Reports that the navigation information associated with a region of a
  /// single file has become invalid and should be re-requested.
  ///
  /// This notification is not subscribed to by default. Clients can subscribe
  /// by including the value "INVALIDATE" in the list of services passed in an
  /// analysis.setSubscriptions request.
  ///
  /// Parameters
  ///
  /// file: FilePath
  ///
  ///   The file whose information has been invalidated.
  ///
  /// offset: int
  ///
  ///   The offset of the invalidated region.
  ///
  /// length: int
  ///
  ///   The length of the invalidated region.
  ///
  /// delta: int
  ///
  ///   The delta to be applied to the offsets in information that follows the
  ///   invalidated region in order to update it so that it doesn't need to be
  ///   re-requested.
  late final Stream<AnalysisInvalidateParams> onAnalysisInvalidate =
      _onAnalysisInvalidate.stream.asBroadcastStream();

  /// Stream controller for [onAnalysisInvalidate].
  final _onAnalysisInvalidate =
      StreamController<AnalysisInvalidateParams>(sync: true);

  /// Reports the navigation targets associated with a given file.
  ///
  /// This notification is not subscribed to by default. Clients can subscribe
  /// by including the value "NAVIGATION" in the list of services passed in an
  /// analysis.setSubscriptions request.
  ///
  /// Parameters
  ///
  /// file: FilePath
  ///
  ///   The file containing the navigation regions.
  ///
  /// regions: List<NavigationRegion>
  ///
  ///   The navigation regions contained in the file. The regions are sorted by
  ///   their offsets. Each navigation region represents a list of targets
  ///   associated with some range. The lists will usually contain a single
  ///   target, but can contain more in the case of a part that is included in
  ///   multiple libraries or in Dart code that is compiled against multiple
  ///   versions of a package. Note that the navigation regions that are
  ///   returned do not overlap other navigation regions.
  ///
  /// targets: List<NavigationTarget>
  ///
  ///   The navigation targets referenced in the file. They are referenced by
  ///   NavigationRegions by their index in this array.
  ///
  /// files: List<FilePath>
  ///
  ///   The files containing navigation targets referenced in the file. They
  ///   are referenced by NavigationTargets by their index in this array.
  late final Stream<AnalysisNavigationParams> onAnalysisNavigation =
      _onAnalysisNavigation.stream.asBroadcastStream();

  /// Stream controller for [onAnalysisNavigation].
  final _onAnalysisNavigation =
      StreamController<AnalysisNavigationParams>(sync: true);

  /// Reports the occurrences of references to elements within a single file.
  ///
  /// This notification is not subscribed to by default. Clients can subscribe
  /// by including the value "OCCURRENCES" in the list of services passed in an
  /// analysis.setSubscriptions request.
  ///
  /// Parameters
  ///
  /// file: FilePath
  ///
  ///   The file in which the references occur.
  ///
  /// occurrences: List<Occurrences>
  ///
  ///   The occurrences of references to elements within the file.
  late final Stream<AnalysisOccurrencesParams> onAnalysisOccurrences =
      _onAnalysisOccurrences.stream.asBroadcastStream();

  /// Stream controller for [onAnalysisOccurrences].
  final _onAnalysisOccurrences =
      StreamController<AnalysisOccurrencesParams>(sync: true);

  /// Reports the outline associated with a single file.
  ///
  /// This notification is not subscribed to by default. Clients can subscribe
  /// by including the value "OUTLINE" in the list of services passed in an
  /// analysis.setSubscriptions request.
  ///
  /// Parameters
  ///
  /// file: FilePath
  ///
  ///   The file with which the outline is associated.
  ///
  /// kind: FileKind
  ///
  ///   The kind of the file.
  ///
  /// libraryName: String (optional)
  ///
  ///   The name of the library defined by the file using a "library"
  ///   directive, or referenced by a "part of" directive. If both "library"
  ///   and "part of" directives are present, then the "library" directive
  ///   takes precedence. This field will be omitted if the file has neither
  ///   "library" nor "part of" directives.
  ///
  /// outline: Outline
  ///
  ///   The outline associated with the file.
  late final Stream<AnalysisOutlineParams> onAnalysisOutline =
      _onAnalysisOutline.stream.asBroadcastStream();

  /// Stream controller for [onAnalysisOutline].
  final _onAnalysisOutline =
      StreamController<AnalysisOutlineParams>(sync: true);

  /// Reports the overriding members in a file.
  ///
  /// This notification is not subscribed to by default. Clients can subscribe
  /// by including the value "OVERRIDES" in the list of services passed in an
  /// analysis.setSubscriptions request.
  ///
  /// Parameters
  ///
  /// file: FilePath
  ///
  ///   The file with which the overrides are associated.
  ///
  /// overrides: List<Override>
  ///
  ///   The overrides associated with the file.
  late final Stream<AnalysisOverridesParams> onAnalysisOverrides =
      _onAnalysisOverrides.stream.asBroadcastStream();

  /// Stream controller for [onAnalysisOverrides].
  final _onAnalysisOverrides =
      StreamController<AnalysisOverridesParams>(sync: true);

  /// Request that completion suggestions for the given offset in the given
  /// file be returned.
  ///
  /// Parameters
  ///
  /// file: FilePath
  ///
  ///   The file containing the point at which suggestions are to be made.
  ///
  /// offset: int
  ///
  ///   The offset within the file at which suggestions are to be made.
  ///
  /// Returns
  ///
  /// id: CompletionId
  ///
  ///   The identifier used to associate results with this completion request.
  Future<CompletionGetSuggestionsResult> sendCompletionGetSuggestions(
      String file, int offset) async {
    var params = CompletionGetSuggestionsParams(file, offset).toJson();
    var result = await server.send('completion.getSuggestions', params);
    var decoder = ResponseDecoder(null);
    return CompletionGetSuggestionsResult.fromJson(decoder, 'result', result);
  }

  /// Request that completion suggestions for the given offset in the given
  /// file be returned. The suggestions will be filtered using fuzzy matching
  /// with the already existing prefix.
  ///
  /// Parameters
  ///
  /// file: FilePath
  ///
  ///   The file containing the point at which suggestions are to be made.
  ///
  /// offset: int
  ///
  ///   The offset within the file at which suggestions are to be made.
  ///
  /// maxResults: int
  ///
  ///   The maximum number of suggestions to return. If the number of
  ///   suggestions after filtering is greater than the maxResults, then
  ///   isIncomplete is set to true.
  ///
  /// completionCaseMatchingMode: CompletionCaseMatchingMode (optional)
  ///
  ///   The mode of code completion being invoked. If no value is provided,
  ///   MATCH_FIRST_CHAR will be assumed.
  ///
  /// Returns
  ///
  /// replacementOffset: int
  ///
  ///   The offset of the start of the text to be replaced. This will be
  ///   different from the offset used to request the completion suggestions if
  ///   there was a portion of an identifier before the original offset. In
  ///   particular, the replacementOffset will be the offset of the beginning
  ///   of said identifier.
  ///
  /// replacementLength: int
  ///
  ///   The length of the text to be replaced if the remainder of the
  ///   identifier containing the cursor is to be replaced when the suggestion
  ///   is applied (that is, the number of characters in the existing
  ///   identifier).
  ///
  /// suggestions: List<CompletionSuggestion>
  ///
  ///   The completion suggestions being reported. This list is filtered by the
  ///   already existing prefix, and sorted first by relevance, and (if the
  ///   same) by the suggestion text. The list will have at most maxResults
  ///   items. If the user types a new keystroke, the client is expected to
  ///   either do local filtering (when the returned list was complete), or ask
  ///   the server again (if isIncomplete was true).
  ///
  ///   This list contains suggestions from both imported, and not yet imported
  ///   libraries. Items from not yet imported libraries will have
  ///   isNotImported set to true.
  ///
  /// isIncomplete: bool
  ///
  ///   True if the number of suggestions after filtering was greater than the
  ///   requested maxResults.
  Future<CompletionGetSuggestions2Result> sendCompletionGetSuggestions2(
      String file, int offset, int maxResults,
      {CompletionCaseMatchingMode? completionCaseMatchingMode,
      CompletionMode? completionMode,
      int? invocationCount,
      int? timeout}) async {
    var params = CompletionGetSuggestions2Params(file, offset, maxResults,
            completionCaseMatchingMode: completionCaseMatchingMode,
            completionMode: completionMode,
            invocationCount: invocationCount,
            timeout: timeout)
        .toJson();
    var result = await server.send('completion.getSuggestions2', params);
    var decoder = ResponseDecoder(null);
    return CompletionGetSuggestions2Result.fromJson(decoder, 'result', result);
  }

  /// Subscribe for completion services. All previous subscriptions are
  /// replaced by the given set of services.
  ///
  /// It is an error if any of the elements in the list are not valid services.
  /// If there is an error, then the current subscriptions will remain
  /// unchanged.
  ///
  /// Parameters
  ///
  /// subscriptions: List<CompletionService>
  ///
  ///   A list of the services being subscribed to.
  Future<void> sendCompletionSetSubscriptions(
      List<CompletionService> subscriptions) async {
    var params = CompletionSetSubscriptionsParams(subscriptions).toJson();
    var result = await server.send('completion.setSubscriptions', params);
    outOfTestExpect(result, isNull);
  }

  /// The client can make this request to express interest in certain libraries
  /// to receive completion suggestions from based on the client path. If this
  /// request is received before the client has used
  /// 'completion.setSubscriptions' to subscribe to the
  /// AVAILABLE_SUGGESTION_SETS service, then an error of type
  /// NOT_SUBSCRIBED_TO_AVAILABLE_SUGGESTION_SETS will be generated. All
  /// previous paths are replaced by the given set of paths.
  ///
  /// Parameters
  ///
  /// paths: List<LibraryPathSet>
  ///
  ///   A list of objects each containing a path and the additional libraries
  ///   from which the client is interested in receiving completion
  ///   suggestions. If one configured path is beneath another, the descendant
  ///   will override the ancestors' configured libraries of interest.
  // TODO(srawlins): Provide a deprecation message, or remove.
  // ignore: provide_deprecation_message
  @deprecated
  Future<void> sendCompletionRegisterLibraryPaths(
      List<LibraryPathSet> paths) async {
    var params = CompletionRegisterLibraryPathsParams(paths).toJson();
    var result = await server.send('completion.registerLibraryPaths', params);
    outOfTestExpect(result, isNull);
  }

  /// Clients must make this request when the user has selected a completion
  /// suggestion from an AvailableSuggestionSet. Analysis server will respond
  /// with the text to insert as well as any SourceChange that needs to be
  /// applied in case the completion requires an additional import to be added.
  /// It is an error if the id is no longer valid, for instance if the library
  /// has been removed after the completion suggestion is accepted.
  ///
  /// Parameters
  ///
  /// file: FilePath
  ///
  ///   The path of the file into which this completion is being inserted.
  ///
  /// id: int
  ///
  ///   The identifier of the AvailableSuggestionSet containing the selected
  ///   label.
  ///
  /// label: String
  ///
  ///   The label from the AvailableSuggestionSet with the `id` for which
  ///   insertion information is requested.
  ///
  /// offset: int
  ///
  ///   The offset in the file where the completion will be inserted.
  ///
  /// Returns
  ///
  /// completion: String
  ///
  ///   The full text to insert, including any optional import prefix.
  ///
  /// change: SourceChange (optional)
  ///
  ///   A change for the client to apply in case the library containing the
  ///   accepted completion suggestion needs to be imported. The field will be
  ///   omitted if there are no additional changes that need to be made.
  Future<CompletionGetSuggestionDetailsResult>
      sendCompletionGetSuggestionDetails(
          String file, int id, String label, int offset) async {
    var params =
        CompletionGetSuggestionDetailsParams(file, id, label, offset).toJson();
    var result = await server.send('completion.getSuggestionDetails', params);
    var decoder = ResponseDecoder(null);
    return CompletionGetSuggestionDetailsResult.fromJson(
        decoder, 'result', result);
  }

  /// Clients must make this request when the user has selected a completion
  /// suggestion with the isNotImported field set to true. The server will
  /// respond with the text to insert, as well as any SourceChange that needs
  /// to be applied in case the completion requires an additional import to be
  /// added. The text to insert might be different from the original suggestion
  /// to include an import prefix if the library will be imported with a prefix
  /// to avoid shadowing conflicts in the file.
  ///
  /// Parameters
  ///
  /// file: FilePath
  ///
  ///   The path of the file into which this completion is being inserted.
  ///
  /// offset: int
  ///
  ///   The offset in the file where the completion will be inserted.
  ///
  /// completion: String
  ///
  ///   The completion from the selected CompletionSuggestion. It could be a
  ///   name of a class, or a name of a constructor in form
  ///   "typeName.constructorName()", or an enumeration constant in form
  ///   "enumName.constantName", etc.
  ///
  /// libraryUri: String
  ///
  ///   The URI of the library to import, so that the element referenced in the
  ///   completion becomes accessible.
  ///
  /// Returns
  ///
  /// completion: String
  ///
  ///   The full text to insert, which possibly includes now an import prefix.
  ///   The client should insert this text, not the completion from the
  ///   selected CompletionSuggestion.
  ///
  /// change: SourceChange
  ///
  ///   A change for the client to apply to make the accepted completion
  ///   suggestion available. In most cases the change is to add a new import
  ///   directive to the file.
  Future<CompletionGetSuggestionDetails2Result>
      sendCompletionGetSuggestionDetails2(
          String file, int offset, String completion, String libraryUri) async {
    var params = CompletionGetSuggestionDetails2Params(
            file, offset, completion, libraryUri)
        .toJson();
    var result = await server.send('completion.getSuggestionDetails2', params);
    var decoder = ResponseDecoder(null);
    return CompletionGetSuggestionDetails2Result.fromJson(
        decoder, 'result', result);
  }

  /// Reports the completion suggestions that should be presented to the user.
  /// The set of suggestions included in the notification is always a complete
  /// list that supersedes any previously reported suggestions.
  ///
  /// Parameters
  ///
  /// id: CompletionId
  ///
  ///   The id associated with the completion.
  ///
  /// replacementOffset: int
  ///
  ///   The offset of the start of the text to be replaced. This will be
  ///   different than the offset used to request the completion suggestions if
  ///   there was a portion of an identifier before the original offset. In
  ///   particular, the replacementOffset will be the offset of the beginning
  ///   of said identifier.
  ///
  /// replacementLength: int
  ///
  ///   The length of the text to be replaced if the remainder of the
  ///   identifier containing the cursor is to be replaced when the suggestion
  ///   is applied (that is, the number of characters in the existing
  ///   identifier).
  ///
  /// results: List<CompletionSuggestion>
  ///
  ///   The completion suggestions being reported. The notification contains
  ///   all possible completions at the requested cursor position, even those
  ///   that do not match the characters the user has already typed. This
  ///   allows the client to respond to further keystrokes from the user
  ///   without having to make additional requests.
  ///
  /// isLast: bool
  ///
  ///   True if this is that last set of results that will be returned for the
  ///   indicated completion.
  ///
  /// libraryFile: FilePath (optional)
  ///
  ///   The library file that contains the file where completion was requested.
  ///   The client might use it for example together with the existingImports
  ///   notification to filter out available suggestions. If there were changes
  ///   to existing imports in the library, the corresponding existingImports
  ///   notification will be sent before the completion notification.
  ///
  /// includedSuggestionSets: List<IncludedSuggestionSet> (optional)
  ///
  ///   References to AvailableSuggestionSet objects previously sent to the
  ///   client. The client can include applicable names from the referenced
  ///   library in code completion suggestions.
  ///
  /// includedElementKinds: List<ElementKind> (optional)
  ///
  ///   The client is expected to check this list against the ElementKind sent
  ///   in IncludedSuggestionSet to decide whether or not these symbols should
  ///   be presented to the user.
  ///
  /// includedSuggestionRelevanceTags: List<IncludedSuggestionRelevanceTag>
  /// (optional)
  ///
  ///   The client is expected to check this list against the values of the
  ///   field relevanceTags of AvailableSuggestion to decide if the suggestion
  ///   should be given a different relevance than the IncludedSuggestionSet
  ///   that contains it. This might be used for example to give higher
  ///   relevance to suggestions of matching types.
  ///
  ///   If an AvailableSuggestion has relevance tags that match more than one
  ///   IncludedSuggestionRelevanceTag, the maximum relevance boost is used.
  late final Stream<CompletionResultsParams> onCompletionResults =
      _onCompletionResults.stream.asBroadcastStream();

  /// Stream controller for [onCompletionResults].
  final _onCompletionResults =
      StreamController<CompletionResultsParams>(sync: true);

  /// Reports the pre-computed, candidate completions from symbols defined in a
  /// corresponding library. This notification may be sent multiple times. When
  /// a notification is processed, clients should replace any previous
  /// information about the libraries in the list of changedLibraries, discard
  /// any information about the libraries in the list of removedLibraries, and
  /// preserve any previously received information about any libraries that are
  /// not included in either list.
  ///
  /// Parameters
  ///
  /// changedLibraries: List<AvailableSuggestionSet> (optional)
  ///
  ///   A list of pre-computed, potential completions coming from this set of
  ///   completion suggestions.
  ///
  /// removedLibraries: List<int> (optional)
  ///
  ///   A list of library ids that no longer apply.
  late final Stream<CompletionAvailableSuggestionsParams>
      onCompletionAvailableSuggestions =
      _onCompletionAvailableSuggestions.stream.asBroadcastStream();

  /// Stream controller for [onCompletionAvailableSuggestions].
  final _onCompletionAvailableSuggestions =
      StreamController<CompletionAvailableSuggestionsParams>(sync: true);

  /// Reports existing imports in a library. This notification may be sent
  /// multiple times for a library. When a notification is processed, clients
  /// should replace any previous information for the library.
  ///
  /// Parameters
  ///
  /// file: FilePath
  ///
  ///   The defining file of the library.
  ///
  /// imports: ExistingImports
  ///
  ///   The existing imports in the library.
  late final Stream<CompletionExistingImportsParams>
      onCompletionExistingImports =
      _onCompletionExistingImports.stream.asBroadcastStream();

  /// Stream controller for [onCompletionExistingImports].
  final _onCompletionExistingImports =
      StreamController<CompletionExistingImportsParams>(sync: true);

  /// Perform a search for references to the element defined or referenced at
  /// the given offset in the given file.
  ///
  /// An identifier is returned immediately, and individual results will be
  /// returned via the search.results notification as they become available.
  ///
  /// Parameters
  ///
  /// file: FilePath
  ///
  ///   The file containing the declaration of or reference to the element used
  ///   to define the search.
  ///
  /// offset: int
  ///
  ///   The offset within the file of the declaration of or reference to the
  ///   element.
  ///
  /// includePotential: bool
  ///
  ///   True if potential matches are to be included in the results.
  ///
  /// Returns
  ///
  /// id: SearchId (optional)
  ///
  ///   The identifier used to associate results with this search request.
  ///
  ///   If no element was found at the given location, this field will be
  ///   absent, and no results will be reported via the search.results
  ///   notification.
  ///
  /// element: Element (optional)
  ///
  ///   The element referenced or defined at the given offset and whose
  ///   references will be returned in the search results.
  ///
  ///   If no element was found at the given location, this field will be
  ///   absent.
  Future<SearchFindElementReferencesResult> sendSearchFindElementReferences(
      String file, int offset, bool includePotential) async {
    var params =
        SearchFindElementReferencesParams(file, offset, includePotential)
            .toJson();
    var result = await server.send('search.findElementReferences', params);
    var decoder = ResponseDecoder(null);
    return SearchFindElementReferencesResult.fromJson(
        decoder, 'result', result);
  }

  /// Perform a search for declarations of members whose name is equal to the
  /// given name.
  ///
  /// An identifier is returned immediately, and individual results will be
  /// returned via the search.results notification as they become available.
  ///
  /// Parameters
  ///
  /// name: String
  ///
  ///   The name of the declarations to be found.
  ///
  /// Returns
  ///
  /// id: SearchId
  ///
  ///   The identifier used to associate results with this search request.
  Future<SearchFindMemberDeclarationsResult> sendSearchFindMemberDeclarations(
      String name) async {
    var params = SearchFindMemberDeclarationsParams(name).toJson();
    var result = await server.send('search.findMemberDeclarations', params);
    var decoder = ResponseDecoder(null);
    return SearchFindMemberDeclarationsResult.fromJson(
        decoder, 'result', result);
  }

  /// Perform a search for references to members whose name is equal to the
  /// given name. This search does not check to see that there is a member
  /// defined with the given name, so it is able to find references to
  /// undefined members as well.
  ///
  /// An identifier is returned immediately, and individual results will be
  /// returned via the search.results notification as they become available.
  ///
  /// Parameters
  ///
  /// name: String
  ///
  ///   The name of the references to be found.
  ///
  /// Returns
  ///
  /// id: SearchId
  ///
  ///   The identifier used to associate results with this search request.
  Future<SearchFindMemberReferencesResult> sendSearchFindMemberReferences(
      String name) async {
    var params = SearchFindMemberReferencesParams(name).toJson();
    var result = await server.send('search.findMemberReferences', params);
    var decoder = ResponseDecoder(null);
    return SearchFindMemberReferencesResult.fromJson(decoder, 'result', result);
  }

  /// Perform a search for declarations of top-level elements (classes,
  /// typedefs, getters, setters, functions and fields) whose name matches the
  /// given pattern.
  ///
  /// An identifier is returned immediately, and individual results will be
  /// returned via the search.results notification as they become available.
  ///
  /// Parameters
  ///
  /// pattern: String
  ///
  ///   The regular expression used to match the names of the declarations to
  ///   be found.
  ///
  /// Returns
  ///
  /// id: SearchId
  ///
  ///   The identifier used to associate results with this search request.
  Future<SearchFindTopLevelDeclarationsResult>
      sendSearchFindTopLevelDeclarations(String pattern) async {
    var params = SearchFindTopLevelDeclarationsParams(pattern).toJson();
    var result = await server.send('search.findTopLevelDeclarations', params);
    var decoder = ResponseDecoder(null);
    return SearchFindTopLevelDeclarationsResult.fromJson(
        decoder, 'result', result);
  }

  /// Return top-level and class member declarations.
  ///
  /// Parameters
  ///
  /// file: FilePath (optional)
  ///
  ///   If this field is provided, return only declarations in this file. If
  ///   this field is missing, return declarations in all files.
  ///
  /// pattern: String (optional)
  ///
  ///   The regular expression used to match the names of declarations. If this
  ///   field is missing, return all declarations.
  ///
  /// maxResults: int (optional)
  ///
  ///   The maximum number of declarations to return. If this field is missing,
  ///   return all matching declarations.
  ///
  /// Returns
  ///
  /// declarations: List<ElementDeclaration>
  ///
  ///   The list of declarations.
  ///
  /// files: List<FilePath>
  ///
  ///   The list of the paths of files with declarations.
  Future<SearchGetElementDeclarationsResult> sendSearchGetElementDeclarations(
      {String? file, String? pattern, int? maxResults}) async {
    var params = SearchGetElementDeclarationsParams(
            file: file, pattern: pattern, maxResults: maxResults)
        .toJson();
    var result = await server.send('search.getElementDeclarations', params);
    var decoder = ResponseDecoder(null);
    return SearchGetElementDeclarationsResult.fromJson(
        decoder, 'result', result);
  }

  /// Return the type hierarchy of the class declared or referenced at the
  /// given location.
  ///
  /// Parameters
  ///
  /// file: FilePath
  ///
  ///   The file containing the declaration or reference to the type for which
  ///   a hierarchy is being requested.
  ///
  /// offset: int
  ///
  ///   The offset of the name of the type within the file.
  ///
  /// superOnly: bool (optional)
  ///
  ///   True if the client is only requesting superclasses and interfaces
  ///   hierarchy.
  ///
  /// Returns
  ///
  /// hierarchyItems: List<TypeHierarchyItem> (optional)
  ///
  ///   A list of the types in the requested hierarchy. The first element of
  ///   the list is the item representing the type for which the hierarchy was
  ///   requested. The index of other elements of the list is unspecified, but
  ///   correspond to the integers used to reference supertype and subtype
  ///   items within the items.
  ///
  ///   This field will be absent if the code at the given file and offset does
  ///   not represent a type, or if the file has not been sufficiently analyzed
  ///   to allow a type hierarchy to be produced.
  Future<SearchGetTypeHierarchyResult> sendSearchGetTypeHierarchy(
      String file, int offset,
      {bool? superOnly}) async {
    var params =
        SearchGetTypeHierarchyParams(file, offset, superOnly: superOnly)
            .toJson();
    var result = await server.send('search.getTypeHierarchy', params);
    var decoder = ResponseDecoder(null);
    return SearchGetTypeHierarchyResult.fromJson(decoder, 'result', result);
  }

  /// Reports some or all of the results of performing a requested search.
  /// Unlike other notifications, this notification contains search results
  /// that should be added to any previously received search results associated
  /// with the same search id.
  ///
  /// Parameters
  ///
  /// id: SearchId
  ///
  ///   The id associated with the search.
  ///
  /// results: List<SearchResult>
  ///
  ///   The search results being reported.
  ///
  /// isLast: bool
  ///
  ///   True if this is that last set of results that will be returned for the
  ///   indicated search.
  late final Stream<SearchResultsParams> onSearchResults =
      _onSearchResults.stream.asBroadcastStream();

  /// Stream controller for [onSearchResults].
  final _onSearchResults = StreamController<SearchResultsParams>(sync: true);

  /// Format the contents of a single file. The currently selected region of
  /// text is passed in so that the selection can be preserved across the
  /// formatting operation. The updated selection will be as close to matching
  /// the original as possible, but whitespace at the beginning or end of the
  /// selected region will be ignored. If preserving selection information is
  /// not required, zero (0) can be specified for both the selection offset and
  /// selection length.
  ///
  /// If a request is made for a file which does not exist, or which is not
  /// currently subject to analysis (e.g. because it is not associated with any
  /// analysis root specified to analysis.setAnalysisRoots), an error of type
  /// FORMAT_INVALID_FILE will be generated. If the source contains syntax
  /// errors, an error of type FORMAT_WITH_ERRORS will be generated.
  ///
  /// Parameters
  ///
  /// file: FilePath
  ///
  ///   The file containing the code to be formatted.
  ///
  /// selectionOffset: int
  ///
  ///   The offset of the current selection in the file.
  ///
  /// selectionLength: int
  ///
  ///   The length of the current selection in the file.
  ///
  /// lineLength: int (optional)
  ///
  ///   The line length to be used by the formatter.
  ///
  /// Returns
  ///
  /// edits: List<SourceEdit>
  ///
  ///   The edit(s) to be applied in order to format the code. The list will be
  ///   empty if the code was already formatted (there are no changes).
  ///
  /// selectionOffset: int
  ///
  ///   The offset of the selection after formatting the code.
  ///
  /// selectionLength: int
  ///
  ///   The length of the selection after formatting the code.
  Future<EditFormatResult> sendEditFormat(
      String file, int selectionOffset, int selectionLength,
      {int? lineLength}) async {
    var params = EditFormatParams(file, selectionOffset, selectionLength,
            lineLength: lineLength)
        .toJson();
    var result = await server.send('edit.format', params);
    var decoder = ResponseDecoder(null);
    return EditFormatResult.fromJson(decoder, 'result', result);
  }

  /// Format the contents of the files in one or more directories, but only if
  /// the analysis options file for those files has enabled the 'format'
  /// option.
  ///
  /// If any of the specified directories does not exist, that directory will
  /// be ignored. If any of the files that are eligible for being formatted
  /// cannot be formatted because of a syntax error in the file, that file will
  /// be ignored.
  ///
  /// Parameters
  ///
  /// directories: List<FilePath>
  ///
  ///   The paths of the directories containing the code to be formatted.
  ///
  /// Returns
  ///
  /// edits: List<SourceFileEdit>
  ///
  ///   The edit(s) to be applied in order to format the code. The list will be
  ///   empty if none of the files were formatted, whether because they were
  ///   not eligible to be formatted or because they were already formatted.
  Future<EditFormatIfEnabledResult> sendEditFormatIfEnabled(
      List<String> directories) async {
    var params = EditFormatIfEnabledParams(directories).toJson();
    var result = await server.send('edit.formatIfEnabled', params);
    var decoder = ResponseDecoder(null);
    return EditFormatIfEnabledResult.fromJson(decoder, 'result', result);
  }

  /// Return the set of assists that are available at the given location. An
  /// assist is distinguished from a refactoring primarily by the fact that it
  /// affects a single file and does not require user input in order to be
  /// performed.
  ///
  /// Parameters
  ///
  /// file: FilePath
  ///
  ///   The file containing the code for which assists are being requested.
  ///
  /// offset: int
  ///
  ///   The offset of the code for which assists are being requested.
  ///
  /// length: int
  ///
  ///   The length of the code for which assists are being requested.
  ///
  /// Returns
  ///
  /// assists: List<SourceChange>
  ///
  ///   The assists that are available at the given location.
  Future<EditGetAssistsResult> sendEditGetAssists(
      String file, int offset, int length) async {
    var params = EditGetAssistsParams(file, offset, length).toJson();
    var result = await server.send('edit.getAssists', params);
    var decoder = ResponseDecoder(null);
    return EditGetAssistsResult.fromJson(decoder, 'result', result);
  }

  /// Get a list of the kinds of refactorings that are valid for the given
  /// selection in the given file.
  ///
  /// Parameters
  ///
  /// file: FilePath
  ///
  ///   The file containing the code on which the refactoring would be based.
  ///
  /// offset: int
  ///
  ///   The offset of the code on which the refactoring would be based.
  ///
  /// length: int
  ///
  ///   The length of the code on which the refactoring would be based.
  ///
  /// Returns
  ///
  /// kinds: List<RefactoringKind>
  ///
  ///   The kinds of refactorings that are valid for the given selection.
  Future<EditGetAvailableRefactoringsResult> sendEditGetAvailableRefactorings(
      String file, int offset, int length) async {
    var params =
        EditGetAvailableRefactoringsParams(file, offset, length).toJson();
    var result = await server.send('edit.getAvailableRefactorings', params);
    var decoder = ResponseDecoder(null);
    return EditGetAvailableRefactoringsResult.fromJson(
        decoder, 'result', result);
  }

  /// Analyze the specified sources for fixes that can be applied in bulk and
  /// return a set of suggested edits for those sources. These edits may
  /// include changes to sources outside the set of specified sources if a
  /// change in a specified source requires it.
  ///
  /// Parameters
  ///
  /// included: List<FilePath>
  ///
  ///   A list of the files and directories for which edits should be
  ///   suggested.
  ///
  ///   If a request is made with a path that is invalid, e.g. is not absolute
  ///   and normalized, an error of type INVALID_FILE_PATH_FORMAT will be
  ///   generated. If a request is made for a file which does not exist, or
  ///   which is not currently subject to analysis (e.g. because it is not
  ///   associated with any analysis root specified to
  ///   analysis.setAnalysisRoots), an error of type FILE_NOT_ANALYZED will be
  ///   generated.
  ///
  /// inTestMode: bool (optional)
  ///
  ///   A flag indicating whether the bulk fixes are being run in test mode.
  ///   The only difference is that in test mode the fix processor will look
  ///   for a configuration file that can modify the content of the data file
  ///   used to compute the fixes when data-driven fixes are being considered.
  ///
  ///   If this field is omitted the flag defaults to false.
  ///
  /// updatePubspec: bool (optional)
  ///
  ///   A flag indicating whether to validate that the dependencies used by the
  ///   included files are listed in the pubspec file. If specified, the fix
  ///   processor will compute the set of packages imported in the source and
  ///   check to see if they are listed in the corresponding pubspec file, and
  ///   compute the fixes, if any.
  ///
  ///   If this field is omitted the flag defaults to false.
  ///
  /// codes: List<String> (optional)
  ///
  ///   A list of diagnostic codes to be fixed.
  ///
  /// Returns
  ///
  /// message: String
  ///
  ///   An optional message explaining unapplied fixes.
  ///
  /// edits: List<SourceFileEdit>
  ///
  ///   A list of source edits to apply the recommended changes.
  ///
  /// details: List<BulkFix>
  ///
  ///   Details that summarize the fixes associated with the recommended
  ///   changes.
  Future<EditBulkFixesResult> sendEditBulkFixes(List<String> included,
      {bool? inTestMode, bool? updatePubspec, List<String>? codes}) async {
    var params = EditBulkFixesParams(included,
            inTestMode: inTestMode, updatePubspec: updatePubspec, codes: codes)
        .toJson();
    var result = await server.send('edit.bulkFixes', params);
    var decoder = ResponseDecoder(null);
    return EditBulkFixesResult.fromJson(decoder, 'result', result);
  }

  /// Return the set of fixes that are available for the errors at a given
  /// offset in a given file.
  ///
  /// If a request is made for a file which does not exist, or which is not
  /// currently subject to analysis (e.g. because it is not associated with any
  /// analysis root specified to analysis.setAnalysisRoots), an error of type
  /// GET_FIXES_INVALID_FILE will be generated.
  ///
  /// Parameters
  ///
  /// file: FilePath
  ///
  ///   The file containing the errors for which fixes are being requested.
  ///
  /// offset: int
  ///
  ///   The offset used to select the errors for which fixes will be returned.
  ///
  /// Returns
  ///
  /// fixes: List<AnalysisErrorFixes>
  ///
  ///   The fixes that are available for the errors at the given offset.
  Future<EditGetFixesResult> sendEditGetFixes(String file, int offset) async {
    var params = EditGetFixesParams(file, offset).toJson();
    var result = await server.send('edit.getFixes', params);
    var decoder = ResponseDecoder(null);
    return EditGetFixesResult.fromJson(decoder, 'result', result);
  }

  /// Get the changes required to convert the postfix template at the given
  /// location into the template's expanded form.
  ///
  /// Parameters
  ///
  /// file: FilePath
  ///
  ///   The file containing the postfix template to be expanded.
  ///
  /// key: String
  ///
  ///   The unique name that identifies the template in use.
  ///
  /// offset: int
  ///
  ///   The offset used to identify the code to which the template will be
  ///   applied.
  ///
  /// Returns
  ///
  /// change: SourceChange
  ///
  ///   The change to be applied in order to complete the statement.
  Future<EditGetPostfixCompletionResult> sendEditGetPostfixCompletion(
      String file, String key, int offset) async {
    var params = EditGetPostfixCompletionParams(file, key, offset).toJson();
    var result = await server.send('edit.getPostfixCompletion', params);
    var decoder = ResponseDecoder(null);
    return EditGetPostfixCompletionResult.fromJson(decoder, 'result', result);
  }

  /// Get the changes required to perform a refactoring.
  ///
  /// If another refactoring request is received during the processing of this
  /// one, an error of type REFACTORING_REQUEST_CANCELLED will be generated.
  ///
  /// Parameters
  ///
  /// kind: RefactoringKind
  ///
  ///   The kind of refactoring to be performed.
  ///
  /// file: FilePath
  ///
  ///   The file containing the code involved in the refactoring.
  ///
  /// offset: int
  ///
  ///   The offset of the region involved in the refactoring.
  ///
  /// length: int
  ///
  ///   The length of the region involved in the refactoring.
  ///
  /// validateOnly: bool
  ///
  ///   True if the client is only requesting that the values of the options be
  ///   validated and no change be generated.
  ///
  /// options: RefactoringOptions (optional)
  ///
  ///   Data used to provide values provided by the user. The structure of the
  ///   data is dependent on the kind of refactoring being performed. The data
  ///   that is expected is documented in the section titled Refactorings,
  ///   labeled as "Options". This field can be omitted if the refactoring does
  ///   not require any options or if the values of those options are not
  ///   known.
  ///
  /// Returns
  ///
  /// initialProblems: List<RefactoringProblem>
  ///
  ///   The initial status of the refactoring, i.e. problems related to the
  ///   context in which the refactoring is requested. The array will be empty
  ///   if there are no known problems.
  ///
  /// optionsProblems: List<RefactoringProblem>
  ///
  ///   The options validation status, i.e. problems in the given options, such
  ///   as light-weight validation of a new name, flags compatibility, etc. The
  ///   array will be empty if there are no known problems.
  ///
  /// finalProblems: List<RefactoringProblem>
  ///
  ///   The final status of the refactoring, i.e. problems identified in the
  ///   result of a full, potentially expensive validation and / or change
  ///   creation. The array will be empty if there are no known problems.
  ///
  /// feedback: RefactoringFeedback (optional)
  ///
  ///   Data used to provide feedback to the user. The structure of the data is
  ///   dependent on the kind of refactoring being created. The data that is
  ///   returned is documented in the section titled Refactorings, labeled as
  ///   "Feedback".
  ///
  /// change: SourceChange (optional)
  ///
  ///   The changes that are to be applied to affect the refactoring. This
  ///   field will be omitted if there are problems that prevent a set of
  ///   changes from being computed, such as having no options specified for a
  ///   refactoring that requires them, or if only validation was requested.
  ///
  /// potentialEdits: List<String> (optional)
  ///
  ///   The ids of source edits that are not known to be valid. An edit is not
  ///   known to be valid if there was insufficient type information for the
  ///   server to be able to determine whether or not the code needs to be
  ///   modified, such as when a member is being renamed and there is a
  ///   reference to a member from an unknown type. This field will be omitted
  ///   if the change field is omitted or if there are no potential edits for
  ///   the refactoring.
  Future<EditGetRefactoringResult> sendEditGetRefactoring(RefactoringKind kind,
      String file, int offset, int length, bool validateOnly,
      {RefactoringOptions? options}) async {
    var params = EditGetRefactoringParams(
            kind, file, offset, length, validateOnly,
            options: options)
        .toJson();
    var result = await server.send('edit.getRefactoring', params);
    var decoder = ResponseDecoder(kind);
    return EditGetRefactoringResult.fromJson(decoder, 'result', result);
  }

  /// Get the changes required to convert the partial statement at the given
  /// location into a syntactically valid statement. If the current statement
  /// is already valid the change will insert a newline plus appropriate
  /// indentation at the end of the line containing the offset. If a change
  /// that makes the statement valid cannot be determined (perhaps because it
  /// has not yet been implemented) the statement will be considered already
  /// valid and the appropriate change returned.
  ///
  /// Parameters
  ///
  /// file: FilePath
  ///
  ///   The file containing the statement to be completed.
  ///
  /// offset: int
  ///
  ///   The offset used to identify the statement to be completed.
  ///
  /// Returns
  ///
  /// change: SourceChange
  ///
  ///   The change to be applied in order to complete the statement.
  ///
  /// whitespaceOnly: bool
  ///
  ///   Will be true if the change contains nothing but whitespace characters,
  ///   or is empty.
  Future<EditGetStatementCompletionResult> sendEditGetStatementCompletion(
      String file, int offset) async {
    var params = EditGetStatementCompletionParams(file, offset).toJson();
    var result = await server.send('edit.getStatementCompletion', params);
    var decoder = ResponseDecoder(null);
    return EditGetStatementCompletionResult.fromJson(decoder, 'result', result);
  }

  /// Determine if the request postfix completion template is applicable at the
  /// given location in the given file.
  ///
  /// Parameters
  ///
  /// file: FilePath
  ///
  ///   The file containing the postfix template to be expanded.
  ///
  /// key: String
  ///
  ///   The unique name that identifies the template in use.
  ///
  /// offset: int
  ///
  ///   The offset used to identify the code to which the template will be
  ///   applied.
  ///
  /// Returns
  ///
  /// value: bool
  ///
  ///   True if the template can be expanded at the given location.
  Future<EditIsPostfixCompletionApplicableResult>
      sendEditIsPostfixCompletionApplicable(
          String file, String key, int offset) async {
    var params =
        EditIsPostfixCompletionApplicableParams(file, key, offset).toJson();
    var result =
        await server.send('edit.isPostfixCompletionApplicable', params);
    var decoder = ResponseDecoder(null);
    return EditIsPostfixCompletionApplicableResult.fromJson(
        decoder, 'result', result);
  }

  /// Return a list of all postfix templates currently available.
  ///
  /// Returns
  ///
  /// templates: List<PostfixTemplateDescriptor>
  ///
  ///   The list of available templates.
  Future<EditListPostfixCompletionTemplatesResult>
      sendEditListPostfixCompletionTemplates() async {
    var result = await server.send('edit.listPostfixCompletionTemplates', null);
    var decoder = ResponseDecoder(null);
    return EditListPostfixCompletionTemplatesResult.fromJson(
        decoder, 'result', result);
  }

  /// Return a list of edits that would need to be applied in order to ensure
  /// that all of the elements in the specified list of imported elements are
  /// accessible within the library.
  ///
  /// If a request is made for a file that does not exist, or that is not
  /// currently subject to analysis (e.g. because it is not associated with any
  /// analysis root specified via analysis.setAnalysisRoots), an error of type
  /// IMPORT_ELEMENTS_INVALID_FILE will be generated.
  ///
  /// Parameters
  ///
  /// file: FilePath
  ///
  ///   The file in which the specified elements are to be made accessible.
  ///
  /// elements: List<ImportedElements>
  ///
  ///   The elements to be made accessible in the specified file.
  ///
  /// offset: int (optional)
  ///
  ///   The offset at which the specified elements need to be made accessible.
  ///   If provided, this is used to guard against adding imports for text that
  ///   would be inserted into a comment, string literal, or other location
  ///   where the imports would not be necessary.
  ///
  /// Returns
  ///
  /// edit: SourceFileEdit (optional)
  ///
  ///   The edits to be applied in order to make the specified elements
  ///   accessible. The file to be edited will be the defining compilation unit
  ///   of the library containing the file specified in the request, which can
  ///   be different than the file specified in the request if the specified
  ///   file is a part file. This field will be omitted if there are no edits
  ///   that need to be applied.
  Future<EditImportElementsResult> sendEditImportElements(
      String file, List<ImportedElements> elements,
      {int? offset}) async {
    var params =
        EditImportElementsParams(file, elements, offset: offset).toJson();
    var result = await server.send('edit.importElements', params);
    var decoder = ResponseDecoder(null);
    return EditImportElementsResult.fromJson(decoder, 'result', result);
  }

  /// Sort all of the directives, unit and class members of the given Dart
  /// file.
  ///
  /// If a request is made for a file that does not exist, does not belong to
  /// an analysis root or is not a Dart file, SORT_MEMBERS_INVALID_FILE will be
  /// generated.
  ///
  /// If the Dart file has scan or parse errors, SORT_MEMBERS_PARSE_ERRORS will
  /// be generated.
  ///
  /// Parameters
  ///
  /// file: FilePath
  ///
  ///   The Dart file to sort.
  ///
  /// Returns
  ///
  /// edit: SourceFileEdit
  ///
  ///   The file edit that is to be applied to the given file to effect the
  ///   sorting.
  Future<EditSortMembersResult> sendEditSortMembers(String file) async {
    var params = EditSortMembersParams(file).toJson();
    var result = await server.send('edit.sortMembers', params);
    var decoder = ResponseDecoder(null);
    return EditSortMembersResult.fromJson(decoder, 'result', result);
  }

  /// Organizes all of the directives - removes unused imports and sorts
  /// directives of the given Dart file according to the Dart Style Guide.
  ///
  /// If a request is made for a file that does not exist, does not belong to
  /// an analysis root or is not a Dart file, FILE_NOT_ANALYZED will be
  /// generated.
  ///
  /// If directives of the Dart file cannot be organized, for example because
  /// it has scan or parse errors, or by other reasons,
  /// ORGANIZE_DIRECTIVES_ERROR will be generated. The message will provide
  /// details about the reason.
  ///
  /// Parameters
  ///
  /// file: FilePath
  ///
  ///   The Dart file to organize directives in.
  ///
  /// Returns
  ///
  /// edit: SourceFileEdit
  ///
  ///   The file edit that is to be applied to the given file to effect the
  ///   organizing.
  Future<EditOrganizeDirectivesResult> sendEditOrganizeDirectives(
      String file) async {
    var params = EditOrganizeDirectivesParams(file).toJson();
    var result = await server.send('edit.organizeDirectives', params);
    var decoder = ResponseDecoder(null);
    return EditOrganizeDirectivesResult.fromJson(decoder, 'result', result);
  }

  /// Create an execution context for the executable file with the given path.
  /// The context that is created will persist until execution.deleteContext is
  /// used to delete it. Clients, therefore, are responsible for managing the
  /// lifetime of execution contexts.
  ///
  /// Parameters
  ///
  /// contextRoot: FilePath
  ///
  ///   The path of the Dart or HTML file that will be launched, or the path of
  ///   the directory containing the file.
  ///
  /// Returns
  ///
  /// id: ExecutionContextId
  ///
  ///   The identifier used to refer to the execution context that was created.
  Future<ExecutionCreateContextResult> sendExecutionCreateContext(
      String contextRoot) async {
    var params = ExecutionCreateContextParams(contextRoot).toJson();
    var result = await server.send('execution.createContext', params);
    var decoder = ResponseDecoder(null);
    return ExecutionCreateContextResult.fromJson(decoder, 'result', result);
  }

  /// Delete the execution context with the given identifier. The context id is
  /// no longer valid after this command. The server is allowed to re-use ids
  /// when they are no longer valid.
  ///
  /// Parameters
  ///
  /// id: ExecutionContextId
  ///
  ///   The identifier of the execution context that is to be deleted.
  Future<void> sendExecutionDeleteContext(String id) async {
    var params = ExecutionDeleteContextParams(id).toJson();
    var result = await server.send('execution.deleteContext', params);
    outOfTestExpect(result, isNull);
  }

  /// Request completion suggestions for the given runtime context.
  ///
  /// It might take one or two requests of this type to get completion
  /// suggestions. The first request should have only "code", "offset", and
  /// "variables", but not "expressions". If there are sub-expressions that can
  /// have different runtime types, and are considered to be safe to evaluate
  /// at runtime (e.g. getters), so using their actual runtime types can
  /// improve completion results, the server will not include the "suggestions"
  /// field in the response, and instead will return the "expressions" field.
  /// The client will use debug API to get current runtime types for these
  /// sub-expressions and send another request, this time with "expressions".
  /// If there are no interesting sub-expressions to get runtime types for, or
  /// when the "expressions" field is provided by the client, the server will
  /// return "suggestions" in the response.
  ///
  /// Parameters
  ///
  /// code: String
  ///
  ///   The code to get suggestions in.
  ///
  /// offset: int
  ///
  ///   The offset within the code to get suggestions at.
  ///
  /// contextFile: FilePath
  ///
  ///   The path of the context file, e.g. the file of the current debugger
  ///   frame. The combination of the context file and context offset can be
  ///   used to ensure that all variables of the context are available for
  ///   completion (with their static types).
  ///
  /// contextOffset: int
  ///
  ///   The offset in the context file, e.g. the line offset in the current
  ///   debugger frame.
  ///
  /// variables: List<RuntimeCompletionVariable>
  ///
  ///   The runtime context variables that are potentially referenced in the
  ///   code.
  ///
  /// expressions: List<RuntimeCompletionExpression> (optional)
  ///
  ///   The list of sub-expressions in the code for which the client wants to
  ///   provide runtime types. It does not have to be the full list of
  ///   expressions requested by the server, for missing expressions their
  ///   static types will be used.
  ///
  ///   When this field is omitted, the server will return completion
  ///   suggestions only when there are no interesting sub-expressions in the
  ///   given code. The client may provide an empty list, in this case the
  ///   server will return completion suggestions.
  ///
  /// Returns
  ///
  /// suggestions: List<CompletionSuggestion> (optional)
  ///
  ///   The completion suggestions. In contrast to usual completion request,
  ///   suggestions for private elements also will be provided.
  ///
  ///   If there are sub-expressions that can have different runtime types, and
  ///   are considered to be safe to evaluate at runtime (e.g. getters), so
  ///   using their actual runtime types can improve completion results, the
  ///   server omits this field in the response, and instead will return the
  ///   "expressions" field.
  ///
  /// expressions: List<RuntimeCompletionExpression> (optional)
  ///
  ///   The list of sub-expressions in the code for which the server would like
  ///   to know runtime types to provide better completion suggestions.
  ///
  ///   This field is omitted the field "suggestions" is returned.
  Future<ExecutionGetSuggestionsResult> sendExecutionGetSuggestions(
      String code,
      int offset,
      String contextFile,
      int contextOffset,
      List<RuntimeCompletionVariable> variables,
      {List<RuntimeCompletionExpression>? expressions}) async {
    var params = ExecutionGetSuggestionsParams(
            code, offset, contextFile, contextOffset, variables,
            expressions: expressions)
        .toJson();
    var result = await server.send('execution.getSuggestions', params);
    var decoder = ResponseDecoder(null);
    return ExecutionGetSuggestionsResult.fromJson(decoder, 'result', result);
  }

  /// Map a URI from the execution context to the file that it corresponds to,
  /// or map a file to the URI that it corresponds to in the execution context.
  ///
  /// Exactly one of the file and uri fields must be provided. If both fields
  /// are provided, then an error of type INVALID_PARAMETER will be generated.
  /// Similarly, if neither field is provided, then an error of type
  /// INVALID_PARAMETER will be generated.
  ///
  /// If the file field is provided and the value is not the path of a file
  /// (either the file does not exist or the path references something other
  /// than a file), then an error of type INVALID_PARAMETER will be generated.
  ///
  /// If the uri field is provided and the value is not a valid URI or if the
  /// URI references something that is not a file (either a file that does not
  /// exist or something other than a file), then an error of type
  /// INVALID_PARAMETER will be generated.
  ///
  /// If the contextRoot used to create the execution context does not exist,
  /// then an error of type INVALID_EXECUTION_CONTEXT will be generated.
  ///
  /// Parameters
  ///
  /// id: ExecutionContextId
  ///
  ///   The identifier of the execution context in which the URI is to be
  ///   mapped.
  ///
  /// file: FilePath (optional)
  ///
  ///   The path of the file to be mapped into a URI.
  ///
  /// uri: String (optional)
  ///
  ///   The URI to be mapped into a file path.
  ///
  /// Returns
  ///
  /// file: FilePath (optional)
  ///
  ///   The file to which the URI was mapped. This field is omitted if the uri
  ///   field was not given in the request.
  ///
  /// uri: String (optional)
  ///
  ///   The URI to which the file path was mapped. This field is omitted if the
  ///   file field was not given in the request.
  Future<ExecutionMapUriResult> sendExecutionMapUri(String id,
      {String? file, String? uri}) async {
    var params = ExecutionMapUriParams(id, file: file, uri: uri).toJson();
    var result = await server.send('execution.mapUri', params);
    var decoder = ResponseDecoder(null);
    return ExecutionMapUriResult.fromJson(decoder, 'result', result);
  }

  /// Deprecated: the analysis server no longer fires LAUNCH_DATA events.
  ///
  /// Subscribe for services. All previous subscriptions are replaced by the
  /// given set of services.
  ///
  /// It is an error if any of the elements in the list are not valid services.
  /// If there is an error, then the current subscriptions will remain
  /// unchanged.
  ///
  /// Parameters
  ///
  /// subscriptions: List<ExecutionService>
  ///
  ///   A list of the services being subscribed to.
  // TODO(srawlins): Provide a deprecation message, or remove.
  // ignore: provide_deprecation_message
  @deprecated
  Future<void> sendExecutionSetSubscriptions(
      List<ExecutionService> subscriptions) async {
    var params = ExecutionSetSubscriptionsParams(subscriptions).toJson();
    var result = await server.send('execution.setSubscriptions', params);
    outOfTestExpect(result, isNull);
  }

  /// Reports information needed to allow a single file to be launched.
  ///
  /// This notification is not subscribed to by default. Clients can subscribe
  /// by including the value "LAUNCH_DATA" in the list of services passed in an
  /// execution.setSubscriptions request.
  ///
  /// Parameters
  ///
  /// file: FilePath
  ///
  ///   The file for which launch data is being provided. This will either be a
  ///   Dart library or an HTML file.
  ///
  /// kind: ExecutableKind (optional)
  ///
  ///   The kind of the executable file. This field is omitted if the file is
  ///   not a Dart file.
  ///
  /// referencedFiles: List<FilePath> (optional)
  ///
  ///   A list of the Dart files that are referenced by the file. This field is
  ///   omitted if the file is not an HTML file.
  late final Stream<ExecutionLaunchDataParams> onExecutionLaunchData =
      _onExecutionLaunchData.stream.asBroadcastStream();

  /// Stream controller for [onExecutionLaunchData].
  final _onExecutionLaunchData =
      StreamController<ExecutionLaunchDataParams>(sync: true);

  /// Return server diagnostics.
  ///
  /// Returns
  ///
  /// contexts: List<ContextData>
  ///
  ///   The list of analysis contexts.
  Future<DiagnosticGetDiagnosticsResult> sendDiagnosticGetDiagnostics() async {
    var result = await server.send('diagnostic.getDiagnostics', null);
    var decoder = ResponseDecoder(null);
    return DiagnosticGetDiagnosticsResult.fromJson(decoder, 'result', result);
  }

  /// Return the port of the diagnostic web server. If the server is not
  /// running this call will start the server. If unable to start the
  /// diagnostic web server, this call will return an error of
  /// DEBUG_PORT_COULD_NOT_BE_OPENED.
  ///
  /// Returns
  ///
  /// port: int
  ///
  ///   The diagnostic server port.
  Future<DiagnosticGetServerPortResult> sendDiagnosticGetServerPort() async {
    var result = await server.send('diagnostic.getServerPort', null);
    var decoder = ResponseDecoder(null);
    return DiagnosticGetServerPortResult.fromJson(decoder, 'result', result);
  }

  /// Query whether analytics is enabled.
  ///
  /// This flag controls whether the analysis server sends any analytics data
  /// to the cloud. If disabled, the analysis server does not send any
  /// analytics data, and any data sent to it by clients (from sendEvent and
  /// sendTiming) will be ignored.
  ///
  /// The value of this flag can be changed by other tools outside of the
  /// analysis server's process. When you query the flag, you get the value of
  /// the flag at a given moment. Clients should not use the value returned to
  /// decide whether or not to send the sendEvent and sendTiming requests.
  /// Those requests should be used unconditionally and server will determine
  /// whether or not it is appropriate to forward the information to the cloud
  /// at the time each request is received.
  ///
  /// Returns
  ///
  /// enabled: bool
  ///
  ///   Whether sending analytics is enabled or not.
  Future<AnalyticsIsEnabledResult> sendAnalyticsIsEnabled() async {
    var result = await server.send('analytics.isEnabled', null);
    var decoder = ResponseDecoder(null);
    return AnalyticsIsEnabledResult.fromJson(decoder, 'result', result);
  }

  /// Enable or disable the sending of analytics data. Note that there are
  /// other ways for users to change this setting, so clients cannot assume
  /// that they have complete control over this setting. In particular, there
  /// is no guarantee that the result returned by the isEnabled request will
  /// match the last value set via this request.
  ///
  /// Parameters
  ///
  /// value: bool
  ///
  ///   Enable or disable analytics.
  Future<void> sendAnalyticsEnable(bool value) async {
    var params = AnalyticsEnableParams(value).toJson();
    var result = await server.send('analytics.enable', params);
    outOfTestExpect(result, isNull);
  }

  /// Send information about client events.
  ///
  /// Ask the analysis server to include the fact that an action was performed
  /// in the client as part of the analytics data being sent. The data will
  /// only be included if the sending of analytics data is enabled at the time
  /// the request is processed. The action that was performed is indicated by
  /// the value of the action field.
  ///
  /// The value of the action field should not include the identity of the
  /// client. The analytics data sent by server will include the client id
  /// passed in using the --client-id command-line argument. The request will
  /// be ignored if the client id was not provided when server was started.
  ///
  /// Parameters
  ///
  /// action: String
  ///
  ///   The value used to indicate which action was performed.
  Future<void> sendAnalyticsSendEvent(String action) async {
    var params = AnalyticsSendEventParams(action).toJson();
    var result = await server.send('analytics.sendEvent', params);
    outOfTestExpect(result, isNull);
  }

  /// Send timing information for client events (e.g. code completions).
  ///
  /// Ask the analysis server to include the fact that a timed event occurred
  /// as part of the analytics data being sent. The data will only be included
  /// if the sending of analytics data is enabled at the time the request is
  /// processed.
  ///
  /// The value of the event field should not include the identity of the
  /// client. The analytics data sent by server will include the client id
  /// passed in using the --client-id command-line argument. The request will
  /// be ignored if the client id was not provided when server was started.
  ///
  /// Parameters
  ///
  /// event: String
  ///
  ///   The name of the event.
  ///
  /// millis: int
  ///
  ///   The duration of the event in milliseconds.
  Future<void> sendAnalyticsSendTiming(String event, int millis) async {
    var params = AnalyticsSendTimingParams(event, millis).toJson();
    var result = await server.send('analytics.sendTiming', params);
    outOfTestExpect(result, isNull);
  }

  /// Return the description of the widget instance at the given location.
  ///
  /// If the location does not have a support widget, an error of type
  /// FLUTTER_GET_WIDGET_DESCRIPTION_NO_WIDGET will be generated.
  ///
  /// If a change to a file happens while widget descriptions are computed, an
  /// error of type FLUTTER_GET_WIDGET_DESCRIPTION_CONTENT_MODIFIED will be
  /// generated.
  ///
  /// Parameters
  ///
  /// file: FilePath
  ///
  ///   The file where the widget instance is created.
  ///
  /// offset: int
  ///
  ///   The offset in the file where the widget instance is created.
  ///
  /// Returns
  ///
  /// properties: List<FlutterWidgetProperty>
  ///
  ///   The list of properties of the widget. Some of the properties might be
  ///   read only, when their editor is not set. This might be because they
  ///   have type that we don't know how to edit, or for compound properties
  ///   that work as containers for sub-properties.
  Future<FlutterGetWidgetDescriptionResult> sendFlutterGetWidgetDescription(
      String file, int offset) async {
    var params = FlutterGetWidgetDescriptionParams(file, offset).toJson();
    var result = await server.send('flutter.getWidgetDescription', params);
    var decoder = ResponseDecoder(null);
    return FlutterGetWidgetDescriptionResult.fromJson(
        decoder, 'result', result);
  }

  /// Set the value of a property, or remove it.
  ///
  /// The server will generate a change that the client should apply to the
  /// project to get the value of the property set to the new value. The
  /// complexity of the change might be from updating a single literal value in
  /// the code, to updating multiple files to get libraries imported, and new
  /// intermediate widgets instantiated.
  ///
  /// Parameters
  ///
  /// id: int
  ///
  ///   The identifier of the property, previously returned as a part of a
  ///   FlutterWidgetProperty.
  ///
  ///   An error of type FLUTTER_SET_WIDGET_PROPERTY_VALUE_INVALID_ID is
  ///   generated if the identifier is not valid.
  ///
  /// value: FlutterWidgetPropertyValue (optional)
  ///
  ///   The new value to set for the property.
  ///
  ///   If absent, indicates that the property should be removed. If the
  ///   property corresponds to an optional parameter, the corresponding named
  ///   argument is removed. If the property isRequired is true,
  ///   FLUTTER_SET_WIDGET_PROPERTY_VALUE_IS_REQUIRED error is generated.
  ///
  ///   If the expression is not a syntactically valid Dart code, then
  ///   FLUTTER_SET_WIDGET_PROPERTY_VALUE_INVALID_EXPRESSION is reported.
  ///
  /// Returns
  ///
  /// change: SourceChange
  ///
  ///   The change that should be applied.
  Future<FlutterSetWidgetPropertyValueResult> sendFlutterSetWidgetPropertyValue(
      int id,
      {FlutterWidgetPropertyValue? value}) async {
    var params = FlutterSetWidgetPropertyValueParams(id, value: value).toJson();
    var result = await server.send('flutter.setWidgetPropertyValue', params);
    var decoder = ResponseDecoder(null);
    return FlutterSetWidgetPropertyValueResult.fromJson(
        decoder, 'result', result);
  }

  /// Subscribe for services that are specific to individual files. All
  /// previous subscriptions are replaced by the current set of subscriptions.
  /// If a given service is not included as a key in the map then no files will
  /// be subscribed to the service, exactly as if the service had been included
  /// in the map with an explicit empty list of files.
  ///
  /// Note that this request determines the set of requested subscriptions. The
  /// actual set of subscriptions at any given time is the intersection of this
  /// set with the set of files currently subject to analysis. The files
  /// currently subject to analysis are the set of files contained within an
  /// actual analysis root but not excluded, plus all of the files transitively
  /// reachable from those files via import, export and part directives. (See
  /// analysis.setAnalysisRoots for an explanation of how the actual analysis
  /// roots are determined.) When the actual analysis roots change, the actual
  /// set of subscriptions is automatically updated, but the set of requested
  /// subscriptions is unchanged.
  ///
  /// If a requested subscription is a directory it is ignored, but remains in
  /// the set of requested subscriptions so that if it later becomes a file it
  /// can be included in the set of actual subscriptions.
  ///
  /// It is an error if any of the keys in the map are not valid services. If
  /// there is an error, then the existing subscriptions will remain unchanged.
  ///
  /// Parameters
  ///
  /// subscriptions: Map<FlutterService, List<FilePath>>
  ///
  ///   A table mapping services to a list of the files being subscribed to the
  ///   service.
  Future<void> sendFlutterSetSubscriptions(
      Map<FlutterService, List<String>> subscriptions) async {
    var params = FlutterSetSubscriptionsParams(subscriptions).toJson();
    var result = await server.send('flutter.setSubscriptions', params);
    outOfTestExpect(result, isNull);
  }

  /// Reports the Flutter outline associated with a single file.
  ///
  /// This notification is not subscribed to by default. Clients can subscribe
  /// by including the value "OUTLINE" in the list of services passed in an
  /// flutter.setSubscriptions request.
  ///
  /// Parameters
  ///
  /// file: FilePath
  ///
  ///   The file with which the outline is associated.
  ///
  /// outline: FlutterOutline
  ///
  ///   The outline associated with the file.
  late final Stream<FlutterOutlineParams> onFlutterOutline =
      _onFlutterOutline.stream.asBroadcastStream();

  /// Stream controller for [onFlutterOutline].
  final _onFlutterOutline = StreamController<FlutterOutlineParams>(sync: true);

  /// Call an LSP handler. Message can be requests or notifications.
  ///
  /// Parameters
  ///
  /// lspMessage: object
  ///
  ///   The LSP RequestMessage.
  ///
  /// Returns
  ///
  /// lspResponse: object
  ///
  ///   The LSP ResponseMessage returned by the handler.
  Future<LspHandleResult> sendLspHandle(Object lspMessage) async {
    var params = LspHandleParams(lspMessage).toJson();
    var result = await server.send('lsp.handle', params);
    var decoder = ResponseDecoder(null);
    return LspHandleResult.fromJson(decoder, 'result', result);
  }

  /// Dispatch the notification named [event], and containing parameters
  /// [params], to the appropriate stream.
  void dispatchNotification(String event, params) {
    var decoder = ResponseDecoder(null);
    switch (event) {
      case 'server.connected':
        outOfTestExpect(params, isServerConnectedParams);
        _onServerConnected
            .add(ServerConnectedParams.fromJson(decoder, 'params', params));
      case 'server.error':
        outOfTestExpect(params, isServerErrorParams);
        _onServerError
            .add(ServerErrorParams.fromJson(decoder, 'params', params));
      case 'server.log':
        outOfTestExpect(params, isServerLogParams);
        _onServerLog.add(ServerLogParams.fromJson(decoder, 'params', params));
      case 'server.status':
        outOfTestExpect(params, isServerStatusParams);
        _onServerStatus
            .add(ServerStatusParams.fromJson(decoder, 'params', params));
      case 'analysis.analyzedFiles':
        outOfTestExpect(params, isAnalysisAnalyzedFilesParams);
        _onAnalysisAnalyzedFiles.add(
            AnalysisAnalyzedFilesParams.fromJson(decoder, 'params', params));
      case 'analysis.closingLabels':
        outOfTestExpect(params, isAnalysisClosingLabelsParams);
        _onAnalysisClosingLabels.add(
            AnalysisClosingLabelsParams.fromJson(decoder, 'params', params));
      case 'analysis.errors':
        outOfTestExpect(params, isAnalysisErrorsParams);
        _onAnalysisErrors
            .add(AnalysisErrorsParams.fromJson(decoder, 'params', params));
      case 'analysis.flushResults':
        outOfTestExpect(params, isAnalysisFlushResultsParams);
        _onAnalysisFlushResults.add(
            AnalysisFlushResultsParams.fromJson(decoder, 'params', params));
      case 'analysis.folding':
        outOfTestExpect(params, isAnalysisFoldingParams);
        _onAnalysisFolding
            .add(AnalysisFoldingParams.fromJson(decoder, 'params', params));
      case 'analysis.highlights':
        outOfTestExpect(params, isAnalysisHighlightsParams);
        _onAnalysisHighlights
            .add(AnalysisHighlightsParams.fromJson(decoder, 'params', params));
      case 'analysis.implemented':
        outOfTestExpect(params, isAnalysisImplementedParams);
        _onAnalysisImplemented
            .add(AnalysisImplementedParams.fromJson(decoder, 'params', params));
      case 'analysis.invalidate':
        outOfTestExpect(params, isAnalysisInvalidateParams);
        _onAnalysisInvalidate
            .add(AnalysisInvalidateParams.fromJson(decoder, 'params', params));
      case 'analysis.navigation':
        outOfTestExpect(params, isAnalysisNavigationParams);
        _onAnalysisNavigation
            .add(AnalysisNavigationParams.fromJson(decoder, 'params', params));
      case 'analysis.occurrences':
        outOfTestExpect(params, isAnalysisOccurrencesParams);
        _onAnalysisOccurrences
            .add(AnalysisOccurrencesParams.fromJson(decoder, 'params', params));
      case 'analysis.outline':
        outOfTestExpect(params, isAnalysisOutlineParams);
        _onAnalysisOutline
            .add(AnalysisOutlineParams.fromJson(decoder, 'params', params));
      case 'analysis.overrides':
        outOfTestExpect(params, isAnalysisOverridesParams);
        _onAnalysisOverrides
            .add(AnalysisOverridesParams.fromJson(decoder, 'params', params));
      case 'completion.results':
        outOfTestExpect(params, isCompletionResultsParams);
        _onCompletionResults
            .add(CompletionResultsParams.fromJson(decoder, 'params', params));
      case 'completion.availableSuggestions':
        outOfTestExpect(params, isCompletionAvailableSuggestionsParams);
        _onCompletionAvailableSuggestions.add(
            CompletionAvailableSuggestionsParams.fromJson(
                decoder, 'params', params));
      case 'completion.existingImports':
        outOfTestExpect(params, isCompletionExistingImportsParams);
        _onCompletionExistingImports.add(
            CompletionExistingImportsParams.fromJson(
                decoder, 'params', params));
      case 'search.results':
        outOfTestExpect(params, isSearchResultsParams);
        _onSearchResults
            .add(SearchResultsParams.fromJson(decoder, 'params', params));
      case 'execution.launchData':
        outOfTestExpect(params, isExecutionLaunchDataParams);
        _onExecutionLaunchData
            .add(ExecutionLaunchDataParams.fromJson(decoder, 'params', params));
      case 'flutter.outline':
        outOfTestExpect(params, isFlutterOutlineParams);
        _onFlutterOutline
            .add(FlutterOutlineParams.fromJson(decoder, 'params', params));
      default:
        fail('Unexpected notification: $event');
    }
  }
}
