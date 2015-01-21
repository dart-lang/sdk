// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analysis_server.src.get_handler;

import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/domain_completion.dart';
import 'package:analysis_server/src/domain_execution.dart';
import 'package:analysis_server/src/operation/operation.dart';
import 'package:analysis_server/src/operation/operation_analysis.dart';
import 'package:analysis_server/src/operation/operation_queue.dart';
import 'package:analysis_server/src/protocol.dart' hide Element;
import 'package:analysis_server/src/socket_server.dart';
import 'package:analysis_server/src/status/ast_writer.dart';
import 'package:analysis_server/src/status/element_writer.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/source.dart';

import 'analysis_server.dart';

/**
 * A function that can be used to generate HTML output into the given [buffer].
 * The HTML that is generated must be valid (special characters must already be
 * encoded).
 */
typedef void HtmlGenerator(StringBuffer buffer);

/**
 * Instances of the class [GetHandler] handle GET requests.
 */
class GetHandler {
  /**
   * The path used to request the status of the analysis server as a whole.
   */
  static const String STATUS_PATH = '/status';

  /**
   * The path used to request information about a element model.
   */
  static const String AST_PATH = '/ast';

  /**
   * The path used to request information about the cache entry corresponding
   * to a single file.
   */
  static const String CACHE_ENTRY_PATH = '/cache_entry';

  /**
   * The path used to request information about the cache entry corresponding
   * to a single file.
   */
  static const String CACHE_ENTRY2_PATH = '/cache_entry2';

  /**
   * The path used to request the list of source files in a certain cache
   * state.
   */
  static const String CACHE_STATE_PATH = '/cache_state';

  /**
   * The path used to request code completion information.
   */
  static const String COMPLETION_PATH = '/completion';

  /**
   * The path used to request information about a specific context.
   */
  static const String CONTEXT_PATH = '/context';

  /**
   * The path used to request information about a element model.
   */
  static const String ELEMENT_PATH = '/element';

  /**
   * The path used to request an overlay contents.
   */
  static const String OVERLAY_PATH = '/overlay';

  /**
   * The path used to request overlays information.
   */
  static const String OVERLAYS_PATH = '/overlays';

  /**
   * Query parameter used to represent the cache state to search for, when
   * accessing [CACHE_STATE_PATH].
   */
  static const String STATE_QUERY_PARAM = 'state';

  /**
   * Query parameter used to represent the context to search for, when
   * accessing [CACHE_ENTRY_PATH] or [CACHE_STATE_PATH].
   */
  static const String CONTEXT_QUERY_PARAM = 'context';

  /**
   * Query parameter used to represent the descriptor to search for, when
   * accessing [CACHE_STATE_PATH].
   */
  static const String DESCRIPTOR_QUERY_PARAM = 'descriptor';

  /**
   * Query parameter used to represent the index in the [_overlayContents].
   */
  static const String ID_PARAM = 'id';

  /**
   * Query parameter used to represent the source to search for, when accessing
   * [CACHE_ENTRY_PATH].
   */
  static const String SOURCE_QUERY_PARAM = 'entry';

  static final ContentType _htmlContent =
      new ContentType("text", "html", charset: "utf-8");

  /**
   * The socket server whose status is to be reported on.
   */
  SocketServer _server;

  /**
   * Buffer containing strings printed by the analysis server.
   */
  List<String> _printBuffer;

  /**
   * Contents of overlay files.
   */
  final Map<int, String> _overlayContents = <int, String>{};

  /**
   * Initialize a newly created handler for GET requests.
   */
  GetHandler(this._server, this._printBuffer);

  /**
   * Handle a GET request received by the HTTP server.
   */
  void handleGetRequest(HttpRequest request) {
    String path = request.uri.path;
    if (path == STATUS_PATH) {
      _returnServerStatus(request);
    } else if (path == '/status2') {
      _returnServerStatus2(request);
    } else if (path == AST_PATH) {
      _returnAst(request);
    } else if (path == CACHE_STATE_PATH) {
      _returnCacheState(request);
    } else if (path == CACHE_ENTRY_PATH) {
      _returnCacheEntry(request);
    } else if (path == CACHE_ENTRY2_PATH) {
      _returnCacheEntry2(request);
    } else if (path == COMPLETION_PATH) {
      _returnCompletionInfo(request);
    } else if (path == CONTEXT_PATH) {
      _returnContextInfo(request);
    } else if (path == ELEMENT_PATH) {
      _returnElement(request);
    } else if (path == OVERLAY_PATH) {
      _returnOverlayContents(request);
    } else if (path == OVERLAYS_PATH) {
      _returnOverlaysInfo(request);
    } else {
      _returnUnknownRequest(request);
    }
  }

  /**
   * Return the folder being managed by the given [analysisServer] that matches
   * the given [contextFilter], or `null` if there is none.
   */
  Folder _findFolder(AnalysisServer analysisServer, String contextFilter) {
    return analysisServer.folderMap.keys.firstWhere(
        (Folder folder) => folder.path == contextFilter,
        orElse: () => null);
  }

  /**
   * Return `true` if the given analysis [context] has at least one entry with
   * an exception.
   */
  bool _hasException(AnalysisContextImpl context) {
    bool hasException = false;
    context.visitCacheItems(
        (Source source, SourceEntry sourceEntry, DataDescriptor rowDesc,
            CacheState state) {
      if (sourceEntry.exception != null) {
        hasException = true;
      }
    });
    return hasException;
  }

  Folder _keyForValue(Map<Folder, AnalysisContext> folderMap,
      AnalysisContext context) {
    for (Folder folder in folderMap.keys) {
      if (folderMap[folder] == context) {
        return folder;
      }
    }
    return null;
  }

  /**
   * Create a link to [path] with query parameters [params], with inner HTML
   * [innerHtml]. If [hasError] is `true`, then the link will have the class
   * 'error'.
   */
  String _makeLink(String path, Map<String, String> params, String innerHtml,
      [bool hasError = false]) {
    Uri uri = new Uri(path: path, queryParameters: params);
    String href = HTML_ESCAPE.convert(uri.toString());
    String classAttribute = hasError ? ' class="error"' : '';
    return '<a href="$href"$classAttribute>$innerHtml</a>';
  }

  /**
   * Generate a table showing the cache values corresponding to the given
   * [descriptors], using [getState] to get the cache state corresponding to
   * each descriptor, and [getValue] to get the cached value corresponding to
   * each descriptor.  Append the resulting HTML to [response].
   */
  void _outputDescriptorTable(HttpResponse response,
      List<DataDescriptor> descriptors, CacheState getState(DataDescriptor), dynamic
      getValue(DataDescriptor)) {
    response.write('<dl>');
    for (DataDescriptor descriptor in descriptors) {
      String descriptorName = HTML_ESCAPE.convert(descriptor.toString());
      String descriptorState =
          HTML_ESCAPE.convert(getState(descriptor).toString());
      response.write('<dt>$descriptorName ($descriptorState)</dt><dd>');
      try {
        _outputValueAsHtml(response, getValue(descriptor));
      } catch (exception) {
        response.write('(${HTML_ESCAPE.convert(exception.toString())})');
      }
      response.write('</dd>');
    }
    response.write('</dl>');
  }

