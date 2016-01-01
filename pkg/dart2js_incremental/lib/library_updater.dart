// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js_incremental.library_updater;

import 'dart:async' show
    Future;

import 'package:compiler/compiler.dart' as api;

import 'package:compiler/src/compiler.dart' show
    Compiler;

import 'package:compiler/src/diagnostics/messages.dart' show
    MessageKind;

import 'package:compiler/src/elements/elements.dart' show
    ClassElement,
    CompilationUnitElement,
    Element,
    FunctionElement,
    LibraryElement,
    STATE_NOT_STARTED,
    ScopeContainerElement;

import 'package:compiler/src/enqueue.dart' show
    EnqueueTask;

import 'package:compiler/src/parser/listener.dart' show
    Listener;

import 'package:compiler/src/parser/node_listener.dart' show
    NodeListener;

import 'package:compiler/src/parser/partial_elements.dart' show
    PartialClassElement,
    PartialElement,
    PartialFieldList,
    PartialFunctionElement;

import 'package:compiler/src/parser/parser.dart' show
    Parser;

import 'package:compiler/src/scanner/scanner.dart' show
    Scanner;

import 'package:compiler/src/tokens/token.dart' show
    Token;

import 'package:compiler/src/tokens/token_constants.dart' show
    EOF_TOKEN;

import 'package:compiler/src/script.dart' show
    Script;

import 'package:compiler/src/io/source_file.dart' show
    CachingUtf8BytesSourceFile,
    SourceFile,
    StringSourceFile;

import 'package:compiler/src/tree/tree.dart' show
    ClassNode,
    FunctionExpression,
    LibraryTag,
    NodeList,
    Part,
    StringNode,
    unparse;

import 'package:compiler/src/js/js.dart' show
    js;

import 'package:compiler/src/js/js.dart' as jsAst;

import 'package:compiler/src/js_emitter/js_emitter.dart' show
    CodeEmitterTask,
    computeMixinClass;

import 'package:compiler/src/js_emitter/full_emitter/emitter.dart'
    as full show Emitter;

import 'package:compiler/src/js_emitter/model.dart' show
    Class,
    Method;

import 'package:compiler/src/js_emitter/program_builder/program_builder.dart'
    show ProgramBuilder;

import 'package:js_runtime/shared/embedded_names.dart'
    as embeddedNames;

import 'package:compiler/src/js_backend/js_backend.dart' show
    JavaScriptBackend,
    Namer;

import 'package:compiler/src/util/util.dart' show
    Link,
    LinkBuilder;

import 'package:compiler/src/elements/modelx.dart' show
    ClassElementX,
    CompilationUnitElementX,
    DeclarationSite,
    ElementX,
    FieldElementX,
    LibraryElementX;

import 'package:compiler/src/universe/selector.dart' show
    Selector;

import 'package:compiler/src/constants/values.dart' show
    ConstantValue;

import 'package:compiler/src/library_loader.dart' show
    TagState;

import 'diff.dart' show
    Difference,
    computeDifference;

import 'dart2js_incremental.dart' show
    IncrementalCompilationFailed,
    IncrementalCompiler;

typedef void Logger(message);

typedef bool Reuser(
    Token diffToken,
    PartialElement before,
    PartialElement after);

class FailedUpdate {
  /// Either an [Element] or a [Difference].
  final context;
  final String message;

  FailedUpdate(this.context, this.message);

  String toString() {
    if (context == null) return '$message';
    return 'In $context:\n  $message';
  }
}

abstract class _IncrementalCompilerContext {
  IncrementalCompiler incrementalCompiler;

  Set<ClassElementX> _emittedClasses;

  Set<ClassElementX> _directlyInstantiatedClasses;

  Set<ConstantValue> _compiledConstants;
}

class IncrementalCompilerContext extends _IncrementalCompilerContext {
  final Set<Uri> _uriWithUpdates = new Set<Uri>();

  void set incrementalCompiler(IncrementalCompiler value) {
    if (super.incrementalCompiler != null) {
      throw new StateError("Can't set [incrementalCompiler] more than once.");
    }
    super.incrementalCompiler = value;
  }

  void registerUriWithUpdates(Iterable<Uri> uris) {
    _uriWithUpdates.addAll(uris);
  }

  void _captureState(Compiler compiler) {
    JavaScriptBackend backend = compiler.backend;
    Set neededClasses = backend.emitter.neededClasses;
    if (neededClasses == null) {
      neededClasses = new Set();
    }
    _emittedClasses = new Set.from(neededClasses);

    _directlyInstantiatedClasses =
        new Set.from(compiler.codegenWorld.directlyInstantiatedClasses);

    // This breaks constant tracking of the incremental compiler. It would need
    // to capture the emitted constants.
    List<ConstantValue> constants = null;
    if (constants == null) constants = <ConstantValue>[];
    _compiledConstants = new Set<ConstantValue>.identity()..addAll(constants);
  }

  bool _uriHasUpdate(Uri uri) => _uriWithUpdates.contains(uri);
}

class LibraryUpdater extends JsFeatures {
  final Compiler compiler;

  final api.CompilerInputProvider inputProvider;

  final Logger logTime;

  final Logger logVerbose;

  final List<Update> updates = <Update>[];

  final List<FailedUpdate> _failedUpdates = <FailedUpdate>[];

  final Set<ElementX> _elementsToInvalidate = new Set<ElementX>();

  final Set<ElementX> _removedElements = new Set<ElementX>();

  final Set<ClassElementX> _classesWithSchemaChanges =
      new Set<ClassElementX>();

  final IncrementalCompilerContext _context;

  final Map<Uri, Future> _sources = <Uri, Future>{};

  /// Cached tokens of entry compilation units.
  final Map<LibraryElementX, Token> _entryUnitTokens =
      <LibraryElementX, Token>{};

