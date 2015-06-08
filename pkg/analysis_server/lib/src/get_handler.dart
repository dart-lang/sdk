// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analysis_server.src.get_handler;

import 'dart:async';
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
import 'package:analysis_server/src/services/index/index.dart';
import 'package:analysis_server/src/services/index/local_index.dart';
import 'package:analysis_server/src/services/index/store/split_store.dart';
import 'package:analysis_server/src/socket_server.dart';
import 'package:analysis_server/src/status/ast_writer.dart';
import 'package:analysis_server/src/status/element_writer.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_general.dart';
import 'package:analyzer/task/model.dart' as newTask;
import 'package:plugin/plugin.dart';

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
   * The path used to request overall performance information.
   */
  static const String ANALYSIS_PERFORMANCE_PATH = '/perf/analysis';

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
   * The path used to request the list of source files in a certain cache
   * state.
   */
  static const String CACHE_STATE_PATH = '/cache_state';

  /**
   * The path used to request code completion information.
   */
  static const String COMPLETION_PATH = '/completion';

  /**
   * The path used to request communication performance information.
   */
  static const String COMMUNICATION_PERFORMANCE_PATH = '/perf/communication';

  /**
   * The path used to request information about a specific context.
   */
  static const String CONTEXT_PATH = '/context';

  /**
   * The path used to request information about a element model.
   */
  static const String ELEMENT_PATH = '/element';

  /**
   * The path used to request information about elements with the given name.
   */
  static const String INDEX_ELEMENT_BY_NAME = '/index/element-by-name';

  /**
   * The path used to request an overlay contents.
   */
  static const String OVERLAY_PATH = '/overlay';

  /**
   * The path used to request overlays information.
   */
  static const String OVERLAYS_PATH = '/overlays';

  /**
   * The path used to request the status of the analysis server as a whole.
   */
  static const String STATUS_PATH = '/status';

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
   * Query parameter used to represent the name of elements to search for, when
   * accessing [INDEX_ELEMENT_BY_NAME].
   */
  static const String INDEX_ELEMENT_NAME = 'name';

  /**
   * Query parameter used to represent the path of an overlayed file.
   */
  static const String PATH_PARAM = 'path';

  /**
   * Query parameter used to represent the source to search for, when accessing
   * [CACHE_ENTRY_PATH].
   */
  static const String SOURCE_QUERY_PARAM = 'entry';

  /**
   * Query parameter used to represent the cache state to search for, when
   * accessing [CACHE_STATE_PATH].
   */
  static const String STATE_QUERY_PARAM = 'state';

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
  final Map<String, String> _overlayContents = <String, String>{};

  /**
   * Initialize a newly created handler for GET requests.
   */
  GetHandler(this._server, this._printBuffer);

  /**
   * Return the active [CompletionDomainHandler]
   * or `null` if either analysis server is not running
   * or there is no completion domain handler.
   */
  CompletionDomainHandler get _completionDomainHandler {
    AnalysisServer analysisServer = _server.analysisServer;
    if (analysisServer == null) {
      return null;
    }
    return analysisServer.handlers.firstWhere(
        (h) => h is CompletionDomainHandler, orElse: () => null);
  }

  /**
   * Handle a GET request received by the HTTP server.
   */
  void handleGetRequest(HttpRequest request) {
    String path = request.uri.path;
    if (path == STATUS_PATH) {
      _returnServerStatus(request);
    } else if (path == ANALYSIS_PERFORMANCE_PATH) {
      _returnAnalysisPerformance(request);
    } else if (path == AST_PATH) {
      _returnAst(request);
    } else if (path == CACHE_STATE_PATH) {
      _returnCacheState(request);
    } else if (path == CACHE_ENTRY_PATH) {
      _returnCacheEntry(request);
    } else if (path == COMPLETION_PATH) {
      _returnCompletionInfo(request);
    } else if (path == COMMUNICATION_PERFORMANCE_PATH) {
      _returnCommunicationPerformance(request);
    } else if (path == CONTEXT_PATH) {
      _returnContextInfo(request);
    } else if (path == ELEMENT_PATH) {
      _returnElement(request);
    } else if (path == INDEX_ELEMENT_BY_NAME) {
      _returnIndexElementByName(request);
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
        (Folder folder) => folder.path == contextFilter, orElse: () => null);
  }

  /**
   * Return `true` if the given analysis [context] has at least one entry with
   * an exception.
   */
  bool _hasException(AnalysisContextImpl context) {
    bool hasException = false;
    context.visitCacheItems((Source source, SourceEntry sourceEntry,
        DataDescriptor rowDesc, CacheState state) {
      if (sourceEntry.exception != null) {
        hasException = true;
      }
    });
    return hasException;
  }

  /**
   * Return the folder in the [folderMap] with which the given [context] is
   * associated.
   */
  Folder _keyForValue(
      Map<Folder, AnalysisContext> folderMap, AnalysisContext context) {
    for (Folder folder in folderMap.keys) {
      if (folderMap[folder] == context) {
        return folder;
      }
    }
    return null;
  }

  /**
   * Return a response displaying overall performance information.
   */
  void _returnAnalysisPerformance(HttpRequest request) {
    AnalysisServer analysisServer = _server.analysisServer;
    if (analysisServer == null) {
      return _returnFailure(request, 'Analysis server is not running');
    }
    _writeResponse(request, (StringBuffer buffer) {
      _writePage(buffer, 'Analysis Server - Analysis Performance', [],
          (StringBuffer buffer) {
        buffer.write('<h3>Analysis Performance</h3>');

        //
        // Write performance tags.
        //
        {
          buffer.write('<p><b>Time spent in each phase of analysis</b></p>');
          buffer.write(
              '<table style="border-collapse: separate; border-spacing: 10px 5px;">');
          _writeRow(buffer, ['Time (in ms)', 'Percent', 'Analysis Phase'],
              header: true);
          // prepare sorted tags
          List<PerformanceTag> tags = PerformanceTag.all.toList();
          tags.remove(ServerPerformanceStatistics.idle);
          tags.sort((a, b) => b.elapsedMs - a.elapsedMs);
          // prepare total time
          int totalTime = 0;
          tags.forEach((PerformanceTag tag) {
            totalTime += tag.elapsedMs;
          });
          // write rows
          void writeRow(PerformanceTag tag) {
            double percent = (tag.elapsedMs * 100) / totalTime;
            String percentStr = '${percent.toStringAsFixed(2)}%';
            _writeRow(buffer, [tag.elapsedMs, percentStr, tag.label],
                classes: ["right", "right", null]);
          }
          tags.forEach(writeRow);
          buffer.write('</table>');
        }

        //
        // Write new task model timing information.
        //
        if (AnalysisEngine.instance.useTaskModel) {
          buffer.write('<p><b>Task performace data</b></p>');
          buffer.write(
              '<table style="border-collapse: separate; border-spacing: 10px 5px;">');
          _writeRow(buffer, [
            'Task Name',
            'Count',
            'Total Time (in ms)',
            'Average Time (in ms)'
          ], header: true);

          Map<Type, int> countMap = newTask.AnalysisTask.countMap;
          Map<Type, Stopwatch> stopwatchMap = newTask.AnalysisTask.stopwatchMap;
          List<Type> taskClasses = stopwatchMap.keys.toList();
          taskClasses.sort((Type first, Type second) =>
              first.toString().compareTo(second.toString()));
          int totalTime = 0;
          taskClasses.forEach((Type taskClass) {
            int count = countMap[taskClass];
            if (count == null) {
              count = 0;
            }
            int taskTime = stopwatchMap[taskClass].elapsedMilliseconds;
            totalTime += taskTime;
            _writeRow(buffer, [
              taskClass.toString(),
              count,
              taskTime,
              count <= 0 ? '-' : (taskTime / count).toStringAsFixed(3)
            ], classes: [null, "right", "right", "right"]);
          });
          _writeRow(buffer, ['Total', '-', totalTime, '-'],
              classes: [null, "right", "right", "right"]);
          buffer.write('</table>');
        }

        //
        // Write old task model transition information.
        //
        {
          Map<DataDescriptor, Map<CacheState, int>> transitionMap =
              SourceEntry.transitionMap;
          buffer.write(
              '<p><b>Number of times a state transitioned to VALID (grouped by descriptor)</b></p>');
          if (transitionMap.isEmpty) {
            buffer.write('<p>none</p>');
          } else {
            List<DataDescriptor> descriptors = transitionMap.keys.toList();
            descriptors.sort((DataDescriptor first, DataDescriptor second) =>
                first.toString().compareTo(second.toString()));
            for (DataDescriptor key in descriptors) {
              Map<CacheState, int> countMap = transitionMap[key];
              List<CacheState> oldStates = countMap.keys.toList();
              oldStates.sort((CacheState first, CacheState second) =>
                  first.toString().compareTo(second.toString()));
              buffer.write('<p>${key.toString()}</p>');
              buffer.write(
                  '<table style="border-collapse: separate; border-spacing: 10px 5px;">');
              _writeRow(buffer, ['Count', 'Previous State'], header: true);
              for (CacheState state in oldStates) {
                _writeRow(buffer, [countMap[state], state.toString()],
                    classes: ["right", null]);
              }
              buffer.write('</table>');
            }
          }
        }
      });
    });
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
          request, 'Query parameter $CONTEXT_QUERY_PARAM required');
    }
    Folder folder = _findFolder(analysisServer, contextFilter);
    if (folder == null) {
      return _returnFailure(request, 'Invalid context: $contextFilter');
    }
    String sourceUri = request.uri.queryParameters[SOURCE_QUERY_PARAM];
    if (sourceUri == null) {
      return _returnFailure(
          request, 'Query parameter $SOURCE_QUERY_PARAM required');
    }

    AnalysisContextImpl context = analysisServer.folderMap[folder];

    _writeResponse(request, (StringBuffer buffer) {
      _writePage(buffer, 'Analysis Server - AST Structure', [
        'Context: $contextFilter',
        'File: $sourceUri'
      ], (HttpResponse) {
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
        AstWriter writer = new AstWriter(buffer);
        ast.accept(writer);
        if (writer.exceptions.isNotEmpty) {
          buffer.write('<h3>Exceptions while creating page</h3>');
          for (CaughtException exception in writer.exceptions) {
            _writeException(buffer, exception);
          }
        }
      });
    });
  }

  /**
   * Return a response containing information about a single source file in the
   * cache.
   */
  void _returnCacheEntry(HttpRequest request) {
    AnalysisServer analysisServer = _server.analysisServer;
    if (analysisServer == null) {
      return _returnFailure(request, 'Analysis server not running');
    }
    String contextFilter = request.uri.queryParameters[CONTEXT_QUERY_PARAM];
    if (contextFilter == null) {
      return _returnFailure(
          request, 'Query parameter $CONTEXT_QUERY_PARAM required');
    }
    Folder folder = _findFolder(analysisServer, contextFilter);
    if (folder == null) {
      return _returnFailure(request, 'Invalid context: $contextFilter');
    }
    String sourceUri = request.uri.queryParameters[SOURCE_QUERY_PARAM];
    if (sourceUri == null) {
      return _returnFailure(
          request, 'Query parameter $SOURCE_QUERY_PARAM required');
    }

    List<Folder> allContexts = <Folder>[];
    Map<Folder, SourceEntry> entryMap = new HashMap<Folder, SourceEntry>();
    analysisServer.folderMap
        .forEach((Folder folder, AnalysisContextImpl context) {
      Source source = context.sourceFactory.forUri(sourceUri);
      if (source != null) {
        SourceEntry entry = context.getReadableSourceEntryOrNull(source);
        if (entry != null) {
          allContexts.add(folder);
          entryMap[folder] = entry;
        }
      }
    });
    allContexts.sort((Folder firstFolder, Folder secondFolder) =>
        firstFolder.path.compareTo(secondFolder.path));
    AnalysisContextImpl context = analysisServer.folderMap[folder];

    _writeResponse(request, (StringBuffer buffer) {
      _writePage(buffer, 'Analysis Server - Cache Entry', [
        'Context: $contextFilter',
        'File: $sourceUri'
      ], (HttpResponse) {
        buffer.write('<h3>Analyzing Contexts</h3><p>');
        bool first = true;
        allContexts.forEach((Folder folder) {
          if (first) {
            first = false;
          } else {
            buffer.write('<br>');
          }
          AnalysisContextImpl analyzingContext =
              analysisServer.folderMap[folder];
          if (analyzingContext == context) {
            buffer.write(folder.path);
          } else {
            buffer.write(makeLink(CACHE_ENTRY_PATH, {
              CONTEXT_QUERY_PARAM: folder.path,
              SOURCE_QUERY_PARAM: sourceUri
            }, HTML_ESCAPE.convert(folder.path)));
          }
          if (entryMap[folder].explicitlyAdded) {
            buffer.write(' (explicit)');
          } else {
            buffer.write(' (implicit)');
          }
        });
        buffer.write('</p>');

        SourceEntry entry = entryMap[folder];
        if (entry == null) {
          buffer.write('<p>Not being analyzed in this context.</p>');
          return;
        }
        Map<String, String> linkParameters = <String, String>{
          CONTEXT_QUERY_PARAM: folder.path,
          SOURCE_QUERY_PARAM: sourceUri
        };

        buffer.write('<h3>Library Independent</h3>');
        _writeDescriptorTable(buffer, entry.descriptors, entry.getState,
            entry.getValue, linkParameters);
        if (entry is DartEntry) {
          for (Source librarySource in entry.containingLibraries) {
            String libraryName = HTML_ESCAPE.convert(librarySource.fullName);
            buffer.write('<h3>In library $libraryName:</h3>');
            _writeDescriptorTable(buffer, entry.libraryDescriptors,
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
    AnalysisServer analysisServer = _server.analysisServer;
    if (analysisServer == null) {
      return _returnFailure(request, 'Analysis server not running');
    }
    // Figure out which context is being searched within.
    String contextFilter = request.uri.queryParameters[CONTEXT_QUERY_PARAM];
    if (contextFilter == null) {
      return _returnFailure(
          request, 'Query parameter $CONTEXT_QUERY_PARAM required');
    }
    // Figure out what CacheState is being searched for.
    String stateQueryParam = request.uri.queryParameters[STATE_QUERY_PARAM];
    if (stateQueryParam == null) {
      return _returnFailure(
          request, 'Query parameter $STATE_QUERY_PARAM required');
    }
    CacheState stateFilter = null;
    for (CacheState value in CacheState.values) {
      if (value.toString() == stateQueryParam) {
        stateFilter = value;
      }
    }
    if (stateFilter == null) {
      return _returnFailure(
          request, 'Query parameter $STATE_QUERY_PARAM is invalid');
    }
    // Figure out which descriptor is being searched for.
    String descriptorFilter =
        request.uri.queryParameters[DESCRIPTOR_QUERY_PARAM];
    if (descriptorFilter == null) {
      return _returnFailure(
          request, 'Query parameter $DESCRIPTOR_QUERY_PARAM required');
    }

    Folder folder = _findFolder(analysisServer, contextFilter);
    AnalysisContextImpl context = analysisServer.folderMap[folder];
    List<String> links = <String>[];
    context.visitCacheItems((Source source, SourceEntry dartEntry,
        DataDescriptor rowDesc, CacheState state) {
      if (state != stateFilter || rowDesc.toString() != descriptorFilter) {
        return;
      }
      String link = makeLink(CACHE_ENTRY_PATH, {
        CONTEXT_QUERY_PARAM: folder.path,
        SOURCE_QUERY_PARAM: source.uri.toString()
      }, HTML_ESCAPE.convert(source.fullName));
      links.add(link);
    });

    _writeResponse(request, (StringBuffer buffer) {
      _writePage(buffer, 'Analysis Server - Cache Search', [
        'Context: $contextFilter',
        'Descriptor: ${HTML_ESCAPE.convert(descriptorFilter)}',
        'State: ${HTML_ESCAPE.convert(stateQueryParam)}'
      ], (StringBuffer buffer) {
        buffer.write('<p>${links.length} files found</p>');
        buffer.write('<ul>');
        links.forEach((String link) {
          buffer.write('<li>$link</li>');
        });
        buffer.write('</ul>');
      });
    });
  }

  /**
   * Return a response displaying overall performance information.
   */
  void _returnCommunicationPerformance(HttpRequest request) {
    AnalysisServer analysisServer = _server.analysisServer;
    if (analysisServer == null) {
      return _returnFailure(request, 'Analysis server is not running');
    }
    _writeResponse(request, (StringBuffer buffer) {
      _writePage(buffer, 'Analysis Server - Communication Performance', [],
          (StringBuffer buffer) {
        buffer.write('<h3>Communication Performance</h3>');
        _writeTwoColumns(buffer, (StringBuffer buffer) {
          ServerPerformance perf = analysisServer.performanceDuringStartup;
          int requestCount = perf.requestCount;
          num averageLatency = requestCount > 0
              ? (perf.requestLatency / requestCount).round()
              : 0;
          int maximumLatency = perf.maxLatency;
          num slowRequestPercent = requestCount > 0
              ? (perf.slowRequestCount * 100 / requestCount).round()
              : 0;
          buffer.write('<h4>Startup</h4>');
          buffer.write('<table>');
          _writeRow(buffer, [requestCount, 'requests'],
              classes: ["right", null]);
          _writeRow(buffer, [averageLatency, 'ms average latency'],
              classes: ["right", null]);
          _writeRow(buffer, [maximumLatency, 'ms maximum latency'],
              classes: ["right", null]);
          _writeRow(buffer, [slowRequestPercent, '% > 150 ms latency'],
              classes: ["right", null]);
          if (analysisServer.performanceAfterStartup != null) {
            int startupTime = analysisServer.performanceAfterStartup.startTime -
                perf.startTime;
            _writeRow(
                buffer, [startupTime, 'ms for initial analysis to complete']);
          }
          buffer.write('</table>');
        }, (StringBuffer buffer) {
          ServerPerformance perf = analysisServer.performanceAfterStartup;
          if (perf == null) {
            return;
          }
          int requestCount = perf.requestCount;
          num averageLatency = requestCount > 0
              ? (perf.requestLatency * 10 / requestCount).round() / 10
              : 0;
          int maximumLatency = perf.maxLatency;
          num slowRequestPercent = requestCount > 0
              ? (perf.slowRequestCount * 100 / requestCount).round()
              : 0;
          buffer.write('<h4>Current</h4>');
          buffer.write('<table>');
          _writeRow(buffer, [requestCount, 'requests'],
              classes: ["right", null]);
          _writeRow(buffer, [averageLatency, 'ms average latency'],
              classes: ["right", null]);
          _writeRow(buffer, [maximumLatency, 'ms maximum latency'],
              classes: ["right", null]);
          _writeRow(buffer, [slowRequestPercent, '% > 150 ms latency'],
              classes: ["right", null]);
          buffer.write('</table>');
        });
      });
    });
  }

  /**
   * Return a response displaying code completion information.
   */
  void _returnCompletionInfo(HttpRequest request) {
    String value = request.requestedUri.queryParameters['index'];
    int index = value != null ? int.parse(value, onError: (_) => 0) : 0;
    _writeResponse(request, (StringBuffer buffer) {
      _writePage(buffer, 'Analysis Server - Completion Stats', [],
          (StringBuffer buffer) {
        _writeCompletionPerformanceDetail(buffer, index);
        _writeCompletionPerformanceList(buffer);
      });
    });
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
          request, 'Query parameter $CONTEXT_QUERY_PARAM required');
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
    AnalysisContextImpl context = analysisServer.folderMap[folder];
    priorityNames = context.prioritySources
        .map((Source source) => source.fullName)
        .toList();
    context.visitCacheItems((Source source, SourceEntry sourceEntry,
        DataDescriptor rowDesc, CacheState state) {
      String sourceName = source.fullName;
      if (!links.containsKey(sourceName)) {
        CaughtException exception = sourceEntry.exception;
        if (exception != null) {
          exceptions.add(exception);
        }
        String link = makeLink(CACHE_ENTRY_PATH, {
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
    explicitNames.sort();
    implicitNames.sort();

    _overlayContents.clear();
    context.visitContentCache((String fullName, int stamp, String contents) {
      _overlayContents[fullName] = contents;
    });

    void _writeFiles(
        StringBuffer buffer, String title, List<String> fileNames) {
      buffer.write('<h3>$title</h3>');
      if (fileNames == null || fileNames.isEmpty) {
        buffer.write('<p>None</p>');
      } else {
        buffer.write('<table style="width: 100%">');
        for (String fileName in fileNames) {
          buffer.write('<tr><td>');
          buffer.write(links[fileName]);
          buffer.write('</td><td>');
          if (_overlayContents.containsKey(fileName)) {
            buffer.write(
                makeLink(OVERLAY_PATH, {PATH_PARAM: fileName}, 'overlay'));
          }
          buffer.write('</td></tr>');
        }
        buffer.write('</table>');
      }
    }

    _writeResponse(request, (StringBuffer buffer) {
      _writePage(buffer, 'Analysis Server - Context',
          ['Context: $contextFilter'], (StringBuffer buffer) {
        List headerRowText = ['Context'];
        headerRowText.addAll(CacheState.values);
        buffer.write('<h3>Summary</h3>');
        buffer.write('<table>');
        _writeRow(buffer, headerRowText, header: true);
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
            rowText.add(makeLink(CACHE_STATE_PATH, params, text));
          }
          _writeRow(buffer, rowText, classes: [null, "right"]);
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
          request, 'Query parameter $CONTEXT_QUERY_PARAM required');
    }
    Folder folder = _findFolder(analysisServer, contextFilter);
    if (folder == null) {
      return _returnFailure(request, 'Invalid context: $contextFilter');
    }
    String sourceUri = request.uri.queryParameters[SOURCE_QUERY_PARAM];
    if (sourceUri == null) {
      return _returnFailure(
          request, 'Query parameter $SOURCE_QUERY_PARAM required');
    }

    AnalysisContextImpl context = analysisServer.folderMap[folder];

    _writeResponse(request, (StringBuffer buffer) {
      _writePage(buffer, 'Analysis Server - Element Model', [
        'Context: $contextFilter',
        'File: $sourceUri'
      ], (StringBuffer buffer) {
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
    _writeResponse(request, (StringBuffer buffer) {
      _writePage(buffer, 'Analysis Server - Failure', [],
          (StringBuffer buffer) {
        buffer.write(HTML_ESCAPE.convert(message));
      });
    });
  }

  /**
   * Return a response containing information about elements with the given
   * name.
   */
  Future _returnIndexElementByName(HttpRequest request) async {
    AnalysisServer analysisServer = _server.analysisServer;
    if (analysisServer == null) {
      return _returnFailure(request, 'Analysis server not running');
    }
    Index index = analysisServer.index;
    if (index == null) {
      return _returnFailure(request, 'Indexing is disabled');
    }
    String name = request.uri.queryParameters[INDEX_ELEMENT_NAME];
    if (name == null) {
      return _returnFailure(
          request, 'Query parameter $INDEX_ELEMENT_NAME required');
    }
    if (index is LocalIndex) {
      Map<List<String>, List<InspectLocation>> relations =
          await index.findElementsByName(name);
      _writeResponse(request, (StringBuffer buffer) {
        _writePage(buffer, 'Analysis Server - Index Elements', ['Name: $name'],
            (StringBuffer buffer) {
          buffer.write('<table border="1">');
          _writeRow(buffer, ['Element', 'Relationship', 'Location'],
              header: true);
          relations.forEach((List<String> elementPath,
              List<InspectLocation> relations) {
            String elementLocation = elementPath.join(' ');
            relations.forEach((InspectLocation location) {
              var relString = location.relationship.identifier;
              var locString = '${location.path} offset=${location.offset} '
                  'length=${location.length} flags=${location.flags}';
              _writeRow(buffer, [elementLocation, relString, locString]);
            });
          });
          buffer.write('</table>');
        });
      });
    } else {
      return _returnFailure(request, 'LocalIndex expected, but $index found.');
    }
  }

  void _returnOverlayContents(HttpRequest request) {
    String path = request.requestedUri.queryParameters[PATH_PARAM];
    if (path == null) {
      return _returnFailure(request, 'Query parameter $PATH_PARAM required');
    }
    String contents = _overlayContents[path];

    _writeResponse(request, (StringBuffer buffer) {
      _writePage(buffer, 'Analysis Server - Overlay', [],
          (StringBuffer buffer) {
        buffer.write('<pre>${HTML_ESCAPE.convert(contents)}</pre>');
      });
    });
  }

  /**
   * Return a response displaying overlays information.
   */
  void _returnOverlaysInfo(HttpRequest request) {
    AnalysisServer analysisServer = _server.analysisServer;
    if (analysisServer == null) {
      return _returnFailure(request, 'Analysis server is not running');
    }

    _writeResponse(request, (StringBuffer buffer) {
      _writePage(buffer, 'Analysis Server - Overlays', [],
          (StringBuffer buffer) {
        buffer.write('<table border="1">');
        _overlayContents.clear();
        ContentCache overlayState = analysisServer.overlayState;
        overlayState.accept((String fullName, int stamp, String contents) {
          buffer.write('<tr>');
          String link =
              makeLink(OVERLAY_PATH, {PATH_PARAM: fullName}, fullName);
          DateTime time = new DateTime.fromMillisecondsSinceEpoch(stamp);
          _writeRow(buffer, [link, time]);
          _overlayContents[fullName] = contents;
        });
        int count = _overlayContents.length;
        buffer.write('<tr><td colspan="2">Total: $count entries.</td></tr>');
        buffer.write('</table>');
      });
    });
  }

  /**
   * Return a response indicating the status of the analysis server.
   */
  void _returnServerStatus(HttpRequest request) {
    _writeResponse(request, (StringBuffer buffer) {
      _writePage(buffer, 'Analysis Server - Status', [], (StringBuffer buffer) {
        if (_writeServerStatus(buffer)) {
          _writeAnalysisStatus(buffer);
          _writeEditStatus(buffer);
          _writeExecutionStatus(buffer);
          _writePluginStatus(buffer);
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
    _writeResponse(request, (StringBuffer buffer) {
      _writePage(buffer, 'Analysis Server', [], (StringBuffer buffer) {
        buffer.write('<h3>Pages</h3>');
        buffer.write('<p>');
        buffer.write(makeLink(COMPLETION_PATH, {}, 'Completion data'));
        buffer.write('</p>');
        buffer.write('<p>');
        buffer
            .write(makeLink(COMMUNICATION_PERFORMANCE_PATH, {}, 'Performance'));
        buffer.write('</p>');
        buffer.write('<p>');
        buffer.write(makeLink(STATUS_PATH, {}, 'Server status'));
        buffer.write('</p>');
        buffer.write('<p>');
        buffer.write(makeLink(OVERLAYS_PATH, {}, 'File overlays'));
        buffer.write('</p>');
      });
    });
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
    folders.sort((Folder first, Folder second) =>
        first.shortName.compareTo(second.shortName));
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
        buffer.write(makeLink(CONTEXT_PATH, {
          CONTEXT_QUERY_PARAM: folder.path
        }, key, _hasException(folderMap[folder])));
      });
      buffer.write('</p>');

      buffer.write('<p><b>Options</b></p>');
      buffer.write('<p>');
      _writeOption(
          buffer, 'Analyze functon bodies', options.analyzeFunctionBodies);
      _writeOption(buffer, 'Cache size', options.cacheSize);
      _writeOption(buffer, 'Enable null-aware operators',
          options.enableNullAwareOperators);
      _writeOption(
          buffer, 'Enable strict call checks', options.enableStrictCallChecks);
      _writeOption(buffer, 'Generate hints', options.hint);
      _writeOption(buffer, 'Generate dart2js hints', options.dart2jsHint);
      _writeOption(buffer, 'Generate errors in implicit files',
          options.generateImplicitErrors);
      _writeOption(
          buffer, 'Generate errors in SDK files', options.generateSdkErrors);
      _writeOption(buffer, 'Incremental resolution', options.incremental);
      _writeOption(buffer, 'Incremental resolution with API changes',
          options.incrementalApi);
      _writeOption(buffer, 'Preserve comments', options.preserveComments,
          last: true);
      buffer.write('</p>');
      int freq = AnalysisServer.performOperationDelayFreqency;
      String delay = freq > 0 ? '1 ms every $freq ms' : 'off';
      buffer.write('<p><b>perform operation delay:</b> $delay</p>');

      buffer.write('<p><b>Performance Data</b></p>');
      buffer.write('<p>');
      buffer.write(makeLink(ANALYSIS_PERFORMANCE_PATH, {}, 'Task data'));
      buffer.write('</p>');
    }, (StringBuffer buffer) {
      _writeSubscriptionMap(
          buffer, AnalysisService.VALUES, analysisServer.analysisServices);
    });
  }

  /**
   * Write performance information about a specific completion request
   * to the given [buffer] object.
   */
  void _writeCompletionPerformanceDetail(StringBuffer buffer, int index) {
    CompletionDomainHandler handler = _completionDomainHandler;
    CompletionPerformance performance;
    if (handler != null) {
      List<CompletionPerformance> list = handler.performanceList;
      if (list != null && list.isNotEmpty) {
        performance = list[max(0, min(list.length - 1, index))];
      }
    }
    if (performance == null) {
      buffer.write('<h3>Completion Performance Detail</h3>');
      buffer.write('<p>No completions yet</p>');
      return;
    }
    buffer.write('<h3>Completion Performance Detail</h3>');
    buffer.write('<p>${performance.startTimeAndMs} for ${performance.source}');
    buffer.write('<table>');
    _writeRow(buffer, ['Elapsed', '', 'Operation'], header: true);
    performance.operations.forEach((OperationPerformance op) {
      String elapsed = op.elapsed != null ? op.elapsed.toString() : '???';
      _writeRow(buffer, [elapsed, '&nbsp;&nbsp;', op.name]);
    });
    buffer.write('</table>');
    buffer.write('<p><b>Compute Cache Performance</b>: ');
    if (handler.computeCachePerformance == null) {
      buffer.write('none');
    } else {
      int elapsed = handler.computeCachePerformance.elapsedInMilliseconds;
      Source source = handler.computeCachePerformance.source;
      buffer.write(' $elapsed ms for $source');
    }
    buffer.write('</p>');
  }

  /**
   * Write a table showing summary information for the last several
   * completion requests to the given [buffer] object.
   */
  void _writeCompletionPerformanceList(StringBuffer buffer) {
    CompletionDomainHandler handler = _completionDomainHandler;
    buffer.write('<h3>Completion Performance List</h3>');
    if (handler == null) {
      return;
    }
    buffer.write('<table>');
    _writeRow(buffer, [
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
      'Snippet'
    ], header: true);
    int index = 0;
    for (CompletionPerformance performance in handler.performanceList) {
      String link = makeLink(COMPLETION_PATH, {
        'index': '$index'
      }, '${performance.startTimeAndMs}');
      _writeRow(buffer, [
        link,
        '&nbsp;&nbsp;',
        performance.firstNotificationInMilliseconds,
        '&nbsp;&nbsp;',
        performance.elapsedInMilliseconds,
        '&nbsp;&nbsp;',
        performance.notificationCount,
        '&nbsp;&nbsp;',
        performance.suggestionCount,
        '&nbsp;&nbsp;',
        HTML_ESCAPE.convert(performance.snippet)
      ]);
      ++index;
    }

    buffer.write('</table>');
    buffer.write('''
      <p><strong>First (ms)</strong> - the number of milliseconds
        from when completion received the request until the first notification
        with completion results was queued for sending back to the client.
      <p><strong>Complete (ms)</strong> - the number of milliseconds
        from when completion received the request until the final notification
        with completion results was queued for sending back to the client.
      <p><strong># Notifications</strong> - the total number of notifications
        sent to the client with completion results for this request.
      <p><strong># Suggestions</strong> - the number of suggestions
        sent to the client in the first notification, followed by a comma,
        followed by the number of suggestions send to the client
        in the last notification. If there is only one notification,
        then there will be only one number in this column.''');
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
      List<DataDescriptor> descriptors, CacheState getState(DataDescriptor),
      dynamic getValue(DataDescriptor), Map<String, String> linkParameters) {
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
      buffer.write(makeLink(COMPLETION_PATH, {}, 'Completion data'));
      buffer.write('</p>');
    }, (StringBuffer buffer) {});
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
      }, (StringBuffer buffer) {});
    }
  }

  /**
   * Write a representation of an analysis option with the given [name] and
   * [value] to the given [buffer]. The option should be separated from other
   * options unless the [last] flag is true, indicating that this is the last
   * option in the list of options.
   */
  void _writeOption(StringBuffer buffer, String name, Object value,
      {bool last: false}) {
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
  void _writePluginStatus(StringBuffer buffer) {
    void writePlugin(Plugin plugin) {
      buffer.write(_server.serverPlugin.uniqueIdentifier);
      buffer.write(' (');
      buffer.write(_server.serverPlugin.runtimeType);
      buffer.write(')<br>');
    }
    buffer.write('<h3>Plugin Status</h3><p>');
    writePlugin(AnalysisEngine.instance.enginePlugin);
    writePlugin(_server.serverPlugin);
    for (Plugin plugin in _server.analysisServer.userDefinedPlugins) {
      writePlugin(plugin);
    }
    buffer.write('<p>');
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
   * Write a single row within a table to the given [buffer]. The row will have
   * one cell for each of the [columns], and will be a header row if [header] is
   * `true`.
   */
  void _writeRow(StringBuffer buffer, List<Object> columns,
      {bool header: false, List<String> classes}) {
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

      buffer.write('<p><b>Performance Data</b></p>');
      buffer.write('<p>');
      buffer.write(makeLink(
          COMMUNICATION_PERFORMANCE_PATH, {}, 'Communication performance'));
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
  void _writeSubscriptionInList(
      StringBuffer buffer, Enum service, Set<Enum> subscribedServices) {
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
  void _writeSubscriptionInMap(
      StringBuffer buffer, Enum service, Set<String> subscribedPaths) {
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
    buffer
        .write('<table class="column"><tr class="column"><td class="column">');
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
  void _writeValueAsHtml(
      StringBuffer buffer, Object value, Map<String, String> linkParameters) {
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
          makeLink(AST_PATH, linkParameters, value.runtimeType.toString());
      buffer.write('<i>$link</i>');
    } else if (value is Element) {
      String link =
          makeLink(ELEMENT_PATH, linkParameters, value.runtimeType.toString());
      buffer.write('<i>$link</i>');
    } else {
      buffer.write(HTML_ESCAPE.convert(value.toString()));
      buffer.write(' <i>(${value.runtimeType.toString()})</i>');
    }
  }

  /**
   * Create a link to [path] with query parameters [params], with inner HTML
   * [innerHtml]. If [hasError] is `true`, then the link will have the class
   * 'error'.
   */
  static String makeLink(
      String path, Map<String, String> params, String innerHtml,
      [bool hasError = false]) {
    Uri uri = new Uri(path: path, queryParameters: params);
    String href = HTML_ESCAPE.convert(uri.toString());
    String classAttribute = hasError ? ' class="error"' : '';
    return '<a href="$href"$classAttribute>$innerHtml</a>';
  }
}
