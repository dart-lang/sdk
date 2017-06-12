// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/domain_completion.dart';
import 'package:analysis_server/src/domain_diagnostic.dart';
import 'package:analysis_server/src/domain_execution.dart';
import 'package:analysis_server/src/services/completion/completion_performance.dart';
import 'package:analysis_server/src/socket_server.dart';
import 'package:analysis_server/src/status/get_handler.dart';
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:analyzer/source/error_processor.dart';
import 'package:analyzer/source/sdk_ext.dart';
import 'package:analyzer/src/context/source.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_general.dart';
import 'package:analyzer/src/services/lint.dart';
import 'package:analyzer/task/model.dart';
import 'package:path/path.dart' as path;
import 'package:plugin/plugin.dart';

String _writeWithSeparators(int value) {
  // TODO(devoncarew): Replace with the implementation from package:intl.
  String str = value.toString();
  int pos = 3;
  while (str.length > pos) {
    int len = str.length;
    str = '${str.substring(0, len - pos)},${str.substring(len - pos)}';
    pos += 4;
  }
  return str;
}

/**
 * A function that can be used to generate HTML output into the given [buffer].
 * The HTML that is generated must be valid (special characters must already be
 * encoded).
 */
typedef void HtmlGenerator(StringBuffer buffer);

/**
 * Instances of the class [GetHandler2] handle GET requests.
 */
class GetHandler2 implements AbstractGetHandler {
  /**
   * The path used to request overall performance information.
   */
  static const String ANALYSIS_PERFORMANCE_PATH = '/perf/analysis';

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
   * Query parameter used to represent the context to search for.
   */
  static const String CONTEXT_QUERY_PARAM = 'context';

  /**
   * Query parameter used to represent the path of an overlayed file.
   */
  static const String PATH_PARAM = 'path';

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
   * Handler for diagnostics requests.
   */
  DiagnosticDomainHandler _diagnosticHandler;

  /**
   * Initialize a newly created handler for GET requests.
   */
  GetHandler2(this._server, this._printBuffer);

