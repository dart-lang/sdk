// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/domain_completion.dart';
import 'package:analysis_server/src/domain_diagnostic.dart';
import 'package:analysis_server/src/domain_execution.dart';
import 'package:analysis_server/src/operation/operation.dart';
import 'package:analysis_server/src/operation/operation_analysis.dart';
import 'package:analysis_server/src/operation/operation_queue.dart';
import 'package:analysis_server/src/services/completion/completion_performance.dart';
import 'package:analysis_server/src/socket_server.dart';
import 'package:analysis_server/src/status/ast_writer.dart';
import 'package:analysis_server/src/status/element_writer.dart';
import 'package:analysis_server/src/status/memory_use.dart';
import 'package:analysis_server/src/status/validator.dart';
import 'package:analysis_server/src/utilities/average.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/error_processor.dart';
import 'package:analyzer/source/sdk_ext.dart';
import 'package:analyzer/src/context/cache.dart';
import 'package:analyzer/src/context/context.dart' show AnalysisContextImpl;
import 'package:analyzer/src/context/source.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_collection.dart';
import 'package:analyzer/src/generated/utilities_general.dart';
import 'package:analyzer/src/services/lint.dart';
import 'package:analyzer/src/task/dart.dart';
import 'package:analyzer/src/task/driver.dart';
import 'package:analyzer/src/task/html.dart';
import 'package:analyzer/src/task/options.dart';
import 'package:analyzer/task/dart.dart';
import 'package:analyzer/task/general.dart';
import 'package:analyzer/task/html.dart';
import 'package:analyzer/task/model.dart';
import 'package:plugin/plugin.dart';

/**
 * A function that can be used to generate HTML output into the given [buffer].
 * The HTML that is generated must be valid (special characters must already be
 * encoded).
 */
typedef void HtmlGenerator(StringBuffer buffer);

/**
 * Instances of the class [AbstractGetHandler] handle GET requests.
 */
abstract class AbstractGetHandler {
  /**
   * Handle a GET request received by the HTTP server.
   */
  void handleGetRequest(HttpRequest request);
}

class ElementCounter extends RecursiveElementVisitor {
  Map<Type, int> counts = new HashMap<Type, int>();
  int elementsWithDocs = 0;
  int totalDocSpan = 0;

  void visit(Element element) {
    String comment = element.documentationComment;
    if (comment != null) {
      ++elementsWithDocs;
      totalDocSpan += comment.length;
    }

    Type type = element.runtimeType;
    if (counts[type] == null) {
      counts[type] = 1;
    } else {
      counts[type]++;
    }
  }

  @override
  visitClassElement(ClassElement element) {
    visit(element);
    super.visitClassElement(element);
  }

  @override
  visitCompilationUnitElement(CompilationUnitElement element) {
    visit(element);
    super.visitCompilationUnitElement(element);
  }

  @override
  visitConstructorElement(ConstructorElement element) {
    visit(element);
    super.visitConstructorElement(element);
  }

  @override
  visitExportElement(ExportElement element) {
    visit(element);
    super.visitExportElement(element);
  }

  @override
  visitFieldElement(FieldElement element) {
    visit(element);
    super.visitFieldElement(element);
  }

  @override
  visitFieldFormalParameterElement(FieldFormalParameterElement element) {
    visit(element);
    super.visitFieldFormalParameterElement(element);
  }

  @override
  visitFunctionElement(FunctionElement element) {
    visit(element);
    super.visitFunctionElement(element);
  }

  @override
  visitFunctionTypeAliasElement(FunctionTypeAliasElement element) {
    visit(element);
    super.visitFunctionTypeAliasElement(element);
  }

  @override
  visitImportElement(ImportElement element) {
    visit(element);
    super.visitImportElement(element);
  }

  @override
  visitLabelElement(LabelElement element) {
    visit(element);
    super.visitLabelElement(element);
  }

  @override
  visitLibraryElement(LibraryElement element) {
    visit(element);
    super.visitLibraryElement(element);
  }

  @override
  visitLocalVariableElement(LocalVariableElement element) {
    visit(element);
    super.visitLocalVariableElement(element);
  }

  @override
  visitMethodElement(MethodElement element) {
    visit(element);
    super.visitMethodElement(element);
  }

  @override
  visitMultiplyDefinedElement(MultiplyDefinedElement element) {
    visit(element);
    super.visitMultiplyDefinedElement(element);
  }

  @override
  visitParameterElement(ParameterElement element) {
    visit(element);
    super.visitParameterElement(element);
  }

  @override
  visitPrefixElement(PrefixElement element) {
    visit(element);
    super.visitPrefixElement(element);
  }

  @override
  visitPropertyAccessorElement(PropertyAccessorElement element) {
    visit(element);
    super.visitPropertyAccessorElement(element);
  }

  @override
  visitTopLevelVariableElement(TopLevelVariableElement element) {
    visit(element);
    super.visitTopLevelVariableElement(element);
  }

  @override
  visitTypeParameterElement(TypeParameterElement element) {
    visit(element);
    super.visitTypeParameterElement(element);
  }
}

/**
 * Instances of the class [GetHandler] handle GET requests.
 */
class GetHandler implements AbstractGetHandler {
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
   * The path used to request diagnostic information for a single context.
   */
  static const String CONTEXT_DIAGNOSTICS_PATH = '/diagnostic/context';

  /**
   * The path used to request running a validation report for a single context.
   */
  static const String CONTEXT_VALIDATION_DIAGNOSTICS_PATH =
      '/diagnostic/contextValidation';

  /**
   * The path used to request information about a specific context.
   */
  static const String CONTEXT_PATH = '/context';

  /**
   * The path used to request diagnostic information.
   */
  static const String DIAGNOSTIC_PATH = '/diagnostic';

  /**
   * The path used to request information about a element model.
   */
  static const String ELEMENT_PATH = '/element';