  /// Cached source files for entry compilation units.
  final Map<LibraryElementX, SourceFile> _entrySourceFiles =
      <LibraryElementX, SourceFile>{};

  bool _hasComputedNeeds = false;

  bool _hasCapturedCompilerState = false;

  LibraryUpdater(
      this.compiler,
      this.inputProvider,
      this.logTime,
      this.logVerbose,
      this._context) {
    // TODO(ahe): Would like to remove this from the constructor. However, the
    // state must be captured before calling [reuseCompiler].
    // Proper solution might be: [reuseCompiler] should not clear the sets that
    // are captured in [IncrementalCompilerContext._captureState].
    _ensureCompilerStateCaptured();
  }

  /// Returns the classes emitted by [compiler].
  Set<ClassElementX> get _emittedClasses => _context._emittedClasses;

  /// Returns the directly instantantiated classes seen by [compiler] (this
  /// includes interfaces and may be different from [_emittedClasses] that only
  /// includes interfaces used in type tests).
  Set<ClassElementX> get _directlyInstantiatedClasses {
    return _context._directlyInstantiatedClasses;
  }

  /// Returns the constants emitted by [compiler].
  Set<ConstantValue> get _compiledConstants => _context._compiledConstants;

  /// When [true], updates must be applied (using [applyUpdates]) before the
  /// [compiler]'s state correctly reflects the updated program.
  bool get hasPendingUpdates => !updates.isEmpty;

  bool get failed => !_failedUpdates.isEmpty;

  /// Used as tear-off passed to [LibraryLoaderTask.resetAsync].
  Future<bool> reuseLibrary(LibraryElement library) {
    _ensureCompilerStateCaptured();
    assert(compiler != null);
    if (library.isPlatformLibrary) {
      logTime('Reusing $library (assumed read-only).');
      return new Future.value(true);
    }
    return _haveTagsChanged(library).then((bool haveTagsChanged) {
      if (haveTagsChanged) {
        cannotReuse(
            library,
            "Changes to library, import, export, or part declarations not"
            " supported.");
        return true;
      }

      bool isChanged = false;
      List<Future<Script>> futureScripts = <Future<Script>>[];

      for (CompilationUnitElementX unit in library.compilationUnits) {
        Uri uri = unit.script.resourceUri;
        if (_context._uriHasUpdate(uri)) {
          isChanged = true;
          futureScripts.add(_updatedScript(unit.script, library));
        } else {
          futureScripts.add(new Future.value(unit.script));
        }
      }

      if (!isChanged) {
        logTime("Reusing $library, source didn't change.");
        return true;
      }

      return Future.wait(futureScripts).then(
          (List<Script> scripts) => canReuseLibrary(library, scripts));
    }).whenComplete(() => _cleanUp(library));
  }

  void _cleanUp(LibraryElementX library) {
    _entryUnitTokens.remove(library);
    _entrySourceFiles.remove(library);
  }

  Future<Script> _updatedScript(Script before, LibraryElementX library) {
    if (before == library.entryCompilationUnit.script &&
        _entrySourceFiles.containsKey(library)) {
      return new Future.value(before.copyWithFile(_entrySourceFiles[library]));
    }

    return _readUri(before.resourceUri).then((bytes) {
      Uri uri = before.file.uri;
      String filename = before.file.filename;
      SourceFile sourceFile = bytes is String
          ? new StringSourceFile(uri, filename, bytes)
          : new CachingUtf8BytesSourceFile(uri, filename, bytes);
      return before.copyWithFile(sourceFile);
    });
  }

  Future<bool> _haveTagsChanged(LibraryElement library) {
    Script before = library.entryCompilationUnit.script;
    if (!_context._uriHasUpdate(before.resourceUri)) {
      // The entry compilation unit hasn't been updated. So the tags aren't
      // changed.
      return new Future<bool>.value(false);
    }

    return _updatedScript(before, library).then((Script script) {
      _entrySourceFiles[library] = script.file;
      Token token = new Scanner(_entrySourceFiles[library]).tokenize();
      _entryUnitTokens[library] = token;
      // Using two parsers to only create the nodes we want ([LibraryTag]).
      Parser parser = new Parser(new Listener());
      NodeListener listener = new NodeListener(
          compiler, library.entryCompilationUnit);
      Parser nodeParser = new Parser(listener);
      Iterator<LibraryTag> tags = library.tags.iterator;
      while (token.kind != EOF_TOKEN) {
        token = parser.parseMetadataStar(token);
        if (parser.optional('library', token) ||
            parser.optional('import', token) ||
            parser.optional('export', token) ||
            parser.optional('part', token)) {
          if (!tags.moveNext()) return true;
          token = nodeParser.parseTopLevelDeclaration(token);
          LibraryTag tag = listener.popNode();
          assert(listener.nodes.isEmpty);
          if (unparse(tags.current) != unparse(tag)) {
            return true;
          }
        } else {
          break;
        }
      }
      return tags.moveNext();
    });
  }

  Future _readUri(Uri uri) {
    return _sources.putIfAbsent(uri, () => inputProvider(uri));
  }

  void _ensureCompilerStateCaptured() {
    // TODO(ahe): [compiler] shouldn't be null, remove the following line.
    if (compiler == null) return;

    if (_hasCapturedCompilerState) return;
    _context._captureState(compiler);
    _hasCapturedCompilerState = true;
  }

