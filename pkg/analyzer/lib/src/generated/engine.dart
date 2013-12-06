// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library engine;

import 'java_core.dart';
import 'java_engine.dart';
import 'utilities_collection.dart';
import 'utilities_general.dart';
import 'instrumentation.dart';
import 'error.dart';
import 'source.dart';
import 'scanner.dart' show Token, Scanner, CharSequenceReader, CharacterReader, IncrementalScanner;
import 'ast.dart';
import 'parser.dart' show Parser, IncrementalParser;
import 'sdk.dart' show DartSdk;
import 'element.dart';
import 'resolver.dart';
import 'html.dart' show XmlTagNode, XmlAttributeNode, RecursiveXmlVisitor, HtmlScanner, HtmlScanResult, HtmlParser, HtmlParseResult, HtmlScriptTagNode, HtmlUnit;

/**
 * The unique instance of the class `AnalysisEngine` serves as the entry point for the
 * functionality provided by the analysis engine.
 *
 * @coverage dart.engine
 */
class AnalysisEngine {
  /**
   * The suffix used for Dart source files.
   */
  static String SUFFIX_DART = "dart";

  /**
   * The short suffix used for HTML files.
   */
  static String SUFFIX_HTM = "htm";

  /**
   * The long suffix used for HTML files.
   */
  static String SUFFIX_HTML = "html";

  /**
   * The unique instance of this class.
   */
  static final AnalysisEngine instance = new AnalysisEngine();

  /**
   * Return `true` if the given file name is assumed to contain Dart source code.
   *
   * @param fileName the name of the file being tested
   * @return `true` if the given file name is assumed to contain Dart source code
   */
  static bool isDartFileName(String fileName) {
    if (fileName == null) {
      return false;
    }
    return javaStringEqualsIgnoreCase(FileNameUtilities.getExtension(fileName), SUFFIX_DART);
  }

  /**
   * Return `true` if the given file name is assumed to contain HTML.
   *
   * @param fileName the name of the file being tested
   * @return `true` if the given file name is assumed to contain HTML
   */
  static bool isHtmlFileName(String fileName) {
    if (fileName == null) {
      return false;
    }
    String extension = FileNameUtilities.getExtension(fileName);
    return javaStringEqualsIgnoreCase(extension, SUFFIX_HTML) || javaStringEqualsIgnoreCase(extension, SUFFIX_HTM);
  }

  /**
   * The logger that should receive information about errors within the analysis engine.
   */
  Logger _logger = Logger.NULL;

  /**
   * Create a new context in which analysis can be performed.
   *
   * @return the analysis context that was created
   */
  AnalysisContext createAnalysisContext() {
    if (Instrumentation.isNullLogger) {
      return new DelegatingAnalysisContextImpl();
    }
    return new InstrumentedAnalysisContextImpl.con1(new DelegatingAnalysisContextImpl());
  }

  /**
   * Return the logger that should receive information about errors within the analysis engine.
   *
   * @return the logger that should receive information about errors within the analysis engine
   */
  Logger get logger => _logger;

  /**
   * Set the logger that should receive information about errors within the analysis engine to the
   * given logger.
   *
   * @param logger the logger that should receive information about errors within the analysis
   *          engine
   */
  void set logger(Logger logger) {
    this._logger = logger == null ? Logger.NULL : logger;
  }
}

/**
 * Container with statistics about the [AnalysisContext].
 */
abstract class AnalysisContentStatistics {
  /**
   * Return the exceptions that caused some entries to have a state of [CacheState#ERROR].
   *
   * @return the exceptions that caused some entries to have a state of [CacheState#ERROR]
   */
  List<AnalysisException> get exceptions;

  /**
   * Return the statistics for each kind of cached data.
   *
   * @return the statistics for each kind of cached data
   */
  List<AnalysisContentStatistics_CacheRow> get cacheRows;
}

/**
 * Information about single item in the cache.
 */
abstract class AnalysisContentStatistics_CacheRow {
  int get errorCount;

  int get flushedCount;

  int get inProcessCount;

  int get invalidCount;

  String get name;

  int get validCount;
}

/**
 * The interface `AnalysisContext` defines the behavior of objects that represent a context in
 * which a single analysis can be performed and incrementally maintained. The context includes such
 * information as the version of the SDK being analyzed against as well as the package-root used to
 * resolve 'package:' URI's. (Both of which are known indirectly through the [SourceFactory
 ].)
 *
 * An analysis context also represents the state of the analysis, which includes knowing which
 * sources have been included in the analysis (either directly or indirectly) and the results of the
 * analysis. Sources must be added and removed from the context using the method
 * [applyChanges], which is also used to notify the context when sources have been
 * modified and, consequently, previously known results might have been invalidated.
 *
 * There are two ways to access the results of the analysis. The most common is to use one of the
 * 'get' methods to access the results. The 'get' methods have the advantage that they will always
 * return quickly, but have the disadvantage that if the results are not currently available they
 * will return either nothing or in some cases an incomplete result. The second way to access
 * results is by using one of the 'compute' methods. The 'compute' methods will always attempt to
 * compute the requested results but might block the caller for a significant period of time.
 *
 * When results have been invalidated, have never been computed (as is the case for newly added
 * sources), or have been removed from the cache, they are <b>not</b> automatically recreated. They
 * will only be recreated if one of the 'compute' methods is invoked.
 *
 * However, this is not always acceptable. Some clients need to keep the analysis results
 * up-to-date. For such clients there is a mechanism that allows them to incrementally perform
 * needed analysis and get notified of the consequent changes to the analysis results. This
 * mechanism is realized by the method [performAnalysisTask].
 *
 * Analysis engine allows for having more than one context. This can be used, for example, to
 * perform one analysis based on the state of files on disk and a separate analysis based on the
 * state of those files in open editors. It can also be used to perform an analysis based on a
 * proposed future state, such as the state after a refactoring.
 */
abstract class AnalysisContext {
  /**
   * Apply the changes specified by the given change set to this context. Any analysis results that
   * have been invalidated by these changes will be removed.
   *
   * @param changeSet a description of the changes that are to be applied
   */
  void applyChanges(ChangeSet changeSet);

  /**
   * Return the documentation comment for the given element as it appears in the original source
   * (complete with the beginning and ending delimiters), or `null` if the element does not
   * have a documentation comment associated with it. This can be a long-running operation if the
   * information needed to access the comment is not cached.
   *
   * @param element the element whose documentation comment is to be returned
   * @return the element's documentation comment
   * @throws AnalysisException if the documentation comment could not be determined because the
   *           analysis could not be performed
   */
  String computeDocumentationComment(Element element);

  /**
   * Return an array containing all of the errors associated with the given source. If the errors
   * are not already known then the source will be analyzed in order to determine the errors
   * associated with it.
   *
   * @param source the source whose errors are to be returned
   * @return all of the errors associated with the given source
   * @throws AnalysisException if the errors could not be determined because the analysis could not
   *           be performed
   * @see #getErrors(Source)
   */
  List<AnalysisError> computeErrors(Source source);

  /**
   * Return the element model corresponding to the HTML file defined by the given source. If the
   * element model does not yet exist it will be created. The process of creating an element model
   * for an HTML file can long-running, depending on the size of the file and the number of
   * libraries that are defined in it (via script tags) that also need to have a model built for
   * them.
   *
   * @param source the source defining the HTML file whose element model is to be returned
   * @return the element model corresponding to the HTML file defined by the given source
   * @throws AnalysisException if the element model could not be determined because the analysis
   *           could not be performed
   * @see #getHtmlElement(Source)
   */
  HtmlElement computeHtmlElement(Source source);

  /**
   * Return the kind of the given source, computing it's kind if it is not already known. Return
   * [SourceKind#UNKNOWN] if the source is not contained in this context.
   *
   * @param source the source whose kind is to be returned
   * @return the kind of the given source
   * @see #getKindOf(Source)
   */
  SourceKind computeKindOf(Source source);

  /**
   * Return the element model corresponding to the library defined by the given source. If the
   * element model does not yet exist it will be created. The process of creating an element model
   * for a library can long-running, depending on the size of the library and the number of
   * libraries that are imported into it that also need to have a model built for them.
   *
   * @param source the source defining the library whose element model is to be returned
   * @return the element model corresponding to the library defined by the given source
   * @throws AnalysisException if the element model could not be determined because the analysis
   *           could not be performed
   * @see #getLibraryElement(Source)
   */
  LibraryElement computeLibraryElement(Source source);

  /**
   * Return the line information for the given source, or `null` if the source is not of a
   * recognized kind (neither a Dart nor HTML file). If the line information was not previously
   * known it will be created. The line information is used to map offsets from the beginning of the
   * source to line and column pairs.
   *
   * @param source the source whose line information is to be returned
   * @return the line information for the given source
   * @throws AnalysisException if the line information could not be determined because the analysis
   *           could not be performed
   * @see #getLineInfo(Source)
   */
  LineInfo computeLineInfo(Source source);

  /**
   * Create a new context in which analysis can be performed. Any sources in the specified container
   * will be removed from this context and added to the newly created context.
   *
   * @param container the container containing sources that should be removed from this context and
   *          added to the returned context
   * @return the analysis context that was created
   */
  AnalysisContext extractContext(SourceContainer container);

  /**
   * Return the set of analysis options controlling the behavior of this context. Clients should not
   * modify the returned set of options. The options should only be set by invoking the method
   * [setAnalysisOptions].
   *
   * @return the set of analysis options controlling the behavior of this context
   */
  AnalysisOptions get analysisOptions;

  /**
   * Return the element referenced by the given location, or `null` if the element is not
   * immediately available or if there is no element with the given location. The latter condition
   * can occur, for example, if the location describes an element from a different context or if the
   * element has been removed from this context as a result of some change since it was originally
   * obtained.
   *
   * @param location the reference describing the element to be returned
   * @return the element referenced by the given location
   */
  Element getElement(ElementLocation location);

  /**
   * Return an analysis error info containing the array of all of the errors and the line info
   * associated with the given source. The array of errors will be empty if the source is not known
   * to this context or if there are no errors in the source. The errors contained in the array can
   * be incomplete.
   *
   * @param source the source whose errors are to be returned
   * @return all of the errors associated with the given source and the line info
   * @see #computeErrors(Source)
   */
  AnalysisErrorInfo getErrors(Source source);

  /**
   * Return the element model corresponding to the HTML file defined by the given source, or
   * `null` if the source does not represent an HTML file, the element representing the file
   * has not yet been created, or the analysis of the HTML file failed for some reason.
   *
   * @param source the source defining the HTML file whose element model is to be returned
   * @return the element model corresponding to the HTML file defined by the given source
   * @see #computeHtmlElement(Source)
   */
  HtmlElement getHtmlElement(Source source);

  /**
   * Return the sources for the HTML files that reference the given compilation unit. If the source
   * does not represent a Dart source or is not known to this context, the returned array will be
   * empty. The contents of the array can be incomplete.
   *
   * @param source the source referenced by the returned HTML files
   * @return the sources for the HTML files that reference the given compilation unit
   */
  List<Source> getHtmlFilesReferencing(Source source);

  /**
   * Return an array containing all of the sources known to this context that represent HTML files.
   * The contents of the array can be incomplete.
   *
   * @return the sources known to this context that represent HTML files
   */
  List<Source> get htmlSources;

  /**
   * Return the kind of the given source, or `null` if the kind is not known to this context.
   *
   * @param source the source whose kind is to be returned
   * @return the kind of the given source
   * @see #computeKindOf(Source)
   */
  SourceKind getKindOf(Source source);

  /**
   * Return an array containing all of the sources known to this context that represent the defining
   * compilation unit of a library that can be run within a browser. The sources that are returned
   * represent libraries that have a 'main' method and are either referenced by an HTML file or
   * import, directly or indirectly, a client-only library. The contents of the array can be
   * incomplete.
   *
   * @return the sources known to this context that represent the defining compilation unit of a
   *         library that can be run within a browser
   */
  List<Source> get launchableClientLibrarySources;

  /**
   * Return an array containing all of the sources known to this context that represent the defining
   * compilation unit of a library that can be run outside of a browser. The contents of the array
   * can be incomplete.
   *
   * @return the sources known to this context that represent the defining compilation unit of a
   *         library that can be run outside of a browser
   */
  List<Source> get launchableServerLibrarySources;

  /**
   * Return the sources for the defining compilation units of any libraries of which the given
   * source is a part. The array will normally contain a single library because most Dart sources
   * are only included in a single library, but it is possible to have a part that is contained in
   * multiple identically named libraries. If the source represents the defining compilation unit of
   * a library, then the returned array will contain the given source as its only element. If the
   * source does not represent a Dart source or is not known to this context, the returned array
   * will be empty. The contents of the array can be incomplete.
   *
   * @param source the source contained in the returned libraries
   * @return the sources for the libraries containing the given source
   */
  List<Source> getLibrariesContaining(Source source);

  /**
   * Return the sources for the defining compilation units of any libraries that depend on the given
   * library. One library depends on another if it either imports or exports that library.
   *
   * @param librarySource the source for the defining compilation unit of the library being depended
   *          on
   * @return the sources for the libraries that depend on the given library
   */
  List<Source> getLibrariesDependingOn(Source librarySource);

  /**
   * Return the element model corresponding to the library defined by the given source, or
   * `null` if the element model does not currently exist or if the library cannot be analyzed
   * for some reason.
   *
   * @param source the source defining the library whose element model is to be returned
   * @return the element model corresponding to the library defined by the given source
   */
  LibraryElement getLibraryElement(Source source);

  /**
   * Return an array containing all of the sources known to this context that represent the defining
   * compilation unit of a library. The contents of the array can be incomplete.
   *
   * @return the sources known to this context that represent the defining compilation unit of a
   *         library
   */
  List<Source> get librarySources;

  /**
   * Return the line information for the given source, or `null` if the line information is
   * not known. The line information is used to map offsets from the beginning of the source to line
   * and column pairs.
   *
   * @param source the source whose line information is to be returned
   * @return the line information for the given source
   * @see #computeLineInfo(Source)
   */
  LineInfo getLineInfo(Source source);

  /**
   * Return an array containing all of the sources known to this context and their resolution state
   * is not valid or flush. So, these sources are not safe to update during refactoring, because we
   * may be don't know all the references in them.
   *
   * @return the sources known to this context and are not safe for refactoring
   */
  List<Source> get refactoringUnsafeSources;

  /**
   * Return a fully resolved AST for a single compilation unit within the given library, or
   * `null` if the resolved AST is not already computed.
   *
   * @param unitSource the source of the compilation unit
   * @param library the library containing the compilation unit
   * @return a fully resolved AST for the compilation unit
   * @see #resolveCompilationUnit(Source, LibraryElement)
   */
  CompilationUnit getResolvedCompilationUnit(Source unitSource, LibraryElement library);

  /**
   * Return a fully resolved AST for a single compilation unit within the given library, or
   * `null` if the resolved AST is not already computed.
   *
   * @param unitSource the source of the compilation unit
   * @param librarySource the source of the defining compilation unit of the library containing the
   *          compilation unit
   * @return a fully resolved AST for the compilation unit
   * @see #resolveCompilationUnit(Source, Source)
   */
  CompilationUnit getResolvedCompilationUnit2(Source unitSource, Source librarySource);

  /**
   * Return the source factory used to create the sources that can be analyzed in this context.
   *
   * @return the source factory used to create the sources that can be analyzed in this context
   */
  SourceFactory get sourceFactory;

  /**
   * Return `true` if the given source is known to be the defining compilation unit of a
   * library that can be run on a client (references 'dart:html', either directly or indirectly).
   *
   * <b>Note:</b> In addition to the expected case of returning `false` if the source is known
   * to be a library that cannot be run on a client, this method will also return `false` if
   * the source is not known to be a library or if we do not know whether it can be run on a client.
   *
   * @param librarySource the source being tested
   * @return `true` if the given source is known to be a library that can be run on a client
   */
  bool isClientLibrary(Source librarySource);

  /**
   * Return `true` if the given source is known to be the defining compilation unit of a
   * library that can be run on the server (does not reference 'dart:html', either directly or
   * indirectly).
   *
   * <b>Note:</b> In addition to the expected case of returning `false` if the source is known
   * to be a library that cannot be run on the server, this method will also return `false` if
   * the source is not known to be a library or if we do not know whether it can be run on the
   * server.
   *
   * @param librarySource the source being tested
   * @return `true` if the given source is known to be a library that can be run on the server
   */
  bool isServerLibrary(Source librarySource);

  /**
   * Add the sources contained in the specified context to this context's collection of sources.
   * This method is called when an existing context's pubspec has been removed, and the contained
   * sources should be reanalyzed as part of this context.
   *
   * @param context the context being merged
   */
  void mergeContext(AnalysisContext context);

  /**
   * Parse a single source to produce an AST structure. The resulting AST structure may or may not
   * be resolved, and may have a slightly different structure depending upon whether it is resolved.
   *
   * @param source the source to be parsed
   * @return the AST structure representing the content of the source
   * @throws AnalysisException if the analysis could not be performed
   */
  CompilationUnit parseCompilationUnit(Source source);

  /**
   * Parse a single HTML source to produce an AST structure. The resulting HTML AST structure may or
   * may not be resolved, and may have a slightly different structure depending upon whether it is
   * resolved.
   *
   * @param source the HTML source to be parsed
   * @return the parse result (not `null`)
   * @throws AnalysisException if the analysis could not be performed
   */
  HtmlUnit parseHtmlUnit(Source source);

  /**
   * Perform the next unit of work required to keep the analysis results up-to-date and return
   * information about the consequent changes to the analysis results. This method can be long
   * running.
   *
   * @return the results of performing the analysis
   */
  AnalysisResult performAnalysisTask();

  /**
   * Parse and resolve a single source within the given context to produce a fully resolved AST.
   *
   * @param unitSource the source to be parsed and resolved
   * @param library the library containing the source to be resolved
   * @return the result of resolving the AST structure representing the content of the source in the
   *         context of the given library
   * @throws AnalysisException if the analysis could not be performed
   * @see #getResolvedCompilationUnit(Source, LibraryElement)
   */
  CompilationUnit resolveCompilationUnit(Source unitSource, LibraryElement library);

  /**
   * Parse and resolve a single source within the given context to produce a fully resolved AST.
   * Return the resolved AST structure, or `null` if the source could not be either parsed or
   * resolved.
   *
   * @param unitSource the source to be parsed and resolved
   * @param librarySource the source of the defining compilation unit of the library containing the
   *          source to be resolved
   * @return the result of resolving the AST structure representing the content of the source in the
   *         context of the given library
   * @throws AnalysisException if the analysis could not be performed
   * @see #getResolvedCompilationUnit(Source, Source)
   */
  CompilationUnit resolveCompilationUnit2(Source unitSource, Source librarySource);

  /**
   * Parse and resolve a single source within the given context to produce a fully resolved AST.
   *
   * @param htmlSource the source to be parsed and resolved
   * @return the result of resolving the AST structure representing the content of the source
   * @throws AnalysisException if the analysis could not be performed
   */
  HtmlUnit resolveHtmlUnit(Source htmlSource);

  /**
   * Set the set of analysis options controlling the behavior of this context to the given options.
   * Clients can safely assume that all necessary analysis results have been invalidated.
   *
   * @param options the set of analysis options that will control the behavior of this context
   */
  void set analysisOptions(AnalysisOptions options);

  /**
   * Set the order in which sources will be analyzed by [performAnalysisTask] to match the
   * order of the sources in the given list. If a source that needs to be analyzed is not contained
   * in the list, then it will be treated as if it were at the end of the list. If the list is empty
   * (or `null`) then no sources will be given priority over other sources.
   *
   * Changes made to the list after this method returns will <b>not</b> be reflected in the priority
   * order.
   *
   * @param sources the sources to be given priority over other sources
   */
  void set analysisPriorityOrder(List<Source> sources);

  /**
   * Set the contents of the given source to the given contents and mark the source as having
   * changed. The additional offset and length information is used by the context to determine what
   * reanalysis is necessary.
   *
   * @param source the source whose contents are being overridden
   * @param contents the text to replace the range in the current contents
   * @param offset the offset into the current contents
   * @param oldLength the number of characters in the original contents that were replaced
   * @param newLength the number of characters in the replacement text
   */
  void setChangedContents(Source source, String contents, int offset, int oldLength, int newLength);

  /**
   * Set the contents of the given source to the given contents and mark the source as having
   * changed. This has the effect of overriding the default contents of the source. If the contents
   * are `null` the override is removed so that the default contents will be returned.
   *
   * @param source the source whose contents are being overridden
   * @param contents the new contents of the source
   */
  void setContents(Source source, String contents);

  /**
   * Set the source factory used to create the sources that can be analyzed in this context to the
   * given source factory. Clients can safely assume that all analysis results have been
   * invalidated.
   *
   * @param factory the source factory used to create the sources that can be analyzed in this
   *          context
   */
  void set sourceFactory(SourceFactory factory);

  /**
   * Given a collection of sources with content that has changed, return an [Iterable]
   * identifying the sources that need to be resolved.
   *
   * @param changedSources an array of sources (not `null`, contains no `null`s)
   * @return An iterable returning the sources to be resolved
   */
  Iterable<Source> sourcesToResolve(List<Source> changedSources);
}

/**
 * The interface `AnalysisErrorInfo` contains the analysis errors and line information for the
 * errors.
 */
abstract class AnalysisErrorInfo {
  /**
   * Return the errors that as a result of the analysis, or `null` if there were no errors.
   *
   * @return the errors as a result of the analysis
   */
  List<AnalysisError> get errors;

  /**
   * Return the line information associated with the errors, or `null` if there were no
   * errors.
   *
   * @return the line information associated with the errors
   */
  LineInfo get lineInfo;
}

/**
 * Instances of the class `AnalysisException` represent an exception that occurred during the
 * analysis of one or more sources.
 *
 * @coverage dart.engine
 */
class AnalysisException extends JavaException {
  /**
   * Initialize a newly created exception.
   */
  AnalysisException() : super();

  /**
   * Initialize a newly created exception to have the given message.
   *
   * @param message the message associated with the exception
   */
  AnalysisException.con1(String message) : super(message);

  /**
   * Initialize a newly created exception to have the given message and cause.
   *
   * @param message the message associated with the exception
   * @param cause the underlying exception that caused this exception
   */
  AnalysisException.con2(String message, Exception cause) : super(message, cause);

  /**
   * Initialize a newly created exception to have the given cause.
   *
   * @param cause the underlying exception that caused this exception
   */
  AnalysisException.con3(Exception cause) : super.withCause(cause);
}

/**
 * The interface `AnalysisOptions` defines the behavior of objects that provide access to a
 * set of analysis options used to control the behavior of an analysis context.
 */
abstract class AnalysisOptions {
  /**
   * Return `true` if analysis is to parse and analyze function bodies.
   *
   * @return `true` if analysis is to parse and analyzer function bodies
   */
  bool get analyzeFunctionBodies;

  /**
   * Return the maximum number of sources for which AST structures should be kept in the cache.
   *
   * @return the maximum number of sources for which AST structures should be kept in the cache
   */
  int get cacheSize;

  /**
   * Return `true` if analysis is to generate dart2js related hint results.
   *
   * @return `true` if analysis is to generate dart2js related hint results
   */
  bool get dart2jsHint;

  /**
   * Return `true` if analysis is to generate hint results (e.g. type inference based
   * information and pub best practices).
   *
   * @return `true` if analysis is to generate hint results
   */
  bool get hint;

  /**
   * Return `true` if incremental analysis should be used.
   *
   * @return `true` if incremental analysis should be used
   */
  bool get incremental;

  /**
   * Return `true` if analysis is to parse comments.
   *
   * @return `true` if analysis is to parse comments
   */
  bool get preserveComments;
}

/**
 * Instances of the class `AnalysisResult`
 */
class AnalysisResult {
  /**
   * The change notices associated with this result, or `null` if there were no changes and
   * there is no more work to be done.
   */
  List<ChangeNotice> changeNotices;

  /**
   * The number of milliseconds required to determine which task was to be performed.
   */
  int getTime = 0;

  /**
   * The name of the class of the task that was performed.
   */
  String taskClassName;

  /**
   * The number of milliseconds required to perform the task.
   */
  int performTime = 0;

  /**
   * Initialize a newly created analysis result to have the given values.
   *
   * @param notices the change notices associated with this result
   * @param getTime the number of milliseconds required to determine which task was to be performed
   * @param taskClassName the name of the class of the task that was performed
   * @param performTime the number of milliseconds required to perform the task
   */
  AnalysisResult(List<ChangeNotice> notices, int getTime, String taskClassName, int performTime) {
    this.changeNotices = notices;
    this.getTime = getTime;
    this.taskClassName = taskClassName;
    this.performTime = performTime;
  }
}

/**
 * The interface `ChangeNotice` defines the behavior of objects that represent a change to the
 * analysis results associated with a given source.
 *
 * @coverage dart.engine
 */
abstract class ChangeNotice implements AnalysisErrorInfo {
  /**
   * Return the fully resolved AST that changed as a result of the analysis, or `null` if the
   * AST was not changed.
   *
   * @return the fully resolved AST that changed as a result of the analysis
   */
  CompilationUnit get compilationUnit;

  /**
   * Return the source for which the result is being reported.
   *
   * @return the source for which the result is being reported
   */
  Source get source;
}

/**
 * Instances of the class `ChangeSet` indicate what sources have been added, changed, or
 * removed.
 *
 * @coverage dart.engine
 */
class ChangeSet {
  /**
   * A list containing the sources that have been added.
   */
  final List<Source> added3 = new List<Source>();

  /**
   * A list containing the sources that have been changed.
   */
  final List<Source> changed3 = new List<Source>();

  /**
   * A list containing the sources that have been removed.
   */
  final List<Source> removed3 = new List<Source>();

  /**
   * A list containing the source containers specifying additional sources that have been removed.
   */
  final List<SourceContainer> removedContainers = new List<SourceContainer>();

  /**
   * Record that the specified source has been added and that it's content is the default contents
   * of the source.
   *
   * @param source the source that was added
   */
  void added(Source source) {
    added3.add(source);
  }

  /**
   * Record that the specified source has been changed and that it's content is the default contents
   * of the source.
   *
   * @param source the source that was changed
   */
  void changed(Source source) {
    changed3.add(source);
  }

  /**
   * Return `true` if this change set does not contain any changes.
   *
   * @return `true` if this change set does not contain any changes
   */
  bool get isEmpty => added3.isEmpty && changed3.isEmpty && removed3.isEmpty && removedContainers.isEmpty;

  /**
   * Record that the specified source has been removed.
   *
   * @param source the source that was removed
   */
  void removed(Source source) {
    if (source != null) {
      removed3.add(source);
    }
  }

  /**
   * Record that the specified source container has been removed.
   *
   * @param container the source container that was removed
   */
  void removedContainer(SourceContainer container) {
    if (container != null) {
      removedContainers.add(container);
    }
  }

  String toString() {
    JavaStringBuilder builder = new JavaStringBuilder();
    bool needsSeparator = appendSources(builder, added3, false, "added");
    needsSeparator = appendSources(builder, changed3, needsSeparator, "changed");
    appendSources(builder, removed3, needsSeparator, "removed");
    int count = removedContainers.length;
    if (count > 0) {
      if (removed3.isEmpty) {
        if (needsSeparator) {
          builder.append("; ");
        }
        builder.append("removed: from ");
        builder.append(count);
        builder.append(" containers");
      } else {
        builder.append(", and more from ");
        builder.append(count);
        builder.append(" containers");
      }
    }
    return builder.toString();
  }

  /**
   * Append the given sources to the given builder, prefixed with the given label and possibly a
   * separator.
   *
   * @param builder the builder to which the sources are to be appended
   * @param sources the sources to be appended
   * @param needsSeparator `true` if a separator is needed before the label
   * @param label the label used to prefix the sources
   * @return `true` if future lists of sources will need a separator
   */
  bool appendSources(JavaStringBuilder builder, List<Source> sources, bool needsSeparator, String label) {
    if (sources.isEmpty) {
      return needsSeparator;
    }
    if (needsSeparator) {
      builder.append("; ");
    }
    builder.append(label);
    String prefix = " ";
    for (Source source in sources) {
      builder.append(prefix);
      builder.append(source.fullName);
      prefix = ", ";
    }
    return true;
  }
}

/**
 * Instances of the class `AnalysisCache` implement an LRU cache of information related to
 * analysis.
 */
class AnalysisCache {
  /**
   * A table mapping the sources known to the context to the information known about the source.
   */
  Map<Source, SourceEntry> _sourceMap = new Map<Source, SourceEntry>();

  /**
   * The maximum number of sources for which AST structures should be kept in the cache.
   */
  int _maxCacheSize = 0;

  /**
   * The policy used to determine which pieces of data to remove from the cache.
   */
  CacheRetentionPolicy _retentionPolicy;

  /**
   * A list containing the most recently accessed sources with the most recently used at the end of
   * the list. When more sources are added than the maximum allowed then the least recently used
   * source will be removed and will have it's cached AST structure flushed.
   */
  List<Source> _recentlyUsed;

  /**
   * Initialize a newly created cache to maintain at most the given number of AST structures in the
   * cache.
   *
   * @param maxCacheSize the maximum number of sources for which AST structures should be kept in
   *          the cache
   * @param retentionPolicy the policy used to determine which pieces of data to remove from the
   *          cache
   */
  AnalysisCache(int maxCacheSize, CacheRetentionPolicy retentionPolicy) {
    this._maxCacheSize = maxCacheSize;
    this._retentionPolicy = retentionPolicy;
    _recentlyUsed = new List<Source>();
  }

  /**
   * Record that the given source was just accessed.
   *
   * @param source the source that was accessed
   */
  void accessed(Source source) {
    if (_recentlyUsed.remove(source)) {
      _recentlyUsed.add(source);
      return;
    }
    while (_recentlyUsed.length >= _maxCacheSize) {
      if (!flushAstFromCache()) {
        break;
      }
    }
    _recentlyUsed.add(source);
  }

  /**
   * Return a collection containing all of the map entries mapping sources to cache entries. Clients
   * should not modify the returned collection.
   *
   * @return a collection containing all of the map entries mapping sources to cache entries
   */
  Iterable<MapEntry<Source, SourceEntry>> entrySet() => getMapEntrySet(_sourceMap);

  /**
   * Return the entry associated with the given source.
   *
   * @param source the source whose entry is to be returned
   * @return the entry associated with the given source
   */
  SourceEntry get(Source source) => _sourceMap[source];

  /**
   * Associate the given entry with the given source.
   *
   * @param source the source with which the entry is to be associated
   * @param entry the entry to be associated with the source
   */
  void put(Source source, SourceEntry entry) {
    _sourceMap[source] = entry;
  }

  /**
   * Remove all information related to the given source from this cache.
   *
   * @param source the source to be removed
   */
  void remove(Source source) {
    _sourceMap.remove(source);
  }

  /**
   * Set the maximum size of the cache to the given size.
   *
   * @param size the maximum number of sources for which AST structures should be kept in the cache
   */
  void set maxCacheSize(int size) {
    _maxCacheSize = size;
    while (_recentlyUsed.length > _maxCacheSize) {
      if (!flushAstFromCache()) {
        break;
      }
    }
  }

  /**
   * Return the number of sources that are mapped to cache entries.
   *
   * @return the number of sources that are mapped to cache entries
   */
  int size() => _sourceMap.length;

  /**
   * Attempt to flush one AST structure from the cache.
   *
   * @return `true` if a structure was flushed
   */
  bool flushAstFromCache() {
    Source removedSource = removeAstToFlush();
    if (removedSource == null) {
      return false;
    }
    SourceEntry sourceEntry = _sourceMap[removedSource];
    if (sourceEntry is HtmlEntry) {
      HtmlEntryImpl htmlCopy = (sourceEntry as HtmlEntry).writableCopy;
      htmlCopy.setState(HtmlEntry.PARSED_UNIT, CacheState.FLUSHED);
      _sourceMap[removedSource] = htmlCopy;
    } else if (sourceEntry is DartEntry) {
      DartEntryImpl dartCopy = (sourceEntry as DartEntry).writableCopy;
      dartCopy.flushAstStructures();
      _sourceMap[removedSource] = dartCopy;
    }
    return true;
  }

  /**
   * Remove and return one source from the list of recently used sources whose AST structure can be
   * flushed from the cache. The source that will be returned will be the source that has been
   * unreferenced for the longest period of time but that is not a priority for analysis.
   *
   * @return the source that was removed
   */
  Source removeAstToFlush() {
    int sourceToRemove = -1;
    for (int i = 0; i < _recentlyUsed.length; i++) {
      Source source = _recentlyUsed[i];
      RetentionPriority priority = _retentionPolicy.getAstPriority(source, _sourceMap[source]);
      if (identical(priority, RetentionPriority.LOW)) {
        return _recentlyUsed.removeAt(i);
      } else if (identical(priority, RetentionPriority.MEDIUM) && sourceToRemove < 0) {
        sourceToRemove = i;
      }
    }
    if (sourceToRemove < 0) {
      AnalysisEngine.instance.logger.logError2("Internal error: Could not flush data from the cache", new JavaException());
      return null;
    }
    return _recentlyUsed.removeAt(sourceToRemove);
  }
}

/**
 * Instances of the class `CacheRetentionPolicy` define the behavior of objects that determine
 * how important it is for data to be retained in the analysis cache.
 */
abstract class CacheRetentionPolicy {
  /**
   * Return the priority of retaining the AST structure for the given source.
   *
   * @param source the source whose AST structure is being considered for removal
   * @param sourceEntry the entry representing the source
   * @return the priority of retaining the AST structure for the given source
   */
  RetentionPriority getAstPriority(Source source, SourceEntry sourceEntry);
}

/**
 * The enumeration `CacheState` defines the possible states of cached data.
 */
class CacheState extends Enum<CacheState> {
  /**
   * The data is not in the cache and the last time an attempt was made to compute the data an
   * exception occurred, making it pointless to attempt.
   *
   * Valid Transitions:
   *
   * * [INVALID] if a source was modified that might cause the data to be computable
   *
   */
  static final CacheState ERROR = new CacheState('ERROR', 0);

  /**
   * The data is not in the cache because it was flushed from the cache in order to control memory
   * usage. If the data is recomputed, results do not need to be reported.
   *
   * Valid Transitions:
   *
   * * [IN_PROCESS] if the data is being recomputed
   * * [INVALID] if a source was modified that causes the data to need to be recomputed
   *
   */
  static final CacheState FLUSHED = new CacheState('FLUSHED', 1);

