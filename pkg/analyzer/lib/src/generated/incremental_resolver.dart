// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.generated.incremental_resolver;

import 'dart:collection';
import 'dart:math' as math;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/src/context/cache.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/element/builder.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/resolver/inheritance_manager.dart';
import 'package:analyzer/src/dart/scanner/reader.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/generated/constant.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/error_verifier.dart';
import 'package:analyzer/src/generated/incremental_logger.dart'
    show logger, LoggingTimer;
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/task/dart.dart';
import 'package:analyzer/task/dart.dart';
import 'package:analyzer/task/general.dart' show CONTENT, LINE_INFO;
import 'package:analyzer/task/model.dart';

/**
 * The [Delta] implementation used by incremental resolver.
 * It keeps Dart results that are either don't change or are updated.
 */
class IncrementalBodyDelta extends Delta {
  /**
   * The offset of the changed contents.
   */
  final int updateOffset;

  /**
   * The end of the changed contents in the old unit.
   */
  final int updateEndOld;

  /**
   * The end of the changed contents in the new unit.
   */
  final int updateEndNew;

  /**
   * The delta between [updateEndNew] and [updateEndOld].
   */
  final int updateDelta;

  IncrementalBodyDelta(Source source, this.updateOffset, this.updateEndOld,
      this.updateEndNew, this.updateDelta)
      : super(source);

  @override
  DeltaResult validate(InternalAnalysisContext context, AnalysisTarget target,
      ResultDescriptor descriptor, Object value) {
    // A body change delta should never leak outside its source.
    // It can cause invalidation of results (e.g. hints) in other sources,
    // but only when a result in the updated source is INVALIDATE_NO_DELTA.
    if (target.source != source) {
      return DeltaResult.STOP;
    }
    // don't invalidate results of standard Dart tasks
    bool isByTask(TaskDescriptor taskDescriptor) {
      return taskDescriptor.results.contains(descriptor);
    }

    if (descriptor == CONTENT) {
      return DeltaResult.KEEP_CONTINUE;
    }
    if (target is LibrarySpecificUnit && target.unit != source) {
      if (isByTask(GatherUsedLocalElementsTask.DESCRIPTOR) ||
          isByTask(GatherUsedImportedElementsTask.DESCRIPTOR)) {
        return DeltaResult.KEEP_CONTINUE;
      }
    }
    if (isByTask(BuildCompilationUnitElementTask.DESCRIPTOR) ||
        isByTask(BuildDirectiveElementsTask.DESCRIPTOR) ||
        isByTask(BuildEnumMemberElementsTask.DESCRIPTOR) ||
        isByTask(BuildExportNamespaceTask.DESCRIPTOR) ||
        isByTask(BuildLibraryElementTask.DESCRIPTOR) ||
        isByTask(BuildPublicNamespaceTask.DESCRIPTOR) ||
        isByTask(BuildSourceExportClosureTask.DESCRIPTOR) ||
        isByTask(ComputeConstantDependenciesTask.DESCRIPTOR) ||
        isByTask(ComputeConstantValueTask.DESCRIPTOR) ||
        isByTask(ComputeInferableStaticVariableDependenciesTask.DESCRIPTOR) ||
        isByTask(ComputeLibraryCycleTask.DESCRIPTOR) ||
        isByTask(DartErrorsTask.DESCRIPTOR) ||
        isByTask(ReadyLibraryElement2Task.DESCRIPTOR) ||
        isByTask(ReadyLibraryElement5Task.DESCRIPTOR) ||
        isByTask(ReadyLibraryElement7Task.DESCRIPTOR) ||
        isByTask(ReadyResolvedUnitTask.DESCRIPTOR) ||
        isByTask(EvaluateUnitConstantsTask.DESCRIPTOR) ||
        isByTask(GenerateHintsTask.DESCRIPTOR) ||
        isByTask(InferInstanceMembersInUnitTask.DESCRIPTOR) ||
        isByTask(InferStaticVariableTypesInUnitTask.DESCRIPTOR) ||
        isByTask(InferStaticVariableTypeTask.DESCRIPTOR) ||
        isByTask(LibraryErrorsReadyTask.DESCRIPTOR) ||
        isByTask(LibraryUnitErrorsTask.DESCRIPTOR) ||
        isByTask(ParseDartTask.DESCRIPTOR) ||
        isByTask(PartiallyResolveUnitReferencesTask.DESCRIPTOR) ||
        isByTask(ScanDartTask.DESCRIPTOR) ||
        isByTask(ResolveConstantExpressionTask.DESCRIPTOR) ||
        isByTask(ResolveDirectiveElementsTask.DESCRIPTOR) ||
        isByTask(ResolvedUnit7InLibraryClosureTask.DESCRIPTOR) ||
        isByTask(ResolvedUnit7InLibraryTask.DESCRIPTOR) ||
        isByTask(ResolveInstanceFieldsInUnitTask.DESCRIPTOR) ||
        isByTask(ResolveLibraryReferencesTask.DESCRIPTOR) ||
        isByTask(ResolveLibraryTask.DESCRIPTOR) ||
        isByTask(ResolveLibraryTypeNamesTask.DESCRIPTOR) ||
        isByTask(ResolveTopLevelLibraryTypeBoundsTask.DESCRIPTOR) ||
        isByTask(ResolveTopLevelUnitTypeBoundsTask.DESCRIPTOR) ||
        isByTask(ResolveUnitTask.DESCRIPTOR) ||
        isByTask(ResolveUnitTypeNamesTask.DESCRIPTOR) ||
        isByTask(ResolveVariableReferencesTask.DESCRIPTOR) ||
        isByTask(StrongModeVerifyUnitTask.DESCRIPTOR) ||
        isByTask(VerifyUnitTask.DESCRIPTOR)) {
      return DeltaResult.KEEP_CONTINUE;
    }
    // invalidate all the other results
    return DeltaResult.INVALIDATE_NO_DELTA;
  }
}

