// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/context/declared_variables.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/context/context.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/analysis/frontend_resolution.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/constant/evaluation.dart';
import 'package:analyzer/src/dart/constant/utilities.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/handle.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/error/pending_error.dart';
import 'package:analyzer/src/fasta/resolution_applier.dart';
import 'package:analyzer/src/generated/declaration_resolver.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/error_verifier.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/kernel/resynthesize.dart';
import 'package:analyzer/src/services/lint.dart';
import 'package:analyzer/src/task/dart.dart';
import 'package:analyzer/src/task/strong/checker.dart';
import 'package:front_end/src/dependency_walker.dart';
import 'package:front_end/src/incremental/kernel_driver.dart';

/**
 * Analyzer of a single library.
 */
class LibraryAnalyzer {
  final AnalysisOptions _analysisOptions;
  final DeclaredVariables _declaredVariables;
  final SourceFactory _sourceFactory;
  final FileState _library;

  final bool _enableKernelDriver;
  final bool _previewDart2;
  final KernelDriver _kernelDriver;

  final bool Function(Uri) _isLibraryUri;
  final AnalysisContextImpl _context;
  final ElementResynthesizer _resynthesizer;
  final TypeProvider _typeProvider;

  LibraryElement _libraryElement;

  final Map<FileState, LineInfo> _fileToLineInfo = {};
  final Map<FileState, IgnoreInfo> _fileToIgnoreInfo = {};

  final Map<FileState, RecordingErrorListener> _errorListeners = {};
  final Map<FileState, ErrorReporter> _errorReporters = {};
  final List<UsedImportedElements> _usedImportedElementsList = [];
  final List<UsedLocalElements> _usedLocalElementsList = [];
  final Map<FileState, List<PendingError>> _fileToPendingErrors = {};
  final List<ConstantEvaluationTarget> _constants = [];

  LibraryAnalyzer(
      this._analysisOptions,
      this._declaredVariables,
      this._sourceFactory,
      this._isLibraryUri,
      this._context,
      this._resynthesizer,
      this._library,
      {bool enableKernelDriver: false,
      bool previewDart2: false,
      KernelDriver kernelDriver})
      : _typeProvider = _context.typeProvider,
        _enableKernelDriver = enableKernelDriver,
        _previewDart2 = previewDart2,
        _kernelDriver = kernelDriver;

  /**
   * Compute analysis results for all units of the library.
   */
  Future<Map<FileState, UnitAnalysisResult>> analyze() async {
    return PerformanceStatistics.analysis.makeCurrentWhileAsync(() async {
      if (_previewDart2) {
        return await _analyze2();
      } else {
        return _analyze();
      }
    });
  }

  Map<FileState, UnitAnalysisResult> _analyze() {
    Map<FileState, CompilationUnit> units = {};

    // Parse all files.
    units[_library] = _parse(_library);
    for (FileState part in _library.partedFiles) {
      units[part] = _parse(part);
    }

    // Resolve URIs in directives to corresponding sources.
    units.forEach((file, unit) {
      _resolveUriBasedDirectives(file, unit);
    });

    try {
      _libraryElement = _resynthesizer
          .getElement(new ElementLocationImpl.con3([_library.uriStr]));

      _resolveDirectives(units);

      units.forEach((file, unit) {
        _resolveFile(file, unit);
        _computePendingMissingRequiredParameters(file, unit);
      });

      _computeConstants();

      PerformanceStatistics.errors.makeCurrentWhile(() {
        units.forEach((file, unit) {
          _computeVerifyErrors(file, unit);
        });
      });

      if (_analysisOptions.hint) {
        PerformanceStatistics.hints.makeCurrentWhile(() {
          units.forEach((file, unit) {
            {
              var visitor = new GatherUsedLocalElementsVisitor(_libraryElement);
              unit.accept(visitor);
              _usedLocalElementsList.add(visitor.usedElements);
            }
            {
              var visitor =
                  new GatherUsedImportedElementsVisitor(_libraryElement);
              unit.accept(visitor);
              _usedImportedElementsList.add(visitor.usedElements);
            }
          });
          units.forEach((file, unit) {
            _computeHints(file, unit);
          });
        });
      }

      if (_analysisOptions.lint) {
        PerformanceStatistics.lints.makeCurrentWhile(() {
          units.forEach((file, unit) {
            _computeLints(file, unit);
          });
        });
      }
    } finally {
      _context.dispose();
    }

    // Return full results.
    Map<FileState, UnitAnalysisResult> results = {};
    units.forEach((file, unit) {
      List<AnalysisError> errors = _getErrorListener(file).errors;
      errors = _filterIgnoredErrors(file, errors);
      results[file] = new UnitAnalysisResult(file, unit, errors);
    });
    return results;
  }