  /**
   * The data might or might not be in the cache but is in the process of being recomputed.
   *
   * Valid Transitions:
   *
   * * [ERROR] if an exception occurred while trying to compute the data
   * * [VALID] if the data was successfully computed and stored in the cache
   *
   */
  static final CacheState IN_PROCESS = new CacheState('IN_PROCESS', 2);

  /**
   * The data is not in the cache and needs to be recomputed so that results can be reported.
   *
   * Valid Transitions:
   *
   * * [IN_PROCESS] if an attempt is being made to recompute the data
   *
   */
  static final CacheState INVALID = new CacheState('INVALID', 3);

  /**
   * The data is in the cache and up-to-date.
   *
   * Valid Transitions:
   *
   * * [FLUSHED] if the data is removed in order to manage memory usage
   * * [INVALID] if a source was modified in such a way as to invalidate the previous data
   *
   */
  static final CacheState VALID = new CacheState('VALID', 4);

  static final List<CacheState> values = [ERROR, FLUSHED, IN_PROCESS, INVALID, VALID];

  CacheState(String name, int ordinal) : super(name, ordinal);
}

/**
 * The interface `DartEntry` defines the behavior of objects that maintain the information
 * cached by an analysis context about an individual Dart file.
 *
 * @coverage dart.engine
 */
abstract class DartEntry implements SourceEntry {
  /**
   * The data descriptor representing the library element for the library. This data is only
   * available for Dart files that are the defining compilation unit of a library.
   */
  static final DataDescriptor<LibraryElement> ELEMENT = new DataDescriptor<LibraryElement>("DartEntry.ELEMENT");

  /**
   * The data descriptor representing the list of exported libraries. This data is only available
   * for Dart files that are the defining compilation unit of a library.
   */
  static final DataDescriptor<List<Source>> EXPORTED_LIBRARIES = new DataDescriptor<List<Source>>("DartEntry.EXPORTED_LIBRARIES");

  /**
   * The data descriptor representing the hints resulting from auditing the source.
   */
  static final DataDescriptor<List<AnalysisError>> HINTS = new DataDescriptor<List<AnalysisError>>("DartEntry.HINTS");

  /**
   * The data descriptor representing the list of imported libraries. This data is only available
   * for Dart files that are the defining compilation unit of a library.
   */
  static final DataDescriptor<List<Source>> IMPORTED_LIBRARIES = new DataDescriptor<List<Source>>("DartEntry.IMPORTED_LIBRARIES");

  /**
   * The data descriptor representing the list of included parts. This data is only available for
   * Dart files that are the defining compilation unit of a library.
   */
  static final DataDescriptor<List<Source>> INCLUDED_PARTS = new DataDescriptor<List<Source>>("DartEntry.INCLUDED_PARTS");

  /**
   * The data descriptor representing the client flag. This data is only available for Dart files
   * that are the defining compilation unit of a library.
   */
  static final DataDescriptor<bool> IS_CLIENT = new DataDescriptor<bool>("DartEntry.IS_CLIENT");

  /**
   * The data descriptor representing the launchable flag. This data is only available for Dart
   * files that are the defining compilation unit of a library.
   */
  static final DataDescriptor<bool> IS_LAUNCHABLE = new DataDescriptor<bool>("DartEntry.IS_LAUNCHABLE");

  /**
   * The data descriptor representing the errors resulting from parsing the source.
   */
  static final DataDescriptor<List<AnalysisError>> PARSE_ERRORS = new DataDescriptor<List<AnalysisError>>("DartEntry.PARSE_ERRORS");

  /**
   * The data descriptor representing the parsed AST structure.
   */
  static final DataDescriptor<CompilationUnit> PARSED_UNIT = new DataDescriptor<CompilationUnit>("DartEntry.PARSED_UNIT");

  /**
   * The data descriptor representing the public namespace of the library. This data is only
   * available for Dart files that are the defining compilation unit of a library.
   */
  static final DataDescriptor<Namespace> PUBLIC_NAMESPACE = new DataDescriptor<Namespace>("DartEntry.PUBLIC_NAMESPACE");

  /**
   * The data descriptor representing the errors resulting from resolving the source.
   */
  static final DataDescriptor<List<AnalysisError>> RESOLUTION_ERRORS = new DataDescriptor<List<AnalysisError>>("DartEntry.RESOLUTION_ERRORS");

  /**
   * The data descriptor representing the resolved AST structure.
   */
  static final DataDescriptor<CompilationUnit> RESOLVED_UNIT = new DataDescriptor<CompilationUnit>("DartEntry.RESOLVED_UNIT");

  /**
   * The data descriptor representing the source kind.
   */
  static final DataDescriptor<SourceKind> SOURCE_KIND = new DataDescriptor<SourceKind>("DartEntry.SOURCE_KIND");

  /**
   * The data descriptor representing the errors resulting from verifying the source.
   */
  static final DataDescriptor<List<AnalysisError>> VERIFICATION_ERRORS = new DataDescriptor<List<AnalysisError>>("DartEntry.VERIFICATION_ERRORS");

  /**
   * Return all of the errors associated with the compilation unit that are currently cached.
   *
   * @return all of the errors associated with the compilation unit
   */
  List<AnalysisError> get allErrors;

  /**
   * Return a valid parsed compilation unit, either an unresolved AST structure or the result of
   * resolving the AST structure in the context of some library, or `null` if there is no
   * parsed compilation unit available.
   *
   * @return a valid parsed compilation unit
   */
  CompilationUnit get anyParsedCompilationUnit;

  /**
   * Return the result of resolving the compilation unit as part of any library, or `null` if
   * there is no cached resolved compilation unit.
   *
   * @return any resolved compilation unit
   */
  CompilationUnit get anyResolvedCompilationUnit;

  /**
   * Return the state of the data represented by the given descriptor in the context of the given
   * library.
   *
   * @param descriptor the descriptor representing the data whose state is to be returned
   * @param librarySource the source of the defining compilation unit of the library that is the
   *          context for the data
   * @return the value of the data represented by the given descriptor and library
   */
  CacheState getState2(DataDescriptor descriptor, Source librarySource);

  /**
   * Return the value of the data represented by the given descriptor in the context of the given
   * library, or `null` if the data represented by the descriptor is not in the cache.
   *
   * @param descriptor the descriptor representing which data is to be returned
   * @param librarySource the source of the defining compilation unit of the library that is the
   *          context for the data
   * @return the value of the data represented by the given descriptor and library
   */
  Object getValue2(DataDescriptor descriptor, Source librarySource);

  DartEntryImpl get writableCopy;

  /**
   * Return `true` if the data represented by the given descriptor is marked as being invalid.
   * If the descriptor represents library-specific data then this method will return `true` if
   * the data associated with any library it marked as invalid.
   *
   * @param descriptor the descriptor representing which data is being tested
   * @return `true` if the data is marked as being invalid
   */
  bool hasInvalidData(DataDescriptor descriptor);

  /**
   * Return `true` if this data is safe to use in refactoring.
   */
  bool get isRefactoringSafe;
}

/**
 * Instances of the class `DartEntryImpl` implement a [DartEntry].
 *
 * @coverage dart.engine
 */
class DartEntryImpl extends SourceEntryImpl implements DartEntry {
  /**
   * The state of the cached source kind.
   */
  CacheState _sourceKindState = CacheState.INVALID;

  /**
   * The kind of this source.
   */
  SourceKind _sourceKind = SourceKind.UNKNOWN;

  /**
   * The state of the cached parsed compilation unit.
   */
  CacheState _parsedUnitState = CacheState.INVALID;

  /**
   * A flag indicating whether the parsed AST structure has been accessed since it was set. This is
   * used to determine whether the structure needs to be copied before it is resolved.
   */
  bool _parsedUnitAccessed = false;

  /**
   * The parsed compilation unit, or `null` if the parsed compilation unit is not currently
   * cached.
   */
  CompilationUnit _parsedUnit;

  /**
   * The state of the cached parse errors.
   */
  CacheState _parseErrorsState = CacheState.INVALID;

  /**
   * The errors produced while scanning and parsing the compilation unit, or `null` if the
   * errors are not currently cached.
   */
  List<AnalysisError> _parseErrors = AnalysisError.NO_ERRORS;

  /**
   * The state of the cached list of imported libraries.
   */
  CacheState _importedLibrariesState = CacheState.INVALID;

  /**
   * The list of libraries imported by the library, or an empty array if the list is not currently
   * cached. The list will be empty if the Dart file is a part rather than a library.
   */
  List<Source> _importedLibraries = Source.EMPTY_ARRAY;

  /**
   * The state of the cached list of exported libraries.
   */
  CacheState _exportedLibrariesState = CacheState.INVALID;

  /**
   * The list of libraries exported by the library, or an empty array if the list is not currently
   * cached. The list will be empty if the Dart file is a part rather than a library.
   */
  List<Source> _exportedLibraries = Source.EMPTY_ARRAY;

  /**
   * The state of the cached list of included parts.
   */
  CacheState _includedPartsState = CacheState.INVALID;

  /**
   * The list of parts included in the library, or an empty array if the list is not currently
   * cached. The list will be empty if the Dart file is a part rather than a library.
   */
  List<Source> _includedParts = Source.EMPTY_ARRAY;

  /**
   * The information known as a result of resolving this compilation unit as part of the library
   * that contains this unit. This field will never be `null`.
   */
  DartEntryImpl_ResolutionState _resolutionState = new DartEntryImpl_ResolutionState();

  /**
   * The state of the cached library element.
   */
  CacheState _elementState = CacheState.INVALID;

  /**
   * The element representing the library, or `null` if the element is not currently cached.
   */
  LibraryElement _element;

  /**
   * The state of the cached public namespace.
   */
  CacheState _publicNamespaceState = CacheState.INVALID;

  /**
   * The public namespace of the library, or `null` if the namespace is not currently cached.
   */
  Namespace _publicNamespace;

  /**
   * The state of the cached client/ server flag.
   */
  CacheState _clientServerState = CacheState.INVALID;

  /**
   * The state of the cached launchable flag.
   */
  CacheState _launchableState = CacheState.INVALID;

  /**
   * An integer holding bit masks such as [LAUNCHABLE] and [CLIENT_CODE].
   */
  int _bitmask = 0;

  /**
   * The index of the bit in the [bitmask] indicating that this library is launchable: that
   * the file has a main method.
   */
  static int _LAUNCHABLE_INDEX = 1;

  /**
   * The index of the bit in the [bitmask] indicating that the library is client code: that
   * the library depends on the html library. If the library is not "client code", then it is
   * referred to as "server code".
   */
  static int _CLIENT_CODE_INDEX = 2;

  /**
   * Flush any AST structures being maintained by this entry.
   */
  void flushAstStructures() {
    if (identical(_parsedUnitState, CacheState.VALID)) {
      _parsedUnitState = CacheState.FLUSHED;
      _parsedUnitAccessed = false;
      _parsedUnit = null;
    }
    _resolutionState.flushAstStructures();
  }

  List<AnalysisError> get allErrors {
    List<AnalysisError> errors = new List<AnalysisError>();
    for (AnalysisError error in _parseErrors) {
      errors.add(error);
    }
    DartEntryImpl_ResolutionState state = _resolutionState;
    while (state != null) {
      for (AnalysisError error in state._resolutionErrors) {
        errors.add(error);
      }
      for (AnalysisError error in state._verificationErrors) {
        errors.add(error);
      }
      for (AnalysisError error in state._hints) {
        errors.add(error);
      }
      state = state._nextState;
    }
    ;
    if (errors.length == 0) {
      return AnalysisError.NO_ERRORS;
    }
    return new List.from(errors);
  }

  CompilationUnit get anyParsedCompilationUnit {
    if (identical(_parsedUnitState, CacheState.VALID)) {
      _parsedUnitAccessed = true;
      return _parsedUnit;
    }
    return anyResolvedCompilationUnit;
  }

  CompilationUnit get anyResolvedCompilationUnit {
    DartEntryImpl_ResolutionState state = _resolutionState;
    while (state != null) {
      if (identical(state._resolvedUnitState, CacheState.VALID)) {
        return state._resolvedUnit;
      }
      state = state._nextState;
    }
    ;
    return null;
  }

  SourceKind get kind => _sourceKind;

  /**
   * Answer an array of library sources containing the receiver's source.
   */
  List<Source> get librariesContaining {
    DartEntryImpl_ResolutionState state = _resolutionState;
    List<Source> result = new List<Source>();
    while (state != null) {
      if (state._librarySource != null) {
        result.add(state._librarySource);
      }
      state = state._nextState;
    }
    return new List.from(result);
  }

  /**
   * Return a compilation unit that has not been accessed by any other client and can therefore
   * safely be modified by the reconciler.
   *
   * @return a compilation unit that can be modified by the reconciler
   */
  CompilationUnit get resolvableCompilationUnit {
    if (identical(_parsedUnitState, CacheState.VALID)) {
      if (_parsedUnitAccessed) {
        return _parsedUnit.accept(new ASTCloner()) as CompilationUnit;
      }
      CompilationUnit unit = _parsedUnit;
      _parsedUnitState = CacheState.FLUSHED;
      _parsedUnitAccessed = false;
      _parsedUnit = null;
      return unit;
    }
    DartEntryImpl_ResolutionState state = _resolutionState;
    while (state != null) {
      if (identical(state._resolvedUnitState, CacheState.VALID)) {
        return state._resolvedUnit.accept(new ASTCloner()) as CompilationUnit;
      }
      state = state._nextState;
    }
    ;
    return null;
  }

  CacheState getState(DataDescriptor descriptor) {
    if (identical(descriptor, DartEntry.ELEMENT)) {
      return _elementState;
    } else if (identical(descriptor, DartEntry.EXPORTED_LIBRARIES)) {
      return _exportedLibrariesState;
    } else if (identical(descriptor, DartEntry.IMPORTED_LIBRARIES)) {
      return _importedLibrariesState;
    } else if (identical(descriptor, DartEntry.INCLUDED_PARTS)) {
      return _includedPartsState;
    } else if (identical(descriptor, DartEntry.IS_CLIENT)) {
      return _clientServerState;
    } else if (identical(descriptor, DartEntry.IS_LAUNCHABLE)) {
      return _launchableState;
    } else if (identical(descriptor, DartEntry.PARSE_ERRORS)) {
      return _parseErrorsState;
    } else if (identical(descriptor, DartEntry.PARSED_UNIT)) {
      return _parsedUnitState;
    } else if (identical(descriptor, DartEntry.PUBLIC_NAMESPACE)) {
      return _publicNamespaceState;
    } else if (identical(descriptor, DartEntry.SOURCE_KIND)) {
      return _sourceKindState;
    } else {
      return super.getState(descriptor);
    }
  }

  CacheState getState2(DataDescriptor descriptor, Source librarySource) {
    DartEntryImpl_ResolutionState state = _resolutionState;
    while (state != null) {
      if (librarySource == state._librarySource) {
        if (identical(descriptor, DartEntry.RESOLUTION_ERRORS)) {
          return state._resolutionErrorsState;
        } else if (identical(descriptor, DartEntry.RESOLVED_UNIT)) {
          return state._resolvedUnitState;
        } else if (identical(descriptor, DartEntry.VERIFICATION_ERRORS)) {
          return state._verificationErrorsState;
        } else if (identical(descriptor, DartEntry.HINTS)) {
          return state._hintsState;
        } else {
          throw new IllegalArgumentException("Invalid descriptor: ${descriptor}");
        }
      }
      state = state._nextState;
    }
    ;
    if (identical(descriptor, DartEntry.RESOLUTION_ERRORS) || identical(descriptor, DartEntry.RESOLVED_UNIT) || identical(descriptor, DartEntry.VERIFICATION_ERRORS) || identical(descriptor, DartEntry.HINTS)) {
      return CacheState.INVALID;
    } else {
      throw new IllegalArgumentException("Invalid descriptor: ${descriptor}");
    }
  }

  Object getValue(DataDescriptor descriptor) {
    if (identical(descriptor, DartEntry.ELEMENT)) {
      return _element as Object;
    } else if (identical(descriptor, DartEntry.EXPORTED_LIBRARIES)) {
      return _exportedLibraries as Object;
    } else if (identical(descriptor, DartEntry.IMPORTED_LIBRARIES)) {
      return _importedLibraries as Object;
    } else if (identical(descriptor, DartEntry.INCLUDED_PARTS)) {
      return _includedParts as Object;
    } else if (identical(descriptor, DartEntry.IS_CLIENT)) {
      return (BooleanArray.get2(_bitmask, _CLIENT_CODE_INDEX) as bool) as Object;
    } else if (identical(descriptor, DartEntry.IS_LAUNCHABLE)) {
      return (BooleanArray.get2(_bitmask, _LAUNCHABLE_INDEX) as bool) as Object;
    } else if (identical(descriptor, DartEntry.PARSE_ERRORS)) {
      return _parseErrors as Object;
    } else if (identical(descriptor, DartEntry.PARSED_UNIT)) {
      _parsedUnitAccessed = true;
      return _parsedUnit as Object;
    } else if (identical(descriptor, DartEntry.PUBLIC_NAMESPACE)) {
      return _publicNamespace as Object;
    } else if (identical(descriptor, DartEntry.SOURCE_KIND)) {
      return _sourceKind as Object;
    }
    return super.getValue(descriptor);
  }

  Object getValue2(DataDescriptor descriptor, Source librarySource) {
    DartEntryImpl_ResolutionState state = _resolutionState;
    while (state != null) {
      if (librarySource == state._librarySource) {
        if (identical(descriptor, DartEntry.RESOLUTION_ERRORS)) {
          return state._resolutionErrors as Object;
        } else if (identical(descriptor, DartEntry.RESOLVED_UNIT)) {
          return state._resolvedUnit as Object;
        } else if (identical(descriptor, DartEntry.VERIFICATION_ERRORS)) {
          return state._verificationErrors as Object;
        } else if (identical(descriptor, DartEntry.HINTS)) {
          return state._hints as Object;
        } else {
          throw new IllegalArgumentException("Invalid descriptor: ${descriptor}");
        }
      }
      state = state._nextState;
    }
    ;
    if (identical(descriptor, DartEntry.RESOLUTION_ERRORS) || identical(descriptor, DartEntry.VERIFICATION_ERRORS) || identical(descriptor, DartEntry.HINTS)) {
      return AnalysisError.NO_ERRORS as Object;
    } else if (identical(descriptor, DartEntry.RESOLVED_UNIT)) {
      return null;
    } else {
      throw new IllegalArgumentException("Invalid descriptor: ${descriptor}");
    }
  }

  DartEntryImpl get writableCopy {
    DartEntryImpl copy = new DartEntryImpl();
    copy.copyFrom(this);
    return copy;
  }

  bool hasInvalidData(DataDescriptor descriptor) {
    if (identical(descriptor, DartEntry.ELEMENT)) {
      return identical(_elementState, CacheState.INVALID);
    } else if (identical(descriptor, DartEntry.EXPORTED_LIBRARIES)) {
      return identical(_exportedLibrariesState, CacheState.INVALID);
    } else if (identical(descriptor, DartEntry.IMPORTED_LIBRARIES)) {
      return identical(_importedLibrariesState, CacheState.INVALID);
    } else if (identical(descriptor, DartEntry.INCLUDED_PARTS)) {
      return identical(_includedPartsState, CacheState.INVALID);
    } else if (identical(descriptor, DartEntry.IS_CLIENT)) {
      return identical(_clientServerState, CacheState.INVALID);
    } else if (identical(descriptor, DartEntry.IS_LAUNCHABLE)) {
      return identical(_launchableState, CacheState.INVALID);
    } else if (identical(descriptor, DartEntry.PARSE_ERRORS)) {
      return identical(_parseErrorsState, CacheState.INVALID);
    } else if (identical(descriptor, DartEntry.PARSED_UNIT)) {
      return identical(_parsedUnitState, CacheState.INVALID);
    } else if (identical(descriptor, DartEntry.PUBLIC_NAMESPACE)) {
      return identical(_publicNamespaceState, CacheState.INVALID);
    } else if (identical(descriptor, DartEntry.SOURCE_KIND)) {
      return identical(_sourceKindState, CacheState.INVALID);
    } else if (identical(descriptor, DartEntry.RESOLUTION_ERRORS) || identical(descriptor, DartEntry.RESOLVED_UNIT) || identical(descriptor, DartEntry.VERIFICATION_ERRORS) || identical(descriptor, DartEntry.HINTS)) {
      DartEntryImpl_ResolutionState state = _resolutionState;
      while (state != null) {
        if (identical(descriptor, DartEntry.RESOLUTION_ERRORS)) {
          return identical(state._resolutionErrorsState, CacheState.INVALID);
        } else if (identical(descriptor, DartEntry.RESOLVED_UNIT)) {
          return identical(state._resolvedUnitState, CacheState.INVALID);
        } else if (identical(descriptor, DartEntry.VERIFICATION_ERRORS)) {
          return identical(state._verificationErrorsState, CacheState.INVALID);
        } else if (identical(descriptor, DartEntry.HINTS)) {
          return identical(state._hintsState, CacheState.INVALID);
        }
      }
      return false;
    } else {
      return identical(super.getState(descriptor), CacheState.INVALID);
    }
  }

  /**
   * Invalidate all of the information associated with the compilation unit.
   */
  void invalidateAllInformation() {
    setState(SourceEntry.LINE_INFO, CacheState.INVALID);
    _sourceKind = SourceKind.UNKNOWN;
    _sourceKindState = CacheState.INVALID;
    _parseErrors = AnalysisError.NO_ERRORS;
    _parseErrorsState = CacheState.INVALID;
    _parsedUnit = null;
    _parsedUnitAccessed = false;
    _parsedUnitState = CacheState.INVALID;
    discardCachedResolutionInformation();
  }

  /**
   * Invalidate all of the resolution information associated with the compilation unit.
   */
  void invalidateAllResolutionInformation() {
    if (identical(_parsedUnitState, CacheState.FLUSHED)) {
      DartEntryImpl_ResolutionState state = _resolutionState;
      while (state != null) {
        if (identical(state._resolvedUnitState, CacheState.VALID)) {
          _parsedUnit = state._resolvedUnit;
          _parsedUnitAccessed = true;
          _parsedUnitState = CacheState.VALID;
          break;
        }
        state = state._nextState;
      }
    }
    discardCachedResolutionInformation();
  }

  bool get isRefactoringSafe {
    DartEntryImpl_ResolutionState state = _resolutionState;
    while (state != null) {
      CacheState resolvedState = state._resolvedUnitState;
      if (resolvedState != CacheState.VALID && resolvedState != CacheState.FLUSHED) {
        return false;
      }
      state = state._nextState;
    }
    return true;
  }

  /**
   * Record that an error occurred while attempting to scan or parse the entry represented by this
   * entry. This will set the state of all information, including any resolution-based information,
   * as being in error.
   */
  void recordParseError() {
    setState(SourceEntry.LINE_INFO, CacheState.ERROR);
    _sourceKind = SourceKind.UNKNOWN;
    _sourceKindState = CacheState.ERROR;
    _parseErrors = AnalysisError.NO_ERRORS;
    _parseErrorsState = CacheState.ERROR;
    _parsedUnit = null;
    _parsedUnitAccessed = false;
    _parsedUnitState = CacheState.ERROR;
    _exportedLibraries = Source.EMPTY_ARRAY;
    _exportedLibrariesState = CacheState.ERROR;
    _importedLibraries = Source.EMPTY_ARRAY;
    _importedLibrariesState = CacheState.ERROR;
    _includedParts = Source.EMPTY_ARRAY;
    _includedPartsState = CacheState.ERROR;
    recordResolutionError();
  }

  /**
   * Record that the parse-related information for the associated source is about to be computed by
   * the current thread.
   */
  void recordParseInProcess() {
    if (getState(SourceEntry.LINE_INFO) != CacheState.VALID) {
      setState(SourceEntry.LINE_INFO, CacheState.IN_PROCESS);
    }
    if (_sourceKindState != CacheState.VALID) {
      _sourceKindState = CacheState.IN_PROCESS;
    }
    if (_parseErrorsState != CacheState.VALID) {
      _parseErrorsState = CacheState.IN_PROCESS;
    }
    if (_parsedUnitState != CacheState.VALID) {
      _parsedUnitState = CacheState.IN_PROCESS;
    }
    if (_exportedLibrariesState != CacheState.VALID) {
      _exportedLibrariesState = CacheState.IN_PROCESS;
    }
    if (_importedLibrariesState != CacheState.VALID) {
      _importedLibrariesState = CacheState.IN_PROCESS;
    }
    if (_includedPartsState != CacheState.VALID) {
      _includedPartsState = CacheState.IN_PROCESS;
    }
  }

  /**
   * Record that an in-process parse has stopped without recording results because the results were
   * invalidated before they could be recorded.
   */
  void recordParseNotInProcess() {
    if (identical(getState(SourceEntry.LINE_INFO), CacheState.IN_PROCESS)) {
      setState(SourceEntry.LINE_INFO, CacheState.INVALID);
    }
    if (identical(_sourceKindState, CacheState.IN_PROCESS)) {
      _sourceKindState = CacheState.INVALID;
    }
    if (identical(_parseErrorsState, CacheState.IN_PROCESS)) {
      _parseErrorsState = CacheState.INVALID;
    }
    if (identical(_parsedUnitState, CacheState.IN_PROCESS)) {
      _parsedUnitState = CacheState.INVALID;
    }
    if (identical(_exportedLibrariesState, CacheState.IN_PROCESS)) {
      _exportedLibrariesState = CacheState.INVALID;
    }
    if (identical(_importedLibrariesState, CacheState.IN_PROCESS)) {
      _importedLibrariesState = CacheState.INVALID;
    }
    if (identical(_includedPartsState, CacheState.IN_PROCESS)) {
      _includedPartsState = CacheState.INVALID;
    }
  }

  /**
   * Record that an error occurred while attempting to scan or parse the entry represented by this
   * entry. This will set the state of all resolution-based information as being in error, but will
   * not change the state of any parse results.
   */
  void recordResolutionError() {
    _element = null;
    _elementState = CacheState.ERROR;
    _bitmask = 0;
    _clientServerState = CacheState.ERROR;
    _launchableState = CacheState.ERROR;
    _publicNamespace = null;
    _publicNamespaceState = CacheState.ERROR;
    _resolutionState.recordResolutionError();
  }

  /**
   * Record that an in-process parse has stopped without recording results because the results were
   * invalidated before they could be recorded.
   */
  void recordResolutionNotInProcess() {
    if (identical(_elementState, CacheState.IN_PROCESS)) {
      _elementState = CacheState.INVALID;
    }
    if (identical(_clientServerState, CacheState.IN_PROCESS)) {
      _clientServerState = CacheState.INVALID;
    }
    if (identical(_launchableState, CacheState.IN_PROCESS)) {
      _launchableState = CacheState.INVALID;
    }
    if (identical(_publicNamespaceState, CacheState.IN_PROCESS)) {
      _publicNamespaceState = CacheState.INVALID;
    }
    _resolutionState.recordResolutionNotInProcess();
  }

  /**
   * Remove any resolution information associated with this compilation unit being part of the given
   * library, presumably because it is no longer part of the library.
   *
   * @param librarySource the source of the defining compilation unit of the library that used to
   *          contain this part but no longer does
   */
  void removeResolution(Source librarySource) {
    if (librarySource != null) {
      if (librarySource == _resolutionState._librarySource) {
        if (_resolutionState._nextState == null) {
          _resolutionState.invalidateAllResolutionInformation();
        } else {
          _resolutionState = _resolutionState._nextState;
        }
      } else {
        DartEntryImpl_ResolutionState priorState = _resolutionState;
        DartEntryImpl_ResolutionState state = _resolutionState._nextState;
        while (state != null) {
          if (librarySource == state._librarySource) {
            priorState._nextState = state._nextState;
            break;
          }
          priorState = state;
          state = state._nextState;
        }
      }
    }
  }

  /**
   * Set the results of parsing the compilation unit at the given time to the given values.
   *
   * @param modificationStamp the earliest time at which the source was last modified before the
   *          parsing was started
   * @param lineInfo the line information resulting from parsing the compilation unit
   * @param unit the AST structure resulting from parsing the compilation unit
   * @param errors the parse errors resulting from parsing the compilation unit
   */
  void setParseResults(int modificationStamp, LineInfo lineInfo, CompilationUnit unit, List<AnalysisError> errors) {
    if (getState(SourceEntry.LINE_INFO) != CacheState.VALID) {
      setValue(SourceEntry.LINE_INFO, lineInfo);
    }
    if (_parsedUnitState != CacheState.VALID) {
      _parsedUnit = unit;
      _parsedUnitAccessed = false;
      _parsedUnitState = CacheState.VALID;
    }
    if (_parseErrorsState != CacheState.VALID) {
      _parseErrors = errors == null ? AnalysisError.NO_ERRORS : errors;
      _parseErrorsState = CacheState.VALID;
    }
  }

  void setState(DataDescriptor descriptor, CacheState state) {
    if (identical(descriptor, DartEntry.ELEMENT)) {
      _element = updatedValue(state, _element, null);
      _elementState = state;
    } else if (identical(descriptor, DartEntry.EXPORTED_LIBRARIES)) {
      _exportedLibraries = updatedValue(state, _exportedLibraries, Source.EMPTY_ARRAY);
      _exportedLibrariesState = state;
    } else if (identical(descriptor, DartEntry.IMPORTED_LIBRARIES)) {
      _importedLibraries = updatedValue(state, _importedLibraries, Source.EMPTY_ARRAY);
      _importedLibrariesState = state;
    } else if (identical(descriptor, DartEntry.INCLUDED_PARTS)) {
      _includedParts = updatedValue(state, _includedParts, Source.EMPTY_ARRAY);
      _includedPartsState = state;
    } else if (identical(descriptor, DartEntry.IS_CLIENT)) {
      _bitmask = updatedValue2(state, _bitmask, _CLIENT_CODE_INDEX);
      _clientServerState = state;
    } else if (identical(descriptor, DartEntry.IS_LAUNCHABLE)) {
      _bitmask = updatedValue2(state, _bitmask, _LAUNCHABLE_INDEX);
      _launchableState = state;
    } else if (identical(descriptor, DartEntry.PARSE_ERRORS)) {
      _parseErrors = updatedValue(state, _parseErrors, AnalysisError.NO_ERRORS);
      _parseErrorsState = state;
    } else if (identical(descriptor, DartEntry.PARSED_UNIT)) {
      CompilationUnit newUnit = updatedValue(state, _parsedUnit, null);
      if (newUnit != _parsedUnit) {
        _parsedUnitAccessed = false;
      }
      _parsedUnit = newUnit;
      _parsedUnitState = state;
    } else if (identical(descriptor, DartEntry.PUBLIC_NAMESPACE)) {
      _publicNamespace = updatedValue(state, _publicNamespace, null);
      _publicNamespaceState = state;
    } else if (identical(descriptor, DartEntry.SOURCE_KIND)) {
      _sourceKind = updatedValue(state, _sourceKind, SourceKind.UNKNOWN);
      _sourceKindState = state;
    } else {
      super.setState(descriptor, state);
    }
  }

  /**
   * Set the state of the data represented by the given descriptor in the context of the given
   * library to the given state.
   *
   * @param descriptor the descriptor representing the data whose state is to be set
   * @param librarySource the source of the defining compilation unit of the library that is the
   *          context for the data
   * @param cacheState the new state of the data represented by the given descriptor
   */
  void setState2(DataDescriptor descriptor, Source librarySource, CacheState cacheState) {
    DartEntryImpl_ResolutionState state = getOrCreateResolutionState(librarySource);
    if (identical(descriptor, DartEntry.RESOLUTION_ERRORS)) {
      state._resolutionErrors = updatedValue(cacheState, state._resolutionErrors, AnalysisError.NO_ERRORS);
      state._resolutionErrorsState = cacheState;
    } else if (identical(descriptor, DartEntry.RESOLVED_UNIT)) {
      state._resolvedUnit = updatedValue(cacheState, state._resolvedUnit, null);
      state._resolvedUnitState = cacheState;
    } else if (identical(descriptor, DartEntry.VERIFICATION_ERRORS)) {
      state._verificationErrors = updatedValue(cacheState, state._verificationErrors, AnalysisError.NO_ERRORS);
      state._verificationErrorsState = cacheState;
    } else if (identical(descriptor, DartEntry.HINTS)) {
      state._hints = updatedValue(cacheState, state._hints, AnalysisError.NO_ERRORS);
      state._hintsState = cacheState;
    } else {
      throw new IllegalArgumentException("Invalid descriptor: ${descriptor}");
    }
  }

  void setValue(DataDescriptor descriptor, Object value) {
    if (identical(descriptor, DartEntry.ELEMENT)) {
      _element = value as LibraryElement;
      _elementState = CacheState.VALID;
    } else if (identical(descriptor, DartEntry.EXPORTED_LIBRARIES)) {
      _exportedLibraries = value == null ? Source.EMPTY_ARRAY : (value as List<Source>);
      _exportedLibrariesState = CacheState.VALID;
    } else if (identical(descriptor, DartEntry.IMPORTED_LIBRARIES)) {
      _importedLibraries = value == null ? Source.EMPTY_ARRAY : (value as List<Source>);
      _importedLibrariesState = CacheState.VALID;
    } else if (identical(descriptor, DartEntry.INCLUDED_PARTS)) {
      _includedParts = value == null ? Source.EMPTY_ARRAY : (value as List<Source>);
      _includedPartsState = CacheState.VALID;
    } else if (identical(descriptor, DartEntry.IS_CLIENT)) {
      _bitmask = BooleanArray.set2(_bitmask, _CLIENT_CODE_INDEX, value as bool);
      _clientServerState = CacheState.VALID;
    } else if (identical(descriptor, DartEntry.IS_LAUNCHABLE)) {
      _bitmask = BooleanArray.set2(_bitmask, _LAUNCHABLE_INDEX, value as bool);
      _launchableState = CacheState.VALID;
    } else if (identical(descriptor, DartEntry.PARSE_ERRORS)) {
      _parseErrors = value == null ? AnalysisError.NO_ERRORS : (value as List<AnalysisError>);
      _parseErrorsState = CacheState.VALID;
    } else if (identical(descriptor, DartEntry.PARSED_UNIT)) {
      _parsedUnit = value as CompilationUnit;
      _parsedUnitAccessed = false;
      _parsedUnitState = CacheState.VALID;
    } else if (identical(descriptor, DartEntry.PUBLIC_NAMESPACE)) {
      _publicNamespace = value as Namespace;
      _publicNamespaceState = CacheState.VALID;
    } else if (identical(descriptor, DartEntry.SOURCE_KIND)) {
      _sourceKind = value as SourceKind;
      _sourceKindState = CacheState.VALID;
    } else {
      super.setValue(descriptor, value);
    }
  }