  /// Returns true if [library] can be reused.
  ///
  /// This methods also computes the [updates] (patches) needed to have
  /// [library] reflect the modifications in [scripts].
  bool canReuseLibrary(LibraryElement library, List<Script> scripts) {
    logTime('Attempting to reuse ${library}.');

    Uri entryUri = library.entryCompilationUnit.script.resourceUri;
    Script entryScript =
        scripts.singleWhere((Script script) => script.resourceUri == entryUri);
    LibraryElement newLibrary =
        new LibraryElementX(entryScript, library.canonicalUri);
    if (_entryUnitTokens.containsKey(library)) {
      compiler.dietParser.dietParse(
          newLibrary.entryCompilationUnit, _entryUnitTokens[library]);
    } else {
      compiler.scanner.scanLibrary(newLibrary);
    }

    TagState tagState = new TagState();
    for (LibraryTag tag in newLibrary.tags) {
      if (tag.isImport) {
        tagState.checkTag(TagState.IMPORT_OR_EXPORT, tag, compiler);
      } else if (tag.isExport) {
        tagState.checkTag(TagState.IMPORT_OR_EXPORT, tag, compiler);
      } else if (tag.isLibraryName) {
        tagState.checkTag(TagState.LIBRARY, tag, compiler);
        if (newLibrary.libraryTag == null) {
          // Use the first if there are multiple (which is reported as an
          // error in [TagState.checkTag]).
          newLibrary.libraryTag = tag;
        }
      } else if (tag.isPart) {
        tagState.checkTag(TagState.PART, tag, compiler);
      }
    }

    // TODO(ahe): Process tags using TagState, not
    // LibraryLoaderTask.processLibraryTags.
    Link<CompilationUnitElement> units = library.compilationUnits;
    for (Script script in scripts) {
      CompilationUnitElementX unit = units.head;
      units = units.tail;
      if (script != entryScript) {
        // TODO(ahe): Copied from library_loader.
        CompilationUnitElement newUnit =
            new CompilationUnitElementX(script, newLibrary);
        compiler.withCurrentElement(newUnit, () {
          compiler.scanner.scan(newUnit);
          if (unit.partTag == null) {
            compiler.reportError(unit, MessageKind.MISSING_PART_OF_TAG);
          }
        });
      }
    }

    logTime('New library synthesized.');
    return canReuseScopeContainerElement(library, newLibrary);
  }

  bool cannotReuse(context, String message) {
    _failedUpdates.add(new FailedUpdate(context, message));
    logVerbose(message);
    return false;
  }

  bool canReuseScopeContainerElement(
      ScopeContainerElement element,
      ScopeContainerElement newElement) {
    List<Difference> differences = computeDifference(element, newElement);
    logTime('Differences computed.');
    for (Difference difference in differences) {
      logTime('Looking at difference: $difference');

      if (difference.before == null && difference.after is PartialElement) {
        canReuseAddedElement(difference.after, element, newElement);
        continue;
      }
      if (difference.after == null && difference.before is PartialElement) {
        canReuseRemovedElement(difference.before, element);
        continue;
      }
      Token diffToken = difference.token;
      if (diffToken == null) {
        cannotReuse(difference, "No difference token.");
        continue;
      }
      if (difference.after is! PartialElement &&
          difference.before is! PartialElement) {
        cannotReuse(difference, "Don't know how to recompile.");
        continue;
      }
      PartialElement before = difference.before;
      PartialElement after = difference.after;

      Reuser reuser;

      if (before is PartialFunctionElement && after is PartialFunctionElement) {
        reuser = canReuseFunction;
      } else if (before is PartialClassElement &&
                 after is PartialClassElement) {
        reuser = canReuseClass;
      } else {
        reuser = unableToReuse;
      }
      if (!reuser(diffToken, before, after)) {
        assert(!_failedUpdates.isEmpty);
        continue;
      }
    }

    return _failedUpdates.isEmpty;
  }

  bool canReuseAddedElement(
      PartialElement element,
      ScopeContainerElement container,
      ScopeContainerElement syntheticContainer) {
    if (element is PartialFunctionElement) {
      addFunction(element, container);
      return true;
    } else if (element is PartialClassElement) {
      addClass(element, container);
      return true;
    } else if (element is PartialFieldList) {
      addFields(element, container, syntheticContainer);
      return true;
    }
    return cannotReuse(element, "Adding ${element.runtimeType} not supported.");
  }

  void addFunction(
      PartialFunctionElement element,
      /* ScopeContainerElement */ container) {
    invalidateScopesAffectedBy(element, container);

    updates.add(new AddedFunctionUpdate(compiler, element, container));
  }

  void addClass(
      PartialClassElement element,
      LibraryElementX library) {
    invalidateScopesAffectedBy(element, library);

    updates.add(new AddedClassUpdate(compiler, element, library));
  }

  /// Called when a field in [definition] has changed.
  ///
  /// There's no direct link from a [PartialFieldList] to its implied
  /// [FieldElementX], so instead we use [syntheticContainer], the (synthetic)
  /// container created by [canReuseLibrary], or [canReuseClass] (through
  /// [PartialClassElement.parseNode]). This container is scanned looking for
  /// fields whose declaration site is [definition].
  // TODO(ahe): It would be nice if [computeDifference] returned this
  // information directly.
  void addFields(
      PartialFieldList definition,
      ScopeContainerElement container,
      ScopeContainerElement syntheticContainer) {
    List<FieldElementX> fields = <FieldElementX>[];
    syntheticContainer.forEachLocalMember((ElementX member) {
      if (member.declarationSite == definition) {
        fields.add(member);
      }
    });
    for (FieldElementX field in fields) {
      // TODO(ahe): This only works when there's one field per
      // PartialFieldList.
      addField(field, container);
    }
  }

  void addField(FieldElementX element, ScopeContainerElement container) {
    invalidateScopesAffectedBy(element, container);
    if (element.isInstanceMember) {
      _classesWithSchemaChanges.add(container);
    }
    updates.add(new AddedFieldUpdate(compiler, element, container));
  }

  bool canReuseRemovedElement(
      PartialElement element,
      ScopeContainerElement container) {
    if (element is PartialFunctionElement) {
      removeFunction(element);
      return true;
    } else if (element is PartialClassElement) {
      removeClass(element);
      return true;
    } else if (element is PartialFieldList) {
      removeFields(element, container);
      return true;
    }
    return cannotReuse(
        element, "Removing ${element.runtimeType} not supported.");
  }

