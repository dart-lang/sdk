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
import 'package:analyzer/src/task/driver.dart';
import 'package:analyzer/src/task/general.dart';
import 'package:analyzer/src/task/inputs.dart';
import 'package:analyzer/task/dart.dart';
import 'package:analyzer/task/general.dart';
import 'package:analyzer/task/model.dart';

/**
 * The errors produced while resolving a library directives.
 *
 * The list will be empty if there were no errors, but will not be `null`.
 *
 * The result is only available for targets representing a Dart library.
 */
final ResultDescriptor<List<AnalysisError>> BUILD_DIRECTIVES_ERRORS =
    new ResultDescriptor<List<AnalysisError>>(
        'BUILD_DIRECTIVES_ERRORS', AnalysisError.NO_ERRORS,
        contributesTo: ANALYSIS_ERRORS);

/**
 * The errors produced while builing a library element.
 *
 * The list will be empty if there were no errors, but will not be `null`.
 *
 * The result is only available for targets representing a Dart library.
 */
final ResultDescriptor<List<AnalysisError>> BUILD_LIBRARY_ERRORS =
    new ResultDescriptor<List<AnalysisError>>(
        'BUILD_LIBRARY_ERRORS', AnalysisError.NO_ERRORS,
        contributesTo: ANALYSIS_ERRORS);

/**
 * The partial [LibraryElement] associated with a library.
 *
 * The [LibraryElement] and its [CompilationUnitElement]s are attached to each
 * other. Directives 'library', 'part' and 'part of' are resolved.
 *
 * The result is only available for targets representing a Dart library.
 */
final ResultDescriptor<LibraryElement> LIBRARY_ELEMENT1 =
    new ResultDescriptor<LibraryElement>('LIBRARY_ELEMENT1', null);

/**
 * The partially resolved [CompilationUnit] associated with a unit.
 *
 * All declarations bound to the element defined by the declaration.
 *
 * The result is only available for targets representing a unit.
 */
final ResultDescriptor<CompilationUnit> RESOLVED_UNIT1 =
    new ResultDescriptor<CompilationUnit>('RESOLVED_UNIT1', null);

/**
 * The partially resolved [CompilationUnit] associated with a unit.
 *
 * Directives 'library', 'part' and 'part of' are resolved.
 *
 * The result is only available for targets representing a library.
 */
final ResultDescriptor<CompilationUnit> RESOLVED_UNIT2 =
    new ResultDescriptor<CompilationUnit>('RESOLVED_UNIT2', null);

/**
 * The partially resolved [CompilationUnit] associated with a library.
 *
 * All the directives are resolved.
 *
 * The result is only available for targets representing a library.
 */
final ResultDescriptor<CompilationUnit> RESOLVED_UNIT3 =
    new ResultDescriptor<CompilationUnit>('RESOLVED_UNIT3', null);

/**
 * The partially resolved [CompilationUnit] associated with a unit.
 *
 * All the enum member elements are built.
 *
 * The result is only available for targets representing a unit.
 */
final ResultDescriptor<CompilationUnit> RESOLVED_UNIT4 =
    new ResultDescriptor<CompilationUnit>('RESOLVED_UNIT4', null);

/**
 * The [TypeProvider] of the context.
 */
final ResultDescriptor<TypeProvider> TYPE_PROVIDER =
    new ResultDescriptor<TypeProvider>('TYPE_PROVIDER', null);

/**
 * A task that builds a compilation unit element for a single compilation unit.
 */
class BuildCompilationUnitElementTask extends SourceBasedAnalysisTask {
  /**
   * The name of the input whose value is the line information for the
   * compilation unit.
   */
  static const String LINE_INFO_INPUT_NAME = 'LINE_INFO_INPUT_NAME';

  /**
   * The name of the input whose value is the AST for the compilation unit.
   */
  static const String PARSED_UNIT_INPUT_NAME = 'PARSED_UNIT_INPUT_NAME';

