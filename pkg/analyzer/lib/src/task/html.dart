// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.task.html;

import 'dart:collection';

import 'package:analyzer/error/error.dart';
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/src/context/cache.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/plugin/engine_plugin.dart';
import 'package:analyzer/src/task/general.dart';
import 'package:analyzer/task/dart.dart';
import 'package:analyzer/task/general.dart';
import 'package:analyzer/task/html.dart';
import 'package:analyzer/task/model.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:source_span/source_span.dart';

/**
 * The Dart scripts that are embedded in an HTML file.
 */
final ListResultDescriptor<DartScript> DART_SCRIPTS =
    new ListResultDescriptor<DartScript>('DART_SCRIPTS', DartScript.EMPTY_LIST);

/**
 * The errors found while parsing an HTML file.
 */
final ListResultDescriptor<AnalysisError> HTML_DOCUMENT_ERRORS =
    new ListResultDescriptor<AnalysisError>(
        'HTML_DOCUMENT_ERRORS', AnalysisError.NO_ERRORS);

/**
 * A Dart script that is embedded in an HTML file.
 */
class DartScript implements Source {
  /**
   * An empty list of scripts.
   */
  static final List<DartScript> EMPTY_LIST = <DartScript>[];

  /**
   * The source containing this script.
   */
  final Source source;

  /**
   * The fragments that comprise this content of the script.
   */
  final List<ScriptFragment> fragments;

  /**
   * Initialize a newly created script in the given [source] that is composed of
   * given [fragments].
   */
  DartScript(this.source, this.fragments);

  @override
  TimestampedData<String> get contents =>
      new TimestampedData(modificationStamp, fragments[0].content);

  @override
  String get encoding => source.encoding;

  @override
  String get fullName => source.fullName;

  @override
  bool get isInSystemLibrary => source.isInSystemLibrary;

  @override
  Source get librarySource => source;

  @override
  int get modificationStamp => source.modificationStamp;

  @override
  String get shortName => source.shortName;

  @override
  Uri get uri => source.uri
      .replace(queryParameters: {'offset': fragments[0].offset.toString()});

  @override
  UriKind get uriKind =>
      throw new StateError('uriKind not supported for scripts');

  @override
  bool exists() => source.exists();
}

/**
 * A task that looks for Dart scripts in an HTML file and computes both the Dart
 * libraries that are referenced by those scripts and the embedded Dart scripts.
 */
class DartScriptsTask extends SourceBasedAnalysisTask {
  /**
   * The name of the [HTML_DOCUMENT] input.
   */
  static const String DOCUMENT_INPUT = 'DOCUMENT';

  /**
   * The task descriptor describing this kind of task.
   */
  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor(
      'DartScriptsTask',
      createTask,
      buildInputs,
      <ResultDescriptor>[DART_SCRIPTS, REFERENCED_LIBRARIES]);

  DartScriptsTask(InternalAnalysisContext context, AnalysisTarget target)
      : super(context, target);

  @override
  TaskDescriptor get descriptor => DESCRIPTOR;

  @override
  void internalPerform() {
    //
    // Prepare inputs.
    //
    Source source = target.source;
    Document document = getRequiredInput(DOCUMENT_INPUT);
    //
    // Process the script tags.
    //
    List<Source> libraries = <Source>[];
    List<DartScript> inlineScripts = <DartScript>[];
    List<Element> scripts = document.getElementsByTagName('script');
    for (Element script in scripts) {
      LinkedHashMap<dynamic, String> attributes = script.attributes;
      if (attributes['type'] == 'application/dart') {
        String src = attributes['src'];
        if (src == null) {
          if (script.hasContent()) {
            List<ScriptFragment> fragments = <ScriptFragment>[];
            for (Node node in script.nodes) {
              if (node.nodeType == Node.TEXT_NODE) {
                FileLocation start = node.sourceSpan.start;
                fragments.add(new ScriptFragment(start.offset, start.line,
                    start.column, (node as Text).data));
              }
            }
            inlineScripts.add(new DartScript(source, fragments));
          }
        } else if (AnalysisEngine.isDartFileName(src)) {
          Source source = context.sourceFactory.resolveUri(target.source, src);
          if (source != null) {
            libraries.add(source);
          }
        }
      }
    }
    //
    // Record outputs.
    //
    outputs[REFERENCED_LIBRARIES] =
        libraries.isEmpty ? Source.EMPTY_LIST : libraries;
    outputs[DART_SCRIPTS] =
        inlineScripts.isEmpty ? DartScript.EMPTY_LIST : inlineScripts;
  }

