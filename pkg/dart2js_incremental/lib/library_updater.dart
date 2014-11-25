// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js_incremental.library_updater;

import 'dart:async' show
    Future;

import 'dart:convert' show
    UTF8;

import 'package:compiler/compiler.dart' as api;

import 'package:compiler/src/dart2jslib.dart' show
    Compiler,
    Script;

import 'package:compiler/src/elements/elements.dart' show
    ClassElement,
    Element,
    FunctionElement,
    LibraryElement,
    STATE_NOT_STARTED,
    ScopeContainerElement;

import 'package:compiler/src/scanner/scannerlib.dart' show
    EOF_TOKEN,
    PartialClassElement,
    PartialElement,
    PartialFieldList,
    PartialFunctionElement,
    Token;

import 'package:compiler/src/source_file.dart' show
    StringSourceFile;

import 'package:compiler/src/tree/tree.dart' show
    ClassNode,
    FunctionExpression,
    NodeList;

import 'package:compiler/src/js/js.dart' show
    js;

import 'package:compiler/src/js/js.dart' as jsAst;

import 'package:compiler/src/js_emitter/js_emitter.dart' show
    ClassBuilder,
    ClassEmitter,
    CodeEmitterTask,
    MemberInfo,
    computeMixinClass;

import 'package:_internal/compiler/js_lib/shared/embedded_names.dart'
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

import 'diff.dart' show
    Difference,
    computeDifference;

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

// TODO(ahe): Generalize this class. For now only works for Compiler.mainApp,
// and only if that library has exactly one compilation unit.
class LibraryUpdater extends JsFeatures {
  final Compiler compiler;

  final api.CompilerInputProvider inputProvider;

  final Logger logTime;

  final Logger logVerbose;

  // TODO(ahe): Get rid of this field. It assumes that only one library has
  // changed.
  final Uri uri;

  final List<Update> updates = <Update>[];

  final List<FailedUpdate> _failedUpdates = <FailedUpdate>[];

  final Set<ElementX> _elementsToInvalidate = new Set<ElementX>();

  final Set<ElementX> _removedElements = new Set<ElementX>();

  final Set<ClassElementX> _classesWithSchemaChanges =
      new Set<ClassElementX>();

  LibraryUpdater(
      this.compiler,
      this.inputProvider,
      this.uri,
      this.logTime,
      this.logVerbose);

  /// When [true], updates must be applied (using [applyUpdates]) before the
  /// [compiler]'s state correctly reflects the updated program.
  bool get hasPendingUpdates => !updates.isEmpty;

  bool get failed => !_failedUpdates.isEmpty;

  /// Used as tear-off passed to [LibraryLoaderTask.resetAsync].
  Future<bool> reuseLibrary(LibraryElement library) {
    assert(compiler != null);
    if (library.isPlatformLibrary || library.isPackageLibrary) {
      logTime('Reusing $library.');
      return new Future.value(true);
    } else if (library != compiler.mainApp) {
      return new Future.value(false);
    }
    return inputProvider(uri).then((bytes) {
      return canReuseLibrary(library, bytes);
    });
  }

  /// Returns true if [library] can be reused.
  ///
  /// This methods also computes the [updates] (patches) needed to have
  /// [library] reflect the modifications in [bytes].
  bool canReuseLibrary(LibraryElement library, bytes) {
    logTime('Attempting to reuse mainApp.');
    String newSource = bytes is String ? bytes : UTF8.decode(bytes);
    logTime('Decoded UTF8');

    // TODO(ahe): Can't use compiler.mainApp in general.
    if (false && newSource == compiler.mainApp.compilationUnit.script.text) {
      // TODO(ahe): Need to update the compilationUnit's source code when
      // doing incremental analysis for this to work.
      logTime("Source didn't change");
      return true;
    }

    logTime("Source did change");
    Script sourceScript = new Script(
        uri, uri, new StringSourceFile('$uri', newSource));
    var dartPrivacyIsBroken = compiler.libraryLoader;
    LibraryElement newLibrary = dartPrivacyIsBroken.createLibrarySync(
        null, sourceScript, uri);
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
    if (!element.isInstanceMember) {
      cannotReuse(element, "Not an instance field.");
    } else {
      addInstanceField(element, container);
    }
  }