  /**
   * The task descriptor describing this kind of task.
   */
  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor(
      'BUILD_COMPILATION_UNIT_ELEMENT', createTask, buildInputs,
      <ResultDescriptor>[COMPILATION_UNIT_ELEMENT, RESOLVED_UNIT1]);

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
    outputs[RESOLVED_UNIT1] = unit;
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
 * A task that builds [RESOLVED_UNIT3] for a library.
 */
class BuildDirectiveElementsTask extends SourceBasedAnalysisTask {
  /**
   * The name of the input for [RESOLVED_UNIT2] of a library unit.
   */
  static const String RESOLVED_UNIT2_INPUT_NAME = 'RESOLVED_UNIT2_INPUT_NAME';

  /**
   * The input with a list of [LIBRARY_ELEMENT1]s of imported libraries.
   */
  static const String IMPORTS_LIBRARY_ELEMENT1_INPUT_NAME =
      'IMPORTS_LIBRARY_ELEMENT1_INPUT_NAME';

  /**
   * The input with a list of [LIBRARY_ELEMENT1]s of exported libraries.
   */
  static const String EXPORTS_LIBRARY_ELEMENT1_INPUT_NAME =
      'EXPORTS_LIBRARY_ELEMENT1_INPUT_NAME';

  /**
   * The input with a list of [SOURCE_KIND]s of imported libraries.
   */
  static const String IMPORTS_SOURCE_KIND_INPUT_NAME =
      'IMPORTS_SOURCE_KIND_INPUT_NAME';

  /**
   * The input with a list of [SOURCE_KIND]s of exported libraries.
   */
  static const String EXPORTS_SOURCE_KIND_INPUT_NAME =
      'EXPORTS_SOURCE_KIND_INPUT_NAME';

  /**
   * The task descriptor describing this kind of task.
   */
  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor(
      'BUILD_RESOLVED_UNIT3', createTask, buildInputs, <ResultDescriptor>[
    RESOLVED_UNIT3,
    BUILD_DIRECTIVES_ERRORS
  ]);