  void removeFunction(PartialFunctionElement element) {
    logVerbose("Removed method $element.");

    invalidateScopesAffectedBy(element, element.enclosingElement);

    _removedElements.add(element);

    updates.add(new RemovedFunctionUpdate(compiler, element));
  }

  void removeClass(PartialClassElement element) {
    logVerbose("Removed class $element.");

    invalidateScopesAffectedBy(element, element.library);

    _removedElements.add(element);
    element.forEachLocalMember((ElementX member) {
      _removedElements.add(member);
    });

    updates.add(new RemovedClassUpdate(compiler, element));
  }

  void removeFields(
      PartialFieldList definition,
      ScopeContainerElement container) {
    List<FieldElementX> fields = <FieldElementX>[];
    container.forEachLocalMember((ElementX member) {
      if (member.declarationSite == definition) {
        fields.add(member);
      }
    });
    for (FieldElementX field in fields) {
      // TODO(ahe): This only works when there's one field per
      // PartialFieldList.
      removeField(field);
    }
  }

  void removeField(FieldElementX element) {
    logVerbose("Removed field $element.");
    if (!element.isInstanceMember) {
      cannotReuse(element, "Not an instance field.");
    } else {
      removeInstanceField(element);
    }
  }

  void removeInstanceField(FieldElementX element) {
    PartialClassElement cls = element.enclosingClass;

    _classesWithSchemaChanges.add(cls);
    invalidateScopesAffectedBy(element, cls);

    _removedElements.add(element);

    updates.add(new RemovedFieldUpdate(compiler, element));
  }

  void invalidateScopesAffectedBy(
      ElementX element,
      /* ScopeContainerElement */ container) {
    for (ScopeContainerElement scope in scopesAffectedBy(element, container)) {
      scanSites(scope, (Element member, DeclarationSite site) {
        // TODO(ahe): Cache qualifiedNamesIn to avoid quadratic behavior.
        Set<String> names = qualifiedNamesIn(site);
        if (canNamesResolveStaticallyTo(names, element, container)) {
          _elementsToInvalidate.add(member);
        }
      });
    }
  }

  /// Invoke [f] on each [DeclarationSite] in [element]. If [element] is a
  /// [ScopeContainerElement], invoke f on all local members as well.
  void scanSites(
      Element element,
      void f(ElementX element, DeclarationSite site)) {
    DeclarationSite site = declarationSite(element);
    if (site != null) {
      f(element, site);
    }
    if (element is ScopeContainerElement) {
      element.forEachLocalMember((member) { scanSites(member, f); });
    }
  }

  /// Assume [element] is either removed from or added to [container], and
  /// return all [ScopeContainerElement] that can see this change.
  List<ScopeContainerElement> scopesAffectedBy(
      Element element,
      /* ScopeContainerElement */ container) {
    // TODO(ahe): Use library export graph to compute this.
    // TODO(ahe): Should return all user-defined libraries and packages.
    LibraryElement library = container.library;
    List<ScopeContainerElement> result = <ScopeContainerElement>[library];

    if (!container.isClass) return result;

    ClassElement cls = container;

    var externalSubtypes =
        compiler.world.subtypesOf(cls).where((e) => e.library != library);

    return result..addAll(externalSubtypes);
  }

  /// Returns true if function [before] can be reused to reflect the changes in
  /// [after].
  ///
  /// If [before] can be reused, an update (patch) is added to [updates].
  bool canReuseFunction(
      Token diffToken,
      PartialFunctionElement before,
      PartialFunctionElement after) {
    FunctionExpression node =
        after.parseNode(compiler.parsing).asFunctionExpression();
    if (node == null) {
      return cannotReuse(after, "Not a function expression: '$node'");
    }
    Token last = after.endToken;
    if (node.body != null) {
      last = node.body.getBeginToken();
    }
    if (isTokenBetween(diffToken, after.beginToken, last)) {
      removeFunction(before);
      addFunction(after, before.enclosingElement);
      return true;
    }
    logVerbose('Simple modification of ${after} detected');
    updates.add(new FunctionUpdate(compiler, before, after));
    return true;
  }

  bool canReuseClass(
      Token diffToken,
      PartialClassElement before,
      PartialClassElement after) {
    ClassNode node = after.parseNode(compiler.parsing).asClassNode();
    if (node == null) {
      return cannotReuse(after, "Not a ClassNode: '$node'");
    }
    NodeList body = node.body;
    if (body == null) {
      return cannotReuse(after, "Class has no body.");
    }
    if (isTokenBetween(diffToken, node.beginToken, body.beginToken)) {
      logVerbose('Class header modified in ${after}');
      updates.add(new ClassUpdate(compiler, before, after));
      before.forEachLocalMember((ElementX member) {
        // TODO(ahe): Quadratic.
        invalidateScopesAffectedBy(member, before);
      });
    }
    return canReuseScopeContainerElement(before, after);
  }

  bool isTokenBetween(Token token, Token first, Token last) {
    Token current = first;
    while (current != last && current.kind != EOF_TOKEN) {
      if (current == token) {
        return true;
      }
      current = current.next;
    }
    return false;
  }

  bool unableToReuse(
      Token diffToken,
      PartialElement before,
      PartialElement after) {
    return cannotReuse(
        after,
        'Unhandled change:'
        ' ${before} (${before.runtimeType} -> ${after.runtimeType}).');
  }