  /**
   * Set the value of the data represented by the given descriptor in the context of the given
   * library to the given value, and set the state of that data to [CacheState#VALID].
   *
   * @param descriptor the descriptor representing which data is to have its value set
   * @param librarySource the source of the defining compilation unit of the library that is the
   *          context for the data
   * @param value the new value of the data represented by the given descriptor and library
   */
  void setValue2(DataDescriptor descriptor, Source librarySource, Object value) {
    DartEntryImpl_ResolutionState state = getOrCreateResolutionState(librarySource);
    if (identical(descriptor, DartEntry.RESOLUTION_ERRORS)) {
      state._resolutionErrors = value == null ? AnalysisError.NO_ERRORS : (value as List<AnalysisError>);
      state._resolutionErrorsState = CacheState.VALID;
    } else if (identical(descriptor, DartEntry.RESOLVED_UNIT)) {
      state._resolvedUnit = value as CompilationUnit;
      state._resolvedUnitState = CacheState.VALID;
    } else if (identical(descriptor, DartEntry.VERIFICATION_ERRORS)) {
      state._verificationErrors = value == null ? AnalysisError.NO_ERRORS : (value as List<AnalysisError>);
      state._verificationErrorsState = CacheState.VALID;
    } else if (identical(descriptor, DartEntry.HINTS)) {
      state._hints = value == null ? AnalysisError.NO_ERRORS : (value as List<AnalysisError>);
      state._hintsState = CacheState.VALID;
    }
  }

  void copyFrom(SourceEntryImpl entry) {
    super.copyFrom(entry);
    DartEntryImpl other = entry as DartEntryImpl;
    _sourceKindState = other._sourceKindState;
    _sourceKind = other._sourceKind;
    _parsedUnitState = other._parsedUnitState;
    _parsedUnit = other._parsedUnit;
    _parsedUnitAccessed = other._parsedUnitAccessed;
    _parseErrorsState = other._parseErrorsState;
    _parseErrors = other._parseErrors;
    _includedPartsState = other._includedPartsState;
    _includedParts = other._includedParts;
    _exportedLibrariesState = other._exportedLibrariesState;
    _exportedLibraries = other._exportedLibraries;
    _importedLibrariesState = other._importedLibrariesState;
    _importedLibraries = other._importedLibraries;
    _resolutionState.copyFrom(other._resolutionState);
    _elementState = other._elementState;
    _element = other._element;
    _publicNamespaceState = other._publicNamespaceState;
    _publicNamespace = other._publicNamespace;
    _clientServerState = other._clientServerState;
    _launchableState = other._launchableState;
    _bitmask = other._bitmask;
  }

  void writeOn(JavaStringBuilder builder) {
    builder.append("Dart: ");
    super.writeOn(builder);
    builder.append("; sourceKind = ");
    builder.append(_sourceKindState);
    builder.append("; parsedUnit = ");
    builder.append(_parsedUnitState);
    builder.append(" (");
    builder.append(_parsedUnitAccessed ? "T" : "F");
    builder.append("); parseErrors = ");
    builder.append(_parseErrorsState);
    builder.append("; exportedLibraries = ");
    builder.append(_exportedLibrariesState);
    builder.append("; importedLibraries = ");
    builder.append(_importedLibrariesState);
    builder.append("; includedParts = ");
    builder.append(_includedPartsState);
    builder.append("; element = ");
    builder.append(_elementState);
    builder.append("; publicNamespace = ");
    builder.append(_publicNamespaceState);
    builder.append("; clientServer = ");
    builder.append(_clientServerState);
    builder.append("; launchable = ");
    builder.append(_launchableState);
    _resolutionState.writeOn(builder);
  }

  /**
   * Invalidate all of the resolution information associated with the compilation unit.
   */
  void discardCachedResolutionInformation() {
    _element = null;
    _elementState = CacheState.INVALID;
    _includedParts = Source.EMPTY_ARRAY;
    _includedPartsState = CacheState.INVALID;
    _exportedLibraries = Source.EMPTY_ARRAY;
    _exportedLibrariesState = CacheState.INVALID;
    _importedLibraries = Source.EMPTY_ARRAY;
    _importedLibrariesState = CacheState.INVALID;
    _bitmask = 0;
    _clientServerState = CacheState.INVALID;
    _launchableState = CacheState.INVALID;
    _publicNamespace = null;
    _publicNamespaceState = CacheState.INVALID;
    _resolutionState.invalidateAllResolutionInformation();
  }

  /**
   * Return a resolution state for the specified library, creating one as necessary.
   *
   * @param librarySource the library source (not `null`)
   * @return the resolution state (not `null`)
   */
  DartEntryImpl_ResolutionState getOrCreateResolutionState(Source librarySource) {
    DartEntryImpl_ResolutionState state = _resolutionState;
    if (state._librarySource == null) {
      state._librarySource = librarySource;
      return state;
    }
    while (state._librarySource != librarySource) {
      if (state._nextState == null) {
        DartEntryImpl_ResolutionState newState = new DartEntryImpl_ResolutionState();
        newState._librarySource = librarySource;
        state._nextState = newState;
        return newState;
      }
      state = state._nextState;
    }
    return state;
  }

  /**
   * Given that one of the flags is being transitioned to the given state, return the value of the
   * flags that should be kept in the cache.
   *
   * @param state the state to which the data is being transitioned
   * @param currentValue the value of the flags before the transition
   * @param bitMask the mask used to access the bit whose state is being set
   * @return the value of the data that should be kept in the cache
   */
  int updatedValue2(CacheState state, int currentValue, int bitIndex) {
    if (identical(state, CacheState.VALID)) {
      throw new IllegalArgumentException("Use setValue() to set the state to VALID");
    } else if (identical(state, CacheState.IN_PROCESS)) {
      return currentValue;
    }
    return BooleanArray.set2(currentValue, bitIndex, false);
  }
}

/**
 * Instances of the class `ResolutionState` represent the information produced by resolving
 * a compilation unit as part of a specific library.
 */
class DartEntryImpl_ResolutionState {
  /**
   * The next resolution state or `null` if none.
   */
  DartEntryImpl_ResolutionState _nextState;

  /**
   * The source for the defining compilation unit of the library that contains this unit. If this
   * unit is the defining compilation unit for it's library, then this will be the source for this
   * unit.
   */
  Source _librarySource;

  /**
   * The state of the cached resolved compilation unit.
   */
  CacheState _resolvedUnitState = CacheState.INVALID;

  /**
   * The resolved compilation unit, or `null` if the resolved compilation unit is not
   * currently cached.
   */
  CompilationUnit _resolvedUnit;

  /**
   * The state of the cached resolution errors.
   */
  CacheState _resolutionErrorsState = CacheState.INVALID;

  /**
   * The errors produced while resolving the compilation unit, or an empty array if the errors are
   * not currently cached.
   */
  List<AnalysisError> _resolutionErrors = AnalysisError.NO_ERRORS;

  /**
   * The state of the cached verification errors.
   */
  CacheState _verificationErrorsState = CacheState.INVALID;

  /**
   * The errors produced while verifying the compilation unit, or an empty array if the errors are
   * not currently cached.
   */
  List<AnalysisError> _verificationErrors = AnalysisError.NO_ERRORS;

  /**
   * The state of the cached hints.
   */
  CacheState _hintsState = CacheState.INVALID;

  /**
   * The hints produced while auditing the compilation unit, or an empty array if the hints are
   * not currently cached.
   */
  List<AnalysisError> _hints = AnalysisError.NO_ERRORS;

  /**
   * Set this state to be exactly like the given state, recursively copying the next state as
   * necessary.
   *
   * @param other the state to be copied
   */
  void copyFrom(DartEntryImpl_ResolutionState other) {
    _librarySource = other._librarySource;
    _resolvedUnitState = other._resolvedUnitState;
    _resolvedUnit = other._resolvedUnit;
    _resolutionErrorsState = other._resolutionErrorsState;
    _resolutionErrors = other._resolutionErrors;
    _verificationErrorsState = other._verificationErrorsState;
    _verificationErrors = other._verificationErrors;
    _hintsState = other._hintsState;
    _hints = other._hints;
    if (other._nextState != null) {
      _nextState = new DartEntryImpl_ResolutionState();
      _nextState.copyFrom(other._nextState);
    }
  }

  /**
   * Flush any AST structures being maintained by this state.
   */
  void flushAstStructures() {
    if (identical(_resolvedUnitState, CacheState.VALID)) {
      _resolvedUnitState = CacheState.FLUSHED;
      _resolvedUnit = null;
    }
    if (_nextState != null) {
      _nextState.flushAstStructures();
    }
  }

  /**
   * Invalidate all of the resolution information associated with the compilation unit.
   */
  void invalidateAllResolutionInformation() {
    _nextState = null;
    _librarySource = null;
    _resolvedUnitState = CacheState.INVALID;
    _resolvedUnit = null;
    _resolutionErrorsState = CacheState.INVALID;
    _resolutionErrors = AnalysisError.NO_ERRORS;
    _verificationErrorsState = CacheState.INVALID;
    _verificationErrors = AnalysisError.NO_ERRORS;
    _hintsState = CacheState.INVALID;
    _hints = AnalysisError.NO_ERRORS;
  }

  /**
   * Record that an error occurred while attempting to scan or parse the entry represented by this
   * entry. This will set the state of all resolution-based information as being in error, but
   * will not change the state of any parse results.
   */
  void recordResolutionError() {
    _resolvedUnitState = CacheState.ERROR;
    _resolvedUnit = null;
    _resolutionErrorsState = CacheState.ERROR;
    _resolutionErrors = AnalysisError.NO_ERRORS;
    _verificationErrorsState = CacheState.ERROR;
    _verificationErrors = AnalysisError.NO_ERRORS;
    _hintsState = CacheState.ERROR;
    _hints = AnalysisError.NO_ERRORS;
    if (_nextState != null) {
      _nextState.recordResolutionError();
    }
  }

  /**
   * Record that an in-process parse has stopped without recording results because the results
   * were invalidated before they could be recorded.
   */
  void recordResolutionNotInProcess() {
    if (identical(_resolvedUnitState, CacheState.IN_PROCESS)) {
      _resolvedUnitState = CacheState.INVALID;
    }
    if (identical(_resolutionErrorsState, CacheState.IN_PROCESS)) {
      _resolutionErrorsState = CacheState.INVALID;
    }
    if (identical(_verificationErrorsState, CacheState.IN_PROCESS)) {
      _verificationErrorsState = CacheState.INVALID;
    }
    if (identical(_hintsState, CacheState.IN_PROCESS)) {
      _hintsState = CacheState.INVALID;
    }
    if (_nextState != null) {
      _nextState.recordResolutionNotInProcess();
    }
  }

  /**
   * Write a textual representation of this state to the given builder. The result will only be
   * used for debugging purposes.
   *
   * @param builder the builder to which the text should be written
   */
  void writeOn(JavaStringBuilder builder) {
    if (_librarySource != null) {
      builder.append("; resolvedUnit = ");
      builder.append(_resolvedUnitState);
      builder.append("; resolutionErrors = ");
      builder.append(_resolutionErrorsState);
      builder.append("; verificationErrors = ");
      builder.append(_verificationErrorsState);
      builder.append("; hints = ");
      builder.append(_hintsState);
      if (_nextState != null) {
        _nextState.writeOn(builder);
      }
    }
  }
}

/**
 * Instances of the class `DataDescriptor` are immutable constants representing data that can
 * be stored in the cache.
 */
class DataDescriptor<E> {
  /**
   * The name of the descriptor, used for debugging purposes.
   */
  String _name;

  /**
   * Initialize a newly created descriptor to have the given name.
   *
   * @param name the name of the descriptor
   */
  DataDescriptor(String name) {
    this._name = name;
  }

  String toString() => _name;
}

/**
 * The interface `HtmlEntry` defines the behavior of objects that maintain the information
 * cached by an analysis context about an individual HTML file.
 *
 * @coverage dart.engine
 */
abstract class HtmlEntry implements SourceEntry {
  /**
   * The data descriptor representing the HTML element.
   */
  static final DataDescriptor<HtmlElement> ELEMENT = new DataDescriptor<HtmlElement>("HtmlEntry.ELEMENT");

  /**
   * The data descriptor representing the hints resulting from auditing the source.
   */
  static final DataDescriptor<List<AnalysisError>> HINTS = new DataDescriptor<List<AnalysisError>>("HtmlEntry.HINTS");

  /**
   * The data descriptor representing the errors resulting from parsing the source.
   */
  static final DataDescriptor<List<AnalysisError>> PARSE_ERRORS = new DataDescriptor<List<AnalysisError>>("HtmlEntry.PARSE_ERRORS");

  /**
   * The data descriptor representing the parsed AST structure.
   */
  static final DataDescriptor<HtmlUnit> PARSED_UNIT = new DataDescriptor<HtmlUnit>("HtmlEntry.PARSED_UNIT");

  /**
   * The data descriptor representing the list of referenced libraries.
   */
  static final DataDescriptor<List<Source>> REFERENCED_LIBRARIES = new DataDescriptor<List<Source>>("HtmlEntry.REFERENCED_LIBRARIES");

  /**
   * The data descriptor representing the errors resulting from resolving the source.
   */
  static final DataDescriptor<List<AnalysisError>> RESOLUTION_ERRORS = new DataDescriptor<List<AnalysisError>>("HtmlEntry.RESOLUTION_ERRORS");

  /**
   * Return all of the errors associated with the compilation unit that are currently cached.
   *
   * @return all of the errors associated with the compilation unit
   */
  List<AnalysisError> get allErrors;

  HtmlEntryImpl get writableCopy;
}

/**
 * Instances of the class `HtmlEntryImpl` implement an [HtmlEntry].
 *
 * @coverage dart.engine
 */
class HtmlEntryImpl extends SourceEntryImpl implements HtmlEntry {
  /**
   * The state of the cached parsed (but not resolved) HTML unit.
   */
  CacheState _parsedUnitState = CacheState.INVALID;

  /**
   * The parsed HTML unit, or `null` if the parsed HTML unit is not currently cached.
   */
  HtmlUnit _parsedUnit;

  /**
   * The state of the cached parse errors.
   */
  CacheState _parseErrorsState = CacheState.INVALID;

  /**
   * The errors produced while scanning and parsing the HTML, or `null` if the errors are not
   * currently cached.
   */
  List<AnalysisError> _parseErrors = AnalysisError.NO_ERRORS;

  /**
   * The state of the cached resolution errors.
   */
  CacheState _resolutionErrorsState = CacheState.INVALID;

  /**
   * The errors produced while resolving the HTML, or `null` if the errors are not currently
   * cached.
   */
  List<AnalysisError> _resolutionErrors = AnalysisError.NO_ERRORS;

  /**
   * The state of the cached list of referenced libraries.
   */
  CacheState _referencedLibrariesState = CacheState.INVALID;

  /**
   * The list of libraries referenced in the HTML, or `null` if the list is not currently
   * cached. Note that this list does not include libraries defined directly within the HTML file.
   */
  List<Source> _referencedLibraries = Source.EMPTY_ARRAY;

  /**
   * The state of the cached HTML element.
   */
  CacheState _elementState = CacheState.INVALID;

  /**
   * The element representing the HTML file, or `null` if the element is not currently cached.
   */
  HtmlElement _element;

  /**
   * The state of the cached hints.
   */
  CacheState _hintsState = CacheState.INVALID;

  /**
   * The hints produced while auditing the compilation unit, or an empty array if the hints are not
   * currently cached.
   */
  List<AnalysisError> _hints = AnalysisError.NO_ERRORS;

  List<AnalysisError> get allErrors {
    List<AnalysisError> errors = new List<AnalysisError>();
    for (AnalysisError error in _parseErrors) {
      errors.add(error);
    }
    for (AnalysisError error in _resolutionErrors) {
      errors.add(error);
    }
    for (AnalysisError error in _hints) {
      errors.add(error);
    }
    if (errors.length == 0) {
      return AnalysisError.NO_ERRORS;
    }
    return new List.from(errors);
  }

  SourceKind get kind => SourceKind.HTML;

  CacheState getState(DataDescriptor descriptor) {
    if (identical(descriptor, HtmlEntry.ELEMENT)) {
      return _elementState;
    } else if (identical(descriptor, HtmlEntry.PARSE_ERRORS)) {
      return _parseErrorsState;
    } else if (identical(descriptor, HtmlEntry.PARSED_UNIT)) {
      return _parsedUnitState;
    } else if (identical(descriptor, HtmlEntry.REFERENCED_LIBRARIES)) {
      return _referencedLibrariesState;
    } else if (identical(descriptor, HtmlEntry.RESOLUTION_ERRORS)) {
      return _resolutionErrorsState;
    } else if (identical(descriptor, HtmlEntry.HINTS)) {
      return _hintsState;
    }
    return super.getState(descriptor);
  }

  Object getValue(DataDescriptor descriptor) {
    if (identical(descriptor, HtmlEntry.ELEMENT)) {
      return _element as Object;
    } else if (identical(descriptor, HtmlEntry.PARSE_ERRORS)) {
      return _parseErrors as Object;
    } else if (identical(descriptor, HtmlEntry.PARSED_UNIT)) {
      return _parsedUnit as Object;
    } else if (identical(descriptor, HtmlEntry.REFERENCED_LIBRARIES)) {
      return _referencedLibraries as Object;
    } else if (identical(descriptor, HtmlEntry.RESOLUTION_ERRORS)) {
      return _resolutionErrors as Object;
    } else if (identical(descriptor, HtmlEntry.HINTS)) {
      return _hints as Object;
    }
    return super.getValue(descriptor);
  }

  HtmlEntryImpl get writableCopy {
    HtmlEntryImpl copy = new HtmlEntryImpl();
    copy.copyFrom(this);
    return copy;
  }

  /**
   * Invalidate all of the information associated with the HTML file.
   */
  void invalidateAllInformation() {
    setState(SourceEntry.LINE_INFO, CacheState.INVALID);
    _parseErrors = AnalysisError.NO_ERRORS;
    _parseErrorsState = CacheState.INVALID;
    _parsedUnit = null;
    _parsedUnitState = CacheState.INVALID;
    _referencedLibraries = Source.EMPTY_ARRAY;
    _referencedLibrariesState = CacheState.INVALID;
    invalidateAllResolutionInformation();
  }

  /**
   * Invalidate all of the resolution information associated with the HTML file.
   */
  void invalidateAllResolutionInformation() {
    _element = null;
    _elementState = CacheState.INVALID;
    _resolutionErrors = AnalysisError.NO_ERRORS;
    _resolutionErrorsState = CacheState.INVALID;
    _hints = AnalysisError.NO_ERRORS;
    _hintsState = CacheState.INVALID;
  }

  /**
   * Record that an error was encountered while attempting to parse the source associated with this
   * entry.
   */
  void recordParseError() {
    setState(SourceEntry.LINE_INFO, CacheState.ERROR);
    setState(HtmlEntry.PARSE_ERRORS, CacheState.ERROR);
    setState(HtmlEntry.PARSED_UNIT, CacheState.ERROR);
    setState(HtmlEntry.REFERENCED_LIBRARIES, CacheState.ERROR);
    recordResolutionError();
  }

  /**
   * Record that an error was encountered while attempting to resolve the source associated with
   * this entry.
   */
  void recordResolutionError() {
    setState(HtmlEntry.ELEMENT, CacheState.ERROR);
    setState(HtmlEntry.RESOLUTION_ERRORS, CacheState.ERROR);
    setState(HtmlEntry.HINTS, CacheState.ERROR);
  }

  void setState(DataDescriptor descriptor, CacheState state) {
    if (identical(descriptor, HtmlEntry.ELEMENT)) {
      _element = updatedValue(state, _element, null);
      _elementState = state;
    } else if (identical(descriptor, HtmlEntry.PARSE_ERRORS)) {
      _parseErrors = updatedValue(state, _parseErrors, null);
      _parseErrorsState = state;
    } else if (identical(descriptor, HtmlEntry.PARSED_UNIT)) {
      _parsedUnit = updatedValue(state, _parsedUnit, null);
      _parsedUnitState = state;
    } else if (identical(descriptor, HtmlEntry.REFERENCED_LIBRARIES)) {
      _referencedLibraries = updatedValue(state, _referencedLibraries, Source.EMPTY_ARRAY);
      _referencedLibrariesState = state;
    } else if (identical(descriptor, HtmlEntry.RESOLUTION_ERRORS)) {
      _resolutionErrors = updatedValue(state, _resolutionErrors, AnalysisError.NO_ERRORS);
      _resolutionErrorsState = state;
    } else if (identical(descriptor, HtmlEntry.HINTS)) {
      _hints = updatedValue(state, _hints, AnalysisError.NO_ERRORS);
      _hintsState = state;
    } else {
      super.setState(descriptor, state);
    }
  }

  void setValue(DataDescriptor descriptor, Object value) {
    if (identical(descriptor, HtmlEntry.ELEMENT)) {
      _element = value as HtmlElement;
      _elementState = CacheState.VALID;
    } else if (identical(descriptor, HtmlEntry.PARSE_ERRORS)) {
      _parseErrors = value as List<AnalysisError>;
      _parseErrorsState = CacheState.VALID;
    } else if (identical(descriptor, HtmlEntry.PARSED_UNIT)) {
      _parsedUnit = value as HtmlUnit;
      _parsedUnitState = CacheState.VALID;
    } else if (identical(descriptor, HtmlEntry.REFERENCED_LIBRARIES)) {
      _referencedLibraries = value == null ? Source.EMPTY_ARRAY : (value as List<Source>);
      _referencedLibrariesState = CacheState.VALID;
    } else if (identical(descriptor, HtmlEntry.RESOLUTION_ERRORS)) {
      _resolutionErrors = value as List<AnalysisError>;
      _resolutionErrorsState = CacheState.VALID;
    } else if (identical(descriptor, HtmlEntry.HINTS)) {
      _hints = value as List<AnalysisError>;
      _hintsState = CacheState.VALID;
    } else {
      super.setValue(descriptor, value);
    }
  }

  void copyFrom(SourceEntryImpl entry) {
    super.copyFrom(entry);
    HtmlEntryImpl other = entry as HtmlEntryImpl;
    _parseErrorsState = other._parseErrorsState;
    _parseErrors = other._parseErrors;
    _parsedUnitState = other._parsedUnitState;
    _parsedUnit = other._parsedUnit;
    _referencedLibrariesState = other._referencedLibrariesState;
    _referencedLibraries = other._referencedLibraries;
    _resolutionErrors = other._resolutionErrors;
    _resolutionErrorsState = other._resolutionErrorsState;
    _elementState = other._elementState;
    _element = other._element;
    _hints = other._hints;
    _hintsState = other._hintsState;
  }

  void writeOn(JavaStringBuilder builder) {
    builder.append("Html: ");
    super.writeOn(builder);
    builder.append("; parseErrors = ");
    builder.append(_parseErrorsState);
    builder.append("; parsedUnit = ");
    builder.append(_parsedUnitState);
    builder.append("; resolutionErrors = ");
    builder.append(_resolutionErrorsState);
    builder.append("; referencedLibraries = ");
    builder.append(_referencedLibrariesState);
    builder.append("; element = ");
    builder.append(_elementState);
  }
}

/**
 * The enumerated type `RetentionPriority` represents the priority of data in the cache in
 * terms of the desirability of retaining some specified data about a specified source.
 */
class RetentionPriority extends Enum<RetentionPriority> {
  /**
   * A priority indicating that a given piece of data can be removed from the cache without
   * reservation.
   */
  static final RetentionPriority LOW = new RetentionPriority('LOW', 0);

  /**
   * A priority indicating that a given piece of data should not be removed from the cache unless
   * there are no sources for which the corresponding data has a lower priority. Currently used for
   * data that is needed in order to finish some outstanding analysis task.
   */
  static final RetentionPriority MEDIUM = new RetentionPriority('MEDIUM', 1);

  /**
   * A priority indicating that a given piece of data should not be removed from the cache.
   * Currently used for data related to a priority source.
   */
  static final RetentionPriority HIGH = new RetentionPriority('HIGH', 2);

  static final List<RetentionPriority> values = [LOW, MEDIUM, HIGH];

  RetentionPriority(String name, int ordinal) : super(name, ordinal);
}

/**
 * The interface `SourceEntry` defines the behavior of objects that maintain the information
 * cached by an analysis context about an individual source, no matter what kind of source it is.
 *
 * Source entries should be treated as if they were immutable unless a writable copy of the entry
 * has been obtained and has not yet been made visible to other threads.
 *
 * @coverage dart.engine
 */
abstract class SourceEntry {
  /**
   * The data descriptor representing the line information.
   */
  static final DataDescriptor<LineInfo> LINE_INFO = new DataDescriptor<LineInfo>("SourceEntry.LINE_INFO");

  /**
   * Return the exception that caused one or more values to have a state of [CacheState#ERROR]
   * .
   *
   * @return the exception that caused one or more values to be uncomputable
   */
  AnalysisException get exception;

  /**
   * Return the kind of the source, or `null` if the kind is not currently cached.
   *
   * @return the kind of the source
   */
  SourceKind get kind;

  /**
   * Return the most recent time at which the state of the source matched the state represented by
   * this entry.
   *
   * @return the modification time of this entry
   */
  int get modificationTime;

  /**
   * Return the state of the data represented by the given descriptor.
   *
   * @param descriptor the descriptor representing the data whose state is to be returned
   * @return the state of the data represented by the given descriptor
   */
  CacheState getState(DataDescriptor descriptor);

  /**
   * Return the value of the data represented by the given descriptor, or `null` if the data
   * represented by the descriptor is not in the cache.
   *
   * @param descriptor the descriptor representing which data is to be returned
   * @return the value of the data represented by the given descriptor
   */
  Object getValue(DataDescriptor descriptor);

  /**
   * Return a new entry that is initialized to the same state as this entry but that can be
   * modified.
   *
   * @return a writable copy of this entry
   */
  SourceEntryImpl get writableCopy;
}

/**
 * Instances of the abstract class `SourceEntryImpl` implement the behavior common to all
 * [SourceEntry].
 *
 * @coverage dart.engine
 */
abstract class SourceEntryImpl implements SourceEntry {
  /**
   * The most recent time at which the state of the source matched the state represented by this
   * entry.
   */
  int _modificationTime = 0;

  /**
   * The exception that caused one or more values to have a state of [CacheState#ERROR].
   */
  AnalysisException _exception;

  /**
   * The state of the cached line information.
   */
  CacheState _lineInfoState = CacheState.INVALID;

  /**
   * The line information computed for the source, or `null` if the line information is not
   * currently cached.
   */
  LineInfo _lineInfo;

  /**
   * Return the exception that caused one or more values to have a state of [CacheState#ERROR]
   * .
   *
   * @return the exception that caused one or more values to be uncomputable
   */
  AnalysisException get exception => _exception;

  int get modificationTime => _modificationTime;

  CacheState getState(DataDescriptor descriptor) {
    if (identical(descriptor, SourceEntry.LINE_INFO)) {
      return _lineInfoState;
    } else {
      throw new IllegalArgumentException("Invalid descriptor: ${descriptor}");
    }
  }

  Object getValue(DataDescriptor descriptor) {
    if (identical(descriptor, SourceEntry.LINE_INFO)) {
      return _lineInfo as Object;
    } else {
      throw new IllegalArgumentException("Invalid descriptor: ${descriptor}");
    }
  }

  /**
   * Set the exception that caused one or more values to have a state of [CacheState#ERROR] to
   * the given exception.
   *
   * @param exception the exception that caused one or more values to be uncomputable
   */
  void set exception(AnalysisException exception) {
    this._exception = exception;
  }

  /**
   * Set the most recent time at which the state of the source matched the state represented by this
   * entry to the given time.
   *
   * @param time the new modification time of this entry
   */
  void set modificationTime(int time) {
    _modificationTime = time;
  }

  /**
   * Set the state of the data represented by the given descriptor to the given state.
   *
   * @param descriptor the descriptor representing the data whose state is to be set
   * @param the new state of the data represented by the given descriptor
   */
  void setState(DataDescriptor descriptor, CacheState state) {
    if (identical(descriptor, SourceEntry.LINE_INFO)) {
      _lineInfo = updatedValue(state, _lineInfo, null);
      _lineInfoState = state;
    } else {
      throw new IllegalArgumentException("Invalid descriptor: ${descriptor}");
    }
  }

  /**
   * Set the value of the data represented by the given descriptor to the given value.
   *
   * @param descriptor the descriptor representing the data whose value is to be set
   * @param value the new value of the data represented by the given descriptor
   */
  void setValue(DataDescriptor descriptor, Object value) {
    if (identical(descriptor, SourceEntry.LINE_INFO)) {
      _lineInfo = value as LineInfo;
      _lineInfoState = CacheState.VALID;
    } else {
      throw new IllegalArgumentException("Invalid descriptor: ${descriptor}");
    }
  }

  String toString() {
    JavaStringBuilder builder = new JavaStringBuilder();
    writeOn(builder);
    return builder.toString();
  }

  /**
   * Copy the information from the given cache entry.
   *
   * @param entry the cache entry from which information will be copied
   */
  void copyFrom(SourceEntryImpl entry) {
    _modificationTime = entry._modificationTime;
    _lineInfoState = entry._lineInfoState;
    _lineInfo = entry._lineInfo;
  }

  /**
   * Given that some data is being transitioned to the given state, return the value that should be
   * kept in the cache.
   *
   * @param state the state to which the data is being transitioned
   * @param currentValue the value of the data before the transition
   * @param defaultValue the value to be used if the current value is to be removed from the cache
   * @return the value of the data that should be kept in the cache
   */
  Object updatedValue(CacheState state, Object currentValue, Object defaultValue) {
    if (identical(state, CacheState.VALID)) {
      throw new IllegalArgumentException("Use setValue() to set the state to VALID");
    } else if (identical(state, CacheState.IN_PROCESS)) {
      return currentValue;
    }
    return defaultValue;
  }

  /**
   * Write a textual representation of this entry to the given builder. The result will only be used
   * for debugging purposes.
   *
   * @param builder the builder to which the text should be written
   */
  void writeOn(JavaStringBuilder builder) {
    builder.append("time = ");
    builder.append(_modificationTime.toRadixString(16));
    builder.append("; lineInfo = ");
    builder.append(_lineInfoState);
  }
}

/**
 * Implementation of the [AnalysisContentStatistics].
 */
class AnalysisContentStatisticsImpl implements AnalysisContentStatistics {
  Map<String, AnalysisContentStatistics_CacheRow> _dataMap = new Map<String, AnalysisContentStatistics_CacheRow>();

  Set<AnalysisException> _exceptions = new Set<AnalysisException>();

  List<AnalysisContentStatistics_CacheRow> get cacheRows {
    Iterable<AnalysisContentStatistics_CacheRow> items = _dataMap.values;
    return new List.from(items);
  }

  List<AnalysisException> get exceptions => new List.from(_exceptions);

  void putCacheItem(DartEntry dartEntry, DataDescriptor descriptor) {
    putCacheItem3(dartEntry, descriptor, dartEntry.getState(descriptor));
  }

  void putCacheItem2(DartEntry dartEntry, Source librarySource, DataDescriptor descriptor) {
    putCacheItem3(dartEntry, descriptor, dartEntry.getState2(descriptor, librarySource));
  }

  void putCacheItem3(SourceEntry dartEntry, DataDescriptor rowDesc, CacheState state) {
    String rowName = rowDesc.toString();
    AnalysisContentStatisticsImpl_CacheRowImpl row = _dataMap[rowName] as AnalysisContentStatisticsImpl_CacheRowImpl;
    if (row == null) {
      row = new AnalysisContentStatisticsImpl_CacheRowImpl(rowName);
      _dataMap[rowName] = row;
    }
    row.incState(state);
    if (identical(state, CacheState.ERROR)) {
      AnalysisException exception = dartEntry.exception;
      if (exception != null) {
        _exceptions.add(exception);
      }
    }
  }
}

class AnalysisContentStatisticsImpl_CacheRowImpl implements AnalysisContentStatistics_CacheRow {
  String _name;

  int _errorCount = 0;

  int _flushedCount = 0;

  int _inProcessCount = 0;

  int _invalidCount = 0;

  int _validCount = 0;

  AnalysisContentStatisticsImpl_CacheRowImpl(String name) {
    this._name = name;
  }

  bool operator ==(Object obj) => obj is AnalysisContentStatisticsImpl_CacheRowImpl && (obj as AnalysisContentStatisticsImpl_CacheRowImpl)._name == _name;

  int get errorCount => _errorCount;

  int get flushedCount => _flushedCount;

  int get inProcessCount => _inProcessCount;

  int get invalidCount => _invalidCount;

  String get name => _name;

  int get validCount => _validCount;

  int get hashCode => _name.hashCode;

  void incState(CacheState state) {
    if (identical(state, CacheState.ERROR)) {
      _errorCount++;
    }
    if (identical(state, CacheState.FLUSHED)) {
      _flushedCount++;
    }
    if (identical(state, CacheState.IN_PROCESS)) {
      _inProcessCount++;
    }
    if (identical(state, CacheState.INVALID)) {
      _invalidCount++;
    }
    if (identical(state, CacheState.VALID)) {
      _validCount++;
    }
  }
}

/**
 * Instances of the class `AnalysisContextImpl` implement an [AnalysisContext].
 *
 * @coverage dart.engine
 */
class AnalysisContextImpl implements InternalAnalysisContext {
  /**
   * The difference between the maximum cache size and the maximum priority order size. The priority
   * list must be capped so that it is less than the cache size. Failure to do so can result in an
   * infinite loop in performAnalysisTask() because re-caching one AST structure can cause another
   * priority source's AST structure to be flushed.
   */
  static int _PRIORITY_ORDER_SIZE_DELTA = 4;

  /**
   * The set of analysis options controlling the behavior of this context.
   */
  AnalysisOptionsImpl _options = new AnalysisOptionsImpl();

  /**
   * The source factory used to create the sources that can be analyzed in this context.
   */
  SourceFactory _sourceFactory;

  /**
   * A table mapping the sources known to the context to the information known about the source.
   */
  AnalysisCache _cache;

  /**
   * An array containing sources for which data should not be flushed.
   */
  List<Source> _priorityOrder = Source.EMPTY_ARRAY;

  /**
   * A table mapping sources to the change notices that are waiting to be returned related to that
   * source.
   */
  Map<Source, ChangeNoticeImpl> _pendingNotices = new Map<Source, ChangeNoticeImpl>();

