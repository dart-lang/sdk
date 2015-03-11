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
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/task/general.dart';
import 'package:analyzer/src/task/inputs.dart';
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
      'BUILD_COMPILATION_UNIT_ELEMENT', createTask, buildInputs,
      <ResultDescriptor>[COMPILATION_UNIT_ELEMENT, BUILT_UNIT]);

  /**
   * Initialize a newly created task to build a compilation unit element for
   * the given [target] in the given [context].
   */
  BuildCompilationUnitElementTask(
      InternalAnalysisContext context, AnalysisTarget target)
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
  static BuildCompilationUnitElementTask createTask(
      AnalysisContext context, AnalysisTarget target) {
    return new BuildCompilationUnitElementTask(context, target);
  }
}

/**
 * A task that builds a library element for a Dart library.
 */
class BuildLibraryElementTask extends SourceBasedAnalysisTask {
  /**
   * The name of the input whose value is the built compilation unit of the
   * defining compilation unit of a library.
   */
  static const String DEFINING_BUILT_UNIT_INPUT_NAME = 'definingBuiltUnit';

  /**
   * The name of the input whose value is a list of built compilation units
   * of the parts sourced by a library.
   */
  static const String PART_BUILT_UNITS_INPUT_NAME = 'partBuiltUnits';

  /**
   * The task descriptor describing this kind of task.
   */
  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor(
      'BUILD_LIBRARY_ELEMENT', createTask, buildInputs, <ResultDescriptor>[
    BUILD_LIBRARY_ERRORS,
    BUILT_LIBRARY_ELEMENT,
    IS_LAUNCHABLE,
    HAS_HTML_IMPORT
  ]);

  /**
   * Initialize a newly created task to build a library element for the given
   * [target] in the given [context].
   */
  BuildLibraryElementTask(
      InternalAnalysisContext context, AnalysisTarget target)
      : super(context, target);

  @override
  TaskDescriptor get descriptor => DESCRIPTOR;

