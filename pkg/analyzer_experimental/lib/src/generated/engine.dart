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
 * being analyzed against as well as the package-root used to resolve 'package:' URI's. (The latter
 * is included indirectly through the {@link SourceFactory source factory}.)
 * <p>
 * Analysis engine allows for having more than one context. This can be used, for example, to
 * perform one analysis based on the state of files on disk and a separate analysis based on the
 * state of those files in open editors. It can also be used to perform an analysis based on a
 * proposed future state, such as the state after a refactoring.
 */
abstract class AnalysisContext {
  /**
   * Respond to the given set of changes by removing any cached information that might now be
   * out-of-date. The result indicates what operations need to be performed as a result of this
   * change without actually performing those operations.
   * @param changeSet a description of the changes that have occurred
   * @return a result (not {@code null}) indicating operations to be performed
   */
  ChangeResult changed(ChangeSet changeSet);
  /**
   * Clear any cached information that is dependent on resolution. This method should be invoked if
   * the assumptions used by resolution have changed but the contents of the file have not changed.
   * Use {@link #sourceChanged(Source)} and {@link #sourcesDeleted(SourceContainer)} to indicate
   * when the contents of a file or files have changed.
   */
  void clearResolution();
  /**
   * Call this method when this context is no longer going to be used. At this point, the receiver
   * may choose to push some of its information back into the global cache for consumption by
   * another context for performance.
   */
  void discard();
  /**
   * Create a new context in which analysis can be performed. Any sources in the specified directory
   * in the receiver will be removed from the receiver and added to the newly created context.
   * @param directory the directory (not {@code null}) containing sources that should be removed
   * from the receiver and added to the returned context
   * @return the analysis context that was created (not {@code null})
   */
  AnalysisContext extractAnalysisContext(SourceContainer container);
  /**
   * Return the element referenced by the given location.
   * @param location the reference describing the element to be returned
   * @return the element referenced by the given location
   */
  Element getElement(ElementLocation location);
  /**
   * Return an array containing all of the errors associated with the given source.
   * @param source the source whose errors are to be returned
   * @return all of the errors associated with the given source
   * @throws AnalysisException if the errors could not be determined because the analysis could not
   * be performed
   */
  List<AnalysisError> getErrors(Source source);
  /**
   * Parse and build an element model for the HTML file defined by the given source.
   * @param source the source defining the HTML file whose element model is to be returned
   * @return the element model corresponding to the HTML file defined by the given source
   */
  HtmlElement getHtmlElement(Source source);
  /**
   * Return the kind of the given source if it is already known, or {@code null} if the kind is not
   * already known.
   * @param source the source whose kind is to be returned
   * @return the kind of the given source
   * @see #getOrComputeKindOf(Source)
   */
  SourceKind getKnownKindOf(Source source);
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
   * Return the element model corresponding to the library defined by the given source, or{@code null} if the element model does not yet exist.
   * @param source the source defining the library whose element model is to be returned
   * @return the element model corresponding to the library defined by the given source
   */
  LibraryElement getLibraryElementOrNull(Source source);
  /**
   * Return the kind of the given source, computing it's kind if it is not already known.
   * @param source the source whose kind is to be returned
   * @return the kind of the given source
   * @see #getKnownKindOf(Source)
   */
  SourceKind getOrComputeKindOf(Source source);
  /**
   * Return an array containing all of the parsing errors associated with the given source.
   * @param source the source whose errors are to be returned
   * @return all of the parsing errors associated with the given source
   * @throws AnalysisException if the errors could not be determined because the analysis could not
   * be performed
   */
  List<AnalysisError> getParsingErrors(Source source);
  /**
   * Return an array containing all of the resolution errors associated with the given source.
   * @param source the source whose errors are to be returned
   * @return all of the resolution errors associated with the given source
   * @throws AnalysisException if the errors could not be determined because the analysis could not
   * be performed
   */
  List<AnalysisError> getResolutionErrors(Source source);
  /**
   * Return the source factory used to create the sources that can be analyzed in this context.
   * @return the source factory used to create the sources that can be analyzed in this context
   */
  SourceFactory get sourceFactory;
  /**
   * Add the sources contained in the specified context to the receiver's collection of sources.
   * This method is called when an existing context's pubspec has been removed, and the contained
   * sources should be reanalyzed as part of the receiver.
   * @param context the context being merged (not {@code null})
   */
  void mergeAnalysisContext(AnalysisContext context);
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
   * Parse and resolve a single source within the given context to produce a fully resolved AST.
   * @param source the source to be parsed and resolved
   * @param library the library defining the context in which the source file is to be resolved
   * @return the result of resolving the AST structure representing the content of the source
   * @throws AnalysisException if the analysis could not be performed
   */
  CompilationUnit resolve(Source source, LibraryElement library);
  /**
   * Scan a single source to produce a token stream.
   * @param source the source to be scanned
   * @param errorListener the listener to which errors should be reported
   * @return the head of the token stream representing the content of the source
   * @throws AnalysisException if the analysis could not be performed
   */
  Token scan(Source source, AnalysisErrorListener errorListener);
  /**
   * Scan a single source to produce an HTML token stream.
   * @param source the source to be scanned
   * @return the scan result (not {@code null})
   * @throws AnalysisException if the analysis could not be performed
   */
  HtmlScanResult scanHtml(Source source);
  /**
   * Set the source factory used to create the sources that can be analyzed in this context to the
   * given source factory.
   * @param sourceFactory the source factory used to create the sources that can be analyzed in this
   * context
   */
  void set sourceFactory(SourceFactory sourceFactory4);
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
 * Instances of {@code ChangeResult} are returned by {@link AnalysisContext#changed(ChangeSet)} to
 * indicate what operations need to be performed as a result of the change.
 * @coverage dart.engine
 */
class ChangeResult {
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
   * source. If the contents are {@code null}, any previous the override is removed so that the
   * default contents will be used.
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
   * source. If the contents are {@code null}, any previous the override is removed so that the
   * default contents will be used.
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
   * The suffix used by sources that contain Dart.
   */
  static String _DART_SUFFIX = ".dart";
  /**
   * The suffix used by sources that contain HTML.
   */
  static String _HTML_SUFFIX = ".html";
  /**
   * Initialize a newly created analysis context.
   */
  AnalysisContextImpl() : super() {
  }
  ChangeResult changed(ChangeSet changeSet) {
    if (changeSet.isEmpty()) {
      return new ChangeResult();
    }
    {
      for (MapEntry<Source, String> entry in getMapEntrySet(changeSet.addedWithContent)) {
        _sourceFactory.setContents(entry.getKey(), entry.getValue());
      }
      for (MapEntry<Source, String> entry in getMapEntrySet(changeSet.changedWithContent)) {
        _sourceFactory.setContents(entry.getKey(), entry.getValue());
      }
      for (Source source in changeSet.addedWithContent.keys.toSet()) {
        sourceAvailable(source);
      }
      for (Source source in changeSet.changedWithContent.keys.toSet()) {
        sourceChanged(source);
      }
      for (Source source in changeSet.removed) {
        sourceDeleted(source);
      }
      for (SourceContainer container in changeSet.removedContainers) {
        sourcesDeleted(container);
      }
    }
    return new ChangeResult();
  }
  void clearResolution() {
    {
      _parseCache.clear();
      _htmlParseCache.clear();
      _libraryElementCache.clear();
      _publicNamespaceCache.clear();
    }
  }
  void discard() {
    {
      _sourceMap.clear();
      _parseCache.clear();
      _htmlParseCache.clear();
      _libraryElementCache.clear();
      _publicNamespaceCache.clear();
    }
  }
  AnalysisContext extractAnalysisContext(SourceContainer container) {
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
    throw new UnsupportedOperationException();
  }
  SourceKind getKnownKindOf(Source source) {
    if (source.fullName.endsWith(_HTML_SUFFIX)) {
      return SourceKind.HTML;
    }
    if (!source.fullName.endsWith(_DART_SUFFIX)) {
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
  SourceKind getOrComputeKindOf(Source source) {
    SourceKind kind = getKnownKindOf(source);
    if (kind != null) {
      return kind;
    }
    try {
      if (hasPartOfDirective(parse(source))) {
        return SourceKind.PART;
      }
    } on AnalysisException catch (exception) {
      return SourceKind.UNKNOWN;
    }
    return SourceKind.LIBRARY;
  }
  List<AnalysisError> getParsingErrors(Source source) {
    throw new UnsupportedOperationException();
  }
  /**
   * Return a namespace containing mappings for all of the public names defined by the given
   * library.
   * @param library the library whose public namespace is to be returned
   * @return the public namespace of the given library
   */
  Namespace getPublicNamespace(LibraryElement library) {
    Source source8 = library.definingCompilationUnit.source;
    {
      Namespace namespace = _publicNamespaceCache[source8];
      if (namespace == null) {
        NamespaceBuilder builder = new NamespaceBuilder();
        namespace = builder.createPublicNamespace(library);
        _publicNamespaceCache[source8] = namespace;
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
  List<AnalysisError> getResolutionErrors(Source source) {
    throw new UnsupportedOperationException();
  }
  SourceFactory get sourceFactory => _sourceFactory;
  void mergeAnalysisContext(AnalysisContext context) {
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
  Token scan(Source source, AnalysisErrorListener errorListener) {
    AnalysisContextImpl_ScanResult result = internalScan(source, errorListener);
    return result._token;
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
  void set sourceFactory(SourceFactory sourceFactory2) {
    this._sourceFactory = sourceFactory2;
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
  /**
   * Note: This method must only be invoked while we are synchronized on {@link #cacheLock}.
   * @param source the source that has been added
   */
  void sourceAvailable(Source source) {
    SourceInfo existingInfo = _sourceMap[source];
    if (existingInfo == null) {
      _sourceMap[source] = new SourceInfo.con1(source, getOrComputeKindOf(source));
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
    for (Source librarySource in info.librarySources) {
      _libraryElementCache.remove(librarySource);
      _publicNamespaceCache.remove(librarySource);
    }
  }
  /**
   * Note: This method must only be invoked while we are synchronized on {@link #cacheLock}.
   * @param source the source that has been deleted
   */
  void sourceDeleted(Source source) {
    _sourceMap.remove(source);
    sourceChanged(source);
  }
  /**
   * Note: This method must only be invoked while we are synchronized on {@link #cacheLock}.
   * @param container the source container specifying the sources that have been deleted
   */
  void sourcesDeleted(SourceContainer container) {
    List<Source> sourcesToRemove = new List<Source>();
    for (Source source in _sourceMap.keys.toSet()) {
      if (container.contains(source)) {
        sourcesToRemove.add(source);
      }
    }
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
    Source source9 = event.source;
    List<AnalysisError> errorsForSource = _errors[source9];
    if (_errors[source9] == null) {
      errorsForSource = new List<AnalysisError>();
      _errors[source9] = errorsForSource;
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
    _jtd_constructor_161_impl(source, kind3);
  }
  _jtd_constructor_161_impl(Source source, SourceKind kind3) {
    this._kind = kind3;
  }
  /**
   * Initialize a newly created information holder to hold the same information as the given holder.
   * @param info the information holder used to initialize this holder
   */
  SourceInfo.con2(SourceInfo info) {
    _jtd_constructor_162_impl(info);
  }
  _jtd_constructor_162_impl(SourceInfo info) {
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