  /**
   * The object used to synchronize access to all of the caches. The rules related to the use of
   * this lock object are
   *
   * * no analysis work is done while holding the lock, and
   * * no analysis results can be recorded unless we have obtained the lock and validated that the
   * results are for the same version (modification time) of the source as our current cache
   * content.
   *
   */
  Object _cacheLock = new Object();

  /**
   * The object used to record the results of performing an analysis task.
   */
  AnalysisContextImpl_AnalysisTaskResultRecorder _resultRecorder;

  /**
   * Cached information used in incremental analysis or `null` if none. Synchronize against
   * [cacheLock] before accessing this field.
   */
  IncrementalAnalysisCache _incrementalAnalysisCache;

  /**
   * Initialize a newly created analysis context.
   */
  AnalysisContextImpl() : super() {
    _resultRecorder = new AnalysisContextImpl_AnalysisTaskResultRecorder(this);
    _cache = new AnalysisCache(AnalysisOptionsImpl.DEFAULT_CACHE_SIZE, new AnalysisContextImpl_ContextRetentionPolicy(this));
  }

  void addSourceInfo(Source source, SourceEntry info) {
    _cache.put(source, info);
  }

  void applyChanges(ChangeSet changeSet) {
    if (changeSet.isEmpty) {
      return;
    }
    {
      List<Source> removedSources = new List<Source>.from(changeSet.removed3);
      for (SourceContainer container in changeSet.removedContainers) {
        addSourcesInContainer(removedSources, container);
      }
      bool addedDartSource = false;
      for (Source source in changeSet.added3) {
        if (sourceAvailable(source)) {
          addedDartSource = true;
        }
      }
      for (Source source in changeSet.changed3) {
        sourceChanged(source);
      }
      for (Source source in removedSources) {
        sourceRemoved(source);
      }
      if (addedDartSource) {
        for (MapEntry<Source, SourceEntry> mapEntry in _cache.entrySet()) {
          SourceEntry sourceEntry = mapEntry.getValue();
          if (!mapEntry.getKey().isInSystemLibrary && sourceEntry is DartEntry) {
            DartEntryImpl dartCopy = (sourceEntry as DartEntry).writableCopy;
            dartCopy.invalidateAllResolutionInformation();
            mapEntry.setValue(dartCopy);
          }
        }
      }
    }
  }

  String computeDocumentationComment(Element element) {
    if (element == null) {
      return null;
    }
    Source source = element.source;
    if (source == null) {
      return null;
    }
    CompilationUnit unit = parseCompilationUnit(source);
    if (unit == null) {
      return null;
    }
    NodeLocator locator = new NodeLocator.con1(element.nameOffset);
    ASTNode nameNode = locator.searchWithin(unit);
    while (nameNode != null) {
      if (nameNode is AnnotatedNode) {
        Comment comment = (nameNode as AnnotatedNode).documentationComment;
        if (comment == null) {
          return null;
        }
        JavaStringBuilder builder = new JavaStringBuilder();
        List<Token> tokens = comment.tokens;
        for (int i = 0; i < tokens.length; i++) {
          if (i > 0) {
            builder.append('\n');
          }
          builder.append(tokens[i].lexeme);
        }
        return builder.toString();
      }
      nameNode = nameNode.parent;
    }
    return null;
  }

  List<AnalysisError> computeErrors(Source source) {
    bool enableHints = _options.hint;
    SourceEntry sourceEntry = getReadableSourceEntry(source);
    if (sourceEntry is DartEntry) {
      List<AnalysisError> errors = new List<AnalysisError>();
      DartEntry dartEntry = sourceEntry as DartEntry;
      ListUtilities.addAll(errors, getDartParseData(source, dartEntry, DartEntry.PARSE_ERRORS));
      dartEntry = getReadableDartEntry(source);
      if (identical(dartEntry.getValue(DartEntry.SOURCE_KIND), SourceKind.LIBRARY)) {
        ListUtilities.addAll(errors, getDartResolutionData(source, source, dartEntry, DartEntry.RESOLUTION_ERRORS));
        ListUtilities.addAll(errors, getDartVerificationData(source, source, dartEntry, DartEntry.VERIFICATION_ERRORS));
        if (enableHints) {
          ListUtilities.addAll(errors, getDartHintData(source, source, dartEntry, DartEntry.HINTS));
        }
      } else {
        List<Source> libraries = getLibrariesContaining(source);
        for (Source librarySource in libraries) {
          ListUtilities.addAll(errors, getDartResolutionData(source, librarySource, dartEntry, DartEntry.RESOLUTION_ERRORS));
          ListUtilities.addAll(errors, getDartVerificationData(source, librarySource, dartEntry, DartEntry.VERIFICATION_ERRORS));
          if (enableHints) {
            ListUtilities.addAll(errors, getDartHintData(source, librarySource, dartEntry, DartEntry.HINTS));
          }
        }
      }
      if (errors.isEmpty) {
        return AnalysisError.NO_ERRORS;
      }
      return new List.from(errors);
    } else if (sourceEntry is HtmlEntry) {
      HtmlEntry htmlEntry = sourceEntry as HtmlEntry;
      return getHtmlResolutionData2(source, htmlEntry, HtmlEntry.RESOLUTION_ERRORS);
    }
    return AnalysisError.NO_ERRORS;
  }

  List<Source> computeExportedLibraries(Source source) => getDartParseData2(source, DartEntry.EXPORTED_LIBRARIES, Source.EMPTY_ARRAY);

  HtmlElement computeHtmlElement(Source source) => getHtmlResolutionData(source, HtmlEntry.ELEMENT, null);

  List<Source> computeImportedLibraries(Source source) => getDartParseData2(source, DartEntry.IMPORTED_LIBRARIES, Source.EMPTY_ARRAY);

  SourceKind computeKindOf(Source source) {
    SourceEntry sourceEntry = getReadableSourceEntry(source);
    if (sourceEntry == null) {
      return SourceKind.UNKNOWN;
    } else if (sourceEntry is DartEntry) {
      try {
        return getDartParseData(source, sourceEntry as DartEntry, DartEntry.SOURCE_KIND);
      } on AnalysisException catch (exception) {
        return SourceKind.UNKNOWN;
      }
    }
    return sourceEntry.kind;
  }

  LibraryElement computeLibraryElement(Source source) => getDartResolutionData2(source, source, DartEntry.ELEMENT, null);

  LineInfo computeLineInfo(Source source) {
    SourceEntry sourceEntry = getReadableSourceEntry(source);
    if (sourceEntry is HtmlEntry) {
      return getHtmlParseData(source, SourceEntry.LINE_INFO, null);
    } else if (sourceEntry is DartEntry) {
      return getDartParseData2(source, SourceEntry.LINE_INFO, null);
    }
    return null;
  }

  ResolvableCompilationUnit computeResolvableCompilationUnit(Source source) {
    while (true) {
      {
        DartEntry dartEntry = getReadableDartEntry(source);
        if (dartEntry == null) {
          throw new AnalysisException.con1("computeResolvableCompilationUnit for non-Dart: ${source.fullName}");
        }
        if (identical(dartEntry.getState(DartEntry.PARSED_UNIT), CacheState.ERROR)) {
          AnalysisException cause = dartEntry.exception;
          if (cause == null) {
            throw new AnalysisException.con1("Internal error: computeResolvableCompilationUnit could not parse ${source.fullName}");
          } else {
            throw new AnalysisException.con2("Internal error: computeResolvableCompilationUnit could not parse ${source.fullName}", cause);
          }
        }
        DartEntryImpl dartCopy = dartEntry.writableCopy;
        CompilationUnit unit = dartCopy.resolvableCompilationUnit;
        if (unit != null) {
          _cache.put(source, dartCopy);
          return new ResolvableCompilationUnit(dartCopy.modificationTime, unit);
        }
      }
      cacheDartParseData(source, getReadableDartEntry(source), DartEntry.PARSED_UNIT);
    }
  }

  ResolvableHtmlUnit computeResolvableHtmlUnit(Source source) {
    HtmlEntry htmlEntry = getReadableHtmlEntry(source);
    if (htmlEntry == null) {
      throw new AnalysisException.con1("computeResolvableHtmlUnit invoked for non-HTML file: ${source.fullName}");
    }
    htmlEntry = cacheHtmlParseData(source, htmlEntry, HtmlEntry.PARSED_UNIT);
    HtmlUnit unit = htmlEntry.getValue(HtmlEntry.PARSED_UNIT);
    if (unit == null) {
      throw new AnalysisException.con1("Internal error: computeResolvableHtmlUnit could not parse ${source.fullName}");
    }
    return new ResolvableHtmlUnit(htmlEntry.modificationTime, unit);
  }

  AnalysisContext extractContext(SourceContainer container) => extractContextInto(container, AnalysisEngine.instance.createAnalysisContext() as InternalAnalysisContext);

  InternalAnalysisContext extractContextInto(SourceContainer container, InternalAnalysisContext newContext) {
    List<Source> sourcesToRemove = new List<Source>();
    {
      for (MapEntry<Source, SourceEntry> entry in _cache.entrySet()) {
        Source source = entry.getKey();
        if (container.contains(source)) {
          sourcesToRemove.add(source);
          newContext.addSourceInfo(source, entry.getValue().writableCopy);
        }
      }
    }
    return newContext;
  }

  AnalysisOptions get analysisOptions => _options;

  Element getElement(ElementLocation location) {
    try {
      List<String> components = (location as ElementLocationImpl).components;
      Source librarySource = computeSourceFromEncoding(components[0]);
      ElementImpl element = computeLibraryElement(librarySource) as ElementImpl;
      for (int i = 1; i < components.length; i++) {
        if (element == null) {
          return null;
        }
        element = element.getChild(components[i]);
      }
      return element;
    } on AnalysisException catch (exception) {
      return null;
    }
  }

  AnalysisErrorInfo getErrors(Source source) {
    SourceEntry sourceEntry = getReadableSourceEntry(source);
    if (sourceEntry is DartEntry) {
      DartEntry dartEntry = sourceEntry as DartEntry;
      return new AnalysisErrorInfoImpl(dartEntry.allErrors, dartEntry.getValue(SourceEntry.LINE_INFO));
    } else if (sourceEntry is HtmlEntry) {
      HtmlEntry htmlEntry = sourceEntry as HtmlEntry;
      return new AnalysisErrorInfoImpl(htmlEntry.allErrors, htmlEntry.getValue(SourceEntry.LINE_INFO));
    }
    return new AnalysisErrorInfoImpl(AnalysisError.NO_ERRORS, null);
  }

  HtmlElement getHtmlElement(Source source) {
    SourceEntry sourceEntry = getReadableSourceEntry(source);
    if (sourceEntry is HtmlEntry) {
      return (sourceEntry as HtmlEntry).getValue(HtmlEntry.ELEMENT);
    }
    return null;
  }

  List<Source> getHtmlFilesReferencing(Source source) {
    SourceKind sourceKind = getKindOf(source);
    if (sourceKind == null) {
      return Source.EMPTY_ARRAY;
    }
    {
      List<Source> htmlSources = new List<Source>();
      while (true) {
        if (sourceKind == SourceKind.LIBRARY) {
        } else if (sourceKind == SourceKind.PART) {
          List<Source> librarySources = getLibrariesContaining(source);
          for (MapEntry<Source, SourceEntry> entry in _cache.entrySet()) {
            SourceEntry sourceEntry = entry.getValue();
            if (identical(sourceEntry.kind, SourceKind.HTML)) {
              List<Source> referencedLibraries = (sourceEntry as HtmlEntry).getValue(HtmlEntry.REFERENCED_LIBRARIES);
              if (containsAny(referencedLibraries, librarySources)) {
                htmlSources.add(entry.getKey());
              }
            }
          }
        }
        break;
      }
      if (htmlSources.isEmpty) {
        return Source.EMPTY_ARRAY;
      }
      return new List.from(htmlSources);
    }
  }

  List<Source> get htmlSources => getSources(SourceKind.HTML);

  SourceKind getKindOf(Source source) {
    SourceEntry sourceEntry = getReadableSourceEntry(source);
    if (sourceEntry == null) {
      return SourceKind.UNKNOWN;
    }
    return sourceEntry.kind;
  }

  List<Source> get launchableClientLibrarySources {
    List<Source> sources = new List<Source>();
    {
      for (MapEntry<Source, SourceEntry> entry in _cache.entrySet()) {
        Source source = entry.getKey();
        SourceEntry sourceEntry = entry.getValue();
        if (identical(sourceEntry.kind, SourceKind.LIBRARY) && !source.isInSystemLibrary) {
          sources.add(source);
        }
      }
    }
    return new List.from(sources);
  }

  List<Source> get launchableServerLibrarySources {
    List<Source> sources = new List<Source>();
    {
      for (MapEntry<Source, SourceEntry> entry in _cache.entrySet()) {
        Source source = entry.getKey();
        SourceEntry sourceEntry = entry.getValue();
        if (identical(sourceEntry.kind, SourceKind.LIBRARY) && !source.isInSystemLibrary) {
          sources.add(source);
        }
      }
    }
    return new List.from(sources);
  }

  List<Source> getLibrariesContaining(Source source) {
    {
      SourceEntry sourceEntry = _cache.get(source);
      if (sourceEntry == null || sourceEntry.kind != SourceKind.PART) {
        return <Source> [source];
      }
      List<Source> librarySources = new List<Source>();
      for (MapEntry<Source, SourceEntry> entry in _cache.entrySet()) {
        sourceEntry = entry.getValue();
        if (identical(sourceEntry.kind, SourceKind.LIBRARY)) {
          if (contains((sourceEntry as DartEntry).getValue(DartEntry.INCLUDED_PARTS), source)) {
            librarySources.add(entry.getKey());
          }
        }
      }
      if (librarySources.isEmpty) {
        return Source.EMPTY_ARRAY;
      }
      return new List.from(librarySources);
    }
  }

  List<Source> getLibrariesDependingOn(Source librarySource) {
    {
      List<Source> dependentLibraries = new List<Source>();
      for (MapEntry<Source, SourceEntry> entry in _cache.entrySet()) {
        SourceEntry sourceEntry = entry.getValue();
        if (identical(sourceEntry.kind, SourceKind.LIBRARY)) {
          if (contains((sourceEntry as DartEntry).getValue(DartEntry.EXPORTED_LIBRARIES), librarySource)) {
            dependentLibraries.add(entry.getKey());
          }
          if (contains((sourceEntry as DartEntry).getValue(DartEntry.IMPORTED_LIBRARIES), librarySource)) {
            dependentLibraries.add(entry.getKey());
          }
        }
      }
      if (dependentLibraries.isEmpty) {
        return Source.EMPTY_ARRAY;
      }
      return new List.from(dependentLibraries);
    }
  }

  LibraryElement getLibraryElement(Source source) {
    SourceEntry sourceEntry = getReadableSourceEntry(source);
    if (sourceEntry is DartEntry) {
      return (sourceEntry as DartEntry).getValue(DartEntry.ELEMENT);
    }
    return null;
  }

  List<Source> get librarySources => getSources(SourceKind.LIBRARY);

  LineInfo getLineInfo(Source source) {
    SourceEntry sourceEntry = getReadableSourceEntry(source);
    if (sourceEntry != null) {
      return sourceEntry.getValue(SourceEntry.LINE_INFO);
    }
    return null;
  }

  Namespace getPublicNamespace(LibraryElement library) {
    Source source = library.definingCompilationUnit.source;
    DartEntry dartEntry = getReadableDartEntry(source);
    if (dartEntry == null) {
      return null;
    }
    Namespace namespace = null;
    if (identical(dartEntry.getValue(DartEntry.ELEMENT), library)) {
      namespace = dartEntry.getValue(DartEntry.PUBLIC_NAMESPACE);
    }
    if (namespace == null) {
      NamespaceBuilder builder = new NamespaceBuilder();
      namespace = builder.createPublicNamespace(library);
      {
        dartEntry = getReadableDartEntry(source);
        if (dartEntry == null) {
          AnalysisEngine.instance.logger.logError3(new AnalysisException.con1("A Dart file became a non-Dart file: ${source.fullName}"));
          return null;
        }
        if (identical(dartEntry.getValue(DartEntry.ELEMENT), library)) {
          DartEntryImpl dartCopy = getReadableDartEntry(source).writableCopy;
          dartCopy.setValue(DartEntry.PUBLIC_NAMESPACE, namespace);
          _cache.put(source, dartCopy);
        }
      }
    }
    return namespace;
  }

  Namespace getPublicNamespace2(Source source) {
    DartEntry dartEntry = getReadableDartEntry(source);
    if (dartEntry == null) {
      return null;
    }
    Namespace namespace = dartEntry.getValue(DartEntry.PUBLIC_NAMESPACE);
    if (namespace == null) {
      LibraryElement library = computeLibraryElement(source);
      if (library == null) {
        return null;
      }
      NamespaceBuilder builder = new NamespaceBuilder();
      namespace = builder.createPublicNamespace(library);
      {
        dartEntry = getReadableDartEntry(source);
        if (dartEntry == null) {
          throw new AnalysisException.con1("A Dart file became a non-Dart file: ${source.fullName}");
        }
        if (identical(dartEntry.getValue(DartEntry.ELEMENT), library)) {
          DartEntryImpl dartCopy = getReadableDartEntry(source).writableCopy;
          dartCopy.setValue(DartEntry.PUBLIC_NAMESPACE, namespace);
          _cache.put(source, dartCopy);
        }
      }
    }
    return namespace;
  }

  List<Source> get refactoringUnsafeSources {
    List<Source> sources = new List<Source>();
    {
      for (MapEntry<Source, SourceEntry> entry in _cache.entrySet()) {
        SourceEntry sourceEntry = entry.getValue();
        if (sourceEntry is DartEntry) {
          if (!(sourceEntry as DartEntry).isRefactoringSafe) {
            sources.add(entry.getKey());
          }
        }
      }
    }
    return new List.from(sources);
  }

  CompilationUnit getResolvedCompilationUnit(Source unitSource, LibraryElement library) {
    if (library == null) {
      return null;
    }
    return getResolvedCompilationUnit2(unitSource, library.source);
  }

  CompilationUnit getResolvedCompilationUnit2(Source unitSource, Source librarySource) {
    SourceEntry sourceEntry = getReadableSourceEntry(unitSource);
    if (sourceEntry is DartEntry) {
      return (sourceEntry as DartEntry).getValue2(DartEntry.RESOLVED_UNIT, librarySource);
    }
    return null;
  }

  SourceFactory get sourceFactory => _sourceFactory;

  /**
   * Return a list of the sources that would be processed by [performAnalysisTask]. This
   * method duplicates, and must therefore be kept in sync with, [getNextTaskAnalysisTask].
   * This method is intended to be used for testing purposes only.
   *
   * @return a list of the sources that would be processed by [performAnalysisTask]
   */
  List<Source> get sourcesNeedingProcessing {
    Set<Source> sources = new Set<Source>();
    {
      bool hintsEnabled = _options.hint;
      for (Source source in _priorityOrder) {
        getSourcesNeedingProcessing2(source, _cache.get(source), true, hintsEnabled, sources);
      }
      for (MapEntry<Source, SourceEntry> entry in _cache.entrySet()) {
        getSourcesNeedingProcessing2(entry.getKey(), entry.getValue(), false, hintsEnabled, sources);
      }
    }
    return new List<Source>.from(sources);
  }

  AnalysisContentStatistics get statistics {
    AnalysisContentStatisticsImpl statistics = new AnalysisContentStatisticsImpl();
    {
      for (MapEntry<Source, SourceEntry> mapEntry in _cache.entrySet()) {
        SourceEntry entry = mapEntry.getValue();
        if (entry is DartEntry) {
          Source source = mapEntry.getKey();
          DartEntry dartEntry = entry as DartEntry;
          SourceKind kind = dartEntry.getValue(DartEntry.SOURCE_KIND);
          statistics.putCacheItem(dartEntry, DartEntry.PARSE_ERRORS);
          statistics.putCacheItem(dartEntry, DartEntry.PARSED_UNIT);
          statistics.putCacheItem(dartEntry, DartEntry.SOURCE_KIND);
          statistics.putCacheItem(dartEntry, SourceEntry.LINE_INFO);
          if (identical(kind, SourceKind.LIBRARY)) {
            statistics.putCacheItem(dartEntry, DartEntry.ELEMENT);
            statistics.putCacheItem(dartEntry, DartEntry.EXPORTED_LIBRARIES);
            statistics.putCacheItem(dartEntry, DartEntry.IMPORTED_LIBRARIES);
            statistics.putCacheItem(dartEntry, DartEntry.INCLUDED_PARTS);
            statistics.putCacheItem(dartEntry, DartEntry.IS_CLIENT);
            statistics.putCacheItem(dartEntry, DartEntry.IS_LAUNCHABLE);
          }
          List<Source> librarySources = getLibrariesContaining(source);
          for (Source librarySource in librarySources) {
            statistics.putCacheItem2(dartEntry, librarySource, DartEntry.HINTS);
            statistics.putCacheItem2(dartEntry, librarySource, DartEntry.RESOLUTION_ERRORS);
            statistics.putCacheItem2(dartEntry, librarySource, DartEntry.RESOLVED_UNIT);
            statistics.putCacheItem2(dartEntry, librarySource, DartEntry.VERIFICATION_ERRORS);
          }
        }
      }
    }
    return statistics;
  }

  TimestampedData<CompilationUnit> internalResolveCompilationUnit(Source unitSource, LibraryElement libraryElement) {
    DartEntry dartEntry = getReadableDartEntry(unitSource);
    if (dartEntry == null) {
      throw new AnalysisException.con1("internalResolveCompilationUnit invoked for non-Dart file: ${unitSource.fullName}");
    }
    Source librarySource = libraryElement.source;
    dartEntry = cacheDartResolutionData(unitSource, librarySource, dartEntry, DartEntry.RESOLVED_UNIT);
    return new TimestampedData<CompilationUnit>(dartEntry.modificationTime, dartEntry.getValue2(DartEntry.RESOLVED_UNIT, librarySource));
  }

  bool isClientLibrary(Source librarySource) {
    SourceEntry sourceEntry = getReadableSourceEntry(librarySource);
    if (sourceEntry is DartEntry) {
      DartEntry dartEntry = sourceEntry as DartEntry;
      return dartEntry.getValue(DartEntry.IS_CLIENT) && dartEntry.getValue(DartEntry.IS_LAUNCHABLE);
    }
    return false;
  }

  bool isServerLibrary(Source librarySource) {
    SourceEntry sourceEntry = getReadableSourceEntry(librarySource);
    if (sourceEntry is DartEntry) {
      DartEntry dartEntry = sourceEntry as DartEntry;
      return !dartEntry.getValue(DartEntry.IS_CLIENT) && dartEntry.getValue(DartEntry.IS_LAUNCHABLE);
    }
    return false;
  }

  void mergeContext(AnalysisContext context) {
    if (context is InstrumentedAnalysisContextImpl) {
      context = (context as InstrumentedAnalysisContextImpl).basis;
    }
    if (context is! AnalysisContextImpl) {
      return;
    }
    {
      for (MapEntry<Source, SourceEntry> entry in (context as AnalysisContextImpl)._cache.entrySet()) {
        Source newSource = entry.getKey();
        SourceEntry existingEntry = getReadableSourceEntry(newSource);
        if (existingEntry == null) {
          _cache.put(newSource, entry.getValue().writableCopy);
        } else {
        }
      }
    }
  }

  CompilationUnit parseCompilationUnit(Source source) => getDartParseData2(source, DartEntry.PARSED_UNIT, null);

  HtmlUnit parseHtmlUnit(Source source) => getHtmlParseData(source, HtmlEntry.PARSED_UNIT, null);

  AnalysisResult performAnalysisTask() {
    int getStart = JavaSystem.currentTimeMillis();
    AnalysisTask task = nextTaskAnalysisTask;
    int getEnd = JavaSystem.currentTimeMillis();
    if (task == null) {
      return new AnalysisResult(getChangeNotices(true), getEnd - getStart, null, -1);
    }
    int performStart = JavaSystem.currentTimeMillis();
    try {
      task.perform(_resultRecorder);
    } on AnalysisException catch (exception) {
      if (exception.cause is! JavaIOException) {
        AnalysisEngine.instance.logger.logError2("Internal error while performing the task: ${task}", exception);
      }
    }
    int performEnd = JavaSystem.currentTimeMillis();
    return new AnalysisResult(getChangeNotices(false), getEnd - getStart, task.runtimeType.toString(), performEnd - performStart);
  }

  void recordLibraryElements(Map<Source, LibraryElement> elementMap) {
    {
      Source htmlSource = _sourceFactory.forUri(DartSdk.DART_HTML);
      for (MapEntry<Source, LibraryElement> entry in getMapEntrySet(elementMap)) {
        Source librarySource = entry.getKey();
        LibraryElement library = entry.getValue();
        DartEntry dartEntry = getReadableDartEntry(librarySource);
        if (dartEntry != null) {
          DartEntryImpl dartCopy = dartEntry.writableCopy;
          recordElementData(dartCopy, library, htmlSource);
          _cache.put(librarySource, dartCopy);
        }
      }
    }
  }

  CompilationUnit resolveCompilationUnit(Source unitSource, LibraryElement library) {
    if (library == null) {
      return null;
    }
    return resolveCompilationUnit2(unitSource, library.source);
  }

  CompilationUnit resolveCompilationUnit2(Source unitSource, Source librarySource) => getDartResolutionData2(unitSource, librarySource, DartEntry.RESOLVED_UNIT, null);

  HtmlUnit resolveHtmlUnit(Source htmlSource) => parseHtmlUnit(htmlSource);

  void set analysisOptions(AnalysisOptions options) {
    {
      bool needsRecompute = this._options.analyzeFunctionBodies != options.analyzeFunctionBodies || this._options.dart2jsHint != options.dart2jsHint || (this._options.hint && !options.hint) || this._options.preserveComments != options.preserveComments;
      int cacheSize = options.cacheSize;
      if (this._options.cacheSize != cacheSize) {
        this._options.cacheSize = cacheSize;
        _cache.maxCacheSize = cacheSize;
        int maxPriorityOrderSize = cacheSize - _PRIORITY_ORDER_SIZE_DELTA;
        if (_priorityOrder.length > maxPriorityOrderSize) {
          List<Source> newPriorityOrder = new List<Source>(maxPriorityOrderSize);
          JavaSystem.arraycopy(_priorityOrder, 0, newPriorityOrder, 0, maxPriorityOrderSize);
          _priorityOrder = newPriorityOrder;
        }
      }
      this._options.analyzeFunctionBodies = options.analyzeFunctionBodies;
      this._options.dart2jsHint = options.dart2jsHint;
      this._options.hint = options.hint;
      this._options.incremental = options.incremental;
      this._options.preserveComments = options.preserveComments;
      if (needsRecompute) {
        invalidateAllResolutionInformation();
      }
    }
  }

  void set analysisPriorityOrder(List<Source> sources) {
    {
      if (sources == null || sources.isEmpty) {
        _priorityOrder = Source.EMPTY_ARRAY;
      } else {
        while (sources.remove(null)) {
        }
        if (sources.isEmpty) {
          _priorityOrder = Source.EMPTY_ARRAY;
        }
        int count = Math.min(sources.length, _options.cacheSize - _PRIORITY_ORDER_SIZE_DELTA);
        _priorityOrder = new List<Source>(count);
        for (int i = 0; i < count; i++) {
          _priorityOrder[i] = sources[i];
        }
      }
    }
  }

  void setChangedContents(Source source, String contents, int offset, int oldLength, int newLength) {
    {
      String originalContents = _sourceFactory.setContents(source, contents);
      if (contents != null) {
        if (contents != originalContents) {
          if (_options.incremental) {
            _incrementalAnalysisCache = IncrementalAnalysisCache.update(_incrementalAnalysisCache, source, originalContents, contents, offset, oldLength, newLength, getReadableSourceEntry(source));
          }
          sourceChanged(source);
        }
      } else if (originalContents != null) {
        _incrementalAnalysisCache = IncrementalAnalysisCache.clear(_incrementalAnalysisCache, source);
        sourceChanged(source);
      }
    }
  }

  void setContents(Source source, String contents) {
    {
      String originalContents = _sourceFactory.setContents(source, contents);
      if (contents != null) {
        if (contents != originalContents) {
          _incrementalAnalysisCache = IncrementalAnalysisCache.clear(_incrementalAnalysisCache, source);
          sourceChanged(source);
        }
      } else if (originalContents != null) {
        _incrementalAnalysisCache = IncrementalAnalysisCache.clear(_incrementalAnalysisCache, source);
        sourceChanged(source);
      }
    }
  }

  void set sourceFactory(SourceFactory factory) {
    {
      if (identical(_sourceFactory, factory)) {
        return;
      } else if (factory.context != null) {
        throw new IllegalStateException("Source factories cannot be shared between contexts");
      }
      if (_sourceFactory != null) {
        _sourceFactory.context = null;
      }
      factory.context = this;
      _sourceFactory = factory;
      invalidateAllResolutionInformation();
    }
  }

  Iterable<Source> sourcesToResolve(List<Source> changedSources) {
    List<Source> librarySources = new List<Source>();
    for (Source source in changedSources) {
      if (identical(computeKindOf(source), SourceKind.LIBRARY)) {
        librarySources.add(source);
      }
    }
    return librarySources;
  }

  /**
   * Add all of the sources contained in the given source container to the given list of sources.
   *
   * Note: This method must only be invoked while we are synchronized on [cacheLock].
   *
   * @param sources the list to which sources are to be added
   * @param container the source container containing the sources to be added to the list
   */
  void addSourcesInContainer(List<Source> sources, SourceContainer container) {
    for (MapEntry<Source, SourceEntry> entry in _cache.entrySet()) {
      Source source = entry.getKey();
      if (container.contains(source)) {
        sources.add(source);
      }
    }
  }

  /**
   * Return `true` if the modification times of the sources used by the given library resolver
   * to resolve one or more libraries are consistent with the modification times in the cache.
   *
   * @param resolver the library resolver used to resolve one or more libraries
   * @return `true` if we should record the results of the resolution
   * @throws AnalysisException if any of the modification times could not be determined (this should
   *           not happen)
   */
  bool allModificationTimesMatch(Set<Library> resolvedLibraries) {
    bool allTimesMatch = true;
    for (Library library in resolvedLibraries) {
      for (Source source in library.compilationUnitSources) {
        DartEntry dartEntry = getReadableDartEntry(source);
        if (dartEntry == null) {
          throw new AnalysisException.con1("Internal error: attempting to reolve non-Dart file as a Dart file: ${source.fullName}");
        }
        int sourceTime = source.modificationStamp;
        int resultTime = library.getModificationTime(source);
        if (sourceTime != resultTime) {
          sourceChanged(source);
          allTimesMatch = false;
        }
      }
    }
    return allTimesMatch;
  }

  /**
   * Given a source for a Dart file and the library that contains it, return a cache entry in which
   * the data represented by the given descriptor is available. This method assumes that the data
   * can be produced by generating hints for the library if the data is not already cached.
   *
   * @param unitSource the source representing the Dart file
   * @param librarySource the source representing the library containing the Dart file
   * @param dartEntry the cache entry associated with the Dart file
   * @param descriptor the descriptor representing the data to be returned
   * @return a cache entry containing the required data
   * @throws AnalysisException if data could not be returned because the source could not be parsed
   */
  DartEntry cacheDartHintData(Source unitSource, Source librarySource, DartEntry dartEntry, DataDescriptor descriptor) {
    CacheState state = dartEntry.getState2(descriptor, librarySource);
    while (state != CacheState.ERROR && state != CacheState.VALID) {
      dartEntry = new GenerateDartHintsTask(this, getLibraryElement(librarySource)).perform(_resultRecorder) as DartEntry;
      state = dartEntry.getState2(descriptor, librarySource);
    }
    return dartEntry;
  }

  /**
   * Given a source for a Dart file, return a cache entry in which the data represented by the given
   * descriptor is available. This method assumes that the data can be produced by parsing the
   * source if it is not already cached.
   *
   * @param source the source representing the Dart file
   * @param dartEntry the cache entry associated with the Dart file
   * @param descriptor the descriptor representing the data to be returned
   * @return a cache entry containing the required data
   * @throws AnalysisException if data could not be returned because the source could not be
   *           resolved
   */
  DartEntry cacheDartParseData(Source source, DartEntry dartEntry, DataDescriptor descriptor) {
    if (identical(descriptor, DartEntry.PARSED_UNIT)) {
      CompilationUnit unit = dartEntry.anyParsedCompilationUnit;
      if (unit != null) {
        return dartEntry;
      }
    }
    CacheState state = dartEntry.getState(descriptor);
    while (state != CacheState.ERROR && state != CacheState.VALID) {
      dartEntry = new ParseDartTask(this, source).perform(_resultRecorder) as DartEntry;
      state = dartEntry.getState(descriptor);
    }
    return dartEntry;
  }

  /**
   * Given a source for a Dart file and the library that contains it, return a cache entry in which
   * the data represented by the given descriptor is available. This method assumes that the data
   * can be produced by resolving the source in the context of the library if it is not already
   * cached.
   *
   * @param unitSource the source representing the Dart file
   * @param librarySource the source representing the library containing the Dart file
   * @param dartEntry the cache entry associated with the Dart file
   * @param descriptor the descriptor representing the data to be returned
   * @return a cache entry containing the required data
   * @throws AnalysisException if data could not be returned because the source could not be parsed
   */
  DartEntry cacheDartResolutionData(Source unitSource, Source librarySource, DartEntry dartEntry, DataDescriptor descriptor) {
    CacheState state = (identical(descriptor, DartEntry.ELEMENT)) ? dartEntry.getState(descriptor) : dartEntry.getState2(descriptor, librarySource);
    while (state != CacheState.ERROR && state != CacheState.VALID) {
      dartEntry = new ResolveDartLibraryTask(this, unitSource, librarySource).perform(_resultRecorder) as DartEntry;
      state = (identical(descriptor, DartEntry.ELEMENT)) ? dartEntry.getState(descriptor) : dartEntry.getState2(descriptor, librarySource);
    }
    return dartEntry;
  }

  /**
   * Given a source for a Dart file and the library that contains it, return a cache entry in which
   * the data represented by the given descriptor is available. This method assumes that the data
   * can be produced by verifying the source in the given library if the data is not already cached.
   *
   * @param unitSource the source representing the Dart file
   * @param librarySource the source representing the library containing the Dart file
   * @param dartEntry the cache entry associated with the Dart file
   * @param descriptor the descriptor representing the data to be returned
   * @return a cache entry containing the required data
   * @throws AnalysisException if data could not be returned because the source could not be parsed
   */
  DartEntry cacheDartVerificationData(Source unitSource, Source librarySource, DartEntry dartEntry, DataDescriptor descriptor) {
    CacheState state = dartEntry.getState2(descriptor, librarySource);
    while (state != CacheState.ERROR && state != CacheState.VALID) {
      dartEntry = new GenerateDartErrorsTask(this, unitSource, getLibraryElement(librarySource)).perform(_resultRecorder) as DartEntry;
      state = dartEntry.getState2(descriptor, librarySource);
    }
    return dartEntry;
  }