/**
 * Instances of the class [IncrementalResolver] resolve the smallest portion of
 * an AST structure that we currently know how to resolve.
 */
class IncrementalResolver {
  /**
   * The element of the compilation unit being resolved.
   */
  final CompilationUnitElementImpl _definingUnit;

  /**
   * The context the compilation unit being resolved in.
   */
  final AnalysisContext _context;

  /**
   * The object used to access the types from the core library.
   */
  final TypeProvider _typeProvider;

  /**
   * The type system primitives.
   */
  final TypeSystem _typeSystem;

  /**
   * The element for the library containing the compilation unit being resolved.
   */
  final LibraryElementImpl _definingLibrary;

  final AnalysisCache _cache;

  /**
   * The [CacheEntry] corresponding to the source being resolved.
   */
  final CacheEntry newSourceEntry;

  /**
   * The [CacheEntry] corresponding to the [LibrarySpecificUnit] being resolved.
   */
  final CacheEntry newUnitEntry;

  /**
   * The source representing the compilation unit being visited.
   */
  final Source _source;

  /**
   * The source representing the library of the compilation unit being visited.
   */
  final Source _librarySource;

  /**
   * The offset of the changed contents.
   */
  final int _updateOffset;

  /**
   * The end of the changed contents in the old unit.
   */
  final int _updateEndOld;

  /**
   * The end of the changed contents in the new unit.
   */
  final int _updateEndNew;

  /**
   * The delta between [_updateEndNew] and [_updateEndOld].
   */
  final int _updateDelta;

  /**
   * The set of [AnalysisError]s that have been already shifted.
   */
  final Set<AnalysisError> _alreadyShiftedErrors = new HashSet.identity();

  final RecordingErrorListener errorListener = new RecordingErrorListener();
  ResolutionContext _resolutionContext;

  List<AnalysisError> _resolveErrors = AnalysisError.NO_ERRORS;
  List<AnalysisError> _verifyErrors = AnalysisError.NO_ERRORS;

  /**
   * Initialize a newly created incremental resolver to resolve a node in the
   * given source in the given library.
   */
  IncrementalResolver(
      this._cache,
      this.newSourceEntry,
      this.newUnitEntry,
      CompilationUnitElementImpl definingUnit,
      this._updateOffset,
      int updateEndOld,
      int updateEndNew)
      : _definingUnit = definingUnit,
        _context = definingUnit.context,
        _typeProvider = definingUnit.context.typeProvider,
        _typeSystem = definingUnit.context.typeSystem,
        _definingLibrary = definingUnit.library,
        _source = definingUnit.source,
        _librarySource = definingUnit.library.source,
        _updateEndOld = updateEndOld,
        _updateEndNew = updateEndNew,
        _updateDelta = updateEndNew - updateEndOld;

  /**
   * Resolve [body], reporting any errors or warnings to the given listener.
   *
   * [body] - the root of the AST structure to be resolved.
   */
  void resolve(BlockFunctionBody body) {
    logger.enter('resolve: $_definingUnit');
    try {
      Declaration executable = _findResolutionRoot(body);
      _prepareResolutionContext(executable);
      // update elements
      _updateCache();
      _updateElementNameOffsets();
      _buildElements(executable, body);
      // resolve
      _resolveReferences(executable);
      _computeConstants(executable);
      _resolveErrors = errorListener.getErrorsForSource(_source);
      // verify
      _verify(executable);
      _context.invalidateLibraryHints(_librarySource);
      // update entry errors
      _updateEntry();
    } finally {
      logger.exit();
    }
  }

  void _buildElements(Declaration executable, AstNode node) {
    LoggingTimer timer = logger.startTimer();
    try {
      ElementHolder holder = new ElementHolder();
      node.accept(new LocalElementBuilder(holder, _definingUnit));
      // Move local elements into the ExecutableElementImpl.
      ExecutableElementImpl executableElement =
          executable.element as ExecutableElementImpl;
      executableElement.localVariables = holder.localVariables;
      executableElement.functions = holder.functions;
      executableElement.labels = holder.labels;
      holder.validate();
    } finally {
      timer.stop('build elements');
    }
  }

  /**
   * Compute a value for all of the constants in the given [node].
   */
  void _computeConstants(AstNode node) {
    // compute values
    {
      CompilationUnit unit = node.getAncestor((n) => n is CompilationUnit);
      ConstantValueComputer computer = new ConstantValueComputer(
          _typeProvider, _context.declaredVariables, null, _typeSystem);
      computer.add(unit);
      computer.computeValues();
    }
    // validate
    {
      ErrorReporter errorReporter = new ErrorReporter(errorListener, _source);
      ConstantVerifier constantVerifier = new ConstantVerifier(errorReporter,
          _definingLibrary, _typeProvider, _context.declaredVariables);
      node.accept(constantVerifier);
    }
  }

  /**
   * Starting at [node], find the smallest AST node that can be resolved
   * independently of any other nodes. Return the node that was found.
   *
   * [node] - the node at which the search is to begin
   *
   * Throws [AnalysisException] if there is no such node.
   */
  Declaration _findResolutionRoot(AstNode node) {
    while (node != null) {
      if (node is ConstructorDeclaration ||
          node is FunctionDeclaration ||
          node is MethodDeclaration) {
        return node;
      }
      node = node.parent;
    }
    throw new AnalysisException("Cannot resolve node: no resolvable node");
  }

  void _prepareResolutionContext(AstNode node) {
    if (_resolutionContext == null) {
      _resolutionContext = ResolutionContextBuilder.contextFor(node);
    }
  }

