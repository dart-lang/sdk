// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_emitter.full_emitter.nsm_emitter;

import '../../elements/entities.dart';
import '../../js/js.dart' as jsAst;
import '../../js/js.dart' show js;
import '../../js_backend/js_backend.dart' show GetterName, SetterName;
import '../../universe/selector.dart' show Selector;
import 'package:front_end/src/fasta/scanner/characters.dart'
    show $$, $A, $HASH, $Z, $a, $z;
import '../../world.dart' show ClosedWorld;
import '../js_emitter.dart' hide Emitter, EmitterFactory;
import '../model.dart';
import 'emitter.dart';

class NsmEmitter extends CodeEmitterHelper {
  final ClosedWorld closedWorld;
  final List<Selector> trivialNsmHandlers = <Selector>[];

  NsmEmitter(this.closedWorld);

  /// If this is true then we can generate the noSuchMethod handlers at startup
  /// time, instead of them being emitted as part of the Object class.
  bool get generateTrivialNsmHandlers => true;

  // If we need fewer than this many noSuchMethod handlers we can save space by
  // just emitting them in JS, rather than emitting the JS needed to generate
  // them at run time.
  static const VERY_FEW_NO_SUCH_METHOD_HANDLERS = 10;

  static const MAX_MINIFIED_LENGTH_FOR_DIFF_ENCODING = 4;

  void emitNoSuchMethodHandlers(AddPropertyFunction addProperty) {
    ClassStubGenerator generator = new ClassStubGenerator(task.emitter,
        compiler.commonElements, namer, codegenWorldBuilder, closedWorld,
        enableMinification: compiler.options.enableMinification);

    // Keep track of the JavaScript names we've already added so we
    // do not introduce duplicates (bad for code size).
    Map<jsAst.Name, Selector> addedJsNames =
        generator.computeSelectorsForNsmHandlers();

    // Set flag used by generateMethod helper below.  If we have very few
    // handlers we use addProperty for them all, rather than try to generate
    // them at runtime.
    bool haveVeryFewNoSuchMemberHandlers =
        (addedJsNames.length < VERY_FEW_NO_SUCH_METHOD_HANDLERS);
    List<jsAst.Name> names = addedJsNames.keys.toList()..sort();
    for (jsAst.Name jsName in names) {
      Selector selector = addedJsNames[jsName];
      String reflectionName = emitter.getReflectionName(selector, jsName);

      if (reflectionName != null) {
        emitter.mangledFieldNames[jsName] = reflectionName;
      }

      List<jsAst.Expression> argNames = selector.callStructure
          .getOrderedNamedArguments()
          .map((String name) => js.string(name))
          .toList();
      int type = selector.invocationMirrorKind;
      if (!haveVeryFewNoSuchMemberHandlers &&
          isTrivialNsmHandler(type, argNames, selector, jsName) &&
          reflectionName == null) {
        trivialNsmHandlers.add(selector);
      } else {
        StubMethod method =
            generator.generateStubForNoSuchMethod(jsName, selector);
        addProperty(method.name, method.code);
        if (reflectionName != null) {
          bool accessible = closedWorld
              .locateMembers(selector, null)
              .any(backend.mirrorsData.isMemberAccessibleByReflection);
          addProperty(
              namer.asName('+$reflectionName'), js(accessible ? '2' : '0'));
        }
      }
    }
  }

  // Identify the noSuchMethod handlers that are so simple that we can
  // generate them programatically.
  bool isTrivialNsmHandler(
      int type, List argNames, Selector selector, jsAst.Name internalName) {
    if (!generateTrivialNsmHandlers) return false;
    // Check for named arguments.
    if (argNames.length != 0) return false;
    // Check for unexpected name (this doesn't really happen).
    if (internalName is GetterName) return type == 1;
    if (internalName is SetterName) return type == 2;
    return type == 0;
  }

