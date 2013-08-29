// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library compiler;

import 'dart:async';
import 'dart:collection' show SplayTreeMap;
import 'dart:convert';

import 'package:analyzer_experimental/src/generated/ast.dart' show Directive, UriBasedDirective;
import 'package:csslib/visitor.dart' show StyleSheet, treeToDebugString;
import 'package:html5lib/dom.dart';
import 'package:html5lib/parser.dart';
import 'package:source_maps/span.dart' show Span;
import 'package:source_maps/refactor.dart' show TextEditTransaction;
import 'package:source_maps/printer.dart';

import 'analyzer.dart';
import 'css_analyzer.dart' show analyzeCss, findUrlsImported,
       findImportsInStyleSheet, parseCss;
import 'css_emitters.dart' show rewriteCssUris,
       emitComponentStyleSheet, emitOriginalCss, emitStyleSheet;
import 'dart_parser.dart';
import 'file_system.dart';
import 'files.dart';
import 'info.dart';
import 'messages.dart';
import 'compiler_options.dart';
import 'utils.dart';

/**
 * Parses an HTML file [contents] and returns a DOM-like tree.
 * Note that [contents] will be a [String] if coming from a browser-based
 * [FileSystem], or it will be a [List<int>] if running on the command line.
 *
 * Adds emitted error/warning to [messages], if [messages] is supplied.
 */
Document parseHtml(contents, String sourcePath, Messages messages) {
  var parser = new HtmlParser(contents, generateSpans: true,
      sourceUrl: sourcePath);
  var document = parser.parse();

  // Note: errors aren't fatal in HTML (unless strict mode is on).
  // So just print them as warnings.
  for (var e in parser.errors) {
    messages.warning(e.message, e.span);
  }
  return document;
}

/** Compiles an application written with Dart web components. */
class Compiler {
  final FileSystem fileSystem;
  final CompilerOptions options;
  final List<SourceFile> files = <SourceFile>[];

  String _mainPath;
  String _packageRoot;
  String _resetCssFile;
  StyleSheet _cssResetStyleSheet;
  Messages _messages;

  FutureGroup _tasks;
  Set _processed;

  /** Information about source [files] given their href. */
  final Map<String, FileInfo> info = new SplayTreeMap<String, FileInfo>();
  final _edits = new Map<DartCodeInfo, TextEditTransaction>();

  final GlobalInfo global = new GlobalInfo();

  /** Creates a compiler with [options] using [fileSystem]. */
  Compiler(this.fileSystem, this.options, this._messages) {
    _mainPath = options.inputFile;
    var mainDir = path.dirname(_mainPath);
    var baseDir = options.baseDir != null ? options.baseDir : mainDir;
    _packageRoot = options.packageRoot != null ? options.packageRoot
        : path.join(path.dirname(_mainPath), 'packages');

    if (options.resetCssFile != null) {
      _resetCssFile = options.resetCssFile;
      if (path.isRelative(_resetCssFile)) {
        // If CSS reset file path is relative from our current path.
        _resetCssFile = path.resolve(_resetCssFile);
      }
    }

    // Normalize paths - all should be relative or absolute paths.
    if (path.isAbsolute(_mainPath) || path.isAbsolute(baseDir)
        || path.isAbsolute(_packageRoot)) {
      if (path.isRelative(_mainPath)) _mainPath = path.resolve(_mainPath);
      if (path.isRelative(baseDir)) baseDir = path.resolve(baseDir);
      if (path.isRelative(_packageRoot)) {
        _packageRoot = path.resolve(_packageRoot);
      }
    }
  }

  /** Compile the application starting from the given input file. */
  Future run() {
    if (path.basename(_mainPath).endsWith('.dart')) {
      _messages.error("Please provide an HTML file as your entry point.",
          null);
      return new Future.value(null);
    }
    return _parseAndDiscover(_mainPath).then((_) {
      _analyze();

      // Analyze all CSS files.
      _time('Analyzed Style Sheets', '', () =>
          analyzeCss(_packageRoot, files, info,
              global.pseudoElements, _messages,
              warningsAsErrors: options.warningsAsErrors));
    });
  }