  /**
   * Given a source for an HTML file, return a cache entry in which all of the data represented by
   * the given descriptors is available. This method assumes that the data can be produced by
   * parsing the source if it is not already cached.
   *
   * @param source the source representing the HTML file
   * @param htmlEntry the cache entry associated with the HTML file
   * @param descriptor the descriptor representing the data to be returned
   * @return a cache entry containing the required data
   * @throws AnalysisException if data could not be returned because the source could not be
   *           resolved
   */
  HtmlEntry cacheHtmlParseData(Source source, HtmlEntry htmlEntry, DataDescriptor descriptor) {
    CacheState state = htmlEntry.getState(descriptor);
    while (state != CacheState.ERROR && state != CacheState.VALID) {
      htmlEntry = new ParseHtmlTask(this, source).perform(_resultRecorder) as HtmlEntry;
      state = htmlEntry.getState(descriptor);
    }
    return htmlEntry;
  }

  /**
   * Given a source for an HTML file, return a cache entry in which the the data represented by the
   * given descriptor is available. This method assumes that the data can be produced by resolving
   * the source if it is not already cached.
   *
   * @param source the source representing the HTML file
   * @param dartEntry the cache entry associated with the HTML file
   * @param descriptor the descriptor representing the data to be returned
   * @return a cache entry containing the required data
   * @throws AnalysisException if data could not be returned because the source could not be
   *           resolved
   */
  HtmlEntry cacheHtmlResolutionData(Source source, HtmlEntry htmlEntry, DataDescriptor descriptor) {
    CacheState state = htmlEntry.getState(descriptor);
    while (state != CacheState.ERROR && state != CacheState.VALID) {
      htmlEntry = new ResolveHtmlTask(this, source).perform(_resultRecorder) as HtmlEntry;
      state = htmlEntry.getState(descriptor);
    }
    return htmlEntry;
  }

  /**
   * Given the encoded form of a source, use the source factory to reconstitute the original source.
   *
   * @param encoding the encoded form of a source
   * @return the source represented by the encoding
   */
  Source computeSourceFromEncoding(String encoding) {
    {
      return _sourceFactory.fromEncoding(encoding);
    }
  }

  /**
   * Return `true` if the given array of sources contains the given source.
   *
   * @param sources the sources being searched
   * @param targetSource the source being searched for
   * @return `true` if the given source is in the array
   */
  bool contains(List<Source> sources, Source targetSource) {
    for (Source source in sources) {
      if (source == targetSource) {
        return true;
      }
    }
    return false;
  }

  /**
   * Return `true` if the given array of sources contains any of the given target sources.
   *
   * @param sources the sources being searched
   * @param targetSources the sources being searched for
   * @return `true` if any of the given target sources are in the array
   */
  bool containsAny(List<Source> sources, List<Source> targetSources) {
    for (Source targetSource in targetSources) {
      if (contains(sources, targetSource)) {
        return true;
      }
    }
    return false;
  }

  /**
   * Create a source information object suitable for the given source. Return the source information
   * object that was created, or `null` if the source should not be tracked by this context.
   *
   * @param source the source for which an information object is being created
   * @return the source information object that was created
   */
  SourceEntry createSourceEntry(Source source) {
    String name = source.shortName;
    if (AnalysisEngine.isHtmlFileName(name)) {
      HtmlEntryImpl htmlEntry = new HtmlEntryImpl();
      htmlEntry.modificationTime = source.modificationStamp;
      _cache.put(source, htmlEntry);
      return htmlEntry;
    } else {
      DartEntryImpl dartEntry = new DartEntryImpl();
      dartEntry.modificationTime = source.modificationStamp;
      _cache.put(source, dartEntry);
      return dartEntry;
    }
  }

  /**
   * Return an array containing all of the change notices that are waiting to be returned. If there
   * are no notices, then return either `null` or an empty array, depending on the value of
   * the argument.
   *
   * @param nullIfEmpty `true` if `null` should be returned when there are no notices
   * @return the change notices that are waiting to be returned
   */
  List<ChangeNotice> getChangeNotices(bool nullIfEmpty) {
    {
      if (_pendingNotices.isEmpty) {
        if (nullIfEmpty) {
          return null;
        }
        return ChangeNoticeImpl.EMPTY_ARRAY;
      }
      List<ChangeNotice> notices = new List.from(_pendingNotices.values);
      _pendingNotices.clear();
      return notices;
    }
  }

  /**
   * Given a source for a Dart file and the library that contains it, return the data represented by
   * the given descriptor that is associated with that source. This method assumes that the data can
   * be produced by generating hints for the library if it is not already cached.
   *
   * @param unitSource the source representing the Dart file
   * @param librarySource the source representing the library containing the Dart file
   * @param dartEntry the entry representing the Dart file
   * @param descriptor the descriptor representing the data to be returned
   * @return the requested data about the given source
   * @throws AnalysisException if data could not be returned because the source could not be
   *           resolved
   */
  Object getDartHintData(Source unitSource, Source librarySource, DartEntry dartEntry, DataDescriptor descriptor) {
    dartEntry = cacheDartHintData(unitSource, librarySource, dartEntry, descriptor);
    if (identical(descriptor, DartEntry.ELEMENT)) {
      return dartEntry.getValue(descriptor);
    }
    return dartEntry.getValue2(descriptor, librarySource);
  }

  /**
   * Given a source for a Dart file, return the data represented by the given descriptor that is
   * associated with that source. This method assumes that the data can be produced by parsing the
   * source if it is not already cached.
   *
   * @param source the source representing the Dart file
   * @param dartEntry the cache entry associated with the Dart file
   * @param descriptor the descriptor representing the data to be returned
   * @return the requested data about the given source
   * @throws AnalysisException if data could not be returned because the source could not be parsed
   */
  Object getDartParseData(Source source, DartEntry dartEntry, DataDescriptor descriptor) {
    dartEntry = cacheDartParseData(source, dartEntry, descriptor);
    if (identical(descriptor, DartEntry.PARSED_UNIT)) {
      return dartEntry.anyParsedCompilationUnit as Object;
    }
    return dartEntry.getValue(descriptor);
  }

  /**
   * Given a source for a Dart file, return the data represented by the given descriptor that is
   * associated with that source, or the given default value if the source is not a Dart file. This
   * method assumes that the data can be produced by parsing the source if it is not already cached.
   *
   * @param source the source representing the Dart file
   * @param descriptor the descriptor representing the data to be returned
   * @param defaultValue the value to be returned if the source is not a Dart file
   * @return the requested data about the given source
   * @throws AnalysisException if data could not be returned because the source could not be parsed
   */
  Object getDartParseData2(Source source, DataDescriptor descriptor, Object defaultValue) {
    DartEntry dartEntry = getReadableDartEntry(source);
    if (dartEntry == null) {
      return defaultValue;
    }
    return getDartParseData(source, dartEntry, descriptor);
  }

  /**
   * Given a source for a Dart file and the library that contains it, return the data represented by
   * the given descriptor that is associated with that source. This method assumes that the data can
   * be produced by resolving the source in the context of the library if it is not already cached.
   *
   * @param unitSource the source representing the Dart file
   * @param librarySource the source representing the library containing the Dart file
   * @param dartEntry the entry representing the Dart file
   * @param descriptor the descriptor representing the data to be returned
   * @return the requested data about the given source
   * @throws AnalysisException if data could not be returned because the source could not be
   *           resolved
   */
  Object getDartResolutionData(Source unitSource, Source librarySource, DartEntry dartEntry, DataDescriptor descriptor) {
    dartEntry = cacheDartResolutionData(unitSource, librarySource, dartEntry, descriptor);
    if (identical(descriptor, DartEntry.ELEMENT)) {
      return dartEntry.getValue(descriptor);
    }
    return dartEntry.getValue2(descriptor, librarySource);
  }

  /**
   * Given a source for a Dart file and the library that contains it, return the data represented by
   * the given descriptor that is associated with that source, or the given default value if the
   * source is not a Dart file. This method assumes that the data can be produced by resolving the
   * source in the context of the library if it is not already cached.
   *
   * @param unitSource the source representing the Dart file
   * @param librarySource the source representing the library containing the Dart file
   * @param descriptor the descriptor representing the data to be returned
   * @param defaultValue the value to be returned if the source is not a Dart file
   * @return the requested data about the given source
   * @throws AnalysisException if data could not be returned because the source could not be
   *           resolved
   */
  Object getDartResolutionData2(Source unitSource, Source librarySource, DataDescriptor descriptor, Object defaultValue) {
    DartEntry dartEntry = getReadableDartEntry(unitSource);
    if (dartEntry == null) {
      return defaultValue;
    }
    return getDartResolutionData(unitSource, librarySource, dartEntry, descriptor);
  }

  /**
   * Given a source for a Dart file and the library that contains it, return the data represented by
   * the given descriptor that is associated with that source. This method assumes that the data can
   * be produced by verifying the source within the given library if it is not already cached.
   *
   * @param unitSource the source representing the Dart file
   * @param librarySource the source representing the library containing the Dart file
   * @param dartEntry the entry representing the Dart file
   * @param descriptor the descriptor representing the data to be returned
   * @return the requested data about the given source
   * @throws AnalysisException if data could not be returned because the source could not be
   *           resolved
   */
  Object getDartVerificationData(Source unitSource, Source librarySource, DartEntry dartEntry, DataDescriptor descriptor) {
    dartEntry = cacheDartVerificationData(unitSource, librarySource, dartEntry, descriptor);
    return dartEntry.getValue2(descriptor, librarySource);
  }

  /**
   * Given a source for an HTML file, return the data represented by the given descriptor that is
   * associated with that source, or the given default value if the source is not an HTML file. This
   * method assumes that the data can be produced by parsing the source if it is not already cached.
   *
   * @param source the source representing the Dart file
   * @param descriptor the descriptor representing the data to be returned
   * @param defaultValue the value to be returned if the source is not an HTML file
   * @return the requested data about the given source
   * @throws AnalysisException if data could not be returned because the source could not be parsed
   */
  Object getHtmlParseData(Source source, DataDescriptor descriptor, Object defaultValue) {
    HtmlEntry htmlEntry = getReadableHtmlEntry(source);
    if (htmlEntry == null) {
      return defaultValue;
    }
    htmlEntry = cacheHtmlParseData(source, htmlEntry, descriptor);
    return htmlEntry.getValue(descriptor);
  }

  /**
   * Given a source for an HTML file, return the data represented by the given descriptor that is
   * associated with that source, or the given default value if the source is not an HTML file. This
   * method assumes that the data can be produced by resolving the source if it is not already
   * cached.
   *
   * @param source the source representing the HTML file
   * @param descriptor the descriptor representing the data to be returned
   * @param defaultValue the value to be returned if the source is not an HTML file
   * @return the requested data about the given source
   * @throws AnalysisException if data could not be returned because the source could not be
   *           resolved
   */
  Object getHtmlResolutionData(Source source, DataDescriptor descriptor, Object defaultValue) {
    HtmlEntry htmlEntry = getReadableHtmlEntry(source);
    if (htmlEntry == null) {
      return defaultValue;
    }
    return getHtmlResolutionData2(source, htmlEntry, descriptor);
  }

  /**
   * Given a source for an HTML file, return the data represented by the given descriptor that is
   * associated with that source. This method assumes that the data can be produced by resolving the
   * source if it is not already cached.
   *
   * @param source the source representing the HTML file
   * @param htmlEntry the entry representing the HTML file
   * @param descriptor the descriptor representing the data to be returned
   * @return the requested data about the given source
   * @throws AnalysisException if data could not be returned because the source could not be
   *           resolved
   */
  Object getHtmlResolutionData2(Source source, HtmlEntry htmlEntry, DataDescriptor descriptor) {
    htmlEntry = cacheHtmlResolutionData(source, htmlEntry, descriptor);
    return htmlEntry.getValue(descriptor);
  }

  /**
   * Look through the cache for a task that needs to be performed. Return the task that was found,
   * or `null` if there is no more work to be done.
   *
   * @return the next task that needs to be performed
   */
  AnalysisTask get nextTaskAnalysisTask {
    {
      bool hintsEnabled = _options.hint;
      if (_incrementalAnalysisCache != null && _incrementalAnalysisCache.hasWork()) {
        AnalysisTask task = new IncrementalAnalysisTask(this, _incrementalAnalysisCache);
        _incrementalAnalysisCache = null;
        return task;
      }
      for (Source source in _priorityOrder) {
        AnalysisTask task = getNextTaskAnalysisTask2(source, _cache.get(source), true, hintsEnabled);
        if (task != null) {
          return task;
        }
      }
      for (MapEntry<Source, SourceEntry> entry in _cache.entrySet()) {
        AnalysisTask task = getNextTaskAnalysisTask2(entry.getKey(), entry.getValue(), false, hintsEnabled);
        if (task != null) {
          return task;
        }
      }
      return null;
    }
  }

  /**
   * Look at the given source to see whether a task needs to be performed related to it. Return the
   * task that should be performed, or `null` if there is no more work to be done for the
   * source.
   *
   * <b>Note:</b> This method must only be invoked while we are synchronized on [cacheLock].
   *
   * @param source the source to be checked
   * @param sourceEntry the cache entry associated with the source
   * @param isPriority `true` if the source is a priority source
   * @param hintsEnabled `true` if hints are currently enabled
   * @return the next task that needs to be performed for the given source
   */
  AnalysisTask getNextTaskAnalysisTask2(Source source, SourceEntry sourceEntry, bool isPriority, bool hintsEnabled) {
    if (sourceEntry is DartEntry) {
      DartEntry dartEntry = sourceEntry as DartEntry;
      if (!source.exists()) {
        DartEntryImpl dartCopy = dartEntry.writableCopy;
        dartCopy.recordParseError();
        dartCopy.exception = new AnalysisException.con1("Source does not exist");
        _cache.put(source, dartCopy);
        return null;
      }
      CacheState parseErrorsState = dartEntry.getState(DartEntry.PARSE_ERRORS);
      if (identical(parseErrorsState, CacheState.INVALID) || (isPriority && identical(parseErrorsState, CacheState.FLUSHED))) {
        DartEntryImpl dartCopy = dartEntry.writableCopy;
        dartCopy.setState(DartEntry.PARSE_ERRORS, CacheState.IN_PROCESS);
        _cache.put(source, dartCopy);
        return new ParseDartTask(this, source);
      }
      if (isPriority && parseErrorsState != CacheState.ERROR) {
        CompilationUnit parseUnit = dartEntry.anyParsedCompilationUnit;
        if (parseUnit == null) {
          DartEntryImpl dartCopy = dartEntry.writableCopy;
          dartCopy.setState(DartEntry.PARSED_UNIT, CacheState.IN_PROCESS);
          _cache.put(source, dartCopy);
          return new ParseDartTask(this, source);
        }
      }
      for (Source librarySource in getLibrariesContaining(source)) {
        SourceEntry libraryEntry = _cache.get(librarySource);
        if (libraryEntry is DartEntry) {
          CacheState elementState = libraryEntry.getState(DartEntry.ELEMENT);
          if (identical(elementState, CacheState.INVALID) || (isPriority && identical(elementState, CacheState.FLUSHED))) {
            DartEntryImpl libraryCopy = (libraryEntry as DartEntry).writableCopy;
            libraryCopy.setState(DartEntry.ELEMENT, CacheState.IN_PROCESS);
            _cache.put(librarySource, libraryCopy);
            return new ResolveDartLibraryTask(this, source, librarySource);
          }
          CacheState resolvedUnitState = dartEntry.getState2(DartEntry.RESOLVED_UNIT, librarySource);
          if (identical(resolvedUnitState, CacheState.INVALID) || (isPriority && identical(resolvedUnitState, CacheState.FLUSHED))) {
            DartEntryImpl dartCopy = dartEntry.writableCopy;
            dartCopy.setState2(DartEntry.RESOLVED_UNIT, librarySource, CacheState.IN_PROCESS);
            _cache.put(source, dartCopy);
            return new ResolveDartLibraryTask(this, source, librarySource);
          }
          CacheState verificationErrorsState = dartEntry.getState2(DartEntry.VERIFICATION_ERRORS, librarySource);
          if (identical(verificationErrorsState, CacheState.INVALID) || (isPriority && identical(verificationErrorsState, CacheState.FLUSHED))) {
            LibraryElement libraryElement = libraryEntry.getValue(DartEntry.ELEMENT);
            if (libraryElement != null) {
              DartEntryImpl dartCopy = dartEntry.writableCopy;
              dartCopy.setState2(DartEntry.VERIFICATION_ERRORS, librarySource, CacheState.IN_PROCESS);
              _cache.put(source, dartCopy);
              return new GenerateDartErrorsTask(this, source, libraryElement);
            }
          }
          if (hintsEnabled) {
            CacheState hintsState = dartEntry.getState2(DartEntry.HINTS, librarySource);
            if (identical(hintsState, CacheState.INVALID) || (isPriority && identical(hintsState, CacheState.FLUSHED))) {
              LibraryElement libraryElement = libraryEntry.getValue(DartEntry.ELEMENT);
              if (libraryElement != null) {
                DartEntryImpl dartCopy = dartEntry.writableCopy;
                dartCopy.setState2(DartEntry.HINTS, librarySource, CacheState.IN_PROCESS);
                _cache.put(source, dartCopy);
                return new GenerateDartHintsTask(this, libraryElement);
              }
            }
          }
        }
      }
    } else if (sourceEntry is HtmlEntry) {
      HtmlEntry htmlEntry = sourceEntry as HtmlEntry;
      if (!source.exists()) {
        HtmlEntryImpl htmlCopy = htmlEntry.writableCopy;
        htmlCopy.recordParseError();
        htmlCopy.exception = new AnalysisException.con1("Source does not exist");
        _cache.put(source, htmlCopy);
        return null;
      }
      CacheState parsedUnitState = htmlEntry.getState(HtmlEntry.PARSED_UNIT);
      if (identical(parsedUnitState, CacheState.INVALID) || (isPriority && identical(parsedUnitState, CacheState.FLUSHED))) {
        HtmlEntryImpl htmlCopy = htmlEntry.writableCopy;
        htmlCopy.setState(HtmlEntry.PARSED_UNIT, CacheState.IN_PROCESS);
        _cache.put(source, htmlCopy);
        return new ParseHtmlTask(this, source);
      }
      CacheState elementState = htmlEntry.getState(HtmlEntry.ELEMENT);
      if (identical(elementState, CacheState.INVALID) || (isPriority && identical(elementState, CacheState.FLUSHED))) {
        HtmlEntryImpl htmlCopy = htmlEntry.writableCopy;
        htmlCopy.setState(HtmlEntry.ELEMENT, CacheState.IN_PROCESS);
        _cache.put(source, htmlCopy);
        return new ResolveHtmlTask(this, source);
      }
    }
    return null;
  }

  /**
   * Return a change notice for the given source, creating one if one does not already exist.
   *
   * @param source the source for which changes are being reported
   * @return a change notice for the given source
   */
  ChangeNoticeImpl getNotice(Source source) {
    ChangeNoticeImpl notice = _pendingNotices[source];
    if (notice == null) {
      notice = new ChangeNoticeImpl(source);
      _pendingNotices[source] = notice;
    }
    return notice;
  }

  /**
   * Return the cache entry associated with the given source, or `null` if the source is not a
   * Dart file.
   *
   * @param source the source for which a cache entry is being sought
   * @return the source cache entry associated with the given source
   */
  DartEntry getReadableDartEntry(Source source) {
    {
      SourceEntry sourceEntry = _cache.get(source);
      if (sourceEntry == null) {
        sourceEntry = createSourceEntry(source);
      }
      if (sourceEntry is DartEntry) {
        _cache.accessed(source);
        return sourceEntry as DartEntry;
      }
      return null;
    }
  }

  /**
   * Return the cache entry associated with the given source, or `null` if the source is not
   * an HTML file.
   *
   * @param source the source for which a cache entry is being sought
   * @return the source cache entry associated with the given source
   */
  HtmlEntry getReadableHtmlEntry(Source source) {
    {
      SourceEntry sourceEntry = _cache.get(source);
      if (sourceEntry == null) {
        sourceEntry = createSourceEntry(source);
      }
      if (sourceEntry is HtmlEntry) {
        _cache.accessed(source);
        return sourceEntry as HtmlEntry;
      }
      return null;
    }
  }

  /**
   * Return the cache entry associated with the given source, or `null` if there is no entry
   * associated with the source.
   *
   * @param source the source for which a cache entry is being sought
   * @return the source cache entry associated with the given source
   */
  SourceEntry getReadableSourceEntry(Source source) {
    {
      SourceEntry sourceEntry = _cache.get(source);
      if (sourceEntry == null) {
        sourceEntry = createSourceEntry(source);
      }
      if (sourceEntry != null) {
        _cache.accessed(source);
      }
      return sourceEntry;
    }
  }

  /**
   * Return an array containing all of the sources known to this context that have the given kind.
   *
   * @param kind the kind of sources to be returned
   * @return all of the sources known to this context that have the given kind
   */
  List<Source> getSources(SourceKind kind) {
    List<Source> sources = new List<Source>();
    {
      for (MapEntry<Source, SourceEntry> entry in _cache.entrySet()) {
        if (identical(entry.getValue().kind, kind)) {
          sources.add(entry.getKey());
        }
      }
    }
    return new List.from(sources);
  }

  /**
   * Look at the given source to see whether a task needs to be performed related to it. If so, add
   * the source to the set of sources that need to be processed. This method duplicates, and must
   * therefore be kept in sync with,
   * [getNextTaskAnalysisTask]. This method is
   * intended to be used for testing purposes only.
   *
   * <b>Note:</b> This method must only be invoked while we are synchronized on [cacheLock].
   *
   * @param source the source to be checked
   * @param sourceEntry the cache entry associated with the source
   * @param isPriority `true` if the source is a priority source
   * @param hintsEnabled `true` if hints are currently enabled
   * @param sources the set to which sources should be added
   */
  void getSourcesNeedingProcessing2(Source source, SourceEntry sourceEntry, bool isPriority, bool hintsEnabled, Set<Source> sources) {
    if (sourceEntry is DartEntry) {
      DartEntry dartEntry = sourceEntry as DartEntry;
      CacheState parseErrorsState = dartEntry.getState(DartEntry.PARSE_ERRORS);
      if (identical(parseErrorsState, CacheState.INVALID) || (isPriority && identical(parseErrorsState, CacheState.FLUSHED))) {
        sources.add(source);
        return;
      }
      if (isPriority) {
        CompilationUnit parseUnit = dartEntry.anyParsedCompilationUnit;
        if (parseUnit == null) {
          sources.add(source);
          return;
        }
      }
      for (Source librarySource in getLibrariesContaining(source)) {
        SourceEntry libraryEntry = _cache.get(librarySource);
        if (libraryEntry is DartEntry) {
          CacheState elementState = libraryEntry.getState(DartEntry.ELEMENT);
          if (identical(elementState, CacheState.INVALID) || (isPriority && identical(elementState, CacheState.FLUSHED))) {
            sources.add(source);
            return;
          }
          CacheState resolvedUnitState = dartEntry.getState2(DartEntry.RESOLVED_UNIT, librarySource);
          if (identical(resolvedUnitState, CacheState.INVALID) || (isPriority && identical(resolvedUnitState, CacheState.FLUSHED))) {
            LibraryElement libraryElement = libraryEntry.getValue(DartEntry.ELEMENT);
            if (libraryElement != null) {
              sources.add(source);
              return;
            }
          }
          CacheState verificationErrorsState = dartEntry.getState2(DartEntry.VERIFICATION_ERRORS, librarySource);
          if (identical(verificationErrorsState, CacheState.INVALID) || (isPriority && identical(verificationErrorsState, CacheState.FLUSHED))) {
            LibraryElement libraryElement = libraryEntry.getValue(DartEntry.ELEMENT);
            if (libraryElement != null) {
              sources.add(source);
              return;
            }
          }
          if (hintsEnabled) {
            CacheState hintsState = dartEntry.getState2(DartEntry.HINTS, librarySource);
            if (identical(hintsState, CacheState.INVALID) || (isPriority && identical(hintsState, CacheState.FLUSHED))) {
              LibraryElement libraryElement = libraryEntry.getValue(DartEntry.ELEMENT);
              if (libraryElement != null) {
                sources.add(source);
                return;
              }
            }
          }
        }
      }
    } else if (sourceEntry is HtmlEntry) {
      HtmlEntry htmlEntry = sourceEntry as HtmlEntry;
      CacheState parsedUnitState = htmlEntry.getState(HtmlEntry.PARSED_UNIT);
      if (identical(parsedUnitState, CacheState.INVALID) || (isPriority && identical(parsedUnitState, CacheState.FLUSHED))) {
        sources.add(source);
        return;
      }
      CacheState elementState = htmlEntry.getState(HtmlEntry.ELEMENT);
      if (identical(elementState, CacheState.INVALID) || (isPriority && identical(elementState, CacheState.FLUSHED))) {
        sources.add(source);
        return;
      }
    }
  }

  /**
   * Invalidate all of the resolution results computed by this context.
   *
   * <b>Note:</b> This method must only be invoked while we are synchronized on [cacheLock].
   */
  void invalidateAllResolutionInformation() {
    for (MapEntry<Source, SourceEntry> mapEntry in _cache.entrySet()) {
      SourceEntry sourceEntry = mapEntry.getValue();
      if (sourceEntry is HtmlEntry) {
        HtmlEntryImpl htmlCopy = (sourceEntry as HtmlEntry).writableCopy;
        htmlCopy.invalidateAllResolutionInformation();
        mapEntry.setValue(htmlCopy);
      } else if (sourceEntry is DartEntry) {
        DartEntryImpl dartCopy = (sourceEntry as DartEntry).writableCopy;
        dartCopy.invalidateAllResolutionInformation();
        mapEntry.setValue(dartCopy);
      }
    }
  }

  /**
   * In response to a change to at least one of the compilation units in the given library,
   * invalidate any results that are dependent on the result of resolving that library.
   *
   * <b>Note:</b> This method must only be invoked while we are synchronized on [cacheLock].
   *
   * @param librarySource the source of the library being invalidated
   */
  void invalidateLibraryResolution(Source librarySource) {
    DartEntry libraryEntry = getReadableDartEntry(librarySource);
    if (libraryEntry != null) {
      List<Source> includedParts = libraryEntry.getValue(DartEntry.INCLUDED_PARTS);
      DartEntryImpl libraryCopy = libraryEntry.writableCopy;
      libraryCopy.invalidateAllResolutionInformation();
      libraryCopy.setState(DartEntry.INCLUDED_PARTS, CacheState.INVALID);
      _cache.put(librarySource, libraryCopy);
      for (Source partSource in includedParts) {
        SourceEntry partEntry = _cache.get(partSource);
        if (partEntry is DartEntry) {
          DartEntryImpl partCopy = (partEntry as DartEntry).writableCopy;
          partCopy.invalidateAllResolutionInformation();
          _cache.put(partSource, partCopy);
        }
      }
    }
  }

  /**
   * Return `true` if this library is, or depends on, dart:html.
   *
   * @param library the library being tested
   * @param visitedLibraries a collection of the libraries that have been visited, used to prevent
   *          infinite recursion
   * @return `true` if this library is, or depends on, dart:html
   */
  bool isClient(LibraryElement library, Source htmlSource, Set<LibraryElement> visitedLibraries) {
    if (visitedLibraries.contains(library)) {
      return false;
    }
    if (library.source == htmlSource) {
      return true;
    }
    visitedLibraries.add(library);
    for (LibraryElement imported in library.importedLibraries) {
      if (isClient(imported, htmlSource, visitedLibraries)) {
        return true;
      }
    }
    for (LibraryElement exported in library.exportedLibraries) {
      if (isClient(exported, htmlSource, visitedLibraries)) {
        return true;
      }
    }
    return false;
  }

  /**
   * Given a cache entry and a library element, record the library element and other information
   * gleaned from the element in the cache entry.
   *
   * @param dartCopy the cache entry in which data is to be recorded
   * @param library the library element used to record information
   * @param htmlSource the source for the HTML library
   */
  void recordElementData(DartEntryImpl dartCopy, LibraryElement library, Source htmlSource) {
    dartCopy.setValue(DartEntry.ELEMENT, library);
    dartCopy.setValue(DartEntry.IS_LAUNCHABLE, library.entryPoint != null);
    dartCopy.setValue(DartEntry.IS_CLIENT, isClient(library, htmlSource, new Set<LibraryElement>()));
    List<Source> unitSources = new List<Source>();
    unitSources.add(library.definingCompilationUnit.source);
    for (CompilationUnitElement part in library.parts) {
      Source partSource = part.source;
      unitSources.add(partSource);
    }
    dartCopy.setValue(DartEntry.INCLUDED_PARTS, new List.from(unitSources));
  }

  /**
   * Record the results produced by performing a [GenerateDartErrorsTask]. If the results were
   * computed from data that is now out-of-date, then the results will not be recorded.
   *
   * @param task the task that was performed
   * @return an entry containing the computed results
   * @throws AnalysisException if the results could not be recorded
   */
  DartEntry recordGenerateDartErrorsTask(GenerateDartErrorsTask task) {
    Source source = task.source;
    Source librarySource = task.libraryElement.source;
    AnalysisException thrownException = task.exception;
    DartEntry dartEntry = null;
    {
      SourceEntry sourceEntry = _cache.get(source);
      if (sourceEntry is! DartEntry) {
        throw new AnalysisException.con1("Internal error: attempting to verify non-Dart file as a Dart file: ${source.fullName}");
      }
      dartEntry = sourceEntry as DartEntry;
      _cache.accessed(source);
      int sourceTime = source.modificationStamp;
      int resultTime = task.modificationTime;
      if (sourceTime == resultTime) {
        if (dartEntry.modificationTime != sourceTime) {
          sourceChanged(source);
          dartEntry = getReadableDartEntry(source);
          if (dartEntry == null) {
            throw new AnalysisException.con1("A Dart file became a non-Dart file: ${source.fullName}");
          }
        }
        DartEntryImpl dartCopy = dartEntry.writableCopy;
        if (thrownException == null) {
          dartCopy.setValue2(DartEntry.VERIFICATION_ERRORS, librarySource, task.errors);
          ChangeNoticeImpl notice = getNotice(source);
          notice.setErrors(dartCopy.allErrors, dartCopy.getValue(SourceEntry.LINE_INFO));
        } else {
          dartCopy.setState2(DartEntry.VERIFICATION_ERRORS, librarySource, CacheState.ERROR);
        }
        dartCopy.exception = thrownException;
        _cache.put(source, dartCopy);
        dartEntry = dartCopy;
      } else {
        DartEntryImpl dartCopy = dartEntry.writableCopy;
        if (thrownException == null || resultTime >= 0) {
          dartCopy.setState2(DartEntry.VERIFICATION_ERRORS, librarySource, CacheState.INVALID);
        } else {
          dartCopy.setState2(DartEntry.VERIFICATION_ERRORS, librarySource, CacheState.ERROR);
        }
        dartCopy.exception = thrownException;
        _cache.put(source, dartCopy);
        dartEntry = dartCopy;
      }
    }
    if (thrownException != null) {
      throw thrownException;
    }
    return dartEntry;
  }

  /**
   * Record the results produced by performing a [GenerateDartHintsTask]. If the results were
   * computed from data that is now out-of-date, then the results will not be recorded.
   *
   * @param task the task that was performed
   * @return an entry containing the computed results
   * @throws AnalysisException if the results could not be recorded
   */
  DartEntry recordGenerateDartHintsTask(GenerateDartHintsTask task) {
    Source librarySource = task.libraryElement.source;
    AnalysisException thrownException = task.exception;
    DartEntry libraryEntry = null;
    Map<Source, TimestampedData<List<AnalysisError>>> hintMap = task.hintMap;
    if (hintMap == null) {
      {
        SourceEntry sourceEntry = _cache.get(librarySource);
        if (sourceEntry is! DartEntry) {
          throw new AnalysisException.con1("Internal error: attempting to generate hints for non-Dart file as a Dart file: ${librarySource.fullName}");
        }
        if (thrownException == null) {
          thrownException = new AnalysisException.con1("GenerateDartHintsTask returned a null hint map without throwing an exception: ${librarySource.fullName}");
        }
        DartEntryImpl dartCopy = (sourceEntry as DartEntry).writableCopy;
        dartCopy.setState2(DartEntry.HINTS, librarySource, CacheState.ERROR);
        dartCopy.exception = thrownException;
        _cache.put(librarySource, dartCopy);
      }
      throw thrownException;
    }
    for (MapEntry<Source, TimestampedData<List<AnalysisError>>> entry in getMapEntrySet(hintMap)) {
      Source unitSource = entry.getKey();
      TimestampedData<List<AnalysisError>> results = entry.getValue();
      {
        SourceEntry sourceEntry = _cache.get(unitSource);
        if (sourceEntry is! DartEntry) {
          throw new AnalysisException.con1("Internal error: attempting to parse non-Dart file as a Dart file: ${unitSource.fullName}");
        }
        DartEntry dartEntry = sourceEntry as DartEntry;
        if (unitSource == librarySource) {
          libraryEntry = dartEntry;
        }
        _cache.accessed(unitSource);
        int sourceTime = unitSource.modificationStamp;
        int resultTime = results.modificationTime;
        if (sourceTime == resultTime) {
          if (dartEntry.modificationTime != sourceTime) {
            sourceChanged(unitSource);
            dartEntry = getReadableDartEntry(unitSource);
            if (dartEntry == null) {
              throw new AnalysisException.con1("A Dart file became a non-Dart file: ${unitSource.fullName}");
            }
          }
          DartEntryImpl dartCopy = dartEntry.writableCopy;
          if (thrownException == null) {
            dartCopy.setValue2(DartEntry.HINTS, librarySource, results.data);
            ChangeNoticeImpl notice = getNotice(unitSource);
            notice.setErrors(dartCopy.allErrors, dartCopy.getValue(SourceEntry.LINE_INFO));
          } else {
            dartCopy.setState2(DartEntry.HINTS, librarySource, CacheState.ERROR);
          }
          dartCopy.exception = thrownException;
          _cache.put(unitSource, dartCopy);
          dartEntry = dartCopy;
        } else {
          if (identical(dartEntry.getState2(DartEntry.HINTS, librarySource), CacheState.IN_PROCESS)) {
            DartEntryImpl dartCopy = dartEntry.writableCopy;
            if (thrownException == null || resultTime >= 0) {
              dartCopy.setState2(DartEntry.HINTS, librarySource, CacheState.INVALID);
            } else {
              dartCopy.setState2(DartEntry.HINTS, librarySource, CacheState.ERROR);
            }
            dartCopy.exception = thrownException;
            _cache.put(unitSource, dartCopy);
            dartEntry = dartCopy;
          }
        }
      }
    }
    if (thrownException != null) {
      throw thrownException;
    }
    return libraryEntry;
  }