  /**
   * Adds (at runtime) the handlers to the Object class which catch calls to
   * methods that the object does not have.  The handlers create an invocation
   * mirror object.
   *
   * The current version only gives you the minified name when minifying (when
   * not minifying this method is not called).
   *
   * In order to generate the noSuchMethod handlers we only need the minified
   * name of the method.  We test the first character of the minified name to
   * determine if it is a getter or a setter, and we use the arguments array at
   * runtime to get the number of arguments and their values.  If the method
   * involves named arguments etc. then we don't handle it here, but emit the
   * handler method directly on the Object class.
   *
   * The minified names are mostly 1-4 character names, which we emit in sorted
   * order (primary key is length, secondary ordering is lexicographic).  This
   * gives an order like ... dD dI dX da ...
   *
   * Gzip is good with repeated text, but it can't diff-encode, so we do that
   * for it.  We encode the minified names in a comma-separated string, but all
   * the 1-4 character names are encoded before the first comma as a series of
   * base 26 numbers.  The last digit of each number is lower case, the others
   * are upper case, so 1 is "b" and 26 is "Ba".
   *
   * We think of the minified names as base 88 numbers using the ASCII
   * characters from # to z.  The base 26 numbers each encode the delta from
   * the previous minified name to the next.  So if there is a minified name
   * called Df and the next is Dh, then they are 2971 and 2973 when thought of
   * as base 88 numbers.  The difference is 2, which is "c" in lower-case-
   * terminated base 26.
   *
   * The reason we don't encode long minified names with this method is that
   * decoding the base 88 numbers would overflow JavaScript's puny integers.
   *
   * There are some selectors that have a special calling convention (because
   * they are called with the receiver as the first argument).  They need a
   * slightly different noSuchMethod handler, so we handle these first.
   */
  List<jsAst.Statement> buildTrivialNsmHandlers() {
    List<jsAst.Statement> statements = <jsAst.Statement>[];
    if (trivialNsmHandlers.length == 0) return statements;

    bool minify = compiler.options.enableMinification;
    bool useDiffEncoding = minify && trivialNsmHandlers.length > 30;

    // Find out how many selectors there are with the special calling
    // convention.
    Iterable<Selector> interceptedSelectors = trivialNsmHandlers.where(
        (Selector s) => closedWorld.interceptorData.isInterceptedName(s.name));
    Iterable<Selector> ordinarySelectors = trivialNsmHandlers.where(
        (Selector s) => !closedWorld.interceptorData.isInterceptedName(s.name));

    // Get the short names (JS names, perhaps minified).
    Iterable<jsAst.Name> interceptedShorts =
        interceptedSelectors.map(namer.invocationMirrorInternalName);
    Iterable<jsAst.Name> ordinaryShorts =
        ordinarySelectors.map(namer.invocationMirrorInternalName);

    jsAst.Expression sortedShorts;
    Iterable<String> sortedLongs;
    if (useDiffEncoding) {
      assert(minify);
      sortedShorts =
          new _DiffEncodedListOfNames([interceptedShorts, ordinaryShorts]);
    } else {
      Iterable<Selector> sorted =
          [interceptedSelectors, ordinarySelectors].expand((e) => (e));
      sortedShorts = js.concatenateStrings(
          js.joinLiterals(sorted.map(namer.invocationMirrorInternalName),
              js.stringPart(",")),
          addQuotes: true);

      if (!minify) {
        sortedLongs =
            sorted.map((selector) => selector.invocationMirrorMemberName);
      }
    }
    // Startup code that loops over the method names and puts handlers on the
    // Object class to catch noSuchMethod invocations.
    ClassEntity objectClass = compiler.commonElements.objectClass;
    jsAst.Expression createInvocationMirror = backend.emitter
        .staticFunctionAccess(compiler.commonElements.createInvocationMirror);
    if (useDiffEncoding) {
      statements.add(js.statement(
          '''{
          var objectClassObject = processedClasses.collected[#objectClass],
              nameSequences = #diffEncoding.split("."),
              shortNames = [];
          if (objectClassObject instanceof Array)
              objectClassObject = objectClassObject[1];
          for (var j = 0; j < nameSequences.length; ++j) {
              var sequence = nameSequences[j].split(","),
                nameNumber = 0;
            // If we are loading a deferred library the object class will not be
            // in the collectedClasses so objectClassObject is undefined, and we
            // skip setting up the names.
            if (!objectClassObject) break;
            // Likewise, if the current sequence is empty, we don't process it.
            if (sequence.length == 0) continue;
            var diffEncodedString = sequence[0];
            for (var i = 0; i < diffEncodedString.length; i++) {
              var codes = [],
                  diff = 0,
                  digit = diffEncodedString.charCodeAt(i);
              for (; digit <= ${$Z};) {
                diff *= 26;
                diff += (digit - ${$A});
                digit = diffEncodedString.charCodeAt(++i);
              }
              diff *= 26;
              diff += (digit - ${$a});
              nameNumber += diff;
              for (var remaining = nameNumber;
                   remaining > 0;
                   remaining = (remaining / 88) | 0) {
                codes.unshift(${$HASH} + remaining % 88);
              }
              shortNames.push(
                String.fromCharCode.apply(String, codes));
            }
            if (sequence.length > 1) {
              Array.prototype.push.apply(shortNames, sequence.shift());
            }
          }
        }''',
          {
            'objectClass': js.quoteName(namer.className(objectClass)),
            'diffEncoding': sortedShorts
          }));
    } else {
      // No useDiffEncoding version.
      statements.add(js.statement(
          'var objectClassObject = processedClasses.collected[#objectClass],'
          '    shortNames = #diffEncoding.split(",")',
          {
            'objectClass': js.quoteName(namer.className(objectClass)),
            'diffEncoding': sortedShorts
          }));
      if (!minify) {
        statements.add(js.statement('var longNames = #longs.split(",")',
            {'longs': js.string(sortedLongs.join(','))}));
      }
      statements.add(js.statement('if (objectClassObject instanceof Array)'
          '  objectClassObject = objectClassObject[1];'));
    }

    dynamic isIntercepted = // jsAst.Expression or bool.
        interceptedSelectors.isEmpty
            ? false
            : ordinarySelectors.isEmpty
                ? true
                : js('j < #', js.number(interceptedSelectors.length));

    statements.add(js.statement(
        '''
      // If we are loading a deferred library the object class will not be in
      // the collectedClasses so objectClassObject is undefined, and we skip
      // setting up the names.
      if (objectClassObject) {
        for (var j = 0; j < shortNames.length; j++) {
          var type = 0;
          var shortName = shortNames[j];
          if (shortName.indexOf("${namer.getterPrefix}") == 0) type = 1;
          if (shortName.indexOf("${namer.setterPrefix}") == 0) type = 2;
          // Generate call to:
          //
          //     createInvocationMirror(String name, internalName, type,
          //         arguments, argumentNames)
          //

          // This 'if' is either a static choice or dynamic choice depending on
          // [isIntercepted].
          if (#isIntercepted) {
            objectClassObject[shortName] =
                (function(name, shortName, type) {
                  return function(receiver) {
                    return this.#noSuchMethodName(
                      receiver,
                      #createInvocationMirror(name, shortName, type,
                          // Create proper Array with all arguments except first
                          // (receiver).
                          Array.prototype.slice.call(arguments, 1),
                          []));
                  }
                 })(#names[j], shortName, type);
          } else {
            objectClassObject[shortName] =
                (function(name, shortName, type) {
                  return function() {
                    return this.#noSuchMethodName(
                      // Object.noSuchMethodName ignores the explicit receiver
                      // argument. We could pass anything in place of [this].
                      this,
                      #createInvocationMirror(name, shortName, type,
                          // Create proper Array with all arguments.
                          Array.prototype.slice.call(arguments, 0),
                          []));
                  }
                 })(#names[j], shortName, type);
          }
        }
      }''',
        {
          'noSuchMethodName': namer.noSuchMethodName,
          'createInvocationMirror': createInvocationMirror,
          'names': minify ? 'shortNames' : 'longNames',
          'isIntercepted': isIntercepted
        }));

    return statements;
  }
}