  _resolveReferences(AstNode node) {
    LoggingTimer timer = logger.startTimer();
    try {
      _prepareResolutionContext(node);
      Scope scope = _resolutionContext.scope;
      // resolve types
      {
        TypeResolverVisitor visitor = new TypeResolverVisitor(
            _definingLibrary, _source, _typeProvider, errorListener,
            nameScope: scope);
        node.accept(visitor);
      }
      // resolve variables
      {
        VariableResolverVisitor visitor = new VariableResolverVisitor(
            _definingLibrary, _source, _typeProvider, errorListener,
            nameScope: scope);
        node.accept(visitor);
      }
      // resolve references
      {
        ResolverVisitor visitor = new ResolverVisitor(
            _definingLibrary, _source, _typeProvider, errorListener,
            nameScope: scope);
        if (_resolutionContext.enclosingClassDeclaration != null) {
          visitor.visitClassDeclarationIncrementally(
              _resolutionContext.enclosingClassDeclaration);
        }
        if (node is Comment) {
          visitor.resolveOnlyCommentInFunctionBody = true;
          node = node.parent;
        }
        visitor.initForIncrementalResolution();
        node.accept(visitor);
      }
    } finally {
      timer.stop('resolve references');
    }
  }

  void _shiftEntryErrors() {
    _shiftErrors_NEW(HINTS);
    _shiftErrors_NEW(LINTS);
    _shiftErrors_NEW(LIBRARY_UNIT_ERRORS);
    _shiftErrors_NEW(RESOLVE_TYPE_NAMES_ERRORS);
    _shiftErrors_NEW(RESOLVE_TYPE_BOUNDS_ERRORS);
    _shiftErrors_NEW(RESOLVE_UNIT_ERRORS);
    _shiftErrors_NEW(STATIC_VARIABLE_RESOLUTION_ERRORS_IN_UNIT);
    _shiftErrors_NEW(STRONG_MODE_ERRORS);
    _shiftErrors_NEW(VARIABLE_REFERENCE_ERRORS);
    _shiftErrors_NEW(VERIFY_ERRORS);
  }

  void _shiftErrors(List<AnalysisError> errors) {
    for (AnalysisError error in errors) {
      if (_alreadyShiftedErrors.add(error)) {
        int errorOffset = error.offset;
        if (errorOffset > _updateOffset) {
          error.offset += _updateDelta;
        }
      }
    }
  }

  void _shiftErrors_NEW(ResultDescriptor<List<AnalysisError>> descriptor) {
    List<AnalysisError> errors = newUnitEntry.getValue(descriptor);
    _shiftErrors(errors);
  }

  void _updateCache() {
    if (newSourceEntry != null) {
      LoggingTimer timer = logger.startTimer();
      try {
        newSourceEntry.setState(CONTENT, CacheState.INVALID,
            delta: new IncrementalBodyDelta(_source, _updateOffset,
                _updateEndOld, _updateEndNew, _updateDelta));
      } finally {
        timer.stop('invalidate cache with delta');
      }
    }
  }

  void _updateElementNameOffsets() {
    LoggingTimer timer = logger.startTimer();
    try {
      _definingUnit.accept(
          new _ElementOffsetUpdater(_updateOffset, _updateDelta, _cache));
      _definingUnit.afterIncrementalResolution();
    } finally {
      timer.stop('update element offsets');
    }
  }

  void _updateEntry() {
    _updateErrors_NEW(RESOLVE_TYPE_NAMES_ERRORS, []);
    _updateErrors_NEW(RESOLVE_TYPE_BOUNDS_ERRORS, []);
    _updateErrors_NEW(RESOLVE_UNIT_ERRORS, _resolveErrors);
    _updateErrors_NEW(VARIABLE_REFERENCE_ERRORS, []);
    _updateErrors_NEW(VERIFY_ERRORS, _verifyErrors);
    // invalidate results we don't update incrementally
    newUnitEntry.setState(STRONG_MODE_ERRORS, CacheState.INVALID);
    newUnitEntry.setState(USED_IMPORTED_ELEMENTS, CacheState.INVALID);
    newUnitEntry.setState(USED_LOCAL_ELEMENTS, CacheState.INVALID);
    newUnitEntry.setState(HINTS, CacheState.INVALID);
    newUnitEntry.setState(LINTS, CacheState.INVALID);
  }

  List<AnalysisError> _updateErrors(
      List<AnalysisError> oldErrors, List<AnalysisError> newErrors) {
    List<AnalysisError> errors = new List<AnalysisError>();
    // add updated old errors
    for (AnalysisError error in oldErrors) {
      int errorOffset = error.offset;
      if (errorOffset < _updateOffset) {
        errors.add(error);
      } else if (errorOffset > _updateEndOld) {
        error.offset += _updateDelta;
        errors.add(error);
      }
    }
    // add new errors
    for (AnalysisError error in newErrors) {
      int errorOffset = error.offset;
      if (errorOffset > _updateOffset && errorOffset < _updateEndNew) {
        errors.add(error);
      }
    }
    // done
    return errors;
  }

  void _updateErrors_NEW(ResultDescriptor<List<AnalysisError>> descriptor,
      List<AnalysisError> newErrors) {
    List<AnalysisError> oldErrors = newUnitEntry.getValue(descriptor);
    List<AnalysisError> errors = _updateErrors(oldErrors, newErrors);
    newUnitEntry.setValueIncremental(descriptor, errors, true);
  }

