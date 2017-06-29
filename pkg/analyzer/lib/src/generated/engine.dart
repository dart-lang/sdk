// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.generated.engine;

import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:analyzer/plugin/resolver_provider.dart';
import 'package:analyzer/source/error_processor.dart';
import 'package:analyzer/src/cancelable_future.dart';
import 'package:analyzer/src/context/builder.dart' show EmbedderYamlLocator;
import 'package:analyzer/src/context/cache.dart';
import 'package:analyzer/src/context/context.dart';
import 'package:analyzer/src/generated/constant.dart';
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_general.dart';
import 'package:analyzer/src/plugin/engine_plugin.dart';
import 'package:analyzer/src/services/lint.dart';
import 'package:analyzer/src/task/dart.dart';
import 'package:analyzer/src/task/general.dart';
import 'package:analyzer/src/task/html.dart';
import 'package:analyzer/src/task/manager.dart';
import 'package:analyzer/src/task/options.dart';
import 'package:analyzer/src/task/yaml.dart';
import 'package:analyzer/task/dart.dart';
import 'package:analyzer/task/model.dart';
import 'package:front_end/src/base/api_signature.dart';
import 'package:front_end/src/base/timestamped_data.dart';
import 'package:html/dom.dart' show Document;
import 'package:path/path.dart' as pathos;
import 'package:plugin/manager.dart';
import 'package:plugin/plugin.dart';

export 'package:analyzer/error/listener.dart' show RecordingErrorListener;
export 'package:front_end/src/base/timestamped_data.dart' show TimestampedData;

/**
 * Used by [AnalysisOptions] to allow function bodies to be analyzed in some
 * sources but not others.
 */
typedef bool AnalyzeFunctionBodiesPredicate(Source source);

/**
 * A context in which a single analysis can be performed and incrementally
 * maintained. The context includes such information as the version of the SDK
 * being analyzed against as well as the package-root used to resolve 'package:'
 * URI's. (Both of which are known indirectly through the [SourceFactory].)
 *
 * An analysis context also represents the state of the analysis, which includes
 * knowing which sources have been included in the analysis (either directly or
 * indirectly) and the results of the analysis. Sources must be added and
 * removed from the context using the method [applyChanges], which is also used
 * to notify the context when sources have been modified and, consequently,
 * previously known results might have been invalidated.
 *
 * There are two ways to access the results of the analysis. The most common is
 * to use one of the 'get' methods to access the results. The 'get' methods have
 * the advantage that they will always return quickly, but have the disadvantage
 * that if the results are not currently available they will return either
 * nothing or in some cases an incomplete result. The second way to access
 * results is by using one of the 'compute' methods. The 'compute' methods will
 * always attempt to compute the requested results but might block the caller
 * for a significant period of time.
 *
 * When results have been invalidated, have never been computed (as is the case
 * for newly added sources), or have been removed from the cache, they are
 * <b>not</b> automatically recreated. They will only be recreated if one of the
 * 'compute' methods is invoked.
 *
 * However, this is not always acceptable. Some clients need to keep the
 * analysis results up-to-date. For such clients there is a mechanism that
 * allows them to incrementally perform needed analysis and get notified of the
 * consequent changes to the analysis results. This mechanism is realized by the
 * method [performAnalysisTask].
 *
 * Analysis engine allows for having more than one context. This can be used,
 * for example, to perform one analysis based on the state of files on disk and
 * a separate analysis based on the state of those files in open editors. It can
 * also be used to perform an analysis based on a proposed future state, such as
 * the state after a refactoring.
 */
abstract class AnalysisContext {
  /**
   * An empty list of contexts.
   */
  static const List<AnalysisContext> EMPTY_LIST = const <AnalysisContext>[];

  /**
   * The file resolver provider used to override the way file URI's are
   * resolved in some contexts.
   */
  ResolverProvider fileResolverProvider;

  /**
   * Return the set of analysis options controlling the behavior of this
   * context. Clients should not modify the returned set of options. The options
   * should only be set by invoking the method [setAnalysisOptions].
   */
  AnalysisOptions get analysisOptions;

  /**
   * Set the set of analysis options controlling the behavior of this context to
   * the given [options]. Clients can safely assume that all necessary analysis
   * results have been invalidated.
   */
  void set analysisOptions(AnalysisOptions options);

  /**
   * Set the order in which sources will be analyzed by [performAnalysisTask] to
   * match the order of the sources in the given list of [sources]. If a source
   * that needs to be analyzed is not contained in the list, then it will be
   * treated as if it were at the end of the list. If the list is empty (or
   * `null`) then no sources will be given priority over other sources.
   *
   * Changes made to the list after this method returns will <b>not</b> be
   * reflected in the priority order.
   */
  void set analysisPriorityOrder(List<Source> sources);

  /**
   * Return the set of declared variables used when computing constant values.
   */
  DeclaredVariables get declaredVariables;

  /**
   * Return a list containing all of the sources known to this context that
   * represent HTML files. The contents of the list can be incomplete.
   */
  List<Source> get htmlSources;

  /**
   * The stream that is notified when a source either starts or stops being
   * analyzed implicitly.
   */
  Stream<ImplicitAnalysisEvent> get implicitAnalysisEvents;

  /**
   * Returns `true` if this context was disposed using [dispose].
   */
  bool get isDisposed;

  /**
   * Return a list containing all of the sources known to this context that
   * represent the defining compilation unit of a library that can be run within
   * a browser. The sources that are returned represent libraries that have a
   * 'main' method and are either referenced by an HTML file or import, directly
   * or indirectly, a client-only library. The contents of the list can be
   * incomplete.
   */
  List<Source> get launchableClientLibrarySources;

  /**
   * Return a list containing all of the sources known to this context that
   * represent the defining compilation unit of a library that can be run
   * outside of a browser. The contents of the list can be incomplete.
   */
  List<Source> get launchableServerLibrarySources;

  /**
   * Return a list containing all of the sources known to this context that
   * represent the defining compilation unit of a library. The contents of the
   * list can be incomplete.
   */
  List<Source> get librarySources;

  /**
   * Return a client-provided name used to identify this context, or `null` if
   * the client has not provided a name.
   */
  String get name;

  /**
   * Set the client-provided name used to identify this context to the given
   * [name].
   */
  set name(String name);

  /**
   * The stream that is notified when sources have been added or removed,
   * or the source's content has changed.
   */
  Stream<SourcesChangedEvent> get onSourcesChanged;

  /**
   * Return the source factory used to create the sources that can be analyzed
   * in this context.
   */
  SourceFactory get sourceFactory;

  /**
   * Set the source factory used to create the sources that can be analyzed in
   * this context to the given source [factory]. Clients can safely assume that
   * all analysis results have been invalidated.
   */
  void set sourceFactory(SourceFactory factory);

  /**
   * Return a list containing all of the sources known to this context.
   */
  List<Source> get sources;

  /**
   * Return a type provider for this context or throw [AnalysisException] if
   * either `dart:core` or `dart:async` cannot be resolved.
   */
  TypeProvider get typeProvider;

  /**
   * Return a type system for this context.
   */
  TypeSystem get typeSystem;

  /**
   * Add the given [listener] to the list of objects that are to be notified
   * when various analysis results are produced in this context.
   */
  void addListener(AnalysisListener listener);

  /**
   * Apply the given [delta] to change the level of analysis that will be
   * performed for the sources known to this context.
   */
  void applyAnalysisDelta(AnalysisDelta delta);

  /**
   * Apply the changes specified by the given [changeSet] to this context. Any
   * analysis results that have been invalidated by these changes will be
   * removed.
   */
  void applyChanges(ChangeSet changeSet);

  /**
   * Return the documentation comment for the given [element] as it appears in
   * the original source (complete with the beginning and ending delimiters) for
   * block documentation comments, or lines starting with `"///"` and separated
   * with `"\n"` characters for end-of-line documentation comments, or `null` if
   * the element does not have a documentation comment associated with it. This
   * can be a long-running operation if the information needed to access the
   * comment is not cached.
   *
   * Throws an [AnalysisException] if the documentation comment could not be
   * determined because the analysis could not be performed.
   *
   * <b>Note:</b> This method cannot be used in an async environment.
   */
  String computeDocumentationComment(Element element);

  /**
   * Return a list containing all of the errors associated with the given
   * [source]. If the errors are not already known then the source will be
   * analyzed in order to determine the errors associated with it.
   *
   * Throws an [AnalysisException] if the errors could not be determined because
   * the analysis could not be performed.
   *
   * <b>Note:</b> This method cannot be used in an async environment.
   *
   * See [getErrors].
   */
  List<AnalysisError> computeErrors(Source source);

  /**
   * Return the kind of the given [source], computing it's kind if it is not
   * already known. Return [SourceKind.UNKNOWN] if the source is not contained
   * in this context.
   *
   * <b>Note:</b> This method cannot be used in an async environment.
   *
   * See [getKindOf].
   */
  SourceKind computeKindOf(Source source);

  /**
   * Return the element model corresponding to the library defined by the given
   * [source]. If the element model does not yet exist it will be created. The
   * process of creating an element model for a library can long-running,
   * depending on the size of the library and the number of libraries that are
   * imported into it that also need to have a model built for them.
   *
   * Throws an [AnalysisException] if the element model could not be determined
   * because the analysis could not be performed.
   *
   * <b>Note:</b> This method cannot be used in an async environment.
   *
   * See [getLibraryElement].
   */
  LibraryElement computeLibraryElement(Source source);

  /**
   * Return the line information for the given [source], or `null` if the source
   * is not of a recognized kind (neither a Dart nor HTML file). If the line
   * information was not previously known it will be created. The line
   * information is used to map offsets from the beginning of the source to line
   * and column pairs.
   *
   * Throws an [AnalysisException] if the line information could not be
   * determined because the analysis could not be performed.
   *
   * <b>Note:</b> This method cannot be used in an async environment.
   *
   * See [getLineInfo].
   */
  LineInfo computeLineInfo(Source source);

