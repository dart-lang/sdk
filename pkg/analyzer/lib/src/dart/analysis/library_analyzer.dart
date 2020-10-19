// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/null_safety_understanding_flag.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/context/source.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/analysis/testing_data.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/constant/compute.dart';
import 'package:analyzer/src/dart/constant/constant_verifier.dart';
import 'package:analyzer/src/dart/constant/evaluation.dart';
import 'package:analyzer/src/dart/constant/utilities.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/resolver/flow_analysis_visitor.dart';
import 'package:analyzer/src/dart/resolver/legacy_type_asserter.dart';
import 'package:analyzer/src/dart/resolver/resolution_visitor.dart';
import 'package:analyzer/src/error/best_practices_verifier.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/error/dead_code_verifier.dart';
import 'package:analyzer/src/error/ignore_validator.dart';
import 'package:analyzer/src/error/imports_verifier.dart';
import 'package:analyzer/src/error/inheritance_override.dart';
import 'package:analyzer/src/error/language_version_override_verifier.dart';
import 'package:analyzer/src/error/override_verifier.dart';
import 'package:analyzer/src/error/todo_finder.dart';
import 'package:analyzer/src/error/unused_local_elements_verifier.dart';
import 'package:analyzer/src/generated/declaration_resolver.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/error_verifier.dart';
import 'package:analyzer/src/generated/ffi_verifier.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/hint/sdk_constraint_verifier.dart';
import 'package:analyzer/src/ignore_comments/ignore_info.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer/src/lint/linter_visitor.dart';
import 'package:analyzer/src/services/lint.dart';
import 'package:analyzer/src/summary2/linked_element_factory.dart';
import 'package:analyzer/src/task/strong/checker.dart';
import 'package:pub_semver/pub_semver.dart';

var timerLibraryAnalyzer = Stopwatch();
var timerLibraryAnalyzerConst = Stopwatch();
var timerLibraryAnalyzerFreshUnit = Stopwatch();
var timerLibraryAnalyzerResolve = Stopwatch();
var timerLibraryAnalyzerSplicer = Stopwatch();
var timerLibraryAnalyzerVerify = Stopwatch();

/// Analyzer of a single library.
class LibraryAnalyzer {
  /// A marker object used to prevent the initialization of
  /// [_versionConstraintFromPubspec] when the previous initialization attempt
  /// failed.
  static final VersionRange noSpecifiedRange = VersionRange();
  final AnalysisOptionsImpl _analysisOptions;
  final DeclaredVariables _declaredVariables;
  final SourceFactory _sourceFactory;
  final FileState _library;

  final InheritanceManager3 _inheritance;
  final bool Function(Uri) _isLibraryUri;
  final AnalysisContext _context;
  final LinkedElementFactory _elementFactory;

  LibraryElement _libraryElement;

  final Map<FileState, LineInfo> _fileToLineInfo = {};

  final Map<FileState, IgnoreInfo> _fileToIgnoreInfo = {};
  final Map<FileState, RecordingErrorListener> _errorListeners = {};
  final Map<FileState, ErrorReporter> _errorReporters = {};
  final TestingData _testingData;
  final List<UsedImportedElements> _usedImportedElementsList = [];
  final List<UsedLocalElements> _usedLocalElementsList = [];

  final Set<ConstantEvaluationTarget> _constants = {};

  LibraryAnalyzer(
      this._analysisOptions,
      this._declaredVariables,
      this._sourceFactory,
      this._isLibraryUri,
      this._context,
      this._elementFactory,
      this._inheritance,
      this._library,
      {TestingData testingData})
      : _testingData = testingData;

  TypeProviderImpl get _typeProvider => _libraryElement.typeProvider;

  TypeSystemImpl get _typeSystem => _libraryElement.typeSystem;

  /// Compute analysis results for all units of the library.
  Map<FileState, UnitAnalysisResult> analyze() {
    return analyzeSync();
  }

