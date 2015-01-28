// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.task.dart;

import 'dart:collection';

import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart' hide AnalysisTask;
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/scanner.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/task/general.dart';
import 'package:analyzer/task/dart.dart';
import 'package:analyzer/task/general.dart';
import 'package:analyzer/task/model.dart';

/**
 * A task that builds a compilation unit element for a single compilation unit.
 */
class BuildCompilationUnitElementTask extends SourceBasedAnalysisTask {
  /**
   * The name of the input whose value is the line information for the
   * compilation unit.
   */
  static const String LINE_INFO_INPUT_NAME = "lineInfo";

  /**
   * The name of the input whose value is the AST for the compilation unit.
   */
  static const String PARSED_UNIT_INPUT_NAME = "parsedUnit";

  /**
   * The task descriptor describing this kind of task.
   */
  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor(
      'BUILD_COMPILATION_UNIT_ELEMENT',
      createTask,
      buildInputs,
      <ResultDescriptor>[COMPILATION_UNIT_ELEMENT, BUILT_UNIT]);

  /**
   * Initialize a newly created task to build a compilation unit element for
   * the given [target] in the given [context].
   */
  BuildCompilationUnitElementTask(InternalAnalysisContext context,
      AnalysisTarget target)
      : super(context, target);

  @override
  TaskDescriptor get descriptor => DESCRIPTOR;

  @override
  void internalPerform() {
    Source source = getRequiredSource();
    CompilationUnit unit = getRequiredInput(PARSED_UNIT_INPUT_NAME);

    CompilationUnitBuilder builder = new CompilationUnitBuilder();
    CompilationUnitElement element = builder.buildCompilationUnit(source, unit);

    outputs[COMPILATION_UNIT_ELEMENT] = element;
    outputs[BUILT_UNIT] = unit;
  }

  /**
   * Return a map from the names of the inputs of this kind of task to the task
   * input descriptors describing those inputs for a task with the given [target].
   */
  static Map<String, TaskInput> buildInputs(AnalysisTarget target) {
    return <String, TaskInput>{
      PARSED_UNIT_INPUT_NAME: PARSED_UNIT.inputFor(target)
    };
  }

  /**
   * Create a [BuildCompilationUnitElementTask] based on the given [target] in
   * the given [context].
   */
  static BuildCompilationUnitElementTask createTask(AnalysisContext context,
      AnalysisTarget target) {
    return new BuildCompilationUnitElementTask(context, target);
  }
}

/**
 * A task that parses the content of a Dart file, producing an AST structure.
 */
class ParseDartTask extends SourceBasedAnalysisTask {
  /**
   * The name of the input whose value is the line information produced for the
   * file.
   */
  static const String LINE_INFO_INPUT_NAME = "lineInfo";

  /**
   * The name of the input whose value is the token stream produced for the file.
   */
  static const String TOKEN_STREAM_INPUT_NAME = "tokenStream";

  /**
   * The task descriptor describing this kind of task.
   */
  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor(
      'PARSE_DART',
      createTask,
      buildInputs,
      <ResultDescriptor>[
          EXPORTED_LIBRARIES,
          IMPORTED_LIBRARIES,
          INCLUDED_PARTS,
          PARSE_ERRORS,
          PARSED_UNIT,
          SOURCE_KIND]);

  /**
   * Initialize a newly created task to parse the content of the Dart file
   * associated with the given [target] in the given [context].
   */
  ParseDartTask(InternalAnalysisContext context, AnalysisTarget target)
      : super(context, target);

  @override
  TaskDescriptor get descriptor => DESCRIPTOR;

  @override
  void internalPerform() {
    Source source = getRequiredSource();
    LineInfo lineInfo = getRequiredInput(LINE_INFO_INPUT_NAME);
    Token tokenStream = getRequiredInput(TOKEN_STREAM_INPUT_NAME);

    RecordingErrorListener errorListener = new RecordingErrorListener();
    Parser parser = new Parser(source, errorListener);
    AnalysisOptions options = context.analysisOptions;
    parser.parseFunctionBodies = options.analyzeFunctionBodies;
    CompilationUnit unit = parser.parseCompilationUnit(tokenStream);
    unit.lineInfo = lineInfo;

    bool hasNonPartOfDirective = false;
    bool hasPartOfDirective = false;
    HashSet<Source> exportedSources = new HashSet<Source>();
    HashSet<Source> importedSources = new HashSet<Source>();
    HashSet<Source> includedSources = new HashSet<Source>();
    for (Directive directive in unit.directives) {
      if (directive is PartOfDirective) {
        hasPartOfDirective = true;
      } else {
        hasNonPartOfDirective = true;
        if (directive is UriBasedDirective) {
          Source referencedSource =
              resolveDirective(context, source, directive, errorListener);
          if (referencedSource != null) {
            if (directive is ExportDirective) {
              exportedSources.add(referencedSource);
            } else if (directive is ImportDirective) {
              importedSources.add(referencedSource);
            } else if (directive is PartDirective) {
              if (referencedSource != source) {
                includedSources.add(referencedSource);
              }
            } else {
              throw new AnalysisException(
                  "$runtimeType failed to handle a ${directive.runtimeType}");
            }
          }
        }
      }
    }
    SourceKind sourceKind = SourceKind.LIBRARY;
    if (!hasNonPartOfDirective && hasPartOfDirective) {
      sourceKind = SourceKind.PART;
    }

    outputs[EXPORTED_LIBRARIES] = exportedSources.toList();
    outputs[IMPORTED_LIBRARIES] = importedSources.toList();
    outputs[INCLUDED_PARTS] = includedSources.toList();
    outputs[PARSE_ERRORS] = errorListener.getErrorsForSource(source);
    outputs[PARSED_UNIT] = unit;
    outputs[SOURCE_KIND] = sourceKind;
  }

