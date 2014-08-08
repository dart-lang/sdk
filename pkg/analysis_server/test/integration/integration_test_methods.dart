// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This file has been automatically generated.  Please do not edit it manually.
// To regenerate the file, use the script
// "pkg/analysis_server/spec/generate_files".

/**
 * Convenience methods for running integration tests
 */
library test.integration.methods;

import 'dart:async';

import 'package:unittest/unittest.dart';

import 'integration_tests.dart';
import 'protocol_matchers.dart';


/**
 * Convenience methods for running integration tests
 */
abstract class InttestMixin {
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
  Future sendServerGetVersion({bool checkTypes: true}) {
    return server.send("server.getVersion", null)
        .then((result) {
      if (checkTypes) {
        expect(result, isServerGetVersionResult);
      }
      return result;
    });
  }

  /**
   * Cleanly shutdown the analysis server. Requests that are received after
   * this request will not be processed. Requests that were received before
   * this request, but for which a response has not yet been sent, will not be
   * responded to. No further responses or notifications will be sent after the
   * response to this request has been sent.
   */
  Future sendServerShutdown({bool checkTypes: true}) {
    return server.send("server.shutdown", null)
        .then((result) {
      if (checkTypes) {
        expect(result, isServerShutdownResult);
      }
      return result;
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
  Future sendServerSetSubscriptions(List<String> subscriptions, {bool checkTypes: true}) {
    Map<String, dynamic> params = {};
    params["subscriptions"] = subscriptions;
    if (checkTypes) {
      expect(params, isServerSetSubscriptionsParams);
    }
    return server.send("server.setSubscriptions", params)
        .then((result) {
      if (checkTypes) {
        expect(result, isServerSetSubscriptionsResult);
      }
      return result;
    });
  }

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
  Future sendAnalysisGetErrors(String file, {bool checkTypes: true}) {
    Map<String, dynamic> params = {};
    params["file"] = file;
    if (checkTypes) {
      expect(params, isAnalysisGetErrorsParams);
    }
    return server.send("analysis.getErrors", params)
        .then((result) {
      if (checkTypes) {
        expect(result, isAnalysisGetErrorsResult);
      }
      return result;
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
  Future sendAnalysisGetHover(String file, int offset, {bool checkTypes: true}) {
    Map<String, dynamic> params = {};
    params["file"] = file;
    params["offset"] = offset;
    if (checkTypes) {
      expect(params, isAnalysisGetHoverParams);
    }
    return server.send("analysis.getHover", params)
        .then((result) {
      if (checkTypes) {
        expect(result, isAnalysisGetHoverResult);
      }
      return result;
    });
  }

  /**
   * Force the re-analysis of everything contained in the existing analysis
   * roots. This will cause all previously computed analysis results to be
   * discarded and recomputed, and will cause all subscribed notifications to
   * be re-sent.
   */
  Future sendAnalysisReanalyze({bool checkTypes: true}) {
    return server.send("analysis.reanalyze", null)
        .then((result) {
      if (checkTypes) {
        expect(result, isAnalysisReanalyzeResult);
      }
      return result;
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
   */
  Future sendAnalysisSetAnalysisRoots(List<String> included, List<String> excluded, {bool checkTypes: true}) {
    Map<String, dynamic> params = {};
    params["included"] = included;
    params["excluded"] = excluded;
    if (checkTypes) {
      expect(params, isAnalysisSetAnalysisRootsParams);
    }
    return server.send("analysis.setAnalysisRoots", params)
        .then((result) {
      if (checkTypes) {
        expect(result, isAnalysisSetAnalysisRootsResult);
      }
      return result;
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
  Future sendAnalysisSetPriorityFiles(List<String> files, {bool checkTypes: true}) {
    Map<String, dynamic> params = {};
    params["files"] = files;
    if (checkTypes) {
      expect(params, isAnalysisSetPriorityFilesParams);
    }
    return server.send("analysis.setPriorityFiles", params)
        .then((result) {
      if (checkTypes) {
        expect(result, isAnalysisSetPriorityFilesResult);
      }
      return result;
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
  Future sendAnalysisSetSubscriptions(Map<String, List<String>> subscriptions, {bool checkTypes: true}) {
    Map<String, dynamic> params = {};
    params["subscriptions"] = subscriptions;
    if (checkTypes) {
      expect(params, isAnalysisSetSubscriptionsParams);
    }
    return server.send("analysis.setSubscriptions", params)
        .then((result) {
      if (checkTypes) {
        expect(result, isAnalysisSetSubscriptionsResult);
      }
      return result;
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
   * files ( Map<FilePath, object> )
   *
   *   A table mapping the files whose content has changed to a description of
   *   the content change. Each value should be one of the following types:
   *   AddContentOverlay, ChangeContentOverlay, or RemoveContentOverlay.
   */
  Future sendAnalysisUpdateContent(Map<String, Map<String, dynamic>> files, {bool checkTypes: true}) {
    Map<String, dynamic> params = {};
    params["files"] = files;
    if (checkTypes) {
      expect(params, isAnalysisUpdateContentParams);
    }
    return server.send("analysis.updateContent", params)
        .then((result) {
      if (checkTypes) {
        expect(result, isAnalysisUpdateContentResult);
      }
      return result;
    });
  }

  /**
   * Update the options controlling analysis based on the given set of options.
   * Any options that are not included in the analysis options will not be
   * changed. If there are options in the analysis options that are not valid
   * an error will be reported but the values of the valid options will still
   * be updated.
   *
   * Parameters
   *
   * options ( AnalysisOptions )
   *
   *   The options that are to be used to control analysis.
   */
  Future sendAnalysisUpdateOptions(Map<String, dynamic> options, {bool checkTypes: true}) {
    Map<String, dynamic> params = {};
    params["options"] = options;
    if (checkTypes) {
      expect(params, isAnalysisUpdateOptionsParams);
    }
    return server.send("analysis.updateOptions", params)
        .then((result) {
      if (checkTypes) {
        expect(result, isAnalysisUpdateOptionsResult);
      }
      return result;
    });
  }

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
  Future sendCompletionGetSuggestions(String file, int offset, {bool checkTypes: true}) {
    Map<String, dynamic> params = {};
    params["file"] = file;
    params["offset"] = offset;
    if (checkTypes) {
      expect(params, isCompletionGetSuggestionsParams);
    }
    return server.send("completion.getSuggestions", params)
        .then((result) {
      if (checkTypes) {
        expect(result, isCompletionGetSuggestionsResult);
      }
      return result;
    });
  }

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
   * id ( SearchId )
   *
   *   The identifier used to associate results with this search request.
   *
   * element ( Element )
   *
   *   The element referenced or defined at the given offset and whose
   *   references will be returned in the search results.
   */
  Future sendSearchFindElementReferences(String file, int offset, bool includePotential, {bool checkTypes: true}) {
    Map<String, dynamic> params = {};
    params["file"] = file;
    params["offset"] = offset;
    params["includePotential"] = includePotential;
    if (checkTypes) {
      expect(params, isSearchFindElementReferencesParams);
    }
    return server.send("search.findElementReferences", params)
        .then((result) {
      if (checkTypes) {
        expect(result, isSearchFindElementReferencesResult);
      }
      return result;
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
  Future sendSearchFindMemberDeclarations(String name, {bool checkTypes: true}) {
    Map<String, dynamic> params = {};
    params["name"] = name;
    if (checkTypes) {
      expect(params, isSearchFindMemberDeclarationsParams);
    }
    return server.send("search.findMemberDeclarations", params)
        .then((result) {
      if (checkTypes) {
        expect(result, isSearchFindMemberDeclarationsResult);
      }
      return result;
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
  Future sendSearchFindMemberReferences(String name, {bool checkTypes: true}) {
    Map<String, dynamic> params = {};
    params["name"] = name;
    if (checkTypes) {
      expect(params, isSearchFindMemberReferencesParams);
    }
    return server.send("search.findMemberReferences", params)
        .then((result) {
      if (checkTypes) {
        expect(result, isSearchFindMemberReferencesResult);
      }
      return result;
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
  Future sendSearchFindTopLevelDeclarations(String pattern, {bool checkTypes: true}) {
    Map<String, dynamic> params = {};
    params["pattern"] = pattern;
    if (checkTypes) {
      expect(params, isSearchFindTopLevelDeclarationsParams);
    }
    return server.send("search.findTopLevelDeclarations", params)
        .then((result) {
      if (checkTypes) {
        expect(result, isSearchFindTopLevelDeclarationsResult);
      }
      return result;
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
  Future sendSearchGetTypeHierarchy(String file, int offset, {bool checkTypes: true}) {
    Map<String, dynamic> params = {};
    params["file"] = file;
    params["offset"] = offset;
    if (checkTypes) {
      expect(params, isSearchGetTypeHierarchyParams);
    }
    return server.send("search.getTypeHierarchy", params)
        .then((result) {
      if (checkTypes) {
        expect(result, isSearchGetTypeHierarchyResult);
      }
      return result;
    });
  }

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
  Future sendEditGetAssists(String file, int offset, int length, {bool checkTypes: true}) {
    Map<String, dynamic> params = {};
    params["file"] = file;
    params["offset"] = offset;
    params["length"] = length;
    if (checkTypes) {
      expect(params, isEditGetAssistsParams);
    }
    return server.send("edit.getAssists", params)
        .then((result) {
      if (checkTypes) {
        expect(result, isEditGetAssistsResult);
      }
      return result;
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
  Future sendEditGetAvailableRefactorings(String file, int offset, int length, {bool checkTypes: true}) {
    Map<String, dynamic> params = {};
    params["file"] = file;
    params["offset"] = offset;
    params["length"] = length;
    if (checkTypes) {
      expect(params, isEditGetAvailableRefactoringsParams);
    }
    return server.send("edit.getAvailableRefactorings", params)
        .then((result) {
      if (checkTypes) {
        expect(result, isEditGetAvailableRefactoringsResult);
      }
      return result;
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
   * fixes ( List<ErrorFixes> )
   *
   *   The fixes that are available for each of the analysis errors. There is a
   *   one-to-one correspondence between the analysis errors in the request and
   *   the lists of changes in the response. In particular, it is always the
   *   case that errors.length == fixes.length and that fixes[i] is the list of
   *   fixes for the error in errors[i]. The list of changes corresponding to
   *   an error can be empty if there are no fixes available for that error.
   */
  Future sendEditGetFixes(String file, int offset, {bool checkTypes: true}) {
    Map<String, dynamic> params = {};
    params["file"] = file;
    params["offset"] = offset;
    if (checkTypes) {
      expect(params, isEditGetFixesParams);
    }
    return server.send("edit.getFixes", params)
        .then((result) {
      if (checkTypes) {
        expect(result, isEditGetFixesResult);
      }
      return result;
    });
  }

  /**
   * Get the changes required to perform a refactoring.
   *
   * Parameters
   *
   * kindId ( RefactoringKind )
   *
   *   The identifier of the kind of refactoring to be performed.
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
   * options ( optional object )
   *
   *   Data used to provide values provided by the user. The structure of the
   *   data is dependent on the kind of refactoring being performed. The data
   *   that is expected is documented in the section titled Refactorings,
   *   labeled as “Options”. This field can be omitted if the refactoring does
   *   not require any options or if the values of those options are not known.
   *
   * Returns
   *
   * status ( List<RefactoringProblem> )
   *
   *   The status of the refactoring. The array will be empty if there are no
   *   known problems.
   *
   * feedback ( optional object )
   *
   *   Data used to provide feedback to the user. The structure of the data is
   *   dependent on the kind of refactoring being created. The data that is
   *   returned is documented in the section titled Refactorings, labeled as
   *   “Feedback”.
   *
   * change ( optional SourceChange )
   *
   *   The changes that are to be applied to affect the refactoring. This field
   *   will be omitted if there are problems that prevent a set of changed from
   *   being computed, such as having no options specified for a refactoring
   *   that requires them, or if only validation was requested.
   */
  Future sendEditGetRefactoring(String kindId, String file, int offset, int length, bool validateOnly, {Map<String, dynamic> options, bool checkTypes: true}) {
    Map<String, dynamic> params = {};
    params["kindId"] = kindId;
    params["file"] = file;
    params["offset"] = offset;
    params["length"] = length;
    params["validateOnly"] = validateOnly;
    if (options != null) {
      params["options"] = options;
    }
    if (checkTypes) {
      expect(params, isEditGetRefactoringParams);
    }
    return server.send("edit.getRefactoring", params)
        .then((result) {
      if (checkTypes) {
        expect(result, isEditGetRefactoringResult);
      }
      return result;
    });
  }

  /**
   * Create a debugging context for the executable file with the given path.
   * The context that is created will persist until debug.deleteContext is used
   * to delete it. Clients, therefore, are responsible for managing the
   * lifetime of debugging contexts.
   *
   * Parameters
   *
   * contextRoot ( FilePath )
   *
   *   The path of the Dart or HTML file that will be launched.
   *
   * Returns
   *
   * id ( DebugContextId )
   *
   *   The identifier used to refer to the debugging context that was created.
   */
  Future sendDebugCreateContext(String contextRoot, {bool checkTypes: true}) {
    Map<String, dynamic> params = {};
    params["contextRoot"] = contextRoot;
    if (checkTypes) {
      expect(params, isDebugCreateContextParams);
    }
    return server.send("debug.createContext", params)
        .then((result) {
      if (checkTypes) {
        expect(result, isDebugCreateContextResult);
      }
      return result;
    });
  }

  /**
   * Delete the debugging context with the given identifier. The context id is
   * no longer valid after this command. The server is allowed to re-use ids
   * when they are no longer valid.
   *
   * Parameters
   *
   * id ( DebugContextId )
   *
   *   The identifier of the debugging context that is to be deleted.
   */
  Future sendDebugDeleteContext(String id, {bool checkTypes: true}) {
    Map<String, dynamic> params = {};
    params["id"] = id;
    if (checkTypes) {
      expect(params, isDebugDeleteContextParams);
    }
    return server.send("debug.deleteContext", params)
        .then((result) {
      if (checkTypes) {
        expect(result, isDebugDeleteContextResult);
      }
      return result;
    });
  }

  /**
   * Map a URI from the debugging context to the file that it corresponds to,
   * or map a file to the URI that it corresponds to in the debugging context.
   *
   * Exactly one of the file and uri fields must be provided.
   *
   * Parameters
   *
   * id ( DebugContextId )
   *
   *   The identifier of the debugging context in which the URI is to be
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
  Future sendDebugMapUri(String id, {String file, String uri, bool checkTypes: true}) {
    Map<String, dynamic> params = {};
    params["id"] = id;
    if (file != null) {
      params["file"] = file;
    }
    if (uri != null) {
      params["uri"] = uri;
    }
    if (checkTypes) {
      expect(params, isDebugMapUriParams);
    }
    return server.send("debug.mapUri", params)
        .then((result) {
      if (checkTypes) {
        expect(result, isDebugMapUriResult);
      }
      return result;
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
   * subscriptions ( List<DebugService> )
   *
   *   A list of the services being subscribed to.
   */
  Future sendDebugSetSubscriptions(List<String> subscriptions, {bool checkTypes: true}) {
    Map<String, dynamic> params = {};
    params["subscriptions"] = subscriptions;
    if (checkTypes) {
      expect(params, isDebugSetSubscriptionsParams);
    }
    return server.send("debug.setSubscriptions", params)
        .then((result) {
      if (checkTypes) {
        expect(result, isDebugSetSubscriptionsResult);
      }
      return result;
    });
  }
}
