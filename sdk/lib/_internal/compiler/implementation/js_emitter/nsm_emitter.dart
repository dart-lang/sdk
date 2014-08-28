// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js.js_emitter;

class NsmEmitter extends CodeEmitterHelper {
  final List<Selector> trivialNsmHandlers = <Selector>[];

  /// If this is true then we can generate the noSuchMethod handlers at startup
  /// time, instead of them being emitted as part of the Object class.
  bool get generateTrivialNsmHandlers => true;

  // If we need fewer than this many noSuchMethod handlers we can save space by
  // just emitting them in JS, rather than emitting the JS needed to generate
  // them at run time.
  static const VERY_FEW_NO_SUCH_METHOD_HANDLERS = 10;

  static const MAX_MINIFIED_LENGTH_FOR_DIFF_ENCODING = 4;

  void emitNoSuchMethodHandlers(AddPropertyFunction addProperty) {
    // Do not generate no such method handlers if there is no class.
    if (compiler.codegenWorld.instantiatedClasses.isEmpty) return;

    String noSuchMethodName = namer.publicInstanceMethodNameByArity(
        Compiler.NO_SUCH_METHOD, Compiler.NO_SUCH_METHOD_ARG_COUNT);

    // Keep track of the JavaScript names we've already added so we
    // do not introduce duplicates (bad for code size).
    Map<String, Selector> addedJsNames = new Map<String, Selector>();

    void addNoSuchMethodHandlers(String ignore, Set<Selector> selectors) {
      // Cache the object class and type.
      ClassElement objectClass = compiler.objectClass;
      DartType objectType = objectClass.rawType;

      for (Selector selector in selectors) {
        TypeMask mask = selector.mask;
        if (mask == null) {
          mask = new TypeMask.subclass(compiler.objectClass, compiler.world);
        }

        if (!mask.needsNoSuchMethodHandling(selector, compiler.world)) continue;
        String jsName = namer.invocationMirrorInternalName(selector);
        addedJsNames[jsName] = selector;
        String reflectionName = task.getReflectionName(selector, jsName);
        if (reflectionName != null) {
          task.mangledFieldNames[jsName] = reflectionName;
        }
      }
    }

    compiler.codegenWorld.invokedNames.forEach(addNoSuchMethodHandlers);
    compiler.codegenWorld.invokedGetters.forEach(addNoSuchMethodHandlers);
    compiler.codegenWorld.invokedSetters.forEach(addNoSuchMethodHandlers);

    // Set flag used by generateMethod helper below.  If we have very few
    // handlers we use addProperty for them all, rather than try to generate
    // them at runtime.
    bool haveVeryFewNoSuchMemberHandlers =
        (addedJsNames.length < VERY_FEW_NO_SUCH_METHOD_HANDLERS);

    jsAst.Expression generateMethod(String jsName, Selector selector) {
      // Values match JSInvocationMirror in js-helper library.
      int type = selector.invocationMirrorKind;
      List<String> parameterNames =
          new List.generate(selector.argumentCount, (i) => '\$$i');

      List<jsAst.Expression> argNames =
          selector.getOrderedNamedArguments().map((String name) =>
              js.string(name)).toList();

      String methodName = selector.invocationMirrorMemberName;
      String internalName = namer.invocationMirrorInternalName(selector);
      String reflectionName = task.getReflectionName(selector, internalName);
      if (!haveVeryFewNoSuchMemberHandlers &&
          isTrivialNsmHandler(type, argNames, selector, internalName) &&
          reflectionName == null) {
        trivialNsmHandlers.add(selector);
        return null;
      }

      assert(backend.isInterceptedName(Compiler.NO_SUCH_METHOD));
      jsAst.Expression expression = js('this.#(this, #(#, #, #, #, #))', [
          noSuchMethodName,
          namer.elementAccess(backend.getCreateInvocationMirror()),
          js.string(compiler.enableMinification ?
              internalName : methodName),
          js.string(internalName),
          js.number(type),
          new jsAst.ArrayInitializer.from(parameterNames.map(js)),
          new jsAst.ArrayInitializer.from(argNames)]);

      if (backend.isInterceptedName(selector.name)) {
        return js(r'function($receiver, #) { return # }',
                  [parameterNames, expression]);
      } else {
        return js(r'function(#) { return # }', [parameterNames, expression]);
      }
    }

    for (String jsName in addedJsNames.keys.toList()..sort()) {
      Selector selector = addedJsNames[jsName];
      jsAst.Expression method = generateMethod(jsName, selector);
      if (method != null) {
        addProperty(jsName, method);
        String reflectionName = task.getReflectionName(selector, jsName);
        if (reflectionName != null) {
          bool accessible = compiler.world.allFunctions.filter(selector).any(
              (Element e) => backend.isAccessibleByReflection(e));
          addProperty('+$reflectionName', js(accessible ? '2' : '0'));
        }
      }
    }
  }