  /**
   * Return a future which will be completed with the fully resolved AST for a
   * single compilation unit within the given library, once that AST is up to
   * date.
   *
   * If the resolved AST can't be computed for some reason, the future will be
   * completed with an error.  One possible error is AnalysisNotScheduledError,
   * which means that the resolved AST can't be computed because the given
   * source file is not scheduled to be analyzed within the context of the
   * given library.
   */
  CancelableFuture<CompilationUnit> computeResolvedCompilationUnitAsync(
      Source source, Source librarySource);

  /**
   * Perform work until the given [result] has been computed for the given
   * [target]. Return the computed value.
   */
  V computeResult<V>(AnalysisTarget target, ResultDescriptor<V> result);

  /**
   * Notifies the context that the client is going to stop using this context.
   */
  void dispose();

  /**
   * Return `true` if the given [source] exists.
   *
   * This method should be used rather than the method [Source.exists] because
   * contexts can have local overrides of the content of a source that the
   * source is not aware of and a source with local content is considered to
   * exist even if there is no file on disk.
   */
  bool exists(Source source);

  /**
   * Return the element model corresponding to the compilation unit defined by
   * the given [unitSource] in the library defined by the given [librarySource],
   * or `null` if the element model does not currently exist or if the library
   * cannot be analyzed for some reason.
   */
  CompilationUnitElement getCompilationUnitElement(
      Source unitSource, Source librarySource);

  /**
   * Return configuration data associated with the given key or the [key]'s
   * default value if no state has been associated.
   *
   * See [setConfigurationData].
   */
  @deprecated
  V getConfigurationData<V>(ResultDescriptor<V> key);

  /**
   * Return the contents and timestamp of the given [source].
   *
   * This method should be used rather than the method [Source.getContents]
   * because contexts can have local overrides of the content of a source that
   * the source is not aware of.
   */
  TimestampedData<String> getContents(Source source);

  /**
   * Return the element referenced by the given [location], or `null` if the
   * element is not immediately available or if there is no element with the
   * given location. The latter condition can occur, for example, if the
   * location describes an element from a different context or if the element
   * has been removed from this context as a result of some change since it was
   * originally obtained.
   */
  Element getElement(ElementLocation location);

  /**
   * Return an analysis error info containing the list of all of the errors and
   * the line info associated with the given [source]. The list of errors will
   * be empty if the source is not known to this context or if there are no
   * errors in the source. The errors contained in the list can be incomplete.
   *
   * See [computeErrors].
   */
  AnalysisErrorInfo getErrors(Source source);

  /**
   * Return the sources for the HTML files that reference the compilation unit
   * with the given [source]. If the source does not represent a Dart source or
   * is not known to this context, the returned list will be empty. The contents
   * of the list can be incomplete.
   */
  List<Source> getHtmlFilesReferencing(Source source);

  /**
   * Return the kind of the given [source], or `null` if the kind is not known
   * to this context.
   *
   * See [computeKindOf].
   */
  SourceKind getKindOf(Source source);

  /**
   * Return the sources for the defining compilation units of any libraries of
   * which the given [source] is a part. The list will normally contain a single
   * library because most Dart sources are only included in a single library,
   * but it is possible to have a part that is contained in multiple identically
   * named libraries. If the source represents the defining compilation unit of
   * a library, then the returned list will contain the given source as its only
   * element. If the source does not represent a Dart source or is not known to
   * this context, the returned list will be empty. The contents of the list can
   * be incomplete.
   */
  List<Source> getLibrariesContaining(Source source);

  /**
   * Return the sources for the defining compilation units of any libraries that
   * depend on the library defined by the given [librarySource]. One library
   * depends on another if it either imports or exports that library.
   */
  List<Source> getLibrariesDependingOn(Source librarySource);

  /**
   * Return the sources for the defining compilation units of any libraries that
   * are referenced from the HTML file defined by the given [htmlSource].
   */
  List<Source> getLibrariesReferencedFromHtml(Source htmlSource);

  /**
   * Return the element model corresponding to the library defined by the given
   * [source], or `null` if the element model does not currently exist or if the
   * library cannot be analyzed for some reason.
   */
  LibraryElement getLibraryElement(Source source);

  /**
   * Return the line information for the given [source], or `null` if the line
   * information is not known. The line information is used to map offsets from
   * the beginning of the source to line and column pairs.
   *
   * See [computeLineInfo].
   */
  LineInfo getLineInfo(Source source);

  /**
   * Return the modification stamp for the [source], or a negative value if the
   * source does not exist. A modification stamp is a non-negative integer with
   * the property that if the contents of the source have not been modified
   * since the last time the modification stamp was accessed then the same value
   * will be returned, but if the contents of the source have been modified one
   * or more times (even if the net change is zero) the stamps will be different.
   *
   * This method should be used rather than the method
   * [Source.getModificationStamp] because contexts can have local overrides of
   * the content of a source that the source is not aware of.
   */
  int getModificationStamp(Source source);

  /**
   * Return a fully resolved AST for the compilation unit defined by the given
   * [unitSource] within the given [library], or `null` if the resolved AST is
   * not already computed.
   *
   * See [resolveCompilationUnit].
   */
  CompilationUnit getResolvedCompilationUnit(
      Source unitSource, LibraryElement library);

  /**
   * Return a fully resolved AST for the compilation unit defined by the given
   * [unitSource] within the library defined by the given [librarySource], or
   * `null` if the resolved AST is not already computed.
   *
   * See [resolveCompilationUnit2].
   */
  CompilationUnit getResolvedCompilationUnit2(
      Source unitSource, Source librarySource);

  /**
   * Return the value of the given [result] for the given [target].
   *
   * If the corresponding [target] does not exist, or the [result] is not
   * computed yet, then the default value is returned.
   */
  V getResult<V>(AnalysisTarget target, ResultDescriptor<V> result);

  /**
   * Return a list of the sources being analyzed in this context whose full path
   * is equal to the given [path].
   */
  List<Source> getSourcesWithFullName(String path);

  /**
   * Invalidates hints in the given [librarySource] and included parts.
   */
  void invalidateLibraryHints(Source librarySource);

  /**
   * Return `true` if the given [librarySource] is known to be the defining
   * compilation unit of a library that can be run on a client (references
   * 'dart:html', either directly or indirectly).
   *
   * <b>Note:</b> In addition to the expected case of returning `false` if the
   * source is known to be a library that cannot be run on a client, this method
   * will also return `false` if the source is not known to be a library or if
   * we do not know whether it can be run on a client.
   */
  bool isClientLibrary(Source librarySource);

  /**
   * Return `true` if the given [librarySource] is known to be the defining
   * compilation unit of a library that can be run on the server (does not
   * reference 'dart:html', either directly or indirectly).
   *
   * <b>Note:</b> In addition to the expected case of returning `false` if the
   * source is known to be a library that cannot be run on the server, this
   * method will also return `false` if the source is not known to be a library
   * or if we do not know whether it can be run on the server.
   */
  bool isServerLibrary(Source librarySource);

  /**
   * Return the stream that is notified when a result with the given
   * [descriptor] is changed, e.g. computed or invalidated.
   */
  Stream<ResultChangedEvent> onResultChanged(ResultDescriptor descriptor);

  /**
   * Return the stream that is notified when a new value for the given
   * [descriptor] is computed.
   */
  @deprecated
  Stream<ComputedResult> onResultComputed(ResultDescriptor descriptor);

  /**
   * Parse the content of the given [source] to produce an AST structure. The
   * resulting AST structure may or may not be resolved, and may have a slightly
   * different structure depending upon whether it is resolved.
   *
   * Throws an [AnalysisException] if the analysis could not be performed
   *
   * <b>Note:</b> This method cannot be used in an async environment.
   */
  CompilationUnit parseCompilationUnit(Source source);

  /**
   * Parse a single HTML [source] to produce a document model.
   *
   * Throws an [AnalysisException] if the analysis could not be performed
   *
   * <b>Note:</b> This method cannot be used in an async environment.
   */
  Document parseHtmlDocument(Source source);

  /**
   * Perform the next unit of work required to keep the analysis results
   * up-to-date and return information about the consequent changes to the
   * analysis results. This method can be long running.
   *
   * The implementation that uses the task model notifies subscribers of
   * [onResultChanged] about computed results.
   *
   * The following results are computed for Dart sources.
   *
   * 1. For explicit and implicit sources:
   *    [PARSED_UNIT]
   *    [RESOLVED_UNIT]
   *
   * 2. For explicit sources:
   *    [DART_ERRORS].
   *
   * 3. For explicit and implicit library sources:
   *    [LIBRARY_ELEMENT].
   */
  AnalysisResult performAnalysisTask();

  /**
   * Remove the given [listener] from the list of objects that are to be
   * notified when various analysis results are produced in this context.
   */
  void removeListener(AnalysisListener listener);

  /**
   * Return a fully resolved AST for the compilation unit defined by the given
   * [unitSource] within the given [library].
   *
   * Throws an [AnalysisException] if the analysis could not be performed.
   *
   * <b>Note:</b> This method cannot be used in an async environment.
   *
   * See [getResolvedCompilationUnit].
   */
  CompilationUnit resolveCompilationUnit(
      Source unitSource, LibraryElement library);

  /**
   * Return a fully resolved AST for the compilation unit defined by the given
   * [unitSource] within the library defined by the given [librarySource].
   *
   * Throws an [AnalysisException] if the analysis could not be performed.
   *
   * <b>Note:</b> This method cannot be used in an async environment.
   *
   * See [getResolvedCompilationUnit2].
   */
  CompilationUnit resolveCompilationUnit2(
      Source unitSource, Source librarySource);

  /**
   * Set the contents of the given [source] to the given [contents] and mark the
   * source as having changed. The additional [offset] and [length] information
   * is used by the context to determine what reanalysis is necessary.
   */
  void setChangedContents(
      Source source, String contents, int offset, int oldLength, int newLength);

  /**
   * Associate this configuration [data] object with the given descriptor [key].
   *
   * See [getConfigurationData].
   */
  @deprecated
  void setConfigurationData(ResultDescriptor key, Object data);

  /**
   * Set the contents of the given [source] to the given [contents] and mark the
   * source as having changed. This has the effect of overriding the default
   * contents of the source. If the contents are `null` the override is removed
   * so that the default contents will be returned.
   */
  void setContents(Source source, String contents);
}

/**
 * A representation of changes to the types of analysis that should be
 * performed.
 */