/// When pretty printed, this node computes a diff-encoded string for the list
/// of given names.
///
/// See [buildTrivialNsmHandlers].
class _DiffEncodedListOfNames extends jsAst.DeferredString
    implements jsAst.AstContainer {
  String _cachedValue;
  List<jsAst.ArrayInitializer> ast;

  Iterable<jsAst.Node> get containedNodes => ast;

  _DiffEncodedListOfNames(Iterable<Iterable<jsAst.Name>> names) {
    // Store the names in ArrayInitializer nodes to make them discoverable
    // by traversals of the ast.
    ast = names
        .map((Iterable i) => new jsAst.ArrayInitializer(i.toList()))
        .toList();
  }

  void _computeDiffEncodingForList(
      Iterable<jsAst.Name> names, StringBuffer diffEncoding) {
    // Treat string as a number in base 88 with digits in ASCII order from # to
    // z.  The short name sorting is based on length, and uses ASCII order for
    // equal length strings so this means that names are ascending.  The hash
    // character, #, is never given as input, but we need it because it's the
    // implicit leading zero (otherwise we could not code names with leading
    // dollar signs).
    int fromBase88(String x) {
      int answer = 0;
      for (int i = 0; i < x.length; i++) {
        int c = x.codeUnitAt(i);
        // No support for Unicode minified identifiers in JS.
        assert(c >= $$ && c <= $z);
        answer *= 88;
        answer += c - $HASH;
      }
      return answer;
    }

    // Big endian encoding, A = 0, B = 1...
    // A lower case letter terminates the number.
    String toBase26(int x) {
      int c = x;
      var encodingChars = <int>[];
      encodingChars.add($a + (c % 26));
      while (true) {
        c ~/= 26;
        if (c == 0) break;
        encodingChars.add($A + (c % 26));
      }
      return new String.fromCharCodes(encodingChars.reversed.toList());
    }

    // Sort by length, then lexicographic.
    int compare(String a, String b) {
      if (a.length != b.length) return a.length - b.length;
      return a.compareTo(b);
    }

    List<String> shorts = names.map((jsAst.Name name) => name.name).toList()
      ..sort(compare);

    int previous = 0;
    for (String short in shorts) {
      if (short.length <= NsmEmitter.MAX_MINIFIED_LENGTH_FOR_DIFF_ENCODING) {
        int base63 = fromBase88(short);
        int diff = base63 - previous;
        previous = base63;
        String base26Diff = toBase26(diff);
        diffEncoding.write(base26Diff);
      } else {
        if (diffEncoding.length != 0) {
          diffEncoding.write(',');
        }
        diffEncoding.write(short);
      }
    }
  }

  String _computeDiffEncoding() {
    StringBuffer buffer = new StringBuffer();
    for (jsAst.ArrayInitializer list in ast) {
      if (buffer.isNotEmpty) {
        // Emit period that resets the diff base to zero when we switch to
        // normal calling convention (this avoids the need to code negative
        // diffs).
        buffer.write(".");
      }
      List<jsAst.Name> names = list.elements;
      _computeDiffEncodingForList(names, buffer);
    }
    return '"${buffer.toString()}"';
  }

  String get value {
    if (_cachedValue == null) {
      _cachedValue = _computeDiffEncoding();
    }

    return _cachedValue;
  }
}
