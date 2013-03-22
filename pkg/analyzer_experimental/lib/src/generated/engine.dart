// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library engine;

import 'java_core.dart';
import 'java_engine.dart';
import 'dart:collection' show HasNextIterator;
import 'error.dart';
import 'source.dart';
import 'scanner.dart' show Token, CharBufferScanner, StringScanner;
import 'ast.dart' show CompilationUnit, Directive, PartOfDirective;
import 'parser.dart' show Parser;
import 'element.dart';
import 'resolver.dart' show Namespace, NamespaceBuilder, LibraryResolver;
import 'html.dart' show HtmlScanner, HtmlScanResult, HtmlParser, HtmlParseResult;

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
   * Prevent the creation of instances of this class.
   */
  AnalysisEngine() : super() {
  }
  /**
   * Create a new context in which analysis can be performed.
   * @return the analysis context that was created
   */
  AnalysisContext createAnalysisContext() => new AnalysisContextImpl();
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
 * which analysis can be performed. The context includes such information as the version of the SDK
 * being analyzed against as well as the package-root used to resolve 'package:' URI's. (Both of
 * which are known indirectly through the {@link SourceFactory source factory}.)
 * <p>
 * They also represent the state of a given analysis, which includes knowing which sources have been
 * included in the analysis (either directly or indirectly) and the results of the analysis. Some
 * analysis results are cached in order to allow the context to balance between memory usage and
 * performance. TODO(brianwilkerson) Decide how this is reflected in the API: a getFoo() and
 * getOrComputeFoo() pair of methods, or a single getFoo(boolean).
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
   * Create a new context in which analysis can be performed. Any sources in the specified container
   * will be removed from this context and added to the newly created context.
   * @param container the container containing sources that should be removed from this context and
   * added to the returned context
   * @return the analysis context that was created
   */
  AnalysisContext extractContext(SourceContainer container);
  /**
   * Return the element referenced by the given location.
   * @param location the reference describing the element to be returned
   * @return the element referenced by the given location
   */
  Element getElement(ElementLocation location);
  /**
   * Return an array containing all of the errors associated with the given source. The array will
   * be empty if the source is not known to this context or if there are no errors in the source.
   * @param source the source whose errors are to be returned
   * @return all of the errors associated with the given source
   * @throws AnalysisException if the errors could not be determined because the analysis could not
   * be performed
   */
  List<AnalysisError> getErrors(Source source);
  /**
   * Return the element model corresponding to the HTML file defined by the given source.
   * @param source the source defining the HTML file whose element model is to be returned
   * @return the element model corresponding to the HTML file defined by the given source
   */
  HtmlElement getHtmlElement(Source source);
  /**
   * Return an array containing all of the sources known to this context that represent HTML files.
   * @return the sources known to this context that represent HTML files
   */
  List<Source> get htmlSources;
  /**
   * Return the kind of the given source if it is already known, or {@code null} if the kind is not
   * already known.
   * @param source the source whose kind is to be returned
   * @return the kind of the given source
   * @see #getOrComputeKindOf(Source)
   */
  SourceKind getKnownKindOf(Source source);
  /**
   * Return an array containing all of the sources known to this context that represent the defining
   * compilation unit of a library that can be run within a browser. The sources that are returned
   * represent libraries that have a 'main' method and are either referenced by an HTML file or
   * import, directly or indirectly, a client-only library.
   * @return the sources known to this context that represent the defining compilation unit of a
   * library that can be run within a browser
   */
  List<Source> get launchableClientLibrarySources;
  /**
   * Return an array containing all of the sources known to this context that represent the defining
   * compilation unit of a library that can be run outside of a browser.
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
   * will be empty.
   * @param source the source contained in the returned libraries
   * @return the sources for the libraries containing the given source
   */
  List<Source> getLibrariesContaining(Source source);
  /**
   * Return the element model corresponding to the library defined by the given source. If the
   * element model does not yet exist it will be created. The process of creating an element model
   * for a library can long-running, depending on the size of the library and the number of
   * libraries that are imported into it that also need to have a model built for them.
   * @param source the source defining the library whose element model is to be returned
   * @return the element model corresponding to the library defined by the given source or{@code null} if the element model could not be determined because the analysis could
   * not be performed
   */
  LibraryElement getLibraryElement(Source source);
  /**
   * Return the element model corresponding to the library defined by the given source, or{@code null} if the element model does not currently exist or if the analysis could not be
   * performed.
   * @param source the source defining the library whose element model is to be returned
   * @return the element model corresponding to the library defined by the given source
   */
  LibraryElement getLibraryElementOrNull(Source source);
  /**
   * Return an array containing all of the sources known to this context that represent the defining
   * compilation unit of a library.
   * @return the sources known to this context that represent the defining compilation unit of a
   * library
   */
  List<Source> get librarySources;
  /**
   * Return the kind of the given source, computing it's kind if it is not already known.
   * @param source the source whose kind is to be returned
   * @return the kind of the given source
   * @see #getKnownKindOf(Source)
   */
  SourceKind getOrComputeKindOf(Source source);
  /**
   * Return the source factory used to create the sources that can be analyzed in this context.
   * @return the source factory used to create the sources that can be analyzed in this context
   */
  SourceFactory get sourceFactory;
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
  CompilationUnit parse(Source source);
  /**
   * Parse a single HTML source to produce an AST structure. The resulting HTML AST structure may or
   * may not be resolved, and may have a slightly different structure depending upon whether it is
   * resolved.
   * @param source the HTML source to be parsed
   * @return the parse result (not {@code null})
   * @throws AnalysisException if the analysis could not be performed
   */
  HtmlParseResult parseHtml(Source source);
  /**
   * Perform the next unit of work required to keep the analysis results up-to-date and return
   * information about the consequent changes to the analysis results. If there were no results the
   * returned array will be empty. This method can be long running.
   * @return an array containing notices of changes to the analysis results
   */
  List<ChangeNotice> performAnalysisTask();
  /**
   * Parse and resolve a single source within the given context to produce a fully resolved AST.
   * @param source the source to be parsed and resolved
   * @param library the library defining the context in which the source file is to be resolved
   * @return the result of resolving the AST structure representing the content of the source
   * @throws AnalysisException if the analysis could not be performed
   */
  CompilationUnit resolve(Source source, LibraryElement library);
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
 * Instances of the class {@code AnalysisException} represent an exception that occurred during the
 * analysis of one or more sources.
 * @coverage dart.engine
 */