  /**
   * Return a map from the names of the inputs of this kind of task to the task
   * input descriptors describing those inputs for a task with the
   * given [target].
   */
  static Map<String, TaskInput> buildInputs(AnalysisTarget target) {
    return <String, TaskInput>{DOCUMENT_INPUT: HTML_DOCUMENT.of(target)};
  }

  /**
   * Create a [DartScriptsTask] based on the given [target] in the given
   * [context].
   */
  static DartScriptsTask createTask(
      AnalysisContext context, AnalysisTarget target) {
    return new DartScriptsTask(context, target);
  }
}

/**
 * A task that merges all of the errors for a single source into a single list
 * of errors.
 */
class HtmlErrorsTask extends SourceBasedAnalysisTask {
  /**
   * The suffix to add to the names of contributed error results.
   */
  static const String INPUT_SUFFIX = '_input';

  /**
   * The name of the input that is a list of errors from each of the embedded
   * Dart scripts.
   */
  static const String DART_ERRORS_INPUT = 'DART_ERRORS';

  /**
   * The task descriptor describing this kind of task.
   */
  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor('HtmlErrorsTask',
      createTask, buildInputs, <ResultDescriptor>[HTML_ERRORS]);

  HtmlErrorsTask(InternalAnalysisContext context, AnalysisTarget target)
      : super(context, target);

  @override
  TaskDescriptor get descriptor => DESCRIPTOR;

  @override
  void internalPerform() {
    EnginePlugin enginePlugin = AnalysisEngine.instance.enginePlugin;
    //
    // Prepare inputs.
    //
    List<List<AnalysisError>> dartErrors = getRequiredInput(DART_ERRORS_INPUT);
    List<List<AnalysisError>> htmlErrors = <List<AnalysisError>>[];
    for (ResultDescriptor result in enginePlugin.htmlErrors) {
      String inputName = result.name + INPUT_SUFFIX;
      htmlErrors.add(getRequiredInput(inputName));
    }
    //
    // Compute the error list.
    //
    List<List<AnalysisError>> errorLists = <List<AnalysisError>>[];
    errorLists.addAll(dartErrors);
    errorLists.addAll(htmlErrors);
    //
    // Record outputs.
    //
    outputs[HTML_ERRORS] = AnalysisError.mergeLists(errorLists);
  }

  /**
   * Return a map from the names of the inputs of this kind of task to the task
   * input descriptors describing those inputs for a task with the
   * given [target].
   */
  static Map<String, TaskInput> buildInputs(AnalysisTarget target) {
    EnginePlugin enginePlugin = AnalysisEngine.instance.enginePlugin;
    Map<String, TaskInput> inputs = <String, TaskInput>{
      DART_ERRORS_INPUT: DART_SCRIPTS.of(target).toListOf(DART_ERRORS)
    };
    for (ResultDescriptor result in enginePlugin.htmlErrors) {
      String inputName = result.name + INPUT_SUFFIX;
      inputs[inputName] = result.of(target);
    }
    return inputs;
  }

  /**
   * Create an [HtmlErrorsTask] based on the given [target] in the given
   * [context].
   */
  static HtmlErrorsTask createTask(
      AnalysisContext context, AnalysisTarget target) {
    return new HtmlErrorsTask(context, target);
  }
}

/**
 * A task that scans the content of a file, producing a set of Dart tokens.
 */
class ParseHtmlTask extends SourceBasedAnalysisTask {
  /**
   * The name of the input whose value is the content of the file.
   */
  static const String CONTENT_INPUT_NAME = 'CONTENT_INPUT_NAME';

  /**
   * The name of the input whose value is the modification time of the file.
   */
  static const String MODIFICATION_TIME_INPUT = 'MODIFICATION_TIME_INPUT';

  /**
   * The task descriptor describing this kind of task.
   */
  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor(
      'ParseHtmlTask',
      createTask,
      buildInputs,
      <ResultDescriptor>[HTML_DOCUMENT, HTML_DOCUMENT_ERRORS, LINE_INFO],
      suitabilityFor: suitabilityFor);