  void _verify(AstNode node) {
    LoggingTimer timer = logger.startTimer();
    try {
      RecordingErrorListener errorListener = new RecordingErrorListener();
      ErrorReporter errorReporter = new ErrorReporter(errorListener, _source);
      ErrorVerifier errorVerifier = new ErrorVerifier(
          errorReporter,
          _definingLibrary,
          _typeProvider,
          new InheritanceManager(_definingLibrary),
          _context.analysisOptions.enableSuperMixins);
      if (_resolutionContext.enclosingClassDeclaration != null) {
        errorVerifier.visitClassDeclarationIncrementally(
            _resolutionContext.enclosingClassDeclaration);
      }
      node.accept(errorVerifier);
      _verifyErrors = errorListener.getErrorsForSource(_source);
    } finally {
      timer.stop('verify');
    }
  }
}

class PoorMansIncrementalResolver {
  final TypeProvider _typeProvider;
  final Source _unitSource;
  final AnalysisCache _cache;

  /**
   * The [CacheEntry] corresponding to the source being resolved.
   */
  final CacheEntry _sourceEntry;

  /**
   * The [CacheEntry] corresponding to the [LibrarySpecificUnit] being resolved.
   */
  final CacheEntry _unitEntry;

  final CompilationUnit _oldUnit;
  CompilationUnitElement _unitElement;

  int _updateOffset;
  int _updateDelta;
  int _updateEndOld;
  int _updateEndNew;

  LineInfo _newLineInfo;
  List<AnalysisError> _newScanErrors = <AnalysisError>[];
  List<AnalysisError> _newParseErrors = <AnalysisError>[];

  PoorMansIncrementalResolver(
      this._typeProvider,
      this._unitSource,
      this._cache,
      this._sourceEntry,
      this._unitEntry,
      this._oldUnit,
      bool resolveApiChanges);