  /// Apply the collected [updates]. Return a list of elements that needs to be
  /// recompiled after applying the updates. Any elements removed as a
  /// consequence of applying the patches are added to [removals] if provided.
  List<Element> applyUpdates([List<Update> removals]) {
    for (Update update in updates) {
      update.captureState();
    }
    if (!_failedUpdates.isEmpty) {
      throw new IncrementalCompilationFailed(_failedUpdates.join('\n\n'));
    }
    for (ElementX element in _elementsToInvalidate) {
      compiler.forgetElement(element);
      element.reuseElement();
    }
    List<Element> elementsToInvalidate = <Element>[];
    for (ElementX element in _elementsToInvalidate) {
      if (!_removedElements.contains(element)) {
        elementsToInvalidate.add(element);
      }
    }
    for (Update update in updates) {
      Element element = update.apply();
      if (update.isRemoval) {
        if (removals != null) {
          removals.add(update);
        }
      } else {
        elementsToInvalidate.add(element);
      }
    }
    return elementsToInvalidate;
  }

  String computeUpdateJs() {
    List<Update> removals = <Update>[];
    List<Element> updatedElements = applyUpdates(removals);
    if (compiler.progress != null) {
      compiler.progress.reset();
    }
    for (Element element in updatedElements) {
      if (!element.isClass) {
        enqueuer.resolution.addToWorkList(element);
      } else {
        NO_WARN(element).ensureResolved(compiler);
      }
    }
    compiler.processQueue(enqueuer.resolution, null);

    compiler.phase = Compiler.PHASE_DONE_RESOLVING;

    // TODO(ahe): Clean this up. Don't call this method in analyze-only mode.
    if (compiler.analyzeOnly) return "/* analyze only */";

    Set<ClassElementX> changedClasses =
        new Set<ClassElementX>.from(_classesWithSchemaChanges);
    for (Element element in updatedElements) {
      if (!element.isClass) {
        enqueuer.codegen.addToWorkList(element);
      } else {
        changedClasses.add(element);
      }
    }
    compiler.processQueue(enqueuer.codegen, null);

    // Run through all compiled methods and see if they may apply to
    // newlySeenSelectors.
    for (Element e in enqueuer.codegen.generatedCode.keys) {
      if (e.isFunction && !e.isConstructor &&
          e.functionSignature.hasOptionalParameters) {
        for (Selector selector in enqueuer.codegen.newlySeenSelectors) {
          // TODO(ahe): Group selectors by name at this point for improved
          // performance.
          if (e.isInstanceMember && selector.applies(e, compiler.world)) {
            // TODO(ahe): Don't use
            // enqueuer.codegen.newlyEnqueuedElements directly like
            // this, make a copy.
            enqueuer.codegen.newlyEnqueuedElements.add(e);
          }
          if (selector.name == namer.closureInvocationSelectorName) {
            selector = new Selector.call(
                e.name, e.library,
                selector.argumentCount, selector.namedArguments);
            if (selector.appliesUnnamed(e, compiler.world)) {
              // TODO(ahe): Also make a copy here.
              enqueuer.codegen.newlyEnqueuedElements.add(e);
            }
          }
        }
      }
    }

    List<jsAst.Statement> updates = <jsAst.Statement>[];

    Set<ClassElementX> newClasses = new Set.from(
        compiler.codegenWorld.directlyInstantiatedClasses);
    newClasses.removeAll(_directlyInstantiatedClasses);

    if (!newClasses.isEmpty) {
      // Ask the emitter to compute "needs" (only) if new classes were
      // instantiated.
      _ensureAllNeededEntitiesComputed();
      newClasses = new Set.from(emitter.neededClasses);
      newClasses.removeAll(_emittedClasses);
    } else {
      // Make sure that the set of emitted classes is preserved for subsequent
      // updates.
      // TODO(ahe): This is a bit convoluted, find a better approach.
      emitter.neededClasses
          ..clear()
          ..addAll(_emittedClasses);
    }

    List<jsAst.Statement> inherits = <jsAst.Statement>[];

    for (ClassElementX cls in newClasses) {
      jsAst.Node classAccess = emitter.constructorAccess(cls);
      String name = namer.className(cls);

      updates.add(
          js.statement(
              r'# = #', [classAccess, invokeDefineClass(cls)]));

      ClassElement superclass = cls.superclass;
      if (superclass != null) {
        jsAst.Node superAccess = emitter.constructorAccess(superclass);
        inherits.add(
            js.statement(
                r'this.inheritFrom(#, #)', [classAccess, superAccess]));
      }
    }

    // Call inheritFrom after all classes have been created. This way we don't
    // need to sort the classes by having superclasses defined before their
    // subclasses.
    updates.addAll(inherits);

    for (ClassElementX cls in changedClasses) {
      ClassElement superclass = cls.superclass;
      jsAst.Node superAccess =
          superclass == null ? js('null')
              : emitter.constructorAccess(superclass);
      jsAst.Node classAccess = emitter.constructorAccess(cls);
      updates.add(
          js.statement(
              r'# = this.schemaChange(#, #, #)',
              [classAccess, invokeDefineClass(cls), classAccess, superAccess]));
    }

    for (RemovalUpdate update in removals) {
      update.writeUpdateJsOn(updates);
    }
    for (Element element in enqueuer.codegen.newlyEnqueuedElements) {
      if (element.isField) {
        updates.addAll(computeFieldUpdateJs(element));
      } else {
        updates.add(computeMethodUpdateJs(element));
      }
    }

    Set<ConstantValue> newConstants = new Set<ConstantValue>.identity()..addAll(
        compiler.backend.constants.compiledConstants);
    newConstants.removeAll(_compiledConstants);

    if (!newConstants.isEmpty) {
      _ensureAllNeededEntitiesComputed();
      List<ConstantValue> constants =
          emitter.outputConstantLists[compiler.deferredLoadTask.mainOutputUnit];
      if (constants != null) {
        for (ConstantValue constant in constants) {
          if (!_compiledConstants.contains(constant)) {
            full.Emitter fullEmitter = emitter.emitter;
            jsAst.Statement constantInitializer =
                fullEmitter.buildConstantInitializer(constant).toStatement();
            updates.add(constantInitializer);
          }
        }
      }
    }

    updates.add(js.statement(r'''
if (this.pendingStubs) {
  this.pendingStubs.map(function(e) { return e(); });
  this.pendingStubs = void 0;
}
'''));

    if (updates.length == 1) {
      return prettyPrintJs(updates.single);
    } else {
      return prettyPrintJs(js.statement('{#}', [updates]));
    }
  }