  /**
   * Render the given [value] as HTML and append it to [response].
   */
  void _outputValueAsHtml(HttpResponse response, dynamic value) {
    if (value == null) {
      response.write('<i>null</i>');
    } else if (value is String) {
      response.write('<pre>${HTML_ESCAPE.convert(value)}</pre>');
    } else if (value is List) {
      response.write('${value.length} entries');
      response.write('<ul>');
      for (var entry in value) {
        response.write('<li>');
        _outputValueAsHtml(response, entry);
        response.write('</li>');
      }
      response.write('</ul>');
    } else {
      response.write(HTML_ESCAPE.convert(value.toString()));
      response.write(
          ' <i>(${HTML_ESCAPE.convert(value.runtimeType.toString())})</i>');
    }
  }

  /**
   * Return a response containing information about an AST structure.
   */
  void _returnAst(HttpRequest request) {
    AnalysisServer analysisServer = _server.analysisServer;
    if (analysisServer == null) {
      return _returnFailure(request, 'Analysis server not running');
    }
    String contextFilter = request.uri.queryParameters[CONTEXT_QUERY_PARAM];
    if (contextFilter == null) {
      return _returnFailure(
          request,
          'Query parameter $CONTEXT_QUERY_PARAM required');
    }
    Folder folder = _findFolder(analysisServer, contextFilter);
    if (folder == null) {
      return _returnFailure(request, 'Invalid context: $contextFilter');
    }
    String sourceUri = request.uri.queryParameters[SOURCE_QUERY_PARAM];
    if (sourceUri == null) {
      return _returnFailure(
          request,
          'Query parameter $SOURCE_QUERY_PARAM required');
    }

    AnalysisContextImpl context = analysisServer.folderMap[folder];

    _writeResponse(request, (StringBuffer buffer) {
      _writePage(
          buffer,
          'Analysis Server - AST Structure',
          ['Context: $contextFilter', 'File: $sourceUri'],
          (HttpResponse) {
        Source source = context.sourceFactory.forUri(sourceUri);
        if (source == null) {
          buffer.write('<p>Not found.</p>');
          return;
        }
        SourceEntry entry = context.getReadableSourceEntryOrNull(source);
        if (entry == null) {
          buffer.write('<p>Not found.</p>');
          return;
        }
        CompilationUnit ast = (entry as DartEntry).anyParsedCompilationUnit;
        if (ast == null) {
          buffer.write('<p>null</p>');
          return;
        }
        ast.accept(new AstWriter(buffer));
      });
    });
  }

  /**
   * Return a response containing information about a single source file in the
   * cache.
   */
  void _returnCacheEntry(HttpRequest request) {
    // Figure out which context is being searched for.
    String contextFilter = request.uri.queryParameters[CONTEXT_QUERY_PARAM];
    if (contextFilter == null) {
      return _returnFailure(
          request,
          'Query parameter $CONTEXT_QUERY_PARAM required');
    }

    // Figure out which CacheEntry is being searched for.
    String sourceUri = request.uri.queryParameters[SOURCE_QUERY_PARAM];
    if (sourceUri == null) {
      return _returnFailure(
          request,
          'Query parameter $SOURCE_QUERY_PARAM required');
    }

    AnalysisServer analysisServer = _server.analysisServer;
    if (analysisServer == null) {
      return _returnFailure(request, 'Analysis server not running');
    }

    HttpResponse response = request.response;
    response.statusCode = HttpStatus.OK;
    response.headers.contentType = _htmlContent;
    response.write('<html>');
    response.write('<head>');
    response.write('<title>Dart Analysis Server - Search result</title>');
    response.write('</head>');
    response.write('<body>');
    response.write('<h1>');
    response.write('File ${HTML_ESCAPE.convert(sourceUri)}');
    response.write(' in context ${HTML_ESCAPE.convert(contextFilter)}');
    response.write('</h1>');
    analysisServer.folderMap.forEach(
        (Folder folder, AnalysisContextImpl context) {
      if (folder.path != contextFilter) {
        return;
      }
      Source source = context.sourceFactory.forUri(sourceUri);
      if (source == null) {
        response.write('<p>Not found.</p>');
        return;
      }
      SourceEntry entry = context.getReadableSourceEntryOrNull(source);
      if (entry == null) {
        response.write('<p>Not found.</p>');
        return;
      }
      response.write('<h2>File info:</h2><dl>');
      _outputDescriptorTable(
          response,
          entry.descriptors,
          entry.getState,
          entry.getValue);
      if (entry is DartEntry) {
        for (Source librarySource in entry.containingLibraries) {
          String libraryName = HTML_ESCAPE.convert(librarySource.fullName);
          response.write('<h2>In library $libraryName:</h2>');
          _outputDescriptorTable(
              response,
              entry.libraryDescriptors,
              (DataDescriptor descriptor) =>
                  entry.getStateInLibrary(descriptor, librarySource),
              (DataDescriptor descriptor) =>
                  entry.getValueInLibrary(descriptor, librarySource));
        }
      }
    });
    response.write('</body>');
    response.write('</html>');

    response.close();
  }

