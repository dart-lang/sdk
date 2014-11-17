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
    ScopeContainerElement;

import 'package:compiler/src/scanner/scannerlib.dart' show
    EOF_TOKEN,
    PartialClassElement,
    PartialElement,
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
    CodeEmitterTask,
    MemberInfo;

import 'package:_internal/compiler/js_lib/shared/embedded_names.dart'
    as embeddedNames;

import 'package:compiler/src/js_backend/js_backend.dart' show
    JavaScriptBackend,
    Namer;

import 'package:compiler/src/util/util.dart' show
    Link;

import 'package:compiler/src/elements/modelx.dart' show
    DeclarationSite,
    ElementX;

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
class LibraryUpdater {
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

  JavaScriptBackend get backend => compiler.backend;

  Namer get namer => backend.namer;

  CodeEmitterTask get emitter => backend.emitter;

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
        canReuseAddedElement(difference.after);
        continue;
      }
      if (difference.after == null && difference.before is PartialElement) {
        canReuseRemovedElement(difference.before);
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

  bool canReuseAddedElement(PartialElement element) {
    return cannotReuse(element, "Scope changed, element added.");
  }

  bool canReuseRemovedElement(PartialElement element) {
    if (element is PartialFunctionElement) {
      return canReuseRemovedFunction(element);
    }
    return cannotReuse(
        element, "Removed element that isn't a method.");
  }

  bool canReuseRemovedFunction(PartialFunctionElement element) {
    if (!element.isInstanceMember) {
      return cannotReuse(
          element, "Removed function that isn't an instance method.");
    }
    logVerbose("Removed instance method $element.");

    PartialClassElement cls = element.enclosingClass;
    for (ScopeContainerElement scope in scopesAffectedBy(element, cls)) {
      scanSites(scope, (Element member, DeclarationSite site) {
        // TODO(ahe): Cache qualifiedNamesIn to avoid quadratic behavior.
        Map<String, List<String>> names = qualifiedNamesIn(site);
        if (canNamesResolveTo(names, element, cls)) {
          _elementsToInvalidate.add(member);
        }
      });
    }

    // TODO(ahe): Don't modify the class here, instead use an instance of
    // Update.
    Link<Element> localMembersReversed = const Link<Element>();
    cls.forEachLocalMember((member) {
      if (member != element) {
        localMembersReversed = localMembersReversed.prepend(member);
      }
    });
    cls.localMembersCache = null;
    cls.localMembersReversed = localMembersReversed;
    cls.localScope.contents.remove(element.name);

    // TODO(ahe): Also compute a patch which removes the function, e.g.,
    // "delete GlobalObject.MyClass.prototype.memberName".

    // TODO(ahe): Also forget [element].

    return true;
  }

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

  List<ScopeContainerElement> scopesAffectedBy(
      Element element,
      ClassElement cls) {
    // TODO(ahe): Use library export graph to compute this.
    // TODO(ahe): Should return all user-defined libraries and packages.
    LibraryElement library = element.library;
    List<ScopeContainerElement> result = <ScopeContainerElement>[library];

    if (cls == null) return result;

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
      return cannotReuse(after, 'Signature changed.');
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
      return cannotReuse(after, "Class header changed.");
    }
    logVerbose('Simple modification of ${after} detected');
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

  List<Element> applyUpdates() {
    if (!_failedUpdates.isEmpty) {
      throw new StateError(
          "Can't compute update.\n\n${_failedUpdates.join('\n\n')}");
    }
    for (ElementX element in _elementsToInvalidate) {
      compiler.forgetElement(element);
      element.reuseElement();
    }
    return updates.map((Update update) => update.apply()).toList()
        ..addAll(_elementsToInvalidate);
  }

  String computeUpdateJs() {
    List<Element> updatedElements = applyUpdates();
    if (compiler.progress != null) {
      compiler.progress.reset();
    }
    for (Element element in updatedElements) {
      compiler.enqueuer.resolution.addToWorkList(element);
    }
    compiler.processQueue(compiler.enqueuer.resolution, null);

    compiler.phase = Compiler.PHASE_DONE_RESOLVING;

    for (Element element in updatedElements) {
      compiler.enqueuer.codegen.addToWorkList(element);
    }
    compiler.processQueue(compiler.enqueuer.codegen, null);

    List<jsAst.Statement> updates = <jsAst.Statement>[];
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

      if (backend.isAliasedSuperMember(element)) {
        String superName = namer.getNameOfAliasedSuperMember(element);
        statements.add(
            js.statement('#.prototype.# = f', [elementAccess, superName]));
      }
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
}

/// Represents an update (aka patch) of [before] to [after]. We use the word
/// "update" to avoid confusion with the compiler feature of "patch" methods.
abstract class Update {
  final Compiler compiler;

  PartialElement get before;

  PartialElement get after;

  Update(this.compiler);

  /// Applies the update to [before] and returns that element.
  PartialElement apply();
}

/// Represents an update of a function element.
class FunctionUpdate extends Update {
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

  /// Reset various caches and remove this element from the compiler's internal
  /// state.
  void reuseElement() {
    compiler.forgetElement(before);
    before.reuseElement();
  }
}

Map<String, List<String>> qualifiedNamesIn(PartialElement element) {
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
  Map<String, List<String>> names = new Map<String, List<String>>();
  List<List<Token>> qualifieds = <List<Token>>[];
  do {
    if (token.isIdentifier()) {
      List<String> name = names.putIfAbsent(token.value, () => <String>[]);
      while (identical('.', token.next.stringValue) &&
             token.next.next.isIdentifier()) {
        token = token.next.next;
        name.add(token.value);
      }
    }
    token = token.next;
  } while (token.kind != EOF_TOKEN && token != endToken);
  return names;
}

bool canNamesResolveTo(
    Map<String, List<String>> names,
    Element element,
    ClassElement cls) {
  if (names.containsKey(element.name)) {
    return true;
  }
  if (cls != null) {
    List<String> rest = names[cls.name];
    if (rest != null && rest.contains(element.name)) {
      // [names] contains C.m, where C is the name of [cls], and m is the name
      // of [element].
      return true;
    }
  }
  return false;
}

DeclarationSite declarationSite(Element element) {
  return element is ElementX ? element.declarationSite : null;
}
