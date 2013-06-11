// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.
library engine;
import 'dart:collection' show HasNextIterator;
import 'java_core.dart';
import 'java_engine.dart';
import 'instrumentation.dart';
import 'error.dart';
import 'source.dart';
import 'scanner.dart' show Token, CharBufferScanner, StringScanner;
import 'ast.dart';
import 'parser.dart' show Parser;
import 'sdk.dart' show DartSdk;
import 'element.dart';
import 'resolver.dart';
import 'html.dart' show XmlTagNode, XmlAttributeNode, RecursiveXmlVisitor, HtmlScanner, HtmlScanResult, HtmlParser, HtmlParseResult, HtmlUnit;
/**
 * The unique instance of the class {@code AnalysisEngine} serves as the entry point for the
 * functionality provided by the analysis engine.
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
  static AnalysisEngine _UniqueInstance = new AnalysisEngine();

  /**
   * Return the unique instance of this class.
   * @return the unique instance of this class
   */
  static AnalysisEngine get instance => _UniqueInstance;

  /**
   * Return {@code true} if the given file name is assumed to contain Dart source code.
   * @param fileName the name of the file being tested
   * @return {@code true} if the given file name is assumed to contain Dart source code
   */
  static bool isDartFileName(String fileName) {
    if (fileName == null) {
      return false;
    }
    return javaStringEqualsIgnoreCase(FileNameUtilities.getExtension(fileName), SUFFIX_DART);
  }

  /**
   * Return {@code true} if the given file name is assumed to contain HTML.
   * @param fileName the name of the file being tested
   * @return {@code true} if the given file name is assumed to contain HTML
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
   * @return the analysis context that was created
   */
  AnalysisContext createAnalysisContext() {
    if (Instrumentation.isNullLogger()) {
      return new DelegatingAnalysisContextImpl();
    } else {
      return new InstrumentedAnalysisContextImpl.con1(new DelegatingAnalysisContextImpl());
    }
  }

  /**
   * Return the logger that should receive information about errors within the analysis engine.
   * @return the logger that should receive information about errors within the analysis engine
   */
  Logger get logger => _logger;

  /**
   * Set the logger that should receive information about errors within the analysis engine to the
   * given logger.
   * @param logger the logger that should receive information about errors within the analysis
   * engine
   */
  void set logger(Logger logger2) {
    this._logger = logger2 == null ? Logger.NULL : logger2;
  }
}
/**
 * The interface {@code AnalysisContext} defines the behavior of objects that represent a context in
 * which a single analysis can be performed and incrementally maintained. The context includes such
 * information as the version of the SDK being analyzed against as well as the package-root used to
 * resolve 'package:' URI's. (Both of which are known indirectly through the {@link SourceFactorysource factory}.)
 * <p>
 * An analysis context also represents the state of the analysis, which includes knowing which
 * sources have been included in the analysis (either directly or indirectly) and the results of the
 * analysis. Sources must be added and removed from the context using the method{@link #applyChanges(ChangeSet)}, which is also used to notify the context when sources have been
 * modified and, consequently, previously known results might have been invalidated.
 * <p>
 * There are two ways to access the results of the analysis. The most common is to use one of the
 * 'get' methods to access the results. The 'get' methods have the advantage that they will always
 * return quickly, but have the disadvantage that if the results are not currently available they
 * will return either nothing or in some cases an incomplete result. The second way to access
 * results is by using one of the 'compute' methods. The 'compute' methods will always attempt to
 * compute the requested results but might block the caller for a significant period of time.
 * <p>
 * When results have been invalidated, have never been computed (as is the case for newly added
 * sources), or have been removed from the cache, they are <b>not</b> automatically recreated. They
 * will only be recreated if one of the 'compute' methods is invoked.
 * <p>
 * However, this is not always acceptable. Some clients need to keep the analysis results
 * up-to-date. For such clients there is a mechanism that allows them to incrementally perform
 * needed analysis and get notified of the consequent changes to the analysis results. This
 * mechanism is realized by the method {@link #performAnalysisTask()}.
 * <p>
 * Analysis engine allows for having more than one context. This can be used, for example, to
 * perform one analysis based on the state of files on disk and a separate analysis based on the
 * state of those files in open editors. It can also be used to perform an analysis based on a
 * proposed future state, such as the state after a refactoring.
 */
abstract class AnalysisContext {

  /**
   * Apply the changes specified by the given change set to this context. Any analysis results that
   * have been invalidated by these changes will be removed.
   * @param changeSet a description of the changes that are to be applied
   */
  void applyChanges(ChangeSet changeSet);

  /**
   * Return the documentation comment for the given element as it appears in the original source
   * (complete with the beginning and ending delimiters), or {@code null} if the element does not
   * have a documentation comment associated with it. This can be a long-running operation if the
   * information needed to access the comment is not cached.
   * @param element the element whose documentation comment is to be returned
   * @return the element's documentation comment
   * @throws AnalysisException if the documentation comment could not be determined because the
   * analysis could not be performed
   */
  String computeDocumentationComment(Element element);

  /**
   * Return an array containing all of the errors associated with the given source. If the errors
   * are not already known then the source will be analyzed in order to determine the errors
   * associated with it.
   * @param source the source whose errors are to be returned
   * @return all of the errors associated with the given source
   * @throws AnalysisException if the errors could not be determined because the analysis could not
   * be performed
   * @see #getErrors(Source)
   */
  List<AnalysisError> computeErrors(Source source);

  /**
   * Return the element model corresponding to the HTML file defined by the given source. If the
   * element model does not yet exist it will be created. The process of creating an element model
   * for an HTML file can long-running, depending on the size of the file and the number of
   * libraries that are defined in it (via script tags) that also need to have a model built for
   * them.
   * @param source the source defining the HTML file whose element model is to be returned
   * @return the element model corresponding to the HTML file defined by the given source
   * @throws AnalysisException if the element model could not be determined because the analysis
   * could not be performed
   * @see #getHtmlElement(Source)
   */
  HtmlElement computeHtmlElement(Source source);

  /**
   * Return the kind of the given source, computing it's kind if it is not already known. Return{@link SourceKind#UNKNOWN} if the source is not contained in this context.
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
   * @param source the source defining the library whose element model is to be returned
   * @return the element model corresponding to the library defined by the given source
   * @throws AnalysisException if the element model could not be determined because the analysis
   * could not be performed
   * @see #getLibraryElement(Source)
   */
  LibraryElement computeLibraryElement(Source source);

  /**
   * Return the line information for the given source, or {@code null} if the source is not of a
   * recognized kind (neither a Dart nor HTML file). If the line information was not previously
   * known it will be created. The line information is used to map offsets from the beginning of the
   * source to line and column pairs.
   * @param source the source whose line information is to be returned
   * @return the line information for the given source
   * @throws AnalysisException if the line information could not be determined because the analysis
   * could not be performed
   * @see #getLineInfo(Source)
   */
  LineInfo computeLineInfo(Source source);

  /**
   * Create a new context in which analysis can be performed. Any sources in the specified container
   * will be removed from this context and added to the newly created context.
   * @param container the container containing sources that should be removed from this context and
   * added to the returned context
   * @return the analysis context that was created
   */
  AnalysisContext extractContext(SourceContainer container);

  /**
   * Return the set of analysis options controlling the behavior of this context.
   * @return the set of analysis options controlling the behavior of this context
   */
  AnalysisOptions get analysisOptions;

  /**
   * Return the element referenced by the given location, or {@code null} if the element is not
   * immediately available or if there is no element with the given location. The latter condition
   * can occur, for example, if the location describes an element from a different context or if the
   * element has been removed from this context as a result of some change since it was originally
   * obtained.
   * @param location the reference describing the element to be returned
   * @return the element referenced by the given location
   */
  Element getElement(ElementLocation location);

  /**
   * Return an analysis error info containing the array of all of the errors and the line info
   * associated with the given source. The array of errors will be empty if the source is not known
   * to this context or if there are no errors in the source. The errors contained in the array can
   * be incomplete.
   * @param source the source whose errors are to be returned
   * @return all of the errors associated with the given source and the line info
   * @see #computeErrors(Source)
   */
  AnalysisErrorInfo getErrors(Source source);

  /**
   * Return the element model corresponding to the HTML file defined by the given source, or{@code null} if the source does not represent an HTML file, the element representing the file
   * has not yet been created, or the analysis of the HTML file failed for some reason.
   * @param source the source defining the HTML file whose element model is to be returned
   * @return the element model corresponding to the HTML file defined by the given source
   * @see #computeHtmlElement(Source)
   */
  HtmlElement getHtmlElement(Source source);

  /**
   * Return the sources for the HTML files that reference the given compilation unit. If the source
   * does not represent a Dart source or is not known to this context, the returned array will be
   * empty. The contents of the array can be incomplete.
   * @param source the source referenced by the returned HTML files
   * @return the sources for the HTML files that reference the given compilation unit
   */
  List<Source> getHtmlFilesReferencing(Source source);

  /**
   * Return an array containing all of the sources known to this context that represent HTML files.
   * The contents of the array can be incomplete.
   * @return the sources known to this context that represent HTML files
   */
  List<Source> get htmlSources;

  /**
   * Return the kind of the given source, or {@code null} if the kind is not known to this context.
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
   * @return the sources known to this context that represent the defining compilation unit of a
   * library that can be run within a browser
   */
  List<Source> get launchableClientLibrarySources;

  /**
   * Return an array containing all of the sources known to this context that represent the defining
   * compilation unit of a library that can be run outside of a browser. The contents of the array
   * can be incomplete.
   * @return the sources known to this context that represent the defining compilation unit of a
   * library that can be run outside of a browser
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
   * @param source the source contained in the returned libraries
   * @return the sources for the libraries containing the given source
   */
  List<Source> getLibrariesContaining(Source source);

  /**
   * Return the sources for the defining compilation units of any libraries that depend on the given
   * library. One library depends on another if it either imports or exports that library.
   * @param librarySource the source for the defining compilation unit of the library being depended
   * on
   * @return the sources for the libraries that depend on the given library
   */
  List<Source> getLibrariesDependingOn(Source librarySource);

  /**
   * Return the element model corresponding to the library defined by the given source, or{@code null} if the element model does not currently exist or if the library cannot be analyzed
   * for some reason.
   * @param source the source defining the library whose element model is to be returned
   * @return the element model corresponding to the library defined by the given source
   */
  LibraryElement getLibraryElement(Source source);

  /**
   * Return an array containing all of the sources known to this context that represent the defining
   * compilation unit of a library. The contents of the array can be incomplete.
   * @return the sources known to this context that represent the defining compilation unit of a
   * library
   */
  List<Source> get librarySources;

  /**
   * Return the line information for the given source, or {@code null} if the line information is
   * not known. The line information is used to map offsets from the beginning of the source to line
   * and column pairs.
   * @param source the source whose line information is to be returned
   * @return the line information for the given source
   * @see #computeLineInfo(Source)
   */
  LineInfo getLineInfo(Source source);

  /**
   * Return a fully resolved AST for a single compilation unit within the given library, or{@code null} if the resolved AST is not already computed.
   * @param unitSource the source of the compilation unit
   * @param library the library containing the compilation unit
   * @return a fully resolved AST for the compilation unit
   * @see #resolveCompilationUnit(Source,LibraryElement)
   */
  CompilationUnit getResolvedCompilationUnit(Source unitSource, LibraryElement library);

  /**
   * Return a fully resolved AST for a single compilation unit within the given library, or{@code null} if the resolved AST is not already computed.
   * @param unitSource the source of the compilation unit
   * @param librarySource the source of the defining compilation unit of the library containing the
   * compilation unit
   * @return a fully resolved AST for the compilation unit
   * @see #resolveCompilationUnit(Source,Source)
   */
  CompilationUnit getResolvedCompilationUnit2(Source unitSource, Source librarySource);

  /**
   * Return the source factory used to create the sources that can be analyzed in this context.
   * @return the source factory used to create the sources that can be analyzed in this context
   */
  SourceFactory get sourceFactory;

  /**
   * Return {@code true} if the given source is known to be the defining compilation unit of a
   * library that can be run on a client (references 'dart:html', either directly or indirectly).
   * <p>
   * <b>Note:</b> In addition to the expected case of returning {@code false} if the source is known
   * to be a library that cannot be run on a client, this method will also return {@code false} if
   * the source is not known to be a library or if we do not know whether it can be run on a client.
   * @param librarySource the source being tested
   * @return {@code true} if the given source is known to be a library that can be run on a client
   */
  bool isClientLibrary(Source librarySource);

  /**
   * Return {@code true} if the given source is known to be the defining compilation unit of a
   * library that can be run on the server (does not reference 'dart:html', either directly or
   * indirectly).
   * <p>
   * <b>Note:</b> In addition to the expected case of returning {@code false} if the source is known
   * to be a library that cannot be run on the server, this method will also return {@code false} if
   * the source is not known to be a library or if we do not know whether it can be run on the
   * server.
   * @param librarySource the source being tested
   * @return {@code true} if the given source is known to be a library that can be run on the server
   */
  bool isServerLibrary(Source librarySource);

  /**
   * Add the sources contained in the specified context to this context's collection of sources.
   * This method is called when an existing context's pubspec has been removed, and the contained
   * sources should be reanalyzed as part of this context.
   * @param context the context being merged
   */
  void mergeContext(AnalysisContext context);

  /**
   * Parse a single source to produce an AST structure. The resulting AST structure may or may not
   * be resolved, and may have a slightly different structure depending upon whether it is resolved.
   * @param source the source to be parsed
   * @return the AST structure representing the content of the source
   * @throws AnalysisException if the analysis could not be performed
   */
  CompilationUnit parseCompilationUnit(Source source);

  /**
   * Parse a single HTML source to produce an AST structure. The resulting HTML AST structure may or
   * may not be resolved, and may have a slightly different structure depending upon whether it is
   * resolved.
   * @param source the HTML source to be parsed
   * @return the parse result (not {@code null})
   * @throws AnalysisException if the analysis could not be performed
   */
  HtmlUnit parseHtmlUnit(Source source);

  /**
   * Perform the next unit of work required to keep the analysis results up-to-date and return
   * information about the consequent changes to the analysis results. If there were no results the
   * returned array will be empty. If there are no more units of work required, then this method
   * returns {@code null}. This method can be long running.
   * @return an array containing notices of changes to the analysis results
   */
  List<ChangeNotice> performAnalysisTask();

  /**
   * Parse and resolve a single source within the given context to produce a fully resolved AST.
   * @param unitSource the source to be parsed and resolved
   * @param library the library containing the source to be resolved
   * @return the result of resolving the AST structure representing the content of the source in the
   * context of the given library
   * @throws AnalysisException if the analysis could not be performed
   * @see #getResolvedCompilationUnit(Source,LibraryElement)
   */
  CompilationUnit resolveCompilationUnit(Source unitSource, LibraryElement library);

  /**
   * Parse and resolve a single source within the given context to produce a fully resolved AST.
   * @param unitSource the source to be parsed and resolved
   * @param librarySource the source of the defining compilation unit of the library containing the
   * source to be resolved
   * @return the result of resolving the AST structure representing the content of the source in the
   * context of the given library
   * @throws AnalysisException if the analysis could not be performed
   * @see #getResolvedCompilationUnit(Source,Source)
   */
  CompilationUnit resolveCompilationUnit2(Source unitSource, Source librarySource);

  /**
   * Parse and resolve a single source within the given context to produce a fully resolved AST.
   * @param htmlSource the source to be parsed and resolved
   * @return the result of resolving the AST structure representing the content of the source
   * @throws AnalysisException if the analysis could not be performed
   */
  HtmlUnit resolveHtmlUnit(Source htmlSource);

  /**
   * Set the set of analysis options controlling the behavior of this context to the given options.
   * Clients can safely assume that all necessary analysis results have been invalidated.
   * @param options the set of analysis options that will control the behavior of this context
   */
  void set analysisOptions(AnalysisOptions options);

  /**
   * Set the contents of the given source to the given contents and mark the source as having
   * changed. This has the effect of overriding the default contents of the source. If the contents
   * are {@code null} the override is removed so that the default contents will be returned.
   * @param source the source whose contents are being overridden
   * @param contents the new contents of the source
   */
  void setContents(Source source, String contents);

  /**
   * Set the source factory used to create the sources that can be analyzed in this context to the
   * given source factory. Clients can safely assume that all analysis results have been
   * invalidated.
   * @param factory the source factory used to create the sources that can be analyzed in this
   * context
   */
  void set sourceFactory(SourceFactory factory);