  /**
   * Asynchronously parse [inputFile] and transitively discover web components
   * to load and parse. Returns a future that completes when all files are
   * processed.
   */
  Future _parseAndDiscover(String inputFile) {
    _tasks = new FutureGroup();
    _processed = new Set();
    _processed.add(inputFile);
    _tasks.add(_parseHtmlFile(new UrlInfo(inputFile, inputFile, null)));
    return _tasks.future;
  }

  void _processHtmlFile(UrlInfo inputUrl, SourceFile file) {
    if (file == null) return;

    bool isEntryPoint = _processed.length == 1;

    files.add(file);

    var fileInfo = _time('Analyzed definitions', inputUrl.url, () {
      return analyzeDefinitions(global, inputUrl, file.document, _packageRoot,
        _messages, isEntryPoint: isEntryPoint);
    });
    info[inputUrl.resolvedPath] = fileInfo;

    if (isEntryPoint && _resetCssFile != null) {
      _processed.add(_resetCssFile);
      _tasks.add(_parseCssFile(new UrlInfo(_resetCssFile, _resetCssFile,
          null)));
    }

    _processImports(fileInfo);

    // Load component files referenced by [file].
    for (var link in fileInfo.componentLinks) {
      _loadFile(link, _parseHtmlFile);
    }

    // Load stylesheet files referenced by [file].
    for (var link in fileInfo.styleSheetHrefs) {
      _loadFile(link, _parseCssFile);
    }

    // Load .dart files being referenced in the page.
    _loadFile(fileInfo.externalFile, _parseDartFile);

    // Process any @imports inside of a <style> tag.
    var urlInfos = findUrlsImported(fileInfo, fileInfo.inputUrl, _packageRoot,
        file.document, _messages, options);
    for (var urlInfo in urlInfos) {
      _loadFile(urlInfo, _parseCssFile);
    }

    // Load .dart files being referenced in components.
    for (var component in fileInfo.declaredComponents) {
      if (component.externalFile != null) {
        _loadFile(component.externalFile, _parseDartFile);
      } else if (component.userCode != null) {
        _processImports(component);
      }

      // Process any @imports inside of the <style> tag in a component.
      var urlInfos = findUrlsImported(component,
          component.declaringFile.inputUrl, _packageRoot, component.element,
          _messages, options);
      for (var urlInfo in urlInfos) {
        _loadFile(urlInfo, _parseCssFile);
      }
    }
  }

  /**
   * Helper function to load [urlInfo] and parse it using [loadAndParse] if it
   * hasn't been loaded before.
   */
  void _loadFile(UrlInfo urlInfo, Future loadAndParse(UrlInfo inputUrl)) {
    if (urlInfo == null) return;
    var resolvedPath = urlInfo.resolvedPath;
    if (!_processed.contains(resolvedPath)) {
      _processed.add(resolvedPath);
      _tasks.add(loadAndParse(urlInfo));
    }
  }

  /** Parse an HTML file. */
  Future _parseHtmlFile(UrlInfo inputUrl) {
    var filePath = inputUrl.resolvedPath;
    return fileSystem.readTextOrBytes(filePath)
        .catchError((e) => _readError(e, inputUrl))
        .then((source) {
          if (source == null) return;
          var file = new SourceFile(filePath);
          file.document = _time('Parsed', filePath,
              () => parseHtml(source, filePath, _messages));
          _processHtmlFile(inputUrl, file);
        });
  }

  /** Parse a Dart file. */
  Future _parseDartFile(UrlInfo inputUrl) {
    var filePath = inputUrl.resolvedPath;
    return fileSystem.readText(filePath)
        .catchError((e) => _readError(e, inputUrl))
        .then((code) {
          if (code == null) return;
          var file = new SourceFile(filePath, type: SourceFile.DART);
          file.code = code;
          _processDartFile(inputUrl, file);
        });
  }

  /** Parse a stylesheet file. */
  Future _parseCssFile(UrlInfo inputUrl) {
    if (!options.emulateScopedCss) {
      return new Future<SourceFile>.value(null);
    }
    var filePath = inputUrl.resolvedPath;
    return fileSystem.readText(filePath)
        .catchError((e) => _readError(e, inputUrl, isWarning: true))
        .then((code) {
          if (code == null) return;
          var file = new SourceFile(filePath, type: SourceFile.STYLESHEET);
          file.code = code;
          _processCssFile(inputUrl, file);
        });
  }