  /**
   * Return a response containing information about a single source file in the
   * cache.
   */
  void _returnCacheEntry2(HttpRequest request) {
    AnalysisServer analysisServer = _server.analysisServer;
    if (analysisServer == null) {
      return _returnFailure(request, 'Analysis server not running');
    }
    String contextFilter = request.uri.queryParameters[CONTEXT_QUERY_PARAM];
    if (contextFilter == null) {
      return _returnFailure(
          request,
          'Query parameter $CONTEXT_QUERY_PARAM required');
    }
    Folder folder = _findFolder(analysisServer, contextFilter);
    if (folder == null) {
      return _returnFailure(request, 'Invalid context: $contextFilter');
    }
    String sourceUri = request.uri.queryParameters[SOURCE_QUERY_PARAM];
    if (sourceUri == null) {
      return _returnFailure(
          request,
          'Query parameter $SOURCE_QUERY_PARAM required');
    }

    AnalysisContextImpl context = analysisServer.folderMap[folder];

    _writeResponse(request, (StringBuffer buffer) {
      _writePage(
          buffer,
          'Analysis Server - Cache Entry',
          ['Context: $contextFilter', 'File: $sourceUri'],
          (HttpResponse) {
        Source source = context.sourceFactory.forUri(sourceUri);
        if (source == null) {
          buffer.write('<p>Not found.</p>');
          return;
        }
        SourceEntry entry = context.getReadableSourceEntryOrNull(source);
        if (entry == null) {
          buffer.write('<p>Not found.</p>');
          return;
        }
        Map<String, String> linkParameters = <String, String>{
          CONTEXT_QUERY_PARAM: folder.path,
          SOURCE_QUERY_PARAM: source.uri.toString()
        };
        buffer.write('<h3>Library Independent</h3>');
        _writeDescriptorTable(
            buffer,
            entry.descriptors,
            entry.getState,
            entry.getValue,
            linkParameters);
        if (entry is DartEntry) {
          for (Source librarySource in entry.containingLibraries) {
            String libraryName = HTML_ESCAPE.convert(librarySource.fullName);
            buffer.write('<h3>In library $libraryName:</h3>');
            _writeDescriptorTable(
                buffer,
                entry.libraryDescriptors,
                (DataDescriptor descriptor) =>
                    entry.getStateInLibrary(descriptor, librarySource),
                (DataDescriptor descriptor) =>
                    entry.getValueInLibrary(descriptor, librarySource),
                linkParameters);
          }
        }
        if (entry.exception != null) {
          buffer.write('<h3>Exception</h3>');
          _writeException(buffer, entry.exception);
        }
      });
    });
  }

  /**
   * Return a response indicating the set of source files in a certain cache
   * state.
   */
  void _returnCacheState(HttpRequest request) {
    // Figure out what CacheState is being searched for.
    String stateQueryParam = request.uri.queryParameters[STATE_QUERY_PARAM];
    if (stateQueryParam == null) {
      return _returnFailure(
          request,
          'Query parameter $STATE_QUERY_PARAM required');
    }
    CacheState stateFilter = null;
    for (CacheState value in CacheState.values) {
      if (value.toString() == stateQueryParam) {
        stateFilter = value;
      }
    }
    if (stateFilter == null) {
      return _returnFailure(
          request,
          'Query parameter $STATE_QUERY_PARAM is invalid');
    }

    // Figure out which context is being searched for.
    String contextFilter = request.uri.queryParameters[CONTEXT_QUERY_PARAM];
    if (contextFilter == null) {
      return _returnFailure(
          request,
          'Query parameter $CONTEXT_QUERY_PARAM required');
    }

    // Figure out which descriptor is being searched for.
    String descriptorFilter =
        request.uri.queryParameters[DESCRIPTOR_QUERY_PARAM];
    if (descriptorFilter == null) {
      return _returnFailure(
          request,
          'Query parameter $DESCRIPTOR_QUERY_PARAM required');
    }

    AnalysisServer analysisServer = _server.analysisServer;
    if (analysisServer == null) {
      return _returnFailure(request, 'Analysis server not running');
    }
    HttpResponse response = request.response;
    response.statusCode = HttpStatus.OK;
    response.headers.contentType = _htmlContent;
    response.write('<html>');
    response.write('<head>');
    response.write('<title>Dart Analysis Server - Search result</title>');
    response.write('</head>');
    response.write('<body>');
    response.write('<h1>');
    response.write('Files with state ${HTML_ESCAPE.convert(stateQueryParam)}');
    response.write(' for descriptor ${HTML_ESCAPE.convert(descriptorFilter)}');
    response.write(' in context ${HTML_ESCAPE.convert(contextFilter)}');
    response.write('</h1>');
    response.write('<ul>');
    int count = 0;
    analysisServer.folderMap.forEach(
        (Folder folder, AnalysisContextImpl context) {
      if (folder.path != contextFilter) {
        return;
      }
      context.visitCacheItems(
          (Source source, SourceEntry dartEntry, DataDescriptor rowDesc, CacheState state)
              {
        if (state != stateFilter || rowDesc.toString() != descriptorFilter) {
          return;
        }
        String link = _makeLink(CACHE_ENTRY_PATH, {
          CONTEXT_QUERY_PARAM: folder.path,
          SOURCE_QUERY_PARAM: source.uri.toString()
        }, HTML_ESCAPE.convert(source.fullName));
        response.write('<li>$link</li>');
        count++;
      });
    });
    response.write('</ul>');
    response.write('<p>$count files found</p>');
    response.write('</body>');
    response.write('</html>');
    response.close();
  }

  /**
   * Return a response displaying code completion information.
   */
  void _returnCompletionInfo(HttpRequest request) {
    var refresh = request.requestedUri.queryParameters['refresh'];
    var maxCount = request.requestedUri.queryParameters['maxCount'];
    HttpResponse response = request.response;
    response.statusCode = HttpStatus.OK;
    response.headers.contentType = _htmlContent;
    response.write('<html>');
    response.write('<head>');
    response.write('<title>Dart Analysis Server - Completion Stats</title>');
    response.write('<style>');
    response.write('td.right {text-align: right;}');
    response.write('</style>');
    if (refresh is String) {
      int seconds = int.parse(refresh, onError: (_) => 5);
      response.write('<meta http-equiv="refresh" content="$seconds">');
    }
    response.write('</head>');
    response.write('<body>');
    _writeCompletionInfo(response, maxCount);
    response.write('<p>&nbsp</p>');
    response.write('<p>Try ');
    response.write('<a href="?refresh=5">?refresh=5</a>');
    response.write(' to refresh every 5 seconds</p>');
    response.write('<p>and ');
    response.write('<a href="?maxCount=50">?maxCount=50</a>');
    response.write(' to keep the last 50 performance measurements</p>');
    response.write('</body>');
    response.write('</html>');
    response.close();
  }