  /// Compute analysis results for all units of the library.
  Map<FileState, UnitAnalysisResult> analyzeSync() {
    // Analyzer understands null safety, so it should set
    // NullSafetyUnderstandingFlag.
    assert(NullSafetyUnderstandingFlag.isEnabled);

    timerLibraryAnalyzer.start();
    Map<FileState, CompilationUnit> units = {};

    // Parse all files.
    timerLibraryAnalyzerFreshUnit.start();
    for (FileState file in _library.libraryFiles) {
      units[file] = _parse(file);
    }
    timerLibraryAnalyzerFreshUnit.stop();

    _libraryElement = _elementFactory.libraryOfUri(_library.uriStr);

    // Resolve URIs in directives to corresponding sources.
    FeatureSet featureSet = units[_library].featureSet;
    units.forEach((file, unit) {
      _validateFeatureSet(unit, featureSet);
      _resolveUriBasedDirectives(file, unit);
    });

    timerLibraryAnalyzerResolve.start();
    _resolveDirectives(units);

    units.forEach((file, unit) {
      _resolveFile(file, unit);
    });
    timerLibraryAnalyzerResolve.stop();

    timerLibraryAnalyzerConst.start();
    units.values.forEach(_findConstants);
    _computeConstants();
    timerLibraryAnalyzerConst.stop();

    timerLibraryAnalyzerVerify.start();
    units.forEach((file, unit) {
      _computeVerifyErrors(file, unit);
    });

    if (_analysisOptions.hint) {
      units.forEach((file, unit) {
        {
          var visitor = GatherUsedLocalElementsVisitor(_libraryElement);
          unit.accept(visitor);
          _usedLocalElementsList.add(visitor.usedElements);
        }
        {
          var visitor = GatherUsedImportedElementsVisitor(_libraryElement);
          unit.accept(visitor);
          _usedImportedElementsList.add(visitor.usedElements);
        }
      });
      units.forEach((file, unit) {
        _computeHints(file, unit);
      });
    }

    if (_analysisOptions.lint) {
      var allUnits = _library.libraryFiles
          .map((file) => LinterContextUnit(file.content, units[file]))
          .toList();
      for (int i = 0; i < allUnits.length; i++) {
        _computeLints(_library.libraryFiles[i], allUnits[i], allUnits);
      }
    }

    assert(units.values.every(LegacyTypeAsserter.assertLegacyTypes));

    _checkForInconsistentLanguageVersionOverride(units);

    // This must happen after all other diagnostics have been computed but
    // before the list of diagnostics has been filtered.
    for (var file in _library.libraryFiles) {
      if (file.source != null) {
        IgnoreValidator(_getErrorReporter(file), _getErrorListener(file).errors,
                _fileToIgnoreInfo[file], _fileToLineInfo[file])
            .reportErrors();
      }
    }

    timerLibraryAnalyzerVerify.stop();

    // Return full results.
    Map<FileState, UnitAnalysisResult> results = {};
    units.forEach((file, unit) {
      List<AnalysisError> errors = _getErrorListener(file).errors;
      errors = _filterIgnoredErrors(file, errors);
      results[file] = UnitAnalysisResult(file, unit, errors);
    });
    timerLibraryAnalyzer.stop();
    return results;
  }

  void _checkForInconsistentLanguageVersionOverride(
    Map<FileState, CompilationUnit> units,
  ) {
    var libraryEntry = units.entries.first;
    var libraryUnit = libraryEntry.value;
    var libraryOverrideToken = libraryUnit.languageVersionToken;

    var elementToUnit = <CompilationUnitElement, CompilationUnit>{};
    for (var entry in units.entries) {
      var unit = entry.value;
      elementToUnit[unit.declaredElement] = unit;
    }

    for (var directive in libraryUnit.directives) {
      if (directive is PartDirective) {
        var partUnit = elementToUnit[directive.uriElement];
        if (partUnit != null) {
          var shouldReport = false;
          var partOverrideToken = partUnit.languageVersionToken;
          if (libraryOverrideToken != null) {
            if (partOverrideToken != null) {
              if (partOverrideToken.major != libraryOverrideToken.major ||
                  partOverrideToken.minor != libraryOverrideToken.minor) {
                shouldReport = true;
              }
            } else {
              shouldReport = true;
            }
          } else if (partOverrideToken != null) {
            shouldReport = true;
          }
          if (shouldReport) {
            _getErrorReporter(_library).reportErrorForNode(
              CompileTimeErrorCode.INCONSISTENT_LANGUAGE_VERSION_OVERRIDE,
              directive.uri,
            );
          }
        }
      }
    }
  }