  @override
  void internalPerform() {
    List<AnalysisError> errors = <AnalysisError>[];
    //
    // Prepare inputs.
    //
    Source librarySource = getRequiredSource();
    CompilationUnit definingCompilationUnit =
        getRequiredInput(DEFINING_BUILT_UNIT_INPUT_NAME);
    List<CompilationUnit> partUnits =
        getRequiredInput(PART_BUILT_UNITS_INPUT_NAME);
    //
    // Process inputs.
    //
    CompilationUnitElementImpl definingCompilationUnitElement =
        definingCompilationUnit.element;
    Map<Source, CompilationUnit> partUnitMap =
        new HashMap<Source, CompilationUnit>();
    for (CompilationUnit partUnit in partUnits) {
      Source partSource = partUnit.element.source;
      partUnitMap[partSource] = partUnit;
    }
    Source htmlSource = context.sourceFactory.forUri(DartSdk.DART_HTML);
    //
    // Update "part" directives.
    //
    LibraryIdentifier libraryNameNode = null;
    bool hasHtmlImport = false;
    bool hasPartDirective = false;
    FunctionElement entryPoint =
        _findEntryPoint(definingCompilationUnitElement);
    List<Directive> directivesToResolve = <Directive>[];
    List<CompilationUnitElementImpl> sourcedCompilationUnits =
        <CompilationUnitElementImpl>[];
    for (Directive directive in definingCompilationUnit.directives) {
      if (directive is ImportDirective) {
        hasHtmlImport = hasHtmlImport || directive.source == htmlSource;
      } else if (directive is LibraryDirective) {
        if (libraryNameNode == null) {
          libraryNameNode = directive.name;
          directivesToResolve.add(directive);
        }
      } else if (directive is PartDirective) {
        PartDirective partDirective = directive;
        StringLiteral partUri = partDirective.uri;
        Source partSource = partDirective.source;
        if (context.exists(partSource)) {
          hasPartDirective = true;
          CompilationUnit partUnit = partUnitMap[partSource];
          CompilationUnitElementImpl partElement = partUnit.element;
          partElement.uriOffset = partUri.offset;
          partElement.uriEnd = partUri.end;
          partElement.uri = partDirective.uriContent;
          //
          // Validate that the part contains a part-of directive with the same
          // name as the library.
          //
          String partLibraryName =
              _getPartLibraryName(partSource, partUnit, directivesToResolve);
          if (partLibraryName == null) {
            errors.add(new AnalysisError.con2(librarySource, partUri.offset,
                partUri.length, CompileTimeErrorCode.PART_OF_NON_PART, [
              partUri.toSource()
            ]));
          } else if (libraryNameNode == null) {
            // TODO(brianwilkerson) Collect the names declared by the part.
            // If they are all the same then we can use that name as the
            // inferred name of the library and present it in a quick-fix.
            // partLibraryNames.add(partLibraryName);
          } else if (libraryNameNode.name != partLibraryName) {
            errors.add(new AnalysisError.con2(librarySource, partUri.offset,
                partUri.length, StaticWarningCode.PART_OF_DIFFERENT_LIBRARY, [
              libraryNameNode.name,
              partLibraryName
            ]));
          }
          if (entryPoint == null) {
            entryPoint = _findEntryPoint(partElement);
          }
          directive.element = partElement;
          sourcedCompilationUnits.add(partElement);
        }
      }
    }
    if (hasPartDirective && libraryNameNode == null) {
      errors.add(new AnalysisError.con1(librarySource,
          ResolverErrorCode.MISSING_LIBRARY_DIRECTIVE_WITH_PART));
    }
    //
    // Create and populate the library element.
    //
    LibraryElementImpl libraryElement =
        new LibraryElementImpl.forNode(context, libraryNameNode);
    libraryElement.definingCompilationUnit = definingCompilationUnitElement;
    libraryElement.entryPoint = entryPoint;
    libraryElement.parts = sourcedCompilationUnits;
    for (Directive directive in directivesToResolve) {
      directive.element = libraryElement;
    }
    if (sourcedCompilationUnits.isNotEmpty) {
      _patchTopLevelAccessors(libraryElement);
    }
    //
    // Record outputs.
    //
    outputs[BUILD_LIBRARY_ERRORS] = errors;
    outputs[BUILT_LIBRARY_ELEMENT] = libraryElement;
    outputs[IS_LAUNCHABLE] = entryPoint != null;
    outputs[HAS_HTML_IMPORT] = hasHtmlImport;
  }

  /**
   * Add all of the non-synthetic [getters] and [setters] defined in the given
   * [unit] that have no corresponding accessor to one of the given collections.
   */
  void _collectAccessors(Map<String, PropertyAccessorElement> getters,
      List<PropertyAccessorElement> setters, CompilationUnitElement unit) {
    for (PropertyAccessorElement accessor in unit.accessors) {
      if (accessor.isGetter) {
        if (!accessor.isSynthetic && accessor.correspondingSetter == null) {
          getters[accessor.displayName] = accessor;
        }
      } else {
        if (!accessor.isSynthetic && accessor.correspondingGetter == null) {
          setters.add(accessor);
        }
      }
    }
  }

  /**
   * Return the top-level [FunctionElement] entry point, or `null` if the given
   * [element] does not define an entry point.
   */
  FunctionElement _findEntryPoint(CompilationUnitElementImpl element) {
    for (FunctionElement function in element.functions) {
      if (function.isEntryPoint) {
        return function;
      }
    }
    return null;
  }

  /**
   * Return the name of the library that the given part is declared to be a
   * part of, or `null` if the part does not contain a part-of directive.
   */
  String _getPartLibraryName(Source partSource, CompilationUnit partUnit,
      List<Directive> directivesToResolve) {
    for (Directive directive in partUnit.directives) {
      if (directive is PartOfDirective) {
        directivesToResolve.add(directive);
        LibraryIdentifier libraryName = directive.libraryName;
        if (libraryName != null) {
          return libraryName.name;
        }
      }
    }
    return null;
  }