  /**
   * Return a response containing information about a single source file in the
   * cache.
   */
  void _returnContextInfo(HttpRequest request) {
    AnalysisServer analysisServer = _server.analysisServer;
    if (analysisServer == null) {
      return _returnFailure(request, 'Analysis server not running');
    }
    String contextFilter = request.uri.queryParameters[CONTEXT_QUERY_PARAM];
    if (contextFilter == null) {
      return _returnFailure(
          request,
          'Query parameter $CONTEXT_QUERY_PARAM required');
    }
    Folder folder = _findFolder(analysisServer, contextFilter);
    if (folder == null) {
      return _returnFailure(request, 'Invalid context: $contextFilter');
    }

    List<String> priorityNames;
    List<String> explicitNames = <String>[];
    List<String> implicitNames = <String>[];
    Map<String, String> links = new HashMap<String, String>();
    List<CaughtException> exceptions = <CaughtException>[];
    Map<String, int> overlayMap = new HashMap<String, int>();
    AnalysisContextImpl context = analysisServer.folderMap[folder];
    priorityNames =
        context.prioritySources.map((Source source) => source.fullName).toList();
    context.visitCacheItems(
        (Source source, SourceEntry sourceEntry, DataDescriptor rowDesc,
            CacheState state) {
      String sourceName = source.fullName;
      if (!links.containsKey(sourceName)) {
        CaughtException exception = sourceEntry.exception;
        if (exception != null) {
          exceptions.add(exception);
        }
        String link = _makeLink(CACHE_ENTRY2_PATH, {
          CONTEXT_QUERY_PARAM: folder.path,
          SOURCE_QUERY_PARAM: source.uri.toString()
        }, sourceName, exception != null);
        if (sourceEntry.explicitlyAdded) {
          explicitNames.add(sourceName);
        } else {
          implicitNames.add(sourceName);
        }
        links[sourceName] = link;
      }
    });
    _overlayContents.clear();
    int count = 0;
    context.visitContentCache((Source source, int stamp, String contents) {
      count++;
      overlayMap[source.fullName] = count;
      _overlayContents[count] = contents;
    });
    explicitNames.sort();
    implicitNames.sort();

    void _writeFiles(StringBuffer buffer, String title, List<String> fileNames)
        {
      buffer.write('<h3>$title</h3>');
      if (fileNames == null || fileNames.isEmpty) {
        buffer.write('<p>None</p>');
      } else {
        buffer.write('<table style="width: 100%">');
        for (String fileName in fileNames) {
          buffer.write('<tr><td>');
          buffer.write(links[fileName]);
          buffer.write('</td><td>');
          if (overlayMap.containsKey(fileName)) {
            buffer.write(_makeLink(OVERLAY_PATH, {
              ID_PARAM: overlayMap[fileName].toString()
            }, 'overlay'));
          }
          buffer.write('</td></tr>');
        }
        buffer.write('</table>');
      }
    }

    _writeResponse(request, (StringBuffer buffer) {
      _writePage(
          buffer,
          'Analysis Server - Context',
          ['Context: $contextFilter'],
          (StringBuffer buffer) {
        List headerRowText = ['Context'];
        headerRowText.addAll(CacheState.values);
        buffer.write('<h3>Summary</h3>');
        buffer.write('<table>');
        _writeRow2(buffer, headerRowText, header: true);
        AnalysisContextStatistics statistics = context.statistics;
        statistics.cacheRows.forEach((AnalysisContextStatistics_CacheRow row) {
          List rowText = [row.name];
          for (CacheState state in CacheState.values) {
            String text = row.getCount(state).toString();
            Map<String, String> params = <String, String>{
              STATE_QUERY_PARAM: state.toString(),
              CONTEXT_QUERY_PARAM: folder.path,
              DESCRIPTOR_QUERY_PARAM: row.name
            };
            rowText.add(_makeLink(CACHE_STATE_PATH, params, text));
          }
          _writeRow2(buffer, rowText, classes: [null, "right"]);
        });
        buffer.write('</table>');

        _writeFiles(buffer, 'Priority Files', priorityNames);
        _writeFiles(buffer, 'Explicitly Analyzed Files', explicitNames);
        _writeFiles(buffer, 'Implicitly Analyzed Files', implicitNames);

        buffer.write('<h3>Exceptions</h3>');
        if (exceptions.isEmpty) {
          buffer.write('<p>None</p>');
        } else {
          exceptions.forEach((CaughtException exception) {
            _writeException(buffer, exception);
          });
        }
      });
    });
  }

  /**
   * Return a response containing information about an element structure.
   */
  void _returnElement(HttpRequest request) {
    AnalysisServer analysisServer = _server.analysisServer;
    if (analysisServer == null) {
      return _returnFailure(request, 'Analysis server not running');
    }
    String contextFilter = request.uri.queryParameters[CONTEXT_QUERY_PARAM];
    if (contextFilter == null) {
      return _returnFailure(
          request,
          'Query parameter $CONTEXT_QUERY_PARAM required');
    }
    Folder folder = _findFolder(analysisServer, contextFilter);
    if (folder == null) {
      return _returnFailure(request, 'Invalid context: $contextFilter');
    }
    String sourceUri = request.uri.queryParameters[SOURCE_QUERY_PARAM];
    if (sourceUri == null) {
      return _returnFailure(
          request,
          'Query parameter $SOURCE_QUERY_PARAM required');
    }

    AnalysisContextImpl context = analysisServer.folderMap[folder];

    _writeResponse(request, (StringBuffer buffer) {
      _writePage(
          buffer,
          'Analysis Server - Element Model',
          ['Context: $contextFilter', 'File: $sourceUri'],
          (HttpResponse) {
        Source source = context.sourceFactory.forUri(sourceUri);
        if (source == null) {
          buffer.write('<p>Not found.</p>');
          return;
        }
        SourceEntry entry = context.getReadableSourceEntryOrNull(source);
        if (entry == null) {
          buffer.write('<p>Not found.</p>');
          return;
        }
        LibraryElement element = entry.getValue(DartEntry.ELEMENT);
        if (element == null) {
          buffer.write('<p>null</p>');
          return;
        }
        element.accept(new ElementWriter(buffer));
      });
    });
  }

  void _returnFailure(HttpRequest request, String message) {
    HttpResponse response = request.response;
    response.statusCode = HttpStatus.OK;
    response.headers.contentType = _htmlContent;
    response.write('<html>');
    response.write('<head>');
    response.write('<title>Dart Analysis Server - Failure</title>');
    response.write('</head>');
    response.write('<body>');
    response.write(HTML_ESCAPE.convert(message));
    response.write('</body>');
    response.write('</html>');
    response.close();
  }

  void _returnOverlayContents(HttpRequest request) {
    String idString = request.requestedUri.queryParameters[ID_PARAM];
    int id = int.parse(idString);
    String contents = _overlayContents[id];
    HttpResponse response = request.response;
    response.statusCode = HttpStatus.OK;
    response.headers.contentType = _htmlContent;
    response.write('<html>');
    response.write('<head>');
    response.write('<title>Dart Analysis Server - Overlay</title>');
    response.write('</head>');
    response.write('<body>');
    response.write('<pre>${HTML_ESCAPE.convert(contents)}</pre>');
    response.write('</body>');
    response.write('</html>');
    response.close();
  }