  void _computeConstantErrors(
      ErrorReporter errorReporter, CompilationUnit unit) {
    ConstantVerifier constantVerifier = ConstantVerifier(
        errorReporter, _libraryElement, _declaredVariables,
        featureSet: unit.featureSet);
    unit.accept(constantVerifier);
  }

  /// Compute [_constants] in all units.
  void _computeConstants() {
    computeConstants(_typeProvider, _typeSystem, _declaredVariables,
        _constants.toList(), _analysisOptions.experimentStatus);
  }

  void _computeHints(FileState file, CompilationUnit unit) {
    if (file.source == null) {
      return;
    }

    AnalysisErrorListener errorListener = _getErrorListener(file);
    ErrorReporter errorReporter = _getErrorReporter(file);

    if (!_libraryElement.isNonNullableByDefault) {
      unit.accept(
        LegacyDeadCodeVerifier(
          errorReporter,
          typeSystem: _typeSystem,
        ),
      );
    }

    unit.accept(DeadCodeVerifier(errorReporter));

    unit.accept(
      BestPracticesVerifier(
        errorReporter,
        _typeProvider,
        _libraryElement,
        unit,
        file.content,
        declaredVariables: _declaredVariables,
        typeSystem: _typeSystem,
        inheritanceManager: _inheritance,
        analysisOptions: _context.analysisOptions,
        workspacePackage: _library.workspacePackage,
      ),
    );

    unit.accept(OverrideVerifier(
      _inheritance,
      _libraryElement,
      errorReporter,
    ));

    TodoFinder(errorReporter).findIn(unit);
    LanguageVersionOverrideVerifier(errorReporter).verify(unit);

    // Verify imports.
    {
      ImportsVerifier verifier = ImportsVerifier();
      verifier.addImports(unit);
      _usedImportedElementsList.forEach(verifier.removeUsedElements);
      verifier.generateDuplicateImportHints(errorReporter);
      verifier.generateDuplicateShownHiddenNameHints(errorReporter);
      verifier.generateUnusedImportHints(errorReporter);
      verifier.generateUnusedShownNameHints(errorReporter);
    }

    // Unused local elements.
    {
      UsedLocalElements usedElements =
          UsedLocalElements.merge(_usedLocalElementsList);
      UnusedLocalElementsVerifier visitor = UnusedLocalElementsVerifier(
          errorListener, usedElements, _inheritance, _libraryElement);
      unit.accept(visitor);
    }

    //
    // Find code that uses features from an SDK version that does not satisfy
    // the SDK constraints specified in analysis options.
    //
    var sdkVersionConstraint = _analysisOptions.sdkVersionConstraint;
    if (sdkVersionConstraint != null) {
      SdkConstraintVerifier verifier = SdkConstraintVerifier(
          errorReporter, _libraryElement, _typeProvider, sdkVersionConstraint);
      unit.accept(verifier);
    }
  }

  void _computeLints(FileState file, LinterContextUnit currentUnit,
      List<LinterContextUnit> allUnits) {
    var unit = currentUnit.unit;
    if (file.source == null) {
      return;
    }

    ErrorReporter errorReporter = _getErrorReporter(file);

    var nodeRegistry = NodeLintRegistry(_analysisOptions.enableTiming);
    var visitors = <AstVisitor>[];

    var context = LinterContextImpl(
      allUnits,
      currentUnit,
      _declaredVariables,
      _typeProvider,
      _typeSystem,
      _inheritance,
      _analysisOptions,
      file.workspacePackage,
    );
    for (Linter linter in _analysisOptions.lintRules) {
      linter.reporter = errorReporter;
      linter.registerNodeProcessors(nodeRegistry, context);
    }

    // Run lints that handle specific node types.
    unit.accept(LinterVisitor(
        nodeRegistry, ExceptionHandlingDelegatingAstVisitor.logException));

    // Run visitor based lints.
    if (visitors.isNotEmpty) {
      AstVisitor visitor = ExceptionHandlingDelegatingAstVisitor(
          visitors, ExceptionHandlingDelegatingAstVisitor.logException);
      unit.accept(visitor);
    }
  }