  /**
   * Attempts to update [_oldUnit] to the state corresponding to [newCode].
   * Returns `true` if success, or `false` otherwise.
   * The [_oldUnit] might be damaged.
   */
  bool resolve(String newCode) {
    logger.enter('diff/resolve $_unitSource');
    try {
      // prepare old unit
      if (!_areCurlyBracketsBalanced(_oldUnit.beginToken)) {
        logger.log('Unbalanced number of curly brackets in the old unit.');
        return false;
      }
      _unitElement = _oldUnit.element;
      // prepare new unit
      CompilationUnit newUnit = _parseUnit(newCode);
      if (!_areCurlyBracketsBalanced(newUnit.beginToken)) {
        logger.log('Unbalanced number of curly brackets in the new unit.');
        return false;
      }
      // find difference
      _TokenPair firstPair =
          _findFirstDifferentToken(_oldUnit.beginToken, newUnit.beginToken);
      _TokenPair lastPair =
          _findLastDifferentToken(_oldUnit.endToken, newUnit.endToken);
      if (firstPair != null && lastPair != null) {
        int firstOffsetOld = firstPair.oldToken.offset;
        int firstOffsetNew = firstPair.newToken.offset;
        int lastOffsetOld = lastPair.oldToken.end;
        int lastOffsetNew = lastPair.newToken.end;
        int beginOffsetOld = math.min(firstOffsetOld, lastOffsetOld);
        int endOffsetOld = math.max(firstOffsetOld, lastOffsetOld);
        int beginOffsetNew = math.min(firstOffsetNew, lastOffsetNew);
        int endOffsetNew = math.max(firstOffsetNew, lastOffsetNew);
        // A pure whitespace change.
        if (identical(firstPair.oldToken, lastPair.oldToken) &&
            identical(firstPair.newToken, lastPair.newToken) &&
            firstPair.kind == _TokenDifferenceKind.OFFSET) {
          _updateOffset = beginOffsetOld - 1;
          _updateEndOld = endOffsetOld;
          _updateEndNew = endOffsetNew;
          _updateDelta = newUnit.length - _oldUnit.length;
          logger.log('Whitespace change.');
          _shiftTokens(firstPair.oldToken, true);
          IncrementalResolver incrementalResolver = new IncrementalResolver(
              _cache,
              _sourceEntry,
              _unitEntry,
              _unitElement,
              _updateOffset,
              _updateEndOld,
              _updateEndNew);
          incrementalResolver._updateCache();
          incrementalResolver._updateElementNameOffsets();
          incrementalResolver._shiftEntryErrors();
          _updateEntry();
          logger.log('Success.');
          return true;
        }
        // A Dart documentation comment change.
        {
          Token firstOldToken = firstPair.oldToken;
          Token firstNewToken = firstPair.newToken;
          Token lastOldToken = lastPair.oldToken;
          Token lastNewToken = lastPair.newToken;
          if (firstOldToken is DocumentationCommentToken &&
              firstNewToken is DocumentationCommentToken &&
              lastOldToken is DocumentationCommentToken &&
              lastNewToken is DocumentationCommentToken &&
              identical(firstOldToken.parent, lastOldToken.parent) &&
              identical(firstNewToken.parent, lastNewToken.parent)) {
            _updateOffset = beginOffsetOld;
            _updateEndOld = firstOldToken.parent.offset;
            _updateEndNew = firstNewToken.parent.offset;
            _updateDelta = newUnit.length - _oldUnit.length;
            bool success =
                _resolveCommentDoc(newUnit, firstOldToken, firstNewToken);
            logger.log('Documentation comment resolved: $success');
            return success;
          }
        }
        // Find nodes covering the "old" and "new" token ranges.
        AstNode oldNode =
            _findNodeCovering(_oldUnit, beginOffsetOld, endOffsetOld - 1);
        AstNode newNode =
            _findNodeCovering(newUnit, beginOffsetNew, endOffsetNew - 1);
        logger.log(() => 'oldNode: $oldNode');
        logger.log(() => 'newNode: $newNode');
        // Try to find the smallest common node, a FunctionBody currently.
        {
          List<AstNode> oldParents = _getParents(oldNode);
          List<AstNode> newParents = _getParents(newNode);
          // fail if an initializer change
          if (oldParents.any((n) => n is ConstructorInitializer) ||
              newParents.any((n) => n is ConstructorInitializer)) {
            logger.log('Failure: a change in a constructor initializer');
            return false;
          }
          // find matching methods / bodies
          int length = math.min(oldParents.length, newParents.length);
          bool found = false;
          for (int i = 0; i < length; i++) {
            AstNode oldParent = oldParents[i];
            AstNode newParent = newParents[i];
            if (oldParent is CompilationUnit && newParent is CompilationUnit) {
              int oldLength = oldParent.declarations.length;
              int newLength = newParent.declarations.length;
              if (oldLength != newLength) {
                logger.log(
                    'Failure: unit declarations mismatch $oldLength vs. $newLength');
                return false;
              }
            } else if (oldParent is ClassDeclaration &&
                newParent is ClassDeclaration) {
              int oldLength = oldParent.members.length;
              int newLength = newParent.members.length;
              if (oldLength != newLength) {
                logger.log(
                    'Failure: class declarations mismatch $oldLength vs. $newLength');
                return false;
              }
            } else if (oldParent is FunctionDeclaration &&
                    newParent is FunctionDeclaration ||
                oldParent is ConstructorDeclaration &&
                    newParent is ConstructorDeclaration ||
                oldParent is MethodDeclaration &&
                    newParent is MethodDeclaration) {
              if (oldParents.length == i || newParents.length == i) {
                return false;
              }
            } else if (oldParent is FunctionBody && newParent is FunctionBody) {
              if (oldParent is BlockFunctionBody &&
                  newParent is BlockFunctionBody) {
                if (oldParent.isAsynchronous != newParent.isAsynchronous) {
                  logger.log('Failure: body async mismatch.');
                  return false;
                }
                if (oldParent.isGenerator != newParent.isGenerator) {
                  logger.log('Failure: body generator mismatch.');
                  return false;
                }
                oldNode = oldParent;
                newNode = newParent;
                found = true;
                break;
              }
              logger.log('Failure: not a block function body.');
              return false;
            } else if (oldParent is FunctionExpression &&
                newParent is FunctionExpression) {
              // skip
            } else {
              logger.log('Failure: old and new parent mismatch'
                  ' ${oldParent.runtimeType} vs. ${newParent.runtimeType}');
              return false;
            }
          }
          if (!found) {
            logger.log('Failure: no enclosing function body or executable.');
            return false;
          }
        }
        logger.log(() => 'oldNode: $oldNode');
        logger.log(() => 'newNode: $newNode');
        // prepare update range
        _updateOffset = oldNode.offset;
        _updateEndOld = oldNode.end;
        _updateEndNew = newNode.end;
        _updateDelta = _updateEndNew - _updateEndOld;
        // replace node
        NodeReplacer.replace(oldNode, newNode);
        // update token references
        {
          Token oldBeginToken = _getBeginTokenNotComment(oldNode);
          Token newBeginToken = _getBeginTokenNotComment(newNode);
          if (oldBeginToken.previous.type == TokenType.EOF) {
            _oldUnit.beginToken = newBeginToken;
          } else {
            oldBeginToken.previous.setNext(newBeginToken);
          }
          newNode.endToken.setNext(oldNode.endToken.next);
          _shiftTokens(oldNode.endToken.next);
        }
        // perform incremental resolution
        IncrementalResolver incrementalResolver = new IncrementalResolver(
            _cache,
            _sourceEntry,
            _unitEntry,
            _unitElement,
            _updateOffset,
            _updateEndOld,
            _updateEndNew);
        incrementalResolver.resolve(newNode);
        // update DartEntry
        _updateEntry();
        logger.log('Success.');
        return true;
      }
    } catch (e, st) {
      logger.logException(e, st);
      logger.log('Failure: exception.');
      // The incremental resolver log is usually turned off,
      // so also log the exception to the instrumentation log.
      AnalysisEngine.instance.logger.logError(
          'Failure in incremental resolver', new CaughtException(e, st));
    } finally {
      logger.exit();
    }
    return false;
  }

  CompilationUnit _parseUnit(String code) {
    LoggingTimer timer = logger.startTimer();
    try {
      Token token = _scan(code);
      RecordingErrorListener errorListener = new RecordingErrorListener();
      Parser parser = new Parser(_unitSource, errorListener);
      AnalysisOptions options = _unitElement.context.analysisOptions;
      parser.parseGenericMethodComments = options.strongMode;
      CompilationUnit unit = parser.parseCompilationUnit(token);
      _newParseErrors = errorListener.errors;
      return unit;
    } finally {
      timer.stop('parse');
    }
  }