  /**
   * Return a response displaying overlays information.
   */
  void _returnOverlaysInfo(HttpRequest request) {
    AnalysisServer analysisServer = _server.analysisServer;
    if (analysisServer == null) {
      return _returnFailure(request, 'Analysis server is not running');
    }
    HttpResponse response = request.response;
    response.statusCode = HttpStatus.OK;
    response.headers.contentType = _htmlContent;
    response.write('<html>');
    response.write('<head>');
    response.write('<title>Dart Analysis Server - Overlays</title>');
    response.write('</head>');
    response.write('<body>');
    response.write('<h1>Dart Analysis Server - Overlays</h1>');
    response.write('<table border="1">');
    int count = 0;
    _overlayContents.clear();
    analysisServer.folderMap.forEach((_, AnalysisContextImpl context) {
      context.visitContentCache((Source source, int stamp, String contents) {
        count++;
        response.write('<tr>');
        String linkRef = '$OVERLAY_PATH?id=$count';
        String linkText = HTML_ESCAPE.convert(source.toString());
        response.write('<td><a href="$linkRef">$linkText</a></td>');
        response.write(
            '<td>${new DateTime.fromMillisecondsSinceEpoch(stamp)}</td>');
        response.write('</tr>');
        _overlayContents[count] = contents;
      });
    });
    response.write('<tr><td colspan="2">Total: $count entries.</td></tr>');
    response.write('</table>');
    response.write('</body>');
    response.write('</html>');
    response.close();
  }

  /**
   * Return a response indicating the status of the analysis server.
   */
  void _returnServerStatus(HttpRequest request) {
    HttpResponse response = request.response;
    response.statusCode = HttpStatus.OK;
    response.headers.contentType = _htmlContent;
    response.write('<html>');
    response.write('<head>');
    response.write('<title>Dart Analysis Server - Status</title>');
    response.write('<style>');
    response.write('td.right {text-align: right;}');
    response.write('</style>');
    response.write('</head>');
    response.write('<body>');
    response.write('<h1>Analysis Server</h1>');
    AnalysisServer analysisServer = _server.analysisServer;
    if (analysisServer == null) {
      response.write('<p>Not running</p>');
    } else {
      if (analysisServer.statusAnalyzing) {
        response.write('<p>Running (analyzing)</p>');
      } else {
        response.write('<p>Running (not analyzing)</p>');
      }
      response.write('<p>Instrumentation status: ');
      if (AnalysisEngine.instance.instrumentationService.isActive) {
        response.write('<span style="color:red">active</span>');
      } else {
        response.write('inactive');
      }
      response.write('</p>');
      response.write('<h1>Analysis Contexts</h1>');
      response.write('<h2>Summary</h2>');
      response.write('<table>');
      List headerRowText = ['Context'];
      headerRowText.addAll(CacheState.values);
      _writeRow(response, headerRowText, header: true);
      Map<Folder, AnalysisContext> folderMap = analysisServer.folderMap;
      List<Folder> folders = folderMap.keys.toList();
      folders.sort(
          (Folder first, Folder second) => first.shortName.compareTo(second.shortName));
      folders.forEach((Folder folder) {
        AnalysisContextImpl context = folderMap[folder];
        String key = folder.shortName;
        AnalysisContextStatistics statistics = context.statistics;
        Map<CacheState, int> totals = <CacheState, int>{};
        for (CacheState state in CacheState.values) {
          totals[state] = 0;
        }
        statistics.cacheRows.forEach((AnalysisContextStatistics_CacheRow row) {
          for (CacheState state in CacheState.values) {
            totals[state] += row.getCount(state);
          }
        });
        List rowText = [
            '<a href="#context_${HTML_ESCAPE.convert(key)}">$key</a>'];
        for (CacheState state in CacheState.values) {
          rowText.add(totals[state]);
        }
        _writeRow(response, rowText, classes: [null, "right"]);
      });
      response.write('</table>');
      folders.forEach((Folder folder) {
        AnalysisContextImpl context = folderMap[folder];
        String key = folder.shortName;
        response.write(
            '<h2><a name="context_${HTML_ESCAPE.convert(key)}">Analysis Context: $key</a></h2>');
        AnalysisContextStatistics statistics = context.statistics;
        response.write('<table>');
        _writeRow(response, headerRowText, header: true);
        statistics.cacheRows.forEach((AnalysisContextStatistics_CacheRow row) {
          List rowText = [row.name];
          for (CacheState state in CacheState.values) {
            String text = row.getCount(state).toString();
            Map<String, String> params = <String, String>{
              STATE_QUERY_PARAM: state.toString(),
              CONTEXT_QUERY_PARAM: folder.path,
              DESCRIPTOR_QUERY_PARAM: row.name
            };
            rowText.add(_makeLink(CACHE_STATE_PATH, params, text));
          }
          _writeRow(response, rowText, classes: [null, "right"]);
        });
        response.write('</table>');
        List<CaughtException> exceptions = statistics.exceptions;
        if (!exceptions.isEmpty) {
          response.write('<h2>Exceptions</h2>');
          exceptions.forEach((CaughtException exception) {
            StringBuffer buffer = new StringBuffer();
            _writeException(buffer, exception);
            response.write(buffer.toString());
          });
        }
      });
    }
    response.write('<h1>Most recent strings printed by analysis server</h2>');
    response.write('<pre>');
    response.write(HTML_ESCAPE.convert(_printBuffer.join('\n')));
    response.write('</pre>');
    response.write('</body>');
    response.write('</html>');
    response.close();
  }

  /**
   * Return a response indicating the status of the analysis server.
   */
  void _returnServerStatus2(HttpRequest request) {
    _writeResponse(request, (StringBuffer buffer) {
      _writePage(buffer, 'Analysis Server - Status', [], (StringBuffer buffer) {
        if (_writeServerStatus(buffer)) {
          _writeAnalysisStatus(buffer);
          _writeEditStatus(buffer);
          _writeExecutionStatus(buffer);
          _writeRecentOutput(buffer);
        }
      });
    });
  }

  /**
   * Return an error in response to an unrecognized request received by the HTTP
   * server.
   */
  void _returnUnknownRequest(HttpRequest request) {
    HttpResponse response = request.response;
    response.statusCode = HttpStatus.NOT_FOUND;
    response.headers.contentType = _htmlContent;
    response.write('<html>');
    response.write('<head>');
    response.write('<title>Dart Analysis Server - Page Not Found</title>');
    response.write('</head>');
    response.write('<body>');
    response.write('<h1>Page Not Found</h1>');
    response.write('<p>Try one of these links instead:</p>');
    response.write('<ul>');
    response.write('<li><a href="$STATUS_PATH">Server Status</a></li>');
    response.write('<li><a href="$COMPLETION_PATH">Completion Stats</a></li>');
    response.write('<ul>');
    response.write('</body>');
    response.write('</html>');
    response.close();
  }

  /**
   * Return a two digit decimal representation of the given non-negative integer
   * [value].
   */
  String _twoDigit(int value) {
    if (value < 10) {
      return '0$value';
    }
    return value.toString();
  }