  Future<Map<FileState, UnitAnalysisResult>> _analyze2() async {
    Map<FileState, CompilationUnit> units = {};

    // Parse all files.
    units[_library] = _parse(_library);
    for (FileState part in _library.partedFiles) {
      units[part] = _parse(part);
    }

    // Resolve URIs in directives to corresponding sources.
    units.forEach((file, unit) {
      _resolveUriBasedDirectives(file, unit);
    });

    try {
      _libraryElement = _resynthesizer
          .getElement(new ElementLocationImpl.con3([_library.uriStr]));

      _resolveDirectives(units);

      // TODO(scheglov) Improve.
      {
        AnalyzerTarget analyzerTarget;
        await _kernelDriver.compileLibrary(
            (fileSystem, bool includeComments, dillTarget, uriTranslator,
                    {metadataCollector}) =>
                analyzerTarget ??= new AnalyzerTarget(fileSystem, dillTarget,
                    uriTranslator, _analysisOptions.strongMode),
            _library.uri);

        // TODO(scheglov) Types depend on enclosing elements?
        var astTypes = <DartType>[];
        KernelResynthesizer resynthesizer = _resynthesizer;
        for (var kernelType in analyzerTarget.kernelTypes) {
          DartType astType = resynthesizer.getType(null, kernelType);
          astTypes.add(astType);
        }

        if (units.length != 1) {
          // TODO(scheglov) Handle this case.
          throw new UnimplementedError('Multiple units in a library');
        }

        var unit = units.values.single;
        var applier = new ValidatingResolutionApplier(
            astTypes, analyzerTarget.typeOffsets);
        for (var declaration in unit.declarations) {
          if (declaration is ClassDeclaration) {
            for (var member in declaration.members) {
              if (member is ConstructorDeclaration) {
                member.body.accept(applier);
              } else if (member is FieldDeclaration) {
                if (member.fields.variables.length != 1) {
                  // TODO(scheglov) Handle this case.
                  throw new UnimplementedError('Multiple field');
                }
                member.fields.variables[0].initializer?.accept(applier);
              } else if (member is MethodDeclaration) {
                member.body.accept(applier);
              } else {
                // TODO(scheglov) Handle more cases.
                throw new UnimplementedError('${member.runtimeType}');
              }
            }
          } else if (declaration is FunctionDeclaration) {
            declaration.functionExpression.body.accept(applier);
          } else if (declaration is TopLevelVariableDeclaration) {
            if (declaration.variables.variables.length != 1) {
              // TODO(scheglov) Handle this case.
              throw new UnimplementedError('Multiple variables');
            }
            declaration.variables.variables[0].initializer?.accept(applier);
          } else {
            // TODO(scheglov) Handle more cases.
            throw new UnimplementedError('${declaration.runtimeType}');
          }
        }
      }

      units.forEach((file, unit) {
        CompilationUnitElement unitElement = unit.element;
        new DeclarationResolver(enableKernelDriver: _enableKernelDriver)
            .resolve(unit, unitElement);
//        _resolveFile(file, unit);
//        _computePendingMissingRequiredParameters(file, unit);
      });

      _computeConstants();

      // TODO(scheglov) Restore.
//      PerformanceStatistics.errors.makeCurrentWhile(() {
//        units.forEach((file, unit) {
//          _computeVerifyErrors(file, unit);
//        });
//      });

      // TODO(scheglov) Restore.
//      if (_analysisOptions.hint) {
//        PerformanceStatistics.hints.makeCurrentWhile(() {
//          units.forEach((file, unit) {
//            {
//              var visitor = new GatherUsedLocalElementsVisitor(_libraryElement);
//              unit.accept(visitor);
//              _usedLocalElementsList.add(visitor.usedElements);
//            }
//            {
//              var visitor =
//              new GatherUsedImportedElementsVisitor(_libraryElement);
//              unit.accept(visitor);
//              _usedImportedElementsList.add(visitor.usedElements);
//            }
//          });
//          units.forEach((file, unit) {
//            _computeHints(file, unit);
//          });
//        });
//      }

      if (_analysisOptions.lint) {
        PerformanceStatistics.lints.makeCurrentWhile(() {
          units.forEach((file, unit) {
            _computeLints(file, unit);
          });
        });
      }
    } finally {
      _context.dispose();
    }

    // Return full results.
    Map<FileState, UnitAnalysisResult> results = {};
    units.forEach((file, unit) {
      List<AnalysisError> errors = _getErrorListener(file).errors;
      errors = _filterIgnoredErrors(file, errors);
      results[file] = new UnitAnalysisResult(file, unit, errors);
    });
    return results;
  }