  void _computeVerifyErrors(FileState file, CompilationUnit unit) {
    if (file.source == null) {
      return;
    }

    RecordingErrorListener errorListener = _getErrorListener(file);

    CodeChecker checker = CodeChecker(
      _typeProvider,
      _typeSystem,
      _inheritance,
      errorListener,
    );
    checker.visitCompilationUnit(unit);

    ErrorReporter errorReporter = _getErrorReporter(file);

    //
    // Validate the directives.
    //
    _validateUriBasedDirectives(file, unit);

    //
    // Use the ConstantVerifier to compute errors.
    //
    _computeConstantErrors(errorReporter, unit);

    //
    // Compute inheritance and override errors.
    //
    var inheritanceOverrideVerifier =
        InheritanceOverrideVerifier(_typeSystem, _inheritance, errorReporter);
    inheritanceOverrideVerifier.verifyUnit(unit);

    //
    // Use the ErrorVerifier to compute errors.
    //
    ErrorVerifier errorVerifier = ErrorVerifier(
        errorReporter, _libraryElement, _typeProvider, _inheritance);
    unit.accept(errorVerifier);

    // Verify constraints on FFI uses. The CFE enforces these constraints as
    // compile-time errors and so does the analyzer.
    unit.accept(FfiVerifier(_typeSystem, errorReporter));
  }

  /// Return a subset of the given [errors] that are not marked as ignored in
  /// the [file].
  List<AnalysisError> _filterIgnoredErrors(
      FileState file, List<AnalysisError> errors) {
    if (errors.isEmpty) {
      return errors;
    }

    IgnoreInfo ignoreInfo = _fileToIgnoreInfo[file];
    if (!ignoreInfo.hasIgnores) {
      return errors;
    }

    LineInfo lineInfo = _fileToLineInfo[file];

    bool isIgnored(AnalysisError error) {
      var code = error.errorCode;
      // Don't allow error severity issues to be ignored.
      if (!IgnoreValidator.isIgnorable(file.path, code)) {
        return false;
      }

      int errorLine = lineInfo.getLocation(error.offset).lineNumber;
      String name = code.name.toLowerCase();
      if (ignoreInfo.ignoredAt(name, errorLine)) {
        return true;
      }
      String uniqueName = code.uniqueName;
      int period = uniqueName.indexOf('.');
      if (period >= 0) {
        uniqueName = uniqueName.substring(period + 1);
      }
      return uniqueName != name &&
          ignoreInfo.ignoredAt(uniqueName.toLowerCase(), errorLine);
    }

    return errors.where((AnalysisError e) => !isIgnored(e)).toList();
  }

  /// Find constants to compute.
  void _findConstants(CompilationUnit unit) {
    ConstantFinder constantFinder = ConstantFinder();
    unit.accept(constantFinder);
    _constants.addAll(constantFinder.constantsToCompute);

    var dependenciesFinder = ConstantExpressionsDependenciesFinder();
    unit.accept(dependenciesFinder);
    _constants.addAll(dependenciesFinder.dependencies);
  }

  RecordingErrorListener _getErrorListener(FileState file) =>
      _errorListeners.putIfAbsent(file, () => RecordingErrorListener());

  ErrorReporter _getErrorReporter(FileState file) {
    return _errorReporters.putIfAbsent(file, () {
      RecordingErrorListener listener = _getErrorListener(file);
      return ErrorReporter(
        listener,
        file.source,
        isNonNullableByDefault: _libraryElement.isNonNullableByDefault,
      );
    });
  }