  /**
   * Write the status of the analysis domain (on the main status page) to the
   * given [buffer] object.
   */
  void _writeAnalysisStatus(StringBuffer buffer) {
    AnalysisServer analysisServer = _server.analysisServer;
    Map<Folder, AnalysisContext> folderMap = analysisServer.folderMap;
    List<Folder> folders = folderMap.keys.toList();
    folders.sort(
        (Folder first, Folder second) => first.shortName.compareTo(second.shortName));
    AnalysisOptionsImpl options =
        analysisServer.contextDirectoryManager.defaultOptions;
    ServerOperationQueue operationQueue = analysisServer.operationQueue;

    buffer.write('<h3>Analysis Domain</h3>');
    _writeTwoColumns(buffer, (StringBuffer buffer) {
      if (operationQueue.isEmpty) {
        buffer.write('<p>Status: Done analyzing</p>');
      } else {
        ServerOperation operation = operationQueue.peek();
        if (operation is PerformAnalysisOperation) {
          Folder folder = _keyForValue(folderMap, operation.context);
          if (folder == null) {
            buffer.write('<p>Status: Analyzing in unmapped context</p>');
          } else {
            buffer.write('<p>Status: Analyzing in ${folder.path}</p>');
          }
        } else {
          buffer.write('<p>Status: Analyzing</p>');
        }
      }

      buffer.write('<p><b>Analysis Contexts</b></p>');
      buffer.write('<p>');
      bool first = true;
      folders.forEach((Folder folder) {
        if (first) {
          first = false;
        } else {
          buffer.write('<br>');
        }
        String key = folder.shortName;
        buffer.write(_makeLink(CONTEXT_PATH, {
          CONTEXT_QUERY_PARAM: folder.path
        }, key, _hasException(folderMap[folder])));
      });
      buffer.write('</p>');

      buffer.write('<p><b>Options</b></p>');
      buffer.write('<p>');
      _writeOption(
          buffer,
          'Analyze functon bodies',
          options.analyzeFunctionBodies);
      _writeOption(buffer, 'Cache size', options.cacheSize);
      _writeOption(buffer, 'Generate hints', options.hint);
      _writeOption(buffer, 'Generate dart2js hints', options.dart2jsHint);
      _writeOption(buffer, 'Generate SDK errors', options.generateSdkErrors);
      _writeOption(buffer, 'Incremental resolution', options.incremental);
      _writeOption(
          buffer,
          'Incremental resolution with API changes',
          options.incrementalApi);
      _writeOption(
          buffer,
          'Preserve comments',
          options.preserveComments,
          last: true);
      buffer.write('</p>');
    }, (StringBuffer buffer) {
      _writeSubscriptionMap(
          buffer,
          AnalysisService.VALUES,
          analysisServer.analysisServices);
    });
  }

  /**
   * Append code completion information.
   */
  void _writeCompletionInfo(HttpResponse response, maxCount) {
    response.write('<h1>Code Completion</h1>');
    AnalysisServer analysisServer = _server.analysisServer;
    if (analysisServer == null) {
      response.write('<p>Not running</p>');
      return;
    }
    CompletionDomainHandler handler = analysisServer.handlers.firstWhere(
        (h) => h is CompletionDomainHandler,
        orElse: () => null);
    if (handler == null) {
      response.write('<p>No code completion</p>');
      return;
    }
    if (maxCount is String) {
      int count = int.parse(maxCount, onError: (_) => 0);
      handler.performanceListMaxLength = count;
    }
    CompletionPerformance performance = handler.performance;
    if (performance == null) {
      response.write('<p>No performance stats yet</p>');
      return;
    }
    response.write('<h2>Last Completion Performance</h2>');
    response.write('<table>');
    _writeRow(response, ['Elapsed', '', 'Operation'], header: true);
    performance.operations.forEach((OperationPerformance op) {
      String elapsed = op.elapsed != null ? op.elapsed.toString() : '???';
      _writeRow(response, [elapsed, '&nbsp;&nbsp;', op.name]);
    });
    if (handler.priorityChangedPerformance == null) {
      response.write('<p>No priorityChanged caching</p>');
    } else {
      int len = handler.priorityChangedPerformance.operations.length;
      if (len > 0) {
        var op = handler.priorityChangedPerformance.operations[len - 1];
        if (op != null) {
          _writeRow(response, ['&nbsp;', '&nbsp;', '&nbsp;']);
          String elapsed = op.elapsed != null ? op.elapsed.toString() : '???';
          _writeRow(response, [elapsed, '&nbsp;&nbsp;', op.name]);
        }
      }
    }
    response.write('</table>');
    if (handler.performanceList.length > 0) {
      response.write('<h2>Last Completion Summary</h2>');
      response.write('<table>');
      _writeRow(
          response,
          [
              'Start Time',
              '',
              'First (ms)',
              '',
              'Complete (ms)',
              '',
              '# Notifications',
              '',
              '# Suggestions',
              '',
              'Snippet'],
          header: true);
      handler.performanceList.forEach((CompletionPerformance performance) {
        _writeRow(
            response,
            [
                performance.start,
                '&nbsp;&nbsp;',
                performance.firstNotificationInMilliseconds,
                '&nbsp;&nbsp;',
                performance.elapsedInMilliseconds,
                '&nbsp;&nbsp;',
                performance.notificationCount,
                '&nbsp;&nbsp;',
                performance.suggestionCount,
                '&nbsp;&nbsp;',
                performance.snippet]);
      });
      response.write('</table>');
    }
  }

  /**
   * Generate a table showing the cache values corresponding to the given
   * [descriptors], using [getState] to get the cache state corresponding to
   * each descriptor, and [getValue] to get the cached value corresponding to
   * each descriptor.  Append the resulting HTML to the given [buffer]. The
   * [linkParameters] will be used if the value is too large to be displayed on
   * the current page and needs to be linked to a separate page.
   */
  void _writeDescriptorTable(StringBuffer buffer,
      List<DataDescriptor> descriptors, CacheState getState(DataDescriptor), dynamic
      getValue(DataDescriptor), Map<String, String> linkParameters) {
    buffer.write('<dl>');
    for (DataDescriptor descriptor in descriptors) {
      String descriptorName = HTML_ESCAPE.convert(descriptor.toString());
      String descriptorState =
          HTML_ESCAPE.convert(getState(descriptor).toString());
      buffer.write('<dt>$descriptorName ($descriptorState)</dt><dd>');
      try {
        _writeValueAsHtml(buffer, getValue(descriptor), linkParameters);
      } catch (exception) {
        buffer.write('(${HTML_ESCAPE.convert(exception.toString())})');
      }
      buffer.write('</dd>');
    }
    buffer.write('</dl>');
  }

  /**
   * Write the status of the edit domain (on the main status page) to the given
   * [buffer].
   */
  void _writeEditStatus(StringBuffer buffer) {
    buffer.write('<h3>Edit Domain</h3>');
    _writeTwoColumns(buffer, (StringBuffer buffer) {
      buffer.write('<p><b>Performance Data</b></p>');
      buffer.write('<p>');
      buffer.write(_makeLink(COMPLETION_PATH, {}, 'Completion data'));
      buffer.write('</p>');
    }, (StringBuffer buffer) {
    });
  }