  BuildDirectiveElementsTask(
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
    CompilationUnit libraryUnit = getRequiredInput(RESOLVED_UNIT2_INPUT_NAME);
    Map<Source, LibraryElement> importLibraryMap =
        getRequiredInput(IMPORTS_LIBRARY_ELEMENT1_INPUT_NAME);
    Map<Source, LibraryElement> exportLibraryMap =
        getRequiredInput(EXPORTS_LIBRARY_ELEMENT1_INPUT_NAME);
    Map<Source, SourceKind> importSourceKindMap =
        getRequiredInput(IMPORTS_SOURCE_KIND_INPUT_NAME);
    Map<Source, SourceKind> exportSourceKindMap =
        getRequiredInput(EXPORTS_SOURCE_KIND_INPUT_NAME);
    //
    // Process inputs.
    //
    LibraryElementImpl libraryElement = libraryUnit.element.library;
    Source librarySource = libraryElement.source;
    //
    // Resolve directives.
    //
    HashMap<String, PrefixElementImpl> nameToPrefixMap =
        new HashMap<String, PrefixElementImpl>();
    List<ImportElement> imports = <ImportElement>[];
    List<ExportElement> exports = <ExportElement>[];
    bool explicitlyImportsCore = false;
    for (Directive directive in libraryUnit.directives) {
      if (directive is ImportDirective) {
        ImportDirective importDirective = directive;
        String uriContent = importDirective.uriContent;
        if (DartUriResolver.isDartExtUri(uriContent)) {
          libraryElement.hasExtUri = true;
        }
        Source importedSource = importDirective.source;
        if (importedSource != null && context.exists(importedSource)) {
          // The imported source will be null if the URI in the import
          // directive was invalid.
          LibraryElement importedLibrary = importLibraryMap[importedSource];
          if (importedLibrary != null) {
            ImportElementImpl importElement =
                new ImportElementImpl(directive.offset);
            StringLiteral uriLiteral = importDirective.uri;
            if (uriLiteral != null) {
              importElement.uriOffset = uriLiteral.offset;
              importElement.uriEnd = uriLiteral.end;
            }
            importElement.uri = uriContent;
            importElement.deferred = importDirective.deferredKeyword != null;
            importElement.combinators = _buildCombinators(importDirective);
            importElement.importedLibrary = importedLibrary;
            SimpleIdentifier prefixNode = directive.prefix;
            if (prefixNode != null) {
              importElement.prefixOffset = prefixNode.offset;
              String prefixName = prefixNode.name;
              PrefixElementImpl prefix = nameToPrefixMap[prefixName];
              if (prefix == null) {
                prefix = new PrefixElementImpl.forNode(prefixNode);
                nameToPrefixMap[prefixName] = prefix;
              }
              importElement.prefix = prefix;
              prefixNode.staticElement = prefix;
            }
            directive.element = importElement;
            imports.add(importElement);
            if (importSourceKindMap[importedSource] != SourceKind.LIBRARY) {
              ErrorCode errorCode = (importElement.isDeferred
                  ? StaticWarningCode.IMPORT_OF_NON_LIBRARY
                  : CompileTimeErrorCode.IMPORT_OF_NON_LIBRARY);
              errors.add(new AnalysisError.con2(importedSource,
                  uriLiteral.offset, uriLiteral.length, errorCode,
                  [uriLiteral.toSource()]));
            }
          }
        }
      } else if (directive is ExportDirective) {
        ExportDirective exportDirective = directive;
        Source exportedSource = exportDirective.source;
        if (exportedSource != null && context.exists(exportedSource)) {
          // The exported source will be null if the URI in the export
          // directive was invalid.
          LibraryElement exportedLibrary = exportLibraryMap[exportedSource];
          if (exportedLibrary != null) {
            ExportElementImpl exportElement =
                new ExportElementImpl(directive.offset);
            StringLiteral uriLiteral = exportDirective.uri;
            if (uriLiteral != null) {
              exportElement.uriOffset = uriLiteral.offset;
              exportElement.uriEnd = uriLiteral.end;
            }
            exportElement.uri = exportDirective.uriContent;
            exportElement.combinators = _buildCombinators(exportDirective);
            exportElement.exportedLibrary = exportedLibrary;
            directive.element = exportElement;
            exports.add(exportElement);
            if (exportSourceKindMap[exportedSource] != SourceKind.LIBRARY) {
              errors.add(new AnalysisError.con2(exportedSource,
                  uriLiteral.offset, uriLiteral.length,
                  CompileTimeErrorCode.EXPORT_OF_NON_LIBRARY,
                  [uriLiteral.toSource()]));
            }
          }
        }
      }
    }
    //
    // Ensure "dart:core" import.
    //
    Source coreLibrarySource = context.sourceFactory.forUri(DartSdk.DART_CORE);
    if (!explicitlyImportsCore && coreLibrarySource != librarySource) {
      ImportElementImpl importElement = new ImportElementImpl(-1);
      importElement.importedLibrary = importLibraryMap[coreLibrarySource];
      importElement.synthetic = true;
      imports.add(importElement);
    }
    //
    // Populate the library element.
    //
    libraryElement.imports = imports;
    libraryElement.exports = exports;
    // TODO(scheglov) move after EXPORT_NAMESPACE or just this task
//    if (libraryElement.entryPoint == null) {
//      Namespace namespace = new NamespaceBuilder()
//          .createExportNamespaceForLibrary(libraryElement);
//      Element element = namespace.get(FunctionElement.MAIN_FUNCTION_NAME);
//      if (element is FunctionElement) {
//        libraryElement.entryPoint = element;
//      }
//    }
    //
    // Record outputs.
    //
    outputs[RESOLVED_UNIT3] = libraryUnit;
    outputs[BUILD_DIRECTIVES_ERRORS] = errors;
  }