  /// Return the name of the library that the given part is declared to be a
  /// part of, or `null` if the part does not contain a part-of directive.
  _NameOrSource _getPartLibraryNameOrUri(Source partSource,
      CompilationUnit partUnit, List<Directive> directivesToResolve) {
    for (Directive directive in partUnit.directives) {
      if (directive is PartOfDirective) {
        directivesToResolve.add(directive);
        LibraryIdentifier libraryName = directive.libraryName;
        if (libraryName != null) {
          return _NameOrSource(libraryName.name, null);
        }
        String uri = directive.uri?.stringValue;
        if (uri != null) {
          Source librarySource = _sourceFactory.resolveUri(partSource, uri);
          if (librarySource != null) {
            return _NameOrSource(null, librarySource);
          }
        }
      }
    }
    return null;
  }

  bool _isExistingSource(Source source) {
    for (var file in _library.directReferencedFiles) {
      if (file.uri == source.uri) {
        return file.exists;
      }
    }
    // A library can refer to itself with an empty URI.
    return source == _library.source;
  }

  /// Return `true` if the given [source] is a library.
  bool _isLibrarySource(Source source) {
    return _isLibraryUri(source.uri);
  }

  /// Return a new parsed unresolved [CompilationUnit].
  CompilationUnit _parse(FileState file) {
    AnalysisErrorListener errorListener = _getErrorListener(file);
    String content = file.content;
    CompilationUnit unit = file.parse(errorListener);

    LineInfo lineInfo = unit.lineInfo;
    _fileToLineInfo[file] = lineInfo;
    _fileToIgnoreInfo[file] = IgnoreInfo.forDart(unit, content);

    return unit;
  }

  void _resolveDirectives(Map<FileState, CompilationUnit> units) {
    CompilationUnit definingCompilationUnit = units[_library];
    definingCompilationUnit.element = _libraryElement.definingCompilationUnit;

    bool matchNodeElement(Directive node, Element element) {
      return node.keyword.offset == element.nameOffset;
    }

    ErrorReporter libraryErrorReporter = _getErrorReporter(_library);

    LibraryIdentifier libraryNameNode;
    var seenPartSources = <Source>{};
    var directivesToResolve = <Directive>[];
    int partIndex = 0;
    for (Directive directive in definingCompilationUnit.directives) {
      if (directive is LibraryDirective) {
        libraryNameNode = directive.name;
        directivesToResolve.add(directive);
      } else if (directive is ImportDirective) {
        for (ImportElement importElement in _libraryElement.imports) {
          if (matchNodeElement(directive, importElement)) {
            directive.element = importElement;
            directive.prefix?.staticElement = importElement.prefix;
            Source source = importElement.importedLibrary?.source;
            if (source != null && !_isLibrarySource(source)) {
              libraryErrorReporter.reportErrorForNode(
                  CompileTimeErrorCode.IMPORT_OF_NON_LIBRARY,
                  directive.uri,
                  [directive.uri]);
            }
          }
        }
      } else if (directive is ExportDirective) {
        for (ExportElement exportElement in _libraryElement.exports) {
          if (matchNodeElement(directive, exportElement)) {
            directive.element = exportElement;
            Source source = exportElement.exportedLibrary?.source;
            if (source != null && !_isLibrarySource(source)) {
              libraryErrorReporter.reportErrorForNode(
                  CompileTimeErrorCode.EXPORT_OF_NON_LIBRARY,
                  directive.uri,
                  [directive.uri]);
            }
          }
        }
      } else if (directive is PartDirective) {
        StringLiteral partUri = directive.uri;

        FileState partFile = _library.partedFiles[partIndex];
        CompilationUnit partUnit = units[partFile];
        CompilationUnitElement partElement = _libraryElement.parts[partIndex];
        partUnit.element = partElement;
        directive.element = partElement;
        partIndex++;

        Source partSource = directive.uriSource;
        if (partSource == null) {
          continue;
        }

        //
        // Validate that the part source is unique in the library.
        //
        if (!seenPartSources.add(partSource)) {
          libraryErrorReporter.reportErrorForNode(
              CompileTimeErrorCode.DUPLICATE_PART, partUri, [partSource.uri]);
        }

        //
        // Validate that the part contains a part-of directive with the same
        // name or uri as the library.
        //
        if (_isExistingSource(partSource)) {
          _NameOrSource nameOrSource = _getPartLibraryNameOrUri(
              partSource, partUnit, directivesToResolve);
          if (nameOrSource == null) {
            libraryErrorReporter.reportErrorForNode(
                CompileTimeErrorCode.PART_OF_NON_PART,
                partUri,
                [partUri.toSource()]);
          } else {
            String name = nameOrSource.name;
            if (name != null) {
              if (libraryNameNode == null) {
                libraryErrorReporter.reportErrorForNode(
                    CompileTimeErrorCode.PART_OF_UNNAMED_LIBRARY,
                    partUri,
                    [name]);
              } else if (libraryNameNode.name != name) {
                libraryErrorReporter.reportErrorForNode(
                    CompileTimeErrorCode.PART_OF_DIFFERENT_LIBRARY,
                    partUri,
                    [libraryNameNode.name, name]);
              }
            } else {
              Source source = nameOrSource.source;
              if (source != _library.source) {
                libraryErrorReporter.reportErrorForNode(
                    CompileTimeErrorCode.PART_OF_DIFFERENT_LIBRARY,
                    partUri,
                    [_library.uriStr, source.uri]);
              }
            }
          }
        }
      }
    }

    // TODO(brianwilkerson) Report the error
    // ResolverErrorCode.MISSING_LIBRARY_DIRECTIVE_WITH_PART

    //
    // Resolve the relevant directives to the library element.
    //
    for (Directive directive in directivesToResolve) {
      directive.element = _libraryElement;
    }

    // TODO(scheglov) remove DirectiveResolver class
  }