class AnalysisDelta {
  /**
   * A mapping from source to what type of analysis should be performed on that
   * source.
   */
  HashMap<Source, AnalysisLevel> _analysisMap =
      new HashMap<Source, AnalysisLevel>();

  /**
   * Return a collection of the sources that have been added. This is equivalent
   * to calling [getAnalysisLevels] and collecting all sources that do not have
   * an analysis level of [AnalysisLevel.NONE].
   */
  List<Source> get addedSources {
    List<Source> result = new List<Source>();
    _analysisMap.forEach((Source source, AnalysisLevel level) {
      if (level != AnalysisLevel.NONE) {
        result.add(source);
      }
    });
    return result;
  }

  /**
   * Return a mapping of sources to the level of analysis that should be
   * performed.
   */
  Map<Source, AnalysisLevel> get analysisLevels => _analysisMap;

  /**
   * Record that the given [source] should be analyzed at the given [level].
   */
  void setAnalysisLevel(Source source, AnalysisLevel level) {
    _analysisMap[source] = level;
  }

  @override
  String toString() {
    StringBuffer buffer = new StringBuffer();
    bool needsSeparator = _appendSources(buffer, false, AnalysisLevel.ALL);
    needsSeparator =
        _appendSources(buffer, needsSeparator, AnalysisLevel.RESOLVED);
    _appendSources(buffer, needsSeparator, AnalysisLevel.NONE);
    return buffer.toString();
  }

  /**
   * Append to the given [buffer] all sources with the given analysis [level],
   * prefixed with a label and a separator if [needsSeparator] is `true`.
   */
  bool _appendSources(
      StringBuffer buffer, bool needsSeparator, AnalysisLevel level) {
    bool first = true;
    _analysisMap.forEach((Source source, AnalysisLevel sourceLevel) {
      if (sourceLevel == level) {
        if (first) {
          first = false;
          if (needsSeparator) {
            buffer.write("; ");
          }
          buffer.write(level);
          buffer.write(" ");
        } else {
          buffer.write(", ");
        }
        buffer.write(source.fullName);
      }
    });
    return needsSeparator || !first;
  }
}

/**
 * The entry point for the functionality provided by the analysis engine. There
 * is a single instance of this class.
 */
class AnalysisEngine {
  /**
   * The suffix used for Dart source files.
   */
  static const String SUFFIX_DART = "dart";

  /**
   * The short suffix used for HTML files.
   */
  static const String SUFFIX_HTM = "htm";

  /**
   * The long suffix used for HTML files.
   */
  static const String SUFFIX_HTML = "html";

  /**
   * The deprecated file name used for analysis options files.
   */
  static const String ANALYSIS_OPTIONS_FILE = '.analysis_options';

  /**
   * The file name used for analysis options files.
   */
  static const String ANALYSIS_OPTIONS_YAML_FILE = 'analysis_options.yaml';

  /**
   * The unique instance of this class.
   */
  static final AnalysisEngine instance = new AnalysisEngine._();

  /**
   * The logger that should receive information about errors within the analysis
   * engine.
   */
  Logger _logger = Logger.NULL;

  /**
   * The plugin that defines the extension points and extensions that are
   * inherently defined by the analysis engine.
   */
  final EnginePlugin enginePlugin = new EnginePlugin();

  /**
   * The instrumentation service that is to be used by this analysis engine.
   */
  InstrumentationService _instrumentationService =
      InstrumentationService.NULL_SERVICE;

  /**
   * The partition manager being used to manage the shared partitions.
   */
  final PartitionManager partitionManager = new PartitionManager();

  /**
   * The task manager used to manage the tasks used to analyze code.
   */
  TaskManager _taskManager;

  AnalysisEngine._();

  /**
   * Return the instrumentation service that is to be used by this analysis
   * engine.
   */
  InstrumentationService get instrumentationService => _instrumentationService;

  /**
   * Set the instrumentation service that is to be used by this analysis engine
   * to the given [service].
   */
  void set instrumentationService(InstrumentationService service) {
    if (service == null) {
      _instrumentationService = InstrumentationService.NULL_SERVICE;
    } else {
      _instrumentationService = service;
    }
  }

  /**
   * Return the logger that should receive information about errors within the
   * analysis engine.
   */
  Logger get logger => _logger;

  /**
   * Set the logger that should receive information about errors within the
   * analysis engine to the given [logger].
   */
  void set logger(Logger logger) {
    this._logger = logger ?? Logger.NULL;
  }

  /**
   * Return the list of plugins that clients are required to process, either by
   * creating an [ExtensionManager] or by using the method
   * [processRequiredPlugins].
   */
  List<Plugin> get requiredPlugins => <Plugin>[enginePlugin];

  /**
   * Return the task manager used to manage the tasks used to analyze code.
   */
  TaskManager get taskManager {
    if (_taskManager == null) {
      _taskManager = new TaskManager();
      _initializeTaskMap();
      _initializeResults();
    }
    return _taskManager;
  }

  /**
   * Clear any caches holding on to analysis results so that a full re-analysis
   * will be performed the next time an analysis context is created.
   */
  void clearCaches() {
    partitionManager.clearCache();
  }

  /**
   * Create and return a new context in which analysis can be performed.
   */
  AnalysisContext createAnalysisContext() {
    return new AnalysisContextImpl();
  }

  /**
   * A utility method that clients can use to process all of the required
   * plugins. This method can only be used by clients that do not need to
   * process any other plugins.
   */
  void processRequiredPlugins() {
    if (enginePlugin.workManagerFactoryExtensionPoint == null) {
      ExtensionManager manager = new ExtensionManager();
      manager.processPlugins(requiredPlugins);
    }
  }

  void _initializeResults() {
    _taskManager.addGeneralResult(DART_ERRORS);
  }

  void _initializeTaskMap() {
    //
    // Register general tasks.
    //
    _taskManager.addTaskDescriptor(GetContentTask.DESCRIPTOR);
    //
    // Register Dart tasks.
    //
    _taskManager.addTaskDescriptor(BuildCompilationUnitElementTask.DESCRIPTOR);
    _taskManager.addTaskDescriptor(BuildDirectiveElementsTask.DESCRIPTOR);
    _taskManager.addTaskDescriptor(BuildEnumMemberElementsTask.DESCRIPTOR);
    _taskManager.addTaskDescriptor(BuildExportNamespaceTask.DESCRIPTOR);
    _taskManager.addTaskDescriptor(BuildLibraryElementTask.DESCRIPTOR);
    _taskManager.addTaskDescriptor(BuildPublicNamespaceTask.DESCRIPTOR);
    _taskManager.addTaskDescriptor(BuildSourceExportClosureTask.DESCRIPTOR);
    _taskManager.addTaskDescriptor(BuildTypeProviderTask.DESCRIPTOR);
    _taskManager.addTaskDescriptor(ComputeConstantDependenciesTask.DESCRIPTOR);
    _taskManager.addTaskDescriptor(ComputeConstantValueTask.DESCRIPTOR);
    _taskManager.addTaskDescriptor(
        ComputeInferableStaticVariableDependenciesTask.DESCRIPTOR);
    _taskManager.addTaskDescriptor(ComputeLibraryCycleTask.DESCRIPTOR);
    _taskManager.addTaskDescriptor(ComputeRequiredConstantsTask.DESCRIPTOR);
    _taskManager.addTaskDescriptor(ContainingLibrariesTask.DESCRIPTOR);
    _taskManager.addTaskDescriptor(DartErrorsTask.DESCRIPTOR);
    _taskManager.addTaskDescriptor(EvaluateUnitConstantsTask.DESCRIPTOR);
    _taskManager.addTaskDescriptor(GatherUsedImportedElementsTask.DESCRIPTOR);
    _taskManager.addTaskDescriptor(GatherUsedLocalElementsTask.DESCRIPTOR);
    _taskManager.addTaskDescriptor(GenerateHintsTask.DESCRIPTOR);
    _taskManager.addTaskDescriptor(GenerateLintsTask.DESCRIPTOR);
    _taskManager.addTaskDescriptor(InferInstanceMembersInUnitTask.DESCRIPTOR);
    _taskManager
        .addTaskDescriptor(InferStaticVariableTypesInUnitTask.DESCRIPTOR);
    _taskManager.addTaskDescriptor(InferStaticVariableTypeTask.DESCRIPTOR);
    _taskManager.addTaskDescriptor(LibraryErrorsReadyTask.DESCRIPTOR);
    _taskManager.addTaskDescriptor(LibraryUnitErrorsTask.DESCRIPTOR);
    _taskManager.addTaskDescriptor(ParseDartTask.DESCRIPTOR);
    _taskManager
        .addTaskDescriptor(PartiallyResolveUnitReferencesTask.DESCRIPTOR);
    _taskManager.addTaskDescriptor(ReadyLibraryElement2Task.DESCRIPTOR);
    _taskManager.addTaskDescriptor(ReadyLibraryElement5Task.DESCRIPTOR);
    _taskManager.addTaskDescriptor(ReadyLibraryElement7Task.DESCRIPTOR);
    _taskManager.addTaskDescriptor(ReadyResolvedUnitTask.DESCRIPTOR);
    _taskManager.addTaskDescriptor(ResolveConstantExpressionTask.DESCRIPTOR);
    _taskManager.addTaskDescriptor(ResolveDirectiveElementsTask.DESCRIPTOR);
    _taskManager
        .addTaskDescriptor(ResolvedUnit7InLibraryClosureTask.DESCRIPTOR);
    _taskManager.addTaskDescriptor(ResolvedUnit7InLibraryTask.DESCRIPTOR);
    _taskManager.addTaskDescriptor(ResolveInstanceFieldsInUnitTask.DESCRIPTOR);
    _taskManager.addTaskDescriptor(ResolveLibraryReferencesTask.DESCRIPTOR);
    _taskManager.addTaskDescriptor(ResolveLibraryTask.DESCRIPTOR);
    _taskManager.addTaskDescriptor(ResolveLibraryTypeNamesTask.DESCRIPTOR);
    _taskManager
        .addTaskDescriptor(ResolveTopLevelLibraryTypeBoundsTask.DESCRIPTOR);
    _taskManager
        .addTaskDescriptor(ResolveTopLevelUnitTypeBoundsTask.DESCRIPTOR);
    _taskManager.addTaskDescriptor(ResolveUnitTask.DESCRIPTOR);
    _taskManager.addTaskDescriptor(ResolveUnitTypeNamesTask.DESCRIPTOR);
    _taskManager.addTaskDescriptor(ResolveVariableReferencesTask.DESCRIPTOR);
    _taskManager.addTaskDescriptor(ScanDartTask.DESCRIPTOR);
    _taskManager.addTaskDescriptor(StrongModeVerifyUnitTask.DESCRIPTOR);
    _taskManager.addTaskDescriptor(VerifyUnitTask.DESCRIPTOR);
    //
    // Register HTML tasks.
    //
    _taskManager.addTaskDescriptor(DartScriptsTask.DESCRIPTOR);
    _taskManager.addTaskDescriptor(HtmlErrorsTask.DESCRIPTOR);
    _taskManager.addTaskDescriptor(ParseHtmlTask.DESCRIPTOR);
    //
    // Register YAML tasks.
    //
    _taskManager.addTaskDescriptor(ParseYamlTask.DESCRIPTOR);
    //
    // Register analysis option file tasks.
    //
    _taskManager.addTaskDescriptor(GenerateOptionsErrorsTask.DESCRIPTOR);
  }