  DiagnosticDomainHandler get diagnosticHandler {
    if (_diagnosticHandler == null) {
      _diagnosticHandler = new DiagnosticDomainHandler(_server.analysisServer);
    }
    return _diagnosticHandler;
  }

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
    return analysisServer.handlers
        .firstWhere((h) => h is CompletionDomainHandler, orElse: () => null);
  }

  /**
   * Handle a GET request received by the HTTP server.
   */
  void handleGetRequest(HttpRequest request) {
    String path = request.uri.path;
    if (path == '/') {
      _returnRedirect(request, STATUS_PATH);
    } else if (path == STATUS_PATH) {
      _returnServerStatus(request);
    } else if (path == ANALYSIS_PERFORMANCE_PATH) {
      _returnAnalysisPerformance(request);
    } else if (path == COMPLETION_PATH) {
      _returnCompletionInfo(request);
    } else if (path == COMMUNICATION_PERFORMANCE_PATH) {
      _returnCommunicationPerformance(request);
    } else if (path == CONTEXT_PATH) {
      _returnContextInfo(request);
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
    return analysisServer.driverMap.keys.firstWhere(
        (Folder folder) => folder.path == contextFilter,
        orElse: () => null);
  }

  /**
   * Return `true` if the given analysis [driver] has at least one entry with
   * an exception.
   */
  bool _hasException(AnalysisDriver driver) {
//    if (driver == null) {
//      return false;
//    }
//    MapIterator<AnalysisTarget, CacheEntry> iterator =
//        context.analysisCache.iterator();
//    while (iterator.moveNext()) {
//      CacheEntry entry = iterator.value;
//      if (entry == null || entry.exception != null) {
//        return true;
//      }
//    }
    // TODO(scheglov)
    return false;
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
      _writePage(buffer, 'Analysis Performance', [], (StringBuffer buffer) {
        buffer.write('<h3>Analysis Performance</h3>');
        _writeTwoColumns(buffer, (StringBuffer buffer) {
          //
          // Write performance tags.
          //
          buffer.write('<p><b>Performance tag data</b></p>');
          buffer.write(
              '<table style="border-collapse: separate; border-spacing: 10px 5px;">');
          _writeRow(buffer, ['Time (in ms)', 'Percent', 'Tag name'],
              header: true);
          // prepare sorted tags
          List<PerformanceTag> tags = PerformanceTag.all.toList();
          tags.remove(ServerPerformanceStatistics.idle);
          tags.sort((a, b) => b.elapsedMs - a.elapsedMs);
          // prepare total time
          int totalTagTime = 0;
          tags.forEach((PerformanceTag tag) {
            totalTagTime += tag.elapsedMs;
          });
          // write rows
          void writeRow(PerformanceTag tag) {
            double percent = (tag.elapsedMs * 100) / totalTagTime;
            String percentStr = '${percent.toStringAsFixed(2)}%';
            _writeRow(buffer, [tag.elapsedMs, percentStr, tag.label],
                classes: ["right", "right", null]);
          }

          tags.forEach(writeRow);
          buffer.write('</table>');
        }, (StringBuffer buffer) {
          //
          // Write task model timing information.
          //
          buffer.write('<p><b>Task performance data</b></p>');
          buffer.write(
              '<table style="border-collapse: separate; border-spacing: 10px 5px;">');
          _writeRow(
              buffer,
              [
                'Task Name',
                'Count',
                'Total Time (in ms)',
                'Average Time (in ms)'
              ],
              header: true);

          Map<Type, int> countMap = AnalysisTask.countMap;
          Map<Type, Stopwatch> stopwatchMap = AnalysisTask.stopwatchMap;
          List<Type> taskClasses = stopwatchMap.keys.toList();
          taskClasses.sort((Type first, Type second) =>
              first.toString().compareTo(second.toString()));
          int totalTaskTime = 0;
          taskClasses.forEach((Type taskClass) {
            int count = countMap[taskClass];
            if (count == null) {
              count = 0;
            }
            int taskTime = stopwatchMap[taskClass].elapsedMilliseconds;
            totalTaskTime += taskTime;
            _writeRow(buffer, [
              taskClass.toString(),
              count,
              taskTime,
              count <= 0 ? '-' : (taskTime / count).toStringAsFixed(3)
            ], classes: [
              null,
              "right",
              "right",
              "right"
            ]);
          });
          _writeRow(buffer, ['Total', '-', totalTaskTime, '-'],
              classes: [null, "right", "right", "right"]);
          buffer.write('</table>');
        });
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
      _writePage(buffer, 'Communication Performance', [],
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
      _writePage(buffer, 'Completion Stats', [], (StringBuffer buffer) {
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
    AnalysisDriver driver = null;
    Folder folder = _findFolder(analysisServer, contextFilter);
    if (folder == null) {
      return _returnFailure(request, 'Invalid context: $contextFilter');
    } else {
      driver = analysisServer.driverMap[folder];
    }

    List<String> priorityFiles = driver.priorityFiles;
    List<String> addedFiles = driver.addedFiles.toList();
    List<String> implicitFiles =
        driver.knownFiles.difference(driver.addedFiles).toList();
    addedFiles.sort();
    implicitFiles.sort();

    // TODO(scheglov) Use file overlays.
//    _overlayContents.clear();
//    context.visitContentCache((String fullName, int stamp, String contents) {
//      _overlayContents[fullName] = contents;
//    });

    void _writeFiles(StringBuffer buffer, String title, List<String> files) {
      buffer.write('<h3>$title</h3>');
      if (files == null || files.isEmpty) {
        buffer.write('<p>None</p>');
      } else {
        buffer.write('<p><table style="width: 100%">');
        for (String file in files) {
          buffer.write('<tr><td>');
          buffer.write(file);
          buffer.write('</td><td>');
          if (_overlayContents.containsKey(files)) {
            buffer.write(makeLink(OVERLAY_PATH, {PATH_PARAM: file}, 'overlay'));
          }
          buffer.write('</td></tr>');
        }
        buffer.write('</table></p>');
      }
    }

    void writeOptions(StringBuffer buffer, AnalysisOptionsImpl options,
        {void writeAdditionalOptions(StringBuffer buffer)}) {
      if (options == null) {
        buffer.write('<p>No option information available.</p>');
        return;
      }
      buffer.write('<p>');
      _writeOption(
          buffer, 'Analyze functon bodies', options.analyzeFunctionBodies);
      _writeOption(
          buffer, 'Enable strict call checks', options.enableStrictCallChecks);
      _writeOption(buffer, 'Enable super mixins', options.enableSuperMixins);
      _writeOption(buffer, 'Generate dart2js hints', options.dart2jsHint);
      _writeOption(buffer, 'Generate errors in implicit files',
          options.generateImplicitErrors);
      _writeOption(
          buffer, 'Generate errors in SDK files', options.generateSdkErrors);
      _writeOption(buffer, 'Generate hints', options.hint);
      _writeOption(buffer, 'Incremental resolution', options.incremental);
      _writeOption(buffer, 'Incremental resolution with API changes',
          options.incrementalApi);
      _writeOption(buffer, 'Preserve comments', options.preserveComments);
      _writeOption(buffer, 'Strong mode', options.strongMode);
      _writeOption(buffer, 'Strong mode hints', options.strongModeHints);
      if (writeAdditionalOptions != null) {
        writeAdditionalOptions(buffer);
      }
      buffer.write('</p>');
    }

    _writeResponse(request, (StringBuffer buffer) {
      String contextName = path.basename(contextFilter);
      _writePage(buffer, 'Context: $contextName', [contextFilter],
          (StringBuffer buffer) {
        buffer.write('<h3>Configuration</h3>');

        _writeColumns(buffer, <HtmlGenerator>[
          (StringBuffer buffer) {
            buffer.write('<p><b>Context Options</b></p>');
            writeOptions(buffer, driver.analysisOptions);
          },
          (StringBuffer buffer) {
            buffer.write('<p><b>SDK Context Options</b></p>');
            DartSdk sdk = driver?.sourceFactory?.dartSdk;
            writeOptions(buffer, sdk?.context?.analysisOptions,
                writeAdditionalOptions: (StringBuffer buffer) {
              if (sdk is FolderBasedDartSdk) {
                _writeOption(buffer, 'Use summaries', sdk.useSummary);
              }
            });
          },
          (StringBuffer buffer) {
            List<Linter> lints = driver.analysisOptions.lintRules;
            buffer.write('<p><b>Lints</b></p>');
            if (lints.isEmpty) {
              buffer.write('<p>none</p>');
            } else {
              for (Linter lint in lints) {
                buffer.write('<p>');
                buffer.write(lint.runtimeType);
                buffer.write('</p>');
              }
            }

            List<ErrorProcessor> errorProcessors =
                driver.analysisOptions.errorProcessors;
            int processorCount = errorProcessors?.length ?? 0;
            buffer
                .write('<p><b>Error Processor count</b>: $processorCount</p>');
          }
        ]);

        SourceFactory sourceFactory = driver.sourceFactory;
        if (sourceFactory is SourceFactoryImpl) {
          buffer.write('<h3>Resolvers</h3>');
          for (UriResolver resolver in sourceFactory.resolvers) {
            buffer.write('<p>');
            buffer.write(resolver.runtimeType);
            if (resolver is DartUriResolver) {
              DartSdk sdk = resolver.dartSdk;
              buffer.write(' (sdk = ');
              buffer.write(sdk.runtimeType);
              if (sdk is FolderBasedDartSdk) {
                buffer.write(' (path = ');
                buffer.write(sdk.directory.path);
                buffer.write(')');
              } else if (sdk is EmbedderSdk) {
                buffer.write(' (map = ');
                _writeMapOfStringToString(buffer, sdk.urlMappings);
                buffer.write(')');
              }
              buffer.write(')');
            } else if (resolver is SdkExtUriResolver) {
              buffer.write(' (map = ');
              _writeMapOfStringToString(buffer, resolver.urlMappings);
              buffer.write(')');
            }
            buffer.write('</p>');
          }
        }

        _writeFiles(
            buffer, 'Priority Files (${priorityFiles.length})', priorityFiles);
        _writeFiles(buffer, 'Added Files (${addedFiles.length})', addedFiles);
        _writeFiles(
            buffer,
            'Implicitly Analyzed Files (${implicitFiles.length})',
            implicitFiles);

        // TODO(scheglov) Show exceptions.
//        buffer.write('<h3>Exceptions</h3>');
//        if (exceptions.isEmpty) {
//          buffer.write('<p>none</p>');
//        } else {
//          exceptions.forEach((CaughtException exception) {
//            _writeException(buffer, exception);
//          });
//        }
      });
    });
  }

  void _returnFailure(HttpRequest request, String message) {
    _writeResponse(request, (StringBuffer buffer) {
      _writePage(buffer, 'Failure', [], (StringBuffer buffer) {
        buffer.write(HTML_ESCAPE.convert(message));
      });
    });
  }

  void _returnOverlayContents(HttpRequest request) {
    String path = request.requestedUri.queryParameters[PATH_PARAM];
    if (path == null) {
      return _returnFailure(request, 'Query parameter $PATH_PARAM required');
    }
    String contents = _overlayContents[path];

    _writeResponse(request, (StringBuffer buffer) {
      _writePage(buffer, 'Overlay', [], (StringBuffer buffer) {
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
      _writePage(buffer, 'Overlay information', [], (StringBuffer buffer) {
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
        buffer.write('<tr><td colspan="2">Total: $count entries</td></tr>');
        buffer.write('</table>');
      });
    });
  }

  void _returnRedirect(HttpRequest request, String pathFragment) {
    HttpResponse response = request.response;
    response.redirect(request.uri.resolve(pathFragment));
  }

  /**
   * Return a response indicating the status of the analysis server.
   */
  void _returnServerStatus(HttpRequest request) {
    _writeResponse(request, (StringBuffer buffer) {
      _writePage(buffer, 'Status', [], (StringBuffer buffer) {
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
        buffer.write('<h3>Unknown page: ');
        buffer.write(request.uri.path);
        buffer.write('</h3>');
        buffer.write('''
        <p>
        You have reached an un-recognized page. If you reached this page by
        following a link from a status page, please report the broken link to
        the Dart analyzer team:
        <a>https://github.com/dart-lang/sdk/issues/new</a>.
        </p><p>
        If you mistyped the URL, you can correct it or return to
        ${makeLink(STATUS_PATH, {}, 'the main status page')}.
        </p>''');
      });
    });
  }

  /**
   * Return a two digit decimal representation of the given non-negative integer
   * [value].
   */
  String _twoDigit(int value) => value.toString().padLeft(2, '0');

  /**
   * Write the status of the analysis domain (on the main status page) to the
   * given [buffer] object.
   */
  void _writeAnalysisStatus(StringBuffer buffer) {
    AnalysisServer analysisServer = _server.analysisServer;
    Map<Folder, AnalysisDriver> driverMap = analysisServer.driverMap;
    List<Folder> folders = driverMap.keys.toList();
    folders.sort((Folder first, Folder second) =>
        first.shortName.compareTo(second.shortName));

    buffer.write('<h3>Analysis Domain</h3>');
    _writeTwoColumns(buffer, (StringBuffer buffer) {
      buffer.write('<p>Using package resolver provider: ');
      buffer.write(_server.packageResolverProvider != null);
      buffer.write('</p>');
      buffer.write(makeLink(OVERLAYS_PATH, {}, 'Overlay information'));

      buffer.write('<p><b>Analysis Contexts</b></p>');
      bool first = true;
      folders.forEach((Folder folder) {
        if (first) {
          first = false;
        } else {
          buffer.write('<br>');
        }
        String key = folder.shortName;
        buffer.write(makeLink(CONTEXT_PATH, {CONTEXT_QUERY_PARAM: folder.path},
            key, _hasException(driverMap[folder])));
        if (!folder.getChild('.packages').exists) {
          buffer.write(' [no .packages file]');
        }
      });

      int freq = AnalysisServer.performOperationDelayFrequency;
      String delay = freq > 0 ? '1 ms every $freq ms' : 'off';

      buffer.write('<p><b>Performance Data</b></p>');
      buffer.write(
          makeLink(ANALYSIS_PERFORMANCE_PATH, {}, 'Analysis performance'));
      buffer.write('<br>');
      buffer.write('Perform operation delay: $delay');
      buffer.write('<br>');
    }, (StringBuffer buffer) {
      _writeSubscriptionMap(
          buffer, AnalysisService.VALUES, analysisServer.analysisServices);
    });
  }

  /**
   * Write multiple columns of information to the given [buffer], where the list
   * of [columns] functions are used to generate the content of those columns.
   */
  void _writeColumns(StringBuffer buffer, List<HtmlGenerator> columns) {
    buffer
        .write('<table class="column"><tr class="column"><td class="column">');
    int count = columns.length;
    for (int i = 0; i < count; i++) {
      if (i > 0) {
        buffer.write('</td><td class="column">');
      }
      columns[i](buffer);
    }
    buffer.write('</td></tr></table>');
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
    _writeRow(
        buffer,
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
          'Snippet'
        ],
        header: true);
    int index = 0;
    for (CompletionPerformance performance in handler.performanceList) {
      String link = makeLink(COMPLETION_PATH, {'index': '$index'},
          '${performance.startTimeAndMs}');
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
   * Write the status of the edit domain (on the main status page) to the given
   * [buffer].
   */
  void _writeEditStatus(StringBuffer buffer) {
    buffer.write('<h3>Edit Domain</h3>');
    _writeTwoColumns(buffer, (StringBuffer buffer) {
      buffer.write(makeLink(COMPLETION_PATH, {}, 'Completion stats'));
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
        buffer.write('<br>');
      }, (StringBuffer buffer) {
        _writeSubscriptionList(buffer, ExecutionService.VALUES, services);
      });
    }
  }

  /**
   * Write to the given [buffer] a representation of the given [map] of strings
   * to strings.
   */
  void _writeMapOfStringToString(StringBuffer buffer, Map<String, String> map) {
    List<String> keys = map.keys.toList();
    keys.sort();
    int length = keys.length;
    buffer.write('{');
    for (int i = 0; i < length; i++) {
      buffer.write('<br>');
      String key = keys[i];
      if (i > 0) {
        buffer.write(', ');
      }
      buffer.write(key);
      buffer.write(' = ');
      buffer.write(map[key]);
    }
    buffer.write('<br>}');
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
    buffer.write('<title>Analysis Server</title>');
    buffer.write('<style>');
    buffer.write('a {color: #0000DD; text-decoration: none;}');
    buffer.write('a:link.error {background-color: #FFEEEE;}');
    buffer.write('a:visited.error {background-color: #FFEEEE;}');
    buffer.write('a:hover.error {background-color: #FFEEEE;}');
    buffer.write('a:active.error {background-color: #FFEEEE;}');
    buffer.write(
        'div.subtitle {float: right; font-weight: normal; font-size: 1rem;}');
    buffer.write('h2 {margin-top: 0;}');
    buffer.write('h3 {border-bottom: 1px #DDD solid; margin-bottom: 0em;}');
    buffer.write('p {margin-top: 0.5em; margin-bottom: 0;}');
    buffer.write(
        'p.commentary {margin-top: 1em; margin-bottom: 1em; margin-left: 2em; font-style: italic;}');
//    response.write('span.error {text-decoration-line: underline; text-decoration-color: red; text-decoration-style: wavy;}');
    buffer.write(
        'table.column {border: 0px solid black; width: 100%; table-layout: fixed;}');
    buffer.write('td.column {vertical-align: top; width: 50%;}');
    buffer.write('td.right {text-align: right;}');
    buffer.write('th {text-align: left; vertical-align:top;}');
    buffer.write('tr {vertical-align:top;}');
    buffer.write('</style>');
    buffer.write('</head>');

    buffer.write('<body>');
    buffer.write('<h2>$title <div class="subtitle">$date, $time</div></h2>');
    if (subtitles != null && subtitles.isNotEmpty) {
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
      buffer.write(plugin.uniqueIdentifier);
      buffer.write(' (');
      buffer.write(plugin.runtimeType);
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
      if (columns[i] is int) {
        buffer.write(_writeWithSeparators(columns[i]));
      } else {
        buffer.write(columns[i]);
      }
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
      buffer.write('<p><b>State</b></p>');
      if (analysisServer == null) {
        buffer.write('Status: <span style="color:red">Not running</span>');
        return;
      }
      buffer.write('Status: Running<br>');
      buffer.write('New analysis driver: ');
      buffer.write(analysisServer.options.enableNewAnalysisDriver);
      buffer.write('<br>');
      buffer.write('Instrumentation: ');
      if (AnalysisEngine.instance.instrumentationService.isActive) {
        buffer.write('<strong>active</strong>');
      } else {
        buffer.write('inactive');
      }
      buffer.write('<br>');
      buffer.write('Process ID: ');
      buffer.write(pid);

      buffer.write('<p><b>Performance Data</b></p>');
      buffer.write(makeLink(
          COMMUNICATION_PERFORMANCE_PATH, {}, 'Communication performance'));

      if (AnalysisEngine.instance.instrumentationService.isActive) {
        buffer.write('<p><b>Instrumentation</b></p>');
        InstrumentationServer instrumentationServer = AnalysisEngine
            .instance.instrumentationService.instrumentationServer;
        String description = instrumentationServer.describe;
        HtmlEscape htmlEscape = new HtmlEscape(HtmlEscapeMode.ELEMENT);
        description = htmlEscape.convert(description);
        // Convert http(s): references to hyperlinks.
        final RegExp urlRegExp = new RegExp(r'[http|https]+:\/*(\S+)');
        description = description.replaceAllMapped(urlRegExp, (Match match) {
          return '<a href="${match.group(0)}">${match.group(1)}</a>';
        });
        buffer.write(description.replaceAll('\n', '<br>'));
      }
    }, (StringBuffer buffer) {
      _writeSubscriptionList(buffer, ServerService.VALUES, services);
      buffer.write('<p><b>Versions</b></p>');
      buffer.write('Dart SDK: ${Platform.version}<br>');
      buffer.write('Analysis server version: ${AnalysisServer.VERSION}<br>');
    });
    return analysisServer != null;
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
    buffer.write('<br>');
    if (subscribedPaths != null && subscribedPaths.isNotEmpty) {
      List<String> paths = subscribedPaths.toList();
      paths.sort();
      for (String path in paths) {
        buffer.write('$path<br>');
      }
    }
    buffer.write('</p>');
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
    for (Enum service in allServices) {
      _writeSubscriptionInList(buffer, service, subscribedServices);
      buffer.write('<br>');
    }
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
   * Create a link to [path] with query parameters [params], with inner HTML
   * [innerHtml]. If [hasError] is `true`, then the link will have the class
   * 'error'.
   */
  static String makeLink(
      String path, Map<String, String> params, String innerHtml,
      [bool hasError = false]) {
    Uri uri = params.isEmpty
        ? new Uri(path: path)
        : new Uri(path: path, queryParameters: params);
    String href = HTML_ESCAPE.convert(uri.toString());
    String classAttribute = hasError ? ' class="error"' : '';
    return '<a href="$href" $classAttribute>$innerHtml</a>';
  }
}