  void _resolveFile(FileState file, CompilationUnit unit) {
    Source source = file.source;
    if (source == null) {
      return;
    }

    RecordingErrorListener errorListener = _getErrorListener(file);

    CompilationUnitElementImpl unitElement = unit.declaredElement;

    // TODO(scheglov) Hack: set types for top-level variables
    // Otherwise TypeResolverVisitor will set declared types, and because we
    // don't run InferStaticVariableTypeTask, we will stuck with these declared
    // types. And we don't need to run this task - resynthesized elements have
    // inferred types.
    for (var e in unitElement.topLevelVariables) {
      if (!e.isSynthetic) {
        e.type;
      }
    }

    unit.accept(
      ResolutionVisitor(
        unitElement: unitElement,
        errorListener: errorListener,
        featureSet: unit.featureSet,
        nameScope: _libraryElement.scope,
        elementWalker: ElementWalker.forCompilationUnit(unitElement),
      ),
    );

    unit.accept(VariableResolverVisitor(
        _libraryElement, source, _typeProvider, errorListener,
        nameScope: _libraryElement.scope));

    // Nothing for RESOLVED_UNIT8?
    // Nothing for RESOLVED_UNIT9?
    // Nothing for RESOLVED_UNIT10?

    FlowAnalysisHelper flowAnalysisHelper;
    if (unit.featureSet.isEnabled(Feature.non_nullable)) {
      flowAnalysisHelper =
          FlowAnalysisHelper(_typeSystem, _testingData != null);
      _testingData?.recordFlowAnalysisDataForTesting(
          file.uri, flowAnalysisHelper.dataForTesting);
    }

    unit.accept(ResolverVisitor(
        _inheritance, _libraryElement, source, _typeProvider, errorListener,
        featureSet: unit.featureSet, flowAnalysisHelper: flowAnalysisHelper));
  }

  /// Return the result of resolve the given [uriContent], reporting errors
  /// against the [uriLiteral].
  Source _resolveUri(FileState file, bool isImport, StringLiteral uriLiteral,
      String uriContent) {
    UriValidationCode code =
        UriBasedDirectiveImpl.validateUri(isImport, uriLiteral, uriContent);
    if (code == null) {
      try {
        Uri.parse(uriContent);
      } on FormatException {
        return null;
      }
      return _sourceFactory.resolveUri(file.source, uriContent);
    } else if (code == UriValidationCode.URI_WITH_DART_EXT_SCHEME) {
      return null;
    } else if (code == UriValidationCode.URI_WITH_INTERPOLATION) {
      _getErrorReporter(file).reportErrorForNode(
          CompileTimeErrorCode.URI_WITH_INTERPOLATION, uriLiteral);
      return null;
    } else if (code == UriValidationCode.INVALID_URI) {
      _getErrorReporter(file).reportErrorForNode(
          CompileTimeErrorCode.INVALID_URI, uriLiteral, [uriContent]);
      return null;
    }
    return null;
  }