  /**
   * Return `true` if the given [fileName] is an analysis options file.
   */
  static bool isAnalysisOptionsFileName(String fileName,
      [pathos.Context context]) {
    if (fileName == null) {
      return false;
    }
    String basename = (context ?? pathos.posix).basename(fileName);
    return basename == ANALYSIS_OPTIONS_FILE ||
        basename == ANALYSIS_OPTIONS_YAML_FILE;
  }

  /**
   * Return `true` if the given [fileName] is assumed to contain Dart source
   * code.
   */
  static bool isDartFileName(String fileName) {
    if (fileName == null) {
      return false;
    }
    String extension = FileNameUtilities.getExtension(fileName).toLowerCase();
    return extension == SUFFIX_DART;
  }

  /**
   * Return `true` if the given [fileName] is assumed to contain HTML.
   */
  static bool isHtmlFileName(String fileName) {
    if (fileName == null) {
      return false;
    }
    String extension = FileNameUtilities.getExtension(fileName).toLowerCase();
    return extension == SUFFIX_HTML || extension == SUFFIX_HTM;
  }
}

/**
 * The analysis errors and line information for the errors.
 */
abstract class AnalysisErrorInfo {
  /**
   * Return the errors that as a result of the analysis, or `null` if there were
   * no errors.
   */
  List<AnalysisError> get errors;

  /**
   * Return the line information associated with the errors, or `null` if there
   * were no errors.
   */
  LineInfo get lineInfo;
}

/**
 * The analysis errors and line info associated with a source.
 */
class AnalysisErrorInfoImpl implements AnalysisErrorInfo {
  /**
   * The analysis errors associated with a source, or `null` if there are no
   * errors.
   */
  @override
  final List<AnalysisError> errors;

  /**
   * The line information associated with the errors, or `null` if there are no
   * errors.
   */
  final LineInfo lineInfo;

  /**
   * Initialize an newly created error info with the given [errors] and
   * [lineInfo].
   */
  AnalysisErrorInfoImpl(this.errors, this.lineInfo);
}

/**
 * The levels at which a source can be analyzed.
 */
class AnalysisLevel implements Comparable<AnalysisLevel> {
  /**
   * Indicates a source should be fully analyzed.
   */
  static const AnalysisLevel ALL = const AnalysisLevel('ALL', 0);

  /**
   * Indicates a source should be resolved and that errors, warnings and hints
   * are needed.
   */
  static const AnalysisLevel ERRORS = const AnalysisLevel('ERRORS', 1);

  /**
   * Indicates a source should be resolved, but that errors, warnings and hints
   * are not needed.
   */
  static const AnalysisLevel RESOLVED = const AnalysisLevel('RESOLVED', 2);

  /**
   * Indicates a source is not of interest to the client.
   */
  static const AnalysisLevel NONE = const AnalysisLevel('NONE', 3);

  static const List<AnalysisLevel> values = const [ALL, ERRORS, RESOLVED, NONE];

  /**
   * The name of this analysis level.
   */
  final String name;

  /**
   * The ordinal value of the analysis level.
   */
  final int ordinal;

  const AnalysisLevel(this.name, this.ordinal);

  @override
  int get hashCode => ordinal;

  @override
  int compareTo(AnalysisLevel other) => ordinal - other.ordinal;

  @override
  String toString() => name;
}

/**
 * An object that is listening for results being produced by an analysis
 * context.
 */
abstract class AnalysisListener {
  /**
   * Reports that a task, described by the given [taskDescription] is about to
   * be performed by the given [context].
   */
  void aboutToPerformTask(AnalysisContext context, String taskDescription);

  /**
   * Reports that the [errors] associated with the given [source] in the given
   * [context] has been updated to the given errors. The [lineInfo] is the line
   * information associated with the source.
   */
  void computedErrors(AnalysisContext context, Source source,
      List<AnalysisError> errors, LineInfo lineInfo);

  /**
   * Reports that the given [source] is no longer included in the set of sources
   * that are being analyzed by the given analysis [context].
   */
  void excludedSource(AnalysisContext context, Source source);

  /**
   * Reports that the given [source] is now included in the set of sources that
   * are being analyzed by the given analysis [context].
   */
  void includedSource(AnalysisContext context, Source source);

  /**
   * Reports that the given Dart [source] was parsed in the given [context],
   * producing the given [unit].
   */
  void parsedDart(AnalysisContext context, Source source, CompilationUnit unit);

  /**
   * Reports that the given Dart [source] was resolved in the given [context].
   */
  void resolvedDart(
      AnalysisContext context, Source source, CompilationUnit unit);
}

/**
 * Futures returned by [AnalysisContext] for pending analysis results will
 * complete with this error if it is determined that analysis results will
 * never become available (e.g. because the requested source is not subject to
 * analysis, or because the requested source is a part file which is not a part
 * of any known library).
 */
class AnalysisNotScheduledError implements Exception {}

/**
 * A set of analysis options used to control the behavior of an analysis
 * context.
 */
abstract class AnalysisOptions {
  /**
   * The length of the list returned by [encodeCrossContextOptions].
   */
  static const int signatureLength = 4;

  /**
   * Function that returns `true` if analysis is to parse and analyze function
   * bodies for a given source.
   */
  AnalyzeFunctionBodiesPredicate get analyzeFunctionBodiesPredicate;

  /**
   * DEPRECATED: Return the maximum number of sources for which AST structures should be
   * kept in the cache.
   *
   * This setting no longer has any effect.
   */
  @deprecated
  int get cacheSize;

  /**
   * Return `true` if analysis is to generate dart2js related hint results.
   */
  bool get dart2jsHint;

  /**
   * Return `true` if cache flushing should be disabled.  Setting this option to
   * `true` can improve analysis speed at the expense of memory usage.  It may
   * also be useful for working around bugs.
   *
   * This option should not be used when the analyzer is part of a long running
   * process (such as the analysis server) because it has the potential to
   * prevent memory from being reclaimed.
   */
  bool get disableCacheFlushing;

  /**
   * Return `true` if the parser is to parse asserts in the initializer list of
   * a constructor.
   */
  bool get enableAssertInitializer;

  /**
   * Return `true` to enable custom assert messages (DEP 37).
   */
  @deprecated
  bool get enableAssertMessage;

  /**
   * Return `true` to if analysis is to enable async support.
   */
  @deprecated
  bool get enableAsync;

  /**
   * Return `true` to enable interface libraries (DEP 40).
   */
  @deprecated
  bool get enableConditionalDirectives;

  /**
   * Return `true` to enable generic methods (DEP 22).
   */
  @deprecated
  bool get enableGenericMethods => null;

  /**
   * Return `true` if access to field formal parameters should be allowed in a
   * constructor's initializer list.
   */
  @deprecated
  bool get enableInitializingFormalAccess;

  /**
   * Return `true` to enable the lazy compound assignment operators '&&=' and
   * '||='.
   */
  bool get enableLazyAssignmentOperators;

  /**
   * Return `true` to strictly follow the specification when generating
   * warnings on "call" methods (fixes dartbug.com/21938).
   */
  bool get enableStrictCallChecks;

  /**
   * Return `true` if mixins are allowed to inherit from types other than
   * Object, and are allowed to reference `super`.
   */
  bool get enableSuperMixins;

  /**
   * Return `true` if timing data should be gathered during execution.
   */
  bool get enableTiming;

  /**
   * Return `true` to enable the use of URIs in part-of directives.
   */
  bool get enableUriInPartOf;

  /**
   * Return a list of error processors that are to be used when reporting
   * errors in some analysis context.
   */
  List<ErrorProcessor> get errorProcessors;

  /**
   * Return a list of exclude patterns used to exclude some sources from
   * analysis.
   */
  List<String> get excludePatterns;

  /**
   * Return `true` if errors, warnings and hints should be generated for sources
   * that are implicitly being analyzed. The default value is `true`.
   */
  bool get generateImplicitErrors;

  /**
   * Return `true` if errors, warnings and hints should be generated for sources
   * in the SDK. The default value is `false`.
   */
  bool get generateSdkErrors;

  /**
   * Return `true` if analysis is to generate hint results (e.g. type inference
   * based information and pub best practices).
   */
  bool get hint;

  /**
   * Return `true` if analysis is to generate lint warnings.
   */
  bool get lint;

  /**
   * Return a list of the lint rules that are to be run in an analysis context
   * if [lint] returns `true`.
   */
  List<Linter> get lintRules;

  /**
   * A mapping from Dart SDK library name (e.g. "dart:core") to a list of paths
   * to patch files that should be applied to the library.
   */
  Map<String, List<String>> get patchPaths;

  /**
   * Return `true` if analysis is to parse comments.
   */
  bool get preserveComments;

  /**
   * Return the opaque signature of the options.
   *
   * The length of the list is guaranteed to equal [signatureLength].
   */
  Uint32List get signature;

  /**
   * Return `true` if strong mode analysis should be used.
   */
  bool get strongMode;

