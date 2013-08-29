// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library compiler;

import 'dart:async';
import 'dart:collection' show SplayTreeMap;

import 'package:csslib/visitor.dart' show StyleSheet, treeToDebugString;
import 'package:html5lib/dom.dart';
import 'package:html5lib/parser.dart';

import 'analyzer.dart';
import 'css_analyzer.dart' show analyzeCss, findUrlsImported,
       findImportsInStyleSheet, parseCss;
import 'css_emitters.dart' show rewriteCssUris,
       emitComponentStyleSheet, emitOriginalCss, emitStyleSheet;
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
        _messages);
    });
    info[inputUrl.resolvedPath] = fileInfo;

    if (isEntryPoint && _resetCssFile != null) {
      _processed.add(_resetCssFile);
      _tasks.add(_parseCssFile(new UrlInfo(_resetCssFile, _resetCssFile,
          null)));
    }

    // Load component files referenced by [file].
    for (var link in fileInfo.componentLinks) {
      _loadFile(link, _parseHtmlFile);
    }

    // Load stylesheet files referenced by [file].
    for (var link in fileInfo.styleSheetHrefs) {
      _loadFile(link, _parseCssFile);
    }

    // Process any @imports inside of a <style> tag.
    var urlInfos = findUrlsImported(fileInfo, fileInfo.inputUrl, _packageRoot,
        file.document, _messages, options);
    for (var urlInfo in urlInfos) {
      _loadFile(urlInfo, _parseCssFile);
    }

    // Load .dart files being referenced in components.
    for (var component in fileInfo.declaredComponents) {
      // Process any @imports inside of the <style> tag in a component.
      var urlInfos = findUrlsImported(component, fileInfo.inputUrl,
          _packageRoot, component.element, _messages, options);
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