  /**
   * Return a map from the names of the inputs of this kind of task to the task
   * input descriptors describing those inputs for a task with the
   * given [target].
   */
  static Map<String, TaskInput> buildInputs(AnalysisTarget target) {
    return <String, TaskInput>{
      RESOLVED_UNIT2_INPUT_NAME: RESOLVED_UNIT2.inputFor(target),
      IMPORTS_LIBRARY_ELEMENT1_INPUT_NAME:
          new ListToMapTaskInput<Source, LibraryElement>(
              IMPORTED_LIBRARIES.inputFor(target),
              (Source source) => LIBRARY_ELEMENT1.inputFor(source)),
      EXPORTS_LIBRARY_ELEMENT1_INPUT_NAME:
          new ListToMapTaskInput<Source, LibraryElement>(
              EXPORTED_LIBRARIES.inputFor(target),
              (Source source) => LIBRARY_ELEMENT1.inputFor(source)),
      IMPORTS_SOURCE_KIND_INPUT_NAME:
          new ListToMapTaskInput<Source, SourceKind>(
              IMPORTED_LIBRARIES.inputFor(target),
              (Source source) => SOURCE_KIND.inputFor(source)),
      EXPORTS_SOURCE_KIND_INPUT_NAME:
          new ListToMapTaskInput<Source, SourceKind>(
              EXPORTED_LIBRARIES.inputFor(target),
              (Source source) => SOURCE_KIND.inputFor(source))
    };
  }

  /**
   * Create a [BuildDirectiveElementsTask] based on the given [target] in
   * the given [context].
   */
  static BuildDirectiveElementsTask createTask(
      AnalysisContext context, AnalysisTarget target) {
    return new BuildDirectiveElementsTask(context, target);
  }

  /**
   * Build the element model representing the combinators declared by
   * the given [directive].
   */
  static List<NamespaceCombinator> _buildCombinators(
      NamespaceDirective directive) {
    List<NamespaceCombinator> combinators = <NamespaceCombinator>[];
    for (Combinator combinator in directive.combinators) {
      if (combinator is ShowCombinator) {
        ShowElementCombinatorImpl show = new ShowElementCombinatorImpl();
        show.offset = combinator.offset;
        show.end = combinator.end;
        show.shownNames = _getIdentifiers(combinator.shownNames);
        combinators.add(show);
      } else if (combinator is HideCombinator) {
        HideElementCombinatorImpl hide = new HideElementCombinatorImpl();
        hide.hiddenNames = _getIdentifiers(combinator.hiddenNames);
        combinators.add(hide);
      }
    }
    return combinators;
  }

  /**
   * Return the lexical identifiers associated with the given [identifiers].
   */
  static List<String> _getIdentifiers(NodeList<SimpleIdentifier> identifiers) {
    return identifiers.map((identifier) => identifier.name).toList();
  }
}

/**
 * A task that builds the elements representing the members of enum
 * declarations.
 */
class BuildEnumMemberElementsTask extends SourceBasedAnalysisTask {
  /**
   * The name of the [TYPE_PROVIDER] input.
   */
  static const String TYPE_PROVIDER_INPUT = 'TYPE_PROVIDER_INPUT';

  /**
   * The name of the [RESOLVED_UNIT3] input.
   */
  static const String UNIT_INPUT = 'UNIT_INPUT';

  /**
   * The task descriptor describing this kind of task.
   */
  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor(
      'BuildEnumMemberElementsTask', createTask, buildInputs,
      <ResultDescriptor>[RESOLVED_UNIT4]);

  BuildEnumMemberElementsTask(
      InternalAnalysisContext context, AnalysisTarget target)
      : super(context, target);

  @override
  TaskDescriptor get descriptor => DESCRIPTOR;

  @override
  void internalPerform() {
    //
    // Prepare inputs.
    //
    TypeProvider typeProvider = getRequiredInput(TYPE_PROVIDER_INPUT);
    CompilationUnit unit = getRequiredInput(UNIT_INPUT);
    //
    // Record outputs.
    //
    EnumMemberBuilder builder = new EnumMemberBuilder(typeProvider);
    unit.accept(builder);
    outputs[RESOLVED_UNIT4] = unit;
  }