  /**
   * Record the results produced by performing a [IncrementalAnalysisTask].
   *
   * @param task the task that was performed
   * @return an entry containing the computed results
   * @throws AnalysisException if the results could not be recorded
   */
  DartEntry recordIncrementalAnalysisTaskResults(IncrementalAnalysisTask task) {
    {
      CompilationUnit unit = task.compilationUnit;
      if (unit != null) {
        ChangeNoticeImpl notice = getNotice(task.source);
        notice.compilationUnit = unit;
        _incrementalAnalysisCache = IncrementalAnalysisCache.cacheResult(task.cache, unit);
      }
    }
    return null;
  }

  /**
   * Record the results produced by performing a [ParseDartTask]. If the results were computed
   * from data that is now out-of-date, then the results will not be recorded.
   *
   * @param task the task that was performed
   * @return an entry containing the computed results
   * @throws AnalysisException if the results could not be recorded
   */
  DartEntry recordParseDartTaskResults(ParseDartTask task) {
    Source source = task.source;
    AnalysisException thrownException = task.exception;
    DartEntry dartEntry = null;
    {
      SourceEntry sourceEntry = _cache.get(source);
      if (sourceEntry is! DartEntry) {
        throw new AnalysisException.con1("Internal error: attempting to parse non-Dart file as a Dart file: ${source.fullName}");
      }
      dartEntry = sourceEntry as DartEntry;
      _cache.accessed(source);
      int sourceTime = source.modificationStamp;
      int resultTime = task.modificationTime;
      if (sourceTime == resultTime) {
        if (dartEntry.modificationTime != sourceTime) {
          sourceChanged(source);
          dartEntry = getReadableDartEntry(source);
          if (dartEntry == null) {
            throw new AnalysisException.con1("A Dart file became a non-Dart file: ${source.fullName}");
          }
        }
        DartEntryImpl dartCopy = dartEntry.writableCopy;
        if (thrownException == null) {
          LineInfo lineInfo = task.lineInfo;
          dartCopy.setValue(SourceEntry.LINE_INFO, lineInfo);
          if (task.hasPartOfDirective() && !task.hasLibraryDirective()) {
            dartCopy.setValue(DartEntry.SOURCE_KIND, SourceKind.PART);
          } else {
            dartCopy.setValue(DartEntry.SOURCE_KIND, SourceKind.LIBRARY);
          }
          dartCopy.setValue(DartEntry.PARSED_UNIT, task.compilationUnit);
          dartCopy.setValue(DartEntry.PARSE_ERRORS, task.errors);
          dartCopy.setValue(DartEntry.EXPORTED_LIBRARIES, task.exportedSources);
          dartCopy.setValue(DartEntry.IMPORTED_LIBRARIES, task.importedSources);
          dartCopy.setValue(DartEntry.INCLUDED_PARTS, task.includedSources);
          ChangeNoticeImpl notice = getNotice(source);
          notice.setErrors(dartEntry.allErrors, lineInfo);
          _incrementalAnalysisCache = IncrementalAnalysisCache.verifyStructure(_incrementalAnalysisCache, source, task.compilationUnit);
        } else {
          dartCopy.recordParseError();
        }
        dartCopy.exception = thrownException;
        _cache.put(source, dartCopy);
        dartEntry = dartCopy;
      } else {
        DartEntryImpl dartCopy = dartEntry.writableCopy;
        if (thrownException == null || resultTime >= 0) {
          dartCopy.recordParseNotInProcess();
        } else {
          dartCopy.recordParseError();
        }
        dartCopy.exception = thrownException;
        _cache.put(source, dartCopy);
        dartEntry = dartCopy;
      }
    }
    if (thrownException != null) {
      throw thrownException;
    }
    return dartEntry;
  }

  /**
   * Record the results produced by performing a [ParseHtmlTask]. If the results were computed
   * from data that is now out-of-date, then the results will not be recorded.
   *
   * @param task the task that was performed
   * @return an entry containing the computed results
   * @throws AnalysisException if the results could not be recorded
   */
  HtmlEntry recordParseHtmlTaskResults(ParseHtmlTask task) {
    Source source = task.source;
    AnalysisException thrownException = task.exception;
    HtmlEntry htmlEntry = null;
    {
      SourceEntry sourceEntry = _cache.get(source);
      if (sourceEntry is! HtmlEntry) {
        throw new AnalysisException.con1("Internal error: attempting to parse non-HTML file as a HTML file: ${source.fullName}");
      }
      htmlEntry = sourceEntry as HtmlEntry;
      _cache.accessed(source);
      int sourceTime = source.modificationStamp;
      int resultTime = task.modificationTime;
      if (sourceTime == resultTime) {
        if (htmlEntry.modificationTime != sourceTime) {
          sourceChanged(source);
          htmlEntry = getReadableHtmlEntry(source);
          if (htmlEntry == null) {
            throw new AnalysisException.con1("An HTML file became a non-HTML file: ${source.fullName}");
          }
        }
        HtmlEntryImpl htmlCopy = (sourceEntry as HtmlEntry).writableCopy;
        if (thrownException == null) {
          LineInfo lineInfo = task.lineInfo;
          HtmlUnit unit = task.htmlUnit;
          htmlCopy.setValue(SourceEntry.LINE_INFO, lineInfo);
          htmlCopy.setValue(HtmlEntry.PARSED_UNIT, unit);
          htmlCopy.setValue(HtmlEntry.PARSE_ERRORS, task.errors);
          htmlCopy.setValue(HtmlEntry.REFERENCED_LIBRARIES, task.referencedLibraries);
          ChangeNoticeImpl notice = getNotice(source);
          notice.setErrors(htmlEntry.allErrors, lineInfo);
        } else {
          htmlCopy.recordParseError();
        }
        htmlCopy.exception = thrownException;
        _cache.put(source, htmlCopy);
        htmlEntry = htmlCopy;
      } else {
        HtmlEntryImpl htmlCopy = (sourceEntry as HtmlEntry).writableCopy;
        if (thrownException == null || resultTime >= 0) {
          if (identical(htmlCopy.getState(SourceEntry.LINE_INFO), CacheState.IN_PROCESS)) {
            htmlCopy.setState(SourceEntry.LINE_INFO, CacheState.INVALID);
          }
          if (identical(htmlCopy.getState(HtmlEntry.PARSED_UNIT), CacheState.IN_PROCESS)) {
            htmlCopy.setState(HtmlEntry.PARSED_UNIT, CacheState.INVALID);
          }
          if (identical(htmlCopy.getState(HtmlEntry.REFERENCED_LIBRARIES), CacheState.IN_PROCESS)) {
            htmlCopy.setState(HtmlEntry.REFERENCED_LIBRARIES, CacheState.INVALID);
          }
        } else {
          htmlCopy.setState(SourceEntry.LINE_INFO, CacheState.ERROR);
          htmlCopy.setState(HtmlEntry.PARSED_UNIT, CacheState.ERROR);
          htmlCopy.setState(HtmlEntry.REFERENCED_LIBRARIES, CacheState.ERROR);
        }
        htmlCopy.exception = thrownException;
        _cache.put(source, htmlCopy);
        htmlEntry = htmlCopy;
      }
    }
    if (thrownException != null) {
      throw thrownException;
    }
    return htmlEntry;
  }

  /**
   * Record the results produced by performing a [ResolveDartLibraryTask]. If the results were
   * computed from data that is now out-of-date, then the results will not be recorded.
   *
   * @param task the task that was performed
   * @return an entry containing the computed results
   * @throws AnalysisException if the results could not be recorded
   */
  DartEntry recordResolveDartLibraryTaskResults(ResolveDartLibraryTask task) {
    LibraryResolver resolver = task.libraryResolver;
    AnalysisException thrownException = task.exception;
    DartEntry unitEntry = null;
    Source unitSource = task.unitSource;
    if (resolver != null) {
      Set<Library> resolvedLibraries = resolver.resolvedLibraries;
      if (resolvedLibraries == null) {
        unitEntry = getReadableDartEntry(unitSource);
        if (unitEntry == null) {
          throw new AnalysisException.con1("A Dart file became a non-Dart file: ${unitSource.fullName}");
        }
        DartEntryImpl dartCopy = unitEntry.writableCopy;
        dartCopy.recordResolutionError();
        dartCopy.exception = thrownException;
        _cache.put(unitSource, dartCopy);
        if (thrownException != null) {
          throw thrownException;
        }
        return dartCopy;
      }
      {
        if (allModificationTimesMatch(resolvedLibraries)) {
          Source htmlSource = sourceFactory.forUri(DartSdk.DART_HTML);
          RecordingErrorListener errorListener = resolver.errorListener;
          for (Library library in resolvedLibraries) {
            Source librarySource = library.librarySource;
            for (Source source in library.compilationUnitSources) {
              CompilationUnit unit = library.getAST(source);
              List<AnalysisError> errors = errorListener.getErrors2(source);
              LineInfo lineInfo = getLineInfo(source);
              DartEntry dartEntry = _cache.get(source) as DartEntry;
              int sourceTime = source.modificationStamp;
              if (dartEntry.modificationTime != sourceTime) {
                sourceChanged(source);
                dartEntry = getReadableDartEntry(source);
                if (dartEntry == null) {
                  throw new AnalysisException.con1("A Dart file became a non-Dart file: ${source.fullName}");
                }
              }
              DartEntryImpl dartCopy = dartEntry.writableCopy;
              if (thrownException == null) {
                dartCopy.setValue(SourceEntry.LINE_INFO, lineInfo);
                dartCopy.setState(DartEntry.PARSED_UNIT, CacheState.FLUSHED);
                dartCopy.setValue2(DartEntry.RESOLVED_UNIT, librarySource, unit);
                dartCopy.setValue2(DartEntry.RESOLUTION_ERRORS, librarySource, errors);
                if (identical(source, librarySource)) {
                  recordElementData(dartCopy, library.libraryElement, htmlSource);
                }
              } else {
                dartCopy.recordResolutionError();
              }
              dartCopy.exception = thrownException;
              _cache.put(source, dartCopy);
              if (source == unitSource) {
                unitEntry = dartCopy;
              }
              ChangeNoticeImpl notice = getNotice(source);
              notice.compilationUnit = unit;
              notice.setErrors(dartCopy.allErrors, lineInfo);
            }
          }
        } else {
          for (Library library in resolvedLibraries) {
            for (Source source in library.compilationUnitSources) {
              DartEntry dartEntry = getReadableDartEntry(source);
              if (dartEntry != null) {
                int resultTime = library.getModificationTime(source);
                DartEntryImpl dartCopy = dartEntry.writableCopy;
                if (thrownException == null || resultTime >= 0) {
                  dartCopy.recordResolutionNotInProcess();
                } else {
                  dartCopy.recordResolutionError();
                }
                dartCopy.exception = thrownException;
                _cache.put(source, dartCopy);
                if (source == unitSource) {
                  unitEntry = dartCopy;
                }
              }
            }
          }
        }
      }
    }
    if (thrownException != null) {
      throw thrownException;
    }
    if (unitEntry == null) {
      unitEntry = getReadableDartEntry(unitSource);
      if (unitEntry == null) {
        throw new AnalysisException.con1("A Dart file became a non-Dart file: ${unitSource.fullName}");
      }
    }
    return unitEntry;
  }

  /**
   * Record the results produced by performing a [ResolveDartUnitTask]. If the results were
   * computed from data that is now out-of-date, then the results will not be recorded.
   *
   * @param task the task that was performed
   * @return an entry containing the computed results
   * @throws AnalysisException if the results could not be recorded
   */
  SourceEntry recordResolveDartUnitTaskResults(ResolveDartUnitTask task) {
    Source unitSource = task.source;
    Source librarySource = task.librarySource;
    AnalysisException thrownException = task.exception;
    DartEntry dartEntry = null;
    {
      SourceEntry sourceEntry = _cache.get(unitSource);
      if (sourceEntry is! DartEntry) {
        throw new AnalysisException.con1("Internal error: attempting to reolve non-Dart file as a Dart file: ${unitSource.fullName}");
      }
      dartEntry = sourceEntry as DartEntry;
      _cache.accessed(unitSource);
      int sourceTime = unitSource.modificationStamp;
      int resultTime = task.modificationTime;
      if (sourceTime == resultTime) {
        if (dartEntry.modificationTime != sourceTime) {
          sourceChanged(unitSource);
          dartEntry = getReadableDartEntry(unitSource);
          if (dartEntry == null) {
            throw new AnalysisException.con1("A Dart file became a non-Dart file: ${unitSource.fullName}");
          }
        }
        DartEntryImpl dartCopy = dartEntry.writableCopy;
        if (thrownException == null) {
          dartCopy.setValue2(DartEntry.RESOLVED_UNIT, librarySource, task.resolvedUnit);
        } else {
          dartCopy.setState2(DartEntry.RESOLVED_UNIT, librarySource, CacheState.ERROR);
        }
        dartCopy.exception = thrownException;
        _cache.put(unitSource, dartCopy);
        dartEntry = dartCopy;
      } else {
        DartEntryImpl dartCopy = dartEntry.writableCopy;
        if (thrownException == null || resultTime >= 0) {
          if (identical(dartCopy.getState(DartEntry.RESOLVED_UNIT), CacheState.IN_PROCESS)) {
            dartCopy.setState2(DartEntry.RESOLVED_UNIT, librarySource, CacheState.INVALID);
          }
        } else {
          dartCopy.setState2(DartEntry.RESOLVED_UNIT, librarySource, CacheState.ERROR);
        }
        dartCopy.exception = thrownException;
        _cache.put(unitSource, dartCopy);
        dartEntry = dartCopy;
      }
    }
    if (thrownException != null) {
      throw thrownException;
    }
    return dartEntry;
  }

  /**
   * Record the results produced by performing a [ResolveHtmlTask]. If the results were
   * computed from data that is now out-of-date, then the results will not be recorded.
   *
   * @param task the task that was performed
   * @return an entry containing the computed results
   * @throws AnalysisException if the results could not be recorded
   */
  SourceEntry recordResolveHtmlTaskResults(ResolveHtmlTask task) {
    Source source = task.source;
    AnalysisException thrownException = task.exception;
    HtmlEntry htmlEntry = null;
    {
      SourceEntry sourceEntry = _cache.get(source);
      if (sourceEntry is! HtmlEntry) {
        throw new AnalysisException.con1("Internal error: attempting to reolve non-HTML file as an HTML file: ${source.fullName}");
      }
      htmlEntry = sourceEntry as HtmlEntry;
      _cache.accessed(source);
      int sourceTime = source.modificationStamp;
      int resultTime = task.modificationTime;
      if (sourceTime == resultTime) {
        if (htmlEntry.modificationTime != sourceTime) {
          sourceChanged(source);
          htmlEntry = getReadableHtmlEntry(source);
          if (htmlEntry == null) {
            throw new AnalysisException.con1("An HTML file became a non-HTML file: ${source.fullName}");
          }
        }
        HtmlEntryImpl htmlCopy = htmlEntry.writableCopy;
        if (thrownException == null) {
          htmlCopy.setValue(HtmlEntry.ELEMENT, task.element);
          htmlCopy.setValue(HtmlEntry.RESOLUTION_ERRORS, task.resolutionErrors);
          ChangeNoticeImpl notice = getNotice(source);
          notice.setErrors(htmlCopy.allErrors, htmlCopy.getValue(SourceEntry.LINE_INFO));
        } else {
          htmlCopy.recordResolutionError();
        }
        htmlCopy.exception = thrownException;
        _cache.put(source, htmlCopy);
        htmlEntry = htmlCopy;
      } else {
        HtmlEntryImpl htmlCopy = htmlEntry.writableCopy;
        if (thrownException == null || resultTime >= 0) {
          if (identical(htmlCopy.getState(HtmlEntry.ELEMENT), CacheState.IN_PROCESS)) {
            htmlCopy.setState(HtmlEntry.ELEMENT, CacheState.INVALID);
          }
          if (identical(htmlCopy.getState(HtmlEntry.RESOLUTION_ERRORS), CacheState.IN_PROCESS)) {
            htmlCopy.setState(HtmlEntry.RESOLUTION_ERRORS, CacheState.INVALID);
          }
        } else {
          htmlCopy.recordResolutionError();
        }
        htmlCopy.exception = thrownException;
        _cache.put(source, htmlCopy);
        htmlEntry = htmlCopy;
      }
    }
    if (thrownException != null) {
      throw thrownException;
    }
    return htmlEntry;
  }

  /**
   * Create an entry for the newly added source. Return `true` if the new source is a Dart
   * file.
   *
   * <b>Note:</b> This method must only be invoked while we are synchronized on [cacheLock].
   *
   * @param source the source that has been added
   * @return `true` if the new source is a Dart file
   */
  bool sourceAvailable(Source source) {
    SourceEntry sourceEntry = _cache.get(source);
    if (sourceEntry == null) {
      sourceEntry = createSourceEntry(source);
    } else {
      SourceEntryImpl sourceCopy = sourceEntry.writableCopy;
      sourceCopy.modificationTime = source.modificationStamp;
      _cache.put(source, sourceCopy);
    }
    return sourceEntry is DartEntry;
  }

  /**
   * <b>Note:</b> This method must only be invoked while we are synchronized on [cacheLock].
   *
   * @param source the source that has been changed
   */
  void sourceChanged(Source source) {
    SourceEntry sourceEntry = _cache.get(source);
    if (sourceEntry is HtmlEntry) {
      HtmlEntryImpl htmlCopy = (sourceEntry as HtmlEntry).writableCopy;
      htmlCopy.modificationTime = source.modificationStamp;
      htmlCopy.invalidateAllInformation();
      _cache.put(source, htmlCopy);
    } else if (sourceEntry is DartEntry) {
      List<Source> containingLibraries = getLibrariesContaining(source);
      Set<Source> librariesToInvalidate = new Set<Source>();
      for (Source containingLibrary in containingLibraries) {
        librariesToInvalidate.add(containingLibrary);
        for (Source dependentLibrary in getLibrariesDependingOn(containingLibrary)) {
          librariesToInvalidate.add(dependentLibrary);
        }
      }
      for (Source library in librariesToInvalidate) {
        invalidateLibraryResolution(library);
      }
      DartEntryImpl dartCopy = (sourceEntry as DartEntry).writableCopy;
      dartCopy.modificationTime = source.modificationStamp;
      dartCopy.invalidateAllInformation();
      _cache.put(source, dartCopy);
    }
  }

  /**
   * <b>Note:</b> This method must only be invoked while we are synchronized on [cacheLock].
   *
   * @param source the source that has been deleted
   */
  void sourceRemoved(Source source) {
    SourceEntry sourceEntry = _cache.get(source);
    if (sourceEntry is DartEntry) {
      Set<Source> libraries = new Set<Source>();
      for (Source librarySource in getLibrariesContaining(source)) {
        libraries.add(librarySource);
        for (Source dependentLibrary in getLibrariesDependingOn(librarySource)) {
          libraries.add(dependentLibrary);
        }
      }
      for (Source librarySource in libraries) {
        invalidateLibraryResolution(librarySource);
      }
    }
    _cache.remove(source);
  }
}

/**
 * Instances of the class `AnalysisTaskResultRecorder` are used by an analysis context to
 * record the results of a task.
 */
class AnalysisContextImpl_AnalysisTaskResultRecorder implements AnalysisTaskVisitor<SourceEntry> {
  final AnalysisContextImpl AnalysisContextImpl_this;

  AnalysisContextImpl_AnalysisTaskResultRecorder(this.AnalysisContextImpl_this);

  SourceEntry visitGenerateDartErrorsTask(GenerateDartErrorsTask task) => AnalysisContextImpl_this.recordGenerateDartErrorsTask(task);

  SourceEntry visitGenerateDartHintsTask(GenerateDartHintsTask task) => AnalysisContextImpl_this.recordGenerateDartHintsTask(task);

  SourceEntry visitIncrementalAnalysisTask(IncrementalAnalysisTask task) => AnalysisContextImpl_this.recordIncrementalAnalysisTaskResults(task);

  DartEntry visitParseDartTask(ParseDartTask task) => AnalysisContextImpl_this.recordParseDartTaskResults(task);

  HtmlEntry visitParseHtmlTask(ParseHtmlTask task) => AnalysisContextImpl_this.recordParseHtmlTaskResults(task);

  DartEntry visitResolveDartLibraryTask(ResolveDartLibraryTask task) => AnalysisContextImpl_this.recordResolveDartLibraryTaskResults(task);

  SourceEntry visitResolveDartUnitTask(ResolveDartUnitTask task) => AnalysisContextImpl_this.recordResolveDartUnitTaskResults(task);

  SourceEntry visitResolveHtmlTask(ResolveHtmlTask task) => AnalysisContextImpl_this.recordResolveHtmlTaskResults(task);
}

class AnalysisContextImpl_ContextRetentionPolicy implements CacheRetentionPolicy {
  final AnalysisContextImpl AnalysisContextImpl_this;

  AnalysisContextImpl_ContextRetentionPolicy(this.AnalysisContextImpl_this);

  RetentionPriority getAstPriority(Source source, SourceEntry sourceEntry) {
    for (Source prioritySource in AnalysisContextImpl_this._priorityOrder) {
      if (source == prioritySource) {
        return RetentionPriority.HIGH;
      }
    }
    if (sourceEntry is DartEntry) {
      DartEntry dartEntry = sourceEntry as DartEntry;
      if (astIsNeeded(dartEntry)) {
        return RetentionPriority.MEDIUM;
      }
    }
    return RetentionPriority.LOW;
  }

  bool astIsNeeded(DartEntry dartEntry) => dartEntry.hasInvalidData(DartEntry.HINTS) || dartEntry.hasInvalidData(DartEntry.VERIFICATION_ERRORS) || dartEntry.hasInvalidData(DartEntry.RESOLUTION_ERRORS);
}

/**
 * Instances of the class `AnalysisErrorInfoImpl` represent the analysis errors and line info
 * associated with a source.
 */
class AnalysisErrorInfoImpl implements AnalysisErrorInfo {
  /**
   * The analysis errors associated with a source, or `null` if there are no errors.
   */
  List<AnalysisError> _errors;

  /**
   * The line information associated with the errors, or `null` if there are no errors.
   */
  LineInfo _lineInfo;

  /**
   * Initialize an newly created error info with the errors and line information
   *
   * @param errors the errors as a result of analysis
   * @param lineinfo the line info for the errors
   */
  AnalysisErrorInfoImpl(List<AnalysisError> errors, LineInfo lineInfo) {
    this._errors = errors;
    this._lineInfo = lineInfo;
  }

  /**
   * Return the errors of analysis, or `null` if there were no errors.
   *
   * @return the errors as a result of the analysis
   */
  List<AnalysisError> get errors => _errors;

  /**
   * Return the line information associated with the errors, or `null` if there were no
   * errors.
   *
   * @return the line information associated with the errors
   */
  LineInfo get lineInfo => _lineInfo;
}

/**
 * Instances of the class `AnalysisOptions` represent a set of analysis options used to
 * control the behavior of an analysis context.
 */
class AnalysisOptionsImpl implements AnalysisOptions {
  /**
   * The maximum number of sources for which data should be kept in the cache.
   */
  static int DEFAULT_CACHE_SIZE = 64;

  /**
   * The maximum number of sources for which AST structures should be kept in the cache.
   */
  int _cacheSize = DEFAULT_CACHE_SIZE;

  /**
   * A flag indicating whether analysis is to parse and analyze function bodies.
   */
  bool _analyzeFunctionBodies = true;

  /**
   * A flag indicating whether analysis is to generate dart2js related hint results.
   */
  bool _dart2jsHint = true;

  /**
   * A flag indicating whether analysis is to generate hint results (e.g. type inference based
   * information and pub best practices).
   */
  bool _hint = true;

  /**
   * A flag indicating whether incremental analysis should be used.
   */
  bool _incremental = false;

  /**
   * flag indicating whether analysis is to parse comments.
   */
  bool _preserveComments = true;

  /**
   * Initialize a newly created set of analysis options to have their default values.
   */
  AnalysisOptionsImpl();

  /**
   * Initialize a newly created set of analysis options to have the same values as those in the
   * given set of analysis options.
   *
   * @param options the analysis options whose values are being copied
   */
  AnalysisOptionsImpl.con1(AnalysisOptions options) {
    _cacheSize = options.cacheSize;
    _dart2jsHint = options.dart2jsHint;
    _hint = options.hint;
    _incremental = options.incremental;
  }

  bool get analyzeFunctionBodies => _analyzeFunctionBodies;

  int get cacheSize => _cacheSize;

  bool get dart2jsHint => _dart2jsHint;

  bool get hint => _hint;

  bool get incremental => _incremental;

  bool get preserveComments => _preserveComments;

  /**
   * Set whether analysis is to parse and analyze function bodies.
   *
   * @param analyzeFunctionBodies `true` if analysis is to parse and analyze function bodies
   */
  void set analyzeFunctionBodies(bool analyzeFunctionBodies) {
    this._analyzeFunctionBodies = analyzeFunctionBodies;
  }

  /**
   * Set the maximum number of sources for which AST structures should be kept in the cache to the
   * given size.
   *
   * @param cacheSize the maximum number of sources for which AST structures should be kept in the
   *          cache
   */
  void set cacheSize(int cacheSize) {
    this._cacheSize = cacheSize;
  }

  /**
   * Set whether analysis is to generate dart2js related hint results.
   *
   * @param hint `true` if analysis is to generate dart2js related hint results
   */
  void set dart2jsHint(bool dart2jsHints) {
    this._dart2jsHint = dart2jsHints;
  }

  /**
   * Set whether analysis is to generate hint results (e.g. type inference based information and pub
   * best practices).
   *
   * @param hint `true` if analysis is to generate hint results
   */
  void set hint(bool hint) {
    this._hint = hint;
  }

  /**
   * Set whether incremental analysis should be used.
   *
   * @param incremental `true` if incremental analysis should be used
   */
  void set incremental(bool incremental) {
    this._incremental = incremental;
  }

  /**
   * Set whether analysis is to parse comments.
   *
   * @param preserveComments `true` if analysis is to parse comments
   */
  void set preserveComments(bool preserveComments) {
    this._preserveComments = preserveComments;
  }
}

/**
 * Instances of the class `ChangeNoticeImpl` represent a change to the analysis results
 * associated with a given source.
 *
 * @coverage dart.engine
 */
class ChangeNoticeImpl implements ChangeNotice {
  /**
   * The source for which the result is being reported.
   */
  Source _source;

  /**
   * The fully resolved AST that changed as a result of the analysis, or `null` if the AST was
   * not changed.
   */
  CompilationUnit _compilationUnit;

  /**
   * The errors that changed as a result of the analysis, or `null` if errors were not
   * changed.
   */
  List<AnalysisError> _errors;

  /**
   * The line information associated with the source, or `null` if errors were not changed.
   */
  LineInfo _lineInfo;

  /**
   * An empty array of change notices.
   */
  static List<ChangeNoticeImpl> EMPTY_ARRAY = new List<ChangeNoticeImpl>(0);

  /**
   * Initialize a newly created notice associated with the given source.
   *
   * @param source the source for which the change is being reported
   */
  ChangeNoticeImpl(Source source) {
    this._source = source;
  }

  /**
   * Return the fully resolved AST that changed as a result of the analysis, or `null` if the
   * AST was not changed.
   *
   * @return the fully resolved AST that changed as a result of the analysis
   */
  CompilationUnit get compilationUnit => _compilationUnit;

  /**
   * Return the errors that changed as a result of the analysis, or `null` if errors were not
   * changed.
   *
   * @return the errors that changed as a result of the analysis
   */
  List<AnalysisError> get errors => _errors;

  /**
   * Return the line information associated with the source, or `null` if errors were not
   * changed.
   *
   * @return the line information associated with the source
   */
  LineInfo get lineInfo => _lineInfo;

  /**
   * Return the source for which the result is being reported.
   *
   * @return the source for which the result is being reported
   */
  Source get source => _source;

  /**
   * Set the fully resolved AST that changed as a result of the analysis to the given AST.
   *
   * @param compilationUnit the fully resolved AST that changed as a result of the analysis
   */
  void set compilationUnit(CompilationUnit compilationUnit) {
    this._compilationUnit = compilationUnit;
  }

  /**
   * Set the errors that changed as a result of the analysis to the given errors and set the line
   * information to the given line information.
   *
   * @param errors the errors that changed as a result of the analysis
   * @param lineInfo the line information associated with the source
   */
  void setErrors(List<AnalysisError> errors, LineInfo lineInfo) {
    this._errors = errors;
    this._lineInfo = lineInfo;
    if (lineInfo == null) {
      AnalysisEngine.instance.logger.logError2("No line info: ${_source}", new JavaException());
    }
  }

  String toString() => "Changes for ${_source.fullName}";
}

/**
 * Instances of the class `DelegatingAnalysisContextImpl` extend [AnalysisContextImpl
 ] to delegate sources to the appropriate analysis context. For instance, if the
 * source is in a system library then the analysis context from the [DartSdk] is used.
 *
 * @coverage dart.engine
 */
class DelegatingAnalysisContextImpl extends AnalysisContextImpl {
  /**
   * This references the [InternalAnalysisContext] held onto by the [DartSdk] which is
   * used (instead of this [AnalysisContext]) for SDK sources. This field is set when
   * #setSourceFactory(SourceFactory) is called, and references the analysis context in the
   * [DartUriResolver] in the [SourceFactory], this analysis context assumes that there
   * will be such a resolver.
   */
  InternalAnalysisContext _sdkAnalysisContext;

  void addSourceInfo(Source source, SourceEntry info) {
    if (source.isInSystemLibrary) {
      _sdkAnalysisContext.addSourceInfo(source, info);
    } else {
      super.addSourceInfo(source, info);
    }
  }

  List<AnalysisError> computeErrors(Source source) {
    if (source.isInSystemLibrary) {
      return _sdkAnalysisContext.computeErrors(source);
    } else {
      return super.computeErrors(source);
    }
  }

  List<Source> computeExportedLibraries(Source source) {
    if (source.isInSystemLibrary) {
      return _sdkAnalysisContext.computeExportedLibraries(source);
    } else {
      return super.computeExportedLibraries(source);
    }
  }

  HtmlElement computeHtmlElement(Source source) {
    if (source.isInSystemLibrary) {
      return _sdkAnalysisContext.computeHtmlElement(source);
    } else {
      return super.computeHtmlElement(source);
    }
  }

  List<Source> computeImportedLibraries(Source source) {
    if (source.isInSystemLibrary) {
      return _sdkAnalysisContext.computeImportedLibraries(source);
    } else {
      return super.computeImportedLibraries(source);
    }
  }

  SourceKind computeKindOf(Source source) {
    if (source.isInSystemLibrary) {
      return _sdkAnalysisContext.computeKindOf(source);
    } else {
      return super.computeKindOf(source);
    }
  }

  LibraryElement computeLibraryElement(Source source) {
    if (source.isInSystemLibrary) {
      return _sdkAnalysisContext.computeLibraryElement(source);
    } else {
      return super.computeLibraryElement(source);
    }
  }

  LineInfo computeLineInfo(Source source) {
    if (source.isInSystemLibrary) {
      return _sdkAnalysisContext.computeLineInfo(source);
    } else {
      return super.computeLineInfo(source);
    }
  }

  ResolvableCompilationUnit computeResolvableCompilationUnit(Source source) {
    if (source.isInSystemLibrary) {
      return _sdkAnalysisContext.computeResolvableCompilationUnit(source);
    } else {
      return super.computeResolvableCompilationUnit(source);
    }
  }

  AnalysisErrorInfo getErrors(Source source) {
    if (source.isInSystemLibrary) {
      return _sdkAnalysisContext.getErrors(source);
    } else {
      return super.getErrors(source);
    }
  }

  HtmlElement getHtmlElement(Source source) {
    if (source.isInSystemLibrary) {
      return _sdkAnalysisContext.getHtmlElement(source);
    } else {
      return super.getHtmlElement(source);
    }
  }

  List<Source> getHtmlFilesReferencing(Source source) {
    if (source.isInSystemLibrary) {
      return _sdkAnalysisContext.getHtmlFilesReferencing(source);
    } else {
      return super.getHtmlFilesReferencing(source);
    }
  }

  SourceKind getKindOf(Source source) {
    if (source.isInSystemLibrary) {
      return _sdkAnalysisContext.getKindOf(source);
    } else {
      return super.getKindOf(source);
    }
  }

  List<Source> getLibrariesContaining(Source source) {
    if (source.isInSystemLibrary) {
      return _sdkAnalysisContext.getLibrariesContaining(source);
    } else {
      return super.getLibrariesContaining(source);
    }
  }

  List<Source> getLibrariesDependingOn(Source librarySource) {
    if (librarySource.isInSystemLibrary) {
      return _sdkAnalysisContext.getLibrariesDependingOn(librarySource);
    } else {
      return super.getLibrariesDependingOn(librarySource);
    }
  }

  LibraryElement getLibraryElement(Source source) {
    if (source.isInSystemLibrary) {
      return _sdkAnalysisContext.getLibraryElement(source);
    } else {
      return super.getLibraryElement(source);
    }
  }

  List<Source> get librarySources => ArrayUtils.addAll(super.librarySources, _sdkAnalysisContext.librarySources);

  LineInfo getLineInfo(Source source) {
    if (source.isInSystemLibrary) {
      return _sdkAnalysisContext.getLineInfo(source);
    } else {
      return super.getLineInfo(source);
    }
  }

  Namespace getPublicNamespace(LibraryElement library) {
    Source source = library.source;
    if (source.isInSystemLibrary) {
      return _sdkAnalysisContext.getPublicNamespace(library);
    } else {
      return super.getPublicNamespace(library);
    }
  }

  Namespace getPublicNamespace2(Source source) {
    if (source.isInSystemLibrary) {
      return _sdkAnalysisContext.getPublicNamespace2(source);
    } else {
      return super.getPublicNamespace2(source);
    }
  }