  /**
   * Return `true` if dependencies between computed results should be tracked
   * by analysis cache.  This option should only be set to `false` if analysis
   * is performed in such a way that none of the inputs is ever changed
   * during the life time of the context.
   */
  bool get trackCacheDependencies;

  /**
   * Reset the state of this set of analysis options to its original state.
   */
  void resetToDefaults();

  /**
   * Set the values of the cross-context options to match those in the given set
   * of [options].
   */
  void setCrossContextOptionsFrom(AnalysisOptions options);

  /**
   * Determine whether two signatures returned by [signature] are equal.
   */
  static bool signaturesEqual(Uint32List a, Uint32List b) {
    assert(a.length == signatureLength);
    assert(b.length == signatureLength);
    if (a.length != b.length) {
      return false;
    }
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }
}

/**
 * A set of analysis options used to control the behavior of an analysis
 * context.
 */
class AnalysisOptionsImpl implements AnalysisOptions {
  /**
   * DEPRECATED: The maximum number of sources for which data should be kept in
   * the cache.
   *
   * This constant no longer has any effect.
   */
  @deprecated
  static const int DEFAULT_CACHE_SIZE = 64;

  /**
   * The default list of non-nullable type names.
   */
  static const List<String> NONNULLABLE_TYPES = const <String>[];

  /**
   * A predicate indicating whether analysis is to parse and analyze function
   * bodies.
   */
  AnalyzeFunctionBodiesPredicate _analyzeFunctionBodiesPredicate =
      _analyzeAllFunctionBodies;

  /**
   * The cached [signature].
   */
  Uint32List _signature;

  @override
  @deprecated
  int cacheSize = 64;

  @override
  bool dart2jsHint = false;

  @override
  bool enableAssertInitializer = false;

  @override
  bool enableLazyAssignmentOperators = false;

  @override
  bool enableStrictCallChecks = false;

  @override
  bool enableSuperMixins = false;

  @override
  bool enableTiming = false;

  /**
   * A list of error processors that are to be used when reporting errors in
   * some analysis context.
   */
  List<ErrorProcessor> _errorProcessors;

  /**
   * A list of exclude patterns used to exclude some sources from analysis.
   */
  List<String> _excludePatterns;

  @override
  bool enableUriInPartOf = true;

  @override
  bool generateImplicitErrors = true;

  @override
  bool generateSdkErrors = false;

  @override
  bool hint = true;

  @override
  bool lint = false;

  /**
   * The lint rules that are to be run in an analysis context if [lint] returns
   * `true`.
   */
  List<Linter> _lintRules;

  Map<String, List<String>> patchPaths = {};

  @override
  bool preserveComments = true;

  @override
  bool strongMode = false;

  /**
   * A flag indicating whether strong-mode inference hints should be
   * used.  This flag is not exposed in the interface, and should be
   * replaced by something more general.
   */
  // TODO(leafp): replace this with something more general
  bool strongModeHints = false;

  @override
  bool trackCacheDependencies = true;

  @override
  bool disableCacheFlushing = false;

  /**
   * A flag indicating whether implicit casts are allowed in [strongMode]
   * (they are always allowed in Dart 1.0 mode).
   *
   * This option is experimental and subject to change.
   */
  bool implicitCasts = true;

  /**
   * A list of non-nullable type names, prefixed by the library URI they belong
   * to, e.g., 'dart:core,int', 'dart:core,bool', 'file:///foo.dart,bar', etc.
   */
  List<String> nonnullableTypes = NONNULLABLE_TYPES;

  /**
   * A flag indicating whether implicit dynamic type is allowed, on by default.
   *
   * This flag can be used without necessarily enabling [strongMode], but it is
   * designed with strong mode's type inference in mind. Without type inference,
   * it will raise many errors. Also it does not provide type safety without
   * strong mode.
   *
   * This option is experimental and subject to change.
   */
  bool implicitDynamic = true;

  /**
   * Initialize a newly created set of analysis options to have their default
   * values.
   */
  AnalysisOptionsImpl();

  /**
   * Initialize a newly created set of analysis options to have the same values
   * as those in the given set of analysis [options].
   */
  AnalysisOptionsImpl.from(AnalysisOptions options) {
    analyzeFunctionBodiesPredicate = options.analyzeFunctionBodiesPredicate;
    dart2jsHint = options.dart2jsHint;
    enableAssertInitializer = options.enableAssertInitializer;
    enableStrictCallChecks = options.enableStrictCallChecks;
    enableLazyAssignmentOperators = options.enableLazyAssignmentOperators;
    enableSuperMixins = options.enableSuperMixins;
    enableTiming = options.enableTiming;
    errorProcessors = options.errorProcessors;
    excludePatterns = options.excludePatterns;
    generateImplicitErrors = options.generateImplicitErrors;
    generateSdkErrors = options.generateSdkErrors;
    hint = options.hint;
    lint = options.lint;
    lintRules = options.lintRules;
    preserveComments = options.preserveComments;
    strongMode = options.strongMode;
    if (options is AnalysisOptionsImpl) {
      strongModeHints = options.strongModeHints;
      implicitCasts = options.implicitCasts;
      nonnullableTypes = options.nonnullableTypes;
      implicitDynamic = options.implicitDynamic;
    }
    trackCacheDependencies = options.trackCacheDependencies;
    disableCacheFlushing = options.disableCacheFlushing;
    patchPaths = options.patchPaths;
  }

  bool get analyzeFunctionBodies {
    if (identical(analyzeFunctionBodiesPredicate, _analyzeAllFunctionBodies)) {
      return true;
    } else if (identical(
        analyzeFunctionBodiesPredicate, _analyzeNoFunctionBodies)) {
      return false;
    } else {
      throw new StateError('analyzeFunctionBodiesPredicate in use');
    }
  }

  set analyzeFunctionBodies(bool value) {
    if (value) {
      analyzeFunctionBodiesPredicate = _analyzeAllFunctionBodies;
    } else {
      analyzeFunctionBodiesPredicate = _analyzeNoFunctionBodies;
    }
  }

  @override
  AnalyzeFunctionBodiesPredicate get analyzeFunctionBodiesPredicate =>
      _analyzeFunctionBodiesPredicate;

  set analyzeFunctionBodiesPredicate(AnalyzeFunctionBodiesPredicate value) {
    if (value == null) {
      throw new ArgumentError.notNull('analyzeFunctionBodiesPredicate');
    }
    _analyzeFunctionBodiesPredicate = value;
  }

  @override
  @deprecated
  bool get enableAssertMessage => true;

  @deprecated
  void set enableAssertMessage(bool enable) {}

  @deprecated
  @override
  bool get enableAsync => true;

  @deprecated
  void set enableAsync(bool enable) {}

  /**
   * A flag indicating whether interface libraries are to be supported (DEP 40).
   */
  bool get enableConditionalDirectives => true;

  @deprecated
  void set enableConditionalDirectives(_) {}

  @override
  @deprecated
  bool get enableGenericMethods => true;

  @deprecated
  void set enableGenericMethods(bool enable) {}

  @deprecated
  @override
  bool get enableInitializingFormalAccess => true;

  @deprecated
  void set enableInitializingFormalAccess(bool enable) {}

  @override
  List<ErrorProcessor> get errorProcessors =>
      _errorProcessors ??= const <ErrorProcessor>[];

  /**
   * Set the list of error [processors] that are to be used when reporting
   * errors in some analysis context.
   */
  void set errorProcessors(List<ErrorProcessor> processors) {
    _errorProcessors = processors;
  }

  @override
  List<String> get excludePatterns => _excludePatterns ??= const <String>[];

  /**
   * Set the exclude patterns used to exclude some sources from analysis to
   * those in the given list of [patterns].
   */
  void set excludePatterns(List<String> patterns) {
    _excludePatterns = patterns;
  }

  @override
  List<Linter> get lintRules => _lintRules ??= const <Linter>[];

  /**
   * Set the lint rules that are to be run in an analysis context if [lint]
   * returns `true`.
   */
  void set lintRules(List<Linter> rules) {
    _lintRules = rules;
  }

  @override
  Uint32List get signature {
    if (_signature == null) {
      ApiSignature buffer = new ApiSignature();

      // Append boolean flags.
      buffer.addBool(enableAssertInitializer);
      buffer.addBool(enableLazyAssignmentOperators);
      buffer.addBool(enableStrictCallChecks);
      buffer.addBool(enableSuperMixins);
      buffer.addBool(enableUriInPartOf);
      buffer.addBool(implicitCasts);
      buffer.addBool(implicitDynamic);
      buffer.addBool(strongMode);
      buffer.addBool(strongModeHints);

      // Append error processors.
      buffer.addInt(errorProcessors.length);
      for (ErrorProcessor processor in errorProcessors) {
        buffer.addString(processor.description);
      }

      // Append lints.
      buffer.addInt(lintRules.length);
      for (Linter lintRule in lintRules) {
        buffer.addString(lintRule.lintCode.uniqueName);
      }

      // Hash and convert to Uint32List.
      List<int> bytes = buffer.toByteList();
      _signature = new Uint8List.fromList(bytes).buffer.asUint32List();
    }
    return _signature;
  }

  @override
  void resetToDefaults() {
    dart2jsHint = false;
    disableCacheFlushing = false;
    enableAssertInitializer = false;
    enableLazyAssignmentOperators = false;
    enableStrictCallChecks = false;
    enableSuperMixins = false;
    enableTiming = false;
    enableUriInPartOf = true;
    _errorProcessors = null;
    _excludePatterns = null;
    generateImplicitErrors = true;
    generateSdkErrors = false;
    hint = true;
    implicitCasts = true;
    implicitDynamic = true;
    lint = false;
    _lintRules = null;
    nonnullableTypes = NONNULLABLE_TYPES;
    patchPaths = {};
    preserveComments = true;
    strongMode = false;
    strongModeHints = false;
    trackCacheDependencies = true;
  }

  @override
  void setCrossContextOptionsFrom(AnalysisOptions options) {
    enableLazyAssignmentOperators = options.enableLazyAssignmentOperators;
    enableStrictCallChecks = options.enableStrictCallChecks;
    enableSuperMixins = options.enableSuperMixins;
    strongMode = options.strongMode;
    if (options is AnalysisOptionsImpl) {
      strongModeHints = options.strongModeHints;
    }
  }