  jsAst.Expression invokeDefineClass(ClassElementX cls) {
    String name = namer.className(cls);
    var descriptor = js('Object.create(null)');
    return js(
        r'''
(new Function(
    "$collectedClasses", "$desc",
    this.defineClass(#name, #computeFields) +"\n;return " + #name))(
        {#name: [,#descriptor]})''',
        {'name': js.string(name),
         'computeFields': js.stringArray(computeFields(cls)),
         'descriptor': descriptor});
  }

  jsAst.Node computeMethodUpdateJs(Element element) {
    Method member = new ProgramBuilder(compiler, namer, emitter)
        .buildMethodHackForIncrementalCompilation(element);
    if (member == null) {
      compiler.internalError(element, '${element.runtimeType}');
    }
    ClassBuilder builder = new ClassBuilder(element, namer);
    containerBuilder.addMemberMethod(member, builder);
    jsAst.Node partialDescriptor =
        builder.toObjectInitializer(emitClassDescriptor: false);

    String name = member.name;
    jsAst.Node function = member.code;
    bool isStatic = !element.isInstanceMember;

    /// Either a global object (non-instance members) or a prototype (instance
    /// members).
    jsAst.Node holder;

    if (element.isInstanceMember) {
      holder = emitter.prototypeAccess(element.enclosingClass);
    } else {
      holder = js('#', namer.globalObjectFor(element));
    }

    jsAst.Expression globalFunctionsAccess =
        emitter.generateEmbeddedGlobalAccess(embeddedNames.GLOBAL_FUNCTIONS);

    return js.statement(
        r'this.addMethod(#, #, #, #, #)',
        [partialDescriptor, js.string(name), holder,
         new jsAst.LiteralBool(isStatic), globalFunctionsAccess]);
  }

  List<jsAst.Statement> computeFieldUpdateJs(FieldElementX element) {
    if (element.isInstanceMember) {
      // Any initializers are inlined in factory methods, and the field is
      // declared by adding its class to [_classesWithSchemaChanges].
      return const <jsAst.Statement>[];
    }
    // A static (or top-level) field.
    if (backend.constants.lazyStatics.contains(element)) {
      full.Emitter fullEmitter = emitter.emitter;
      jsAst.Expression init =
          fullEmitter.buildLazilyInitializedStaticField(
              element, isolateProperties: namer.staticStateHolder);
      if (init == null) {
        throw new StateError("Initializer optimized away for $element");
      }
      return <jsAst.Statement>[init.toStatement()];
    } else {
      // TODO(ahe): When a field is referenced it is enqueued. If the field has
      // no initializer, it will not have any associated code, so it will
      // appear as if it was newly enqueued.
      if (element.initializer == null) {
        return const <jsAst.Statement>[];
      } else {
        throw new StateError("Don't know how to compile $element");
      }
    }
  }

  String prettyPrintJs(jsAst.Node node) {
    jsAst.JavaScriptPrintingOptions options =
        new jsAst.JavaScriptPrintingOptions();
    jsAst.JavaScriptPrintingContext context =
        new jsAst.Dart2JSJavaScriptPrintingContext(compiler, null);
    jsAst.Printer printer = new jsAst.Printer(options, context);
    printer.blockOutWithoutBraces(node);
    return context.outBuffer.getText();
  }

  String callNameFor(FunctionElement element) {
    // TODO(ahe): Call a method in the compiler to obtain this name.
    String callPrefix = namer.callPrefix;
    int parameterCount = element.functionSignature.parameterCount;
    return '$callPrefix\$$parameterCount';
  }

  List<String> computeFields(ClassElement cls) {
    return new EmitterHelper(compiler).computeFields(cls);
  }

  void _ensureAllNeededEntitiesComputed() {
    if (_hasComputedNeeds) return;
    emitter.computeAllNeededEntities();
    _hasComputedNeeds = true;
  }
}

/// Represents an update (aka patch) of [before] to [after]. We use the word
/// "update" to avoid confusion with the compiler feature of "patch" methods.
abstract class Update {
  final Compiler compiler;

  PartialElement get before;

  PartialElement get after;

  Update(this.compiler);

  /// Applies the update to [before] and returns that element.
  Element apply();

  bool get isRemoval => false;

  /// Called before any patches are applied to capture any state that is needed
  /// later.
  void captureState() {
  }
}

/// Represents an update of a function element.
class FunctionUpdate extends Update with ReuseFunction {
  final PartialFunctionElement before;

  final PartialFunctionElement after;

  FunctionUpdate(Compiler compiler, this.before, this.after)
      : super(compiler);

  PartialFunctionElement apply() {
    patchElement();
    reuseElement();
    return before;
  }

  /// Destructively change the tokens in [before] to match those of [after].
  void patchElement() {
    before.beginToken = after.beginToken;
    before.endToken = after.endToken;
    before.getOrSet = after.getOrSet;
  }
}

abstract class ReuseFunction {
  Compiler get compiler;

  PartialFunctionElement get before;

  /// Reset various caches and remove this element from the compiler's internal
  /// state.
  void reuseElement() {
    compiler.forgetElement(before);
    before.reuseElement();
  }
}

abstract class RemovalUpdate extends Update {
  ElementX get element;

  RemovalUpdate(Compiler compiler)
      : super(compiler);

  bool get isRemoval => true;