  /**
   * Write a representation of the given [caughtException] to the given
   * [buffer]. If [isCause] is `true`, then the exception was a cause for
   * another exception.
   */
  void _writeException(StringBuffer buffer, CaughtException caughtException,
      {bool isCause: false}) {
    Object exception = caughtException.exception;

    if (exception is AnalysisException) {
      buffer.write('<p>');
      if (isCause) {
        buffer.write('Caused by ');
      }
      buffer.write(exception.message);
      buffer.write('</p>');
      _writeStackTrace(buffer, caughtException.stackTrace);
      CaughtException cause = exception.cause;
      if (cause != null) {
        buffer.write('<blockquote>');
        _writeException(buffer, cause, isCause: true);
        buffer.write('</blockquote>');
      }
    } else {
      buffer.write('<p>');
      if (isCause) {
        buffer.write('Caused by ');
      }
      buffer.write(exception.toString());
      buffer.write('<p>');
      _writeStackTrace(buffer, caughtException.stackTrace);
    }
  }

  /**
   * Write the status of the execution domain (on the main status page) to the
   * given [buffer].
   */
  void _writeExecutionStatus(StringBuffer buffer) {
    AnalysisServer analysisServer = _server.analysisServer;
    ExecutionDomainHandler handler = analysisServer.handlers.firstWhere(
        (RequestHandler handler) => handler is ExecutionDomainHandler,
        orElse: () => null);
    Set<ExecutionService> services = new Set<ExecutionService>();
    if (handler.onFileAnalyzed != null) {
      services.add(ExecutionService.LAUNCH_DATA);
    }

    if (handler != null) {
      buffer.write('<h3>Execution Domain</h3>');
      _writeTwoColumns(buffer, (StringBuffer buffer) {
        _writeSubscriptionList(buffer, ExecutionService.VALUES, services);
      }, (StringBuffer buffer) {
      });
    }
  }

  /**
   * Write a representation of an analysis option with the given [name] and
   * [value] to the given [buffer]. The option should be separated from other
   * options unless the [last] flag is true, indicating that this is the last
   * option in the list of options.
   */
  void _writeOption(StringBuffer buffer, String name, Object value, {bool last:
      false}) {
    buffer.write(name);
    buffer.write(' = ');
    buffer.write(value.toString());
    if (!last) {
      buffer.write('<br>');
    }
  }

  /**
   * Write a standard HTML page to the given [buffer]. The page will have the
   * given [title] and a body that is generated by the given [body] generator.
   */
  void _writePage(StringBuffer buffer, String title, List<String> subtitles,
      HtmlGenerator body) {
    DateTime now = new DateTime.now();
    String date = "${now.month}/${now.day}/${now.year}";
    String time =
        "${now.hour}:${_twoDigit(now.minute)}:${_twoDigit(now.second)}.${now.millisecond}";

    buffer.write('<!DOCTYPE html>');
    buffer.write('<html>');
    buffer.write('<head>');
    buffer.write('<meta charset="utf-8">');
    buffer.write(
        '<meta name="viewport" content="width=device-width, initial-scale=1.0">');
    buffer.write('<title>$title</title>');
    buffer.write('<style>');
    buffer.write('a {color: #0000DD; text-decoration: none;}');
    buffer.write('a:link.error {background-color: #FFEEEE;}');
    buffer.write('a:visited.error {background-color: #FFEEEE;}');
    buffer.write('a:hover.error {background-color: #FFEEEE;}');
    buffer.write('a:active.error {background-color: #FFEEEE;}');
    buffer.write(
        'h3 {background-color: #DDDDDD; margin-top: 0em; margin-bottom: 0em;}');
    buffer.write('p {margin-top: 0.5em; margin-bottom: 0.5em;}');
//    response.write('span.error {text-decoration-line: underline; text-decoration-color: red; text-decoration-style: wavy;}');
    buffer.write(
        'table.column {border: 0px solid black; width: 100%; table-layout: fixed;}');
    buffer.write('td.column {vertical-align: top; width: 50%;}');
    buffer.write('td.right {text-align: right;}');
    buffer.write('</style>');
    buffer.write('</head>');

    buffer.write('<body>');
    buffer.write(
        '<h2>$title <small><small>(as of $time on $date)</small></small></h2>');
    if (subtitles != null && subtitles.isNotEmpty) {
      buffer.write('<blockquote>');
      bool first = true;
      for (String subtitle in subtitles) {
        if (first) {
          first = false;
        } else {
          buffer.write('<br>');
        }
        buffer.write('<b>');
        buffer.write(subtitle);
        buffer.write('</b>');
      }
      buffer.write('</blockquote>');
    }
    try {
      body(buffer);
    } catch (exception, stackTrace) {
      buffer.write('<h3>Exception while creating page</h3>');
      _writeException(buffer, new CaughtException(exception, stackTrace));
    }
    buffer.write('</body>');
    buffer.write('</html>');
  }

  /**
   * Write the recent output section (on the main status page) to the given
   * [buffer] object.
   */
  void _writeRecentOutput(StringBuffer buffer) {
    buffer.write('<h3>Recent Output</h3>');
    String output = HTML_ESCAPE.convert(_printBuffer.join('\n'));
    if (output.isEmpty) {
      buffer.write('<i>none</i>');
    } else {
      buffer.write('<pre>');
      buffer.write(output);
      buffer.write('</pre>');
    }
  }

  void _writeResponse(HttpRequest request, HtmlGenerator writePage) {
    HttpResponse response = request.response;
    response.statusCode = HttpStatus.OK;
    response.headers.contentType = _htmlContent;
    try {
      StringBuffer buffer = new StringBuffer();
      try {
        writePage(buffer);
      } catch (exception, stackTrace) {
        buffer.clear();
        _writePage(buffer, 'Internal Exception', [], (StringBuffer buffer) {
          _writeException(buffer, new CaughtException(exception, stackTrace));
        });
      }
      response.write(buffer.toString());
    } finally {
      response.close();
    }
  }

  /**
   * Write a single row within a table to the given [response] object. The row
   * will have one cell for each of the [columns], and will be a header row if
   * [header] is `true`.
   */
  void _writeRow(HttpResponse response, List<Object> columns, {bool header:
      false, List<String> classes}) {
    response.write('<tr>');
    int count = columns.length;
    int maxClassIndex = classes == null ? 0 : classes.length - 1;
    for (int i = 0; i < count; i++) {
      String classAttribute = '';
      if (classes != null) {
        String className = classes[min(i, maxClassIndex)];
        if (className != null) {
          classAttribute = ' class="$className"';
        }
      }
      if (header) {
        response.write('<th$classAttribute>');
      } else {
        response.write('<td$classAttribute>');
      }
      response.write(columns[i]);
      if (header) {
        response.write('</th>');
      } else {
        response.write('</td>');
      }
    }

    response.write('</tr>');
  }

