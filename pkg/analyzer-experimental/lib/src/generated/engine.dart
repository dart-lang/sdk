// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library engine;

import 'java_core.dart';
import 'dart:collection' show HasNextIterator;
import 'error.dart';
import 'source.dart';
import 'scanner.dart' show Token, CharBufferScanner, StringScanner;
import 'ast.dart' show CompilationUnit;
import 'parser.dart' show Parser;
import 'element.dart';
import 'resolver.dart' show Namespace, NamespaceBuilder, LibraryResolver;

/**
 * The unique instance of the class {@code AnalysisEngine} serves as the entry point for the
 * functionality provided by the analysis engine.
 */
class AnalysisEngine {
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
 * being analyzed against as well as the package-root used to resolve 'package:' URI's. This
 * information is included indirectly through the {@link SourceFactory source factory}.
 * <p>
 * Analysis engine allows for having more than one context. This can be used, for example, to
 * perform one analysis based on the state of files on disk and a separate analysis based on the
 * state of those files in open editors. It can also be used to perform an analysis based on a
 * proposed future state, such as after a refactoring.
 */
abstract class AnalysisContext {
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
   * Answer the collection of sources that have been added to the receiver via{@link #sourceAvailable(Source)} and not removed from the receiver via{@link #sourceDeleted(Source)} or {@link #sourcesDeleted(SourceContainer)}.
   * @return a collection of sources (not {@code null}, contains no {@code null}s)
   */
  Collection<Source> get availableSources;
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
   * Set the source factory used to create the sources that can be analyzed in this context to the
   * given source factory.
   * @param sourceFactory the source factory used to create the sources that can be analyzed in this
   * context
   */
  void set sourceFactory(SourceFactory sourceFactory4);
  /**
   * Cache the fact that content for the given source is now available, is of interest to the
   * client, and should be analyzed. Do not modify or discard any information about this source that
   * is already cached.
   * @param source the source that is now available
   */
  void sourceAvailable(Source source);
  /**
   * Respond to the fact that the content of the given source has changed by removing any cached
   * information that might now be out-of-date.
   * @param source the source whose content has changed
   */
  void sourceChanged(Source source);
  /**
   * Respond to the fact that the given source has been deleted and should no longer be analyzed by
   * removing any cached information that might now be out-of-date.
   * @param source the source that was deleted
   */
  void sourceDeleted(Source source);
  /**
   * Discard cached information for all files in the specified source container.
   * @param container the source container that was deleted (not {@code null})
   */
  void sourcesDeleted(SourceContainer container);
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
 */
class AnalysisException extends JavaException {
  /**
   * Initialize a newly created exception.
   */
  AnalysisException() : super() {
    _jtd_constructor_117_impl();
  }
  _jtd_constructor_117_impl() {
  }
  /**
   * Initialize a newly created exception to have the given message.
   * @param message the message associated with the exception
   */
  AnalysisException.con1(String message) : super(message) {
    _jtd_constructor_118_impl(message);
  }
  _jtd_constructor_118_impl(String message) {
  }
  /**
   * Initialize a newly created exception to have the given message and cause.
   * @param message the message associated with the exception
   * @param cause the underlying exception that caused this exception
   */
  AnalysisException.con2(String message, Exception cause) : super(message, cause) {
    _jtd_constructor_119_impl(message, cause);
  }
  _jtd_constructor_119_impl(String message, Exception cause) {
  }
  /**
   * Initialize a newly created exception to have the given cause.
   * @param cause the underlying exception that caused this exception
   */
  AnalysisException.con3(Exception cause) : super.withCause(cause) {
    _jtd_constructor_120_impl(cause);
  }
  _jtd_constructor_120_impl(Exception cause) {
  }
}
/**
 * Instances of the class {@code AnalysisContextImpl} implement an {@link AnalysisContext analysis
 * context}.
 */
class AnalysisContextImpl implements AnalysisContext {
  /**
   * The source factory used to create the sources that can be analyzed in this context.
   */
  SourceFactory _sourceFactory;
  /**
   * A cache mapping sources to the compilation units that were produced for the contents of the
   * source.
   */
  Map<Source, CompilationUnit> _parseCache = new Map<Source, CompilationUnit>();
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
   * A cache of the available sources of interest to the client. Sources are added to this
   * collection via {@link #sourceAvailable(Source)} and removed from this collection via{@link #sourceDeleted(Source)} and {@link #directoryDeleted(File)}
   */
  Set<Source> _availableSources = new Set<Source>();
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
  void clearResolution() {
    {
      _parseCache.clear();
      _libraryElementCache.clear();
      _publicNamespaceCache.clear();
    }
  }
  void discard() {
    {
      _parseCache.clear();
      _libraryElementCache.clear();
      _publicNamespaceCache.clear();
      _availableSources.clear();
    }
  }
  AnalysisContext extractAnalysisContext(SourceContainer container) {
    AnalysisContext newContext = AnalysisEngine.instance.createAnalysisContext();
    {
      JavaIterator<Source> iter = new JavaIterator(_availableSources);
      while (iter.hasNext) {
        Source source = iter.next();
        if (container.contains(source)) {
          iter.remove();
          newContext.sourceAvailable(source);
        }
      }
    }
    return newContext;
  }
  Collection<Source> get availableSources {
    {
      return new List<Source>.from(_availableSources);
    }
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
  LibraryElement getLibraryElement(Source source) {
    {
      LibraryElement element = _libraryElementCache[source];
      if (element == null) {
        RecordingErrorListener listener = new RecordingErrorListener();
        LibraryResolver resolver = new LibraryResolver(this, listener);
        try {
          element = resolver.resolveLibrary(source, true);
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
    Source source7 = library.definingCompilationUnit.source;
    {
      Namespace namespace = _publicNamespaceCache[source7];
      if (namespace == null) {
        NamespaceBuilder builder = new NamespaceBuilder();
        namespace = builder.createPublicNamespace(library);
        _publicNamespaceCache[source7] = namespace;
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
      _availableSources.addAll(context.availableSources);
    }
  }
  CompilationUnit parse(Source source) {
    {
      CompilationUnit unit = _parseCache[source];
      if (unit == null) {
        RecordingErrorListener errorListener = new RecordingErrorListener();
        Token token = scan(source, errorListener);
        Parser parser = new Parser(source, errorListener);
        unit = parser.parseCompilationUnit(token);
        unit.parsingErrors = errorListener.errors;
        _parseCache[source] = unit;
      }
      return unit;
    }
  }
  CompilationUnit parse2(Source source, AnalysisErrorListener errorListener) {
    {
      CompilationUnit unit = _parseCache[source];
      if (unit == null) {
        Token token = scan(source, errorListener);
        Parser parser = new Parser(source, errorListener);
        unit = parser.parseCompilationUnit(token);
        _parseCache[source] = unit;
      }
      return unit;
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
    List<Token> tokens = new List<Token>.fixedLength(1);
    Source_ContentReceiver receiver = new Source_ContentReceiver_1(source, errorListener, tokens);
    try {
      source.getContents(receiver);
    } on JavaException catch (exception) {
    }
    return tokens[0];
  }
  void set sourceFactory(SourceFactory sourceFactory2) {
    this._sourceFactory = sourceFactory2;
  }
  void sourceAvailable(Source source) {
    {
      javaSetAdd(_availableSources, source);
    }
  }
  void sourceChanged(Source source) {
    {
      _parseCache.remove(source);
      _libraryElementCache.remove(source);
      _publicNamespaceCache.remove(source);
    }
  }
  void sourceDeleted(Source source) {
    {
      _availableSources.remove(source);
      sourceChanged(source);
    }
  }
  void sourcesDeleted(SourceContainer container) {
    {
      _parseCache.clear();
      _libraryElementCache.clear();
      _publicNamespaceCache.clear();
      JavaIterator<Source> iter = new JavaIterator(_availableSources);
      while (iter.hasNext) {
        if (container.contains(iter.next())) {
          iter.remove();
        }
      }
    }
  }
  Iterable<Source> sourcesToResolve(List<Source> changedSources) => JavaArrays.asList(changedSources);
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
}
class Source_ContentReceiver_1 implements Source_ContentReceiver {
  Source source;
  AnalysisErrorListener errorListener;
  List<Token> tokens;
  Source_ContentReceiver_1(this.source, this.errorListener, this.tokens);
  accept(CharBuffer contents) {
    CharBufferScanner scanner = new CharBufferScanner(source, contents, errorListener);
    tokens[0] = scanner.tokenize();
  }
  void accept2(String contents) {
    StringScanner scanner = new StringScanner(source, contents, errorListener);
    tokens[0] = scanner.tokenize();
  }
}
/**
 * Instances of the class {@code RecordingErrorListener} implement an error listener that will
 * record the errors that are reported to it in a way that is appropriate for caching those errors
 * within an analysis context.
 */
class RecordingErrorListener implements AnalysisErrorListener {
  /**
   * A list containing the errors that were collected.
   */
  List<AnalysisError> _errors = null;
  /**
   * Answer the errors collected by the listener.
   * @return an array of errors (not {@code null}, contains no {@code null}s)
   */
  List<AnalysisError> get errors => _errors != null ? new List.from(_errors) : AnalysisError.NO_ERRORS;
  void onError(AnalysisError event) {
    if (_errors == null) {
      _errors = new List<AnalysisError>();
    }
    _errors.add(event);
  }
}
/**
 * The interface {@code Logger} defines the behavior of objects that can be used to receive
 * information about errors within the analysis engine. Implementations usually write this
 * information to a file, but can also record the information for later use (such as during testing)
 * or even ignore the information.
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