  /**
   * Compute [_constants] in all units.
   */
  void _computeConstants() {
    ConstantEvaluationEngine evaluationEngine = new ConstantEvaluationEngine(
        _typeProvider, _declaredVariables,
        typeSystem: _context.typeSystem);

    List<_ConstantNode> nodes = [];
    Map<ConstantEvaluationTarget, _ConstantNode> nodeMap = {};
    for (ConstantEvaluationTarget constant in _constants) {
      var node = new _ConstantNode(evaluationEngine, nodeMap, constant);
      nodes.add(node);
      nodeMap[constant] = node;
    }

    for (_ConstantNode node in nodes) {
      if (!node.isEvaluated) {
        new _ConstantWalker(evaluationEngine).walk(node);
      }
    }
  }

  void _computeHints(FileState file, CompilationUnit unit) {
    if (file.source == null) {
      return;
    }

    AnalysisErrorListener errorListener = _getErrorListener(file);
    ErrorReporter errorReporter = _getErrorReporter(file);

    //
    // Convert the pending errors into actual errors.
    //
    for (PendingError pendingError in _fileToPendingErrors[file]) {
      errorListener.onError(pendingError.toAnalysisError());
    }

    unit.accept(
        new DeadCodeVerifier(errorReporter, typeSystem: _context.typeSystem));

    // Dart2js analysis.
    if (_analysisOptions.dart2jsHint) {
      unit.accept(new Dart2JSVerifier(errorReporter));
    }

    InheritanceManager inheritanceManager = new InheritanceManager(
        _libraryElement,
        includeAbstractFromSuperclasses: true);

    unit.accept(new BestPracticesVerifier(
        errorReporter, _typeProvider, _libraryElement, inheritanceManager,
        typeSystem: _context.typeSystem));

    unit.accept(new OverrideVerifier(errorReporter, inheritanceManager));

    new ToDoFinder(errorReporter).findIn(unit);

    // Verify imports.
    {
      ImportsVerifier verifier = new ImportsVerifier();
      verifier.addImports(unit);
      _usedImportedElementsList.forEach(verifier.removeUsedElements);
      verifier.generateDuplicateImportHints(errorReporter);
      verifier.generateUnusedImportHints(errorReporter);
      verifier.generateUnusedShownNameHints(errorReporter);
    }

    // Unused local elements.
    {
      UsedLocalElements usedElements =
          new UsedLocalElements.merge(_usedLocalElementsList);
      UnusedLocalElementsVerifier visitor =
          new UnusedLocalElementsVerifier(errorListener, usedElements);
      unit.accept(visitor);
    }
  }