  /**
   * Attempts to resolve a documentation comment change.
   * Returns `true` if success.
   */
  bool _resolveCommentDoc(
      CompilationUnit newUnit, CommentToken oldToken, CommentToken newToken) {
    if (oldToken == null || newToken == null) {
      return false;
    }
    // find nodes
    int offset = oldToken.offset;
    logger.log('offset: $offset');
    AstNode oldNode = _findNodeCovering(_oldUnit, offset, offset);
    AstNode newNode = _findNodeCovering(newUnit, offset, offset);
    if (oldNode is! Comment || newNode is! Comment) {
      return false;
    }
    Comment oldComment = oldNode;
    Comment newComment = newNode;
    logger.log('oldComment.beginToken: ${oldComment.beginToken}');
    logger.log('newComment.beginToken: ${newComment.beginToken}');
    // update token references
    _shiftTokens(oldToken.parent);
    _setPrecedingComments(oldToken.parent, newComment.tokens.first);
    // replace node
    NodeReplacer.replace(oldComment, newComment);
    // update elements
    IncrementalResolver incrementalResolver = new IncrementalResolver(
        _cache,
        _sourceEntry,
        _unitEntry,
        _unitElement,
        _updateOffset,
        _updateEndOld,
        _updateEndNew);
    incrementalResolver._updateCache();
    incrementalResolver._updateElementNameOffsets();
    incrementalResolver._shiftEntryErrors();
    _updateEntry();
    // resolve references in the comment
    incrementalResolver._resolveReferences(newComment);
    // update 'documentationComment' of the parent element(s)
    {
      AstNode parent = newComment.parent;
      if (parent is AnnotatedNode) {
        setElementDocumentationForVariables(VariableDeclarationList list) {
          for (VariableDeclaration variable in list.variables) {
            Element variableElement = variable.element;
            if (variableElement is ElementImpl) {
              setElementDocumentationComment(variableElement, parent);
            }
          }
        }

        Element parentElement = ElementLocator.locate(newComment.parent);
        if (parentElement is ElementImpl) {
          setElementDocumentationComment(parentElement, parent);
        } else if (parent is FieldDeclaration) {
          setElementDocumentationForVariables(parent.fields);
        } else if (parent is TopLevelVariableDeclaration) {
          setElementDocumentationForVariables(parent.variables);
        }
      }
    }
    // OK
    return true;
  }

  Token _scan(String code) {
    RecordingErrorListener errorListener = new RecordingErrorListener();
    CharSequenceReader reader = new CharSequenceReader(code);
    Scanner scanner = new Scanner(_unitSource, reader, errorListener);
    AnalysisOptions options = _unitElement.context.analysisOptions;
    scanner.scanGenericMethodComments = options.strongMode;
    Token token = scanner.tokenize();
    _newLineInfo = new LineInfo(scanner.lineStarts);
    _newScanErrors = errorListener.errors;
    return token;
  }

  /**
   * Set the given [comment] as a "precedingComments" for [token].
   */
  void _setPrecedingComments(Token token, CommentToken comment) {
    if (token is BeginTokenWithComment) {
      token.precedingComments = comment;
    } else if (token is KeywordTokenWithComment) {
      token.precedingComments = comment;
    } else if (token is StringTokenWithComment) {
      token.precedingComments = comment;
    } else if (token is TokenWithComment) {
      token.precedingComments = comment;
    } else {
      Type parentType = token?.runtimeType;
      throw new AnalysisException('Uknown parent token type: $parentType');
    }
  }

  void _shiftTokens(Token token, [bool goUpComment = false]) {
    while (token != null) {
      if (goUpComment && token is CommentToken) {
        token = (token as CommentToken).parent;
      }
      if (token.offset > _updateOffset) {
        token.offset += _updateDelta;
      }
      // comments
      _shiftTokens(token.precedingComments);
      if (token is DocumentationCommentToken) {
        for (Token reference in token.references) {
          _shiftTokens(reference);
        }
      }
      // next
      if (token.type == TokenType.EOF) {
        break;
      }
      token = token.next;
    }
  }

  void _updateEntry() {
    // scan results
    _sourceEntry.setValueIncremental(SCAN_ERRORS, _newScanErrors, true);
    _sourceEntry.setValueIncremental(LINE_INFO, _newLineInfo, false);
    // parse results
    _sourceEntry.setValueIncremental(PARSE_ERRORS, _newParseErrors, true);
    _sourceEntry.setValueIncremental(PARSED_UNIT, _oldUnit, false);
    // referenced names
    ReferencedNames referencedNames = new ReferencedNames(_unitSource);
    new ReferencedNamesBuilder(referencedNames).build(_oldUnit);
    _sourceEntry.setValueIncremental(REFERENCED_NAMES, referencedNames, false);
  }

  /**
   * Checks if [token] has a balanced number of open and closed curly brackets.
   */
  static bool _areCurlyBracketsBalanced(Token token) {
    int numOpen = _getTokenCount(token, TokenType.OPEN_CURLY_BRACKET);
    int numOpen2 =
        _getTokenCount(token, TokenType.STRING_INTERPOLATION_EXPRESSION);
    int numClosed = _getTokenCount(token, TokenType.CLOSE_CURLY_BRACKET);
    return numOpen + numOpen2 == numClosed;
  }

  static _TokenDifferenceKind _compareToken(
      Token oldToken, Token newToken, int delta) {
    if (oldToken == null && newToken == null) {
      return null;
    }
    if (oldToken == null || newToken == null) {
      return _TokenDifferenceKind.CONTENT;
    }
    if (oldToken.type != newToken.type) {
      return _TokenDifferenceKind.CONTENT;
    }
    if (oldToken.lexeme != newToken.lexeme) {
      return _TokenDifferenceKind.CONTENT;
    }
    if (newToken.offset - oldToken.offset != delta) {
      return _TokenDifferenceKind.OFFSET;
    }
    return null;
  }

  static _TokenPair _findFirstDifferentToken(Token oldToken, Token newToken) {
    while (oldToken.type != TokenType.EOF || newToken.type != TokenType.EOF) {
      if (oldToken.type == TokenType.EOF || newToken.type == TokenType.EOF) {
        return new _TokenPair(_TokenDifferenceKind.CONTENT, oldToken, newToken);
      }
      // compare comments
      {
        Token oldComment = oldToken.precedingComments;
        Token newComment = newToken.precedingComments;
        while (true) {
          _TokenDifferenceKind diffKind =
              _compareToken(oldComment, newComment, 0);
          if (diffKind != null) {
            return new _TokenPair(
                diffKind, oldComment ?? oldToken, newComment ?? newToken);
          }
          if (oldComment == null && newComment == null) {
            break;
          }
          oldComment = oldComment.next;
          newComment = newComment.next;
        }
      }
      // compare tokens
      _TokenDifferenceKind diffKind = _compareToken(oldToken, newToken, 0);
      if (diffKind != null) {
        return new _TokenPair(diffKind, oldToken, newToken);
      }
      // next tokens
      oldToken = oldToken.next;
      newToken = newToken.next;
    }
    // no difference
    return null;
  }