  /**
   * Return whether the given lists of lints are equal.
   */
  static bool compareLints(List<Linter> a, List<Linter> b) {
    if (a.length != b.length) {
      return false;
    }
    for (int i = 0; i < a.length; i++) {
      if (a[i].lintCode != b[i].lintCode) {
        return false;
      }
    }
    return true;
  }

  /**
   * Predicate used for [analyzeFunctionBodiesPredicate] when
   * [analyzeFunctionBodies] is set to `true`.
   */
  static bool _analyzeAllFunctionBodies(Source _) => true;

  /**
   * Predicate used for [analyzeFunctionBodiesPredicate] when
   * [analyzeFunctionBodies] is set to `false`.
   */
  static bool _analyzeNoFunctionBodies(Source _) => false;
}

/**
 *
 */
class AnalysisResult {
  /**
   * The change notices associated with this result, or `null` if there were no
   * changes and there is no more work to be done.
   */
  final List<ChangeNotice> _notices;

  /**
   * The number of milliseconds required to determine which task was to be
   * performed.
   */
  final int getTime;

  /**
   * The name of the class of the task that was performed.
   */
  final String taskClassName;

  /**
   * The number of milliseconds required to perform the task.
   */
  final int performTime;

  /**
   * Initialize a newly created analysis result to have the given values. The
   * [notices] is the change notices associated with this result. The [getTime]
   * is the number of milliseconds required to determine which task was to be
   * performed. The [taskClassName] is the name of the class of the task that
   * was performed. The [performTime] is the number of milliseconds required to
   * perform the task.
   */
  AnalysisResult(
      this._notices, this.getTime, this.taskClassName, this.performTime);

  /**
   * Return the change notices associated with this result, or `null` if there
   * were no changes and there is no more work to be done.
   */
  List<ChangeNotice> get changeNotices => _notices;

  /**
   * Return `true` if there is more to be performed after the task that was
   * performed.
   */
  bool get hasMoreWork => _notices != null;
}

/**
 * Statistics about cache consistency validation.
 */
class CacheConsistencyValidationStatistics {
  /**
   * Number of sources which were changed, but the context was not notified
   * about it, so this fact was detected only during cache consistency
   * validation.
   */
  int numOfChanged = 0;

  /**
   * Number of sources which stopped existing, but the context was not notified
   * about it, so this fact was detected only during cache consistency
   * validation.
   */
  int numOfRemoved = 0;

  /**
   * Reset all counters.
   */
  void reset() {
    numOfChanged = 0;
    numOfRemoved = 0;
  }
}

/**
 * Interface for cache consistency validation in an [InternalAnalysisContext].
 */
abstract class CacheConsistencyValidator {
  /**
   * Return sources for which the contexts needs to know modification times.
   */
  List<Source> getSourcesToComputeModificationTimes();

  /**
   * Notify the validator that modification [times] were computed for [sources].
   * If a source does not exist, its modification time is `-1`.
   *
   * It's up to the validator and the context how to use this information,
   * the list of sources the context has might have been changed since the
   * previous invocation of [getSourcesToComputeModificationTimes].
   *
   * Check the cache for any invalid entries (entries whose modification time
   * does not match the modification time of the source associated with the
   * entry). Invalid entries will be marked as invalid so that the source will
   * be re-analyzed. Return `true` if at least one entry was invalid.
   */
  bool sourceModificationTimesComputed(List<Source> sources, List<int> times);
}

/**
 * The possible states of cached data.
 */
class CacheState implements Comparable<CacheState> {
  /**
   * The data is not in the cache and the last time an attempt was made to
   * compute the data an exception occurred, making it pointless to attempt to
   * compute the data again.
   *
   * Valid Transitions:
   * * [INVALID] if a source was modified that might cause the data to be
   *   computable
   */
  static const CacheState ERROR = const CacheState('ERROR', 0);

  /**
   * The data is not in the cache because it was flushed from the cache in order
   * to control memory usage. If the data is recomputed, results do not need to
   * be reported.
   *
   * Valid Transitions:
   * * [IN_PROCESS] if the data is being recomputed
   * * [INVALID] if a source was modified that causes the data to need to be
   *   recomputed
   */
  static const CacheState FLUSHED = const CacheState('FLUSHED', 1);

  /**
   * The data might or might not be in the cache but is in the process of being
   * recomputed.
   *
   * Valid Transitions:
   * * [ERROR] if an exception occurred while trying to compute the data
   * * [VALID] if the data was successfully computed and stored in the cache
   */
  static const CacheState IN_PROCESS = const CacheState('IN_PROCESS', 2);

  /**
   * The data is not in the cache and needs to be recomputed so that results can
   * be reported.
   *
   * Valid Transitions:
   * * [IN_PROCESS] if an attempt is being made to recompute the data
   */
  static const CacheState INVALID = const CacheState('INVALID', 3);

  /**
   * The data is in the cache and up-to-date.
   *
   * Valid Transitions:
   * * [FLUSHED] if the data is removed in order to manage memory usage
   * * [INVALID] if a source was modified in such a way as to invalidate the
   *   previous data
   */
  static const CacheState VALID = const CacheState('VALID', 4);

  static const List<CacheState> values = const [
    ERROR,
    FLUSHED,
    IN_PROCESS,
    INVALID,
    VALID
  ];

  /**
   * The name of this cache state.
   */
  final String name;

  /**
   * The ordinal value of the cache state.
   */
  final int ordinal;

  const CacheState(this.name, this.ordinal);

  @override
  int get hashCode => ordinal;

  @override
  int compareTo(CacheState other) => ordinal - other.ordinal;

  @override
  String toString() => name;
}

/**
 * An object that represents a change to the analysis results associated with a
 * given source.
 */
abstract class ChangeNotice implements AnalysisErrorInfo {
  /**
   * The parsed, but maybe not resolved Dart AST that changed as a result of
   * the analysis, or `null` if the AST was not changed.
   */
  CompilationUnit get parsedDartUnit;

  /**
   * The fully resolved Dart AST that changed as a result of the analysis, or
   * `null` if the AST was not changed.
   */
  CompilationUnit get resolvedDartUnit;

  /**
   * Return the source for which the result is being reported.
   */
  Source get source;
}

/**
 * An implementation of a [ChangeNotice].
 */
class ChangeNoticeImpl implements ChangeNotice {
  /**
   * An empty list of change notices.
   */
  static const List<ChangeNoticeImpl> EMPTY_LIST = const <ChangeNoticeImpl>[];

  /**
   * The source for which the result is being reported.
   */
  @override
  final Source source;

  /**
   * The parsed, but maybe not resolved Dart AST that changed as a result of
   * the analysis, or `null` if the AST was not changed.
   */
  @override
  CompilationUnit parsedDartUnit;

  /**
   * The fully resolved Dart AST that changed as a result of the analysis, or
   * `null` if the AST was not changed.
   */
  @override
  CompilationUnit resolvedDartUnit;

  /**
   * The errors that changed as a result of the analysis, or `null` if errors
   * were not changed.
   */
  List<AnalysisError> _errors;

  /**
   * The line information associated with the source, or `null` if errors were
   * not changed.
   */
  LineInfo _lineInfo;

  /**
   * Initialize a newly created notice associated with the given source.
   *
   * @param source the source for which the change is being reported
   */
  ChangeNoticeImpl(this.source);

  @override
  List<AnalysisError> get errors => _errors;

  @override
  LineInfo get lineInfo => _lineInfo;

  /**
   * Set the errors that changed as a result of the analysis to the given
   * [errors] and set the line information to the given [lineInfo].
   */
  void setErrors(List<AnalysisError> errors, LineInfo lineInfo) {
    this._errors = errors;
    this._lineInfo = lineInfo;
    if (lineInfo == null) {
      AnalysisEngine.instance.logger.logInformation("No line info: $source",
          new CaughtException(new AnalysisException(), null));
    }
  }

  @override
  String toString() => "Changes for ${source.fullName}";
}

/**
 * An indication of which sources have been added, changed, removed, or deleted.
 * In the case of a changed source, there are multiple ways of indicating the
 * nature of the change.
 *
 * No source should be added to the change set more than once, either with the
 * same or a different kind of change. It does not make sense, for example, for
 * a source to be both added and removed, and it is redundant for a source to be
 * marked as changed in its entirety and changed in some specific range.
 */
class ChangeSet {
  /**
   * A list containing the sources that have been added.
   */
  final List<Source> addedSources = new List<Source>();

  /**
   * A list containing the sources that have been changed.
   */
  final List<Source> changedSources = new List<Source>();

  /**
   * A table mapping the sources whose content has been changed to the current
   * content of those sources.
   */
  HashMap<Source, String> _changedContent = new HashMap<Source, String>();

  /**
   * A table mapping the sources whose content has been changed within a single
   * range to the current content of those sources and information about the
   * affected range.
   */
  final HashMap<Source, ChangeSet_ContentChange> changedRanges =
      new HashMap<Source, ChangeSet_ContentChange>();

  /**
   * A list containing the sources that have been removed.
   */
  final List<Source> removedSources = new List<Source>();

  /**
   * A list containing the source containers specifying additional sources that
   * have been removed.
   */
  final List<SourceContainer> removedContainers = new List<SourceContainer>();

  /**
   * Return a table mapping the sources whose content has been changed to the
   * current content of those sources.
   */
  Map<Source, String> get changedContents => _changedContent;

  /**
   * Return `true` if this change set does not contain any changes.
   */
  bool get isEmpty =>
      addedSources.isEmpty &&
      changedSources.isEmpty &&
      _changedContent.isEmpty &&
      changedRanges.isEmpty &&
      removedSources.isEmpty &&
      removedContainers.isEmpty;

  /**
   * Record that the specified [source] has been added and that its content is
   * the default contents of the source.
   */
  void addedSource(Source source) {
    addedSources.add(source);
  }

  /**
   * Record that the specified [source] has been changed and that its content is
   * the given [contents].
   */
  void changedContent(Source source, String contents) {
    _changedContent[source] = contents;
  }