  void writeUpdateJsOn(List<jsAst.Statement> updates);

  void removeFromEnclosing() {
    // TODO(ahe): Need to recompute duplicated elements logic again. Simplest
    // solution is probably to remove all elements from enclosing scope and add
    // them back.
    if (element.isTopLevel) {
      removeFromLibrary(element.library);
    } else {
      removeFromEnclosingClass(element.enclosingClass);
    }
  }

  void removeFromEnclosingClass(PartialClassElement cls) {
    cls.localMembersCache = null;
    cls.localMembersReversed = cls.localMembersReversed.copyWithout(element);
    cls.localScope.contents.remove(element.name);
  }

  void removeFromLibrary(LibraryElementX library) {
    library.localMembers = library.localMembers.copyWithout(element);
    library.localScope.contents.remove(element.name);
  }
}

class RemovedFunctionUpdate extends RemovalUpdate
    with JsFeatures, ReuseFunction {
  final PartialFunctionElement element;

  /// Name of property to remove using JavaScript "delete". Null for
  /// non-instance methods.
  String name;

  /// For instance methods, access to class object. Otherwise, access to the
  /// method itself.
  jsAst.Node elementAccess;

  bool wasStateCaptured = false;

  RemovedFunctionUpdate(Compiler compiler, this.element)
      : super(compiler);

  PartialFunctionElement get before => element;

  PartialFunctionElement get after => null;

  void captureState() {
    if (wasStateCaptured) throw "captureState was called twice.";
    wasStateCaptured = true;

    if (element.isInstanceMember) {
      elementAccess = emitter.constructorAccess(element.enclosingClass);
      name = namer.instanceMethodName(element);
    } else {
      elementAccess = emitter.staticFunctionAccess(element);
    }
  }

  PartialFunctionElement apply() {
    if (!wasStateCaptured) throw "captureState must be called before apply.";
    removeFromEnclosing();
    reuseElement();
    return null;
  }

  void writeUpdateJsOn(List<jsAst.Statement> updates) {
    if (elementAccess == null) {
      compiler.internalError(
          element, 'No elementAccess for ${element.runtimeType}');
    }
    if (element.isInstanceMember) {
      if (name == null) {
        compiler.internalError(element, 'No name for ${element.runtimeType}');
      }
      updates.add(
          js.statement('delete #.prototype.#', [elementAccess, name]));
    } else {
      updates.add(js.statement('delete #', [elementAccess]));
    }
  }
}

class RemovedClassUpdate extends RemovalUpdate with JsFeatures {
  final PartialClassElement element;

  bool wasStateCaptured = false;

  final List<jsAst.Node> accessToStatics = <jsAst.Node>[];

  RemovedClassUpdate(Compiler compiler, this.element)
      : super(compiler);

  PartialClassElement get before => element;

  PartialClassElement get after => null;

  void captureState() {
    if (wasStateCaptured) throw "captureState was called twice.";
    wasStateCaptured = true;
    accessToStatics.add(emitter.constructorAccess(element));

    element.forEachLocalMember((ElementX member) {
      if (!member.isInstanceMember) {
        accessToStatics.add(emitter.staticFunctionAccess(member));
      }
    });
  }

  PartialClassElement apply() {
    if (!wasStateCaptured) {
      throw new StateError("captureState must be called before apply.");
    }

    removeFromEnclosing();

    element.forEachLocalMember((ElementX member) {
      compiler.forgetElement(member);
      member.reuseElement();
    });

    compiler.forgetElement(element);
    element.reuseElement();

    return null;
  }

  void writeUpdateJsOn(List<jsAst.Statement> updates) {
    if (accessToStatics.isEmpty) {
      throw
          new StateError("captureState must be called before writeUpdateJsOn.");
    }

    for (jsAst.Node access in accessToStatics) {
      updates.add(js.statement('delete #', [access]));
    }
  }
}

class RemovedFieldUpdate extends RemovalUpdate with JsFeatures {
  final FieldElementX element;

  bool wasStateCaptured = false;

  jsAst.Node prototypeAccess;

  String getterName;

  String setterName;

  RemovedFieldUpdate(Compiler compiler, this.element)
      : super(compiler);

  PartialFieldList get before => element.declarationSite;

  PartialFieldList get after => null;

  void captureState() {
    if (wasStateCaptured) throw "captureState was called twice.";
    wasStateCaptured = true;

    prototypeAccess = emitter.prototypeAccess(element.enclosingClass);
    getterName = namer.getterForElement(element);
    setterName = namer.setterForElement(element);
  }

  FieldElementX apply() {
    if (!wasStateCaptured) {
      throw new StateError("captureState must be called before apply.");
    }

    removeFromEnclosing();

    return element;
  }

  void writeUpdateJsOn(List<jsAst.Statement> updates) {
    if (!wasStateCaptured) {
      throw new StateError(
          "captureState must be called before writeUpdateJsOn.");
    }

    updates.add(
        js.statement('delete #.#', [prototypeAccess, getterName]));
    updates.add(
        js.statement('delete #.#', [prototypeAccess, setterName]));
  }
}

class AddedFunctionUpdate extends Update with JsFeatures {
  final PartialFunctionElement element;

  final /* ScopeContainerElement */ container;

  AddedFunctionUpdate(Compiler compiler, this.element, this.container)
      : super(compiler) {
    if (container == null) {
      throw "container is null";
    }
  }

  PartialFunctionElement get before => null;

  PartialFunctionElement get after => element;

  PartialFunctionElement apply() {
    Element enclosing = container;
    if (enclosing.isLibrary) {
      // TODO(ahe): Reuse compilation unit of element instead?
      enclosing = enclosing.compilationUnit;
    }
    PartialFunctionElement copy = element.copyWithEnclosing(enclosing);
    NO_WARN(container).addMember(copy, compiler);
    return copy;
  }
}