  // Identify the noSuchMethod handlers that are so simple that we can
  // generate them programatically.
  bool isTrivialNsmHandler(
      int type, List argNames, Selector selector, String internalName) {
    if (!generateTrivialNsmHandlers) return false;
    // Check for interceptor calling convention.
    if (backend.isInterceptedName(selector.name)) {
      // We can handle the calling convention used by intercepted names in the
      // diff encoding, but we don't use that for non-minified code.
      if (!compiler.enableMinification) return false;
      String shortName = namer.invocationMirrorInternalName(selector);
      if (shortName.length > MAX_MINIFIED_LENGTH_FOR_DIFF_ENCODING) {
        return false;
      }
    }
    // Check for named arguments.
    if (argNames.length != 0) return false;
    // Check for unexpected name (this doesn't really happen).
    if (internalName.startsWith(namer.getterPrefix[0])) return type == 1;
    if (internalName.startsWith(namer.setterPrefix[0])) return type == 2;
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
    // Sort by calling convention, JS name length and by JS name.
    trivialNsmHandlers.sort((a, b) {
      bool aIsIntercepted = backend.isInterceptedName(a.name);
      bool bIsIntercepted = backend.isInterceptedName(b.name);
      if (aIsIntercepted != bIsIntercepted) return aIsIntercepted ? -1 : 1;
      String aName = namer.invocationMirrorInternalName(a);
      String bName = namer.invocationMirrorInternalName(b);
      if (aName.length != bName.length) return aName.length - bName.length;
      return aName.compareTo(bName);
    });

    // Find out how many selectors there are with the special calling
    // convention.
    int firstNormalSelector = trivialNsmHandlers.length;
    for (int i = 0; i < trivialNsmHandlers.length; i++) {
      if (!backend.isInterceptedName(trivialNsmHandlers[i].name)) {
        firstNormalSelector = i;
        break;
      }
    }

    // Get the short names (JS names, perhaps minified).
    Iterable<String> shorts = trivialNsmHandlers.map((selector) =>
         namer.invocationMirrorInternalName(selector));
    final diffShorts = <String>[];
    var diffEncoding = new StringBuffer();

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

    bool minify = compiler.enableMinification;
    bool useDiffEncoding = minify && shorts.length > 30;

    int previous = 0;
    int nameCounter = 0;
    for (String short in shorts) {
      // Emit period that resets the diff base to zero when we switch to normal
      // calling convention (this avoids the need to code negative diffs).
      if (useDiffEncoding && nameCounter == firstNormalSelector) {
        diffEncoding.write(".");
        previous = 0;
      }
      if (short.length <= MAX_MINIFIED_LENGTH_FOR_DIFF_ENCODING &&
          useDiffEncoding) {
        int base63 = fromBase88(short);
        int diff = base63 - previous;
        previous = base63;
        String base26Diff = toBase26(diff);
        diffEncoding.write(base26Diff);
      } else {
        if (useDiffEncoding || diffEncoding.length != 0) {
          diffEncoding.write(",");
        }
        diffEncoding.write(short);
      }
      nameCounter++;
    }

    // Startup code that loops over the method names and puts handlers on the
    // Object class to catch noSuchMethod invocations.
    ClassElement objectClass = compiler.objectClass;
    jsAst.Expression createInvocationMirror = namer.elementAccess(
        backend.getCreateInvocationMirror());
    String noSuchMethodName = namer.publicInstanceMethodNameByArity(
        Compiler.NO_SUCH_METHOD, Compiler.NO_SUCH_METHOD_ARG_COUNT);
    var type = 0;
    if (useDiffEncoding) {
      statements.add(js.statement('''{
          var objectClassObject =
                  collectedClasses[#],    // # is name of class Object.
              shortNames = #.split(","),  // # is diffEncoding.
              nameNumber = 0,
              diffEncodedString = shortNames[0],
              calculatedShortNames = [0, 1];    // 0, 1 are args for splice.
          // If we are loading a deferred library the object class will not be in
          // the collectedClasses so objectClassObject is undefined, and we skip
          // setting up the names.

          if (objectClassObject) {
            if (objectClassObject instanceof Array)
              objectClassObject = objectClassObject[1];
            for (var i = 0; i < diffEncodedString.length; i++) {
              var codes = [],
                  diff = 0,
                  digit = diffEncodedString.charCodeAt(i);
              if (digit == ${$PERIOD}) {
                nameNumber = 0;
                digit = diffEncodedString.charCodeAt(++i);
              }
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
              calculatedShortNames.push(
                String.fromCharCode.apply(String, codes));
            }
            shortNames.splice.apply(shortNames, calculatedShortNames);
          }
        }''', [
            js.string(namer.getNameOfClass(objectClass)),
            js.string('$diffEncoding')]));
    } else {
      // No useDiffEncoding version.
      Iterable<String> longs = trivialNsmHandlers.map((selector) =>
             selector.invocationMirrorMemberName);
      statements.add(js.statement(
          'var objectClassObject = collectedClasses[#],'
          '    shortNames = #.split(",")', [
              js.string(namer.getNameOfClass(objectClass)),
              js.string('$diffEncoding')]));
      if (!minify) {
        statements.add(js.statement('var longNames = #.split(",")',
                js.string(longs.join(','))));
      }
      statements.add(js.statement(
          'if (objectClassObject instanceof Array)'
          '  objectClassObject = objectClassObject[1];'));
    }

    // TODO(9631): This is no longer valid for native methods.
    String whatToPatch = task.nativeEmitter.handleNoSuchMethod ?
                         "Object.prototype" :
                         "objectClassObject";

    List<jsAst.Expression> sliceOffsetArguments =
        firstNormalSelector == 0
        ? []
        : (firstNormalSelector == shorts.length
            ? [js.number(1)]
            : [js('(j < #) ? 1 : 0', js.number(firstNormalSelector))]);

    var sliceOffsetParams = sliceOffsetArguments.isEmpty ? [] : ['sliceOffset'];

    statements.add(js.statement('''
      // If we are loading a deferred library the object class will not be in
      // the collectedClasses so objectClassObject is undefined, and we skip
      // setting up the names.
      if (objectClassObject) {
        for (var j = 0; j < shortNames.length; j++) {
          var type = 0;
          var short = shortNames[j];
          if (short[0] == "${namer.getterPrefix[0]}") type = 1;
          if (short[0] == "${namer.setterPrefix[0]}") type = 2;
          // Generate call to:
          //
          //     createInvocationMirror(String name, internalName, type,
          //         arguments, argumentNames)
          //
          $whatToPatch[short] = (function(name, short, type, #) {
              return function() {
                return this.#(this,
                    #(name, short, type,
                      Array.prototype.slice.call(arguments, #),
                      []));
              }
          })(#[j], short, type, #);
        }
      }''', [
          sliceOffsetParams,  // parameter
          noSuchMethodName,
          createInvocationMirror,
          sliceOffsetParams,  // argument to slice
          minify ? 'shortNames' : 'longNames',
          sliceOffsetArguments
      ]));

    return statements;
  }
}