  /**
   * Return a map from the names of the inputs of this kind of task to the task
   * input descriptors describing those inputs for a task with the
   * given [target].
   */
  static Map<String, TaskInput> buildInputs(AnalysisTarget target) {
    return <String, TaskInput>{
      TYPE_PROVIDER_INPUT:
          TYPE_PROVIDER.inputFor(AnalysisContextTarget.request),
      UNIT_INPUT: RESOLVED_UNIT3.inputFor(target)
    };
  }

  /**
   * Create a [BuildEnumMemberElementsTask] based on the given [target] in
   * the given [context].
   */
  static BuildEnumMemberElementsTask createTask(
      AnalysisContext context, AnalysisTarget target) {
    return new BuildEnumMemberElementsTask(context, target);
  }
}

/**
 * A task that builds a library element for a Dart library.
 */
class BuildLibraryElementTask extends SourceBasedAnalysisTask {
  /**
   * The name of the input whose value is the defining [RESOLVED_UNIT1].
   */
  static const String DEFINING_RESOLVER_UNIT1_INPUT_NAME =
      'DEFINING_RESOLVER_UNIT1_INPUT_NAME';

  /**
   * The name of the input whose value is a list of built [RESOLVED_UNIT1]s
   * of the parts sourced by a library.
   */
  static const String PARTS_RESOLVED_UNIT1_INPUT_NAME =
      'PARTS_RESOLVED_UNIT1_INPUT_NAME';

  /**
   * The task descriptor describing this kind of task.
   */
  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor(
      'BUILD_LIBRARY_ELEMENT', createTask, buildInputs, <ResultDescriptor>[
    BUILD_LIBRARY_ERRORS,
    RESOLVED_UNIT2,
    LIBRARY_ELEMENT1,
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
        getRequiredInput(DEFINING_RESOLVER_UNIT1_INPUT_NAME);
    List<CompilationUnit> partUnits =
        getRequiredInput(PARTS_RESOLVED_UNIT1_INPUT_NAME);
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
                partUri.length, CompileTimeErrorCode.PART_OF_NON_PART,
                [partUri.toSource()]));
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
    outputs[RESOLVED_UNIT2] = definingCompilationUnit;
    outputs[LIBRARY_ELEMENT1] = libraryElement;
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
      DEFINING_RESOLVER_UNIT1_INPUT_NAME:
          new SimpleTaskInput(target, RESOLVED_UNIT1),
      PARTS_RESOLVED_UNIT1_INPUT_NAME:
          new ListToListTaskInput<Source, CompilationUnit>(
              INCLUDED_PARTS.inputFor(target),
              (Source source) => RESOLVED_UNIT1.inputFor(source))
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
 * A task that builds [PUBLIC_NAMESPACE] for a library.
 */
class BuildPublicNamespaceTask extends SourceBasedAnalysisTask {
  /**
   * The name of the input for [LIBRARY_ELEMENT1] of a library.
   */
  static const String BUILT_LIBRARY_ELEMENT_INPUT_NAME =
      'BUILT_LIBRARY_ELEMENT_INPUT_NAME';

  /**
   * The task descriptor describing this kind of task.
   */
  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor(
      'BUILD_PUBLIC_NAMESPACE', createTask, buildInputs,
      <ResultDescriptor>[PUBLIC_NAMESPACE]);

  BuildPublicNamespaceTask(
      InternalAnalysisContext context, AnalysisTarget target)
      : super(context, target);

  @override
  TaskDescriptor get descriptor => DESCRIPTOR;

  @override
  void internalPerform() {
    LibraryElement library = getRequiredInput(BUILT_LIBRARY_ELEMENT_INPUT_NAME);

    NamespaceBuilder builder = new NamespaceBuilder();
    Namespace namespace = builder.createPublicNamespaceForLibrary(library);

    outputs[PUBLIC_NAMESPACE] = namespace;
  }