  /**
   * Initialize a newly created task to access the content of the source
   * associated with the given [target] in the given [context].
   */
  ParseHtmlTask(InternalAnalysisContext context, AnalysisTarget target)
      : super(context, target);

  @override
  TaskDescriptor get descriptor => DESCRIPTOR;

  @override
  void internalPerform() {
    String content = getRequiredInput(CONTENT_INPUT_NAME);

    int modificationTime = getRequiredInput(MODIFICATION_TIME_INPUT);
    if (modificationTime < 0) {
      String message = 'Content could not be read';
      if (context is InternalAnalysisContext) {
        CacheEntry entry =
            (context as InternalAnalysisContext).getCacheEntry(target);
        CaughtException exception = entry.exception;
        if (exception != null) {
          message = exception.toString();
        }
      }

      outputs[HTML_DOCUMENT] = new Document();
      outputs[HTML_DOCUMENT_ERRORS] = <AnalysisError>[
        new AnalysisError(
            target.source, 0, 0, ScannerErrorCode.UNABLE_GET_CONTENT, [message])
      ];
      outputs[LINE_INFO] = new LineInfo(<int>[0]);
    } else {
      HtmlParser parser = new HtmlParser(content,
          generateSpans: true, lowercaseAttrName: false);
      parser.compatMode = 'quirks';
      Document document = parser.parse();
      //
      // Convert errors.
      //
      List<AnalysisError> errors = <AnalysisError>[];
      // TODO(scheglov) https://github.com/dart-lang/sdk/issues/24643
//      List<ParseError> parseErrors = parser.errors;
//      for (ParseError parseError in parseErrors) {
//        if (parseError.errorCode == 'expected-doctype-but-got-start-tag') {
//          continue;
//        }
//        SourceSpan span = parseError.span;
//        errors.add(new AnalysisError(target.source, span.start.offset,
//            span.length, HtmlErrorCode.PARSE_ERROR, [parseError.message]));
//      }
      //
      // Record outputs.
      //
      outputs[HTML_DOCUMENT] = document;
      outputs[HTML_DOCUMENT_ERRORS] = errors;
      outputs[LINE_INFO] = _computeLineInfo(content);
    }
  }

  /**
   * Return a map from the names of the inputs of this kind of task to the task
   * input descriptors describing those inputs for a task with the given
   * [source].
   */
  static Map<String, TaskInput> buildInputs(AnalysisTarget source) {
    return <String, TaskInput>{
      CONTENT_INPUT_NAME: CONTENT.of(source),
      MODIFICATION_TIME_INPUT: MODIFICATION_TIME.of(source)
    };
  }

  /**
   * Create a [ParseHtmlTask] based on the given [target] in the given [context].
   */
  static ParseHtmlTask createTask(
      AnalysisContext context, AnalysisTarget target) {
    return new ParseHtmlTask(context, target);
  }

  /**
   * Return an indication of how suitable this task is for the given [target].
   */
  static TaskSuitability suitabilityFor(AnalysisTarget target) {
    if (target is Source) {
      String name = target.shortName;
      if (name.endsWith(AnalysisEngine.SUFFIX_HTML) ||
          name.endsWith(AnalysisEngine.SUFFIX_HTM)) {
        return TaskSuitability.HIGHEST;
      }
    }
    return TaskSuitability.NONE;
  }

  /**
   * Compute [LineInfo] for the given [content].
   */
  static LineInfo _computeLineInfo(String content) {
    List<int> lineStarts = StringUtilities.computeLineStarts(content);
    return new LineInfo(lineStarts);
  }
}

/**
 * A fragment of a [DartScript].
 */
class ScriptFragment {
  /**
   * The offset of the first character of the fragment, relative to the start of
   * the containing source.
   */
  final int offset;

  /**
   * The line number of the line containing the first character of the fragment.
   */
  final int line;

  /**
   * The column number of the line containing the first character of the
   * fragment.
   */
  final int column;

  /**
   * The content of the fragment.
   */
  final String content;

  /**
   * Initialize a newly created script fragment to have the given [offset] and
   * [content].
   */
  ScriptFragment(this.offset, this.line, this.column, this.content);
}