  void _computeLints(FileState file, CompilationUnit unit) {
    if (file.source == null) {
      return;
    }

    ErrorReporter errorReporter = _getErrorReporter(file);

    List<AstVisitor> visitors = <AstVisitor>[];
    for (Linter linter in _analysisOptions.lintRules) {
      AstVisitor visitor = linter.getVisitor();
      if (visitor != null) {
        linter.reporter = errorReporter;
        if (_analysisOptions.enableTiming) {
          visitor = new TimedAstVisitor(visitor, lintRegistry.getTimer(linter));
        }
        visitors.add(visitor);
      }
    }

    AstVisitor visitor = new ExceptionHandlingDelegatingAstVisitor(
        visitors, ExceptionHandlingDelegatingAstVisitor.logException);

    unit.accept(visitor);
  }

  void _computePendingMissingRequiredParameters(
      FileState file, CompilationUnit unit) {
    // TODO(scheglov) This can be done without "pending" if we resynthesize.
    var computer = new RequiredConstantsComputer(file.source);
    unit.accept(computer);
    _constants.addAll(computer.requiredConstants);
    _fileToPendingErrors[file] = computer.pendingErrors;
  }

  void _computeVerifyErrors(FileState file, CompilationUnit unit) {
    if (file.source == null) {
      return;
    }

    RecordingErrorListener errorListener = _getErrorListener(file);

    if (_analysisOptions.strongMode) {
      AnalysisOptionsImpl options = _analysisOptions as AnalysisOptionsImpl;
      CodeChecker checker = new CodeChecker(
          _typeProvider,
          new StrongTypeSystemImpl(_typeProvider,
              implicitCasts: options.implicitCasts,
              declarationCasts: options.declarationCasts,
              nonnullableTypes: options.nonnullableTypes),
          errorListener,
          options);
      checker.visitCompilationUnit(unit);
    }

    ErrorReporter errorReporter = _getErrorReporter(file);

    //
    // Validate the directives.
    //
    _validateUriBasedDirectives(file, unit);

    //
    // Use the ConstantVerifier to compute errors.
    //
    ConstantVerifier constantVerifier = new ConstantVerifier(
        errorReporter, _libraryElement, _typeProvider, _declaredVariables);
    unit.accept(constantVerifier);

    //
    // Use the ErrorVerifier to compute errors.
    //
    ErrorVerifier errorVerifier = new ErrorVerifier(
        errorReporter,
        _libraryElement,
        _typeProvider,
        new InheritanceManager(_libraryElement),
        _analysisOptions.enableSuperMixins);
    unit.accept(errorVerifier);
  }