  /**
   * Return a map from the names of the inputs of this kind of task to the task
   * input descriptors describing those inputs for a task with the
   * given [target].
   */
  static Map<String, TaskInput> buildInputs(AnalysisTarget target) {
    return <String, TaskInput>{
      BUILT_LIBRARY_ELEMENT_INPUT_NAME: LIBRARY_ELEMENT1.inputFor(target)
    };
  }

  /**
   * Create a [BuildPublicNamespaceTask] based on the given [target] in
   * the given [context].
   */
  static BuildPublicNamespaceTask createTask(
      AnalysisContext context, AnalysisTarget target) {
    return new BuildPublicNamespaceTask(context, target);
  }
}

/**
 * A task that builds [TYPE_PROVIDER] for a context.
 */
class BuildTypeProviderTask extends SourceBasedAnalysisTask {
  /**
   * The [RESOLVED_UNIT3] input of the `dart:core` library.
   */
  static const String CORE_INPUT = 'CORE_INPUT';

  /**
   * The [RESOLVED_UNIT3] input of the `dart:async` library.
   */
  static const String ASYNC_INPUT = 'ASYNC_INPUT';

  /**
   * The task descriptor describing this kind of task.
   */
  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor(
      'BuildTypeProviderTask', createTask, buildInputs,
      <ResultDescriptor>[TYPE_PROVIDER]);

  BuildTypeProviderTask(
      InternalAnalysisContext context, AnalysisContextTarget target)
      : super(context, target);

  @override
  TaskDescriptor get descriptor => DESCRIPTOR;

  @override
  void internalPerform() {
    CompilationUnit coreUnit = getRequiredInput(CORE_INPUT);
    CompilationUnit asyncUnit = getRequiredInput(ASYNC_INPUT);
    LibraryElement coreLibrary = coreUnit.element.library;
    LibraryElement asyncLibrary = asyncUnit.element.library;
    //
    // Record outputs.
    //
    TypeProvider typeProvider = new TypeProviderImpl(coreLibrary, asyncLibrary);
    (context as ExtendedAnalysisContext).typeProvider = typeProvider;
    outputs[TYPE_PROVIDER] = typeProvider;
  }

  static Map<String, TaskInput> buildInputs(AnalysisContextTarget target) {
    SourceFactory sourceFactory = target.context.sourceFactory;
    Source coreSource = sourceFactory.forUri(DartSdk.DART_CORE);
    Source asyncSource = sourceFactory.forUri(DartSdk.DART_ASYNC);
    return <String, TaskInput>{
      CORE_INPUT: RESOLVED_UNIT3.inputFor(coreSource),
      ASYNC_INPUT: RESOLVED_UNIT3.inputFor(asyncSource)
    };
  }

  /**
   * Create a [BuildTypeProviderTask] based on the given [context].
   */
  static BuildTypeProviderTask createTask(
      AnalysisContext context, AnalysisContextTarget target) {
    return new BuildTypeProviderTask(context, target);
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
  static const String LINE_INFO_INPUT_NAME = 'LINE_INFO_INPUT_NAME';

  /**
   * The name of the input whose value is the token stream produced for the file.
   */
  static const String TOKEN_STREAM_INPUT_NAME = 'TOKEN_STREAM_INPUT_NAME';

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
    //
    // Always include "dart:core" source.
    //
    Source coreLibrarySource = context.sourceFactory.forUri(DartSdk.DART_CORE);
    importedSources.add(coreLibrarySource);
    //
    // Compute kind.
    //
    SourceKind sourceKind = SourceKind.LIBRARY;
    if (!hasNonPartOfDirective && hasPartOfDirective) {
      sourceKind = SourceKind.PART;
    }
    //
    // Record outputs.
    //
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
  static const String CONTENT_INPUT_NAME = 'CONTENT_INPUT_NAME';

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