  /**
   * Record that the specified [source] has been changed and that its content is
   * the given [contents]. The [offset] is the offset into the current contents.
   * The [oldLength] is the number of characters in the original contents that
   * were replaced. The [newLength] is the number of characters in the
   * replacement text.
   */
  void changedRange(Source source, String contents, int offset, int oldLength,
      int newLength) {
    changedRanges[source] =
        new ChangeSet_ContentChange(contents, offset, oldLength, newLength);
  }

  /**
   * Record that the specified [source] has been changed. If the content of the
   * source was previously overridden, this has no effect (the content remains
   * overridden). To cancel (or change) the override, use [changedContent]
   * instead.
   */
  void changedSource(Source source) {
    changedSources.add(source);
  }

  /**
   * Record that the specified source [container] has been removed.
   */
  void removedContainer(SourceContainer container) {
    if (container != null) {
      removedContainers.add(container);
    }
  }

  /**
   * Record that the specified [source] has been removed.
   */
  void removedSource(Source source) {
    if (source != null) {
      removedSources.add(source);
    }
  }

  @override
  String toString() {
    StringBuffer buffer = new StringBuffer();
    bool needsSeparator =
        _appendSources(buffer, addedSources, false, "addedSources");
    needsSeparator = _appendSources(
        buffer, changedSources, needsSeparator, "changedSources");
    needsSeparator = _appendSources2(
        buffer, _changedContent, needsSeparator, "changedContent");
    needsSeparator =
        _appendSources2(buffer, changedRanges, needsSeparator, "changedRanges");
    needsSeparator = _appendSources(
        buffer, removedSources, needsSeparator, "removedSources");
    int count = removedContainers.length;
    if (count > 0) {
      if (removedSources.isEmpty) {
        if (needsSeparator) {
          buffer.write("; ");
        }
        buffer.write("removed: from ");
        buffer.write(count);
        buffer.write(" containers");
      } else {
        buffer.write(", and more from ");
        buffer.write(count);
        buffer.write(" containers");
      }
    }
    return buffer.toString();
  }

  /**
   * Append the given [sources] to the given [buffer], prefixed with the given
   * [label] and a separator if [needsSeparator] is `true`. Return `true` if
   * future lists of sources will need a separator.
   */
  bool _appendSources(StringBuffer buffer, List<Source> sources,
      bool needsSeparator, String label) {
    if (sources.isEmpty) {
      return needsSeparator;
    }
    if (needsSeparator) {
      buffer.write("; ");
    }
    buffer.write(label);
    String prefix = " ";
    for (Source source in sources) {
      buffer.write(prefix);
      buffer.write(source.fullName);
      prefix = ", ";
    }
    return true;
  }

  /**
   * Append the given [sources] to the given [builder], prefixed with the given
   * [label] and a separator if [needsSeparator] is `true`. Return `true` if
   * future lists of sources will need a separator.
   */
  bool _appendSources2(StringBuffer buffer, HashMap<Source, dynamic> sources,
      bool needsSeparator, String label) {
    if (sources.isEmpty) {
      return needsSeparator;
    }
    if (needsSeparator) {
      buffer.write("; ");
    }
    buffer.write(label);
    String prefix = " ";
    for (Source source in sources.keys.toSet()) {
      buffer.write(prefix);
      buffer.write(source.fullName);
      prefix = ", ";
    }
    return true;
  }
}

/**
 * A change to the content of a source.
 */
class ChangeSet_ContentChange {
  /**
   * The new contents of the source.
   */
  final String contents;

  /**
   * The offset into the current contents.
   */
  final int offset;

  /**
   * The number of characters in the original contents that were replaced
   */
  final int oldLength;

  /**
   * The number of characters in the replacement text.
   */
  final int newLength;

  /**
   * Initialize a newly created change object to represent a change to the
   * content of a source. The [contents] is the new contents of the source. The
   * [offset] is the offset into the current contents. The [oldLength] is the
   * number of characters in the original contents that were replaced. The
   * [newLength] is the number of characters in the replacement text.
   */
  ChangeSet_ContentChange(
      this.contents, this.offset, this.oldLength, this.newLength);
}

/**
 * [ComputedResult] describes a value computed for a [ResultDescriptor].
 */
@deprecated
class ComputedResult<V> {
  /**
   * The context in which the value was computed.
   */
  final AnalysisContext context;

  /**
   * The descriptor of the result which was computed.
   */
  final ResultDescriptor<V> descriptor;

  /**
   * The target for which the result was computed.
   */
  final AnalysisTarget target;

  /**
   * The computed value.
   */
  final V value;

  ComputedResult(this.context, this.descriptor, this.target, this.value);

  @override
  String toString() => 'Computed $descriptor of $target in $context';
}

/**
 * An event indicating when a source either starts or stops being implicitly
 * analyzed.
 */
class ImplicitAnalysisEvent {
  /**
   * The source whose status has changed.
   */
  final Source source;

  /**
   * A flag indicating whether the source is now being analyzed.
   */
  final bool isAnalyzed;

  /**
   * Initialize a newly created event to indicate that the given [source] has
   * changed it status to match the [isAnalyzed] flag.
   */
  ImplicitAnalysisEvent(this.source, this.isAnalyzed);

  @override
  String toString() =>
      '${isAnalyzed ? '' : 'not '}analyzing ${source.fullName}';
}

/**
 * Additional behavior for an analysis context that is required by internal
 * users of the context.
 */
abstract class InternalAnalysisContext implements AnalysisContext {
  /**
   * The result provider for [aboutToComputeResult].
   */
  ResultProvider resultProvider;

  /**
   * A table mapping the sources known to the context to the information known
   * about the source.
   */
  AnalysisCache get analysisCache;

  /**
   * The cache consistency validator for this context.
   */
  CacheConsistencyValidator get cacheConsistencyValidator;

  /**
   * Allow the client to supply its own content cache.  This will take the
   * place of the content cache created by default, allowing clients to share
   * the content cache between contexts.
   */
  set contentCache(ContentCache value);

  /**
   * Get the [EmbedderYamlLocator] for this context.
   */
  @deprecated
  EmbedderYamlLocator get embedderYamlLocator;

  /**
   * Return a list of the explicit targets being analyzed by this context.
   */
  List<AnalysisTarget> get explicitTargets;

  /**
   * Return `true` if the context is active, i.e. is being analyzed now.
   */
  bool get isActive;

  /**
   * Specify whether the context is active, i.e. is being analyzed now.
   */
  set isActive(bool value);

  /**
   * Return the [StreamController] reporting [InvalidatedResult]s for everything
   * in this context's cache.
   */
  ReentrantSynchronousStream<InvalidatedResult> get onResultInvalidated;

  /**
   * Return a list containing all of the sources that have been marked as
   * priority sources. Clients must not modify the returned list.
   */
  List<Source> get prioritySources;

  /**
   * Return a list of the priority targets being analyzed by this context.
   */
  List<AnalysisTarget> get priorityTargets;

  /**
   * The partition that contains analysis results that are not shared with other
   * contexts.
   */
  CachePartition get privateAnalysisCachePartition;

  /**
   * Sets the [TypeProvider] for this context.
   */
  void set typeProvider(TypeProvider typeProvider);

  /**
   * A list of all [WorkManager]s used by this context.
   */
  List<WorkManager> get workManagers;

  /**
   * This method is invoked when the state of the [result] of the [entry] is
   * [CacheState.INVALID], so it is about to be computed.
   *
   * If the context knows how to provide the value, it sets the value into
   * the [entry] with all required dependencies, and returns `true`.
   *
   * Otherwise, it returns `false` to indicate that the result should be
   * computed as usually.
   */
  bool aboutToComputeResult(CacheEntry entry, ResultDescriptor result);

  /**
   * Return a list containing the sources of the libraries that are exported by
   * the library with the given [source]. The list will be empty if the given
   * source is invalid, if the given source does not represent a library, or if
   * the library does not export any other libraries.
   *
   * Throws an [AnalysisException] if the exported libraries could not be
   * computed.
   */
  List<Source> computeExportedLibraries(Source source);

  /**
   * Return a list containing the sources of the libraries that are imported by
   * the library with the given [source]. The list will be empty if the given
   * source is invalid, if the given source does not represent a library, or if
   * the library does not import any other libraries.
   *
   * Throws an [AnalysisException] if the imported libraries could not be
   * computed.
   */
  List<Source> computeImportedLibraries(Source source);

  /**
   * Return all the resolved [CompilationUnit]s for the given [source] if not
   * flushed, otherwise return `null` and ensures that the [CompilationUnit]s
   * will be eventually returned to the client from [performAnalysisTask].
   */
  List<CompilationUnit> ensureResolvedDartUnits(Source source);

  /**
   * Return the cache entry associated with the given [target].
   */
  CacheEntry getCacheEntry(AnalysisTarget target);

  /**
   * Return context that owns the given [source].
   */
  InternalAnalysisContext getContextFor(Source source);

  /**
   * Return a change notice for the given [source], creating one if one does not
   * already exist.
   */
  ChangeNoticeImpl getNotice(Source source);

  /**
   * Return a namespace containing mappings for all of the public names defined
   * by the given [library].
   */
  Namespace getPublicNamespace(LibraryElement library);

  /**
   * Respond to a change which has been made to the given [source] file.
   * [originalContents] is the former contents of the file, and [newContents]
   * is the updated contents.  If [notify] is true, a source changed event is
   * triggered.
   *
   * Normally it should not be necessary for clients to call this function,
   * since it will be automatically invoked in response to a call to
   * [applyChanges] or [setContents].  However, if this analysis context is
   * sharing its content cache with other contexts, then the client must
   * manually update the content cache and call this function for each context.
   *
   * Return `true` if the change was significant to this context (i.e. [source]
   * is either implicitly or explicitly analyzed by this context, and a change
   * actually occurred).
   */
  bool handleContentsChanged(
      Source source, String originalContents, String newContents, bool notify);

  /**
   * Given an [elementMap] mapping the source for the libraries represented by
   * the corresponding elements to the elements representing the libraries,
   * record those mappings.
   */
  void recordLibraryElements(Map<Source, LibraryElement> elementMap);

  /**
   * Return `true` if errors should be produced for the given [source].
   */
  bool shouldErrorsBeAnalyzed(Source source);