  void addInstanceField(FieldElementX element, ClassElementX cls) {
    _classesWithSchemaChanges.add(cls);

    updates.add(new AddedFieldUpdate(compiler, element, cls));
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
        after.parseNode(compiler).asFunctionExpression();
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
    ClassNode node = after.parseNode(compiler).asClassNode();
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
      throw new StateError(
          "Can't compute update.\n\n${_failedUpdates.join('\n\n')}");
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
    Set existingClasses =
        new Set.from(compiler.codegenWorld.directlyInstantiatedClasses);

    List<Update> removals = <Update>[];
    List<Element> updatedElements = applyUpdates(removals);
    if (compiler.progress != null) {
      compiler.progress.reset();
    }
    for (Element element in updatedElements) {
      if (!element.isClass) {
        compiler.enqueuer.resolution.addToWorkList(element);
      } else {
        NO_WARN(element).ensureResolved(compiler);
      }
    }
    compiler.processQueue(compiler.enqueuer.resolution, null);

    compiler.phase = Compiler.PHASE_DONE_RESOLVING;

    // TODO(ahe): Clean this up. Don't call this method in analyze-only mode.
    if (compiler.analyzeOnly) return "/* analyze only */";

    Set<ClassElementX> changedClasses =
        new Set<ClassElementX>.from(_classesWithSchemaChanges);
    for (Element element in updatedElements) {
      if (!element.isClass) {
        compiler.enqueuer.codegen.addToWorkList(element);
      } else {
        changedClasses.add(element);
      }
    }
    compiler.processQueue(compiler.enqueuer.codegen, null);

    List<jsAst.Statement> updates = <jsAst.Statement>[];

    Set newClasses =
        new Set.from(compiler.codegenWorld.directlyInstantiatedClasses);
    newClasses.removeAll(existingClasses);

    List<jsAst.Statement> inherits = <jsAst.Statement>[];

    for (ClassElementX cls in newClasses) {
      jsAst.Node classAccess = namer.elementAccess(cls);
      String name = namer.getNameOfClass(cls);

      updates.add(
          js.statement(
              r'# = #', [classAccess, invokeDefineClass(cls)]));

      ClassElement superclass = cls.superclass;
      if (superclass != null) {
        jsAst.Node superAccess = namer.elementAccess(superclass);
        inherits.add(
            js.statement(
                r'self.$dart_unsafe_eval.inheritFrom(#, #)',
                [classAccess, superAccess]));
      }
    }

    // Call inheritFrom after all classes have been created. This way we don't
    // need to sort the classes by having superclasses defined before their
    // subclasses.
    updates.addAll(inherits);

    for (ClassElementX cls in changedClasses) {
      ClassElement superclass = cls.superclass;
      jsAst.Node superAccess =
          superclass == null ? js('null') : namer.elementAccess(superclass);
      jsAst.Node classAccess = namer.elementAccess(cls);
      updates.add(
          js.statement(
              r'# = self.$dart_unsafe_eval.schemaChange(#, #, #)',
              [classAccess, invokeDefineClass(cls), classAccess, superAccess]));
    }

    for (RemovalUpdate update in removals) {
      update.writeUpdateJsOn(updates);
    }
    for (Element element in compiler.enqueuer.codegen.newlyEnqueuedElements) {
      if (!element.isField) {
        updates.add(computeMemberUpdateJs(element));
      }
    }

    if (updates.length == 1) {
      return prettyPrintJs(updates.single);
    } else {
      return prettyPrintJs(js.statement('{#}', [updates]));
    }
  }

  jsAst.Expression invokeDefineClass(ClassElementX cls) {
    String name = namer.getNameOfClass(cls);
    var descriptor = js('Object.create(null)');
    return js(
        r'''
(new Function(
    "$collectedClasses", "$desc",
    self.$dart_unsafe_eval.defineClass(#, #) +"\n;return " + #))({#: #})''',
        [js.string(name), js.stringArray(computeFields(cls)),
         js.string(name),
         js.string(name), descriptor]);
  }