  SourceFile _readError(error, UrlInfo inputUrl, {isWarning: false}) {
    var message = 'unable to open file "${inputUrl.resolvedPath}"';
    if (options.verbose) {
      message = '$message. original message:\n $error';
    }
    if (isWarning) {
      _messages.warning(message, inputUrl.sourceSpan);
    } else {
      _messages.error(message, inputUrl.sourceSpan);
    }
    return null;
  }

  void _processDartFile(UrlInfo inputUrl, SourceFile dartFile) {
    if (dartFile == null) return;

    files.add(dartFile);

    var resolvedPath = inputUrl.resolvedPath;
    var fileInfo = new FileInfo(inputUrl);
    info[resolvedPath] = fileInfo;
    fileInfo.inlinedCode = parseDartCode(resolvedPath, dartFile.code);
    _processImports(fileInfo);
  }

  void _processImports(LibraryInfo library) {
    if (library.userCode == null) return;

    for (var directive in library.userCode.directives) {
      _loadFile(_getDirectiveUrlInfo(library, directive), _parseDartFile);
    }
  }

  void _processCssFile(UrlInfo inputUrl, SourceFile cssFile) {
    if (cssFile == null) return;

    files.add(cssFile);

    var fileInfo = new FileInfo(inputUrl);
    info[inputUrl.resolvedPath] = fileInfo;

    var styleSheet = parseCss(cssFile.code, _messages, options);
    if (inputUrl.url == _resetCssFile) {
      _cssResetStyleSheet = styleSheet;
    } else if (styleSheet != null) {
      _resolveStyleSheetImports(inputUrl, cssFile.path, styleSheet);
      fileInfo.styleSheets.add(styleSheet);
    }
  }

  /** Load and parse all style sheets referenced with an @imports. */
  void _resolveStyleSheetImports(UrlInfo inputUrl, String processingFile,
      StyleSheet styleSheet) {
    var urlInfos = _time('CSS imports', processingFile, () =>
        findImportsInStyleSheet(styleSheet, _packageRoot, inputUrl, _messages));

    for (var urlInfo in urlInfos) {
      if (urlInfo == null) break;
      // Load any @imported stylesheet files referenced in this style sheet.
      _loadFile(urlInfo, _parseCssFile);
    }
  }

  String _directiveUri(Directive directive) {
    var uriDirective = (directive as UriBasedDirective).uri;
    return (uriDirective as dynamic).value;
  }

  UrlInfo _getDirectiveUrlInfo(LibraryInfo library, Directive directive) {
    var uri = _directiveUri(directive);
    if (uri.startsWith('dart:')) return null;
    if (uri.startsWith('package:') && uri.startsWith('package:polymer/')) {
      // Don't process our own package -- we'll implement @observable manually.
      return null;
    }

    var span = library.userCode.sourceFile.span(
        directive.offset, directive.end);
    return UrlInfo.resolve(uri, library.dartCodeUrl, span, _packageRoot,
        _messages);
  }

  /**
   * Finds all Dart code libraries.
   * Each library will have [LibraryInfo.inlinedCode] that is non-null.
   * Also each inlinedCode will be unique.
   */
  List<LibraryInfo> _findAllDartLibraries() {
    var libs = <LibraryInfo>[];
    void _addLibrary(LibraryInfo lib) {
      if (lib.inlinedCode != null) libs.add(lib);
    }

    for (var sourceFile in files) {
      var file = info[sourceFile.path];
      _addLibrary(file);
      file.declaredComponents.forEach(_addLibrary);
    }

    // Assert that each file path is unique.
    assert(_uniquePaths(libs));
    return libs;
  }

  bool _uniquePaths(List<LibraryInfo> libs) {
    var seen = new Set();
    for (var lib in libs) {
      if (seen.contains(lib.inlinedCode)) {
        throw new StateError('internal error: '
            'duplicate user code for ${lib.dartCodeUrl.resolvedPath}.'
            ' Files were: $files');
      }
      seen.add(lib.inlinedCode);
    }
    return true;
  }