class AnalysisException extends JavaException {
  /**
   * Initialize a newly created exception.
   */
  AnalysisException() : super() {
    _jtd_constructor_123_impl();
  }
  _jtd_constructor_123_impl() {
  }
  /**
   * Initialize a newly created exception to have the given message.
   * @param message the message associated with the exception
   */
  AnalysisException.con1(String message) : super(message) {
    _jtd_constructor_124_impl(message);
  }
  _jtd_constructor_124_impl(String message) {
  }
  /**
   * Initialize a newly created exception to have the given message and cause.
   * @param message the message associated with the exception
   * @param cause the underlying exception that caused this exception
   */
  AnalysisException.con2(String message, Exception cause) : super(message, cause) {
    _jtd_constructor_125_impl(message, cause);
  }
  _jtd_constructor_125_impl(String message, Exception cause) {
  }
  /**
   * Initialize a newly created exception to have the given cause.
   * @param cause the underlying exception that caused this exception
   */
  AnalysisException.con3(Exception cause) : super.withCause(cause) {
    _jtd_constructor_126_impl(cause);
  }
  _jtd_constructor_126_impl(Exception cause) {
  }
}
/**
 * Instances of the class {@code ChangeNotice} represent a change to the analysis results associated
 * with a given source.
 */
class ChangeNotice {
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
  static List<ChangeNotice> EMPTY_ARRAY = new List<ChangeNotice>(0);
  /**
   * Initialize a newly created result representing the fact that the errors associated with a
   * source have changed.
   * @param source the source for which the result is being reported
   * @param errors the errors that changed as a result of the analysis
   * @param the line information associated with the source
   */
  ChangeNotice.con1(Source source2, List<AnalysisError> errors2, LineInfo lineInfo3) {
    _jtd_constructor_127_impl(source2, errors2, lineInfo3);
  }
  _jtd_constructor_127_impl(Source source2, List<AnalysisError> errors2, LineInfo lineInfo3) {
    this._source = source2;
    this._errors = errors2;
    this._lineInfo = lineInfo3;
  }
  /**
   * Initialize a newly created result representing the fact that the resolution of a source has
   * changed.
   * @param source the source for which the result is being reported
   * @param compilationUnit the fully resolved AST produced as a result of the analysis
   */
  ChangeNotice.con2(Source source3, CompilationUnit compilationUnit9) {
    _jtd_constructor_128_impl(source3, compilationUnit9);
  }
  _jtd_constructor_128_impl(Source source3, CompilationUnit compilationUnit9) {
    this._source = source3;
    this._compilationUnit = compilationUnit9;
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
}
/**
 * Instances of the class {@code ChangeSet} indicate what sources have been added, changed, or
 * removed.
 * @coverage dart.engine
 */
class ChangeSet {
  /**
   * A table mapping the sources that have been added to their contents.
   */
  Map<Source, String> _added3 = new Map<Source, String>();
  /**
   * A table mapping the sources that have been changed to their contents.
   */
  Map<Source, String> _changed3 = new Map<Source, String>();
  /**
   * A list containing the sources that have been removed..
   */
  List<Source> _removed2 = new List<Source>();
  /**
   * A list containing the source containers specifying additional sources that have been removed.
   */
  List<SourceContainer> _removedContainers = new List<SourceContainer>();
  /**
   * Initialize a newly created change set to be empty.
   */
  ChangeSet() : super() {
  }
  /**
   * Record that the specified source has been added and that it's content is the default contents
   * of the source.
   * @param source the source that was added
   */
  void added(Source source) {
    added2(source, null);
  }
  /**
   * Record that the specified source has been added and that it has the given content. If the
   * content is non-{@code null}, this has the effect of overriding the default contents of the
   * source. If the contents are {@code null}, any previous override is removed so that the default
   * contents will be used.
   * @param source the source that was added
   * @param content the content of the new source
   */
  void added2(Source source, String content) {
    if (source != null) {
      _added3[source] = content;
    }
  }
  /**
   * Record that the specified source has been changed and that it's content is the default contents
   * of the source.
   * @param source the source that was changed
   */
  void changed(Source source) {
    changed2(source, null);
  }
  /**
   * Record that the specified source has been changed and that it now has the given content. If the
   * content is non-{@code null}, this has the effect of overriding the default contents of the
   * source. If the contents are {@code null}, any previous override is removed so that the default
   * contents will be used.
   * @param source the source that was changed
   * @param content the new content of the source
   */
  void changed2(Source source, String content) {
    if (source != null) {
      _changed3[source] = content;
    }
  }
  /**
   * Return a table mapping the sources that have been added to their contents.
   * @return a table mapping the sources that have been added to their contents
   */
  Map<Source, String> get addedWithContent => _added3;
  /**
   * Return a table mapping the sources that have been changed to their contents.
   * @return a table mapping the sources that have been changed to their contents
   */
  Map<Source, String> get changedWithContent => _changed3;
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
  bool isEmpty() => _added3.isEmpty && _changed3.isEmpty && _removed2.isEmpty && _removedContainers.isEmpty;
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
 * Instances of the class {@code AnalysisContextImpl} implement an {@link AnalysisContext analysis
 * context}.
 * @coverage dart.engine
 */
class AnalysisContextImpl implements AnalysisContext {
  /**
   * The source factory used to create the sources that can be analyzed in this context.
   */
  SourceFactory _sourceFactory;
  /**
   * A table mapping sources known to the context to the information known about the source.
   */
  Map<Source, SourceInfo> _sourceMap = new Map<Source, SourceInfo>();
  /**
   * A cache mapping sources to the compilation units that were produced for the contents of the
   * source.
   */
  Map<Source, CompilationUnit> _parseCache = new Map<Source, CompilationUnit>();
  /**
   * A cache mapping sources to the html parse results that were produced for the contents of the
   * source.
   */
  Map<Source, HtmlParseResult> _htmlParseCache = new Map<Source, HtmlParseResult>();
  /**
   * A cache mapping sources (of the defining compilation units of libraries) to the library
   * elements for those libraries.
   */
  Map<Source, LibraryElement> _libraryElementCache = new Map<Source, LibraryElement>();
  /**
   * A cache mapping sources (of the defining compilation units of libraries) to the public
   * namespace for that library.
   */
  Map<Source, Namespace> _publicNamespaceCache = new Map<Source, Namespace>();
  /**
   * The object used to synchronize access to all of the caches.
   */
  Object _cacheLock = new Object();
  /**
   * Initialize a newly created analysis context.
   */
  AnalysisContextImpl() : super() {
  }
  void applyChanges(ChangeSet changeSet) {
    if (changeSet.isEmpty()) {
      return;
    }
    {
      List<Source> addedSources = new List<Source>();
      for (MapEntry<Source, String> entry in getMapEntrySet(changeSet.addedWithContent)) {
        Source source = entry.getKey();
        _sourceFactory.setContents(source, entry.getValue());
        addedSources.add(source);
      }
      List<Source> changedSources = new List<Source>();
      for (MapEntry<Source, String> entry in getMapEntrySet(changeSet.changedWithContent)) {
        Source source = entry.getKey();
        _sourceFactory.setContents(source, entry.getValue());
        changedSources.add(source);
      }
      List<Source> removedSources = new List<Source>.from(changeSet.removed);
      for (SourceContainer container in changeSet.removedContainers) {
        addSourcesInContainer(removedSources, container);
      }
      for (Source source in addedSources) {
        sourceAvailable(source);
      }
      for (Source source in changedSources) {
        sourceChanged(source);
      }
      for (Source source in removedSources) {
        sourceRemoved(source);
      }
    }
  }
  AnalysisContext extractContext(SourceContainer container) {
    AnalysisContextImpl newContext = AnalysisEngine.instance.createAnalysisContext() as AnalysisContextImpl;
    List<Source> sourcesToRemove = new List<Source>();
    {
      for (MapEntry<Source, SourceInfo> entry in getMapEntrySet(_sourceMap)) {
        Source source = entry.getKey();
        if (container.contains(source)) {
          sourcesToRemove.add(source);
          newContext._sourceMap[source] = new SourceInfo.con2(entry.getValue());
        }
      }
    }
    return newContext;
  }
  Element getElement(ElementLocation location) {
    throw new UnsupportedOperationException();
  }
  List<AnalysisError> getErrors(Source source) {
    throw new UnsupportedOperationException();
  }
  HtmlElement getHtmlElement(Source source) {
    if (!AnalysisEngine.isHtmlFileName(source.shortName)) {
      return null;
    }
    throw new UnsupportedOperationException();
  }
  List<Source> get htmlSources => getSources(SourceKind.HTML);
  SourceKind getKnownKindOf(Source source) {
    String name = source.shortName;
    if (AnalysisEngine.isHtmlFileName(name)) {
      return SourceKind.HTML;
    }
    if (!AnalysisEngine.isDartFileName(name)) {
      return SourceKind.UNKNOWN;
    }
    {
      if (_libraryElementCache.containsKey(source)) {
        return SourceKind.LIBRARY;
      }
      CompilationUnit unit = _parseCache[source];
      if (unit != null && hasPartOfDirective(unit)) {
        return SourceKind.PART;
      }
    }
    return null;
  }
  List<Source> get launchableClientLibrarySources => librarySources;
  List<Source> get launchableServerLibrarySources => librarySources;
  List<Source> getLibrariesContaining(Source source) {
    {
      SourceInfo info = _sourceMap[source];
      if (info == null) {
        return Source.EMPTY_ARRAY;
      }
      return info.librarySources;
    }
  }
  LibraryElement getLibraryElement(Source source) {
    if (!AnalysisEngine.isDartFileName(source.shortName)) {
      return null;
    }
    {
      LibraryElement element = _libraryElementCache[source];
      if (element == null) {
        if (getOrComputeKindOf(source) != SourceKind.LIBRARY) {
          return null;
        }
        LibraryResolver resolver = new LibraryResolver.con1(this);
        try {
          element = resolver.resolveLibrary(source, true);
          if (element != null) {
            _libraryElementCache[source] = element;
          }
        } on AnalysisException catch (exception) {
          AnalysisEngine.instance.logger.logError2("Could not resolve the library ${source.fullName}", exception);
        }
      }
      return element;
    }
  }
  /**
   * Return the element model corresponding to the library defined by the given source, or{@code null} if the element model does not yet exist.
   * @param source the source defining the library whose element model is to be returned
   * @return the element model corresponding to the library defined by the given source
   */
  LibraryElement getLibraryElementOrNull(Source source) {
    {
      return _libraryElementCache[source];
    }
  }
  List<Source> get librarySources => getSources(SourceKind.LIBRARY);
  SourceKind getOrComputeKindOf(Source source) {
    SourceKind kind = getKnownKindOf(source);
    if (kind != null) {
      return kind;
    }
    return computeKindOf(source);
  }
  /**
   * Return a namespace containing mappings for all of the public names defined by the given
   * library.
   * @param library the library whose public namespace is to be returned
   * @return the public namespace of the given library
   */
  Namespace getPublicNamespace(LibraryElement library) {
    Source source10 = library.definingCompilationUnit.source;
    {
      Namespace namespace = _publicNamespaceCache[source10];
      if (namespace == null) {
        NamespaceBuilder builder = new NamespaceBuilder();
        namespace = builder.createPublicNamespace(library);
        _publicNamespaceCache[source10] = namespace;
      }
      return namespace;
    }
  }
  /**
   * Return a namespace containing mappings for all of the public names defined by the library
   * defined by the given source.
   * @param source the source defining the library whose public namespace is to be returned
   * @return the public namespace corresponding to the library defined by the given source
   */
  Namespace getPublicNamespace2(Source source) {
    {
      Namespace namespace = _publicNamespaceCache[source];
      if (namespace == null) {
        LibraryElement library = getLibraryElement(source);
        if (library == null) {
          return null;
        }
        NamespaceBuilder builder = new NamespaceBuilder();
        namespace = builder.createPublicNamespace(library);
        _publicNamespaceCache[source] = namespace;
      }
      return namespace;
    }
  }
  SourceFactory get sourceFactory => _sourceFactory;
  void mergeContext(AnalysisContext context) {
    {
      for (MapEntry<Source, SourceInfo> entry in getMapEntrySet(((context as AnalysisContextImpl))._sourceMap)) {
        Source newSource = entry.getKey();
        SourceInfo existingInfo = _sourceMap[newSource];
        if (existingInfo == null) {
          _sourceMap[newSource] = new SourceInfo.con2(entry.getValue());
        } else {
        }
      }
    }
  }
  CompilationUnit parse(Source source) {
    {
      CompilationUnit unit = _parseCache[source];
      if (unit == null) {
        RecordingErrorListener errorListener = new RecordingErrorListener();
        AnalysisContextImpl_ScanResult scanResult = internalScan(source, errorListener);
        Parser parser = new Parser(source, errorListener);
        unit = parser.parseCompilationUnit(scanResult._token);
        unit.parsingErrors = errorListener.getErrors2(source);
        unit.lineInfo = new LineInfo(scanResult._lineStarts);
        _parseCache[source] = unit;
      }
      return unit;
    }
  }
  CompilationUnit parse3(Source source, AnalysisErrorListener errorListener) {
    {
      CompilationUnit unit = _parseCache[source];
      if (unit == null) {
        AnalysisContextImpl_ScanResult scanResult = internalScan(source, errorListener);
        Parser parser = new Parser(source, errorListener);
        unit = parser.parseCompilationUnit(scanResult._token);
        unit.lineInfo = new LineInfo(scanResult._lineStarts);
        _parseCache[source] = unit;
      }
      return unit;
    }
  }
  HtmlParseResult parseHtml(Source source) {
    {
      HtmlParseResult result = _htmlParseCache[source];
      if (result == null) {
        result = new HtmlParser(source).parse(scanHtml(source));
        _htmlParseCache[source] = result;
      }
      return result;
    }
  }
  List<ChangeNotice> performAnalysisTask() => ChangeNotice.EMPTY_ARRAY;
  /**
   * Given a table mapping the source for the libraries represented by the corresponding elements to
   * the elements representing the libraries, record those mappings.
   * @param elementMap a table mapping the source for the libraries represented by the elements to
   * the elements representing the libraries
   */
  void recordLibraryElements(Map<Source, LibraryElement> elementMap) {
    {
      javaMapPutAll(_libraryElementCache, elementMap);
    }
  }
  CompilationUnit resolve(Source source, LibraryElement library) => parse(source);
  void set sourceFactory(SourceFactory factory) {
    if (identical(_sourceFactory, factory)) {
      return;
    } else if (factory.context != null) {
      throw new IllegalStateException("Source factories cannot be shared between contexts");
    } else if (_sourceFactory != null) {
      _sourceFactory.context = null;
    }
    factory.context = this;
    _sourceFactory = factory;
  }
  Iterable<Source> sourcesToResolve(List<Source> changedSources) {
    List<Source> librarySources = new List<Source>();
    for (Source source in changedSources) {
      if (identical(getOrComputeKindOf(source), SourceKind.LIBRARY)) {
        librarySources.add(source);
      }
    }
    return librarySources;
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
  SourceKind computeKindOf(Source source) {
    try {
      if (hasPartOfDirective(parse(source))) {
        return SourceKind.PART;
      }
    } on AnalysisException catch (exception) {
      return SourceKind.UNKNOWN;
    }
    return SourceKind.LIBRARY;
  }
  /**
   * Return an array containing all of the sources known to this context that have the given kind.
   * @param kind the kind of sources to be returned
   * @return all of the sources known to this context that have the given kind
   */
  List<Source> getSources(SourceKind kind5) {
    List<Source> sources = new List<Source>();
    {
      for (MapEntry<Source, SourceInfo> entry in getMapEntrySet(_sourceMap)) {
        if (identical(entry.getValue().kind, kind5)) {
          sources.add(entry.getKey());
        }
      }
    }
    return new List.from(sources);
  }
  /**
   * Return {@code true} if the given compilation unit has a part-of directive.
   * @param unit the compilation unit being tested
   * @return {@code true} if the compilation unit has a part-of directive
   */
  bool hasPartOfDirective(CompilationUnit unit) {
    for (Directive directive in unit.directives) {
      if (directive is PartOfDirective) {
        return true;
      }
    }
    return false;
  }
  AnalysisContextImpl_ScanResult internalScan(Source source, AnalysisErrorListener errorListener) {
    AnalysisContextImpl_ScanResult result = new AnalysisContextImpl_ScanResult();
    Source_ContentReceiver receiver = new Source_ContentReceiver_3(source, errorListener, result);
    try {
      source.getContents(receiver);
    } on JavaException catch (exception) {
      throw new AnalysisException.con3(exception);
    }
    return result;
  }
  HtmlScanResult scanHtml(Source source) {
    HtmlScanner scanner = new HtmlScanner(source);
    try {
      source.getContents(scanner);
    } on JavaException catch (exception) {
      throw new AnalysisException.con3(exception);
    }
    return scanner.result;
  }
  /**
   * Note: This method must only be invoked while we are synchronized on {@link #cacheLock}.
   * @param source the source that has been added
   */
  void sourceAvailable(Source source) {
    SourceInfo existingInfo = _sourceMap[source];
    if (existingInfo == null) {
      SourceKind kind = computeKindOf(source);
      _sourceMap[source] = new SourceInfo.con1(source, kind);
    }
  }
  /**
   * Note: This method must only be invoked while we are synchronized on {@link #cacheLock}.
   * @param source the source that has been changed
   */
  void sourceChanged(Source source) {
    SourceInfo info = _sourceMap[source];
    if (info == null) {
      return;
    }
    _parseCache.remove(source);
    _htmlParseCache.remove(source);
    _libraryElementCache.remove(source);
    _publicNamespaceCache.remove(source);
    SourceKind oldKind = info.kind;
    SourceKind newKind = computeKindOf(source);
    if (newKind != oldKind) {
      info.kind = newKind;
    }
    for (Source librarySource in info.librarySources) {
      _libraryElementCache.remove(librarySource);
      _publicNamespaceCache.remove(librarySource);
    }
  }
  /**
   * Note: This method must only be invoked while we are synchronized on {@link #cacheLock}.
   * @param source the source that has been deleted
   */
  void sourceRemoved(Source source) {
    SourceInfo info = _sourceMap[source];
    if (info == null) {
      return;
    }
    _parseCache.remove(source);
    _libraryElementCache.remove(source);
    _publicNamespaceCache.remove(source);
    for (Source librarySource in info.librarySources) {
      _libraryElementCache.remove(librarySource);
      _publicNamespaceCache.remove(librarySource);
    }
    _sourceMap.remove(source);
  }
}
/**
 * Instances of the class {@code ScanResult} represent the results of scanning a source.
 */
class AnalysisContextImpl_ScanResult {
  /**
   * The first token in the token stream.
   */
  Token _token;
  /**
   * The line start information that was produced.
   */
  List<int> _lineStarts;
  /**
   * Initialize a newly created result object to be empty.
   */
  AnalysisContextImpl_ScanResult() : super() {
  }
}
class Source_ContentReceiver_3 implements Source_ContentReceiver {
  Source source;
  AnalysisErrorListener errorListener;
  AnalysisContextImpl_ScanResult result;
  Source_ContentReceiver_3(this.source, this.errorListener, this.result);
  accept(CharBuffer contents) {
    CharBufferScanner scanner = new CharBufferScanner(source, contents, errorListener);
    result._token = scanner.tokenize();
    result._lineStarts = scanner.lineStarts;
  }
  void accept2(String contents) {
    StringScanner scanner = new StringScanner(source, contents, errorListener);
    result._token = scanner.tokenize();
    result._lineStarts = scanner.lineStarts;
  }
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
   * Answer the errors collected by the listener.
   * @return an array of errors (not {@code null}, contains no {@code null}s)
   */
  List<AnalysisError> get errors {
    Set<MapEntry<Source, List<AnalysisError>>> entrySet2 = getMapEntrySet(_errors);
    if (entrySet2.length == 0) {
      return AnalysisError.NO_ERRORS;
    }
    List<AnalysisError> resultList = new List<AnalysisError>();
    for (MapEntry<Source, List<AnalysisError>> entry in entrySet2) {
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
    Source source11 = event.source;
    List<AnalysisError> errorsForSource = _errors[source11];
    if (_errors[source11] == null) {
      errorsForSource = new List<AnalysisError>();
      _errors[source11] = errorsForSource;
    }
    errorsForSource.add(event);
  }
}
/**
 * Instances of the class {@code SourceInfo} maintain the information known by an analysis context
 * about an individual source.
 * @coverage dart.engine
 */
class SourceInfo {
  /**
   * The kind of the source.
   */
  SourceKind _kind;
  /**
   * The sources for the defining compilation units for the libraries containing the source, or{@code null} if the libraries containing the source are not yet known.
   */
  List<Source> _librarySources = null;
  SourceInfo.con1(Source source, SourceKind kind3) {
    _jtd_constructor_163_impl(source, kind3);
  }
  _jtd_constructor_163_impl(Source source, SourceKind kind3) {
    this._kind = kind3;
  }
  /**
   * Initialize a newly created information holder to hold the same information as the given holder.
   * @param info the information holder used to initialize this holder
   */
  SourceInfo.con2(SourceInfo info) {
    _jtd_constructor_164_impl(info);
  }
  _jtd_constructor_164_impl(SourceInfo info) {
    _kind = info._kind;
    _librarySources = new List<Source>.from(info._librarySources);
  }
  /**
   * Add the given source to the list of sources for the defining compilation units for the
   * libraries containing this source.
   * @param source the source to be added to the list
   */
  void addLibrarySource(Source source) {
    if (_librarySources == null) {
      _librarySources = new List<Source>();
    }
    _librarySources.add(source);
  }
  /**
   * Return the kind of the source.
   * @return the kind of the source
   */
  SourceKind get kind => _kind;
  /**
   * Return the sources for the defining compilation units for the libraries containing this source.
   * @return the sources for the defining compilation units for the libraries containing this source
   */
  List<Source> get librarySources {
    if (_librarySources == null) {
      return Source.EMPTY_ARRAY;
    }
    return new List.from(_librarySources);
  }
  /**
   * Remove the given source from the list of sources for the defining compilation units for the
   * libraries containing this source.
   * @param source the source to be removed to the list
   */
  void removeLibrarySource(Source source) {
    _librarySources.remove(source);
    if (_librarySources.isEmpty) {
      _librarySources = null;
    }
  }
  /**
   * Set the kind of the source to the given kind.
   * @param kind the kind of the source
   */
  void set kind(SourceKind kind4) {
    this._kind = kind4;
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
  static Logger NULL = new Logger_NullLogger();
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