  static _TokenPair _findLastDifferentToken(Token oldToken, Token newToken) {
    int delta = newToken.offset - oldToken.offset;
    Token prevOldToken;
    Token prevNewToken;
    while (oldToken.previous != oldToken && newToken.previous != newToken) {
      // compare tokens
      _TokenDifferenceKind diffKind = _compareToken(oldToken, newToken, delta);
      if (diffKind != null) {
        return new _TokenPair(diffKind, prevOldToken, prevNewToken);
      }
      prevOldToken = oldToken;
      prevNewToken = newToken;
      // compare comments
      {
        Token oldComment = oldToken.precedingComments;
        Token newComment = newToken.precedingComments;
        while (oldComment?.next != null) {
          oldComment = oldComment.next;
        }
        while (newComment?.next != null) {
          newComment = newComment.next;
        }
        while (true) {
          _TokenDifferenceKind diffKind =
              _compareToken(oldComment, newComment, delta);
          if (diffKind != null) {
            return new _TokenPair(
                diffKind, oldComment ?? oldToken, newComment ?? newToken);
          }
          if (oldComment == null && newComment == null) {
            break;
          }
          prevOldToken = oldComment;
          prevNewToken = newComment;
          oldComment = oldComment.previous;
          newComment = newComment.previous;
        }
      }
      // next tokens
      oldToken = oldToken.previous;
      newToken = newToken.previous;
    }
    return null;
  }

  static AstNode _findNodeCovering(AstNode root, int offset, int end) {
    NodeLocator nodeLocator = new NodeLocator(offset, end);
    return nodeLocator.searchWithin(root);
  }

  static Token _getBeginTokenNotComment(AstNode node) {
    Token oldBeginToken = node.beginToken;
    if (oldBeginToken is CommentToken) {
      return oldBeginToken.parent;
    }
    return oldBeginToken;
  }

  static List<AstNode> _getParents(AstNode node) {
    List<AstNode> parents = <AstNode>[];
    while (node != null) {
      parents.insert(0, node);
      node = node.parent;
    }
    return parents;
  }

  /**
   * Returns number of tokens with the given [type].
   */
  static int _getTokenCount(Token token, TokenType type) {
    int count = 0;
    while (token.type != TokenType.EOF) {
      if (token.type == type) {
        count++;
      }
      token = token.next;
    }
    return count;
  }
}

/**
 * The context to resolve an [AstNode] in.
 */
class ResolutionContext {
  CompilationUnitElement enclosingUnit;
  ClassDeclaration enclosingClassDeclaration;
  ClassElement enclosingClass;
  Scope scope;
}

/**
 * Instances of the class [ResolutionContextBuilder] build the context for a
 * given node in an AST structure. At the moment, this class only handles
 * top-level and class-level declarations.
 */
class ResolutionContextBuilder {
  /**
   * The class containing the enclosing [CompilationUnitElement].
   */
  CompilationUnitElement _enclosingUnit;

  /**
   * The class containing the enclosing [ClassDeclaration], or `null` if we are
   * not in the scope of a class.
   */
  ClassDeclaration _enclosingClassDeclaration;

  /**
   * The class containing the enclosing [ClassElement], or `null` if we are not
   * in the scope of a class.
   */
  ClassElement _enclosingClass;

  Scope _scopeFor(AstNode node) {
    if (node is CompilationUnit) {
      return _scopeForAstNode(node);
    }
    AstNode parent = node.parent;
    if (parent == null) {
      throw new AnalysisException(
          "Cannot create scope: node is not part of a CompilationUnit");
    }
    return _scopeForAstNode(parent);
  }

  /**
   * Return the scope in which the given AST structure should be resolved.
   *
   * *Note:* This method needs to be kept in sync with
   * [IncrementalResolver.canBeResolved].
   *
   * [node] - the root of the AST structure to be resolved.
   *
   * Throws [AnalysisException] if the AST structure has not been resolved or
   * is not part of a [CompilationUnit]
   */
  Scope _scopeForAstNode(AstNode node) {
    if (node is CompilationUnit) {
      return _scopeForCompilationUnit(node);
    }
    AstNode parent = node.parent;
    if (parent == null) {
      throw new AnalysisException(
          "Cannot create scope: node is not part of a CompilationUnit");
    }
    Scope scope = _scopeForAstNode(parent);
    if (node is ClassDeclaration) {
      _enclosingClassDeclaration = node;
      _enclosingClass = node.element;
      if (_enclosingClass == null) {
        throw new AnalysisException(
            "Cannot build a scope for an unresolved class");
      }
      scope = new ClassScope(
          new TypeParameterScope(scope, _enclosingClass), _enclosingClass);
    } else if (node is ClassTypeAlias) {
      ClassElement element = node.element;
      if (element == null) {
        throw new AnalysisException(
            "Cannot build a scope for an unresolved class type alias");
      }
      scope = new ClassScope(new TypeParameterScope(scope, element), element);
    } else if (node is ConstructorDeclaration) {
      ConstructorElement element = node.element;
      if (element == null) {
        throw new AnalysisException(
            "Cannot build a scope for an unresolved constructor");
      }
      FunctionScope functionScope = new FunctionScope(scope, element);
      functionScope.defineParameters();
      scope = functionScope;
    } else if (node is FunctionDeclaration) {
      ExecutableElement element = node.element;
      if (element == null) {
        throw new AnalysisException(
            "Cannot build a scope for an unresolved function");
      }
      FunctionScope functionScope = new FunctionScope(scope, element);
      functionScope.defineParameters();
      scope = functionScope;
    } else if (node is FunctionTypeAlias) {
      scope = new FunctionTypeScope(scope, node.element);
    } else if (node is MethodDeclaration) {
      ExecutableElement element = node.element;
      if (element == null) {
        throw new AnalysisException(
            "Cannot build a scope for an unresolved method");
      }
      FunctionScope functionScope = new FunctionScope(scope, element);
      functionScope.defineParameters();
      scope = functionScope;
    }
    return scope;
  }