  CompilationUnit getResolvedCompilationUnit(Source unitSource, LibraryElement library) {
    if (unitSource.isInSystemLibrary) {
      return _sdkAnalysisContext.getResolvedCompilationUnit(unitSource, library);
    } else {
      return super.getResolvedCompilationUnit(unitSource, library);
    }
  }

  CompilationUnit getResolvedCompilationUnit2(Source unitSource, Source librarySource) {
    if (unitSource.isInSystemLibrary) {
      return _sdkAnalysisContext.getResolvedCompilationUnit2(unitSource, librarySource);
    } else {
      return super.getResolvedCompilationUnit2(unitSource, librarySource);
    }
  }

  bool isClientLibrary(Source librarySource) {
    if (librarySource.isInSystemLibrary) {
      return _sdkAnalysisContext.isClientLibrary(librarySource);
    } else {
      return super.isClientLibrary(librarySource);
    }
  }

  bool isServerLibrary(Source librarySource) {
    if (librarySource.isInSystemLibrary) {
      return _sdkAnalysisContext.isServerLibrary(librarySource);
    } else {
      return super.isServerLibrary(librarySource);
    }
  }

  CompilationUnit parseCompilationUnit(Source source) {
    if (source.isInSystemLibrary) {
      return _sdkAnalysisContext.parseCompilationUnit(source);
    } else {
      return super.parseCompilationUnit(source);
    }
  }

  HtmlUnit parseHtmlUnit(Source source) {
    if (source.isInSystemLibrary) {
      return _sdkAnalysisContext.parseHtmlUnit(source);
    } else {
      return super.parseHtmlUnit(source);
    }
  }

  void recordLibraryElements(Map<Source, LibraryElement> elementMap) {
    if (elementMap.isEmpty) {
      return;
    }
    Source source = new JavaIterator(elementMap.keys.toSet()).next();
    if (source.isInSystemLibrary) {
      _sdkAnalysisContext.recordLibraryElements(elementMap);
    } else {
      super.recordLibraryElements(elementMap);
    }
  }

  CompilationUnit resolveCompilationUnit(Source source, LibraryElement library) {
    if (source.isInSystemLibrary) {
      return _sdkAnalysisContext.resolveCompilationUnit(source, library);
    } else {
      return super.resolveCompilationUnit(source, library);
    }
  }

  CompilationUnit resolveCompilationUnit2(Source unitSource, Source librarySource) {
    if (unitSource.isInSystemLibrary) {
      return _sdkAnalysisContext.resolveCompilationUnit2(unitSource, librarySource);
    } else {
      return super.resolveCompilationUnit2(unitSource, librarySource);
    }
  }

  HtmlUnit resolveHtmlUnit(Source unitSource) {
    if (unitSource.isInSystemLibrary) {
      return _sdkAnalysisContext.resolveHtmlUnit(unitSource);
    } else {
      return super.resolveHtmlUnit(unitSource);
    }
  }

  void setChangedContents(Source source, String contents, int offset, int oldLength, int newLength) {
    if (source.isInSystemLibrary) {
      _sdkAnalysisContext.setChangedContents(source, contents, offset, oldLength, newLength);
    } else {
      super.setChangedContents(source, contents, offset, oldLength, newLength);
    }
  }

  void setContents(Source source, String contents) {
    if (source.isInSystemLibrary) {
      _sdkAnalysisContext.setContents(source, contents);
    } else {
      super.setContents(source, contents);
    }
  }

  void set sourceFactory(SourceFactory factory) {
    super.sourceFactory = factory;
    DartSdk sdk = factory.dartSdk;
    if (sdk != null) {
      _sdkAnalysisContext = sdk.context as InternalAnalysisContext;
      if (_sdkAnalysisContext is DelegatingAnalysisContextImpl) {
        _sdkAnalysisContext = null;
        throw new IllegalStateException("The context provided by an SDK cannot itself be a delegating analysis context");
      }
    } else {
      throw new IllegalStateException("SourceFactorys provided to DelegatingAnalysisContextImpls must have a DartSdk associated with the provided SourceFactory.");
    }
  }
}

/**
 * Instances of the class `IncrementalAnalysisCache` hold information used to perform
 * incremental analysis.
 *
 * @see AnalysisContextImpl#setChangedContents(Source, String, int, int, int)
 */
class IncrementalAnalysisCache {
  /**
   * Determine if the incremental analysis result can be cached for the next incremental analysis.
   *
   * @param cache the prior incremental analysis cache
   * @param unit the incrementally updated compilation unit
   * @return the cache used for incremental analysis or `null` if incremental analysis results
   *         cannot be cached for the next incremental analysis
   */
  static IncrementalAnalysisCache cacheResult(IncrementalAnalysisCache cache, CompilationUnit unit) {
    if (cache != null && unit != null) {
      return new IncrementalAnalysisCache(cache.librarySource, cache.source, unit, cache.newContents, cache.newContents, 0, 0, 0);
    }
    return null;
  }

  /**
   * Determine if the cache should be cleared.
   *
   * @param cache the prior cache or `null` if none
   * @param source the source being updated (not `null`)
   * @return the cache used for incremental analysis or `null` if incremental analysis cannot
   *         be performed
   */
  static IncrementalAnalysisCache clear(IncrementalAnalysisCache cache, Source source) {
    if (cache == null || cache.source == source) {
      return null;
    }
    return cache;
  }

  /**
   * Determine if incremental analysis can be performed from the given information.
   *
   * @param cache the prior cache or `null` if none
   * @param source the source being updated (not `null`)
   * @param oldContents the original source contents prior to this update (may be `null`)
   * @param newContents the new contents after this incremental change (not `null`)
   * @param offset the offset at which the change occurred
   * @param oldLength the length of the text being replaced
   * @param newLength the length of the replacement text
   * @param sourceEntry the cached entry for the given source or `null` if none
   * @return the cache used for incremental analysis or `null` if incremental analysis cannot
   *         be performed
   */
  static IncrementalAnalysisCache update(IncrementalAnalysisCache cache, Source source, String oldContents, String newContents, int offset, int oldLength, int newLength, SourceEntry sourceEntry) {
    Source librarySource = null;
    CompilationUnit unit = null;
    if (sourceEntry is DartEntryImpl) {
      DartEntryImpl dartEntry = sourceEntry as DartEntryImpl;
      List<Source> librarySources = dartEntry.librariesContaining;
      if (librarySources.length == 1) {
        librarySource = librarySources[0];
        if (librarySource != null) {
          unit = dartEntry.getValue2(DartEntry.RESOLVED_UNIT, librarySource);
        }
      }
    }
    if (cache == null || cache.source != source || unit != null) {
      if (unit == null) {
        return null;
      }
      if (oldContents == null) {
        if (oldLength != 0) {
          return null;
        }
        oldContents = "${newContents.substring(0, offset)}${newContents.substring(offset + newLength)}";
      }
      return new IncrementalAnalysisCache(librarySource, source, unit, oldContents, newContents, offset, oldLength, newLength);
    }
    if (cache.oldLength == 0 && cache.newLength == 0) {
      cache.offset = offset;
      cache.oldLength = oldLength;
      cache.newLength = newLength;
    } else {
      if (cache.offset > offset || offset > cache.offset + cache.newLength) {
        return null;
      }
      cache.newLength += newLength - oldLength;
    }
    cache.newContents = newContents;
    return cache;
  }

  /**
   * Verify that the incrementally parsed and resolved unit in the incremental cache is structurally
   * equivalent to the fully parsed unit.
   *
   * @param cache the prior cache or `null` if none
   * @param source the source of the compilation unit that was parsed (not `null`)
   * @param unit the compilation unit that was just parsed
   * @return the cache used for incremental analysis or `null` if incremental analysis results
   *         cannot be cached for the next incremental analysis
   */
  static IncrementalAnalysisCache verifyStructure(IncrementalAnalysisCache cache, Source source, CompilationUnit unit) {
    if (cache != null && unit != null && cache.source == source) {
      if (!ASTComparator.equals4(cache.resolvedUnit, unit)) {
        return null;
      }
    }
    return cache;
  }

  Source librarySource;

  Source source;

  String oldContents;

  CompilationUnit resolvedUnit;

  String newContents;

  int offset = 0;

  int oldLength = 0;

  int newLength = 0;

  IncrementalAnalysisCache(Source librarySource, Source source, CompilationUnit resolvedUnit, String oldContents, String newContents, int offset, int oldLength, int newLength) {
    this.librarySource = librarySource;
    this.source = source;
    this.resolvedUnit = resolvedUnit;
    this.oldContents = oldContents;
    this.newContents = newContents;
    this.offset = offset;
    this.oldLength = oldLength;
    this.newLength = newLength;
  }

  /**
   * Determine if the cache contains source changes that need to be analyzed
   *
   * @return `true` if the cache contains changes to be analyzed, else `false`
   */
  bool hasWork() => oldLength > 0 || newLength > 0;
}

/**
 * Instances of the class `InstrumentedAnalysisContextImpl` implement an
 * [AnalysisContext] by recording instrumentation data and delegating to
 * another analysis context to do the non-instrumentation work.
 *
 * @coverage dart.engine
 */
class InstrumentedAnalysisContextImpl implements InternalAnalysisContext {
  /**
   * Record an exception that was thrown during analysis.
   *
   * @param instrumentation the instrumentation builder being used to record the exception
   * @param exception the exception being reported
   */
  static void recordAnalysisException(InstrumentationBuilder instrumentation, AnalysisException exception) {
    instrumentation.record(exception);
  }

  /**
   * The unique identifier used to identify this analysis context in the instrumentation data.
   */
  String _contextId = UUID.randomUUID().toString();

  /**
   * The analysis context to which all of the non-instrumentation work is delegated.
   */
  InternalAnalysisContext basis;

  /**
   * Create a new [InstrumentedAnalysisContextImpl] which wraps a new
   * [AnalysisContextImpl] as the basis context.
   */
  InstrumentedAnalysisContextImpl() : this.con1(new DelegatingAnalysisContextImpl());

  /**
   * Create a new [InstrumentedAnalysisContextImpl] with a specified basis context, aka the
   * context to wrap and instrument.
   *
   * @param context some [InstrumentedAnalysisContext] to wrap and instrument
   */
  InstrumentedAnalysisContextImpl.con1(InternalAnalysisContext context) {
    basis = context;
  }

  void addSourceInfo(Source source, SourceEntry info) {
    basis.addSourceInfo(source, info);
  }

  void applyChanges(ChangeSet changeSet) {
    InstrumentationBuilder instrumentation = Instrumentation.builder2("Analysis-applyChanges");
    try {
      instrumentation.metric3("contextId", _contextId);
      basis.applyChanges(changeSet);
    } finally {
      instrumentation.log();
    }
  }

  String computeDocumentationComment(Element element) {
    InstrumentationBuilder instrumentation = Instrumentation.builder2("Analysis-computeDocumentationComment");
    try {
      instrumentation.metric3("contextId", _contextId);
      return basis.computeDocumentationComment(element);
    } finally {
      instrumentation.log();
    }
  }

  List<AnalysisError> computeErrors(Source source) {
    InstrumentationBuilder instrumentation = Instrumentation.builder2("Analysis-computeErrors");
    try {
      instrumentation.metric3("contextId", _contextId);
      List<AnalysisError> errors = basis.computeErrors(source);
      instrumentation.metric2("Errors-count", errors.length);
      return errors;
    } finally {
      instrumentation.log();
    }
  }

  List<Source> computeExportedLibraries(Source source) {
    InstrumentationBuilder instrumentation = Instrumentation.builder2("Analysis-computeExportedLibraries");
    try {
      instrumentation.metric3("contextId", _contextId);
      return basis.computeExportedLibraries(source);
    } finally {
      instrumentation.log();
    }
  }

  HtmlElement computeHtmlElement(Source source) {
    InstrumentationBuilder instrumentation = Instrumentation.builder2("Analysis-computeHtmlElement");
    try {
      instrumentation.metric3("contextId", _contextId);
      return basis.computeHtmlElement(source);
    } on AnalysisException catch (e) {
      recordAnalysisException(instrumentation, e);
      throw e;
    } finally {
      instrumentation.log();
    }
  }

  List<Source> computeImportedLibraries(Source source) {
    InstrumentationBuilder instrumentation = Instrumentation.builder2("Analysis-computeImportedLibraries");
    try {
      instrumentation.metric3("contextId", _contextId);
      return basis.computeImportedLibraries(source);
    } finally {
      instrumentation.log();
    }
  }

  SourceKind computeKindOf(Source source) {
    InstrumentationBuilder instrumentation = Instrumentation.builder2("Analysis-computeKindOf");
    try {
      instrumentation.metric3("contextId", _contextId);
      return basis.computeKindOf(source);
    } finally {
      instrumentation.log();
    }
  }

  LibraryElement computeLibraryElement(Source source) {
    InstrumentationBuilder instrumentation = Instrumentation.builder2("Analysis-computeLibraryElement");
    try {
      instrumentation.metric3("contextId", _contextId);
      return basis.computeLibraryElement(source);
    } on AnalysisException catch (e) {
      recordAnalysisException(instrumentation, e);
      throw e;
    } finally {
      instrumentation.log();
    }
  }

  LineInfo computeLineInfo(Source source) {
    InstrumentationBuilder instrumentation = Instrumentation.builder2("Analysis-computeLineInfo");
    try {
      instrumentation.metric3("contextId", _contextId);
      return basis.computeLineInfo(source);
    } on AnalysisException catch (e) {
      recordAnalysisException(instrumentation, e);
      throw e;
    } finally {
      instrumentation.log();
    }
  }

  ResolvableCompilationUnit computeResolvableCompilationUnit(Source source) => basis.computeResolvableCompilationUnit(source);

  ResolvableHtmlUnit computeResolvableHtmlUnit(Source source) => basis.computeResolvableHtmlUnit(source);

  AnalysisContext extractContext(SourceContainer container) {
    InstrumentationBuilder instrumentation = Instrumentation.builder2("Analysis-extractContext");
    try {
      instrumentation.metric3("contextId", _contextId);
      InstrumentedAnalysisContextImpl newContext = new InstrumentedAnalysisContextImpl();
      basis.extractContextInto(container, newContext.basis);
      return newContext;
    } finally {
      instrumentation.log();
    }
  }

  InternalAnalysisContext extractContextInto(SourceContainer container, InternalAnalysisContext newContext) => basis.extractContextInto(container, newContext);

  AnalysisOptions get analysisOptions {
    InstrumentationBuilder instrumentation = Instrumentation.builder2("Analysis-getAnalysisOptions");
    try {
      instrumentation.metric3("contextId", _contextId);
      return basis.analysisOptions;
    } finally {
      instrumentation.log();
    }
  }

  Element getElement(ElementLocation location) {
    InstrumentationBuilder instrumentation = Instrumentation.builder2("Analysis-getElement");
    try {
      instrumentation.metric3("contextId", _contextId);
      return basis.getElement(location);
    } finally {
      instrumentation.log();
    }
  }

  AnalysisErrorInfo getErrors(Source source) {
    InstrumentationBuilder instrumentation = Instrumentation.builder2("Analysis-getErrors");
    try {
      instrumentation.metric3("contextId", _contextId);
      AnalysisErrorInfo ret = basis.getErrors(source);
      if (ret != null) {
        instrumentation.metric2("Errors-count", ret.errors.length);
      }
      return ret;
    } finally {
      instrumentation.log();
    }
  }

  HtmlElement getHtmlElement(Source source) {
    InstrumentationBuilder instrumentation = Instrumentation.builder2("Analysis-getHtmlElement");
    try {
      instrumentation.metric3("contextId", _contextId);
      return basis.getHtmlElement(source);
    } finally {
      instrumentation.log();
    }
  }

  List<Source> getHtmlFilesReferencing(Source source) {
    InstrumentationBuilder instrumentation = Instrumentation.builder2("Analysis-getHtmlFilesReferencing");
    try {
      instrumentation.metric3("contextId", _contextId);
      List<Source> ret = basis.getHtmlFilesReferencing(source);
      if (ret != null) {
        instrumentation.metric2("Source-count", ret.length);
      }
      return ret;
    } finally {
      instrumentation.log();
    }
  }

  List<Source> get htmlSources {
    InstrumentationBuilder instrumentation = Instrumentation.builder2("Analysis-getHtmlSources");
    try {
      instrumentation.metric3("contextId", _contextId);
      List<Source> ret = basis.htmlSources;
      if (ret != null) {
        instrumentation.metric2("Source-count", ret.length);
      }
      return ret;
    } finally {
      instrumentation.log();
    }
  }

  SourceKind getKindOf(Source source) {
    InstrumentationBuilder instrumentation = Instrumentation.builder2("Analysis-getKindOf");
    try {
      instrumentation.metric3("contextId", _contextId);
      return basis.getKindOf(source);
    } finally {
      instrumentation.log();
    }
  }

  List<Source> get launchableClientLibrarySources {
    InstrumentationBuilder instrumentation = Instrumentation.builder2("Analysis-getLaunchableClientLibrarySources");
    try {
      instrumentation.metric3("contextId", _contextId);
      List<Source> ret = basis.launchableClientLibrarySources;
      if (ret != null) {
        instrumentation.metric2("Source-count", ret.length);
      }
      return ret;
    } finally {
      instrumentation.log();
    }
  }

  List<Source> get launchableServerLibrarySources {
    InstrumentationBuilder instrumentation = Instrumentation.builder2("Analysis-getLaunchableServerLibrarySources");
    try {
      instrumentation.metric3("contextId", _contextId);
      List<Source> ret = basis.launchableServerLibrarySources;
      if (ret != null) {
        instrumentation.metric2("Source-count", ret.length);
      }
      return ret;
    } finally {
      instrumentation.log();
    }
  }

  List<Source> getLibrariesContaining(Source source) {
    InstrumentationBuilder instrumentation = Instrumentation.builder2("Analysis-getLibrariesContaining");
    try {
      instrumentation.metric3("contextId", _contextId);
      List<Source> ret = basis.getLibrariesContaining(source);
      if (ret != null) {
        instrumentation.metric2("Source-count", ret.length);
      }
      return ret;
    } finally {
      instrumentation.log2(2);
    }
  }

  List<Source> getLibrariesDependingOn(Source librarySource) {
    InstrumentationBuilder instrumentation = Instrumentation.builder2("Analysis-getLibrariesDependingOn");
    try {
      instrumentation.metric3("contextId", _contextId);
      List<Source> ret = basis.getLibrariesDependingOn(librarySource);
      if (ret != null) {
        instrumentation.metric2("Source-count", ret.length);
      }
      return ret;
    } finally {
      instrumentation.log();
    }
  }

  LibraryElement getLibraryElement(Source source) {
    InstrumentationBuilder instrumentation = Instrumentation.builder2("Analysis-getLibraryElement");
    try {
      instrumentation.metric3("contextId", _contextId);
      return basis.getLibraryElement(source);
    } finally {
      instrumentation.log();
    }
  }

  List<Source> get librarySources {
    InstrumentationBuilder instrumentation = Instrumentation.builder2("Analysis-getLibrarySources");
    try {
      instrumentation.metric3("contextId", _contextId);
      List<Source> ret = basis.librarySources;
      if (ret != null) {
        instrumentation.metric2("Source-count", ret.length);
      }
      return ret;
    } finally {
      instrumentation.log();
    }
  }

  LineInfo getLineInfo(Source source) {
    InstrumentationBuilder instrumentation = Instrumentation.builder2("Analysis-getLineInfo");
    try {
      instrumentation.metric3("contextId", _contextId);
      return basis.getLineInfo(source);
    } finally {
      instrumentation.log();
    }
  }

  Namespace getPublicNamespace(LibraryElement library) => basis.getPublicNamespace(library);

  Namespace getPublicNamespace2(Source source) => basis.getPublicNamespace2(source);

  List<Source> get refactoringUnsafeSources => basis.refactoringUnsafeSources;

  CompilationUnit getResolvedCompilationUnit(Source unitSource, LibraryElement library) {
    InstrumentationBuilder instrumentation = Instrumentation.builder2("Analysis-getResolvedCompilationUnit");
    try {
      instrumentation.metric3("contextId", _contextId);
      return basis.getResolvedCompilationUnit(unitSource, library);
    } finally {
      instrumentation.log();
    }
  }

  CompilationUnit getResolvedCompilationUnit2(Source unitSource, Source librarySource) {
    InstrumentationBuilder instrumentation = Instrumentation.builder2("Analysis-getResolvedCompilationUnit");
    try {
      instrumentation.metric3("contextId", _contextId);
      return basis.getResolvedCompilationUnit2(unitSource, librarySource);
    } finally {
      instrumentation.log2(2);
    }
  }

  SourceFactory get sourceFactory {
    InstrumentationBuilder instrumentation = Instrumentation.builder2("Analysis-getSourceFactory");
    try {
      instrumentation.metric3("contextId", _contextId);
      return basis.sourceFactory;
    } finally {
      instrumentation.log2(2);
    }
  }

  AnalysisContentStatistics get statistics => basis.statistics;

  TimestampedData<CompilationUnit> internalResolveCompilationUnit(Source unitSource, LibraryElement libraryElement) => basis.internalResolveCompilationUnit(unitSource, libraryElement);

  bool isClientLibrary(Source librarySource) {
    InstrumentationBuilder instrumentation = Instrumentation.builder2("Analysis-isClientLibrary");
    try {
      instrumentation.metric3("contextId", _contextId);
      return basis.isClientLibrary(librarySource);
    } finally {
      instrumentation.log();
    }
  }

  bool isServerLibrary(Source librarySource) {
    InstrumentationBuilder instrumentation = Instrumentation.builder2("Analysis-isServerLibrary");
    try {
      instrumentation.metric3("contextId", _contextId);
      return basis.isServerLibrary(librarySource);
    } finally {
      instrumentation.log();
    }
  }

  void mergeContext(AnalysisContext context) {
    InstrumentationBuilder instrumentation = Instrumentation.builder2("Analysis-mergeContext");
    try {
      instrumentation.metric3("contextId", _contextId);
      if (context is InstrumentedAnalysisContextImpl) {
        context = (context as InstrumentedAnalysisContextImpl).basis;
      }
      basis.mergeContext(context);
    } finally {
      instrumentation.log();
    }
  }

  CompilationUnit parseCompilationUnit(Source source) {
    InstrumentationBuilder instrumentation = Instrumentation.builder2("Analysis-parseCompilationUnit");
    try {
      instrumentation.metric3("contextId", _contextId);
      return basis.parseCompilationUnit(source);
    } on AnalysisException catch (e) {
      recordAnalysisException(instrumentation, e);
      throw e;
    } finally {
      instrumentation.log();
    }
  }

  HtmlUnit parseHtmlUnit(Source source) {
    InstrumentationBuilder instrumentation = Instrumentation.builder2("Analysis-parseHtmlUnit");
    try {
      instrumentation.metric3("contextId", _contextId);
      return basis.parseHtmlUnit(source);
    } on AnalysisException catch (e) {
      recordAnalysisException(instrumentation, e);
      throw e;
    } finally {
      instrumentation.log();
    }
  }

  AnalysisResult performAnalysisTask() {
    InstrumentationBuilder instrumentation = Instrumentation.builder2("Analysis-performAnalysisTask");
    try {
      instrumentation.metric3("contextId", _contextId);
      AnalysisResult result = basis.performAnalysisTask();
      if (result.changeNotices != null) {
        instrumentation.metric2("ChangeNotice-count", result.changeNotices.length);
      }
      return result;
    } finally {
      instrumentation.log2(2);
    }
  }

  void recordLibraryElements(Map<Source, LibraryElement> elementMap) {
    basis.recordLibraryElements(elementMap);
  }

  CompilationUnit resolveCompilationUnit(Source unitSource, LibraryElement library) {
    InstrumentationBuilder instrumentation = Instrumentation.builder2("Analysis-resolveCompilationUnit");
    try {
      instrumentation.metric3("contextId", _contextId);
      return basis.resolveCompilationUnit(unitSource, library);
    } on AnalysisException catch (e) {
      recordAnalysisException(instrumentation, e);
      throw e;
    } finally {
      instrumentation.log();
    }
  }

  CompilationUnit resolveCompilationUnit2(Source unitSource, Source librarySource) {
    InstrumentationBuilder instrumentation = Instrumentation.builder2("Analysis-resolveCompilationUnit");
    try {
      instrumentation.metric3("contextId", _contextId);
      return basis.resolveCompilationUnit2(unitSource, librarySource);
    } on AnalysisException catch (e) {
      recordAnalysisException(instrumentation, e);
      throw e;
    } finally {
      instrumentation.log();
    }
  }

  HtmlUnit resolveHtmlUnit(Source htmlSource) {
    InstrumentationBuilder instrumentation = Instrumentation.builder2("Analysis-resolveHtmlUnit");
    try {
      instrumentation.metric3("contextId", _contextId);
      return basis.resolveHtmlUnit(htmlSource);
    } on AnalysisException catch (e) {
      recordAnalysisException(instrumentation, e);
      throw e;
    } finally {
      instrumentation.log();
    }
  }

  void set analysisOptions(AnalysisOptions options) {
    InstrumentationBuilder instrumentation = Instrumentation.builder2("Analysis-setAnalysisOptions");
    try {
      instrumentation.metric3("contextId", _contextId);
      basis.analysisOptions = options;
    } finally {
      instrumentation.log();
    }
  }

  void set analysisPriorityOrder(List<Source> sources) {
    InstrumentationBuilder instrumentation = Instrumentation.builder2("Analysis-setAnalysisPriorityOrder");
    try {
      instrumentation.metric3("contextId", _contextId);
      basis.analysisPriorityOrder = sources;
    } finally {
      instrumentation.log();
    }
  }

  void setChangedContents(Source source, String contents, int offset, int oldLength, int newLength) {
    InstrumentationBuilder instrumentation = Instrumentation.builder2("Analysis-setChangedContents");
    try {
      instrumentation.metric3("contextId", _contextId);
      basis.setChangedContents(source, contents, offset, oldLength, newLength);
    } finally {
      instrumentation.log();
    }
  }

  void setContents(Source source, String contents) {
    InstrumentationBuilder instrumentation = Instrumentation.builder2("Analysis-setContents");
    try {
      instrumentation.metric3("contextId", _contextId);
      basis.setContents(source, contents);
    } finally {
      instrumentation.log();
    }
  }

  void set sourceFactory(SourceFactory factory) {
    InstrumentationBuilder instrumentation = Instrumentation.builder2("Analysis-setSourceFactory");
    try {
      instrumentation.metric3("contextId", _contextId);
      basis.sourceFactory = factory;
    } finally {
      instrumentation.log();
    }
  }

  Iterable<Source> sourcesToResolve(List<Source> changedSources) {
    InstrumentationBuilder instrumentation = Instrumentation.builder2("Analysis-sourcesToResolve");
    try {
      instrumentation.metric3("contextId", _contextId);
      return basis.sourcesToResolve(changedSources);
    } finally {
      instrumentation.log();
    }
  }
}

/**
 * The interface `InternalAnalysisContext` defines additional behavior for an analysis context
 * that is required by internal users of the context.
 */
abstract class InternalAnalysisContext implements AnalysisContext {
  /**
   * Add the given source with the given information to this context.
   *
   * @param source the source to be added
   * @param info the information about the source
   */
  void addSourceInfo(Source source, SourceEntry info);

  /**
   * Return an array containing the sources of the libraries that are exported by the library with
   * the given source. The array will be empty if the given source is invalid, if the given source
   * does not represent a library, or if the library does not export any other libraries.
   *
   * @param source the source representing the library whose exports are to be returned
   * @return the sources of the libraries that are exported by the given library
   * @throws AnalysisException if the exported libraries could not be computed
   */
  List<Source> computeExportedLibraries(Source source);

  /**
   * Return an array containing the sources of the libraries that are imported by the library with
   * the given source. The array will be empty if the given source is invalid, if the given source
   * does not represent a library, or if the library does not import any other libraries.
   *
   * @param source the source representing the library whose imports are to be returned
   * @return the sources of the libraries that are imported by the given library
   * @throws AnalysisException if the imported libraries could not be computed
   */
  List<Source> computeImportedLibraries(Source source);

  /**
   * Return an AST structure corresponding to the given source, but ensure that the structure has
   * not already been resolved and will not be resolved by any other threads or in any other
   * library.
   *
   * @param source the compilation unit for which an AST structure should be returned
   * @return the AST structure representing the content of the source
   * @throws AnalysisException if the analysis could not be performed
   */
  ResolvableCompilationUnit computeResolvableCompilationUnit(Source source);

  /**
   * Return an AST structure corresponding to the given source, but ensure that the structure has
   * not already been resolved and will not be resolved by any other threads.
   *
   * @param source the compilation unit for which an AST structure should be returned
   * @return the AST structure representing the content of the source
   * @throws AnalysisException if the analysis could not be performed
   */
  ResolvableHtmlUnit computeResolvableHtmlUnit(Source source);

  /**
   * Initialize the specified context by removing the specified sources from the receiver and adding
   * them to the specified context.
   *
   * @param container the container containing sources that should be removed from this context and
   *          added to the returned context
   * @param newContext the context to be initialized
   * @return the analysis context that was initialized
   */
  InternalAnalysisContext extractContextInto(SourceContainer container, InternalAnalysisContext newContext);

  /**
   * Return a namespace containing mappings for all of the public names defined by the given
   * library.
   *
   * @param library the library whose public namespace is to be returned
   * @return the public namespace of the given library
   */
  Namespace getPublicNamespace(LibraryElement library);

  /**
   * Return a namespace containing mappings for all of the public names defined by the library
   * defined by the given source.
   *
   * @param source the source defining the library whose public namespace is to be returned
   * @return the public namespace corresponding to the library defined by the given source
   * @throws AnalysisException if the public namespace could not be computed
   */
  Namespace getPublicNamespace2(Source source);

  /**
   * Returns a statistics about this context.
   */
  AnalysisContentStatistics get statistics;

  /**
   * Return a time-stamped fully-resolved compilation unit for the given source in the given
   * library.
   *
   * @param unitSource the source of the compilation unit for which a resolved AST structure is to
   *          be returned
   * @param libraryElement the element representing the library in which the compilation unit is to
   *          be resolved
   * @return a time-stamped fully-resolved compilation unit for the source
   * @throws AnalysisException if the resolved compilation unit could not be computed
   */
  TimestampedData<CompilationUnit> internalResolveCompilationUnit(Source unitSource, LibraryElement libraryElement);

  /**
   * Given a table mapping the source for the libraries represented by the corresponding elements to
   * the elements representing the libraries, record those mappings.
   *
   * @param elementMap a table mapping the source for the libraries represented by the elements to
   *          the elements representing the libraries
   */
  void recordLibraryElements(Map<Source, LibraryElement> elementMap);
}

/**
 * Container with global [AnalysisContext] performance statistics.
 */
class PerformanceStatistics {
  /**
   * The [TimeCounter] for time spent in scanning.
   */
  static TimeCounter scan = new TimeCounter();

  /**
   * The [TimeCounter] for time spent in parsing.
   */
  static TimeCounter parse = new TimeCounter();

  /**
   * The [TimeCounter] for time spent in resolving.
   */
  static TimeCounter resolve = new TimeCounter();

  /**
   * The [TimeCounter] for time spent in error verifier.
   */
  static TimeCounter errors = new TimeCounter();

  /**
   * The [TimeCounter] for time spent in hints generator.
   */
  static TimeCounter hints = new TimeCounter();
}

/**
 * Instances of the class `RecordingErrorListener` implement an error listener that will
 * record the errors that are reported to it in a way that is appropriate for caching those errors
 * within an analysis context.
 *
 * @coverage dart.engine
 */
class RecordingErrorListener implements AnalysisErrorListener {
  /**
   * A HashMap of lists containing the errors that were collected, keyed by each [Source].
   */
  Map<Source, Set<AnalysisError>> _errors = new Map<Source, Set<AnalysisError>>();

  /**
   * Add all of the errors recorded by the given listener to this listener.
   *
   * @param listener the listener that has recorded the errors to be added
   */
  void addAll(RecordingErrorListener listener) {
    for (AnalysisError error in listener.errors) {
      onError(error);
    }
  }

  /**
   * Answer the errors collected by the listener.
   *
   * @return an array of errors (not `null`, contains no `null`s)
   */
  List<AnalysisError> get errors {
    Iterable<MapEntry<Source, Set<AnalysisError>>> entrySet = getMapEntrySet(_errors);
    int numEntries = entrySet.length;
    if (numEntries == 0) {
      return AnalysisError.NO_ERRORS;
    }
    List<AnalysisError> resultList = new List<AnalysisError>();
    for (MapEntry<Source, Set<AnalysisError>> entry in entrySet) {
      resultList.addAll(entry.getValue());
    }
    return new List.from(resultList);
  }

  /**
   * Answer the errors collected by the listener for some passed [Source].
   *
   * @param source some [Source] for which the caller wants the set of [AnalysisError]s
   *          collected by this listener
   * @return the errors collected by the listener for the passed [Source]
   */
  List<AnalysisError> getErrors2(Source source) {
    Set<AnalysisError> errorsForSource = _errors[source];
    if (errorsForSource == null) {
      return AnalysisError.NO_ERRORS;
    } else {
      return new List.from(errorsForSource);
    }
  }

  void onError(AnalysisError error) {
    Source source = error.source;
    Set<AnalysisError> errorsForSource = _errors[source];
    if (_errors[source] == null) {
      errorsForSource = new Set<AnalysisError>();
      _errors[source] = errorsForSource;
    }
    errorsForSource.add(error);
  }
}

/**
 * Instances of the class `ResolutionEraser` remove any resolution information from an AST
 * structure when used to visit that structure.
 */
class ResolutionEraser extends GeneralizingASTVisitor<Object> {
  Object visitAssignmentExpression(AssignmentExpression node) {
    node.staticElement = null;
    node.propagatedElement = null;
    return super.visitAssignmentExpression(node);
  }

  Object visitBinaryExpression(BinaryExpression node) {
    node.staticElement = null;
    node.propagatedElement = null;
    return super.visitBinaryExpression(node);
  }

  Object visitCompilationUnit(CompilationUnit node) {
    node.element = null;
    return super.visitCompilationUnit(node);
  }

  Object visitConstructorDeclaration(ConstructorDeclaration node) {
    node.element = null;
    return super.visitConstructorDeclaration(node);
  }

  Object visitConstructorName(ConstructorName node) {
    node.staticElement = null;
    return super.visitConstructorName(node);
  }

  Object visitDirective(Directive node) {
    node.element = null;
    return super.visitDirective(node);
  }

  Object visitExpression(Expression node) {
    node.staticType = null;
    node.propagatedType = null;
    return super.visitExpression(node);
  }