  /**
   * The path used to request an analysis of the memory use of the analyzer.
   */
  static const String MEMORY_USE_PATH = '/memoryUse';

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
   * Rolling average of calls to get diagnostics.
   */
  Average _diagnosticCallAverage = new Average();

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
  GetHandler(this._server, this._printBuffer);

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
    if (path == '/' || path == STATUS_PATH) {
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
    } else if (path == CONTEXT_DIAGNOSTICS_PATH) {
      _returnContextDiagnostics(request);
    } else if (path == CONTEXT_VALIDATION_DIAGNOSTICS_PATH) {
      _returnContextValidationDiagnostics(request);
    } else if (path == CONTEXT_PATH) {
      _returnContextInfo(request);
    } else if (path == DIAGNOSTIC_PATH) {
      _returnDiagnosticInfo(request);
    } else if (path == ELEMENT_PATH) {
      _returnElement(request);
    } else if (path == MEMORY_USE_PATH) {
      _returnMemoryUsage(request);
    } else if (path == OVERLAY_PATH) {
      _returnOverlayContents(request);
    } else if (path == OVERLAYS_PATH) {
      _returnOverlaysInfo(request);
    } else {
      _returnUnknownRequest(request);
    }
  }

  /**
   * Produce an encoded version of the given [descriptor] that can be used to
   * find the descriptor later.
   */
  String _encodeSdkDescriptor(SdkDescription descriptor) {
    StringBuffer buffer = new StringBuffer();
    buffer.write(descriptor.options.signature.join(','));
    for (String path in descriptor.paths) {
      buffer.write('+');
      buffer.write(path);
    }
    return buffer.toString();
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
   * Return any AST structure stored in the given [entry].
   */
  CompilationUnit _getAnyAst(CacheEntry entry) {
    CompilationUnit unit = entry.getValue(PARSED_UNIT);
    if (unit != null) {
      return unit;
    }
    unit = entry.getValue(RESOLVED_UNIT1);
    if (unit != null) {
      return unit;
    }
    unit = entry.getValue(RESOLVED_UNIT2);
    if (unit != null) {
      return unit;
    }
    unit = entry.getValue(RESOLVED_UNIT3);
    if (unit != null) {
      return unit;
    }
    unit = entry.getValue(RESOLVED_UNIT4);
    if (unit != null) {
      return unit;
    }
    unit = entry.getValue(RESOLVED_UNIT5);
    if (unit != null) {
      return unit;
    }
    unit = entry.getValue(RESOLVED_UNIT6);
    if (unit != null) {
      return unit;
    }
    unit = entry.getValue(RESOLVED_UNIT7);
    if (unit != null) {
      return unit;
    }
    unit = entry.getValue(RESOLVED_UNIT8);
    if (unit != null) {
      return unit;
    }
    unit = entry.getValue(RESOLVED_UNIT9);
    if (unit != null) {
      return unit;
    }
    unit = entry.getValue(RESOLVED_UNIT10);
    if (unit != null) {
      return unit;
    }
    unit = entry.getValue(RESOLVED_UNIT11);
    if (unit != null) {
      return unit;
    }
    unit = entry.getValue(RESOLVED_UNIT12);
    if (unit != null) {
      return unit;
    }
    return entry.getValue(RESOLVED_UNIT);
  }

  /**
   * Return a list of the result descriptors whose state should be displayed for
   * the given cache [entry].
   */
  List<ResultDescriptor> _getExpectedResults(CacheEntry entry) {
    AnalysisTarget target = entry.target;
    Set<ResultDescriptor> results = entry.nonInvalidResults.toSet();
    if (target is Source) {
      String name = target.shortName;
      results.add(CONTENT);
      results.add(LINE_INFO);
      results.add(MODIFICATION_TIME);
      if (AnalysisEngine.isDartFileName(name)) {
        results.add(BUILD_DIRECTIVES_ERRORS);
        results.add(BUILD_LIBRARY_ERRORS);
        results.add(CONTAINING_LIBRARIES);
        results.add(DART_ERRORS);
        results.add(EXPLICITLY_IMPORTED_LIBRARIES);
        results.add(EXPORT_SOURCE_CLOSURE);
        results.add(EXPORTED_LIBRARIES);
        results.add(IMPORTED_LIBRARIES);
        results.add(INCLUDED_PARTS);
        results.add(IS_LAUNCHABLE);
        results.add(LIBRARY_ELEMENT1);
        results.add(LIBRARY_ELEMENT2);
        results.add(LIBRARY_ELEMENT3);
        results.add(LIBRARY_ELEMENT4);
        results.add(LIBRARY_ELEMENT5);
        results.add(LIBRARY_ELEMENT6);
        results.add(LIBRARY_ELEMENT);
        results.add(LIBRARY_ERRORS_READY);
        results.add(PARSE_ERRORS);
        results.add(PARSED_UNIT);
        results.add(SCAN_ERRORS);
        results.add(SOURCE_KIND);
        results.add(TOKEN_STREAM);
        results.add(UNITS);
      } else if (AnalysisEngine.isHtmlFileName(name)) {
        results.add(DART_SCRIPTS);
        results.add(HTML_DOCUMENT);
        results.add(HTML_DOCUMENT_ERRORS);
        results.add(HTML_ERRORS);
        results.add(REFERENCED_LIBRARIES);
      } else if (AnalysisEngine.isAnalysisOptionsFileName(name)) {
        results.add(ANALYSIS_OPTIONS_ERRORS);
      }
    } else if (target is LibrarySpecificUnit) {
      results.add(COMPILATION_UNIT_CONSTANTS);
      results.add(COMPILATION_UNIT_ELEMENT);
      results.add(HINTS);
      results.add(LINTS);
      results.add(INFERABLE_STATIC_VARIABLES_IN_UNIT);
      results.add(LIBRARY_UNIT_ERRORS);
      results.add(RESOLVE_DIRECTIVES_ERRORS);
      results.add(RESOLVE_TYPE_NAMES_ERRORS);
      results.add(RESOLVE_TYPE_BOUNDS_ERRORS);
      results.add(RESOLVE_UNIT_ERRORS);
      results.add(RESOLVED_UNIT1);
      results.add(RESOLVED_UNIT2);
      results.add(RESOLVED_UNIT3);
      results.add(RESOLVED_UNIT4);
      results.add(RESOLVED_UNIT5);
      results.add(RESOLVED_UNIT6);
      results.add(RESOLVED_UNIT7);
      results.add(RESOLVED_UNIT8);
      results.add(RESOLVED_UNIT9);
      results.add(RESOLVED_UNIT10);
      results.add(RESOLVED_UNIT11);
      results.add(RESOLVED_UNIT12);
      results.add(RESOLVED_UNIT);
      results.add(STRONG_MODE_ERRORS);
      results.add(USED_IMPORTED_ELEMENTS);
      results.add(USED_LOCAL_ELEMENTS);
      results.add(VARIABLE_REFERENCE_ERRORS);
      results.add(VERIFY_ERRORS);
    } else if (target is ConstantEvaluationTarget) {
      results.add(CONSTANT_DEPENDENCIES);
      results.add(CONSTANT_VALUE);
      if (target is VariableElement) {
        results.add(INFERABLE_STATIC_VARIABLE_DEPENDENCIES);
        results.add(INFERRED_STATIC_VARIABLE);
      }
    } else if (target is AnalysisContextTarget) {
      results.add(TYPE_PROVIDER);
    }
    return results.toList();
  }

  /**
   * Return the context for the SDK whose descriptor is encoded to be the same
   * as the given [contextFilter]. The [analysisServer] is used to access the
   * SDKs.
   */
  AnalysisContext _getSdkContext(
      AnalysisServer analysisServer, String contextFilter) {
    DartSdkManager manager = analysisServer.sdkManager;
    List<SdkDescription> descriptors = manager.sdkDescriptors;
    for (SdkDescription descriptor in descriptors) {
      if (contextFilter == _encodeSdkDescriptor(descriptor)) {
        return manager.getSdk(descriptor, () => null)?.context;
      }
    }
    return null;
  }

  /**
   * Return `true` if the given analysis [context] has at least one entry with
   * an exception.
   */
  bool _hasException(InternalAnalysisContext context) {
    if (context == null) {
      return false;
    }
    MapIterator<AnalysisTarget, CacheEntry> iterator =
        context.analysisCache.iterator();
    while (iterator.moveNext()) {
      CacheEntry entry = iterator.value;
      if (entry == null || entry.exception != null) {
        return true;
      }
    }
    return false;
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
          //
          // Write target counts.
          //
          void incrementCount(Map<String, int> counts, String key) {
            int count = counts[key];
            if (count == null) {
              count = 1;
            } else {
              count++;
            }
            counts[key] = count;
          }

          Set<AnalysisTarget> countedTargets = new HashSet<AnalysisTarget>();
          Map<String, int> sourceTypeCounts = new HashMap<String, int>();
          Map<String, int> typeCounts = new HashMap<String, int>();
          int explicitSourceCount = 0;
          int explicitLineInfoCount = 0;
          int explicitLineCount = 0;
          int implicitSourceCount = 0;
          int implicitLineInfoCount = 0;
          int implicitLineCount = 0;
          for (InternalAnalysisContext context
              in analysisServer.analysisContexts) {
            Set<Source> explicitSources = new HashSet<Source>();
            Set<Source> implicitSources = new HashSet<Source>();
            AnalysisCache cache = context.analysisCache;
            MapIterator<AnalysisTarget, CacheEntry> iterator = cache.iterator();
            while (iterator.moveNext()) {
              AnalysisTarget target = iterator.key;
              if (countedTargets.add(target)) {
                if (target is Source) {
                  String name = target.fullName;
                  String sourceName;
                  if (AnalysisEngine.isDartFileName(name)) {
                    if (iterator.value.explicitlyAdded) {
                      explicitSources.add(target);
                      sourceName = 'Dart file (explicit)';
                    } else {
                      implicitSources.add(target);
                      sourceName = 'Dart file (implicit)';
                    }
                  } else if (AnalysisEngine.isHtmlFileName(name)) {
                    if (iterator.value.explicitlyAdded) {
                      sourceName = 'Html file (explicit)';
                    } else {
                      sourceName = 'Html file (implicit)';
                    }
                  } else {
                    if (iterator.value.explicitlyAdded) {
                      sourceName = 'Unknown file (explicit)';
                    } else {
                      sourceName = 'Unknown file (implicit)';
                    }
                  }
                  incrementCount(sourceTypeCounts, sourceName);
                } else if (target is ConstantEvaluationTarget) {
                  incrementCount(typeCounts, 'ConstantEvaluationTarget');
                } else {
                  String typeName = target.runtimeType.toString();
                  incrementCount(typeCounts, typeName);
                }
              }
            }

            int lineCount(Set<Source> sources, bool explicit) {
              return sources.fold(0, (int previousTotal, Source source) {
                LineInfo lineInfo = context.getLineInfo(source);
                if (lineInfo is LineInfoWithCount) {
                  if (explicit) {
                    explicitLineInfoCount++;
                  } else {
                    implicitLineInfoCount++;
                  }
                  return previousTotal + lineInfo.lineCount;
                } else {
                  return previousTotal;
                }
              });
            }

            explicitSourceCount += explicitSources.length;
            explicitLineCount += lineCount(explicitSources, true);
            implicitSourceCount += implicitSources.length;
            implicitLineCount += lineCount(implicitSources, false);
          }
          List<String> sourceTypeNames = sourceTypeCounts.keys.toList();
          sourceTypeNames.sort();
          List<String> typeNames = typeCounts.keys.toList();
          typeNames.sort();

          buffer.write('<p><b>Target counts</b></p>');
          buffer.write(
              '<table style="border-collapse: separate; border-spacing: 10px 5px;">');
          _writeRow(buffer, ['Target', 'Count'], header: true);
          for (String sourceTypeName in sourceTypeNames) {
            _writeRow(
                buffer, [sourceTypeName, sourceTypeCounts[sourceTypeName]],
                classes: [null, "right"]);
          }
          for (String typeName in typeNames) {
            _writeRow(buffer, [typeName, typeCounts[typeName]],
                classes: [null, "right"]);
          }
          buffer.write('</table>');

          buffer.write('<p><b>Line counts</b></p>');
          buffer.write(
              '<table style="border-collapse: separate; border-spacing: 10px 5px;">');
          _writeRow(buffer, ['Kind', 'Lines of Code', 'Source Counts'],
              header: true);
          _writeRow(buffer, [
            'Explicit',
            explicitLineCount.toString(),
            '$explicitLineInfoCount / $explicitSourceCount'
          ], classes: [
            null,
            "right"
          ]);
          _writeRow(buffer, [
            'Implicit',
            implicitLineCount.toString(),
            '$implicitLineInfoCount / $implicitSourceCount'
          ], classes: [
            null,
            "right"
          ]);
          _writeRow(buffer, [
            'Total',
            (explicitLineCount + implicitLineCount).toString(),
            '${explicitLineInfoCount + implicitLineInfoCount} / ${explicitSourceCount + implicitSourceCount}'
          ], classes: [
            null,
            "right"
          ]);
          buffer.write('</table>');

          Map<ResultDescriptor, int> recomputedCounts =
              CacheEntry.recomputedCounts;
          List<ResultDescriptor> descriptors = recomputedCounts.keys.toList();
          descriptors.sort(ResultDescriptor.SORT_BY_NAME);
          buffer.write('<p><b>Results computed after being flushed</b></p>');
          buffer.write(
              '<table style="border-collapse: separate; border-spacing: 10px 5px;">');
          _writeRow(buffer, ['Result', 'Count'], header: true);
          for (ResultDescriptor descriptor in descriptors) {
            _writeRow(buffer, [descriptor.name, recomputedCounts[descriptor]],
                classes: [null, "right"]);
          }
          buffer.write('</table>');

          {
            buffer.write('<p><b>Cache consistency statistics</b></p>');
            buffer.write(
                '<table style="border-collapse: separate; border-spacing: 10px 5px;">');
            _writeRow(buffer, ['Name', 'Count'], header: true);
            _writeRow(buffer, [
              'Changed',
              PerformanceStatistics
                  .cacheConsistencyValidationStatistics.numOfChanged
            ], classes: [
              null,
              "right"
            ]);
            _writeRow(buffer, [
              'Removed',
              PerformanceStatistics
                  .cacheConsistencyValidationStatistics.numOfRemoved
            ], classes: [
              null,
              "right"
            ]);
            buffer.write('</table>');
          }
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

    InternalAnalysisContext context = analysisServer.folderMap[folder];

    _writeResponse(request, (StringBuffer buffer) {
      _writePage(buffer, 'Analysis Server - AST Structure',
          ['Context: $contextFilter', 'File: $sourceUri'], (HttpResponse) {
        Source source = context.sourceFactory.forUri(sourceUri);
        if (source == null) {
          buffer.write('<p>Not found.</p>');
          return;
        }
        List<Source> libraries = context.getLibrariesContaining(source);
        for (Source library in libraries) {
          AnalysisTarget target = new LibrarySpecificUnit(library, source);
          CacheEntry entry = context.analysisCache.get(target);
          buffer.write('<b>$target</b><br>');
          if (entry == null) {
            buffer.write('<p>Not found.</p>');
            continue;
          }
          CompilationUnit ast = _getAnyAst(entry);
          if (ast == null) {
            buffer.write('<p>null</p>');
            continue;
          }
          AstWriter writer = new AstWriter(buffer);
          ast.accept(writer);
          if (writer.exceptions.isNotEmpty) {
            buffer.write('<h3>Exceptions while creating page</h3>');
            for (CaughtException exception in writer.exceptions) {
              _writeException(buffer, exception);
            }
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
    InternalAnalysisContext context = null;
    Folder folder = _findFolder(analysisServer, contextFilter);
    if (folder == null) {
      context = _getSdkContext(analysisServer, contextFilter);
      if (context == null) {
        return _returnFailure(request, 'Invalid context: $contextFilter');
      }
      return _returnFailure(request,
          'Cannot view cache entries from an SDK context: $contextFilter');
    } else {
      context = analysisServer.folderMap[folder];
    }
    String sourceUri = request.uri.queryParameters[SOURCE_QUERY_PARAM];
    if (sourceUri == null) {
      return _returnFailure(
          request, 'Query parameter $SOURCE_QUERY_PARAM required');
    }

    List<Folder> allContexts = <Folder>[];
    Map<Folder, List<CacheEntry>> entryMap =
        new HashMap<Folder, List<CacheEntry>>();
    StringBuffer invalidKeysBuffer = new StringBuffer();
    analysisServer.folderMap.forEach((Folder folder, AnalysisContext context) {
      Source source = context.sourceFactory.forUri(sourceUri);
      if (source != null) {
        MapIterator<AnalysisTarget, CacheEntry> iterator =
            (context as InternalAnalysisContext).analysisCache.iterator();
        while (iterator.moveNext()) {
          if (source == iterator.key.source) {
            if (!allContexts.contains(folder)) {
              allContexts.add(folder);
            }
            List<CacheEntry> entries = entryMap[folder];
            if (entries == null) {
              entries = <CacheEntry>[];
              entryMap[folder] = entries;
            }
            CacheEntry value = iterator.value;
            if (value == null) {
              if (invalidKeysBuffer.isNotEmpty) {
                invalidKeysBuffer.write(', ');
              }
              invalidKeysBuffer.write(iterator.key.toString());
            } else {
              entries.add(value);
            }
          }
        }
      }
    });
    allContexts.sort((Folder firstFolder, Folder secondFolder) =>
        firstFolder.path.compareTo(secondFolder.path));

    _writeResponse(request, (StringBuffer buffer) {
      _writePage(buffer, 'Analysis Server - Cache Entry',
          ['Context: $contextFilter', 'File: $sourceUri'], (HttpResponse) {
        if (invalidKeysBuffer.isNotEmpty) {
          buffer.write('<h3>Targets with null Entries</h3><p>');
          buffer.write(invalidKeysBuffer.toString());
          buffer.write('</p>');
        }
        List<CacheEntry> entries = entryMap[folder];
        buffer.write('<h3>Analyzing Contexts</h3><p>');
        bool first = true;
        allContexts.forEach((Folder folder) {
          if (first) {
            first = false;
          } else {
            buffer.write('<br>');
          }
          InternalAnalysisContext analyzingContext =
              analysisServer.folderMap[folder];
          if (analyzingContext == context) {
            buffer.write(folder.path);
          } else {
            buffer.write(makeLink(
                CACHE_ENTRY_PATH,
                {
                  CONTEXT_QUERY_PARAM: folder.path,
                  SOURCE_QUERY_PARAM: sourceUri
                },
                HTML_ESCAPE.convert(folder.path)));
          }
          if (entries == null) {
            buffer.write(' (file does not exist)');
          } else {
            CacheEntry sourceEntry = entries
                .firstWhere((CacheEntry entry) => entry.target is Source);
            if (sourceEntry == null) {
              buffer.write(' (missing source entry)');
            } else if (sourceEntry.explicitlyAdded) {
              buffer.write(' (explicit)');
            } else {
              buffer.write(' (implicit)');
            }
          }
        });
        buffer.write('</p>');

        if (entries == null) {
          buffer.write('<p>Not being analyzed in this context.</p>');
          return;
        }
        for (CacheEntry entry in entries) {
          Map<String, String> linkParameters = <String, String>{
            CONTEXT_QUERY_PARAM: contextFilter,
            SOURCE_QUERY_PARAM: sourceUri
          };
          List<ResultDescriptor> results = _getExpectedResults(entry);
          results.sort(ResultDescriptor.SORT_BY_NAME);

          buffer.write('<h3>');
          buffer.write(HTML_ESCAPE.convert(entry.target.toString()));
          buffer.write('</h3>');
          buffer.write('<p>time</p><blockquote><p>Value</p><blockquote>');
          buffer.write(entry.modificationTime);
          buffer.write('</blockquote></blockquote>');
          for (ResultDescriptor result in results) {
            ResultData data = entry.getResultData(result);
            CacheState state = entry.getState(result);
            String descriptorName = HTML_ESCAPE.convert(result.toString());
            String descriptorState = HTML_ESCAPE.convert(state.toString());
            buffer
                .write('<p>$descriptorName ($descriptorState)</p><blockquote>');
            if (state == CacheState.VALID) {
              buffer.write('<p>Value</p><blockquote>');
              try {
                _writeValueAsHtml(
                    buffer, entry.getValue(result), linkParameters);
              } catch (exception) {
                buffer.write('(${HTML_ESCAPE.convert(exception.toString())})');
              }
              buffer.write('</blockquote>');
            }
            _writeTargetedResults(buffer, 'Depends on', data.dependedOnResults);
            _writeTargetedResults(
                buffer, 'Depended on by', data.dependentResults);
            buffer.write('</blockquote>');
          }
          if (entry.exception != null) {
            buffer.write('<dt>exception</dt><dd>');
            _writeException(buffer, entry.exception);
            buffer.write('</dd>');
          }
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

    // TODO(brianwilkerson) Figure out how to convert the 'descriptorFilter' to
    // a ResultDescriptor so that we can query the state, then uncomment the
    // code below that computes and prints the list of links.
//    Folder folder = _findFolder(analysisServer, contextFilter);
//    InternalAnalysisContext context = analysisServer.folderMap[folder];
//    List<String> links = <String>[];
//    MapIterator<AnalysisTarget, CacheEntry> iterator = context.analysisCache.iterator();
//    while (iterator.moveNext()) {
//      Source source = iterator.key.source;
//      if (source != null) {
//        CacheEntry entry = iterator.value;
//        if (entry.getState(result) == stateFilter) {
//          String link = makeLink(CACHE_ENTRY_PATH, {
//            CONTEXT_QUERY_PARAM: folder.path,
//            SOURCE_QUERY_PARAM: source.uri.toString()
//          }, HTML_ESCAPE.convert(source.fullName));
//          links.add(link);
//        }
//      }
//    }

    _writeResponse(request, (StringBuffer buffer) {
      _writePage(buffer, 'Analysis Server - Cache Search', [
        'Context: $contextFilter',
        'Descriptor: ${HTML_ESCAPE.convert(descriptorFilter)}',
        'State: ${HTML_ESCAPE.convert(stateQueryParam)}'
      ], (StringBuffer buffer) {
        buffer.write('<p>Cache search is not yet implemented.</p>');
//        buffer.write('<p>${links.length} files found</p>');
//        buffer.write('<ul>');
//        links.forEach((String link) {
//          buffer.write('<li>$link</li>');
//        });
//        buffer.write('</ul>');
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
   * Return a response displaying diagnostic information for a single context.
   */
  void _returnContextDiagnostics(HttpRequest request) {
    AnalysisServer analysisServer = _server.analysisServer;
    if (analysisServer == null) {
      return _returnFailure(request, 'Analysis server is not running');
    }
    String contextFilter = request.uri.queryParameters[CONTEXT_QUERY_PARAM];
    if (contextFilter == null) {
      return _returnFailure(
          request, 'Query parameter $CONTEXT_QUERY_PARAM required');
    }
    InternalAnalysisContext context = null;
    Folder folder = _findFolder(analysisServer, contextFilter);
    if (folder == null) {
      context = _getSdkContext(analysisServer, contextFilter);
      if (context == null) {
        return _returnFailure(request, 'Invalid context: $contextFilter');
      }
    } else {
      context = analysisServer.folderMap[folder];
    }

    _writeResponse(request, (StringBuffer buffer) {
      _writePage(buffer, 'Analysis Server - Context Diagnostics',
          ['Context: $contextFilter'], (StringBuffer buffer) {
        _writeContextDiagnostics(buffer, context, contextFilter);
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
    InternalAnalysisContext context = null;
    Folder folder = _findFolder(analysisServer, contextFilter);
    if (folder == null) {
      context = _getSdkContext(analysisServer, contextFilter);
      if (context == null) {
        return _returnFailure(request, 'Invalid context: $contextFilter');
      }
    } else {
      context = analysisServer.folderMap[folder];
    }

    List<String> priorityNames = <String>[];
    List<String> explicitNames = <String>[];
    List<String> implicitNames = <String>[];
    Map<String, String> links = new HashMap<String, String>();
    List<CaughtException> exceptions = <CaughtException>[];
    context.prioritySources.forEach((Source source) {
      priorityNames.add(source.fullName);
    });
    MapIterator<AnalysisTarget, CacheEntry> iterator =
        context.analysisCache.iterator(context: context);
    while (iterator.moveNext()) {
      AnalysisTarget target = iterator.key;
      if (target is Source) {
        CacheEntry entry = iterator.value;
        String sourceName = target.fullName;
        if (!links.containsKey(sourceName)) {
          CaughtException exception = entry.exception;
          if (exception != null) {
            exceptions.add(exception);
          }
          String link = makeLink(
              CACHE_ENTRY_PATH,
              {
                CONTEXT_QUERY_PARAM: contextFilter,
                SOURCE_QUERY_PARAM: target.uri.toString()
              },
              sourceName,
              exception != null);
          if (entry.explicitlyAdded) {
            explicitNames.add(sourceName);
          } else {
            implicitNames.add(sourceName);
          }
          links[sourceName] = link;
        }
      }
    }
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
        buffer.write('<p><table style="width: 100%">');
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
      _writePage(
          buffer, 'Analysis Server - Context', ['Context: $contextFilter'],
          (StringBuffer buffer) {
        buffer.write('<h3>Configuration</h3>');

        _writeColumns(buffer, <HtmlGenerator>[
          (StringBuffer buffer) {
            buffer.write('<p><b>Context Options</b></p>');
            writeOptions(buffer, context.analysisOptions);
          },
          (StringBuffer buffer) {
            buffer.write('<p><b>SDK Context Options</b></p>');
            DartSdk sdk = context?.sourceFactory?.dartSdk;
            writeOptions(buffer, sdk?.context?.analysisOptions,
                writeAdditionalOptions: (StringBuffer buffer) {
              if (sdk is FolderBasedDartSdk) {
                _writeOption(buffer, 'Use summaries', sdk.useSummary);
              }
            });
          },
          (StringBuffer buffer) {
            List<Linter> lints = context.analysisOptions.lintRules;
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
                context.analysisOptions.errorProcessors;
            int processorCount = errorProcessors?.length ?? 0;
            buffer
                .write('<p><b>Error Processor count</b>: $processorCount</p>');
          }
        ]);

        SourceFactory sourceFactory = context.sourceFactory;
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
            buffer, 'Priority Files (${priorityNames.length})', priorityNames);
        _writeFiles(
            buffer,
            'Explicitly Analyzed Files (${explicitNames.length})',
            explicitNames);
        _writeFiles(
            buffer,
            'Implicitly Analyzed Files (${implicitNames.length})',
            implicitNames);

        buffer.write('<h3>Exceptions</h3>');
        if (exceptions.isEmpty) {
          buffer.write('<p>none</p>');
        } else {
          exceptions.forEach((CaughtException exception) {
            _writeException(buffer, exception);
          });
        }

        buffer.write('<h3>Targets Without Entries</h3>');
        bool foundEntry = false;
        MapIterator<AnalysisTarget, CacheEntry> iterator =
            context.analysisCache.iterator(context: context);
        while (iterator.moveNext()) {
          if (iterator.value == null) {
            foundEntry = true;
            buffer.write('<p>');
            buffer.write(iterator.key.toString());
            buffer.write(' (');
            buffer.write(iterator.key.runtimeType.toString());
            buffer.write(')</p>');
          }
        }
        if (!foundEntry) {
          buffer.write('<p>none</p>');
        }
      });
    });
  }

  /**
   * Return a response displaying the results of running a validation report on
   * a single context.
   */
  void _returnContextValidationDiagnostics(HttpRequest request) {
    AnalysisServer analysisServer = _server.analysisServer;
    if (analysisServer == null) {
      return _returnFailure(request, 'Analysis server is not running');
    }
    String contextFilter = request.uri.queryParameters[CONTEXT_QUERY_PARAM];
    if (contextFilter == null) {
      return _returnFailure(
          request, 'Query parameter $CONTEXT_QUERY_PARAM required');
    }
    InternalAnalysisContext context = null;
    Folder folder = _findFolder(analysisServer, contextFilter);
    if (folder == null) {
      context = _getSdkContext(analysisServer, contextFilter);
      if (context == null) {
        return _returnFailure(request, 'Invalid context: $contextFilter');
      }
    } else {
      context = analysisServer.folderMap[folder];
    }

    _writeResponse(request, (StringBuffer buffer) {
      _writePage(buffer, 'Analysis Server - Context Validation Diagnostics',
          ['Context: $contextFilter'], (StringBuffer buffer) {
        _writeContextValidationDiagnostics(buffer, context);
      });
    });
  }

  /**
   * Return a response displaying diagnostic information.
   */
  void _returnDiagnosticInfo(HttpRequest request) {
    _writeResponse(request, (StringBuffer buffer) {
      _writePage(buffer, 'Analysis Server - Diagnostic info', [],
          (StringBuffer buffer) {
        _writeDiagnosticStatus(buffer);
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

    InternalAnalysisContext context = analysisServer.folderMap[folder];

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
        CacheEntry entry = context.analysisCache.get(source);
        if (entry == null) {
          buffer.write('<p>Not found.</p>');
          return;
        }
        LibraryElement element = entry.getValue(LIBRARY_ELEMENT);
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

  void _returnMemoryUsage(HttpRequest request) {
    _writeResponse(request, (StringBuffer buffer) {
      _writePage(buffer, 'Analysis Server - Memory Use', [],
          (StringBuffer buffer) {
        AnalysisServer server = _server.analysisServer;
        MemoryUseData data = new MemoryUseData();
        data.processAnalysisServer(server);
        Map<Type, Set> instances = data.instances;
        List<Type> instanceTypes = instances.keys.toList();
        instanceTypes.sort((Type left, Type right) =>
            left.toString().compareTo(right.toString()));
        Map<Type, Set> ownerMap = data.ownerMap;
        List<Type> ownerTypes = ownerMap.keys.toList();
        ownerTypes.sort((Type left, Type right) =>
            left.toString().compareTo(right.toString()));

        _writeTwoColumns(buffer, (StringBuffer buffer) {
          buffer.write('<h3>Instance Counts (reachable from contexts)</h3>');
          buffer.write('<table>');
          _writeRow(buffer, ['Count', 'Class name'], header: true);
          instanceTypes.forEach((Type type) {
            _writeRow(buffer, [instances[type].length, type],
                classes: ['right', null]);
          });
          buffer.write('</table>');

          buffer.write(
              '<h3>Ownership (which classes of objects hold on to others)</h3>');
          buffer.write('<table>');
          _writeRow(buffer, ['Referenced Type', 'Referencing Types'],
              header: true);
          ownerTypes.forEach((Type type) {
            List<String> referencingTypes =
                ownerMap[type].map((Type type) => type.toString()).toList();
            referencingTypes.sort();
            _writeRow(buffer, [type, referencingTypes.join('<br>')]);
          });
          buffer.write('</table>');

          buffer.write('<h3>Other Data</h3>');
          buffer.write('<p>');
          buffer.write(data.uniqueTargetedResults.length);
          buffer.write(' non-equal TargetedResults</p>');
          buffer.write('<p>');
          buffer.write(data.uniqueLSUs.length);
          buffer.write(' non-equal LibrarySpecificUnits</p>');
          int count = data.mismatchedTargets.length;
          buffer.write('<p>');
          buffer.write(count);
          buffer.write(' mismatched targets</p>');
          if (count < 100) {
            for (AnalysisTarget target in data.mismatchedTargets) {
              buffer.write(target);
              buffer.write('<br>');
            }
          }
        }, (StringBuffer buffer) {
          void writeCountMap(String title, Map<Type, int> counts) {
            List<Type> classNames = counts.keys.toList();
            classNames.sort((Type left, Type right) =>
                left.toString().compareTo(right.toString()));

            buffer.write('<h3>$title</h3>');
            buffer.write('<table>');
            _writeRow(buffer, ['Count', 'Class name'], header: true);
            classNames.forEach((Type type) {
              _writeRow(buffer, [counts[type], type], classes: ['right', null]);
            });
            buffer.write('</table>');
          }

          writeCountMap('Directly Held AST Nodes', data.directNodeCounts);
          writeCountMap('Indirectly Held AST Nodes', data.indirectNodeCounts);
          writeCountMap('Directly Held Elements', data.elementCounts);
        });
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
      buffer.write('<p>Using package resolver provider: ');
      buffer.write(_server.packageResolverProvider != null);
      buffer.write('</p>');
      buffer.write('<p>');
      buffer.write(makeLink(OVERLAYS_PATH, {}, 'All overlay information'));
      buffer.write('</p>');

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
        buffer.write(makeLink(CONTEXT_PATH, {CONTEXT_QUERY_PARAM: folder.path},
            key, _hasException(folderMap[folder])));
        buffer.write(' <small><b>[');
        buffer.write(makeLink(CONTEXT_DIAGNOSTICS_PATH,
            {CONTEXT_QUERY_PARAM: folder.path}, 'diagnostics'));
        buffer.write(']</b></small>');
        if (!folder.getChild('.packages').exists) {
          buffer.write(' <small>[no .packages file]</small>');
        }
      });
      buffer.write('</p>');
      buffer.write('<p><b>SDK Contexts</b></p>');
      buffer.write('<p>');
      first = true;
      DartSdkManager manager = analysisServer.sdkManager;
      List<SdkDescription> descriptors = manager.sdkDescriptors;
      if (descriptors.isEmpty) {
        buffer.write('none');
      } else {
        Map<String, SdkDescription> sdkMap = <String, SdkDescription>{};
        for (SdkDescription descriptor in descriptors) {
          sdkMap[descriptor.toString()] = descriptor;
        }
        List<String> descriptorNames = sdkMap.keys.toList();
        descriptorNames.sort();
        for (String name in descriptorNames) {
          if (first) {
            first = false;
          } else {
            buffer.write('<br>');
          }
          SdkDescription descriptor = sdkMap[name];
          String contextId = _encodeSdkDescriptor(descriptor);
          buffer.write(makeLink(
              CONTEXT_PATH,
              {CONTEXT_QUERY_PARAM: contextId},
              name,
              _hasException(manager.getSdk(descriptor, () => null)?.context)));
          buffer.write(' <small><b>[');
          buffer.write(makeLink(CONTEXT_DIAGNOSTICS_PATH,
              {CONTEXT_QUERY_PARAM: contextId}, 'diagnostics'));
          buffer.write(']</b></small>');
        }
      }
      buffer.write('</p>');

      int freq = AnalysisServer.performOperationDelayFrequency;
      String delay = freq > 0 ? '1 ms every $freq ms' : 'off';

      buffer.write('<p><b>Performance Data</b></p>');
      buffer.write('<p>Perform operation delay: $delay</p>');
      buffer.write('<p>');
      buffer.write(makeLink(ANALYSIS_PERFORMANCE_PATH, {}, 'Task data'));
      buffer.write('</p>');
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
   * Write diagnostic information about the given [context] to the given
   * [buffer].
   */
  void _writeContextDiagnostics(StringBuffer buffer,
      InternalAnalysisContext context, String contextFilter) {
    AnalysisDriver driver = (context as AnalysisContextImpl).driver;
    List<WorkItem> workItems = driver.currentWorkOrder?.workItems;

    buffer.write('<p>');
    buffer.write(makeLink(CONTEXT_VALIDATION_DIAGNOSTICS_PATH,
        {CONTEXT_QUERY_PARAM: contextFilter}, 'Run validation'));
    buffer.write('</p>');

    buffer.write('<h3>Most Recently Perfomed Tasks</h3>');
    AnalysisTask.LAST_TASKS.forEach((String description) {
      buffer.write('<p>');
      buffer.write(description);
      buffer.write('</p>');
    });

    void writeWorkItem(StringBuffer buffer, WorkItem item) {
      if (item == null) {
        buffer.write('none');
      } else {
        buffer.write(item.descriptor?.name);
        buffer.write(' computing ');
        buffer.write(item.spawningResult?.name);
        buffer.write(' for ');
        buffer.write(item.target);
      }
    }

    buffer.write('<h3>Work Items</h3>');
    buffer.write('<p><b>Current:</b> ');
    writeWorkItem(buffer, driver.currentWorkOrder?.current);
    buffer.write('</p>');
    if (workItems != null) {
      workItems.reversed.forEach((WorkItem item) {
        buffer.write('<p>');
        writeWorkItem(buffer, item);
        buffer.write('</p>');
      });
    }
  }

  /**
   * Write diagnostic information about the given [context] to the given
   * [buffer].
   */
  void _writeContextValidationDiagnostics(
      StringBuffer buffer, InternalAnalysisContext context) {
    Stopwatch stopwatch = new Stopwatch();
    stopwatch.start();
    ValidationResults results = new ValidationResults(context);
    stopwatch.stop();

    buffer.write('<h3>Validation Results</h3>');
    buffer.write('<p>Re-analysis took ');
    buffer.write(stopwatch.elapsedMilliseconds);
    buffer.write(' ms</p>');
    results.writeOn(buffer);
  }

  /**
   * Write the status of the diagnostic domain to the given [buffer].
   */
  void _writeDiagnosticStatus(StringBuffer buffer) {
    var request = new DiagnosticGetDiagnosticsParams().toRequest('0');

    var stopwatch = new Stopwatch();
    stopwatch.start();
    var response = diagnosticHandler.handleRequest(request);
    stopwatch.stop();

    int elapsedMs = stopwatch.elapsedMilliseconds;
    _diagnosticCallAverage.addSample(elapsedMs);

    buffer.write('<h3>Timing</h3>');

    buffer.write('<p>getDiagnostic (last call): ');
    buffer.write(elapsedMs);
    buffer.write(' (ms)</p>');
    buffer.write('<p>getDiagnostic (rolling average): ');
    buffer.write(_diagnosticCallAverage.value);
    buffer.write(' (ms)</p>&nbsp;');

    Map json = response.toJson()[Response.RESULT];
    List contexts = json['contexts'];
    contexts.sort((first, second) => first['name'].compareTo(second['name']));

    // Track visited libraries.
    Set<LibraryElement> libraries = new HashSet<LibraryElement>();

    // Count SDK elements separately.
    ElementCounter sdkCounter = new ElementCounter();

    for (var context in contexts) {
      buffer.write('<p><h3>');
      buffer.write(context['name']);
      buffer.write('</h3></p>');
      buffer.write('<p>explicitFileCount: ');
      buffer.write(context['explicitFileCount']);
      buffer.write('</p>');
      buffer.write('<p>implicitFileCount: ');
      buffer.write(context['implicitFileCount']);
      buffer.write('</p>');
      buffer.write('<p>workItemQueueLength: ');
      buffer.write(context['workItemQueueLength']);
      buffer.write('</p>');

      AnalysisServer server = _server.analysisServer;

      if (server != null) {
        Folder folder = _findFolder(server, context['name']);
        InternalAnalysisContext ac = _server.analysisServer.folderMap[folder];
        ElementCounter counter = new ElementCounter();

        for (Source source in ac.librarySources) {
          LibraryElement libraryElement = ac.getLibraryElement(source);
          if (libraries.add(libraryElement)) {
            if (libraryElement != null) {
              if (libraryElement.isInSdk) {
                libraryElement.accept(sdkCounter);
              } else {
                libraryElement.accept(counter);
              }
            }
          }
        }
        buffer.write('<p>element count: ');
        buffer.write(counter.counts.values
            .fold<int>(0, (int prev, int element) => prev + element));
        buffer.write('</p>');
        buffer.write('<p>  (w/docs): ');
        buffer.write(counter.elementsWithDocs);
        buffer.write('</p>');
        buffer.write('<p>total doc span: ');
        buffer.write(counter.totalDocSpan);
        buffer.write('</p>');
      }
    }

    buffer.write('<p><h3>');
    buffer.write('SDK');
    buffer.write('</h3></p>');
    buffer.write('<p>element count: ');
    buffer.write(sdkCounter.counts.values
        .fold<int>(0, (int prev, int element) => prev + element));
    buffer.write('</p>');
    buffer.write('<p>  (w/docs): ');
    buffer.write(sdkCounter.elementsWithDocs);
    buffer.write('</p>');
    buffer.write('<p>total doc span: ');
    buffer.write(sdkCounter.totalDocSpan);
    buffer.write('</p>');
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

  void _writeListItem(StringBuffer buffer, writer()) {
    buffer.write('<li>');
    writer();
    buffer.write('</li>');
  }

  void _writeListOfStrings(
      StringBuffer buffer, String listName, Iterable<String> items) {
    List<String> itemList = items.toList();
    itemList.sort((String a, String b) {
      a = a.toLowerCase();
      b = b.toLowerCase();
      return a.compareTo(b);
    });
    buffer.write('List "$listName" containing ${itemList.length} entries:');
    buffer.write('<ul>');
    for (String member in itemList) {
      _writeListItem(buffer, () {
        buffer.write(member);
      });
    }
    buffer.write('</ul>');
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
        return;
      }
      buffer.write('<p>');
      buffer.write('Status: Running<br>');
      buffer.write('New analysis driver: ');
      buffer.write(analysisServer.options.enableNewAnalysisDriver);
      buffer.write('<br>');
      buffer.write('Instrumentation: ');
      if (AnalysisEngine.instance.instrumentationService.isActive) {
        buffer.write('<span style="color:red">Active</span>');
      } else {
        buffer.write('Inactive');
      }
      buffer.write('<br>');
      buffer.write('Server version: ');
      buffer.write(AnalysisServer.VERSION);
      buffer.write('<br>');
      buffer.write('SDK: ');
      buffer.write(Platform.version);
      buffer.write('<br>');
      buffer.write('Process ID: ');
      buffer.write(pid);
      buffer.write('</p>');

      buffer.write('<p><b>Performance Data</b></p>');
      buffer.write('<p>');
      buffer.write(makeLink(
          COMMUNICATION_PERFORMANCE_PATH, {}, 'Communication performance'));
      buffer.write('</p>');
      buffer.write('<p>');
      buffer.write(makeLink(DIAGNOSTIC_PATH, {}, 'General diagnostics'));
      buffer.write('</p>');
      buffer.write('<p>');
      buffer.write(makeLink(MEMORY_USE_PATH, {}, 'Memory usage'));
      buffer.write(' <small>(long running)</small></p>');
    }, (StringBuffer buffer) {
      _writeSubscriptionList(buffer, ServerService.VALUES, services);
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
   * Write the targeted results returned by iterating over the [results] to the
   * given [buffer]. The list will have the given [title] written before it.
   */
  void _writeTargetedResults(
      StringBuffer buffer, String title, Iterable<TargetedResult> results) {
    List<TargetedResult> sortedResults = results.toList();
    sortedResults.sort((TargetedResult first, TargetedResult second) {
      int nameOrder =
          first.result.toString().compareTo(second.result.toString());
      if (nameOrder != 0) {
        return nameOrder;
      }
      return first.target.toString().compareTo(second.target.toString());
    });

    buffer.write('<p>');
    buffer.write(title);
    buffer.write('</p><blockquote>');
    if (results.isEmpty) {
      buffer.write('nothing');
    } else {
      for (TargetedResult result in sortedResults) {
        buffer.write('<p>');
        buffer.write(result.result.toString());
        buffer.write(' of ');
        buffer.write(result.target.toString());
        buffer.write('<p>');
      }
    }
    buffer.write('</blockquote>');
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
        _writeListItem(buffer, () {
          _writeValueAsHtml(buffer, entry, linkParameters);
        });
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
    } else if (value is UsedLocalElements) {
      buffer.write('<ul>');
      _writeListItem(buffer, () {
        HashSet<Element> elements = value.elements;
        buffer.write('List "elements" containing ${elements.length} entries');
        buffer.write('<ul>');
        for (Element element in elements) {
          _writeListItem(buffer, () {
            String elementStr = HTML_ESCAPE.convert(element.toString());
            buffer.write('<i>${element.runtimeType}</i>  $elementStr');
          });
        }
        buffer.write('</ul>');
      });
      _writeListItem(buffer, () {
        _writeListOfStrings(buffer, 'members', value.members);
      });
      _writeListItem(buffer, () {
        _writeListOfStrings(buffer, 'readMembers', value.readMembers);
      });
      buffer.write('</ul>');
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