  void _resolveUriBasedDirectives(FileState file, CompilationUnit unit) {
    for (Directive directive in unit.directives) {
      if (directive is UriBasedDirective) {
        StringLiteral uriLiteral = directive.uri;
        String uriContent = uriLiteral.stringValue?.trim();
        directive.uriContent = uriContent;
        Source defaultSource = _resolveUri(
            file, directive is ImportDirective, uriLiteral, uriContent);
        directive.uriSource = defaultSource;
      }
      if (directive is NamespaceDirectiveImpl) {
        var relativeUri = _selectRelativeUri(directive);
        directive.selectedUriContent = relativeUri;
        directive.selectedSource = _sourceFactory.resolveUri(
          _library.source,
          relativeUri,
        );
        for (var configuration in directive.configurations) {
          var uriLiteral = configuration.uri;
          String uriContent = uriLiteral.stringValue?.trim();
          Source defaultSource = _resolveUri(
              file, directive is ImportDirective, uriLiteral, uriContent);
          configuration.uriSource = defaultSource;
        }
      }
    }
  }

  String _selectRelativeUri(NamespaceDirective directive) {
    for (var configuration in directive.configurations) {
      var name = configuration.name.components.join('.');
      var value = configuration.value?.stringValue ?? 'true';
      if (_declaredVariables.get(name) == value) {
        return configuration.uri.stringValue ?? '';
      }
    }
    return directive.uri?.stringValue ?? '';
  }

  /// Validate that the feature set associated with the compilation [unit] is
  /// the same as the [expectedSet] of features supported by the library.
  void _validateFeatureSet(CompilationUnit unit, FeatureSet expectedSet) {
    FeatureSet actualSet = unit.featureSet;
    if (actualSet != expectedSet) {
      // TODO(brianwilkerson) Generate a diagnostic.
    }
  }

  /// Check the given [directive] to see if the referenced source exists and
  /// report an error if it does not.
  void _validateUriBasedDirective(
      FileState file, UriBasedDirectiveImpl directive) {
    String uriContent;
    Source source;
    if (directive is NamespaceDirectiveImpl) {
      uriContent = directive.selectedUriContent;
      source = directive.selectedSource;
    } else {
      uriContent = directive.uriContent;
      source = directive.uriSource;
    }
    if (source != null) {
      if (_isExistingSource(source)) {
        return;
      }
    } else {
      // Don't report errors already reported by ParseDartTask.resolveDirective
      // TODO(scheglov) we don't use this task here
      if (directive.validate() != null) {
        return;
      }
    }
    StringLiteral uriLiteral = directive.uri;
    CompileTimeErrorCode errorCode = CompileTimeErrorCode.URI_DOES_NOT_EXIST;
    if (isGeneratedSource(source)) {
      errorCode = CompileTimeErrorCode.URI_HAS_NOT_BEEN_GENERATED;
    }
    _getErrorReporter(file)
        .reportErrorForNode(errorCode, uriLiteral, [uriContent]);
  }

  /// Check each directive in the given [unit] to see if the referenced source
  /// exists and report an error if it does not.
  void _validateUriBasedDirectives(FileState file, CompilationUnit unit) {
    for (Directive directive in unit.directives) {
      if (directive is UriBasedDirective) {
        _validateUriBasedDirective(file, directive);
      }
    }
  }
}

/// Analysis result for single file.
class UnitAnalysisResult {
  final FileState file;
  final CompilationUnit unit;
  final List<AnalysisError> errors;

  UnitAnalysisResult(this.file, this.unit, this.errors);
}

/// Either the name or the source associated with a part-of directive.
class _NameOrSource {
  final String name;
  final Source source;

  _NameOrSource(this.name, this.source);
}