  /**
   * Look through all of the compilation units defined for the given [library],
   * looking for getters and setters that are defined in different compilation
   * units but that have the same names. If any are found, make sure that they
   * have the same variable element.
   */
  void _patchTopLevelAccessors(LibraryElementImpl library) {
    HashMap<String, PropertyAccessorElement> getters =
        new HashMap<String, PropertyAccessorElement>();
    List<PropertyAccessorElement> setters = <PropertyAccessorElement>[];
    _collectAccessors(getters, setters, library.definingCompilationUnit);
    for (CompilationUnitElement unit in library.parts) {
      _collectAccessors(getters, setters, unit);
    }
    for (PropertyAccessorElementImpl setter in setters) {
      PropertyAccessorElement getter = getters[setter.displayName];
      if (getter != null) {
        TopLevelVariableElementImpl variable = getter.variable;
        TopLevelVariableElementImpl setterVariable = setter.variable;
        CompilationUnitElementImpl setterUnit = setterVariable.enclosingElement;
        setterUnit.replaceTopLevelVariable(setterVariable, variable);
        variable.setter = setter;
        setter.variable = variable;
      }
    }
  }

  /**
   * Return a map from the names of the inputs of this kind of task to the task
   * input descriptors describing those inputs for a task with the given
   * [target].
   */
  static Map<String, TaskInput> buildInputs(AnalysisTarget target) {
    return <String, TaskInput>{
      DEFINING_BUILT_UNIT_INPUT_NAME: new SimpleTaskInput(target, BUILT_UNIT),
      PART_BUILT_UNITS_INPUT_NAME:
          new ListBasedTaskInput<List<Source>, CompilationUnit>(
              new SimpleTaskInput<List<Source>>(target, INCLUDED_PARTS),
              (Source includedSource) => new SimpleTaskInput<CompilationUnit>(
                  includedSource, BUILT_UNIT))
    };
  }

  /**
   * Create a [BuildLibraryElementTask] based on the given [target] in the
   * given [context].
   */
  static BuildLibraryElementTask createTask(
      AnalysisContext context, AnalysisTarget target) {
    return new BuildLibraryElementTask(context, target);
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
  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor('PARSE_DART',
      createTask, buildInputs, <ResultDescriptor>[
    EXPORTED_LIBRARIES,
    IMPORTED_LIBRARIES,
    INCLUDED_PARTS,
    PARSE_ERRORS,
    PARSED_UNIT,
    SOURCE_KIND
  ]);

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
    parser.parseFunctionBodies = options.analyzeFunctionBodiesPredicate(source);
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
  static ParseDartTask createTask(
      AnalysisContext context, AnalysisTarget target) {
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
      errorListener.onError(new AnalysisError.con2(librarySource,
          uriLiteral.offset, uriLiteral.length,
          CompileTimeErrorCode.URI_WITH_INTERPOLATION));
      return null;
    }
    if (code == UriValidationCode.INVALID_URI) {
      errorListener.onError(new AnalysisError.con2(librarySource,
          uriLiteral.offset, uriLiteral.length,
          CompileTimeErrorCode.INVALID_URI, [uriContent]));
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
  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor('SCAN_DART',
      createTask, buildInputs, <ResultDescriptor>[
    LINE_INFO,
    SCAN_ERRORS,
    TOKEN_STREAM
  ]);

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
    return <String, TaskInput>{CONTENT_INPUT_NAME: CONTENT.inputFor(target)};
  }

  /**
   * Create a [ScanDartTask] based on the given [target] in the given [context].
   */
  static ScanDartTask createTask(
      AnalysisContext context, AnalysisTarget target) {
    return new ScanDartTask(context, target);
  }
}