class AddedClassUpdate extends Update with JsFeatures {
  final PartialClassElement element;

  final LibraryElementX library;

  AddedClassUpdate(Compiler compiler, this.element, this.library)
      : super(compiler);

  PartialClassElement get before => null;

  PartialClassElement get after => element;

  PartialClassElement apply() {
    // TODO(ahe): Reuse compilation unit of element instead?
    CompilationUnitElementX compilationUnit = library.compilationUnit;
    PartialClassElement copy = element.copyWithEnclosing(compilationUnit);
    compilationUnit.addMember(copy, compiler);
    return copy;
  }
}

class AddedFieldUpdate extends Update with JsFeatures {
  final FieldElementX element;

  final ScopeContainerElement container;

  AddedFieldUpdate(Compiler compiler, this.element, this.container)
      : super(compiler);

  PartialFieldList get before => null;

  PartialFieldList get after => element.declarationSite;

  FieldElementX apply() {
    Element enclosing = container;
    if (enclosing.isLibrary) {
      // TODO(ahe): Reuse compilation unit of element instead?
      enclosing = enclosing.compilationUnit;
    }
    FieldElementX copy = element.copyWithEnclosing(enclosing);
    NO_WARN(container).addMember(copy, compiler);
    return copy;
  }
}


class ClassUpdate extends Update with JsFeatures {
  final PartialClassElement before;

  final PartialClassElement after;

  ClassUpdate(Compiler compiler, this.before, this.after)
      : super(compiler);

  PartialClassElement apply() {
    patchElement();
    reuseElement();
    return before;
  }

  /// Destructively change the tokens in [before] to match those of [after].
  void patchElement() {
    before.cachedNode = after.cachedNode;
    before.beginToken = after.beginToken;
    before.endToken = after.endToken;
  }

  void reuseElement() {
    before.supertype = null;
    before.interfaces = null;
    before.nativeTagInfo = null;
    before.supertypeLoadState = STATE_NOT_STARTED;
    before.resolutionState = STATE_NOT_STARTED;
    before.isProxy = false;
    before.hasIncompleteHierarchy = false;
    before.backendMembers = const Link<Element>();
    before.allSupertypesAndSelf = null;
  }
}

/// Returns all qualified names in [element] with less than four identifiers. A
/// qualified name is an identifier followed by a sequence of dots and
/// identifiers, for example, "x", and "x.y.z". But not "x.y.z.w" ("w" is the
/// fourth identifier).
///
/// The longest possible name that can be resolved is three identifiers, for
/// example, "prefix.MyClass.staticMethod". Since four or more identifiers
/// cannot resolve to anything statically, they're not included in the returned
/// value of this method.
Set<String> qualifiedNamesIn(PartialElement element) {
  Token beginToken = element.beginToken;
  Token endToken = element.endToken;
  Token token = beginToken;
  if (element is PartialClassElement) {
    ClassNode node = element.cachedNode;
    if (node != null) {
      NodeList body = node.body;
      if (body != null) {
        endToken = body.beginToken;
      }
    }
  }
  Set<String> names = new Set<String>();
  do {
    if (token.isIdentifier()) {
      String name = token.value;
      // [name] is a single "identifier".
      names.add(name);
      if (identical('.', token.next.stringValue) &&
          token.next.next.isIdentifier()) {
        token = token.next.next;
        name += '.${token.value}';
        // [name] is "idenfifier.idenfifier".
        names.add(name);

        if (identical('.', token.next.stringValue) &&
            token.next.next.isIdentifier()) {
          token = token.next.next;
          name += '.${token.value}';
          // [name] is "idenfifier.idenfifier.idenfifier".
          names.add(name);

          while (identical('.', token.next.stringValue) &&
                 token.next.next.isIdentifier()) {
            // Skip remaining identifiers, they cannot statically resolve to
            // anything, and must be dynamic sends.
            token = token.next.next;
          }
        }
      }
    }
    token = token.next;
  } while (token.kind != EOF_TOKEN && token != endToken);
  return names;
}

/// Returns true if one of the qualified names in names (as computed by
/// [qualifiedNamesIn]) could be a static reference to [element].
bool canNamesResolveStaticallyTo(
    Set<String> names,
    Element element,
    /* ScopeContainerElement */ container) {
  if (names.contains(element.name)) return true;
  if (container != null && container.isClass) {
    // [names] contains C.m, where C is the name of [container], and m is the
    // name of [element].
    if (names.contains("${container.name}.${element.name}")) return true;
  }
  // TODO(ahe): Check for prefixes as well.
  return false;
}

DeclarationSite declarationSite(Element element) {
  return element is ElementX ? element.declarationSite : null;
}

abstract class JsFeatures {
  Compiler get compiler;

  JavaScriptBackend get backend => compiler.backend;

  Namer get namer => backend.namer;

  CodeEmitterTask get emitter => backend.emitter;

  ContainerBuilder get containerBuilder {
    full.Emitter fullEmitter = emitter.emitter;
    return fullEmitter.containerBuilder;
  }

  EnqueueTask get enqueuer => compiler.enqueuer;
}

class EmitterHelper extends JsFeatures {
  final Compiler compiler;

  EmitterHelper(this.compiler);

  ClassEmitter get classEmitter {
    full.Emitter fullEmitter = emitter.emitter;
    return fullEmitter.classEmitter;
  }

  List<String> computeFields(ClassElement classElement) {
    Class cls = new ProgramBuilder(compiler, namer, emitter)
        .buildFieldsHackForIncrementalCompilation(classElement);
    // TODO(ahe): Rewrite for new emitter.
    ClassBuilder builder = new ClassBuilder(classElement, namer);
    classEmitter.emitFields(cls, builder);
    return builder.fields;
  }
}

// TODO(ahe): Remove this method.
NO_WARN(x) => x;
