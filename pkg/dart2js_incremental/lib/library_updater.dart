// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js_incremental.library_updater;

import 'dart:async' show
    Future;

import 'dart:convert' show
    UTF8;

import 'package:compiler/compiler.dart' as api;

import 'package:compiler/implementation/dart2jslib.dart' show
    Compiler,
    Script;

import 'package:compiler/implementation/elements/elements.dart' show
    Element,
    LibraryElement;

import 'package:compiler/implementation/scanner/scannerlib.dart' show
    EOF_TOKEN,
    PartialElement,
    PartialFunctionElement,
    Token;

import 'package:compiler/implementation/source_file.dart' show
    StringSourceFile;

import 'package:compiler/implementation/tree/tree.dart' show
    FunctionExpression;

import 'package:compiler/implementation/js/js.dart' show
    js;

import 'package:compiler/implementation/js/js.dart' as jsAst;

import 'package:compiler/implementation/js_emitter/js_emitter.dart' show
    ClassBuilder;

import 'package:compiler/js_lib/shared/embedded_names.dart' as embeddedNames;

import 'diff.dart' show
    Difference,
    computeDifference;

typedef void Logger(message);

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

  // When [true], updates must be applied (using [applyUpdates]) before the
  // [compiler]'s state correctly reflects the updated program.
  bool hasPendingUpdates = false;

  final List<Update> updates = <Update>[];

  LibraryUpdater(
      this.compiler,
      this.inputProvider,
      this.uri,
      this.logTime,
      this.logVerbose);

  /// Used as tear-off passed to [LibraryLoaderTask.resetAsync].
  Future<bool> reuseLibrary(LibraryElement library) {
    assert(compiler != null);
    if (library.isPlatformLibrary || library.isPackageLibrary) {
      logTime('Reusing $library.');
      return new Future.value(true);
    } else if (library != compiler.mainApp) {
      return new Future.value(false);
    }
    return inputProvider(uri).then((List<int> bytes) {
      return canReuseLibrary(library, bytes);
    });
  }

  /// Returns true if [library] can be reused.
  ///
  /// This methods also computes the [updates] (patches) needed to have
  /// [library] reflect the modifications in [bytes].
  bool canReuseLibrary(LibraryElement library, List<int> bytes) {
    logTime('Attempting to reuse mainApp.');
    String newSource = UTF8.decode(bytes);
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
    List<Difference> differences = computeDifference(library, newLibrary);
    logTime('Differences computed.');
    for (Difference difference in differences) {
      logTime('Looking at difference: $difference');
      if (difference.before == null || difference.after == null) {
        logVerbose('Scope changed in $difference');
        // Scope changed, don't reuse library.
        return false;
      }
      Token diffToken = difference.token;
      if (diffToken == null) {
        logVerbose('No token stored in difference.');
        return false;
      }
      if (difference.after is! PartialElement &&
          difference.before is! PartialElement) {
        logVerbose('Not a PartialElement: $difference');
        // Don't know how to recompile element.
        return false;
      }
      PartialElement before = difference.before;
      PartialElement after = difference.after;

      if (before is PartialFunctionElement && after is PartialFunctionElement) {
        if (!canReuseFunction(diffToken, before, after)) {
          return false;
        }
      } else {
        // Unhandled kind of element.
        return false;
      }
    }
    hasPendingUpdates = true;

    return true;
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
      print('Not a function expression.');
      return false;
    }
    Token last = after.endToken;
    if (node.body != null) {
      last = node.body.getBeginToken();
    }
    Token token = after.beginToken;
    while (token != last && token.kind != EOF_TOKEN) {
      if (token == diffToken) {
        logVerbose('Signature changed');
        return false;
      }
      token = token.next;
    }
    print('Simple modification of ${after} detected');
    updates.add(new FunctionUpdate(compiler, before, after));
    return true;
  }

  List<Element> applyUpdates() {
    return updates.map((Update update) => update.apply()).toList();
  }

  String computeUpdateJs() {
    List<Element> updatedElements = applyUpdates();
    compiler.progress.reset();
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
      updates.add(computeMemberUpdateJs(element));
    }

    if (updates.length == 1) {
      return prettyPrintJs(updates.single);
    } else {
      return prettyPrintJs(js.statement('{#}', [updates]));
    }
  }

  jsAst.Node computeMemberUpdateJs(Element element) {
    ClassBuilder builder = new ClassBuilder(element, compiler.backend.namer);

    compiler.backend.emitter.oldEmitter.containerBuilder.addMember(
        element, builder);
    jsAst.Property property = builder.properties.single;
    jsAst.Node name = property.name;
    jsAst.Node function = property.value;
    jsAst.Node elementAccess = compiler.backend.namer.elementAccess(element);
    jsAst.Expression globalFunctionsAccess =
        compiler.backend.emitter.generateEmbeddedGlobalAccess(
            embeddedNames.GLOBAL_FUNCTIONS);
    List<jsAst.Statement> statements = <jsAst.Statement>[];
    statements.add(
        js.statement(
            '#.# = # = f',
            [globalFunctionsAccess, name, elementAccess]));
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