  /**
   * Return a subset of the given [errors] that are not marked as ignored in
   * the [file].
   */
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
      int errorLine = lineInfo.getLocation(error.offset).lineNumber;
      String errorCode = error.errorCode.name.toLowerCase();
      // Ignores can be on the line or just preceding the error.
      return ignoreInfo.ignoredAt(errorCode, errorLine) ||
          ignoreInfo.ignoredAt(errorCode, errorLine - 1);
    }

    return errors.where((AnalysisError e) => !isIgnored(e)).toList();
  }

  RecordingErrorListener _getErrorListener(FileState file) =>
      _errorListeners.putIfAbsent(file, () => new RecordingErrorListener());

  ErrorReporter _getErrorReporter(FileState file) {
    return _errorReporters.putIfAbsent(file, () {
      RecordingErrorListener listener = _getErrorListener(file);
      return new ErrorReporter(listener, file.source);
    });
  }

  /**
   * Return the name of the library that the given part is declared to be a
   * part of, or `null` if the part does not contain a part-of directive.
   */
  _NameOrSource _getPartLibraryNameOrUri(Source partSource,
      CompilationUnit partUnit, List<Directive> directivesToResolve) {
    for (Directive directive in partUnit.directives) {
      if (directive is PartOfDirective) {
        directivesToResolve.add(directive);
        LibraryIdentifier libraryName = directive.libraryName;
        if (libraryName != null) {
          return new _NameOrSource(libraryName.name, null);
        }
        String uri = directive.uri?.stringValue;
        if (uri != null) {
          Source librarySource = _sourceFactory.resolveUri(partSource, uri);
          if (librarySource != null) {
            return new _NameOrSource(null, librarySource);
          }
        }
      }
    }
    return null;
  }

  /**
   * Return `true` if the given [source] is a library.
   */
  bool _isLibrarySource(Source source) {
    return _isLibraryUri(source.uri);
  }

  /**
   * Return a new parsed unresolved [CompilationUnit].
   */
  CompilationUnit _parse(FileState file) {
    RecordingErrorListener errorListener = _getErrorListener(file);
    String content = file.content;
    CompilationUnit unit = file.parse(errorListener);

    LineInfo lineInfo = unit.lineInfo;
    _fileToLineInfo[file] = lineInfo;
    _fileToIgnoreInfo[file] = IgnoreInfo.calculateIgnores(content, lineInfo);

    return unit;
  }

  void _resolveDirectives(Map<FileState, CompilationUnit> units) {
    CompilationUnit definingCompilationUnit = units[_library];
    definingCompilationUnit.element = _libraryElement.definingCompilationUnit;

    bool matchNodeElement(Directive node, Element element) {
      if (_enableKernelDriver) {
        return node.keyword.offset == element.nameOffset;
      } else {
        return node.offset == element.nameOffset;
      }
    }

    ErrorReporter libraryErrorReporter = _getErrorReporter(_library);
    LibraryIdentifier libraryNameNode = null;
    bool hasPartDirective = false;
    var seenPartSources = new Set<Source>();
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
            Source source = importElement.importedLibrary?.source;
            if (source != null && !_isLibrarySource(source)) {
              ErrorCode errorCode = importElement.isDeferred
                  ? StaticWarningCode.IMPORT_OF_NON_LIBRARY
                  : CompileTimeErrorCode.IMPORT_OF_NON_LIBRARY;
              libraryErrorReporter.reportErrorForNode(
                  errorCode, directive.uri, [directive.uri]);
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
        hasPartDirective = true;
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
        if (_context.exists(partSource)) {
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
                    ResolverErrorCode.PART_OF_UNNAMED_LIBRARY, partUri, [name]);
              } else if (libraryNameNode.name != name) {
                libraryErrorReporter.reportErrorForNode(
                    StaticWarningCode.PART_OF_DIFFERENT_LIBRARY,
                    partUri,
                    [libraryNameNode.name, name]);
              }
            } else {
              Source source = nameOrSource.source;
              if (source != _library.source) {
                libraryErrorReporter.reportErrorForNode(
                    StaticWarningCode.PART_OF_DIFFERENT_LIBRARY,
                    partUri,
                    [_library.uriStr, source.uri]);
              }
            }
          }
        }
      }
    }

    if (hasPartDirective &&
        libraryNameNode == null &&
        !_context.analysisOptions.enableUriInPartOf) {
      libraryErrorReporter.reportErrorForOffset(
          ResolverErrorCode.MISSING_LIBRARY_DIRECTIVE_WITH_PART, 0, 0);
    }

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

    CompilationUnitElement unitElement = unit.element;

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

    new DeclarationResolver(enableKernelDriver: _enableKernelDriver)
        .resolve(unit, unitElement);

    // TODO(scheglov) remove EnumMemberBuilder class

    new TypeParameterBoundsResolver(
            _typeProvider, _libraryElement, source, errorListener)
        .resolveTypeBounds(unit);

    unit.accept(new TypeResolverVisitor(
        _libraryElement, source, _typeProvider, errorListener));

    LibraryScope libraryScope = new LibraryScope(_libraryElement);
    unit.accept(new VariableResolverVisitor(
        _libraryElement, source, _typeProvider, errorListener,
        nameScope: libraryScope));

    unit.accept(new PartialResolverVisitor(_libraryElement, source,
        _typeProvider, AnalysisErrorListener.NULL_LISTENER));

    // Nothing for RESOLVED_UNIT8?
    // Nothing for RESOLVED_UNIT9?
    // Nothing for RESOLVED_UNIT10?

    unit.accept(new ResolverVisitor(
        _libraryElement, source, _typeProvider, errorListener));

    //
    // Find constants to compute.
    //
    {
      ConstantFinder constantFinder = new ConstantFinder();
      unit.accept(constantFinder);
      _constants.addAll(constantFinder.constantsToCompute);
    }

    //
    // Find constant dependencies to compute.
    //
    {
      var finder = new ConstantExpressionsDependenciesFinder();
      unit.accept(finder);
      _constants.addAll(finder.dependencies);
    }
  }

  /**
   * Return the result of resolve the given [uriContent], reporting errors
   * against the [uriLiteral].
   */
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
    }
  }

  /**
   * Check the given [directive] to see if the referenced source exists and
   * report an error if it does not.
   */
  void _validateUriBasedDirective(
      FileState file, UriBasedDirectiveImpl directive) {
    Source source = directive.uriSource;
    if (source != null) {
      if (_context.exists(source)) {
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
    if (_isGenerated(source)) {
      errorCode = CompileTimeErrorCode.URI_HAS_NOT_BEEN_GENERATED;
    }
    _getErrorReporter(file)
        .reportErrorForNode(errorCode, uriLiteral, [directive.uriContent]);
  }

  /**
   * Check each directive in the given [unit] to see if the referenced source
   * exists and report an error if it does not.
   */
  void _validateUriBasedDirectives(FileState file, CompilationUnit unit) {
    for (Directive directive in unit.directives) {
      if (directive is UriBasedDirective) {
        _validateUriBasedDirective(file, directive);
      }
    }
  }

  /**
   * Return `true` if the given [source] refers to a file that is assumed to be
   * generated.
   */
  static bool _isGenerated(Source source) {
    if (source == null) {
      return false;
    }
    // TODO(brianwilkerson) Generalize this mechanism.
    const List<String> suffixes = const <String>[
      '.g.dart',
      '.pb.dart',
      '.pbenum.dart',
      '.pbserver.dart',
      '.pbjson.dart',
      '.template.dart'
    ];
    String fullName = source.fullName;
    for (String suffix in suffixes) {
      if (fullName.endsWith(suffix)) {
        return true;
      }
    }
    return false;
  }
}

/**
 * Analysis result for single file.
 */
class UnitAnalysisResult {
  final FileState file;
  final CompilationUnit unit;
  final List<AnalysisError> errors;

  UnitAnalysisResult(this.file, this.unit, this.errors);
}

/**
 * [Node] that is used to compute constants in dependency order.
 */
class _ConstantNode extends Node<_ConstantNode> {
  final ConstantEvaluationEngine evaluationEngine;
  final Map<ConstantEvaluationTarget, _ConstantNode> nodeMap;
  final ConstantEvaluationTarget constant;

  bool isEvaluated = false;

  _ConstantNode(this.evaluationEngine, this.nodeMap, this.constant);

  @override
  List<_ConstantNode> computeDependencies() {
    List<ConstantEvaluationTarget> targets = [];
    evaluationEngine.computeDependencies(constant, targets.add);
    return targets.map(_getNode).toList();
  }

  _ConstantNode _getNode(ConstantEvaluationTarget constant) {
    return nodeMap.putIfAbsent(
        constant, () => new _ConstantNode(evaluationEngine, nodeMap, constant));
  }
}

/**
 * [DependencyWalker] for computing constants and detecting cycles.
 */
class _ConstantWalker extends DependencyWalker<_ConstantNode> {
  final ConstantEvaluationEngine evaluationEngine;

  _ConstantWalker(this.evaluationEngine);

  @override
  void evaluate(_ConstantNode node) {
    evaluationEngine.computeConstantValue(node.constant);
    node.isEvaluated = true;
  }

  @override
  void evaluateScc(List<_ConstantNode> scc) {
    var constantsInCycle = scc.map((node) => node.constant);
    for (_ConstantNode node in scc) {
      if (node.constant is ConstructorElementImpl) {
        (node.constant as ConstructorElementImpl).isCycleFree = false;
      }
      evaluationEngine.generateCycleError(constantsInCycle, node.constant);
      node.isEvaluated = true;
    }
  }
}

/**
 * Either the name or the source associated with a part-of directive.
 */
class _NameOrSource {
  final String name;
  final Source source;
  _NameOrSource(this.name, this.source);
}