  /**
   * For testing only: flush all representations of the AST (both resolved and
   * unresolved) for the given [source] out of the cache.
   */
  void test_flushAstStructures(Source source);

  /**
   * Visit all entries of the content cache.
   */
  void visitContentCache(ContentCacheVisitor visitor);
}

/**
 * An object that can be used to receive information about errors within the
 * analysis engine. Implementations usually write this information to a file,
 * but can also record the information for later use (such as during testing) or
 * even ignore the information.
 */
abstract class Logger {
  /**
   * A logger that ignores all logging.
   */
  static final Logger NULL = new NullLogger();

  /**
   * Log the given message as an error. The [message] is expected to be an
   * explanation of why the error occurred or what it means. The [exception] is
   * expected to be the reason for the error. At least one argument must be
   * provided.
   */
  void logError(String message, [CaughtException exception]);

  /**
   * Log the given informational message. The [message] is expected to be an
   * explanation of why the error occurred or what it means. The [exception] is
   * expected to be the reason for the error.
   */
  void logInformation(String message, [CaughtException exception]);
}

/**
 * An implementation of [Logger] that does nothing.
 */
class NullLogger implements Logger {
  @override
  void logError(String message, [CaughtException exception]) {}

  @override
  void logInformation(String message, [CaughtException exception]) {}
}

/**
 * An exception created when an analysis attempt fails because a source was
 * deleted between the time the analysis started and the time the results of the
 * analysis were ready to be recorded.
 */
class ObsoleteSourceAnalysisException extends AnalysisException {
  /**
   * The source that was removed while it was being analyzed.
   */
  Source _source;

  /**
   * Initialize a newly created exception to represent the removal of the given
   * [source].
   */
  ObsoleteSourceAnalysisException(Source source)
      : super(
            "The source '${source.fullName}' was removed while it was being analyzed") {
    this._source = source;
  }

  /**
   * Return the source that was removed while it was being analyzed.
   */
  Source get source => _source;
}

/**
 * Container with global [AnalysisContext] performance statistics.
 */
class PerformanceStatistics {
  /**
   * The [PerformanceTag] for `package:analyzer`.
   */
  static PerformanceTag analyzer = new PerformanceTag('analyzer');

  /**
   * The [PerformanceTag] for time spent in reading files.
   */
  static PerformanceTag io = analyzer.createChild('io');

  /**
   * The [PerformanceTag] for general phases of analysis.
   */
  static PerformanceTag analysis = analyzer.createChild('analysis');

  /**
   * The [PerformanceTag] for time spent in scanning.
   */
  static PerformanceTag scan = analyzer.createChild('scan');

  /**
   * The [PerformanceTag] for time spent in parsing.
   */
  static PerformanceTag parse = analyzer.createChild('parse');

  /**
   * The [PerformanceTag] for time spent in resolving.
   */
  static PerformanceTag resolve = new PerformanceTag('resolve');

  /**
   * The [PerformanceTag] for time spent in error verifier.
   */
  static PerformanceTag errors = analysis.createChild('errors');

  /**
   * The [PerformanceTag] for time spent in hints generator.
   */
  static PerformanceTag hints = analysis.createChild('hints');

  /**
   * The [PerformanceTag] for time spent in linting.
   */
  static PerformanceTag lints = analysis.createChild('lints');

  /**
   * The [PerformanceTag] for time spent computing cycles.
   */
  static PerformanceTag cycles = new PerformanceTag('cycles');

  /**
   * The [PerformanceTag] for time spent in summaries support.
   */
  static PerformanceTag summary = analyzer.createChild('summary');

  /**
   * Statistics about cache consistency validation.
   */
  static final CacheConsistencyValidationStatistics
      cacheConsistencyValidationStatistics =
      new CacheConsistencyValidationStatistics();
}

/**
 * An visitor that removes any resolution information from an AST structure when
 * used to visit that structure.
 */
class ResolutionEraser extends GeneralizingAstVisitor<Object> {
  /**
   * A flag indicating whether the elements associated with declarations should
   * be erased.
   */
  bool eraseDeclarations = true;

  @override
  Object visitAssignmentExpression(AssignmentExpression node) {
    node.staticElement = null;
    node.propagatedElement = null;
    return super.visitAssignmentExpression(node);
  }

  @override
  Object visitBinaryExpression(BinaryExpression node) {
    node.staticElement = null;
    node.propagatedElement = null;
    return super.visitBinaryExpression(node);
  }

  @override
  Object visitBreakStatement(BreakStatement node) {
    node.target = null;
    return super.visitBreakStatement(node);
  }

  @override
  Object visitCompilationUnit(CompilationUnit node) {
    if (eraseDeclarations) {
      node.element = null;
    }
    return super.visitCompilationUnit(node);
  }

  @override
  Object visitConstructorDeclaration(ConstructorDeclaration node) {
    if (eraseDeclarations) {
      node.element = null;
    }
    return super.visitConstructorDeclaration(node);
  }

  @override
  Object visitConstructorName(ConstructorName node) {
    node.staticElement = null;
    return super.visitConstructorName(node);
  }

  @override
  Object visitContinueStatement(ContinueStatement node) {
    node.target = null;
    return super.visitContinueStatement(node);
  }

  @override
  Object visitDirective(Directive node) {
    if (eraseDeclarations) {
      node.element = null;
    }
    return super.visitDirective(node);
  }

  @override
  Object visitExpression(Expression node) {
    node.staticType = null;
    node.propagatedType = null;
    return super.visitExpression(node);
  }

  @override
  Object visitFunctionExpression(FunctionExpression node) {
    if (eraseDeclarations) {
      node.element = null;
    }
    return super.visitFunctionExpression(node);
  }

  @override
  Object visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    node.staticElement = null;
    node.propagatedElement = null;
    return super.visitFunctionExpressionInvocation(node);
  }

  @override
  Object visitIndexExpression(IndexExpression node) {
    node.staticElement = null;
    node.propagatedElement = null;
    return super.visitIndexExpression(node);
  }

  @override
  Object visitInstanceCreationExpression(InstanceCreationExpression node) {
    node.staticElement = null;
    return super.visitInstanceCreationExpression(node);
  }

  @override
  Object visitPostfixExpression(PostfixExpression node) {
    node.staticElement = null;
    node.propagatedElement = null;
    return super.visitPostfixExpression(node);
  }

  @override
  Object visitPrefixExpression(PrefixExpression node) {
    node.staticElement = null;
    node.propagatedElement = null;
    return super.visitPrefixExpression(node);
  }

  @override
  Object visitRedirectingConstructorInvocation(
      RedirectingConstructorInvocation node) {
    node.staticElement = null;
    return super.visitRedirectingConstructorInvocation(node);
  }

  @override
  Object visitSimpleIdentifier(SimpleIdentifier node) {
    if (eraseDeclarations || !node.inDeclarationContext()) {
      node.staticElement = null;
    }
    node.propagatedElement = null;
    return super.visitSimpleIdentifier(node);
  }

  @override
  Object visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    node.staticElement = null;
    return super.visitSuperConstructorInvocation(node);
  }

  /**
   * Remove any resolution information from the given AST structure.
   */
  static void erase(AstNode node, {bool eraseDeclarations: true}) {
    ResolutionEraser eraser = new ResolutionEraser();
    eraser.eraseDeclarations = eraseDeclarations;
    node.accept(eraser);
  }
}

/**
 * [ResultChangedEvent] describes a change to an analysis result.
 */
class ResultChangedEvent<V> {
  /**
   * The context in which the result was changed.
   */
  final AnalysisContext context;

  /**
   * The target for which the result was changed.
   */
  final AnalysisTarget target;

  /**
   * The descriptor of the result which was changed.
   */
  final ResultDescriptor<V> descriptor;

  /**
   * If the result [wasComputed], the new value of the result. If the result
   * [wasInvalidated], the value of before it was invalidated, may be the
   * default value if the result was flushed.
   */
  final V value;

  /**
   * Is `true` if the result was computed, or `false` is is was invalidated.
   */
  final bool _wasComputed;

  ResultChangedEvent(this.context, this.target, this.descriptor, this.value,
      this._wasComputed);

  /**
   * Returns `true` if the result was computed.
   */
  bool get wasComputed => _wasComputed;

  /**
   * Returns `true` if the result was invalidated.
   */
  bool get wasInvalidated => !_wasComputed;

  @override
  String toString() {
    String operation = _wasComputed ? 'Computed' : 'Invalidated';
    return '$operation $descriptor of $target in $context';
  }
}

/**
 * [SourcesChangedEvent] indicates which sources have been added, removed,
 * or whose contents have changed.
 */
class SourcesChangedEvent {
  /**
   * The internal representation of what has changed. Clients should not access
   * this field directly.
   */
  final ChangeSet _changeSet;

  /**
   * Construct an instance representing the given changes.
   */
  SourcesChangedEvent(ChangeSet changeSet) : _changeSet = changeSet;

  /**
   * Construct an instance representing a source content change.
   */
  factory SourcesChangedEvent.changedContent(Source source, String contents) {
    ChangeSet changeSet = new ChangeSet();
    changeSet.changedContent(source, contents);
    return new SourcesChangedEvent(changeSet);
  }

  /**
   * Construct an instance representing a source content change.
   */
  factory SourcesChangedEvent.changedRange(Source source, String contents,
      int offset, int oldLength, int newLength) {
    ChangeSet changeSet = new ChangeSet();
    changeSet.changedRange(source, contents, offset, oldLength, newLength);
    return new SourcesChangedEvent(changeSet);
  }

  /**
   * Return the collection of sources for which content has changed.
   */
  Iterable<Source> get changedSources {
    List<Source> changedSources = new List.from(_changeSet.changedSources);
    changedSources.addAll(_changeSet.changedContents.keys);
    changedSources.addAll(_changeSet.changedRanges.keys);
    return changedSources;
  }

  /**
   * Return `true` if any sources were added.
   */
  bool get wereSourcesAdded => _changeSet.addedSources.length > 0;

  /**
   * Return `true` if any sources were removed or deleted.
   */
  bool get wereSourcesRemoved =>
      _changeSet.removedSources.length > 0 ||
      _changeSet.removedContainers.length > 0;
}