  jsAst.Node computeMemberUpdateJs(Element element) {
    MemberInfo info = emitter.oldEmitter.containerBuilder
        .analyzeMemberMethod(element);
    if (info == null) {
      compiler.internalError(element, '${element.runtimeType}');
    }
    String name = info.name;
    jsAst.Node function = info.code;
    List<jsAst.Statement> statements = <jsAst.Statement>[];
    if (element.isInstanceMember) {
      jsAst.Node elementAccess = namer.elementAccess(element.enclosingClass);
      statements.add(
          js.statement('#.prototype.# = f', [elementAccess, name]));

      // TODO(ahe): Restore when isAliasedSuperMember is restored.
      // if (backend.isAliasedSuperMember(element)) {
      //   String superName = namer.getNameOfAliasedSuperMember(element);
      //   statements.add(
      //       js.statement('#.prototype.# = f', [elementAccess, superName]));
      // }
    } else {
      jsAst.Node elementAccess = namer.elementAccess(element);
      jsAst.Expression globalFunctionsAccess =
          emitter.generateEmbeddedGlobalAccess(embeddedNames.GLOBAL_FUNCTIONS);
      statements.add(
          js.statement(
              '#.# = # = f',
              [globalFunctionsAccess, name, elementAccess]));
      if (info.canTearOff) {
        String globalName = namer.globalObjectFor(element);
        statements.add(
            js.statement(
                '#.#().# = f',
                [globalName, info.tearOffName, callNameFor(element)]));
      }
    }
    // Create a scope by creating a new function. The updated function literal
    // is passed as an argument to this function which ensures that temporary
    // names in updateScope don't shadow global names.
    jsAst.Fun updateScope = js('function (f) { # }', [statements]);
    return js.statement('(#)(#)', [updateScope, function]);
  }

  String prettyPrintJs(jsAst.Node node) {
    jsAst.Printer printer = new jsAst.Printer(compiler, null);
    printer.blockOutWithoutBraces(node);
    return printer.outBuffer.getText();
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

  /// Name of super-alias property to remove using JavaScript "delete".  Null
  /// for methods that aren't "super aliased", and non-instance methods.
  String superName;

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
      elementAccess = namer.elementAccess(element.enclosingClass);
      name = namer.getNameOfMember(element);
      // TODO(ahe): Restore when isAliasedSuperMember is restored.
      // if (backend.isAliasedSuperMember(element)) {
      //   superName = namer.getNameOfAliasedSuperMember(element);
      // }
    } else {
      elementAccess = namer.elementAccess(element);
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

      if (superName != null) {
        updates.add(
            js.statement('delete #.prototype.#', [elementAccess, superName]));
      }
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

    accessToStatics.add(namer.elementAccess(element));

    element.forEachLocalMember((ElementX member) {
      if (!member.isInstanceMember) {
        accessToStatics.add(namer.elementAccess(member));
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

  jsAst.Node elementAccess;

  String getterName;

  String setterName;

  RemovedFieldUpdate(Compiler compiler, this.element)
      : super(compiler);

  PartialFieldList get before => element.declarationSite;

  PartialFieldList get after => null;

  void captureState() {
    if (wasStateCaptured) throw "captureState was called twice.";
    wasStateCaptured = true;

    elementAccess = namer.elementAccess(element.enclosingClass);
    getterName = namer.getterName(element);
    setterName = namer.setterName(element);
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
        js.statement('delete #.prototype.#', [elementAccess, getterName]));
    updates.add(
        js.statement('delete #.prototype.#', [elementAccess, setterName]));
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
    FieldElementX copy = element.copyWithEnclosing(container);
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
}

class EmitterHelper extends JsFeatures {
  final Compiler compiler;

  EmitterHelper(this.compiler);

  ClassEmitter get classEmitter => backend.emitter.oldEmitter.classEmitter;

  List<String> computeFields(ClassElement cls) {
    // TODO(ahe): Rewrite for new emitter.
    ClassBuilder builder = new ClassBuilder(cls, namer);
    classEmitter.emitFields(cls, builder, "");
    return builder.fields;
  }
}

// TODO(ahe): Remove this method.
NO_WARN(x) => x;