  /**
   * Given a collection of sources with content that has changed, return an {@link Iterable}identifying the sources that need to be resolved.
   * @param changedSources an array of sources (not {@code null}, contains no {@code null}s)
   * @return An iterable returning the sources to be resolved
   */
  Iterable<Source> sourcesToResolve(List<Source> changedSources);
}
/**
 * The interface {@code AnalysisErrorInfo} contains the analysis errors and line information for the
 * errors.
 */
abstract class AnalysisErrorInfo {

  /**
   * Return the errors that as a result of the analysis, or {@code null} if there were no errors.
   * @return the errors as a result of the analysis
   */
  List<AnalysisError> get errors;

  /**
   * Return the line information associated with the errors, or {@code null} if there were no
   * errors.
   * @return the line information associated with the errors
   */
  LineInfo get lineInfo;
}
/**
 * Instances of the class {@code AnalysisException} represent an exception that occurred during the
 * analysis of one or more sources.
 * @coverage dart.engine
 */
class AnalysisException extends JavaException {

  /**
   * Initialize a newly created exception.
   */
  AnalysisException() : super() {
    _jtd_constructor_125_impl();
  }
  _jtd_constructor_125_impl() {
  }

  /**
   * Initialize a newly created exception to have the given message.
   * @param message the message associated with the exception
   */
  AnalysisException.con1(String message) : super(message) {
    _jtd_constructor_126_impl(message);
  }
  _jtd_constructor_126_impl(String message) {
  }

  /**
   * Initialize a newly created exception to have the given message and cause.
   * @param message the message associated with the exception
   * @param cause the underlying exception that caused this exception
   */
  AnalysisException.con2(String message, Exception cause) : super(message, cause) {
    _jtd_constructor_127_impl(message, cause);
  }
  _jtd_constructor_127_impl(String message, Exception cause) {
  }

  /**
   * Initialize a newly created exception to have the given cause.
   * @param cause the underlying exception that caused this exception
   */
  AnalysisException.con3(Exception cause) : super.withCause(cause) {
    _jtd_constructor_128_impl(cause);
  }
  _jtd_constructor_128_impl(Exception cause) {
  }
}
/**
 * The interface {@code AnalysisOptions} defines the behavior of objects that provide access to a
 * set of analysis options used to control the behavior of an analysis context.
 */
abstract class AnalysisOptions {

  /**
   * Return {@code true} if analysis is to use strict mode. In strict mode, error reporting is based
   * exclusively on the static type information.
   * @return {@code true} if analysis is to use strict mode
   */
  bool get strictMode;
}
/**
 * The interface {@code ChangeNotice} defines the behavior of objects that represent a change to the
 * analysis results associated with a given source.
 * @coverage dart.engine
 */
abstract class ChangeNotice implements AnalysisErrorInfo {

  /**
   * Return the fully resolved AST that changed as a result of the analysis, or {@code null} if the
   * AST was not changed.
   * @return the fully resolved AST that changed as a result of the analysis
   */
  CompilationUnit get compilationUnit;

  /**
   * Return the source for which the result is being reported.
   * @return the source for which the result is being reported
   */
  Source get source;
}
/**
 * Instances of the class {@code ChangeSet} indicate what sources have been added, changed, or
 * removed.
 * @coverage dart.engine
 */
class ChangeSet {

  /**
   * A list containing the sources that have been added.
   */
  List<Source> _added2 = new List<Source>();

  /**
   * A list containing the sources that have been changed.
   */
  List<Source> _changed2 = new List<Source>();

  /**
   * A list containing the sources that have been removed.
   */
  List<Source> _removed2 = new List<Source>();

  /**
   * A list containing the source containers specifying additional sources that have been removed.
   */
  List<SourceContainer> _removedContainers = new List<SourceContainer>();

  /**
   * Record that the specified source has been added and that it's content is the default contents
   * of the source.
   * @param source the source that was added
   */
  void added(Source source) {
    _added2.add(source);
  }

  /**
   * Record that the specified source has been changed and that it's content is the default contents
   * of the source.
   * @param source the source that was changed
   */
  void changed(Source source) {
    _changed2.add(source);
  }

  /**
   * Return a collection of the sources that have been added.
   * @return a collection of the sources that have been added
   */
  List<Source> get added3 => _added2;

  /**
   * Return a collection of sources that have been changed.
   * @return a collection of sources that have been changed
   */
  List<Source> get changed3 => _changed2;

  /**
   * Return a list containing the sources that were removed.
   * @return a list containing the sources that were removed
   */
  List<Source> get removed => _removed2;

  /**
   * Return a list containing the source containers that were removed.
   * @return a list containing the source containers that were removed
   */
  List<SourceContainer> get removedContainers => _removedContainers;

  /**
   * Return {@code true} if this change set does not contain any changes.
   * @return {@code true} if this change set does not contain any changes
   */
  bool isEmpty() => _added2.isEmpty && _changed2.isEmpty && _removed2.isEmpty && _removedContainers.isEmpty;

  /**
   * Record that the specified source has been removed.
   * @param source the source that was removed
   */
  void removed3(Source source) {
    if (source != null) {
      _removed2.add(source);
    }
  }

  /**
   * Record that the specified source container has been removed.
   * @param container the source container that was removed
   */
  void removedContainer(SourceContainer container) {
    if (container != null) {
      _removedContainers.add(container);
    }
  }
}
/**
 * The interface {@code DartEntry} defines the behavior of objects that maintain the information
 * cached by an analysis context about an individual Dart file.
 * @coverage dart.engine
 */
abstract class DartEntry implements SourceEntry {

  /**
   * The data descriptor representing the library element for the library. This data is only
   * available for Dart files that are the defining compilation unit of a library.
   */
  static final DataDescriptor<LibraryElement> ELEMENT = new DataDescriptor<LibraryElement>("DartEntry.ELEMENT");

  /**
   * The data descriptor representing the list of referenced libraries. This data is only available
   * for Dart files that are the defining compilation unit of a library.
   */
  static final DataDescriptor<List<Source>> REFERENCED_LIBRARIES = new DataDescriptor<List<Source>>("DartEntry.REFERENCED_LIBRARIES");

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
   * Return all of the errors associated with the compilation unit that are currently cached.
   * @return all of the errors associated with the compilation unit
   */
  List<AnalysisError> get allErrors;

  /**
   * Return a valid parsed compilation unit, either an unresolved AST structure or the result of
   * resolving the AST structure in the context of some library, or {@code null} if there is no
   * parsed compilation unit available.
   * @return a valid parsed compilation unit
   */
  CompilationUnit get anyParsedCompilationUnit;

  /**
   * Return the result of resolving the compilation unit as part of any library, or {@code null} if
   * there is no cached resolved compilation unit.
   * @return any resolved compilation unit
   */
  CompilationUnit get anyResolvedCompilationUnit;

  /**
   * Return the state of the data represented by the given descriptor in the context of the given
   * library.
   * @param descriptor the descriptor representing the data whose state is to be returned
   * @param librarySource the source of the defining compilation unit of the library that is the
   * context for the data
   * @return the value of the data represented by the given descriptor and library
   */
  CacheState getState2(DataDescriptor<Object> descriptor, Source librarySource);