  Object visitFunctionExpression(FunctionExpression node) {
    node.element = null;
    return super.visitFunctionExpression(node);
  }

  Object visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    node.staticElement = null;
    node.propagatedElement = null;
    return super.visitFunctionExpressionInvocation(node);
  }

  Object visitIndexExpression(IndexExpression node) {
    node.staticElement = null;
    node.propagatedElement = null;
    return super.visitIndexExpression(node);
  }

  Object visitInstanceCreationExpression(InstanceCreationExpression node) {
    node.staticElement = null;
    return super.visitInstanceCreationExpression(node);
  }

  Object visitPostfixExpression(PostfixExpression node) {
    node.staticElement = null;
    node.propagatedElement = null;
    return super.visitPostfixExpression(node);
  }

  Object visitPrefixExpression(PrefixExpression node) {
    node.staticElement = null;
    node.propagatedElement = null;
    return super.visitPrefixExpression(node);
  }

  Object visitRedirectingConstructorInvocation(RedirectingConstructorInvocation node) {
    node.staticElement = null;
    return super.visitRedirectingConstructorInvocation(node);
  }

  Object visitSimpleIdentifier(SimpleIdentifier node) {
    node.staticElement = null;
    node.propagatedElement = null;
    return super.visitSimpleIdentifier(node);
  }

  Object visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    node.staticElement = null;
    return super.visitSuperConstructorInvocation(node);
  }
}

/**
 * Instances of the class `ResolvableCompilationUnit` represent a compilation unit that is not
 * referenced by any other objects and for which we have modification stamp information. It is used
 * by the [LibraryResolver] to resolve a library.
 */
class ResolvableCompilationUnit extends TimestampedData<CompilationUnit> {
  /**
   * Initialize a newly created holder to hold the given values.
   *
   * @param modificationTime the modification time of the source from which the AST was created
   * @param unit the AST that was created from the source
   */
  ResolvableCompilationUnit(int modificationTime, CompilationUnit unit) : super(modificationTime, unit);

  /**
   * Return the AST that was created from the source.
   *
   * @return the AST that was created from the source
   */
  CompilationUnit get compilationUnit => data;
}

/**
 * Instances of the class `ResolvableHtmlUnit` represent an HTML unit that is not referenced
 * by any other objects and for which we have modification stamp information. It is used by the
 * [ResolveHtmlTask] to resolve an HTML source.
 */
class ResolvableHtmlUnit extends TimestampedData<HtmlUnit> {
  /**
   * Initialize a newly created holder to hold the given values.
   *
   * @param modificationTime the modification time of the source from which the AST was created
   * @param unit the AST that was created from the source
   */
  ResolvableHtmlUnit(int modificationTime, HtmlUnit unit) : super(modificationTime, unit);

  /**
   * Return the AST that was created from the source.
   *
   * @return the AST that was created from the source
   */
  HtmlUnit get compilationUnit => data;
}

/**
 * Instances of the class `TimestampedData` represent analysis data for which we have a
 * modification time.
 */
class TimestampedData<E> {
  /**
   * The modification time of the source from which the data was created.
   */
  int modificationTime = 0;

  /**
   * The data that was created from the source.
   */
  E data;

  /**
   * Initialize a newly created holder to hold the given values.
   *
   * @param modificationTime the modification time of the source from which the data was created
   * @param unit the data that was created from the source
   */
  TimestampedData(int modificationTime, E data) {
    this.modificationTime = modificationTime;
    this.data = data;
  }
}

/**
 * The abstract class `AnalysisTask` defines the behavior of objects used to perform an
 * analysis task.
 */
abstract class AnalysisTask {
  /**
   * The context in which the task is to be performed.
   */
  InternalAnalysisContext context;

  /**
   * The exception that was thrown while performing this task, or `null` if the task completed
   * successfully.
   */
  AnalysisException exception;

  /**
   * Initialize a newly created task to perform analysis within the given context.
   *
   * @param context the context in which the task is to be performed
   */
  AnalysisTask(InternalAnalysisContext context) {
    this.context = context;
  }

  /**
   * Use the given visitor to visit this task.
   *
   * @param visitor the visitor that should be used to visit this task
   * @return the value returned by the visitor
   * @throws AnalysisException if the visitor throws the exception
   */
  accept(AnalysisTaskVisitor visitor);

  /**
   * Perform this analysis task and use the given visitor to visit this task after it has completed.
   *
   * @param visitor the visitor used to visit this task after it has completed
   * @return the value returned by the visitor
   * @throws AnalysisException if the visitor throws the exception
   */
  Object perform(AnalysisTaskVisitor visitor) {
    try {
      safelyPerform();
    } on AnalysisException catch (exception) {
      this.exception = exception;
      AnalysisEngine.instance.logger.logInformation2("Task failed: ${taskDescription}", exception);
    }
    return accept(visitor);
  }

  String toString() => taskDescription;

  /**
   * Return a textual description of this task.
   *
   * @return a textual description of this task
   */
  String get taskDescription;

  /**
   * Perform this analysis task, protected by an exception handler.
   *
   * @throws AnalysisException if an exception occurs while performing the task
   */
  void internalPerform();

  /**
   * Perform this analysis task, ensuring that all exceptions are wrapped in an
   * [AnalysisException].
   *
   * @throws AnalysisException if any exception occurs while performing the task
   */
  void safelyPerform() {
    try {
      internalPerform();
    } on AnalysisException catch (exception) {
      throw exception;
    } on JavaException catch (exception) {
      throw new AnalysisException.con3(exception);
    }
  }
}

/**
 * The interface `AnalysisTaskVisitor` defines the behavior of objects that can visit tasks.
 * While tasks are not structured in any interesting way, this class provides the ability to
 * dispatch to an appropriate method.
 */
abstract class AnalysisTaskVisitor<E> {
  /**
   * Visit a [GenerateDartErrorsTask].
   *
   * @param task the task to be visited
   * @return the result of visiting the task
   * @throws AnalysisException if the visitor throws an exception for some reason
   */
  E visitGenerateDartErrorsTask(GenerateDartErrorsTask task);

  /**
   * Visit a [GenerateDartHintsTask].
   *
   * @param task the task to be visited
   * @return the result of visiting the task
   * @throws AnalysisException if the visitor throws an exception for some reason
   */
  E visitGenerateDartHintsTask(GenerateDartHintsTask task);

  /**
   * Visit an [IncrementalAnalysisTask].
   *
   * @param task the task to be visited
   * @return the result of visiting the task
   * @throws AnalysisException if the visitor throws an exception for some reason
   */
  E visitIncrementalAnalysisTask(IncrementalAnalysisTask incrementalAnalysisTask);

  /**
   * Visit a [ParseDartTask].
   *
   * @param task the task to be visited
   * @return the result of visiting the task
   * @throws AnalysisException if the visitor throws an exception for some reason
   */
  E visitParseDartTask(ParseDartTask task);

  /**
   * Visit a [ParseHtmlTask].
   *
   * @param task the task to be visited
   * @return the result of visiting the task
   * @throws AnalysisException if the visitor throws an exception for some reason
   */
  E visitParseHtmlTask(ParseHtmlTask task);

  /**
   * Visit a [ResolveDartLibraryTask].
   *
   * @param task the task to be visited
   * @return the result of visiting the task
   * @throws AnalysisException if the visitor throws an exception for some reason
   */
  E visitResolveDartLibraryTask(ResolveDartLibraryTask task);

  /**
   * Visit a [ResolveDartUnitTask].
   *
   * @param task the task to be visited
   * @return the result of visiting the task
   * @throws AnalysisException if the visitor throws an exception for some reason
   */
  E visitResolveDartUnitTask(ResolveDartUnitTask task);

  /**
   * Visit a [ResolveHtmlTask].
   *
   * @param task the task to be visited
   * @return the result of visiting the task
   * @throws AnalysisException if the visitor throws an exception for some reason
   */
  E visitResolveHtmlTask(ResolveHtmlTask task);
}

/**
 * Instances of the class `GenerateDartErrorsTask` generate errors and warnings for a single
 * Dart source.
 */
class GenerateDartErrorsTask extends AnalysisTask {
  /**
   * The source for which errors and warnings are to be produced.
   */
  Source source;

  /**
   * The element model for the library containing the source.
   */
  LibraryElement libraryElement;

  /**
   * The time at which the contents of the source were last modified.
   */
  int modificationTime = -1;

  /**
   * The errors that were generated for the source.
   */
  List<AnalysisError> errors;

  /**
   * Initialize a newly created task to perform analysis within the given context.
   *
   * @param context the context in which the task is to be performed
   * @param source the source for which errors and warnings are to be produced
   * @param libraryElement the element model for the library containing the source
   */
  GenerateDartErrorsTask(InternalAnalysisContext context, Source source, LibraryElement libraryElement) : super(context) {
    this.source = source;
    this.libraryElement = libraryElement;
  }

  accept(AnalysisTaskVisitor visitor) => visitor.visitGenerateDartErrorsTask(this);

  String get taskDescription => "generate errors and warnings for ${source.fullName}";

  void internalPerform() {
    InternalAnalysisContext context = this.context;
    TimestampedData<CompilationUnit> data = context.internalResolveCompilationUnit(source, libraryElement);
    TimeCounter_TimeCounterHandle timeCounter = PerformanceStatistics.errors.start();
    try {
      modificationTime = data.modificationTime;
      CompilationUnit unit = data.data;
      RecordingErrorListener errorListener = new RecordingErrorListener();
      ErrorReporter errorReporter = new ErrorReporter(errorListener, source);
      Source coreSource = context.sourceFactory.forUri(DartSdk.DART_CORE);
      LibraryElement coreLibrary = context.getLibraryElement(coreSource);
      TypeProvider typeProvider = new TypeProviderImpl(coreLibrary);
      ConstantVerifier constantVerifier = new ConstantVerifier(errorReporter, typeProvider);
      unit.accept(constantVerifier);
      ErrorVerifier errorVerifier = new ErrorVerifier(errorReporter, libraryElement, typeProvider, new InheritanceManager(libraryElement));
      unit.accept(errorVerifier);
      errors = errorListener.getErrors2(source);
    } finally {
      timeCounter.stop();
    }
  }
}

/**
 * Instances of the class `GenerateDartHintsTask` generate hints for a single Dart library.
 */
class GenerateDartHintsTask extends AnalysisTask {
  /**
   * The element model for the library being analyzed.
   */
  LibraryElement libraryElement;

  /**
   * A table mapping the sources that were analyzed to the hints that were generated for the
   * sources.
   */
  Map<Source, TimestampedData<List<AnalysisError>>> hintMap;

  /**
   * Initialize a newly created task to perform analysis within the given context.
   *
   * @param context the context in which the task is to be performed
   * @param libraryElement the element model for the library being analyzed
   */
  GenerateDartHintsTask(InternalAnalysisContext context, LibraryElement libraryElement) : super(context) {
    this.libraryElement = libraryElement;
  }

  accept(AnalysisTaskVisitor visitor) => visitor.visitGenerateDartHintsTask(this);

  String get taskDescription {
    Source librarySource = libraryElement.source;
    if (librarySource == null) {
      return "generate Dart hints for library without source";
    }
    return "generate Dart hints for ${librarySource.fullName}";
  }

  void internalPerform() {
    RecordingErrorListener errorListener = new RecordingErrorListener();
    List<CompilationUnitElement> parts = libraryElement.parts;
    int partCount = parts.length;
    List<CompilationUnit> compilationUnits = new List<CompilationUnit>(partCount + 1);
    Map<Source, TimestampedData<CompilationUnit>> timestampMap = new Map<Source, TimestampedData<CompilationUnit>>();
    Source unitSource = libraryElement.definingCompilationUnit.source;
    TimestampedData<CompilationUnit> resolvedUnit = getCompilationUnit(unitSource);
    timestampMap[unitSource] = resolvedUnit;
    CompilationUnit unit = resolvedUnit.data;
    if (unit == null) {
      throw new AnalysisException.con1("Internal error: GenerateDartHintsTask failed to access resolved compilation unit for ${unitSource.fullName}");
    }
    compilationUnits[0] = unit;
    for (int i = 0; i < partCount; i++) {
      unitSource = parts[i].source;
      resolvedUnit = getCompilationUnit(unitSource);
      timestampMap[unitSource] = resolvedUnit;
      unit = resolvedUnit.data;
      if (unit == null) {
        throw new AnalysisException.con1("Internal error: GenerateDartHintsTask failed to access resolved compilation unit for ${unitSource.fullName}");
      }
      compilationUnits[i + 1] = unit;
    }
    HintGenerator hintGenerator = new HintGenerator(compilationUnits, context, errorListener);
    hintGenerator.generateForLibrary();
    hintMap = new Map<Source, TimestampedData<List<AnalysisError>>>();
    for (MapEntry<Source, TimestampedData<CompilationUnit>> entry in getMapEntrySet(timestampMap)) {
      Source source = entry.getKey();
      TimestampedData<CompilationUnit> unitData = entry.getValue();
      List<AnalysisError> errors = errorListener.getErrors2(source);
      hintMap[source] = new TimestampedData<List<AnalysisError>>(unitData.modificationTime, errors);
    }
  }

  /**
   * Return the resolved compilation unit associated with the given source.
   *
   * @param unitSource the source for the compilation unit whose resolved AST is to be returned
   * @return the resolved compilation unit associated with the given source
   * @throws AnalysisException if the resolved compilation unit could not be computed
   */
  TimestampedData<CompilationUnit> getCompilationUnit(Source unitSource) => context.internalResolveCompilationUnit(unitSource, libraryElement);
}

/**
 * Instances of the class `IncrementalAnalysisTask` incrementally update existing analysis.
 */
class IncrementalAnalysisTask extends AnalysisTask {
  /**
   * The information used to perform incremental analysis.
   */
  IncrementalAnalysisCache cache;

  /**
   * The compilation unit that was produced by incrementally updating the existing unit.
   */
  CompilationUnit compilationUnit;

  /**
   * Initialize a newly created task to perform analysis within the given context.
   *
   * @param context the context in which the task is to be performed
   * @param cache the incremental analysis cache used to perform the analysis
   */
  IncrementalAnalysisTask(InternalAnalysisContext context, IncrementalAnalysisCache cache) : super(context) {
    this.cache = cache;
  }

  accept(AnalysisTaskVisitor visitor) => visitor.visitIncrementalAnalysisTask(this);

  /**
   * Return the source that is to be incrementally analyzed.
   *
   * @return the source
   */
  Source get source => cache != null ? cache.source : null;

  String get taskDescription => "incremental analysis ${(cache != null ? cache.source : "null")}";

  void internalPerform() {
    if (cache == null) {
      return;
    }
    if (cache.oldLength > 0 || cache.newLength > 30) {
      return;
    }
    CharacterReader reader = new CharSequenceReader(new CharSequence(cache.newContents));
    BooleanErrorListener errorListener = new BooleanErrorListener();
    IncrementalScanner scanner = new IncrementalScanner(cache.source, reader, errorListener);
    Token oldTokens = cache.resolvedUnit.beginToken;
    Token newTokens = scanner.rescan(oldTokens, cache.offset, cache.oldLength, cache.newLength);
    if (errorListener.errorReported) {
      return;
    }
    IncrementalParser parser = new IncrementalParser(cache.source, scanner.tokenMap, AnalysisErrorListener.NULL_LISTENER);
    compilationUnit = parser.reparse(cache.resolvedUnit, scanner.leftToken, scanner.rightToken, cache.offset, cache.offset + cache.oldLength);
  }
}

/**
 * Instances of the class `ParseDartTask` parse a specific source as a Dart file.
 */
class ParseDartTask extends AnalysisTask {
  /**
   * The source to be parsed.
   */
  Source source;

  /**
   * The time at which the contents of the source were last modified.
   */
  int modificationTime = -1;

  /**
   * The line information that was produced.
   */
  LineInfo lineInfo;

  /**
   * The compilation unit that was produced by parsing the source.
   */
  CompilationUnit compilationUnit;

  /**
   * The errors that were produced by scanning and parsing the source.
   */
  List<AnalysisError> errors = AnalysisError.NO_ERRORS;

  /**
   * A flag indicating whether the source contains a 'part of' directive.
   */
  bool _hasPartOfDirective2 = false;

  /**
   * A flag indicating whether the source contains a 'library' directive.
   */
  bool _hasLibraryDirective2 = false;

  /**
   * A set containing the sources referenced by 'export' directives.
   */
  Set<Source> _exportedSources = new Set<Source>();

  /**
   * A set containing the sources referenced by 'import' directives.
   */
  Set<Source> _importedSources = new Set<Source>();

  /**
   * A set containing the sources referenced by 'part' directives.
   */
  Set<Source> _includedSources = new Set<Source>();

  /**
   * Initialize a newly created task to perform analysis within the given context.
   *
   * @param context the context in which the task is to be performed
   * @param source the source to be parsed
   */
  ParseDartTask(InternalAnalysisContext context, Source source) : super(context) {
    this.source = source;
  }

  accept(AnalysisTaskVisitor visitor) => visitor.visitParseDartTask(this);

  /**
   * Return an array containing the sources referenced by 'export' directives, or an empty array if
   * the task has not yet been performed or if an exception occurred.
   *
   * @return an array containing the sources referenced by 'export' directives
   */
  List<Source> get exportedSources => toArray(_exportedSources);

  /**
   * Return an array containing the sources referenced by 'import' directives, or an empty array if
   * the task has not yet been performed or if an exception occurred.
   *
   * @return an array containing the sources referenced by 'import' directives
   */
  List<Source> get importedSources => toArray(_importedSources);

  /**
   * Return an array containing the sources referenced by 'part' directives, or an empty array if
   * the task has not yet been performed or if an exception occurred.
   *
   * @return an array containing the sources referenced by 'part' directives
   */
  List<Source> get includedSources => toArray(_includedSources);

  /**
   * Return `true` if the source contains a 'library' directive, or `false` if the task
   * has not yet been performed or if an exception occurred.
   *
   * @return `true` if the source contains a 'library' directive
   */
  bool hasLibraryDirective() => _hasLibraryDirective2;

  /**
   * Return `true` if the source contains a 'part of' directive, or `false` if the task
   * has not yet been performed or if an exception occurred.
   *
   * @return `true` if the source contains a 'part of' directive
   */
  bool hasPartOfDirective() => _hasPartOfDirective2;

  String get taskDescription {
    if (source == null) {
      return "parse as dart null source";
    }
    return "parse as dart ${source.fullName}";
  }

  void internalPerform() {
    RecordingErrorListener errorListener = new RecordingErrorListener();
    List<Token> token = [null];
    TimeCounter_TimeCounterHandle timeCounterScan = PerformanceStatistics.scan.start();
    try {
      Source_ContentReceiver receiver = new Source_ContentReceiver_11(this, errorListener, token);
      try {
        source.getContents(receiver);
      } on JavaException catch (exception) {
        modificationTime = source.modificationStamp;
        throw new AnalysisException.con3(exception);
      }
    } finally {
      timeCounterScan.stop();
    }
    TimeCounter_TimeCounterHandle timeCounterParse = PerformanceStatistics.parse.start();
    try {
      Parser parser = new Parser(source, errorListener);
      parser.parseFunctionBodies = context.analysisOptions.analyzeFunctionBodies;
      compilationUnit = parser.parseCompilationUnit(token[0]);
      errors = errorListener.getErrors2(source);
      for (Directive directive in compilationUnit.directives) {
        if (directive is ExportDirective) {
          Source exportSource = resolveSource(source, directive as ExportDirective);
          if (exportSource != null) {
            _exportedSources.add(exportSource);
          }
        } else if (directive is ImportDirective) {
          Source importSource = resolveSource(source, directive as ImportDirective);
          if (importSource != null) {
            _importedSources.add(importSource);
          }
        } else if (directive is LibraryDirective) {
          _hasLibraryDirective2 = true;
        } else if (directive is PartDirective) {
          Source partSource = resolveSource(source, directive as PartDirective);
          if (partSource != null) {
            _includedSources.add(partSource);
          }
        } else if (directive is PartOfDirective) {
          _hasPartOfDirective2 = true;
        }
      }
      compilationUnit.lineInfo = lineInfo;
    } finally {
      timeCounterParse.stop();
    }
  }

  /**
   * Return the result of resolving the URI of the given URI-based directive against the URI of the
   * given library, or `null` if the URI is not valid.
   *
   * @param librarySource the source representing the library containing the directive
   * @param directive the directive which URI should be resolved
   * @return the result of resolving the URI against the URI of the library
   */
  Source resolveSource(Source librarySource, UriBasedDirective directive) {
    StringLiteral uriLiteral = directive.uri;
    if (uriLiteral is StringInterpolation) {
      return null;
    }
    String uriContent = uriLiteral.stringValue.trim();
    if (uriContent == null) {
      return null;
    }
    uriContent = Uri.encodeFull(uriContent);
    try {
      parseUriWithException(uriContent);
      return context.sourceFactory.resolveUri(librarySource, uriContent);
    } on URISyntaxException catch (exception) {
      return null;
    }
  }

  /**
   * Efficiently convert the given set of sources to an array.
   *
   * @param sources the set to be converted
   * @return an array containing all of the sources in the given set
   */
  List<Source> toArray(Set<Source> sources) {
    int size = sources.length;
    if (size == 0) {
      return Source.EMPTY_ARRAY;
    }
    return new List.from(sources);
  }
}

class Source_ContentReceiver_11 implements Source_ContentReceiver {
  final ParseDartTask ParseDartTask_this;

  RecordingErrorListener errorListener;

  List<Token> token;

  Source_ContentReceiver_11(this.ParseDartTask_this, this.errorListener, this.token);

  void accept(CharBuffer contents, int modificationTime) {
    doScan(contents, modificationTime);
  }

  void accept2(String contents, int modificationTime) {
    doScan(new CharSequence(contents), modificationTime);
  }

  void doScan(CharSequence contents, int modificationTime) {
    ParseDartTask_this.modificationTime = modificationTime;
    Scanner scanner = new Scanner(ParseDartTask_this.source, new CharSequenceReader(contents), errorListener);
    scanner.preserveComments = ParseDartTask_this.context.analysisOptions.preserveComments;
    token[0] = scanner.tokenize();
    ParseDartTask_this.lineInfo = new LineInfo(scanner.lineStarts);
  }
}

/**
 * Instances of the class `ParseHtmlTask` parse a specific source as an HTML file.
 */
class ParseHtmlTask extends AnalysisTask {
  /**
   * The source to be parsed.
   */
  Source source;

  /**
   * The time at which the contents of the source were last modified.
   */
  int modificationTime = -1;

  /**
   * The line information that was produced.
   */
  LineInfo lineInfo;

  /**
   * The HTML unit that was produced by parsing the source.
   */
  HtmlUnit htmlUnit;

  /**
   * The errors that were produced by scanning and parsing the source.
   */
  List<AnalysisError> errors = AnalysisError.NO_ERRORS;

  /**
   * An array containing the sources of the libraries that are referenced within the HTML.
   */
  List<Source> referencedLibraries = Source.EMPTY_ARRAY;

  /**
   * The name of the 'src' attribute in a HTML tag.
   */
  static String _ATTRIBUTE_SRC = "src";

  /**
   * The name of the 'type' attribute in a HTML tag.
   */
  static String _ATTRIBUTE_TYPE = "type";

  /**
   * The name of the 'script' tag in an HTML file.
   */
  static String _TAG_SCRIPT = "script";

  /**
   * The value of the 'type' attribute of a 'script' tag that indicates that the script is written
   * in Dart.
   */
  static String _TYPE_DART = "application/dart";

  /**
   * Initialize a newly created task to perform analysis within the given context.
   *
   * @param context the context in which the task is to be performed
   * @param source the source to be parsed
   */
  ParseHtmlTask(InternalAnalysisContext context, Source source) : super(context) {
    this.source = source;
  }

  accept(AnalysisTaskVisitor visitor) => visitor.visitParseHtmlTask(this);

  String get taskDescription {
    if (source == null) {
      return "parse as html null source";
    }
    return "parse as html ${source.fullName}";
  }

  void internalPerform() {
    HtmlScanner scanner = new HtmlScanner(source);
    try {
      source.getContents(scanner);
    } on JavaException catch (exception) {
      throw new AnalysisException.con3(exception);
    }
    HtmlScanResult scannerResult = scanner.result;
    modificationTime = scannerResult.modificationTime;
    lineInfo = new LineInfo(scannerResult.lineStarts);
    RecordingErrorListener errorListener = new RecordingErrorListener();
    HtmlParseResult result = new HtmlParser(source, errorListener).parse(scannerResult);
    htmlUnit = result.htmlUnit;
    errors = errorListener.getErrors2(source);
    referencedLibraries = librarySources;
  }

  /**
   * Return the sources of libraries that are referenced in the specified HTML file.
   *
   * @return the sources of libraries that are referenced in the HTML file
   */
  List<Source> get librarySources {
    List<Source> libraries = new List<Source>();
    htmlUnit.accept(new RecursiveXmlVisitor_12(this, libraries));
    if (libraries.isEmpty) {
      return Source.EMPTY_ARRAY;
    }
    return new List.from(libraries);
  }
}

class RecursiveXmlVisitor_12 extends RecursiveXmlVisitor<Object> {
  final ParseHtmlTask ParseHtmlTask_this;

  List<Source> libraries;

  RecursiveXmlVisitor_12(this.ParseHtmlTask_this, this.libraries) : super();

  Object visitHtmlScriptTagNode(HtmlScriptTagNode node) {
    XmlAttributeNode scriptAttribute = null;
    for (XmlAttributeNode attribute in node.attributes) {
      if (javaStringEqualsIgnoreCase(attribute.name.lexeme, ParseHtmlTask._ATTRIBUTE_SRC)) {
        scriptAttribute = attribute;
      }
    }
    if (scriptAttribute != null) {
      try {
        Uri uri = new Uri(path: scriptAttribute.text);
        String fileName = uri.path;
        Source librarySource = ParseHtmlTask_this.context.sourceFactory.resolveUri(ParseHtmlTask_this.source, fileName);
        if (librarySource != null && librarySource.exists()) {
          libraries.add(librarySource);
        }
      } on URISyntaxException catch (e) {
      }
    }
    return super.visitHtmlScriptTagNode(node);
  }
}

/**
 * Instances of the class `ResolveDartLibraryTask` parse a specific Dart library.
 */
class ResolveDartLibraryTask extends AnalysisTask {
  /**
   * The source representing the file whose compilation unit is to be returned.
   */
  Source unitSource;

  /**
   * The source representing the library to be resolved.
   */
  Source librarySource;

  /**
   * The library resolver holding information about the libraries that were resolved.
   */
  LibraryResolver libraryResolver;

  /**
   * Initialize a newly created task to perform analysis within the given context.
   *
   * @param context the context in which the task is to be performed
   * @param unitSource the source representing the file whose compilation unit is to be returned
   * @param librarySource the source representing the library to be resolved
   */
  ResolveDartLibraryTask(InternalAnalysisContext context, Source unitSource, Source librarySource) : super(context) {
    this.unitSource = unitSource;
    this.librarySource = librarySource;
  }

  accept(AnalysisTaskVisitor visitor) => visitor.visitResolveDartLibraryTask(this);

  String get taskDescription {
    if (librarySource == null) {
      return "resolve library null source";
    }
    return "resolve library ${librarySource.fullName}";
  }

  void internalPerform() {
    libraryResolver = new LibraryResolver(context);
    libraryResolver.resolveLibrary(librarySource, true);
  }
}

/**
 * Instances of the class `ResolveDartUnitTask` resolve a single Dart file based on a existing
 * element model.
 */
class ResolveDartUnitTask extends AnalysisTask {
  /**
   * The source that is to be resolved.
   */
  Source source;

  /**
   * The element model for the library containing the source.
   */
  LibraryElement _libraryElement;

  /**
   * The time at which the contents of the source were last modified.
   */
  int modificationTime = -1;

  /**
   * The compilation unit that was resolved by this task.
   */
  CompilationUnit resolvedUnit;

  /**
   * Initialize a newly created task to perform analysis within the given context.
   *
   * @param context the context in which the task is to be performed
   * @param source the source to be parsed
   * @param libraryElement the element model for the library containing the source
   */
  ResolveDartUnitTask(InternalAnalysisContext context, Source source, LibraryElement libraryElement) : super(context) {
    this.source = source;
    this._libraryElement = libraryElement;
  }

  accept(AnalysisTaskVisitor visitor) => visitor.visitResolveDartUnitTask(this);

  /**
   * Return the source for the library containing the source that is to be resolved.
   *
   * @return the source for the library containing the source that is to be resolved
   */
  Source get librarySource => _libraryElement.source;

  String get taskDescription {
    Source librarySource = _libraryElement.source;
    if (librarySource == null) {
      return "resolve unit null source";
    }
    return "resolve unit ${librarySource.fullName}";
  }

  void internalPerform() {
    Source coreLibrarySource = _libraryElement.context.sourceFactory.forUri(DartSdk.DART_CORE);
    LibraryElement coreElement = context.computeLibraryElement(coreLibrarySource);
    TypeProvider typeProvider = new TypeProviderImpl(coreElement);
    ResolvableCompilationUnit resolvableUnit = context.computeResolvableCompilationUnit(source);
    modificationTime = resolvableUnit.modificationTime;
    CompilationUnit unit = resolvableUnit.compilationUnit;
    if (unit == null) {
      throw new AnalysisException.con1("Internal error: computeResolvableCompilationUnit returned a value without a parsed Dart unit");
    }
    new DeclarationResolver().resolve(unit, find(_libraryElement, source));
    RecordingErrorListener errorListener = new RecordingErrorListener();
    TypeResolverVisitor typeResolverVisitor = new TypeResolverVisitor.con2(_libraryElement, source, typeProvider, errorListener);
    unit.accept(typeResolverVisitor);
    InheritanceManager inheritanceManager = new InheritanceManager(_libraryElement);
    ResolverVisitor resolverVisitor = new ResolverVisitor.con2(_libraryElement, source, typeProvider, inheritanceManager, errorListener);
    unit.accept(resolverVisitor);
    for (ProxyConditionalAnalysisError conditionalCode in resolverVisitor.proxyConditionalAnalysisErrors) {
      if (conditionalCode.shouldIncludeErrorCode()) {
        resolverVisitor.reportError(conditionalCode.analysisError);
      }
    }
    TimeCounter_TimeCounterHandle counterHandleErrors = PerformanceStatistics.errors.start();
    try {
      ErrorReporter errorReporter = new ErrorReporter(errorListener, source);
      ErrorVerifier errorVerifier = new ErrorVerifier(errorReporter, _libraryElement, typeProvider, inheritanceManager);
      unit.accept(errorVerifier);
      ConstantVerifier constantVerifier = new ConstantVerifier(errorReporter, typeProvider);
      unit.accept(constantVerifier);
    } finally {
      counterHandleErrors.stop();
    }
    resolvedUnit = unit;
  }

  /**
   * Search the compilation units that are part of the given library and return the element
   * representing the compilation unit with the given source. Return `null` if there is no
   * such compilation unit.
   *
   * @param libraryElement the element representing the library being searched through
   * @param unitSource the source for the compilation unit whose element is to be returned
   * @return the element representing the compilation unit
   */
  CompilationUnitElement find(LibraryElement libraryElement, Source unitSource) {
    CompilationUnitElement element = libraryElement.definingCompilationUnit;
    if (element.source == unitSource) {
      return element;
    }
    for (CompilationUnitElement partElement in libraryElement.parts) {
      if (partElement.source == unitSource) {
        return partElement;
      }
    }
    return null;
  }
}

/**
 * Instances of the class `ResolveHtmlTask` resolve a specific source as an HTML file.
 */
class ResolveHtmlTask extends AnalysisTask {
  /**
   * The source to be resolved.
   */
  Source source;

  /**
   * The time at which the contents of the source were last modified.
   */
  int modificationTime = -1;

  /**
   * The element produced by resolving the source.
   */
  HtmlElement element = null;

  /**
   * The resolution errors that were discovered while resolving the source.
   */
  List<AnalysisError> resolutionErrors = AnalysisError.NO_ERRORS;

  /**
   * Initialize a newly created task to perform analysis within the given context.
   *
   * @param context the context in which the task is to be performed
   * @param source the source to be resolved
   */
  ResolveHtmlTask(InternalAnalysisContext context, Source source) : super(context) {
    this.source = source;
  }

  accept(AnalysisTaskVisitor visitor) => visitor.visitResolveHtmlTask(this);

  String get taskDescription {
    if (source == null) {
      return "resolve as html null source";
    }
    return "resolve as html ${source.fullName}";
  }

  void internalPerform() {
    ResolvableHtmlUnit resolvableHtmlUnit = context.computeResolvableHtmlUnit(source);
    HtmlUnit unit = resolvableHtmlUnit.compilationUnit;
    if (unit == null) {
      throw new AnalysisException.con1("Internal error: computeResolvableHtmlUnit returned a value without a parsed HTML unit");
    }
    modificationTime = resolvableHtmlUnit.modificationTime;
    HtmlUnitBuilder builder = new HtmlUnitBuilder(context);
    element = builder.buildHtmlElement2(source, modificationTime, unit);
    resolutionErrors = builder.errorListener.getErrors2(source);
  }
}

/**
 * The interface `Logger` defines the behavior of objects that can be used to receive
 * information about errors within the analysis engine. Implementations usually write this
 * information to a file, but can also record the information for later use (such as during testing)
 * or even ignore the information.
 *
 * @coverage dart.engine.utilities
 */
abstract class Logger {
  static final Logger NULL = new Logger_NullLogger();

  /**
   * Log the given message as an error.
   *
   * @param message an explanation of why the error occurred or what it means
   */
  void logError(String message);

  /**
   * Log the given exception as one representing an error.
   *
   * @param message an explanation of why the error occurred or what it means
   * @param exception the exception being logged
   */
  void logError2(String message, Exception exception);

  /**
   * Log the given exception as one representing an error.
   *
   * @param exception the exception being logged
   */
  void logError3(Exception exception);

  /**
   * Log the given informational message.
   *
   * @param message an explanation of why the error occurred or what it means
   * @param exception the exception being logged
   */
  void logInformation(String message);

  /**
   * Log the given exception as one representing an informational message.
   *
   * @param message an explanation of why the error occurred or what it means
   * @param exception the exception being logged
   */
  void logInformation2(String message, Exception exception);
}

/**
 * Implementation of [Logger] that does nothing.
 */
class Logger_NullLogger implements Logger {
  void logError(String message) {
  }

  void logError2(String message, Exception exception) {
  }

  void logError3(Exception exception) {
  }

  void logInformation(String message) {
  }

  void logInformation2(String message, Exception exception) {
  }
}