  Scope _scopeForCompilationUnit(CompilationUnit node) {
    _enclosingUnit = node.element;
    if (_enclosingUnit == null) {
      throw new AnalysisException(
          "Cannot create scope: compilation unit is not resolved");
    }
    LibraryElement libraryElement = _enclosingUnit.library;
    if (libraryElement == null) {
      throw new AnalysisException(
          "Cannot create scope: compilation unit is not part of a library");
    }
    return new LibraryScope(libraryElement);
  }

  /**
   * Return the context in which the given AST structure should be resolved.
   *
   * [node] - the root of the AST structure to be resolved.
   *
   * Throws [AnalysisException] if the AST structure has not been resolved or
   * is not part of a [CompilationUnit]
   */
  static ResolutionContext contextFor(AstNode node) {
    if (node == null) {
      throw new AnalysisException("Cannot create context: node is null");
    }
    // build scope
    ResolutionContextBuilder builder = new ResolutionContextBuilder();
    Scope scope = builder._scopeFor(node);
    // prepare context
    ResolutionContext context = new ResolutionContext();
    context.scope = scope;
    context.enclosingUnit = builder._enclosingUnit;
    context.enclosingClassDeclaration = builder._enclosingClassDeclaration;
    context.enclosingClass = builder._enclosingClass;
    return context;
  }
}

/**
 * Adjusts the location of each Element that moved.
 *
 * Since `==` and `hashCode` of a local variable or function Element are based
 * on the element name offsets, we also need to remove these elements from the
 * cache to avoid a memory leak. TODO(scheglov) fix and remove this
 */
class _ElementOffsetUpdater extends GeneralizingElementVisitor {
  final int updateOffset;
  final int updateDelta;
  final AnalysisCache cache;

  _ElementOffsetUpdater(this.updateOffset, this.updateDelta, this.cache);

  @override
  visitElement(Element element) {
    // name offset
    int nameOffset = element.nameOffset;
    if (nameOffset > updateOffset) {
      (element as ElementImpl).nameOffset = nameOffset + updateDelta;
      if (element is ConstVariableElement) {
        Expression initializer = element.constantInitializer;
        if (initializer != null) {
          _shiftTokens(initializer.beginToken);
        }
        _shiftErrors(element.evaluationResult?.errors);
      }
    }
    // code range
    if (element is ElementImpl) {
      int oldOffset = element.codeOffset;
      int oldLength = element.codeLength;
      if (oldOffset != null) {
        int newOffset = oldOffset;
        int newLength = oldLength;
        newOffset += oldOffset > updateOffset ? updateDelta : 0;
        if (oldOffset <= updateOffset && updateOffset < oldOffset + oldLength) {
          newLength += updateDelta;
        }
        if (newOffset != oldOffset || newLength != oldLength) {
          element.setCodeRange(newOffset, newLength);
        }
      }
    }
    // visible range
    if (element is LocalElement) {
      SourceRange visibleRange = element.visibleRange;
      if (visibleRange != null) {
        int oldOffset = visibleRange.offset;
        int oldLength = visibleRange.length;
        int newOffset = oldOffset;
        int newLength = oldLength;
        newOffset += oldOffset > updateOffset ? updateDelta : 0;
        newLength += visibleRange.contains(updateOffset) ? updateDelta : 0;
        if (newOffset != oldOffset || newLength != oldLength) {
          if (element is FunctionElementImpl) {
            element.setVisibleRange(newOffset, newLength);
          } else if (element is LocalVariableElementImpl) {
            element.setVisibleRange(newOffset, newLength);
          } else if (element is ParameterElementImpl) {
            element.setVisibleRange(newOffset, newLength);
          }
        }
      }
    }
    super.visitElement(element);
  }

  void _shiftErrors(List<AnalysisError> errors) {
    if (errors != null) {
      for (AnalysisError error in errors) {
        int errorOffset = error.offset;
        if (errorOffset > updateOffset) {
          error.offset += updateDelta;
        }
      }
    }
  }

  void _shiftTokens(Token token) {
    while (token != null) {
      if (token.offset > updateOffset) {
        token.offset += updateDelta;
      }
      // comments
      _shiftTokens(token.precedingComments);
      if (token is DocumentationCommentToken) {
        for (Token reference in token.references) {
          _shiftTokens(reference);
        }
      }
      // next
      if (token.type == TokenType.EOF) {
        break;
      }
      token = token.next;
    }
  }
}

/**
 * Describes how two [Token]s are different.
 */
class _TokenDifferenceKind {
  static const CONTENT = const _TokenDifferenceKind('CONTENT');
  static const OFFSET = const _TokenDifferenceKind('OFFSET');

  final String name;

  const _TokenDifferenceKind(this.name);

  @override
  String toString() => name;
}

class _TokenPair {
  final _TokenDifferenceKind kind;
  final Token oldToken;
  final Token newToken;
  _TokenPair(this.kind, this.oldToken, this.newToken);
}