  /**
   * Return a map from the names of the inputs of this kind of task to the task
   * input descriptors describing those inputs for a task with the given [target].
   */
  static Map<String, TaskInput> buildInputs(AnalysisTarget target) {
    return <String, TaskInput>{
      LINE_INFO_INPUT_NAME: LINE_INFO.inputFor(target),
      TOKEN_STREAM_INPUT_NAME: TOKEN_STREAM.inputFor(target)
    };
  }

  /**
   * Create a [ParseDartTask] based on the given [target] in the given
   * [context].
   */
  static ParseDartTask createTask(AnalysisContext context,
      AnalysisTarget target) {
    return new ParseDartTask(context, target);
  }

  /**
   * Return the result of resolving the URI of the given URI-based [directive]
   * against the URI of the given library, or `null` if the URI is not valid.
   *
   * Resolution is to be performed in the given [context]. Errors should be
   * reported to the [errorListener].
   */
  static Source resolveDirective(AnalysisContext context, Source librarySource,
      UriBasedDirective directive, AnalysisErrorListener errorListener) {
    StringLiteral uriLiteral = directive.uri;
    String uriContent = uriLiteral.stringValue;
    if (uriContent != null) {
      uriContent = uriContent.trim();
      directive.uriContent = uriContent;
    }
    UriValidationCode code = directive.validate();
    if (code == null) {
      String encodedUriContent = Uri.encodeFull(uriContent);
      Source source =
          context.sourceFactory.resolveUri(librarySource, encodedUriContent);
      directive.source = source;
      return source;
    }
    if (code == UriValidationCode.URI_WITH_DART_EXT_SCHEME) {
      return null;
    }
    if (code == UriValidationCode.URI_WITH_INTERPOLATION) {
      errorListener.onError(
          new AnalysisError.con2(
              librarySource,
              uriLiteral.offset,
              uriLiteral.length,
              CompileTimeErrorCode.URI_WITH_INTERPOLATION));
      return null;
    }
    if (code == UriValidationCode.INVALID_URI) {
      errorListener.onError(
          new AnalysisError.con2(
              librarySource,
              uriLiteral.offset,
              uriLiteral.length,
              CompileTimeErrorCode.INVALID_URI,
              [uriContent]));
      return null;
    }
    throw new AnalysisException('Failed to handle validation code: $code');
  }
}

/**
 * A task that scans the content of a file, producing a set of Dart tokens.
 */
class ScanDartTask extends SourceBasedAnalysisTask {
  /**
   * The name of the input whose value is the content of the file.
   */
  static const String CONTENT_INPUT_NAME = "content";

  /**
   * The task descriptor describing this kind of task.
   */
  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor(
      'SCAN_DART',
      createTask,
      buildInputs,
      <ResultDescriptor>[LINE_INFO, SCAN_ERRORS, TOKEN_STREAM]);

  /**
   * Initialize a newly created task to access the content of the source
   * associated with the given [target] in the given [context].
   */
  ScanDartTask(InternalAnalysisContext context, AnalysisTarget target)
      : super(context, target);

  @override
  TaskDescriptor get descriptor => DESCRIPTOR;

  @override
  void internalPerform() {
    Source source = getRequiredSource();
    String content = getRequiredInput(CONTENT_INPUT_NAME);

    RecordingErrorListener errorListener = new RecordingErrorListener();
    Scanner scanner =
        new Scanner(source, new CharSequenceReader(content), errorListener);
    scanner.preserveComments = context.analysisOptions.preserveComments;
    outputs[TOKEN_STREAM] = scanner.tokenize();
    outputs[LINE_INFO] = new LineInfo(scanner.lineStarts);
    outputs[SCAN_ERRORS] = errorListener.getErrorsForSource(source);
  }

  /**
   * Return a map from the names of the inputs of this kind of task to the task
   * input descriptors describing those inputs for a task with the given [target].
   */
  static Map<String, TaskInput> buildInputs(AnalysisTarget target) {
    return <String, TaskInput>{
      CONTENT_INPUT_NAME: CONTENT.inputFor(target)
    };
  }

  /**
   * Create a [ScanDartTask] based on the given [target] in the given [context].
   */
  static ScanDartTask createTask(AnalysisContext context,
      AnalysisTarget target) {
    return new ScanDartTask(context, target);
  }
}