  /**
   * Return the value of the data represented by the given descriptor in the context of the given
   * library, or {@code null} if the data represented by the descriptor is not in the cache.
   * @param descriptor the descriptor representing which data is to be returned
   * @param librarySource the source of the defining compilation unit of the library that is the
   * context for the data
   * @return the value of the data represented by the given descriptor and library
   */
  Object getValue2(DataDescriptor descriptor, Source librarySource);
  DartEntryImpl get writableCopy;
}
/**
 * Instances of the class {@code DartEntryImpl} implement a {@link DartEntry}.
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
   * The parsed compilation unit, or {@code null} if the parsed compilation unit is not currently
   * cached.
   */
  CompilationUnit _parsedUnit;

  /**
   * The state of the cached parse errors.
   */
  CacheState _parseErrorsState = CacheState.INVALID;

  /**
   * The errors produced while scanning and parsing the compilation unit, or {@code null} if the
   * errors are not currently cached.
   */
  List<AnalysisError> _parseErrors = AnalysisError.NO_ERRORS;

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
   * The state of the cached list of referenced libraries.
   */
  CacheState _referencedLibrariesState = CacheState.INVALID;

  /**
   * The list of libraries referenced (imported or exported) by the library, or an empty array if
   * the list is not currently cached. The list will be empty if the Dart file is a part rather than
   * a library.
   */
  List<Source> _referencedLibraries = Source.EMPTY_ARRAY;

  /**
   * The information known as a result of resolving this compilation unit as part of the library
   * that contains this unit. This field will never be {@code null}.
   */
  DartEntryImpl_ResolutionState _resolutionState = new DartEntryImpl_ResolutionState();

  /**
   * The state of the cached library element.
   */
  CacheState _elementState = CacheState.INVALID;

  /**
   * The element representing the library, or {@code null} if the element is not currently cached.
   */
  LibraryElement _element;

  /**
   * The state of the cached public namespace.
   */
  CacheState _publicNamespaceState = CacheState.INVALID;

  /**
   * The public namespace of the library, or {@code null} if the namespace is not currently cached.
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
   * An integer holding bit masks such as {@link #LAUNCHABLE} and {@link #CLIENT_CODE}.
   */
  int _bitmask = 0;

  /**
   * Mask indicating that this library is launchable: that the file has a main method.
   */
  static int _LAUNCHABLE = 1 << 1;

  /**
   * Mask indicating that the library is client code: that the library depends on the html library.
   * If the library is not "client code", then it is referenced as "server code".
   */
  static int _CLIENT_CODE = 1 << 2;
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
  CacheState getState(DataDescriptor<Object> descriptor) {
    if (identical(descriptor, DartEntry.ELEMENT)) {
      return _elementState;
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
    } else if (identical(descriptor, DartEntry.REFERENCED_LIBRARIES)) {
      return _referencedLibrariesState;
    } else if (identical(descriptor, DartEntry.SOURCE_KIND)) {
      return _sourceKindState;
    } else {
      return super.getState(descriptor);
    }
  }
  CacheState getState2(DataDescriptor<Object> descriptor, Source librarySource2) {
    DartEntryImpl_ResolutionState state = _resolutionState;
    while (state != null) {
      if (librarySource2 == state._librarySource) {
        if (identical(descriptor, DartEntry.RESOLUTION_ERRORS)) {
          return _resolutionState._resolutionErrorsState;
        } else if (identical(descriptor, DartEntry.RESOLVED_UNIT)) {
          return _resolutionState._resolvedUnitState;
        } else {
          throw new IllegalArgumentException("Invalid descriptor: ${descriptor}");
        }
      }
      state = state._nextState;
    }
    ;
    return CacheState.INVALID;
  }
  Object getValue(DataDescriptor descriptor) {
    if (identical(descriptor, DartEntry.ELEMENT)) {
      return _element as Object;
    } else if (identical(descriptor, DartEntry.INCLUDED_PARTS)) {
      return _includedParts as Object;
    } else if (identical(descriptor, DartEntry.IS_CLIENT)) {
      return ((_bitmask & _CLIENT_CODE) != 0 ? true : false) as Object;
    } else if (identical(descriptor, DartEntry.IS_LAUNCHABLE)) {
      return ((_bitmask & _LAUNCHABLE) != 0 ? true : false) as Object;
    } else if (identical(descriptor, DartEntry.PARSE_ERRORS)) {
      return _parseErrors as Object;
    } else if (identical(descriptor, DartEntry.PARSED_UNIT)) {
      return _parsedUnit as Object;
    } else if (identical(descriptor, DartEntry.PUBLIC_NAMESPACE)) {
      return _publicNamespace as Object;
    } else if (identical(descriptor, DartEntry.REFERENCED_LIBRARIES)) {
      return _referencedLibraries as Object;
    } else if (identical(descriptor, DartEntry.SOURCE_KIND)) {
      return _sourceKind as Object;
    }
    return super.getValue(descriptor);
  }
  Object getValue2(DataDescriptor descriptor, Source librarySource2) {
    DartEntryImpl_ResolutionState state = _resolutionState;
    while (state != null) {
      if (librarySource2 == state._librarySource) {
        if (identical(descriptor, DartEntry.RESOLUTION_ERRORS)) {
          return state._resolutionErrors as Object;
        } else if (identical(descriptor, DartEntry.RESOLVED_UNIT)) {
          return state._resolvedUnit as Object;
        } else {
          throw new IllegalArgumentException("Invalid descriptor: ${descriptor}");
        }
      }
      state = state._nextState;
    }
    ;
    if (identical(descriptor, DartEntry.RESOLUTION_ERRORS)) {
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
    _parsedUnitState = CacheState.INVALID;
    invalidateAllResolutionInformation();
  }

  /**
   * Invalidate all of the resolution information associated with the compilation unit.
   */
  void invalidateAllResolutionInformation() {
    _element = null;
    _elementState = CacheState.INVALID;
    _includedParts = Source.EMPTY_ARRAY;
    _includedPartsState = CacheState.INVALID;
    _referencedLibraries = Source.EMPTY_ARRAY;
    _referencedLibrariesState = CacheState.INVALID;
    _bitmask = 0;
    _clientServerState = CacheState.INVALID;
    _launchableState = CacheState.INVALID;
    _publicNamespace = null;
    _publicNamespaceState = CacheState.INVALID;
    _resolutionState.invalidateAllResolutionInformation();
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
    _parsedUnitState = CacheState.ERROR;
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
  }

  /**
   * Record that an error occurred while attempting to scan or parse the entry represented by this
   * entry. This will set the state of all resolution-based information as being in error, but will
   * not change the state of any parse results.
   */
  void recordResolutionError() {
    _element = null;
    _elementState = CacheState.ERROR;
    _includedParts = Source.EMPTY_ARRAY;
    _includedPartsState = CacheState.ERROR;
    _referencedLibraries = Source.EMPTY_ARRAY;
    _referencedLibrariesState = CacheState.ERROR;
    _bitmask = 0;
    _clientServerState = CacheState.ERROR;
    _launchableState = CacheState.ERROR;
    _publicNamespace = null;
    _publicNamespaceState = CacheState.ERROR;
    _resolutionState.recordResolutionError();
  }

  /**
   * Remove any resolution information associated with this compilation unit being part of the given
   * library, presumably because it is no longer part of the library.
   * @param librarySource the source of the defining compilation unit of the library that used to
   * contain this part but no longer does
   */
  void removeResolution(Source librarySource2) {
    if (librarySource2 != null) {
      if (librarySource2 == _resolutionState._librarySource) {
        if (_resolutionState._nextState == null) {
          _resolutionState.invalidateAllResolutionInformation();
        } else {
          _resolutionState = _resolutionState._nextState;
        }
      } else {
        DartEntryImpl_ResolutionState priorState = _resolutionState;
        DartEntryImpl_ResolutionState state = _resolutionState._nextState;
        while (state != null) {
          if (librarySource2 == state._librarySource) {
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
   * @param modificationStamp the earliest time at which the source was last modified before the
   * parsing was started
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
    }
    if (_parseErrorsState != CacheState.VALID) {
      _parseErrors = errors == null ? AnalysisError.NO_ERRORS : errors;
    }
  }
  void setState(DataDescriptor<Object> descriptor, CacheState state) {
    if (identical(descriptor, DartEntry.ELEMENT)) {
      _element = updatedValue(state, _element, null);
      _elementState = state;
    } else if (identical(descriptor, DartEntry.INCLUDED_PARTS)) {
      _includedParts = updatedValue(state, _includedParts, Source.EMPTY_ARRAY);
      _includedPartsState = state;
    } else if (identical(descriptor, DartEntry.IS_CLIENT)) {
      _bitmask = updatedValue2(state, _bitmask, _CLIENT_CODE);
      _clientServerState = state;
    } else if (identical(descriptor, DartEntry.IS_LAUNCHABLE)) {
      _bitmask = updatedValue2(state, _bitmask, _LAUNCHABLE);
      _launchableState = state;
    } else if (identical(descriptor, DartEntry.PARSE_ERRORS)) {
      _parseErrors = updatedValue(state, _parseErrors, AnalysisError.NO_ERRORS);
      _parseErrorsState = state;
    } else if (identical(descriptor, DartEntry.PARSED_UNIT)) {
      _parsedUnit = updatedValue(state, _parsedUnit, null);
      _parsedUnitState = state;
    } else if (identical(descriptor, DartEntry.PUBLIC_NAMESPACE)) {
      _publicNamespace = updatedValue(state, _publicNamespace, null);
      _publicNamespaceState = state;
    } else if (identical(descriptor, DartEntry.REFERENCED_LIBRARIES)) {
      _referencedLibraries = updatedValue(state, _referencedLibraries, Source.EMPTY_ARRAY);
      _referencedLibrariesState = state;
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
   * @param descriptor the descriptor representing the data whose state is to be set
   * @param librarySource the source of the defining compilation unit of the library that is the
   * context for the data
   * @param cacheState the new state of the data represented by the given descriptor
   */
  void setState2(DataDescriptor<Object> descriptor, Source librarySource, CacheState cacheState) {
    DartEntryImpl_ResolutionState state = getOrCreateResolutionState(librarySource);
    if (identical(descriptor, DartEntry.RESOLUTION_ERRORS)) {
      state._resolutionErrors = updatedValue(cacheState, state._resolutionErrors, AnalysisError.NO_ERRORS);
      state._resolutionErrorsState = cacheState;
    } else if (identical(descriptor, DartEntry.RESOLVED_UNIT)) {
      state._resolvedUnit = updatedValue(cacheState, state._resolvedUnit, null);
      state._resolvedUnitState = cacheState;
    } else {
      throw new IllegalArgumentException("Invalid descriptor: ${descriptor}");
    }
  }
  void setValue(DataDescriptor descriptor, Object value) {
    if (identical(descriptor, DartEntry.ELEMENT)) {
      _element = value as LibraryElement;
      _elementState = CacheState.VALID;
    } else if (identical(descriptor, DartEntry.INCLUDED_PARTS)) {
      _includedParts = value == null ? Source.EMPTY_ARRAY : (value as List<Source>);
      _includedPartsState = CacheState.VALID;
    } else if (identical(descriptor, DartEntry.IS_CLIENT)) {
      if (((value as bool))) {
        _bitmask |= _CLIENT_CODE;
      } else {
        _bitmask &= ~_CLIENT_CODE;
      }
      _clientServerState = CacheState.VALID;
    } else if (identical(descriptor, DartEntry.IS_LAUNCHABLE)) {
      if (((value as bool))) {
        _bitmask |= _LAUNCHABLE;
      } else {
        _bitmask &= ~_LAUNCHABLE;
      }
      _launchableState = CacheState.VALID;
    } else if (identical(descriptor, DartEntry.PARSE_ERRORS)) {
      _parseErrors = value == null ? AnalysisError.NO_ERRORS : (value as List<AnalysisError>);
      _parseErrorsState = CacheState.VALID;
    } else if (identical(descriptor, DartEntry.PARSED_UNIT)) {
      _parsedUnit = value as CompilationUnit;
      _parsedUnitState = CacheState.VALID;
    } else if (identical(descriptor, DartEntry.PUBLIC_NAMESPACE)) {
      _publicNamespace = value as Namespace;
      _publicNamespaceState = CacheState.VALID;
    } else if (identical(descriptor, DartEntry.REFERENCED_LIBRARIES)) {
      _referencedLibraries = value == null ? Source.EMPTY_ARRAY : (value as List<Source>);
      _referencedLibrariesState = CacheState.VALID;
    } else if (identical(descriptor, DartEntry.SOURCE_KIND)) {
      _sourceKind = value as SourceKind;
      _sourceKindState = CacheState.VALID;
    } else {
      super.setValue(descriptor, value);
    }
  }

  /**
   * Set the value of the data represented by the given descriptor in the context of the given
   * library to the given value, and set the state of that data to {@link CacheState#VALID}.
   * @param descriptor the descriptor representing which data is to have its value set
   * @param librarySource the source of the defining compilation unit of the library that is the
   * context for the data
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
    }
  }
  void copyFrom(SourceEntryImpl entry) {
    super.copyFrom(entry);
    DartEntryImpl other = entry as DartEntryImpl;
    _sourceKindState = other._sourceKindState;
    _sourceKind = other._sourceKind;
    _parsedUnitState = other._parsedUnitState;
    _parsedUnit = other._parsedUnit;
    _parseErrorsState = other._parseErrorsState;
    _parseErrors = other._parseErrors;
    _includedPartsState = other._includedPartsState;
    _includedParts = other._includedParts;
    _referencedLibrariesState = other._referencedLibrariesState;
    _referencedLibraries = other._referencedLibraries;
    _resolutionState.copyFrom(other._resolutionState);
    _elementState = other._elementState;
    _element = other._element;
    _publicNamespaceState = other._publicNamespaceState;
    _publicNamespace = other._publicNamespace;
    _clientServerState = other._clientServerState;
    _launchableState = other._launchableState;
    _bitmask = other._bitmask;
  }

  /**
   * Return a resolution state for the specified library, creating one as necessary.
   * @param librarySource the library source (not {@code null})
   * @return the resolution state (not {@code null})
   */
  DartEntryImpl_ResolutionState getOrCreateResolutionState(Source librarySource2) {
    DartEntryImpl_ResolutionState state = _resolutionState;
    if (state._librarySource == null) {
      state._librarySource = librarySource2;
      return state;
    }
    while (state._librarySource != librarySource2) {
      if (state._nextState == null) {
        DartEntryImpl_ResolutionState newState = new DartEntryImpl_ResolutionState();
        newState._librarySource = librarySource2;
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
   * @param state the state to which the data is being transitioned
   * @param currentValue the value of the flags before the transition
   * @param bitMask the mask used to access the bit whose state is being set
   * @return the value of the data that should be kept in the cache
   */
  int updatedValue2(CacheState state, int currentValue, int bitMask) {
    if (identical(state, CacheState.VALID)) {
      throw new IllegalArgumentException("Use setValue() to set the state to VALID");
    } else if (identical(state, CacheState.IN_PROCESS)) {
      return currentValue;
    }
    return currentValue &= ~bitMask;
  }
}
/**
 * Instances of the class {@code ResolutionState} represent the information produced by resolving
 * a compilation unit as part of a specific library.
 */
class DartEntryImpl_ResolutionState {

  /**
   * The next resolution state or {@code null} if none.
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
   * The resolved compilation unit, or {@code null} if the resolved compilation unit is not
   * currently cached.
   */
  CompilationUnit _resolvedUnit;

  /**
   * The state of the cached resolution errors.
   */
  CacheState _resolutionErrorsState = CacheState.INVALID;

  /**
   * The errors produced while resolving the compilation unit, or {@code null} if the errors are
   * not currently cached.
   */
  List<AnalysisError> _resolutionErrors = AnalysisError.NO_ERRORS;

  /**
   * Set this state to be exactly like the given state, recursively copying the next state as
   * necessary.
   * @param other the state to be copied
   */
  void copyFrom(DartEntryImpl_ResolutionState other) {
    _librarySource = other._librarySource;
    _resolvedUnitState = other._resolvedUnitState;
    _resolvedUnit = other._resolvedUnit;
    _resolutionErrorsState = other._resolutionErrorsState;
    _resolutionErrors = other._resolutionErrors;
    if (other._nextState != null) {
      _nextState = new DartEntryImpl_ResolutionState();
      _nextState.copyFrom(other._nextState);
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
  }

  /**
   * Record that an error occurred while attempting to scan or parse the entry represented by this
   * entry. This will set the state of all resolution-based information as being in error, but
   * will not change the state of any parse results.
   */
  void recordResolutionError() {
    _nextState = null;
    _librarySource = null;
    _resolvedUnitState = CacheState.ERROR;
    _resolvedUnit = null;
    _resolutionErrorsState = CacheState.ERROR;
    _resolutionErrors = AnalysisError.NO_ERRORS;
  }
}
/**
 * Instances of the class {@code DataDescriptor} are immutable constants representing data that can
 * be stored in the cache.
 */
class DataDescriptor<E> {

  /**
   * The name of the descriptor, used for debugging purposes.
   */
  String _name;

  /**
   * Initialize a newly created descriptor to have the given name.
   * @param name the name of the descriptor
   */
  DataDescriptor(String name) {
    this._name = name;
  }
  String toString() => _name;
}
/**
 * The interface {@code HtmlEntry} defines the behavior of objects that maintain the information
 * cached by an analysis context about an individual HTML file.
 * @coverage dart.engine
 */
abstract class HtmlEntry implements SourceEntry {

  /**
   * The data descriptor representing the HTML element.
   */
  static final DataDescriptor<HtmlElement> ELEMENT = new DataDescriptor<HtmlElement>("HtmlEntry.ELEMENT");

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
   * The data descriptor representing the resolved AST structure.
   */
  static final DataDescriptor<HtmlUnit> RESOLVED_UNIT = new DataDescriptor<HtmlUnit>("HtmlEntry.RESOLVED_UNIT");

  /**
   * Return all of the errors associated with the compilation unit that are currently cached.
   * @return all of the errors associated with the compilation unit
   */
  List<AnalysisError> get allErrors;
  HtmlEntryImpl get writableCopy;
}
/**
 * Instances of the class {@code HtmlEntryImpl} implement an {@link HtmlEntry}.
 * @coverage dart.engine
 */
class HtmlEntryImpl extends SourceEntryImpl implements HtmlEntry {

  /**
   * The state of the cached parsed (but not resolved) HTML unit.
   */
  CacheState _parsedUnitState = CacheState.INVALID;

  /**
   * The parsed HTML unit, or {@code null} if the parsed HTML unit is not currently cached.
   */
  HtmlUnit _parsedUnit;

  /**
   * The state of the cached resolution errors.
   */
  CacheState _resolutionErrorsState = CacheState.INVALID;

  /**
   * The errors produced while resolving the compilation unit, or {@code null} if the errors are not
   * currently cached.
   */
  List<AnalysisError> _resolutionErrors = AnalysisError.NO_ERRORS;

  /**
   * The state of the cached parsed and resolved HTML unit.
   */
  CacheState _resolvedUnitState = CacheState.INVALID;

  /**
   * The resolved HTML unit, or {@code null} if the resolved HTML unit is not currently cached.
   */
  HtmlUnit _resolvedUnit;

  /**
   * The state of the cached list of referenced libraries.
   */
  CacheState _referencedLibrariesState = CacheState.INVALID;

  /**
   * The list of libraries referenced in the HTML, or {@code null} if the list is not currently
   * cached. Note that this list does not include libraries defined directly within the HTML file.
   */
  List<Source> _referencedLibraries = Source.EMPTY_ARRAY;

  /**
   * The state of the cached HTML element.
   */
  CacheState _elementState = CacheState.INVALID;

  /**
   * The element representing the HTML file, or {@code null} if the element is not currently cached.
   */
  HtmlElement _element;
  List<AnalysisError> get allErrors {
    List<AnalysisError> errors = new List<AnalysisError>();
    for (AnalysisError error in _resolutionErrors) {
      errors.add(error);
    }
    if (errors.length == 0) {
      return AnalysisError.NO_ERRORS;
    }
    return new List.from(errors);
  }
  SourceKind get kind => SourceKind.HTML;
  CacheState getState(DataDescriptor<Object> descriptor) {
    if (identical(descriptor, HtmlEntry.ELEMENT)) {
      return _elementState;
    } else if (identical(descriptor, HtmlEntry.PARSED_UNIT)) {
      return _parsedUnitState;
    } else if (identical(descriptor, HtmlEntry.REFERENCED_LIBRARIES)) {
      return _referencedLibrariesState;
    } else if (identical(descriptor, HtmlEntry.RESOLUTION_ERRORS)) {
      return _resolutionErrorsState;
    } else if (identical(descriptor, HtmlEntry.RESOLVED_UNIT)) {
      return _resolvedUnitState;
    }
    return super.getState(descriptor);
  }
  Object getValue(DataDescriptor descriptor) {
    if (identical(descriptor, HtmlEntry.ELEMENT)) {
      return _element as Object;
    } else if (identical(descriptor, HtmlEntry.PARSED_UNIT)) {
      return _parsedUnit as Object;
    } else if (identical(descriptor, HtmlEntry.REFERENCED_LIBRARIES)) {
      return _referencedLibraries as Object;
    } else if (identical(descriptor, HtmlEntry.RESOLUTION_ERRORS)) {
      return _resolutionErrors as Object;
    } else if (identical(descriptor, HtmlEntry.RESOLVED_UNIT)) {
      return _resolvedUnit as Object;
    }
    return super.getValue(descriptor);
  }
  HtmlEntryImpl get writableCopy {
    HtmlEntryImpl copy = new HtmlEntryImpl();
    copy.copyFrom(this);
    return copy;
  }
  void setState(DataDescriptor<Object> descriptor, CacheState state) {
    if (identical(descriptor, HtmlEntry.ELEMENT)) {
      _element = updatedValue(state, _element, null);
      _elementState = state;
    } else if (identical(descriptor, HtmlEntry.PARSED_UNIT)) {
      _parsedUnit = updatedValue(state, _parsedUnit, null);
      _parsedUnitState = state;
    } else if (identical(descriptor, HtmlEntry.REFERENCED_LIBRARIES)) {
      _referencedLibraries = updatedValue(state, _referencedLibraries, Source.EMPTY_ARRAY);
      _referencedLibrariesState = state;
    } else if (identical(descriptor, HtmlEntry.RESOLUTION_ERRORS)) {
      _resolutionErrors = updatedValue(state, _resolutionErrors, AnalysisError.NO_ERRORS);
      _resolutionErrorsState = state;
    } else if (identical(descriptor, HtmlEntry.RESOLVED_UNIT)) {
      _resolvedUnit = updatedValue(state, _resolvedUnit, null);
      _resolvedUnitState = state;
    } else {
      super.setState(descriptor, state);
    }
  }
  void setValue(DataDescriptor descriptor, Object value) {
    if (identical(descriptor, HtmlEntry.ELEMENT)) {
      _element = value as HtmlElement;
      _elementState = CacheState.VALID;
    } else if (identical(descriptor, HtmlEntry.PARSED_UNIT)) {
      _parsedUnit = value as HtmlUnit;
      _parsedUnitState = CacheState.VALID;
    } else if (identical(descriptor, HtmlEntry.REFERENCED_LIBRARIES)) {
      _referencedLibraries = value == null ? Source.EMPTY_ARRAY : (value as List<Source>);
      _referencedLibrariesState = CacheState.VALID;
    } else if (identical(descriptor, HtmlEntry.RESOLUTION_ERRORS)) {
      _resolutionErrors = value as List<AnalysisError>;
      _resolutionErrorsState = CacheState.VALID;
    } else if (identical(descriptor, HtmlEntry.RESOLVED_UNIT)) {
      _resolvedUnit = value as HtmlUnit;
      _resolvedUnitState = CacheState.VALID;
    } else {
      super.setValue(descriptor, value);
    }
  }
  void copyFrom(SourceEntryImpl entry) {
    super.copyFrom(entry);
    HtmlEntryImpl other = entry as HtmlEntryImpl;
    _parsedUnitState = other._parsedUnitState;
    _parsedUnit = other._parsedUnit;
    _referencedLibrariesState = other._referencedLibrariesState;
    _referencedLibraries = other._referencedLibraries;
    _resolutionErrors = other._resolutionErrors;
    _resolutionErrorsState = other._resolutionErrorsState;
    _resolvedUnitState = other._resolvedUnitState;
    _resolvedUnit = other._resolvedUnit;
    _elementState = other._elementState;
    _element = other._element;
  }
}
/**
 * The interface {@code SourceEntry} defines the behavior of objects that maintain the information
 * cached by an analysis context about an individual source, no matter what kind of source it is.
 * <p>
 * Source entries should be treated as if they were immutable unless a writable copy of the entry
 * has been obtained and has not yet been made visible to other threads.
 * @coverage dart.engine
 */
abstract class SourceEntry {

  /**
   * The data descriptor representing the line information.
   */
  static final DataDescriptor<LineInfo> LINE_INFO = new DataDescriptor<LineInfo>("SourceEntry.LINE_INFO");

  /**
   * Return the kind of the source, or {@code null} if the kind is not currently cached.
   * @return the kind of the source
   */
  SourceKind get kind;

  /**
   * Return the most recent time at which the state of the source matched the state represented by
   * this entry.
   * @return the modification time of this entry
   */
  int get modificationTime;

  /**
   * Return the state of the data represented by the given descriptor.
   * @param descriptor the descriptor representing the data whose state is to be returned
   * @return the state of the data represented by the given descriptor
   */
  CacheState getState(DataDescriptor<Object> descriptor);

  /**
   * Return the value of the data represented by the given descriptor, or {@code null} if the data
   * represented by the descriptor is not in the cache.
   * @param descriptor the descriptor representing which data is to be returned
   * @return the value of the data represented by the given descriptor
   */
  Object getValue(DataDescriptor descriptor);

  /**
   * Return a new entry that is initialized to the same state as this entry but that can be
   * modified.
   * @return a writable copy of this entry
   */
  SourceEntryImpl get writableCopy;
}
/**
 * Instances of the abstract class {@code SourceEntryImpl} implement the behavior common to all{@link SourceEntry source entries}.
 * @coverage dart.engine
 */
abstract class SourceEntryImpl implements SourceEntry {

  /**
   * The most recent time at which the state of the source matched the state represented by this
   * entry.
   */
  int _modificationTime = 0;

  /**
   * The state of the cached line information.
   */
  CacheState _lineInfoState = CacheState.INVALID;

  /**
   * The line information computed for the source, or {@code null} if the line information is not
   * currently cached.
   */
  LineInfo _lineInfo;
  int get modificationTime => _modificationTime;
  CacheState getState(DataDescriptor<Object> descriptor) {
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
   * Set the most recent time at which the state of the source matched the state represented by this
   * entry to the given time.
   * @param time the new modification time of this entry
   */
  void set modificationTime(int time) {
    _modificationTime = time;
  }

  /**
   * Set the state of the data represented by the given descriptor to the given state.
   * @param descriptor the descriptor representing the data whose state is to be set
   * @param the new state of the data represented by the given descriptor
   */
  void setState(DataDescriptor<Object> descriptor, CacheState state) {
    if (identical(descriptor, SourceEntry.LINE_INFO)) {
      _lineInfo = updatedValue(state, _lineInfo, null);
      _lineInfoState = state;
    } else {
      throw new IllegalArgumentException("Invalid descriptor: ${descriptor}");
    }
  }

  /**
   * Set the value of the data represented by the given descriptor to the given value.
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

  /**
   * Copy the information from the given cache entry.
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
}
/**
 * Instances of the class {@code AnalysisContextImpl} implement an {@link AnalysisContext analysis
 * context}.
 * @coverage dart.engine
 */
class AnalysisContextImpl implements InternalAnalysisContext {

  /**
   * The set of analysis options controlling the behavior of this context.
   */
  AnalysisOptions _options = new AnalysisOptionsImpl();

  /**
   * The source factory used to create the sources that can be analyzed in this context.
   */
  SourceFactory _sourceFactory;

  /**
   * A table mapping the sources known to the context to the information known about the source.
   */
  Map<Source, SourceEntry> _sourceMap = new Map<Source, SourceEntry>();

  /**
   * A table mapping sources to the change notices that are waiting to be returned related to that
   * source.
   */
  Map<Source, ChangeNoticeImpl> _pendingNotices = new Map<Source, ChangeNoticeImpl>();

  /**
   * A list containing the most recently accessed sources with the most recently used at the end of
   * the list. When more sources are added than the maximum allowed then the least recently used
   * source will be removed and will have it's cached AST structure flushed.
   */
  List<Source> _recentlyUsed = new List<Source>();

  /**
   * The object used to synchronize access to all of the caches.
   */
  Object _cacheLock = new Object();

  /**
   * The maximum number of sources for which data should be kept in the cache.
   */
  static int _MAX_CACHE_SIZE = 64;

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
   * The number of times that the flushing of information from the cache has been disabled without
   * being re-enabled.
   */
  int _cacheRemovalCount = 0;
  void addSourceInfo(Source source, SourceEntry info) {
    _sourceMap[source] = info;
  }
  void applyChanges(ChangeSet changeSet) {
    if (changeSet.isEmpty()) {
      return;
    }
    {
      List<Source> removedSources = new List<Source>.from(changeSet.removed);
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
        for (MapEntry<Source, SourceEntry> mapEntry in getMapEntrySet(_sourceMap)) {
          if (!mapEntry.getKey().isInSystemLibrary() && mapEntry.getValue() is DartEntry) {
            DartEntryImpl dartCopy = ((mapEntry.getValue() as DartEntry)).writableCopy;
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
        Comment comment = ((nameNode as AnnotatedNode)).documentationComment;
        if (comment == null) {
          return null;
        }
        JavaStringBuilder builder = new JavaStringBuilder();
        for (Token token in comment.tokens) {
          builder.append(token.lexeme);
        }
        return builder.toString();
      }
      nameNode = nameNode.parent;
    }
    return null;
  }
  List<AnalysisError> computeErrors(Source source) {
    {
      SourceEntry sourceEntry = getSourceEntry(source);
      if (sourceEntry is DartEntry) {
        DartEntry dartEntry = sourceEntry as DartEntry;
        CacheState parseErrorsState = dartEntry.getState(DartEntry.PARSE_ERRORS);
        if (parseErrorsState != CacheState.VALID && parseErrorsState != CacheState.ERROR) {
          parseCompilationUnit(source);
          dartEntry = getSourceEntry(source) as DartEntry;
        }
        List<Source> libraries = getLibrariesContaining(source);
        for (Source librarySource in libraries) {
          CacheState resolutionErrorsState = dartEntry.getState2(DartEntry.RESOLUTION_ERRORS, librarySource);
          if (resolutionErrorsState != CacheState.VALID && resolutionErrorsState != CacheState.ERROR) {
          }
        }
        return dartEntry.allErrors;
      } else if (sourceEntry is HtmlEntry) {
        HtmlEntry htmlEntry = sourceEntry as HtmlEntry;
        CacheState resolutionErrorsState = htmlEntry.getState(HtmlEntry.RESOLUTION_ERRORS);
        if (resolutionErrorsState != CacheState.VALID && resolutionErrorsState != CacheState.ERROR) {
          computeHtmlElement(source);
          htmlEntry = getSourceEntry(source) as HtmlEntry;
        }
        return htmlEntry.getValue(HtmlEntry.RESOLUTION_ERRORS);
      }
      return AnalysisError.NO_ERRORS;
    }
  }
  HtmlElement computeHtmlElement(Source source) {
    if (!AnalysisEngine.isHtmlFileName(source.shortName)) {
      return null;
    }
    {
      HtmlEntry htmlEntry = getHtmlEntry(source);
      if (htmlEntry == null) {
        return null;
      }
      HtmlElement element = htmlEntry.getValue(HtmlEntry.ELEMENT);
      if (element == null) {
        HtmlUnit unit = htmlEntry.getValue(HtmlEntry.RESOLVED_UNIT);
        if (unit == null) {
          unit = htmlEntry.getValue(HtmlEntry.PARSED_UNIT);
          if (unit == null) {
            unit = parseHtmlUnit(source);
          }
        }
        HtmlUnitBuilder builder = new HtmlUnitBuilder(this);
        element = builder.buildHtmlElement2(source, unit);
        List<AnalysisError> resolutionErrors = builder.errorListener.getErrors2(source);
        HtmlEntryImpl htmlCopy = getHtmlEntry(source).writableCopy;
        htmlCopy.setValue(HtmlEntry.RESOLVED_UNIT, unit);
        htmlCopy.setValue(HtmlEntry.RESOLUTION_ERRORS, resolutionErrors);
        htmlCopy.setValue(HtmlEntry.ELEMENT, element);
        _sourceMap[source] = htmlCopy;
        getNotice(source).setErrors(htmlCopy.allErrors, htmlCopy.getValue(SourceEntry.LINE_INFO));
      }
      return element;
    }
  }
  SourceKind computeKindOf(Source source) {
    {
      SourceEntry sourceEntry = getSourceEntry(source);
      if (sourceEntry == null) {
        return SourceKind.UNKNOWN;
      } else if (sourceEntry is DartEntry) {
        DartEntry dartEntry = sourceEntry as DartEntry;
        CacheState sourceKindState = dartEntry.getState(DartEntry.SOURCE_KIND);
        if (sourceKindState != CacheState.VALID && sourceKindState != CacheState.ERROR) {
          internalComputeKindOf(source);
          sourceEntry = getSourceEntry(source);
        }
      }
      return sourceEntry.kind;
    }
  }
  LibraryElement computeLibraryElement(Source source) {
    {
      DartEntry dartEntry = getDartEntry(source);
      if (dartEntry == null) {
        return null;
      }
      LibraryElement element = dartEntry.getValue(DartEntry.ELEMENT);
      if (element == null) {
        LibraryResolver resolver = new LibraryResolver(this);
        try {
          element = resolver.resolveLibrary(source, true);
          recordResolutionResults(resolver);
        } on AnalysisException catch (exception) {
          DartEntryImpl dartCopy = getDartEntry(source).writableCopy;
          dartCopy.setState(DartEntry.ELEMENT, CacheState.ERROR);
          _sourceMap[source] = dartCopy;
          AnalysisEngine.instance.logger.logError2("Could not resolve the library ${source.fullName}", exception);
        }
      }
      return element;
    }
  }
  LineInfo computeLineInfo(Source source) {
    {
      SourceEntry sourceEntry = getSourceEntry(source);
      if (sourceEntry == null) {
        return null;
      }
      LineInfo lineInfo = sourceEntry.getValue(SourceEntry.LINE_INFO);
      if (lineInfo == null) {
        if (sourceEntry is HtmlEntry) {
          parseHtmlUnit(source);
          lineInfo = getSourceEntry(source).getValue(SourceEntry.LINE_INFO);
        } else if (sourceEntry is DartEntry) {
          parseCompilationUnit(source);
          lineInfo = getSourceEntry(source).getValue(SourceEntry.LINE_INFO);
        }
      }
      return lineInfo;
    }
  }
  CompilationUnit computeResolvableCompilationUnit(Source source) {
    {
      DartEntry dartEntry = getDartEntry(source);
      if (dartEntry == null) {
        return null;
      }
      CompilationUnit unit = dartEntry.anyParsedCompilationUnit;
      if (unit != null) {
        return unit.accept(new ASTCloner()) as CompilationUnit;
      }
      DartEntryImpl dartCopy = dartEntry.writableCopy;
      unit = internalParseCompilationUnit(dartCopy, source);
      dartCopy.setState(DartEntry.PARSED_UNIT, CacheState.FLUSHED);
      _sourceMap[source] = dartCopy;
      return unit;
    }
  }
  AnalysisContext extractContext(SourceContainer container) => extractContextInto(container, (AnalysisEngine.instance.createAnalysisContext() as InternalAnalysisContext));
  InternalAnalysisContext extractContextInto(SourceContainer container, InternalAnalysisContext newContext) {
    List<Source> sourcesToRemove = new List<Source>();
    {
      for (MapEntry<Source, SourceEntry> entry in getMapEntrySet(_sourceMap)) {
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
    List<String> components = ((location as ElementLocationImpl)).components;
    ElementImpl element;
    {
      Source librarySource = _sourceFactory.fromEncoding(components[0]);
      try {
        element = computeLibraryElement(librarySource) as ElementImpl;
      } on AnalysisException catch (exception) {
        return null;
      }
    }
    for (int i = 1; i < components.length; i++) {
      if (element == null) {
        return null;
      }
      element = element.getChild(components[i]);
    }
    return element;
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
      return ((sourceEntry as HtmlEntry)).getValue(HtmlEntry.ELEMENT);
    }
    return null;
  }
  List<Source> getHtmlFilesReferencing(Source source) {
    {
      List<Source> htmlSources = new List<Source>();
      while (true) {
        if (getKindOf(source) == SourceKind.LIBRARY) {
        } else if (getKindOf(source) == SourceKind.PART) {
          List<Source> librarySources = getLibrariesContaining(source);
          for (MapEntry<Source, SourceEntry> entry in getMapEntrySet(_sourceMap)) {
            if (identical(entry.getValue().kind, SourceKind.HTML)) {
              List<Source> referencedLibraries = ((entry.getValue() as HtmlEntry)).getValue(HtmlEntry.REFERENCED_LIBRARIES);
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
      if (AnalysisEngine.isHtmlFileName(source.shortName)) {
        return SourceKind.HTML;
      }
      return SourceKind.UNKNOWN;
    }
    return sourceEntry.kind;
  }
  List<Source> get launchableClientLibrarySources {
    List<Source> sources = new List<Source>();
    {
      for (MapEntry<Source, SourceEntry> entry in getMapEntrySet(_sourceMap)) {
        Source source = entry.getKey();
        SourceEntry sourceEntry = entry.getValue();
        if (identical(sourceEntry.kind, SourceKind.LIBRARY) && !source.isInSystemLibrary()) {
          sources.add(source);
        }
      }
    }
    return new List.from(sources);
  }
  List<Source> get launchableServerLibrarySources {
    List<Source> sources = new List<Source>();
    {
      for (MapEntry<Source, SourceEntry> entry in getMapEntrySet(_sourceMap)) {
        Source source = entry.getKey();
        SourceEntry sourceEntry = entry.getValue();
        if (identical(sourceEntry.kind, SourceKind.LIBRARY) && !source.isInSystemLibrary()) {
          sources.add(source);
        }
      }
    }
    return new List.from(sources);
  }
  List<Source> getLibrariesContaining(Source source) {
    {
      List<Source> librarySources = new List<Source>();
      for (MapEntry<Source, SourceEntry> entry in getMapEntrySet(_sourceMap)) {
        if (identical(entry.getValue().kind, SourceKind.LIBRARY)) {
          if (contains(((entry.getValue() as DartEntry)).getValue(DartEntry.INCLUDED_PARTS), source)) {
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
      for (MapEntry<Source, SourceEntry> entry in getMapEntrySet(_sourceMap)) {
        if (identical(entry.getValue().kind, SourceKind.LIBRARY)) {
          if (contains(((entry.getValue() as DartEntry)).getValue(DartEntry.REFERENCED_LIBRARIES), librarySource)) {
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
      return ((sourceEntry as DartEntry)).getValue(DartEntry.ELEMENT);
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
    {
      DartEntry dartEntry = getDartEntry(source);
      if (dartEntry == null) {
        return null;
      }
      Namespace namespace = dartEntry.getValue(DartEntry.PUBLIC_NAMESPACE);
      if (namespace == null) {
        NamespaceBuilder builder = new NamespaceBuilder();
        namespace = builder.createPublicNamespace(library);
        DartEntryImpl dartCopy = dartEntry.writableCopy;
        dartCopy.setValue(DartEntry.PUBLIC_NAMESPACE, namespace);
        _sourceMap[source] = dartCopy;
      }
      return namespace;
    }
  }
  Namespace getPublicNamespace2(Source source) {
    {
      DartEntry dartEntry = getDartEntry(source);
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
        DartEntryImpl dartCopy = dartEntry.writableCopy;
        dartCopy.setValue(DartEntry.PUBLIC_NAMESPACE, namespace);
        _sourceMap[source] = dartCopy;
      }
      return namespace;
    }
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
      return ((sourceEntry as DartEntry)).getValue2(DartEntry.RESOLVED_UNIT, librarySource);
    }
    return null;
  }
  SourceFactory get sourceFactory => _sourceFactory;
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
    {
      for (MapEntry<Source, SourceEntry> entry in getMapEntrySet(((context as AnalysisContextImpl))._sourceMap)) {
        Source newSource = entry.getKey();
        SourceEntry existingEntry = getSourceEntry(newSource);
        if (existingEntry == null) {
          _sourceMap[newSource] = entry.getValue().writableCopy;
        } else {
        }
      }
    }
  }
  CompilationUnit parseCompilationUnit(Source source) {
    {
      accessed(source);
      DartEntry dartEntry = getDartEntry(source);
      if (dartEntry == null) {
        return null;
      }
      CompilationUnit unit = dartEntry.anyParsedCompilationUnit;
      if (unit == null) {
        DartEntryImpl dartCopy = dartEntry.writableCopy;
        unit = internalParseCompilationUnit(dartCopy, source);
        _sourceMap[source] = dartCopy;
      }
      return unit;
    }
  }
  HtmlUnit parseHtmlUnit(Source source) {
    {
      accessed(source);
      HtmlEntry htmlEntry = getHtmlEntry(source);
      if (htmlEntry == null) {
        return null;
      }
      HtmlUnit unit = htmlEntry.getValue(HtmlEntry.RESOLVED_UNIT);
      if (unit == null) {
        unit = htmlEntry.getValue(HtmlEntry.PARSED_UNIT);
        if (unit == null) {
          HtmlParseResult result = new HtmlParser(source).parse(scanHtml(source));
          unit = result.htmlUnit;
          HtmlEntryImpl htmlCopy = htmlEntry.writableCopy;
          htmlCopy.setValue(SourceEntry.LINE_INFO, new LineInfo(result.lineStarts));
          htmlCopy.setValue(HtmlEntry.PARSED_UNIT, unit);
          htmlCopy.setValue(HtmlEntry.REFERENCED_LIBRARIES, getLibrarySources2(source, unit));
          _sourceMap[source] = htmlCopy;
        }
      }
      return unit;
    }
  }
  List<ChangeNotice> performAnalysisTask() {
    {
      if (!performSingleAnalysisTask() && _pendingNotices.isEmpty) {
        return null;
      }
      if (_pendingNotices.isEmpty) {
        return ChangeNoticeImpl.EMPTY_ARRAY;
      }
      List<ChangeNotice> notices = new List.from(_pendingNotices.values);
      _pendingNotices.clear();
      return notices;
    }
  }
  void recordLibraryElements(Map<Source, LibraryElement> elementMap) {
    Source htmlSource = _sourceFactory.forUri(DartSdk.DART_HTML);
    {
      for (MapEntry<Source, LibraryElement> entry in getMapEntrySet(elementMap)) {
        Source librarySource = entry.getKey();
        LibraryElement library = entry.getValue();
        DartEntry dartEntry = getDartEntry(librarySource);
        if (dartEntry != null) {
          DartEntryImpl dartCopy = dartEntry.writableCopy;
          recordElementData(dartCopy, library, htmlSource);
          _sourceMap[librarySource] = dartCopy;
        }
      }
    }
  }
  CompilationUnit resolveCompilationUnit(Source source2, LibraryElement library) {
    if (library == null) {
      return null;
    }
    return resolveCompilationUnit2(source2, library.source);
  }
  CompilationUnit resolveCompilationUnit2(Source unitSource, Source librarySource) {
    {
      accessed(unitSource);
      DartEntry dartEntry = getDartEntry(unitSource);
      if (dartEntry == null) {
        return null;
      }
      CompilationUnit unit = dartEntry.getValue2(DartEntry.RESOLVED_UNIT, librarySource);
      if (unit == null) {
        disableCacheRemoval();
        try {
          LibraryElement libraryElement = computeLibraryElement(librarySource);
          unit = dartEntry.getValue2(DartEntry.RESOLVED_UNIT, librarySource);
          if (unit == null && libraryElement != null) {
            Source coreLibrarySource = libraryElement.context.sourceFactory.forUri(DartSdk.DART_CORE);
            LibraryElement coreElement = computeLibraryElement(coreLibrarySource);
            TypeProvider typeProvider = new TypeProviderImpl(coreElement);
            CompilationUnit unitAST = computeResolvableCompilationUnit(unitSource);
            new DeclarationResolver().resolve(unitAST, find(libraryElement, unitSource));
            RecordingErrorListener errorListener = new RecordingErrorListener();
            TypeResolverVisitor typeResolverVisitor = new TypeResolverVisitor.con2(libraryElement, unitSource, typeProvider, errorListener);
            unitAST.accept(typeResolverVisitor);
            ResolverVisitor resolverVisitor = new ResolverVisitor.con2(libraryElement, unitSource, typeProvider, errorListener);
            unitAST.accept(resolverVisitor);
            ErrorReporter errorReporter = new ErrorReporter(errorListener, unitSource);
            ErrorVerifier errorVerifier = new ErrorVerifier(errorReporter, libraryElement, typeProvider, new InheritanceManager(libraryElement));
            unitAST.accept(errorVerifier);
            ConstantVerifier constantVerifier = new ConstantVerifier(errorReporter, typeProvider);
            unitAST.accept(constantVerifier);
            unitAST.resolutionErrors = errorListener.errors;
            DartEntryImpl dartCopy = getDartEntry(unitSource).writableCopy;
            dartCopy.setValue2(DartEntry.RESOLVED_UNIT, librarySource, unitAST);
            _sourceMap[unitSource] = dartCopy;
            unit = unitAST;
          }
        } finally {
          enableCacheRemoval();
        }
      }
      return unit;
    }
  }
  HtmlUnit resolveHtmlUnit(Source unitSource) {
    {
      accessed(unitSource);
      HtmlEntry htmlEntry = getHtmlEntry(unitSource);
      if (htmlEntry == null) {
        return null;
      }
      HtmlUnit unit = htmlEntry.getValue(HtmlEntry.RESOLVED_UNIT);
      if (unit == null) {
        disableCacheRemoval();
        try {
          computeHtmlElement(unitSource);
          unit = htmlEntry.getValue(HtmlEntry.RESOLVED_UNIT);
          if (unit == null) {
            unit = parseHtmlUnit(unitSource);
          }
        } finally {
          enableCacheRemoval();
        }
      }
      return unit;
    }
  }
  void set analysisOptions(AnalysisOptions options2) {
    {
      this._options = options2;
      invalidateAllResults();
    }
  }
  void setContents(Source source, String contents) {
    {
      _sourceFactory.setContents(source, contents);
      sourceChanged(source);
    }
  }
  void set sourceFactory(SourceFactory factory) {
    if (identical(_sourceFactory, factory)) {
      return;
    } else if (factory.context != null) {
      throw new IllegalStateException("Source factories cannot be shared between contexts");
    }
    {
      if (_sourceFactory != null) {
        _sourceFactory.context = null;
      }
      factory.context = this;
      _sourceFactory = factory;
      invalidateAllResults();
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
   * Return a list of the sources that would be processed by {@link #performAnalysisTask()}. This
   * method is intended to be used for testing purposes only.
   * @return a list of the sources that would be processed by {@link #performAnalysisTask()}
   */
  List<Source> get sourcesNeedingProcessing {
    List<Source> sources = new List<Source>();
    {
      for (MapEntry<Source, SourceEntry> entry in getMapEntrySet(_sourceMap)) {
        SourceEntry sourceEntry = entry.getValue();
        if (sourceEntry is DartEntry) {
          DartEntry dartEntry = sourceEntry as DartEntry;
          CacheState parsedUnitState = dartEntry.getState(DartEntry.PARSED_UNIT);
          CacheState elementState = dartEntry.getState(DartEntry.ELEMENT);
          if (identical(parsedUnitState, CacheState.INVALID) || identical(elementState, CacheState.INVALID)) {
            sources.add(entry.getKey());
          }
        } else if (sourceEntry is HtmlEntry) {
          HtmlEntry htmlEntry = sourceEntry as HtmlEntry;
          CacheState parsedUnitState = htmlEntry.getState(HtmlEntry.PARSED_UNIT);
          CacheState resolvedUnitState = htmlEntry.getState(HtmlEntry.RESOLVED_UNIT);
          if (identical(parsedUnitState, CacheState.INVALID) || identical(resolvedUnitState, CacheState.INVALID)) {
            sources.add(entry.getKey());
          }
        }
      }
    }
    return sources;
  }

  /**
   * Record that the given source was just accessed for some unspecified purpose.
   * <p>
   * Note: This method must only be invoked while we are synchronized on {@link #cacheLock}.
   * @param source the source that was accessed
   */
  void accessed(Source source) {
    if (_recentlyUsed.contains(source)) {
      _recentlyUsed.remove(source);
      _recentlyUsed.add(source);
      return;
    }
    if (_cacheRemovalCount == 0 && _recentlyUsed.length >= _MAX_CACHE_SIZE) {
      Source removedSource = _recentlyUsed.removeAt(0);
      SourceEntry sourceEntry = _sourceMap[removedSource];
      if (sourceEntry is HtmlEntry) {
        HtmlEntryImpl htmlCopy = ((sourceEntry as HtmlEntry)).writableCopy;
        htmlCopy.setState(HtmlEntry.PARSED_UNIT, CacheState.FLUSHED);
        htmlCopy.setState(HtmlEntry.RESOLVED_UNIT, CacheState.FLUSHED);
        _sourceMap[removedSource] = htmlCopy;
      } else if (sourceEntry is DartEntry) {
        DartEntryImpl dartCopy = ((sourceEntry as DartEntry)).writableCopy;
        dartCopy.setState(DartEntry.PARSED_UNIT, CacheState.FLUSHED);
        for (Source librarySource in getLibrariesContaining(source)) {
          dartCopy.setState2(DartEntry.RESOLVED_UNIT, librarySource, CacheState.FLUSHED);
        }
        _sourceMap[removedSource] = dartCopy;
      }
    }
    _recentlyUsed.add(source);
  }

  /**
   * Add all of the sources contained in the given source container to the given list of sources.
   * <p>
   * Note: This method must only be invoked while we are synchronized on {@link #cacheLock}.
   * @param sources the list to which sources are to be added
   * @param container the source container containing the sources to be added to the list
   */
  void addSourcesInContainer(List<Source> sources, SourceContainer container) {
    for (Source source in _sourceMap.keys.toSet()) {
      if (container.contains(source)) {
        sources.add(source);
      }
    }
  }

  /**
   * Return {@code true} if the given array of sources contains the given source.
   * @param sources the sources being searched
   * @param targetSource the source being searched for
   * @return {@code true} if the given source is in the array
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
   * Return {@code true} if the given array of sources contains any of the given target sources.
   * @param sources the sources being searched
   * @param targetSources the sources being searched for
   * @return {@code true} if any of the given target sources are in the array
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
   * object that was created, or {@code null} if the source should not be tracked by this context.
   * @param source the source for which an information object is being created
   * @return the source information object that was created
   */
  SourceEntry createSourceEntry(Source source) {
    String name = source.shortName;
    if (AnalysisEngine.isHtmlFileName(name)) {
      HtmlEntry htmlEntry = new HtmlEntryImpl();
      _sourceMap[source] = htmlEntry;
      return htmlEntry;
    } else {
      DartEntry dartEntry = new DartEntryImpl();
      _sourceMap[source] = dartEntry;
      return dartEntry;
    }
  }

  /**
   * Disable flushing information from the cache until {@link #enableCacheRemoval()} has been
   * called.
   */
  void disableCacheRemoval() {
    _cacheRemovalCount++;
  }

  /**
   * Re-enable flushing information from the cache.
   */
  void enableCacheRemoval() {
    if (_cacheRemovalCount > 0) {
      _cacheRemovalCount--;
    }
    if (_cacheRemovalCount == 0) {
      while (_recentlyUsed.length >= _MAX_CACHE_SIZE) {
        Source removedSource = _recentlyUsed.removeAt(0);
        SourceEntry sourceEntry = _sourceMap[removedSource];
        if (sourceEntry is HtmlEntry) {
          HtmlEntryImpl htmlCopy = ((sourceEntry as HtmlEntry)).writableCopy;
          htmlCopy.setState(HtmlEntry.PARSED_UNIT, CacheState.FLUSHED);
          htmlCopy.setState(HtmlEntry.RESOLVED_UNIT, CacheState.FLUSHED);
          _sourceMap[removedSource] = htmlCopy;
        } else if (sourceEntry is DartEntry) {
          DartEntryImpl dartCopy = ((sourceEntry as DartEntry)).writableCopy;
          dartCopy.setState(DartEntry.PARSED_UNIT, CacheState.FLUSHED);
          for (Source librarySource in getLibrariesContaining(removedSource)) {
            dartCopy.setState2(DartEntry.RESOLVED_UNIT, librarySource, CacheState.FLUSHED);
          }
          _sourceMap[removedSource] = dartCopy;
        }
      }
    }
  }

  /**
   * Search the compilation units that are part of the given library and return the element
   * representing the compilation unit with the given source. Return {@code null} if there is no
   * such compilation unit.
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

  /**
   * Return the compilation unit information associated with the given source, or {@code null} if
   * the source is not known to this context. This method should be used to access the compilation
   * unit information rather than accessing the compilation unit map directly because sources in the
   * SDK are implicitly part of every analysis context and are therefore only added to the map when
   * first accessed.
   * <p>
   * <b>Note:</b> This method must only be invoked while we are synchronized on {@link #cacheLock}.
   * @param source the source for which information is being sought
   * @return the compilation unit information associated with the given source
   */
  DartEntry getDartEntry(Source source) {
    SourceEntry sourceEntry = getSourceEntry(source);
    if (sourceEntry == null) {
      sourceEntry = new DartEntryImpl();
      _sourceMap[source] = sourceEntry;
      return sourceEntry as DartEntry;
    } else if (sourceEntry is DartEntry) {
      return sourceEntry as DartEntry;
    }
    return null;
  }

  /**
   * Return the HTML unit information associated with the given source, or {@code null} if the
   * source is not known to this context. This method should be used to access the HTML unit
   * information rather than accessing the HTML unit map directly because sources in the SDK are
   * implicitly part of every analysis context and are therefore only added to the map when first
   * accessed.
   * <p>
   * <b>Note:</b> This method must only be invoked while we are synchronized on {@link #cacheLock}.
   * @param source the source for which information is being sought
   * @return the HTML unit information associated with the given source
   */
  HtmlEntry getHtmlEntry(Source source) {
    SourceEntry sourceEntry = getSourceEntry(source);
    if (sourceEntry == null) {
      sourceEntry = new HtmlEntryImpl();
      _sourceMap[source] = sourceEntry;
      return sourceEntry as HtmlEntry;
    } else if (sourceEntry is HtmlEntry) {
      return sourceEntry as HtmlEntry;
    }
    return null;
  }

  /**
   * Return the sources of libraries that are referenced in the specified HTML file.
   * @param htmlSource the source of the HTML file being analyzed
   * @param htmlUnit the AST for the HTML file being analyzed
   * @return the sources of libraries that are referenced in the HTML file
   */
  List<Source> getLibrarySources2(Source htmlSource, HtmlUnit htmlUnit) {
    List<Source> libraries = new List<Source>();
    htmlUnit.accept(new RecursiveXmlVisitor_6(this, htmlSource, libraries));
    if (libraries.isEmpty) {
      return Source.EMPTY_ARRAY;
    }
    return new List.from(libraries);
  }

  /**
   * Return a change notice for the given source, creating one if one does not already exist.
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
   * Return the cache entry associated with the given source, or {@code null} if there is no entry
   * associated with the source.
   * @param source the source for which a cache entry is being sought
   * @return the source cache entry associated with the given source
   */
  SourceEntry getReadableSourceEntry(Source source) {
    {
      return _sourceMap[source];
    }
  }

  /**
   * Return the source information associated with the given source, or {@code null} if the source
   * is not known to this context. This method should be used to access the source information
   * rather than accessing the source map directly because sources in the SDK are implicitly part of
   * every analysis context and are therefore only added to the map when first accessed.
   * <p>
   * <b>Note:</b> This method must only be invoked while we are synchronized on {@link #cacheLock}.
   * @param source the source for which information is being sought
   * @return the source information associated with the given source
   */
  SourceEntry getSourceEntry(Source source) {
    SourceEntry sourceEntry = _sourceMap[source];
    if (sourceEntry == null) {
      sourceEntry = createSourceEntry(source);
    }
    return sourceEntry;
  }

  /**
   * Return an array containing all of the sources known to this context that have the given kind.
   * @param kind the kind of sources to be returned
   * @return all of the sources known to this context that have the given kind
   */
  List<Source> getSources(SourceKind kind2) {
    List<Source> sources = new List<Source>();
    {
      for (MapEntry<Source, SourceEntry> entry in getMapEntrySet(_sourceMap)) {
        if (identical(entry.getValue().kind, kind2)) {
          sources.add(entry.getKey());
        }
      }
    }
    return new List.from(sources);
  }

  /**
   * Return {@code true} if the given compilation unit has a part-of directive but no library
   * directive.
   * @param unit the compilation unit being tested
   * @return {@code true} if the compilation unit has a part-of directive
   */
  bool hasPartOfDirective(CompilationUnit unit) {
    bool hasPartOf = false;
    for (Directive directive in unit.directives) {
      if (directive is PartOfDirective) {
        hasPartOf = true;
      } else if (directive is LibraryDirective) {
        return false;
      }
    }
    return hasPartOf;
  }

  /**
   * Compute the kind of the given source. This method should only be invoked when the kind is not
   * already known.
   * @param source the source for which a kind is to be computed
   * @return the new source info that was created to represent the source
   */
  DartEntry internalComputeKindOf(Source source) {
    try {
      accessed(source);
      RecordingErrorListener errorListener = new RecordingErrorListener();
      AnalysisContextImpl_ScanResult scanResult = internalScan(source, errorListener);
      Parser parser = new Parser(source, errorListener);
      CompilationUnit unit = parser.parseCompilationUnit(scanResult._token);
      LineInfo lineInfo = new LineInfo(scanResult._lineStarts);
      List<AnalysisError> errors = errorListener.getErrors2(source);
      unit.parsingErrors = errors;
      unit.lineInfo = lineInfo;
      DartEntryImpl dartCopy = ((_sourceMap[source] as DartEntry)).writableCopy;
      if (hasPartOfDirective(unit)) {
        dartCopy.setValue(DartEntry.SOURCE_KIND, SourceKind.PART);
      } else {
        dartCopy.setValue(DartEntry.SOURCE_KIND, SourceKind.LIBRARY);
      }
      dartCopy.setValue(SourceEntry.LINE_INFO, lineInfo);
      dartCopy.setValue(DartEntry.PARSED_UNIT, unit);
      dartCopy.setValue(DartEntry.PARSE_ERRORS, errors);
      _sourceMap[source] = dartCopy;
      return dartCopy;
    } on AnalysisException catch (exception) {
      DartEntryImpl dartCopy = ((_sourceMap[source] as DartEntry)).writableCopy;
      dartCopy.setState(DartEntry.SOURCE_KIND, CacheState.ERROR);
      dartCopy.setState(SourceEntry.LINE_INFO, CacheState.ERROR);
      dartCopy.setState(DartEntry.PARSED_UNIT, CacheState.ERROR);
      dartCopy.setState(DartEntry.PARSE_ERRORS, CacheState.ERROR);
      _sourceMap[source] = dartCopy;
      return dartCopy;
    }
  }
  CompilationUnit internalParseCompilationUnit(DartEntryImpl dartCopy, Source source) {
    accessed(source);
    try {
      RecordingErrorListener errorListener = new RecordingErrorListener();
      AnalysisContextImpl_ScanResult scanResult = internalScan(source, errorListener);
      Parser parser = new Parser(source, errorListener);
      CompilationUnit unit = parser.parseCompilationUnit(scanResult._token);
      LineInfo lineInfo = new LineInfo(scanResult._lineStarts);
      List<AnalysisError> errors = errorListener.getErrors2(source);
      unit.parsingErrors = errors;
      unit.lineInfo = lineInfo;
      if (identical(dartCopy.getState(DartEntry.SOURCE_KIND), CacheState.INVALID)) {
        if (hasPartOfDirective(unit)) {
          dartCopy.setValue(DartEntry.SOURCE_KIND, SourceKind.PART);
        } else {
          dartCopy.setValue(DartEntry.SOURCE_KIND, SourceKind.LIBRARY);
        }
      }
      dartCopy.setValue(SourceEntry.LINE_INFO, lineInfo);
      dartCopy.setValue(DartEntry.PARSED_UNIT, unit);
      dartCopy.setValue(DartEntry.PARSE_ERRORS, errors);
      return unit;
    } on AnalysisException catch (exception) {
      dartCopy.setState(SourceEntry.LINE_INFO, CacheState.ERROR);
      dartCopy.setState(DartEntry.PARSED_UNIT, CacheState.ERROR);
      dartCopy.setState(DartEntry.PARSE_ERRORS, CacheState.ERROR);
      throw exception;
    }
  }
  AnalysisContextImpl_ScanResult internalScan(Source source, AnalysisErrorListener errorListener) {
    AnalysisContextImpl_ScanResult result = new AnalysisContextImpl_ScanResult();
    Source_ContentReceiver receiver = new Source_ContentReceiver_7(source, errorListener, result);
    try {
      source.getContents(receiver);
    } catch (exception) {
      throw new AnalysisException.con3(exception);
    }
    return result;
  }

  /**
   * Invalidate all of the results computed by this context.
   * <p>
   * <b>Note:</b> This method must only be invoked while we are synchronized on {@link #cacheLock}.
   */
  void invalidateAllResults() {
    for (MapEntry<Source, SourceEntry> mapEntry in getMapEntrySet(_sourceMap)) {
      SourceEntry sourceEntry = mapEntry.getValue();
      if (sourceEntry is HtmlEntry) {
        HtmlEntryImpl htmlCopy = ((sourceEntry as HtmlEntry)).writableCopy;
        htmlCopy.setState(HtmlEntry.RESOLVED_UNIT, CacheState.INVALID);
        mapEntry.setValue(htmlCopy);
      } else if (sourceEntry is DartEntry) {
        DartEntryImpl dartCopy = ((sourceEntry as DartEntry)).writableCopy;
        dartCopy.invalidateAllResolutionInformation();
        mapEntry.setValue(dartCopy);
      }
    }
  }

  /**
   * In response to a change to at least one of the compilation units in the given library,
   * invalidate any results that are dependent on the result of resolving that library.
   * @param librarySource the source of the library being invalidated
   */
  void invalidateLibraryResolution(Source librarySource) {
    DartEntry libraryEntry = getDartEntry(librarySource);
    if (libraryEntry != null) {
      List<Source> includedParts = libraryEntry.getValue(DartEntry.INCLUDED_PARTS);
      DartEntryImpl libraryCopy = libraryEntry.writableCopy;
      libraryCopy.invalidateAllResolutionInformation();
      libraryCopy.setState(DartEntry.INCLUDED_PARTS, CacheState.INVALID);
      _sourceMap[librarySource] = libraryCopy;
      for (Source unitSource in includedParts) {
        DartEntry partEntry = getDartEntry(unitSource);
        if (partEntry != null) {
          DartEntryImpl dartCopy = partEntry.writableCopy;
          dartCopy.invalidateAllResolutionInformation();
          _sourceMap[unitSource] = dartCopy;
        }
      }
    }
  }

  /**
   * Return {@code true} if this library is, or depends on, dart:html.
   * @param library the library being tested
   * @param visitedLibraries a collection of the libraries that have been visited, used to prevent
   * infinite recursion
   * @return {@code true} if this library is, or depends on, dart:html
   */
  bool isClient(LibraryElement library, Source htmlSource, Set<LibraryElement> visitedLibraries) {
    if (visitedLibraries.contains(library)) {
      return false;
    }
    if (library.source == htmlSource) {
      return true;
    }
    javaSetAdd(visitedLibraries, library);
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
   * Perform a single analysis task.
   * <p>
   * <b>Note:</b> This method must only be invoked while we are synchronized on {@link #cacheLock}.
   * @return {@code true} if work was done, implying that there might be more work to be done
   */
  bool performSingleAnalysisTask() {
    for (MapEntry<Source, SourceEntry> entry in getMapEntrySet(_sourceMap)) {
      SourceEntry sourceEntry = entry.getValue();
      if (sourceEntry is DartEntry) {
        DartEntry dartEntry = sourceEntry as DartEntry;
        CacheState parsedUnitState = dartEntry.getState(DartEntry.PARSED_UNIT);
        if (identical(parsedUnitState, CacheState.INVALID)) {
          try {
            parseCompilationUnit(entry.getKey());
          } on AnalysisException catch (exception) {
            DartEntryImpl dartCopy = ((entry.getValue() as DartEntry)).writableCopy;
            dartCopy.setState(DartEntry.PARSED_UNIT, CacheState.ERROR);
            entry.setValue(dartCopy);
            AnalysisEngine.instance.logger.logError2("Could not parse ${entry.getKey().fullName}", exception);
          }
          return true;
        }
      } else if (sourceEntry is HtmlEntry) {
        HtmlEntry htmlEntry = sourceEntry as HtmlEntry;
        CacheState parsedUnitState = htmlEntry.getState(HtmlEntry.PARSED_UNIT);
        if (identical(parsedUnitState, CacheState.INVALID)) {
          try {
            parseHtmlUnit(entry.getKey());
          } on AnalysisException catch (exception) {
            HtmlEntryImpl htmlCopy = ((entry.getValue() as HtmlEntry)).writableCopy;
            htmlCopy.setState(HtmlEntry.PARSED_UNIT, CacheState.ERROR);
            entry.setValue(htmlCopy);
            AnalysisEngine.instance.logger.logError2("Could not parse ${entry.getKey().fullName}", exception);
          }
          return true;
        }
      }
    }
    for (MapEntry<Source, SourceEntry> entry in getMapEntrySet(_sourceMap)) {
      SourceEntry sourceEntry = entry.getValue();
      if (sourceEntry is DartEntry && identical(sourceEntry.kind, SourceKind.LIBRARY)) {
        DartEntry dartEntry = sourceEntry as DartEntry;
        CacheState elementState = dartEntry.getState(DartEntry.ELEMENT);
        if (identical(elementState, CacheState.INVALID)) {
          try {
            computeLibraryElement(entry.getKey());
          } on AnalysisException catch (exception) {
            DartEntryImpl dartCopy = ((entry.getValue() as DartEntry)).writableCopy;
            dartCopy.setState(DartEntry.ELEMENT, CacheState.ERROR);
            entry.setValue(dartCopy);
            AnalysisEngine.instance.logger.logError2("Could not resolve ${entry.getKey().fullName}", exception);
          }
          return true;
        }
      } else if (sourceEntry is HtmlEntry) {
        HtmlEntry htmlEntry = sourceEntry as HtmlEntry;
        CacheState resolvedUnitState = htmlEntry.getState(HtmlEntry.RESOLVED_UNIT);
        if (identical(resolvedUnitState, CacheState.INVALID)) {
          try {
            resolveHtmlUnit(entry.getKey());
          } on AnalysisException catch (exception) {
            HtmlEntryImpl htmlCopy = ((entry.getValue() as HtmlEntry)).writableCopy;
            htmlCopy.setState(HtmlEntry.RESOLVED_UNIT, CacheState.ERROR);
            entry.setValue(htmlCopy);
            AnalysisEngine.instance.logger.logError2("Could not resolve ${entry.getKey().fullName}", exception);
          }
          return true;
        }
      }
    }
    return false;
  }

  /**
   * Given a cache entry and a library element, record the library element and other information
   * gleaned from the element in the cache entry.
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
   * Record the result of using the given resolver to resolve one or more libraries.
   * @param resolver the resolver that has the needed results
   * @throws AnalysisException if the results cannot be retrieved for some reason
   */
  void recordResolutionResults(LibraryResolver resolver) {
    Source htmlSource = _sourceFactory.forUri(DartSdk.DART_HTML);
    RecordingErrorListener errorListener = resolver.errorListener;
    for (Library library in resolver.resolvedLibraries) {
      Source librarySource = library.librarySource;
      Set<Source> referencedLibraries = new Set<Source>();
      for (Library referencedLibrary in library.exports) {
        javaSetAdd(referencedLibraries, referencedLibrary.librarySource);
      }
      for (Library referencedLibrary in library.imports) {
        javaSetAdd(referencedLibraries, referencedLibrary.librarySource);
      }
      for (Source source in library.compilationUnitSources) {
        CompilationUnit unit = library.getAST(source);
        List<AnalysisError> errors = errorListener.getErrors2(source);
        unit.resolutionErrors = errors;
        LineInfo lineInfo = unit.lineInfo;
        {
          DartEntry dartEntry = getDartEntry(source);
          if (dartEntry != null) {
            DartEntryImpl dartCopy = dartEntry.writableCopy;
            dartCopy.setValue(SourceEntry.LINE_INFO, lineInfo);
            dartCopy.setState(DartEntry.PARSED_UNIT, CacheState.FLUSHED);
            dartCopy.setValue2(DartEntry.RESOLVED_UNIT, librarySource, unit);
            dartCopy.setValue2(DartEntry.RESOLUTION_ERRORS, librarySource, errors);
            if (identical(source, librarySource)) {
              recordElementData(dartCopy, library.libraryElement, htmlSource);
              List<Source> libraries;
              if (referencedLibraries.isEmpty) {
                libraries = Source.EMPTY_ARRAY;
              } else {
                libraries = new List.from(referencedLibraries);
              }
              dartCopy.setValue(DartEntry.REFERENCED_LIBRARIES, libraries);
            }
            _sourceMap[source] = dartCopy;
            ChangeNoticeImpl notice = getNotice(source);
            notice.compilationUnit = unit;
            notice.setErrors(dartCopy.allErrors, lineInfo);
          }
        }
      }
    }
  }
  HtmlScanResult scanHtml(Source source) {
    HtmlScanner scanner = new HtmlScanner(source);
    try {
      source.getContents(scanner);
    } catch (exception) {
      throw new AnalysisException.con3(exception);
    }
    return scanner.result;
  }

  /**
   * Create an entry for the newly added source. Return {@code true} if the new source is a Dart
   * file.
   * <p>
   * <b>Note:</b> This method must only be invoked while we are synchronized on {@link #cacheLock}.
   * @param source the source that has been added
   * @return {@code true} if the new source is a Dart file
   */
  bool sourceAvailable(Source source) {
    SourceEntry sourceEntry = _sourceMap[source];
    if (sourceEntry == null) {
      sourceEntry = createSourceEntry(source);
    }
    return sourceEntry is DartEntry;
  }

  /**
   * <b>Note:</b> This method must only be invoked while we are synchronized on {@link #cacheLock}.
   * @param source the source that has been changed
   */
  void sourceChanged(Source source) {
    SourceEntry sourceEntry = _sourceMap[source];
    if (sourceEntry is HtmlEntry) {
      HtmlEntryImpl htmlCopy = ((sourceEntry as HtmlEntry)).writableCopy;
      htmlCopy.setState(HtmlEntry.ELEMENT, CacheState.INVALID);
      htmlCopy.setState(SourceEntry.LINE_INFO, CacheState.INVALID);
      htmlCopy.setState(HtmlEntry.PARSED_UNIT, CacheState.INVALID);
      htmlCopy.setState(HtmlEntry.REFERENCED_LIBRARIES, CacheState.INVALID);
      htmlCopy.setState(HtmlEntry.RESOLVED_UNIT, CacheState.INVALID);
      _sourceMap[source] = htmlCopy;
    } else if (sourceEntry is DartEntry) {
      Set<Source> librariesToInvalidate = new Set<Source>();
      List<Source> containingLibraries = getLibrariesContaining(source);
      for (Source containingLibrary in containingLibraries) {
        javaSetAdd(librariesToInvalidate, containingLibrary);
        for (Source dependentLibrary in getLibrariesDependingOn(containingLibrary)) {
          javaSetAdd(librariesToInvalidate, dependentLibrary);
        }
      }
      DartEntryImpl dartCopy = ((sourceEntry as DartEntry)).writableCopy;
      dartCopy.setState(SourceEntry.LINE_INFO, CacheState.INVALID);
      dartCopy.setState(DartEntry.PARSE_ERRORS, CacheState.INVALID);
      dartCopy.setState(DartEntry.PARSED_UNIT, CacheState.INVALID);
      dartCopy.setState(DartEntry.SOURCE_KIND, CacheState.INVALID);
      _sourceMap[source] = dartCopy;
      for (Source library in librariesToInvalidate) {
        invalidateLibraryResolution(library);
      }
    }
  }

  /**
   * <b>Note:</b> This method must only be invoked while we are synchronized on {@link #cacheLock}.
   * @param source the source that has been deleted
   */
  void sourceRemoved(Source source) {
    DartEntry dartEntry = getDartEntry(source);
    if (dartEntry != null) {
      Set<Source> libraries = new Set<Source>();
      for (Source librarySource in getLibrariesContaining(source)) {
        javaSetAdd(libraries, librarySource);
        for (Source dependentLibrary in getLibrariesDependingOn(librarySource)) {
          javaSetAdd(libraries, dependentLibrary);
        }
      }
      for (Source librarySource in libraries) {
        invalidateLibraryResolution(librarySource);
      }
    }
    _sourceMap.remove(source);
  }
}
/**
 * Instances of the class {@code ScanResult} represent the results of scanning a source.
 */
class AnalysisContextImpl_ScanResult {

  /**
   * The time at which the contents of the source were last set.
   */
  int _modificationTime = 0;

  /**
   * The first token in the token stream.
   */
  Token _token;

  /**
   * The line start information that was produced.
   */
  List<int> _lineStarts;
}
class RecursiveXmlVisitor_6 extends RecursiveXmlVisitor<Object> {
  final AnalysisContextImpl AnalysisContextImpl_this;
  Source htmlSource;
  List<Source> libraries;
  RecursiveXmlVisitor_6(this.AnalysisContextImpl_this, this.htmlSource, this.libraries) : super();
  Object visitXmlTagNode(XmlTagNode node) {
    if (javaStringEqualsIgnoreCase(node.tag.lexeme, AnalysisContextImpl._TAG_SCRIPT)) {
      bool isDartScript = false;
      XmlAttributeNode scriptAttribute = null;
      for (XmlAttributeNode attribute in node.attributes) {
        if (javaStringEqualsIgnoreCase(attribute.name.lexeme, AnalysisContextImpl._ATTRIBUTE_SRC)) {
          scriptAttribute = attribute;
        } else if (javaStringEqualsIgnoreCase(attribute.name.lexeme, AnalysisContextImpl._ATTRIBUTE_TYPE)) {
          if (javaStringEqualsIgnoreCase(attribute.text, AnalysisContextImpl._TYPE_DART)) {
            isDartScript = true;
          }
        }
      }
      if (isDartScript && scriptAttribute != null) {
        try {
          Uri uri = new Uri(path: scriptAttribute.text);
          String fileName = uri.path;
          Source librarySource = AnalysisContextImpl_this._sourceFactory.resolveUri(htmlSource, fileName);
          if (librarySource.exists()) {
            libraries.add(librarySource);
          }
        } catch (exception) {
          AnalysisEngine.instance.logger.logError2("Invalid URL ('${scriptAttribute.text}') in script tag in '${htmlSource.fullName}'", exception);
        }
      }
    }
    return super.visitXmlTagNode(node);
  }
}
class Source_ContentReceiver_7 implements Source_ContentReceiver {
  Source source;
  AnalysisErrorListener errorListener;
  AnalysisContextImpl_ScanResult result;
  Source_ContentReceiver_7(this.source, this.errorListener, this.result);
  void accept(CharBuffer contents, int modificationTime2) {
    CharBufferScanner scanner = new CharBufferScanner(source, contents, errorListener);
    result._modificationTime = modificationTime2;
    result._token = scanner.tokenize();
    result._lineStarts = scanner.lineStarts;
  }
  void accept2(String contents, int modificationTime2) {
    StringScanner scanner = new StringScanner(source, contents, errorListener);
    result._modificationTime = modificationTime2;
    result._token = scanner.tokenize();
    result._lineStarts = scanner.lineStarts;
  }
}
/**
 * Instances of the class {@code AnalysisErrorInfoImpl} represent the analysis errors and line info
 * associated with a source.
 */
class AnalysisErrorInfoImpl implements AnalysisErrorInfo {

  /**
   * The analysis errors associated with a source, or {@code null} if there are no errors.
   */
  List<AnalysisError> _errors;

  /**
   * The line information associated with the errors, or {@code null} if there are no errors.
   */
  LineInfo _lineInfo;

  /**
   * Initialize an newly created error info with the errors and line information
   * @param errors the errors as a result of analysis
   * @param lineinfo the line info for the errors
   */
  AnalysisErrorInfoImpl(List<AnalysisError> errors, LineInfo lineInfo) {
    this._errors = errors;
    this._lineInfo = lineInfo;
  }

  /**
   * Return the errors of analysis, or {@code null} if there were no errors.
   * @return the errors as a result of the analysis
   */
  List<AnalysisError> get errors => _errors;

  /**
   * Return the line information associated with the errors, or {@code null} if there were no
   * errors.
   * @return the line information associated with the errors
   */
  LineInfo get lineInfo => _lineInfo;
}
/**
 * Instances of the class {@code AnalysisOptions} represent a set of analysis options used to
 * control the behavior of an analysis context.
 */
class AnalysisOptionsImpl implements AnalysisOptions {

  /**
   * A flag indicating whether analysis is to use strict mode. In strict mode, error reporting is
   * based exclusively on the static type information.
   */
  bool _strictMode = false;

  /**
   * Return {@code true} if analysis is to use strict mode. In strict mode, error reporting is based
   * exclusively on the static type information.
   * @return {@code true} if analysis is to use strict mode
   */
  bool get strictMode => _strictMode;

  /**
   * Set whether analysis is to use strict mode to the given value. In strict mode, error reporting
   * is based exclusively on the static type information.
   * @param isStrict {@code true} if analysis is to use strict mode
   */
  void set strictMode(bool isStrict) {
    _strictMode = isStrict;
  }
}
/**
 * The enumeration {@code CacheState} defines the possible states of cached data.
 */
class CacheState implements Comparable<CacheState> {

  /**
   * The data is not in the cache and the last time an attempt was made to compute the data an
   * exception occurred, making it pointless to attempt.
   * <p>
   * Valid Transitions:
   * <ul>
   * <li>{@link #INVALID} if a source was modified that might cause the data to be computable</li>
   * </ul>
   */
  static final CacheState ERROR = new CacheState('ERROR', 0);

  /**
   * The data is not in the cache because it was flushed from the cache in order to control memory
   * usage. If the data is recomputed, results do not need to be reported.
   * <p>
   * Valid Transitions:
   * <ul>
   * <li>{@link #IN_PROCESS} if the data is being recomputed</li>
   * <li>{@link #INVALID} if a source was modified that causes the data to need to be recomputed</li>
   * </ul>
   */
  static final CacheState FLUSHED = new CacheState('FLUSHED', 1);

  /**
   * The data might or might not be in the cache but is in the process of being recomputed.
   * <p>
   * Valid Transitions:
   * <ul>
   * <li>{@link #ERROR} if an exception occurred while trying to compute the data</li>
   * <li>{@link #VALID} if the data was successfully computed and stored in the cache</li>
   * </ul>
   */
  static final CacheState IN_PROCESS = new CacheState('IN_PROCESS', 2);

  /**
   * The data is not in the cache and needs to be recomputed so that results can be reported.
   * <p>
   * Valid Transitions:
   * <ul>
   * <li>{@link #IN_PROCESS} if an attempt is being made to recompute the data</li>
   * </ul>
   */
  static final CacheState INVALID = new CacheState('INVALID', 3);

  /**
   * The data is in the cache and up-to-date.
   * <p>
   * Valid Transitions:
   * <ul>
   * <li>{@link #FLUSHED} if the data is removed in order to manage memory usage</li>
   * <li>{@link #INVALID} if a source was modified in such a way as to invalidate the previous data</li>
   * </ul>
   */
  static final CacheState VALID = new CacheState('VALID', 4);
  static final List<CacheState> values = [ERROR, FLUSHED, IN_PROCESS, INVALID, VALID];

  /// The name of this enum constant, as declared in the enum declaration.
  final String name;

  /// The position in the enum declaration.
  final int ordinal;
  CacheState(this.name, this.ordinal) {
  }
  int compareTo(CacheState other) => ordinal - other.ordinal;
  int get hashCode => ordinal;
  String toString() => name;
}
/**
 * Instances of the class {@code ChangeNoticeImpl} represent a change to the analysis results
 * associated with a given source.
 * @coverage dart.engine
 */
class ChangeNoticeImpl implements ChangeNotice {

  /**
   * The source for which the result is being reported.
   */
  Source _source;

  /**
   * The fully resolved AST that changed as a result of the analysis, or {@code null} if the AST was
   * not changed.
   */
  CompilationUnit _compilationUnit;

  /**
   * The errors that changed as a result of the analysis, or {@code null} if errors were not
   * changed.
   */
  List<AnalysisError> _errors;

  /**
   * The line information associated with the source, or {@code null} if errors were not changed.
   */
  LineInfo _lineInfo;

  /**
   * An empty array of change notices.
   */
  static List<ChangeNoticeImpl> EMPTY_ARRAY = new List<ChangeNoticeImpl>(0);

  /**
   * Initialize a newly created notice associated with the given source.
   * @param source the source for which the change is being reported
   */
  ChangeNoticeImpl(Source source) {
    this._source = source;
  }

  /**
   * Return the fully resolved AST that changed as a result of the analysis, or {@code null} if the
   * AST was not changed.
   * @return the fully resolved AST that changed as a result of the analysis
   */
  CompilationUnit get compilationUnit => _compilationUnit;

  /**
   * Return the errors that changed as a result of the analysis, or {@code null} if errors were not
   * changed.
   * @return the errors that changed as a result of the analysis
   */
  List<AnalysisError> get errors => _errors;

  /**
   * Return the line information associated with the source, or {@code null} if errors were not
   * changed.
   * @return the line information associated with the source
   */
  LineInfo get lineInfo => _lineInfo;

  /**
   * Return the source for which the result is being reported.
   * @return the source for which the result is being reported
   */
  Source get source => _source;

  /**
   * Set the fully resolved AST that changed as a result of the analysis to the given AST.
   * @param compilationUnit the fully resolved AST that changed as a result of the analysis
   */
  void set compilationUnit(CompilationUnit compilationUnit2) {
    this._compilationUnit = compilationUnit2;
  }

  /**
   * Set the errors that changed as a result of the analysis to the given errors and set the line
   * information to the given line information.
   * @param errors the errors that changed as a result of the analysis
   * @param lineInfo the line information associated with the source
   */
  void setErrors(List<AnalysisError> errors2, LineInfo lineInfo2) {
    this._errors = errors2;
    this._lineInfo = lineInfo2;
  }
}
/**
 * Instances of the class {@code DelegatingAnalysisContextImpl} extend {@link AnalysisContextImplanalysis context} to delegate sources to the appropriate analysis context. For instance, if the
 * source is in a system library then the analysis context from the {@link DartSdk} is used.
 * @coverage dart.engine
 */
class DelegatingAnalysisContextImpl extends AnalysisContextImpl {

  /**
   * This references the {@link InternalAnalysisContext} held onto by the {@link DartSdk} which is
   * used (instead of this {@link AnalysisContext}) for SDK sources. This field is set when
   * #setSourceFactory(SourceFactory) is called, and references the analysis context in the{@link DartUriResolver} in the {@link SourceFactory}, this analysis context assumes that there
   * will be such a resolver.
   */
  InternalAnalysisContext _sdkAnalysisContext;
  void addSourceInfo(Source source, SourceEntry info) {
    if (source.isInSystemLibrary()) {
      _sdkAnalysisContext.addSourceInfo(source, info);
    } else {
      super.addSourceInfo(source, info);
    }
  }
  List<AnalysisError> computeErrors(Source source) {
    if (source.isInSystemLibrary()) {
      return _sdkAnalysisContext.computeErrors(source);
    } else {
      return super.computeErrors(source);
    }
  }
  HtmlElement computeHtmlElement(Source source) {
    if (source.isInSystemLibrary()) {
      return _sdkAnalysisContext.computeHtmlElement(source);
    } else {
      return super.computeHtmlElement(source);
    }
  }
  SourceKind computeKindOf(Source source) {
    if (source.isInSystemLibrary()) {
      return _sdkAnalysisContext.computeKindOf(source);
    } else {
      return super.computeKindOf(source);
    }
  }
  LibraryElement computeLibraryElement(Source source) {
    if (source.isInSystemLibrary()) {
      return _sdkAnalysisContext.computeLibraryElement(source);
    } else {
      return super.computeLibraryElement(source);
    }
  }
  LineInfo computeLineInfo(Source source) {
    if (source.isInSystemLibrary()) {
      return _sdkAnalysisContext.computeLineInfo(source);
    } else {
      return super.computeLineInfo(source);
    }
  }
  CompilationUnit computeResolvableCompilationUnit(Source source) {
    if (source.isInSystemLibrary()) {
      return _sdkAnalysisContext.computeResolvableCompilationUnit(source);
    } else {
      return super.computeResolvableCompilationUnit(source);
    }
  }
  AnalysisErrorInfo getErrors(Source source) {
    if (source.isInSystemLibrary()) {
      return _sdkAnalysisContext.getErrors(source);
    } else {
      return super.getErrors(source);
    }
  }
  HtmlElement getHtmlElement(Source source) {
    if (source.isInSystemLibrary()) {
      return _sdkAnalysisContext.getHtmlElement(source);
    } else {
      return super.getHtmlElement(source);
    }
  }
  List<Source> getHtmlFilesReferencing(Source source) {
    if (source.isInSystemLibrary()) {
      return _sdkAnalysisContext.getHtmlFilesReferencing(source);
    } else {
      return super.getHtmlFilesReferencing(source);
    }
  }
  SourceKind getKindOf(Source source) {
    if (source.isInSystemLibrary()) {
      return _sdkAnalysisContext.getKindOf(source);
    } else {
      return super.getKindOf(source);
    }
  }
  List<Source> getLibrariesContaining(Source source) {
    if (source.isInSystemLibrary()) {
      return _sdkAnalysisContext.getLibrariesContaining(source);
    } else {
      return super.getLibrariesContaining(source);
    }
  }
  List<Source> getLibrariesDependingOn(Source librarySource) {
    if (librarySource.isInSystemLibrary()) {
      return _sdkAnalysisContext.getLibrariesDependingOn(librarySource);
    } else {
      return super.getLibrariesDependingOn(librarySource);
    }
  }
  LibraryElement getLibraryElement(Source source) {
    if (source.isInSystemLibrary()) {
      return _sdkAnalysisContext.getLibraryElement(source);
    } else {
      return super.getLibraryElement(source);
    }
  }
  List<Source> get librarySources => ArrayUtils.addAll(super.librarySources, _sdkAnalysisContext.librarySources);
  LineInfo getLineInfo(Source source) {
    if (source.isInSystemLibrary()) {
      return _sdkAnalysisContext.getLineInfo(source);
    } else {
      return super.getLineInfo(source);
    }
  }
  Namespace getPublicNamespace(LibraryElement library) {
    Source source = library.source;
    if (source.isInSystemLibrary()) {
      return _sdkAnalysisContext.getPublicNamespace(library);
    } else {
      return super.getPublicNamespace(library);
    }
  }
  Namespace getPublicNamespace2(Source source) {
    if (source.isInSystemLibrary()) {
      return _sdkAnalysisContext.getPublicNamespace2(source);
    } else {
      return super.getPublicNamespace2(source);
    }
  }
  CompilationUnit getResolvedCompilationUnit(Source unitSource, LibraryElement library) {
    if (unitSource.isInSystemLibrary()) {
      return _sdkAnalysisContext.getResolvedCompilationUnit(unitSource, library);
    } else {
      return super.getResolvedCompilationUnit(unitSource, library);
    }
  }
  CompilationUnit getResolvedCompilationUnit2(Source unitSource, Source librarySource) {
    if (unitSource.isInSystemLibrary()) {
      return _sdkAnalysisContext.getResolvedCompilationUnit2(unitSource, librarySource);
    } else {
      return super.getResolvedCompilationUnit2(unitSource, librarySource);
    }
  }
  bool isClientLibrary(Source librarySource) {
    if (librarySource.isInSystemLibrary()) {
      return _sdkAnalysisContext.isClientLibrary(librarySource);
    } else {
      return super.isClientLibrary(librarySource);
    }
  }
  bool isServerLibrary(Source librarySource) {
    if (librarySource.isInSystemLibrary()) {
      return _sdkAnalysisContext.isServerLibrary(librarySource);
    } else {
      return super.isServerLibrary(librarySource);
    }
  }
  CompilationUnit parseCompilationUnit(Source source) {
    if (source.isInSystemLibrary()) {
      return _sdkAnalysisContext.parseCompilationUnit(source);
    } else {
      return super.parseCompilationUnit(source);
    }
  }
  HtmlUnit parseHtmlUnit(Source source) {
    if (source.isInSystemLibrary()) {
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
    if (source.isInSystemLibrary()) {
      _sdkAnalysisContext.recordLibraryElements(elementMap);
    } else {
      super.recordLibraryElements(elementMap);
    }
  }
  CompilationUnit resolveCompilationUnit(Source source, LibraryElement library) {
    if (source.isInSystemLibrary()) {
      return _sdkAnalysisContext.resolveCompilationUnit(source, library);
    } else {
      return super.resolveCompilationUnit(source, library);
    }
  }
  CompilationUnit resolveCompilationUnit2(Source unitSource, Source librarySource) {
    if (unitSource.isInSystemLibrary()) {
      return _sdkAnalysisContext.resolveCompilationUnit2(unitSource, librarySource);
    } else {
      return super.resolveCompilationUnit2(unitSource, librarySource);
    }
  }
  HtmlUnit resolveHtmlUnit(Source unitSource) {
    if (unitSource.isInSystemLibrary()) {
      return _sdkAnalysisContext.resolveHtmlUnit(unitSource);
    } else {
      return super.resolveHtmlUnit(unitSource);
    }
  }
  void setContents(Source source, String contents) {
    if (source.isInSystemLibrary()) {
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
 * Instances of the class {@code InstrumentedAnalysisContextImpl} implement an{@link AnalysisContext analysis context} by recording instrumentation data and delegating to
 * another analysis context to do the non-instrumentation work.
 * @coverage dart.engine
 */
class InstrumentedAnalysisContextImpl implements InternalAnalysisContext {

  /**
   * Record an exception that was thrown during analysis.
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
  InternalAnalysisContext _basis;

  /**
   * Create a new {@link InstrumentedAnalysisContextImpl} which wraps a new{@link AnalysisContextImpl} as the basis context.
   */
  InstrumentedAnalysisContextImpl() {
    _jtd_constructor_183_impl();
  }
  _jtd_constructor_183_impl() {
    _jtd_constructor_184_impl(new AnalysisContextImpl());
  }

  /**
   * Create a new {@link InstrumentedAnalysisContextImpl} with a specified basis context, aka the
   * context to wrap and instrument.
   * @param context some {@link InstrumentedAnalysisContext} to wrap and instrument
   */
  InstrumentedAnalysisContextImpl.con1(InternalAnalysisContext context) {
    _jtd_constructor_184_impl(context);
  }
  _jtd_constructor_184_impl(InternalAnalysisContext context) {
    _basis = context;
  }
  void addSourceInfo(Source source, SourceEntry info) {
    _basis.addSourceInfo(source, info);
  }
  void applyChanges(ChangeSet changeSet) {
    InstrumentationBuilder instrumentation = Instrumentation.builder2("Analysis-applyChanges");
    try {
      instrumentation.metric3("contextId", _contextId);
      _basis.applyChanges(changeSet);
    } finally {
      instrumentation.log();
    }
  }
  String computeDocumentationComment(Element element) {
    InstrumentationBuilder instrumentation = Instrumentation.builder2("Analysis-computeDocumentationComment");
    try {
      instrumentation.metric3("contextId", _contextId);
      return _basis.computeDocumentationComment(element);
    } finally {
      instrumentation.log();
    }
  }
  List<AnalysisError> computeErrors(Source source) {
    InstrumentationBuilder instrumentation = Instrumentation.builder2("Analysis-computeErrors");
    try {
      instrumentation.metric3("contextId", _contextId);
      List<AnalysisError> errors = _basis.computeErrors(source);
      instrumentation.metric2("Errors-count", errors.length);
      return errors;
    } finally {
      instrumentation.log();
    }
  }
  HtmlElement computeHtmlElement(Source source) {
    InstrumentationBuilder instrumentation = Instrumentation.builder2("Analysis-computeHtmlElement");
    try {
      instrumentation.metric3("contextId", _contextId);
      return _basis.computeHtmlElement(source);
    } on AnalysisException catch (e) {
      recordAnalysisException(instrumentation, e);
      throw e;
    } finally {
      instrumentation.log();
    }
  }
  SourceKind computeKindOf(Source source) {
    InstrumentationBuilder instrumentation = Instrumentation.builder2("Analysis-computeKindOf");
    try {
      instrumentation.metric3("contextId", _contextId);
      return _basis.computeKindOf(source);
    } finally {
      instrumentation.log();
    }
  }
  LibraryElement computeLibraryElement(Source source) {
    InstrumentationBuilder instrumentation = Instrumentation.builder2("Analysis-computeLibraryElement");
    try {
      instrumentation.metric3("contextId", _contextId);
      return _basis.computeLibraryElement(source);
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
      return _basis.computeLineInfo(source);
    } on AnalysisException catch (e) {
      recordAnalysisException(instrumentation, e);
      throw e;
    } finally {
      instrumentation.log();
    }
  }
  CompilationUnit computeResolvableCompilationUnit(Source source) => _basis.computeResolvableCompilationUnit(source);
  AnalysisContext extractContext(SourceContainer container) {
    InstrumentationBuilder instrumentation = Instrumentation.builder2("Analysis-extractContext");
    try {
      instrumentation.metric3("contextId", _contextId);
      InstrumentedAnalysisContextImpl newContext = new InstrumentedAnalysisContextImpl();
      _basis.extractContextInto(container, newContext._basis);
      return newContext;
    } finally {
      instrumentation.log();
    }
  }
  InternalAnalysisContext extractContextInto(SourceContainer container, InternalAnalysisContext newContext) => _basis.extractContextInto(container, newContext);
  AnalysisOptions get analysisOptions {
    InstrumentationBuilder instrumentation = Instrumentation.builder2("Analysis-getAnalysisOptions");
    try {
      instrumentation.metric3("contextId", _contextId);
      return _basis.analysisOptions;
    } finally {
      instrumentation.log();
    }
  }

  /**
   * @return the underlying {@link AnalysisContext}.
   */
  AnalysisContext get basis => _basis;
  Element getElement(ElementLocation location) {
    InstrumentationBuilder instrumentation = Instrumentation.builder2("Analysis-getElement");
    try {
      instrumentation.metric3("contextId", _contextId);
      return _basis.getElement(location);
    } finally {
      instrumentation.log();
    }
  }
  AnalysisErrorInfo getErrors(Source source) {
    InstrumentationBuilder instrumentation = Instrumentation.builder2("Analysis-getErrors");
    try {
      instrumentation.metric3("contextId", _contextId);
      AnalysisErrorInfo ret = _basis.getErrors(source);
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
      return _basis.getHtmlElement(source);
    } finally {
      instrumentation.log();
    }
  }
  List<Source> getHtmlFilesReferencing(Source source) {
    InstrumentationBuilder instrumentation = Instrumentation.builder2("Analysis-getHtmlFilesReferencing");
    try {
      instrumentation.metric3("contextId", _contextId);
      List<Source> ret = _basis.getHtmlFilesReferencing(source);
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
      List<Source> ret = _basis.htmlSources;
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
      return _basis.getKindOf(source);
    } finally {
      instrumentation.log();
    }
  }
  List<Source> get launchableClientLibrarySources {
    InstrumentationBuilder instrumentation = Instrumentation.builder2("Analysis-getLaunchableClientLibrarySources");
    try {
      instrumentation.metric3("contextId", _contextId);
      List<Source> ret = _basis.launchableClientLibrarySources;
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
      List<Source> ret = _basis.launchableServerLibrarySources;
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
      List<Source> ret = _basis.getLibrariesContaining(source);
      if (ret != null) {
        instrumentation.metric2("Source-count", ret.length);
      }
      return ret;
    } finally {
      instrumentation.log();
    }
  }
  List<Source> getLibrariesDependingOn(Source librarySource) {
    InstrumentationBuilder instrumentation = Instrumentation.builder2("Analysis-getLibrariesDependingOn");
    try {
      instrumentation.metric3("contextId", _contextId);
      List<Source> ret = _basis.getLibrariesDependingOn(librarySource);
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
      return _basis.getLibraryElement(source);
    } finally {
      instrumentation.log();
    }
  }
  List<Source> get librarySources {
    InstrumentationBuilder instrumentation = Instrumentation.builder2("Analysis-getLibrarySources");
    try {
      instrumentation.metric3("contextId", _contextId);
      List<Source> ret = _basis.librarySources;
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
      return _basis.getLineInfo(source);
    } finally {
      instrumentation.log();
    }
  }
  Namespace getPublicNamespace(LibraryElement library) => _basis.getPublicNamespace(library);
  Namespace getPublicNamespace2(Source source) => _basis.getPublicNamespace2(source);
  CompilationUnit getResolvedCompilationUnit(Source unitSource, LibraryElement library) {
    InstrumentationBuilder instrumentation = Instrumentation.builder2("Analysis-getResolvedCompilationUnit");
    try {
      instrumentation.metric3("contextId", _contextId);
      return _basis.getResolvedCompilationUnit(unitSource, library);
    } finally {
      instrumentation.log();
    }
  }
  CompilationUnit getResolvedCompilationUnit2(Source unitSource, Source librarySource) {
    InstrumentationBuilder instrumentation = Instrumentation.builder2("Analysis-getResolvedCompilationUnit");
    try {
      instrumentation.metric3("contextId", _contextId);
      return _basis.getResolvedCompilationUnit2(unitSource, librarySource);
    } finally {
      instrumentation.log();
    }
  }
  SourceFactory get sourceFactory {
    InstrumentationBuilder instrumentation = Instrumentation.builder2("Analysis-getSourceFactory");
    try {
      instrumentation.metric3("contextId", _contextId);
      return _basis.sourceFactory;
    } finally {
      instrumentation.log();
    }
  }
  bool isClientLibrary(Source librarySource) {
    InstrumentationBuilder instrumentation = Instrumentation.builder2("Analysis-isClientLibrary");
    try {
      instrumentation.metric3("contextId", _contextId);
      return _basis.isClientLibrary(librarySource);
    } finally {
      instrumentation.log();
    }
  }
  bool isServerLibrary(Source librarySource) {
    InstrumentationBuilder instrumentation = Instrumentation.builder2("Analysis-isServerLibrary");
    try {
      instrumentation.metric3("contextId", _contextId);
      return _basis.isServerLibrary(librarySource);
    } finally {
      instrumentation.log();
    }
  }
  void mergeContext(AnalysisContext context) {
    InstrumentationBuilder instrumentation = Instrumentation.builder2("Analysis-mergeContext");
    try {
      instrumentation.metric3("contextId", _contextId);
      if (context is InstrumentedAnalysisContextImpl) {
        context = ((context as InstrumentedAnalysisContextImpl))._basis;
      }
      _basis.mergeContext(context);
    } finally {
      instrumentation.log();
    }
  }
  CompilationUnit parseCompilationUnit(Source source) {
    InstrumentationBuilder instrumentation = Instrumentation.builder2("Analysis-parseCompilationUnit");
    try {
      instrumentation.metric3("contextId", _contextId);
      return _basis.parseCompilationUnit(source);
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
      return _basis.parseHtmlUnit(source);
    } on AnalysisException catch (e) {
      recordAnalysisException(instrumentation, e);
      throw e;
    } finally {
      instrumentation.log();
    }
  }
  List<ChangeNotice> performAnalysisTask() {
    InstrumentationBuilder instrumentation = Instrumentation.builder2("Analysis-performAnalysisTask");
    try {
      instrumentation.metric3("contextId", _contextId);
      List<ChangeNotice> ret = _basis.performAnalysisTask();
      if (ret != null) {
        instrumentation.metric2("ChangeNotice-count", ret.length);
      }
      return ret;
    } finally {
      instrumentation.log();
    }
  }
  void recordLibraryElements(Map<Source, LibraryElement> elementMap) {
    _basis.recordLibraryElements(elementMap);
  }
  CompilationUnit resolveCompilationUnit(Source unitSource, LibraryElement library) {
    InstrumentationBuilder instrumentation = Instrumentation.builder2("Analysis-resolveCompilationUnit");
    try {
      instrumentation.metric3("contextId", _contextId);
      return _basis.resolveCompilationUnit(unitSource, library);
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
      return _basis.resolveCompilationUnit2(unitSource, librarySource);
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
      return _basis.resolveHtmlUnit(htmlSource);
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
      _basis.analysisOptions = options;
    } finally {
      instrumentation.log();
    }
  }
  void setContents(Source source, String contents) {
    InstrumentationBuilder instrumentation = Instrumentation.builder2("Analysis-setContents");
    try {
      instrumentation.metric3("contextId", _contextId);
      _basis.setContents(source, contents);
    } finally {
      instrumentation.log();
    }
  }
  void set sourceFactory(SourceFactory factory) {
    InstrumentationBuilder instrumentation = Instrumentation.builder2("Analysis-setSourceFactory");
    try {
      instrumentation.metric3("contextId", _contextId);
      _basis.sourceFactory = factory;
    } finally {
      instrumentation.log();
    }
  }
  Iterable<Source> sourcesToResolve(List<Source> changedSources) {
    InstrumentationBuilder instrumentation = Instrumentation.builder2("Analysis-sourcesToResolve");
    try {
      instrumentation.metric3("contextId", _contextId);
      return _basis.sourcesToResolve(changedSources);
    } finally {
      instrumentation.log();
    }
  }
}
/**
 * The interface {@code InternalAnalysisContext} defines additional behavior for an analysis context
 * that is required by internal users of the context.
 */
abstract class InternalAnalysisContext implements AnalysisContext {

  /**
   * Add the given source with the given information to this context.
   * @param source the source to be added
   * @param info the information about the source
   */
  void addSourceInfo(Source source, SourceEntry info);

  /**
   * Return an AST structure corresponding to the given source, but ensure that the structure has
   * not already been resolved and will not be resolved by any other threads or in any other
   * library.
   * @param source the compilation unit for which an AST structure should be returned
   * @return the AST structure representing the content of the source
   * @throws AnalysisException if the analysis could not be performed
   */
  CompilationUnit computeResolvableCompilationUnit(Source source);

  /**
   * Initialize the specified context by removing the specified sources from the receiver and adding
   * them to the specified context.
   * @param container the container containing sources that should be removed from this context and
   * added to the returned context
   * @param newContext the context to be initialized
   * @return the analysis context that was initialized
   */
  InternalAnalysisContext extractContextInto(SourceContainer container, InternalAnalysisContext newContext);

  /**
   * Return a namespace containing mappings for all of the public names defined by the given
   * library.
   * @param library the library whose public namespace is to be returned
   * @return the public namespace of the given library
   */
  Namespace getPublicNamespace(LibraryElement library);

  /**
   * Return a namespace containing mappings for all of the public names defined by the library
   * defined by the given source.
   * @param source the source defining the library whose public namespace is to be returned
   * @return the public namespace corresponding to the library defined by the given source
   * @throws AnalysisException if the public namespace could not be computed
   */
  Namespace getPublicNamespace2(Source source);

  /**
   * Given a table mapping the source for the libraries represented by the corresponding elements to
   * the elements representing the libraries, record those mappings.
   * @param elementMap a table mapping the source for the libraries represented by the elements to
   * the elements representing the libraries
   */
  void recordLibraryElements(Map<Source, LibraryElement> elementMap);
}
/**
 * Instances of the class {@code RecordingErrorListener} implement an error listener that will
 * record the errors that are reported to it in a way that is appropriate for caching those errors
 * within an analysis context.
 * @coverage dart.engine
 */
class RecordingErrorListener implements AnalysisErrorListener {

  /**
   * A HashMap of lists containing the errors that were collected, keyed by each {@link Source}.
   */
  Map<Source, List<AnalysisError>> _errors = new Map<Source, List<AnalysisError>>();

  /**
   * Add all of the errors recorded by the given listener to this listener.
   * @param listener the listener that has recorded the errors to be added
   */
  void addAll(RecordingErrorListener listener) {
    for (AnalysisError error in listener.errors) {
      onError(error);
    }
  }

  /**
   * Answer the errors collected by the listener.
   * @return an array of errors (not {@code null}, contains no {@code null}s)
   */
  List<AnalysisError> get errors {
    Iterable<MapEntry<Source, List<AnalysisError>>> entrySet = getMapEntrySet(_errors);
    int numEntries = entrySet.length;
    if (numEntries == 0) {
      return AnalysisError.NO_ERRORS;
    }
    List<AnalysisError> resultList = new List<AnalysisError>();
    for (MapEntry<Source, List<AnalysisError>> entry in entrySet) {
      resultList.addAll(entry.getValue());
    }
    return new List.from(resultList);
  }

  /**
   * Answer the errors collected by the listener for some passed {@link Source}.
   * @param source some {@link Source} for which the caller wants the set of {@link AnalysisError}s
   * collected by this listener
   * @return the errors collected by the listener for the passed {@link Source}
   */
  List<AnalysisError> getErrors2(Source source) {
    List<AnalysisError> errorsForSource = _errors[source];
    if (errorsForSource == null) {
      return AnalysisError.NO_ERRORS;
    } else {
      return new List.from(errorsForSource);
    }
  }
  void onError(AnalysisError event) {
    Source source = event.source;
    List<AnalysisError> errorsForSource = _errors[source];
    if (_errors[source] == null) {
      errorsForSource = new List<AnalysisError>();
      _errors[source] = errorsForSource;
    }
    errorsForSource.add(event);
  }
}
/**
 * Instances of the class {@code ResolutionEraser} remove any resolution information from an AST
 * structure when used to visit that structure.
 */
class ResolutionEraser extends GeneralizingASTVisitor<Object> {
  Object visitAssignmentExpression(AssignmentExpression node) {
    node.element = null;
    return super.visitAssignmentExpression(node);
  }
  Object visitBinaryExpression(BinaryExpression node) {
    node.element = null;
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
    node.element = null;
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
    node.element = null;
    return super.visitFunctionExpressionInvocation(node);
  }
  Object visitIndexExpression(IndexExpression node) {
    node.element = null;
    return super.visitIndexExpression(node);
  }
  Object visitInstanceCreationExpression(InstanceCreationExpression node) {
    node.element = null;
    return super.visitInstanceCreationExpression(node);
  }
  Object visitPostfixExpression(PostfixExpression node) {
    node.element = null;
    return super.visitPostfixExpression(node);
  }
  Object visitPrefixExpression(PrefixExpression node) {
    node.element = null;
    return super.visitPrefixExpression(node);
  }
  Object visitRedirectingConstructorInvocation(RedirectingConstructorInvocation node) {
    node.element = null;
    return super.visitRedirectingConstructorInvocation(node);
  }
  Object visitSimpleIdentifier(SimpleIdentifier node) {
    node.element = null;
    return super.visitSimpleIdentifier(node);
  }
  Object visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    node.element = null;
    return super.visitSuperConstructorInvocation(node);
  }
}
/**
 * The interface {@code Logger} defines the behavior of objects that can be used to receive
 * information about errors within the analysis engine. Implementations usually write this
 * information to a file, but can also record the information for later use (such as during testing)
 * or even ignore the information.
 * @coverage dart.engine.utilities
 */
abstract class Logger {
  static final Logger NULL = new Logger_NullLogger();

  /**
   * Log the given message as an error.
   * @param message an explanation of why the error occurred or what it means
   */
  void logError(String message);

  /**
   * Log the given exception as one representing an error.
   * @param message an explanation of why the error occurred or what it means
   * @param exception the exception being logged
   */
  void logError2(String message, Exception exception);

  /**
   * Log the given exception as one representing an error.
   * @param exception the exception being logged
   */
  void logError3(Exception exception);

  /**
   * Log the given informational message.
   * @param message an explanation of why the error occurred or what it means
   * @param exception the exception being logged
   */
  void logInformation(String message);

  /**
   * Log the given exception as one representing an informational message.
   * @param message an explanation of why the error occurred or what it means
   * @param exception the exception being logged
   */
  void logInformation2(String message, Exception exception);
}
/**
 * Implementation of {@link Logger} that does nothing.
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