  /**
   * Write a single row within a table to the given [buffer]. The row will have
   * one cell for each of the [columns], and will be a header row if [header] is
   * `true`.
   */
  void _writeRow2(StringBuffer buffer, List<Object> columns, {bool header:
      false, List<String> classes}) {
    buffer.write('<tr>');
    int count = columns.length;
    int maxClassIndex = classes == null ? 0 : classes.length - 1;
    for (int i = 0; i < count; i++) {
      String classAttribute = '';
      if (classes != null) {
        String className = classes[min(i, maxClassIndex)];
        if (className != null) {
          classAttribute = ' class="$className"';
        }
      }
      if (header) {
        buffer.write('<th$classAttribute>');
      } else {
        buffer.write('<td$classAttribute>');
      }
      buffer.write(columns[i]);
      if (header) {
        buffer.write('</th>');
      } else {
        buffer.write('</td>');
      }
    }
    buffer.write('</tr>');
  }

  /**
   * Write the status of the service domain (on the main status page) to the
   * given [response] object.
   */
  bool _writeServerStatus(StringBuffer buffer) {
    AnalysisServer analysisServer = _server.analysisServer;
    Set<ServerService> services = analysisServer.serverServices;

    buffer.write('<h3>Server Domain</h3>');
    _writeTwoColumns(buffer, (StringBuffer buffer) {
      if (analysisServer == null) {
        buffer.write('Status: <span style="color:red">Not running</span>');
        return false;
      }
      buffer.write('<p>');
      buffer.write('Status: Running<br>');
      buffer.write('Instrumentation: ');
      if (AnalysisEngine.instance.instrumentationService.isActive) {
        buffer.write('<span style="color:red">Active</span>');
      } else {
        buffer.write('Inactive');
      }
      buffer.write('<br>');
      buffer.write('Version: ');
      buffer.write(AnalysisServer.VERSION);
      buffer.write('</p>');
    }, (StringBuffer buffer) {
      _writeSubscriptionList(buffer, ServerService.VALUES, services);
    });
    return true;
  }

  /**
   * Write a representation of the given [stackTrace] to the given [buffer].
   */
  void _writeStackTrace(StringBuffer buffer, StackTrace stackTrace) {
    if (stackTrace != null) {
      String trace = stackTrace.toString().replaceAll('#', '<br>#');
      if (trace.startsWith('<br>#')) {
        trace = trace.substring(4);
      }
      buffer.write('<p>');
      buffer.write(trace);
      buffer.write('</p>');
    }
  }

  /**
   * Given a [service] that could be subscribed to and a set of the services
   * that are actually subscribed to ([subscribedServices]), write a
   * representation of the service to the given [buffer].
   */
  void _writeSubscriptionInList(StringBuffer buffer, Enum service,
      Set<Enum> subscribedServices) {
    if (subscribedServices.contains(service)) {
      buffer.write('<code>+ </code>');
    } else {
      buffer.write('<code>- </code>');
    }
    buffer.write(service.name);
    buffer.write('<br>');
  }

  /**
   * Given a [service] that could be subscribed to and a set of paths that are
   * subscribed to the services ([subscribedPaths]), write a representation of
   * the service to the given [buffer].
   */
  void _writeSubscriptionInMap(StringBuffer buffer, Enum service,
      Set<String> subscribedPaths) {
    buffer.write('<p>');
    buffer.write(service.name);
    buffer.write('</p>');
    if (subscribedPaths == null || subscribedPaths.isEmpty) {
      buffer.write('none');
    } else {
      List<String> paths = subscribedPaths.toList();
      paths.sort();
      for (String path in paths) {
        buffer.write('<p>');
        buffer.write(path);
        buffer.write('</p>');
      }
    }
  }

  /**
   * Given a list containing all of the services that can be subscribed to in a
   * single domain ([allServices]) and a set of the services that are actually
   * subscribed to ([subscribedServices]), write a representation of the
   * subscriptions to the given [buffer].
   */
  void _writeSubscriptionList(StringBuffer buffer, List<Enum> allServices,
      Set<Enum> subscribedServices) {
    buffer.write('<p><b>Subscriptions</b></p>');
    buffer.write('<p>');
    for (Enum service in allServices) {
      _writeSubscriptionInList(buffer, service, subscribedServices);
    }
    buffer.write('</p>');
  }

  /**
   * Given a list containing all of the services that can be subscribed to in a
   * single domain ([allServices]) and a set of the services that are actually
   * subscribed to ([subscribedServices]), write a representation of the
   * subscriptions to the given [buffer].
   */
  void _writeSubscriptionMap(StringBuffer buffer, List<Enum> allServices,
      Map<Enum, Set<String>> subscribedServices) {
    buffer.write('<p><b>Subscriptions</b></p>');
    for (Enum service in allServices) {
      _writeSubscriptionInMap(buffer, service, subscribedServices[service]);
    }
  }

  /**
   * Write two columns of information to the given [buffer], where the
   * [leftColumn] and [rightColumn] functions are used to generate the content
   * of those columns.
   */
  void _writeTwoColumns(StringBuffer buffer, HtmlGenerator leftColumn,
      HtmlGenerator rightColumn) {
    buffer.write(
        '<table class="column"><tr class="column"><td class="column">');
    leftColumn(buffer);
    buffer.write('</td><td class="column">');
    rightColumn(buffer);
    buffer.write('</td></tr></table>');
  }

  /**
   * Render the given [value] as HTML and append it to the given [buffer]. The
   * [linkParameters] will be used if the value is too large to be displayed on
   * the current page and needs to be linked to a separate page.
   */
  void _writeValueAsHtml(StringBuffer buffer, Object value, Map<String,
      String> linkParameters) {
    if (value == null) {
      buffer.write('<i>null</i>');
    } else if (value is String) {
      buffer.write('<pre>${HTML_ESCAPE.convert(value)}</pre>');
    } else if (value is List) {
      buffer.write('List containing ${value.length} entries');
      buffer.write('<ul>');
      for (var entry in value) {
        buffer.write('<li>');
        _writeValueAsHtml(buffer, entry, linkParameters);
        buffer.write('</li>');
      }
      buffer.write('</ul>');
    } else if (value is AstNode) {
      String link =
          _makeLink(AST_PATH, linkParameters, value.runtimeType.toString());
      buffer.write('<i>$link</i>');
    } else if (value is Element) {
      String link =
          _makeLink(ELEMENT_PATH, linkParameters, value.runtimeType.toString());
      buffer.write('<i>$link</i>');
    } else {
      buffer.write(HTML_ESCAPE.convert(value.toString()));
      buffer.write(' <i>(${value.runtimeType.toString()})</i>');
    }
  }
}