  /**
   * This method computes which Dart files have been modified, starting
   * from [transformed] and marking recursively through all files that import
   * the modified files.
   */
  void _findModifiedDartFiles(List<LibraryInfo> libraries,
      List<FileInfo> transformed) {

    if (transformed.length == 0) return;

    // Compute files that reference each file, then use this information to
    // flip the modified bit transitively. This is a lot simpler than trying
    // to compute it the other way because of circular references.
    for (var lib in libraries) {
      for (var directive in lib.userCode.directives) {
        var importPath = _getDirectiveUrlInfo(lib, directive);
        if (importPath == null) continue;

        var importInfo = info[importPath.resolvedPath];
        if (importInfo != null) {
          importInfo.referencedBy.add(lib);
        }
      }
    }

    // Propegate the modified bit to anything that references a modified file.
    void setModified(LibraryInfo library) {
      if (library.modified) return;
      library.modified = true;
      library.referencedBy.forEach(setModified);
    }
    transformed.forEach(setModified);

    for (var lib in libraries) {
      // We don't need this anymore, so free it.
      lib.referencedBy = null;
    }
  }

  /** Run the analyzer on every input html file. */
  void _analyze() {
    var uniqueIds = new IntIterator();
    for (var file in files) {
      if (file.isHtml) {
        _time('Analyzed contents', file.path, () =>
            analyzeFile(file, info, uniqueIds, global, _messages,
              options.emulateScopedCss));
      }
    }
  }

  // TODO(jmesserly): refactor this and other CSS related transforms out of
  // Compiler.
  /**
   * Generate an CSS file for all style sheets (main and components).
   * Returns true if a file was generated, otherwise false.
   */
  bool _emitAllCss() {
    if (!options.emulateScopedCss) return false;

    var buff = new StringBuffer();

    // Emit all linked style sheet files first.
    for (var file in files) {
      var css = new StringBuffer();
      var fileInfo = info[file.path];
      if (file.isStyleSheet) {
        for (var styleSheet in fileInfo.styleSheets) {
          // Translate any URIs in CSS.
          rewriteCssUris(_pathMapper, fileInfo.inputUrl.resolvedPath,
              options.rewriteUrls, styleSheet);
          css.write(
              '/* Auto-generated from style sheet href = ${file.path} */\n'
              '/* DO NOT EDIT. */\n\n');
          css.write(emitStyleSheet(styleSheet, fileInfo));
          css.write('\n\n');
        }
      }
    }

    // Emit all CSS for each component (style scoped).
    for (var file in files) {
      if (file.isHtml) {
        var fileInfo = info[file.path];
        for (var component in fileInfo.declaredComponents) {
          for (var styleSheet in component.styleSheets) {
            // Translate any URIs in CSS.
            rewriteCssUris(_pathMapper, fileInfo.inputUrl.resolvedPath,
                options.rewriteUrls, styleSheet);

            if (buff.isEmpty) {
              buff.write(
                  '/* Auto-generated from components style tags. */\n'
                  '/* DO NOT EDIT. */\n\n');
            }
            buff.write(
                '/* ==================================================== \n'
                '   Component ${component.tagName} stylesheet \n'
                '   ==================================================== */\n');

            var tagName = component.tagName;
            if (!component.hasAuthorStyles) {
              if (_cssResetStyleSheet != null) {
                // If component doesn't have apply-author-styles then we need to
                // reset the CSS the styles for the component (if css-reset file
                // option was passed).
                buff.write('\n/* Start CSS Reset */\n');
                var style;
                if (options.emulateScopedCss) {
                  style = emitComponentStyleSheet(_cssResetStyleSheet, tagName);
                } else {
                  style = emitOriginalCss(_cssResetStyleSheet);
                }
                buff.write(style);
                buff.write('/* End CSS Reset */\n\n');
              }
            }
            if (options.emulateScopedCss) {
              buff.write(emitComponentStyleSheet(styleSheet, tagName));
            } else {
              buff.write(emitOriginalCss(styleSheet));
            }
            buff.write('\n\n');
          }
        }
      }
    }

    if (buff.isEmpty) return false;

    var cssPath = _pathMapper.outputPath(_mainPath, '.css', true);
    output.add(new OutputFile(cssPath, buff.toString()));
    return true;
  }

  _time(String logMessage, String filePath, callback(),
      {bool printTime: false}) {
    var message = new StringBuffer();
    message.write(logMessage);
    var filename = path.basename(filePath);
    for (int i = (60 - logMessage.length - filename.length); i > 0 ; i--) {
      message.write(' ');
    }
    message.write(filename);
    return time(message.toString(), callback,
        printTime: options.verbose || printTime);
  }
}
