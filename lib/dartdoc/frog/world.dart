// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** The one true [World]. */
World world;

/**
 * Experimental phase to enable await, only set when using the
 * await/awaitc.dart entrypoint.
 */
Function experimentalAwaitPhase;

/**
 * Set when the leg compiler is available.  Should always be set
 * to frog_leg/compile.
 */
typedef bool LegCompile(World world);
LegCompile legCompile;

typedef void MessageHandler(String prefix, String message, SourceSpan span);


/**
 * Should be called exactly once to setup singleton world.
 * Can use world.reset() to reinitialize.
 */
void initializeWorld(FileSystem files) {
  assert(world == null);
  world = new World(files);
  if (!options.legOnly) world.init();
}

/**
 * Compiles the [target] dart file using the given [corelib].
 */
bool compile(String homedir, List<String> args, FileSystem files) {
  parseOptions(homedir, args, files);
  initializeWorld(files);
  return world.compileAndSave();
}


/** Can be thrown on any compiler error and includes source location. */
class CompilerException implements Exception {
  final String _message;
  final SourceSpan _location;

  CompilerException(this._message, this._location);

  String toString() {
    if (_location != null) {
      return 'CompilerException: ${_location.toMessageString(_message)}';
    } else {
      return 'CompilerException: $_message';
    }
  }
}

/** Counters that track statistics about the generated code. */
class CounterLog {
  int dynamicMethodCalls = 0;
  int typeAsserts = 0;
  int objectProtoMembers = 0;
  int invokeCalls = 0;
  int msetN = 0;

  info() {
    if (options.legOnly) return;
    world.info('Dynamically typed method calls: $dynamicMethodCalls');
    world.info('Generated type assertions: $typeAsserts');
    world.info('Members on Object.prototype: $objectProtoMembers');
    world.info('Invoke calls: $invokeCalls');
    world.info('msetN calls: $msetN');
  }

  // We need to push a new counter when we are abstract interpreting, so we
  // can discard it if we discard the code.
  // TODO(jmesserly): this is ugly but I'm not sure how to make it cleaner,
  // other than splitting abstract interpretation and code generation (which
  // has its own problems).
  add(CounterLog other) {
    dynamicMethodCalls += other.dynamicMethodCalls;
    typeAsserts += other.typeAsserts;
    objectProtoMembers += other.objectProtoMembers;
    invokeCalls += other.invokeCalls;
    msetN += other.msetN;
  }
}


/** Represents a Dart "world" of code. */
class World {
  WorldGenerator gen;
  String legCode; // TODO(kasperl): Remove this temporary kludge.
  String frogCode;

  FileSystem files;
  final LibraryReader reader;

  Map<String, Library> libraries;
  Library corelib;
  Library coreimpl;

  // TODO(jmesserly): we shouldn't be special casing DOM anywhere.
  Library dom;
  Library html;
  Library isolatelib;

  List<Library> _todo;

  /** Internal map to track name conflicts in the generated javascript. */
  Map<String, Element> _topNames;

  /**
   * Internal set of member names that should be avoided because they are known
   * to exist on various objects.
   */
  Set<String> _hazardousMemberNames;

  Map<String, MemberSet> _members;

  MessageHandler messageHandler;

  int errors = 0, warnings = 0;
  int dartBytesRead = 0, jsBytesWritten = 0;
  bool seenFatal = false;

  // Special types to Dart.
  DefinedType varType;
  // TODO(jimhug): Is this ever not === varType?
  DefinedType dynamicType;

  DefinedType voidType;
  DefinedType objectType;
  DefinedType numType;
  DefinedType intType;
  DefinedType doubleType;
  DefinedType boolType;
  DefinedType stringType;
  DefinedType listType;
  DefinedType mapType;
  DefinedType functionType;
  DefinedType typeErrorType;

  // Types from dart:coreimpl that the compiler needs
  DefinedType numImplType;
  DefinedType stringImplType;
  DefinedType functionImplType;
  DefinedType listFactoryType;
  DefinedType immutableListType;

  NonNullableType nonNullBool;

  CounterLog counters;


  World(this.files)
    : libraries = {}, _todo = [], _members = {}, _topNames = {},
      _hazardousMemberNames = new Set<String>(),
      // TODO(jmesserly): these two types don't actually back our Date and
      // RegExp yet, so we need to add them manually.
      reader = new LibraryReader(), counters = new CounterLog() {
  }

  void reset() {
    // TODO(jimhug): Use a smaller hammer in the future.
    libraries = {}; _todo = []; _members = {}; _topNames = {};
    _hazardousMemberNames = new Set<String>();
    counters = new CounterLog();
    errors = warnings = 0;
    seenFatal = false;
    init();
  }

  init() {
    // Hack: We don't want Dart's String.split to overwrite the existing JS
    // String.prototype.split method. By marking 'split' as 'hazardous' we
    // ensure that frog will not use the 'split' name, thus leaving the original
    // JS String.prototype.split untouched.
    _addHazardousMemberName('split');

    // Setup well-known libraries and types.
    corelib = new Library(readFile('dart:core'));
    libraries['dart:core'] = corelib;
    _todo.add(corelib);

    coreimpl = getOrAddLibrary('dart:coreimpl');

    voidType = corelib.addType('void', null, false);
    dynamicType = corelib.addType('Dynamic', null, false);
    varType = dynamicType;

    objectType = corelib.addType('Object', null, true);
    numType = corelib.addType('num', null, false);
    intType = corelib.addType('int', null, false);
    doubleType = corelib.addType('double', null, false);
    boolType = corelib.addType('bool', null, false);
    stringType = corelib.addType('String', null, false);
    listType = corelib.addType('List', null, false);
    mapType = corelib.addType('Map', null, false);
    functionType = corelib.addType('Function', null, false);
    typeErrorType = corelib.addType('TypeError', null, true);

    numImplType = coreimpl.addType('NumImplementation', null, true);
    stringImplType = coreimpl.addType('StringImplementation', null, true);
    immutableListType = coreimpl.addType('ImmutableList', null, true);
    listFactoryType = coreimpl.addType('ListFactory', null, true);
    functionImplType = coreimpl.addType('_FunctionImplementation', null, true);

    nonNullBool = new NonNullableType(boolType);
  }

  _addHazardousMemberName(String name) => _hazardousMemberNames.add(name);

  _addMember(Member member) {
    // Private members are only visible in their own library.
    assert(!member.isPrivate);
    if (member.isStatic) {
      if (member.declaringType.isTop) {
        _addTopName(member);
      }
      return;
    }

    var mset = _members[member.name];
    if (mset == null) {
      mset = new MemberSet(member, isVar:true);
      _members[mset.name] = mset;
    } else {
      mset.members.add(member);
    }
  }

  /**
   * Adds a top level named [Element] so we track which names will be used in
   * the generated JS.
   */
  _addTopName(Element named) {
    if (named is Type && named.isNative) {
      if (named.avoidNativeName) {
        // Mark the native name as unavailable for any type.
        // Consider:
        //  #library('public');
        //   interface DOMWindow { ... }
        //  #library('impl');
        //   class DOMWindow implements public.DOMWindow native '*DOMWindow' { }
        //  #library('proxy');
        //   class DOMWindow implements public.DOMWindow { ... }
        //
        // The global name 'DOMWindow' will be reserved for the native
        // implementation, so all of them need to be renamed to avoid conflict.
        _addJavascriptTopName(new ExistingJsGlobal(named.nativeName, named),
                              named.nativeName);

      } else {
        // Reserve the native name for this type. This ensures no other type
        // will take the native name.  In the above example removing '*':
        //
        //   class DOMWindow implements public.DOMWindow native 'DOMWindow' { }
        //
        // class impl.DOMWindow gets the JS name 'DOMWindow'.
        _addJavascriptTopName(named, named.nativeName);
      }
    }
    _addJavascriptTopName(named, named.jsname);
  }

  /**
   * Reserves [name] in the generated JS, or renames the lower priority
   * [Element] if the name we wanted was already taken.
   */
  _addJavascriptTopName(Element named, String name) {
    var existing = _topNames[name];
    if (existing == null) {
      // No one was using the name. Take it for ourselves.
      _topNames[name] = named;
      return;
    }
    if (existing === named) {
      // This happens for a simple non-hidden native class where the native name
      // is the same as the default jsname, e.g. class A native 'A' {}.
      return;
    }

    info('mangling matching top level name "${named.jsname}" in '
         'both "${named.library.jsname}" and "${existing.library.jsname}"');

    // resolve conflicts based on priority
    int existingPri = existing.jsnamePriority;
    int namedPri = named.jsnamePriority;
    if (existingPri > namedPri || namedPri == 0) {
      // Either existing was higher priority, or they're both 0 so first one
      // wins.
      _renameJavascriptTopName(named);
    } else if (namedPri > existingPri) {
      // New one takes priority over existing
      _renameJavascriptTopName(existing);
    } else {
      if (named.isNative) {
        final msg = 'conflicting JS name "$name" of same '
            'priority $existingPri: (already defined in) '
            '${existing.span.locationText} with priority $namedPri)';
        // We trust that conflicting native names in builtin libraries
        // are harmless. Most cases there are no conflicts, currently
        // isolates in coreimpl and dart:dom_deprecated both define
        // web workers to avoid adding a dependency from corelib to
        // dart:dom_deprecated.
        world.info(msg, named.span, existing.span);
      } else {
        // Conflicting js name in same library. This happens because
        // of two different type arguments with the same name but in
        // different libraries.
        _renameJavascriptTopName(existing);
      }
    }
  }

  /** Renames an [Element] that had a name conflict in the generated JS. */
  _renameJavascriptTopName(Element named) {
    named._jsname = '${named.library.jsname}_${named.jsname}';
    final existing = _topNames[named.jsname];
    if (existing != null && existing != named) {
      // If this happens it means the library name wasn't unique enough.
      world.internalError('name mangling failed for "${named.jsname}" '
          '("${named.jsname}" defined also in ${existing.span.locationText})',
          named.span);
    }
    _topNames[named.jsname] = named;
  }

  _addType(Type type) {
    // Top types don't have a name - we will capture their members in
    // [_addMember].
    if (!type.isTop) _addTopName(type);
  }

  // TODO(jimhug): Can this just be a const Set?
  Set<String> _jsKeywords;

  /** Ensures that identifiers are legal in the generated JS. */
  String toJsIdentifier(String name) {
    if (name == null) return null;
    if (_jsKeywords == null) {
      // TODO(jmesserly): this doesn't work if I write "new Set<String>.from"
      // List of JS reserved words.
      _jsKeywords = new Set.from([
        'break', 'case', 'catch', 'continue', 'debugger', 'default',
        'delete', 'do', 'else', 'finally', 'for', 'function', 'if',
        'in', 'instanceof', 'new', 'return', 'switch', 'this', 'throw',
        'try', 'typeof', 'var', 'void', 'while', 'with',
        'class', 'enum', 'export', 'extends', 'import', 'super',
        'implements', 'interface', 'let', 'package', 'private',
        'protected', 'public', 'static', 'yield', 'native']);
    }
    if (_jsKeywords.contains(name)) {
      return '${name}_';
    } else {
      // regexs for better perf?
      return name.replaceAll(@'$', @'$$').replaceAll(':', @'$');
    }
  }

  /**
   * Runs the compiler and updates the output file. The output will either be
   * the program, or a file that throws an error when run.
   */
  bool compileAndSave() {
    bool success = compile();
    if (options.outfile != null) {
      if (success) {
        var code = world.getGeneratedCode();
        var outfile = options.outfile;
        if (!outfile.endsWith('.js') && !outfile.endsWith('.js_')) {
          // Add in #! to invoke node.js on files with non-js
          // extensions. Treat both '.js' and '.js_' as JS extensions
          // to work around http://dartbug.com/3231.
          code = '#!/usr/bin/env node\n${code}';
        }
        world.files.writeString(outfile, code);
      } else {
        // Throw here so we get a non-zero exit code when running.
        // TODO(jmesserly): make this an alert when compiling for the browser?
        world.files.writeString(options.outfile, "throw "
          "'Sorry, but I could not generate reasonable code to run.\\n';");
      }
    }
    return success;
  }

  bool compile() {
    // TODO(jimhug): Must have called setOptions - better errors.
    if (options.dartScript == null) {
      fatal('no script provided to compile');
      return false;
    }

    try {
      if (options.legOnly) {
        info('[leg] compiling ${options.dartScript}');
      } else {
        info('compiling ${options.dartScript} with corelib $corelib');
      }
      if (!runLeg()) runCompilationPhases();
    } catch (var exc) {
      if (hasErrors && !options.throwOnErrors) {
        // TODO(jimhug): If dev mode then throw.
      } else {
        // TODO(jimhug): Handle these in world or in callers?
        throw;
      }
    }
    printStatus();
    return !hasErrors;
  }

  /** Returns true if Leg handled the compilation job. */
  bool runLeg() {
    if (!options.legOnly) return false;
    if (legCompile == null) {
      fatal('requested leg enabled, but no leg compiler available');
    }
    bool res = withTiming('[leg] compile', () => legCompile(this));
    if (!res && options.legOnly) {
      fatal("Leg could not compile ${options.dartScript}");
      return true; // In --leg_only, always "handle" the compilation.
    }
    return res;
  }

  void runCompilationPhases() {
    final lib = withTiming('first pass', () => processDartScript());
    withTiming('resolve top level', resolveAll);
    withTiming('name safety', () { nameSafety(lib); });
    if (experimentalAwaitPhase != null) {
      withTiming('await translation', experimentalAwaitPhase);
    }
    withTiming('analyze pass', () { analyzeCode(lib); });
    if (options.checkOnly) return;

    withTiming('generate code', () { generateCode(lib); });
  }

  String getGeneratedCode() {
    // TODO(jimhug): Assert compilation is all done here.
    if (legCode != null) {
      assert(options.legOnly);
      return legCode;
    } else {
      return frogCode;
    }
  }

  SourceFile readFile(String filename) {
    try {
      final sourceFile = reader.readFile(filename);
      dartBytesRead += sourceFile.text.length;
      return sourceFile;
    } catch (var e) {
      warning('Error reading file: $filename', null);
      return new SourceFile(filename, '');
    }
  }

  Library getOrAddLibrary(String filename) {
    Library library = libraries[filename];

    if (library == null) {
      library = new Library(readFile(filename));
      info('read library ${filename}');
      if (!library.isCore &&
          !library.imports.some((li) => li.library.isCore)) {
        library.imports.add(new LibraryImport(corelib));
      }
      libraries[filename] = library;
      _todo.add(library);

      if (filename == 'dart:dom_deprecated') {
        dom = library;
      } else if (filename == 'dart:html') {
        html = library;
      } else if (filename == 'dart:isolate') {
        isolatelib = library;
      }
    }
    return library;
  }

  process() {
    while (_todo.length > 0) {
      final todo = _todo;
      _todo = [];
      for (var lib in todo) {
        lib.visitSources();
      }
    }
  }

  Library processDartScript([String script = null]) {
    if (script == null) script = options.dartScript;
    Library library = getOrAddLibrary(script);
    process();
    return library;
  }

  resolveAll() {
    for (var lib in libraries.getValues()) {
      lib.resolve();
    }
    for (var lib in libraries.getValues()) {
      lib.postResolveChecks();
    }
  }

  nameSafety(Library rootLib) {
    makePrivateMembersUnique(rootLib);
    avoidHazardousMemberNames();
  }

  makePrivateMembersUnique(Library rootLib) {
    var usedNames = new Set<String>();
    process(lib) {
      for (var name in lib._privateMembers.getKeys()) {
        if (usedNames.contains(name)) {
          var mset = lib._privateMembers[name];
          String uniqueName = '_${lib.jsname}${mset.jsname}';
          for (var member in mset.members) {
            member._jsname = uniqueName;
          }
        } else {
          usedNames.add(name);
        }
      }
    }

    // Visit libraries in pre-order of imports.
    var visited = new Set<Library>();
    visit(lib) {
      if (visited.contains(lib)) return;
      visited.add(lib);
      process(lib);
      for (var import in lib.imports) {
        visit(import.library);
      }
    }
    visit(rootLib);
  }

  /**
   * Ensures no non-native member has a jsname conflicting with a known native
   * member jsname.
   */
  avoidHazardousMemberNames() {
    for (var name in _members.getKeys()) {
      var mset = _members[name];
      for (var member in mset.members) {
        if (!member.isNative ||
            (member is MethodMember && member.hasNativeBody)) {
          var jsname = member._jsname;
          if (_hazardousMemberNames.contains(jsname)) {
            member._jsnameRoot = jsname;
            member._jsname = '${jsname}\$_';
          }
        }
      }
    }
  }

  findMainMethod(Library lib) {
    var main = lib.lookup('main', lib.span);
    if (main == null) {
      if (!options.checkOnly) fatal('no main method specified');
    }
    return main;
  }

  /**
   * Walks all code in lib and imports for analysis.
   */
  analyzeCode(Library lib) {
    gen = new WorldGenerator(findMainMethod(lib), new CodeWriter());
    gen.analyze();
  }

  /**
   * Walks all live code to generate JS source for output.
   */
  generateCode(Library lib) {
    gen.run();
    frogCode = gen.writer.text;
    jsBytesWritten = frogCode.length;
    gen = null;
  }

  // ********************** Message support ***********************

  void _message(String color, String prefix, String message,
      SourceSpan span, SourceSpan span1, SourceSpan span2, bool throwing) {
    if (messageHandler != null) {
      // TODO(jimhug): Multiple spans cleaner...
      messageHandler(prefix, message, span);
      if (span1 != null) {
        messageHandler(prefix, message, span1);
      }
      if (span2 != null) {
        messageHandler(prefix, message, span2);
      }
    } else {
      final messageWithPrefix = options.useColors
          ? ('$color$prefix${_NO_COLOR}$message') : ('$prefix$message');

      var text = messageWithPrefix;
      if (span != null) {
        text = span.toMessageString(messageWithPrefix);
      }
      print(text);
      if (span1 != null) {
        print(span1.toMessageString(messageWithPrefix));
      }
      if (span2 != null) {
        print(span2.toMessageString(messageWithPrefix));
      }
    }

    if (throwing) {
      throw new CompilerException('$prefix$message', span);
    }
  }

  /** [message] is considered a static compile-time error by the Dart lang. */
  void error(String message,
      [SourceSpan span, SourceSpan span1, SourceSpan span2]) {
    errors++;
    _message(_RED_COLOR, 'error: ', message,
        span, span1, span2, options.throwOnErrors);
  }

  /** [message] is considered a type warning by the Dart lang. */
  void warning(String message,
      [SourceSpan span, SourceSpan span1, SourceSpan span2]) {
    if (options.warningsAsErrors) {
      error(message, span, span1, span2);
      return;
    }
    warnings++;
    if (options.showWarnings) {
      _message(_MAGENTA_COLOR, 'warning: ', message,
          span, span1, span2, options.throwOnWarnings);
    }
  }

  /** [message] at [location] is so bad we can't generate runnable code. */
  void fatal(String message,
      [SourceSpan span, SourceSpan span1, SourceSpan span2]) {
    errors++;
    seenFatal = true;
    _message(_RED_COLOR, 'fatal: ', message,
        span, span1, span2, options.throwOnFatal || options.throwOnErrors);
  }

  /** [message] at [location] is about a bug in the compiler. */
  void internalError(String message,
      [SourceSpan span, SourceSpan span1, SourceSpan span2]) {
    _message(_NO_COLOR,
        'We are sorry, but...', message, span, span1, span2, true);
  }

  /**
   * [message] at [location] will tell the user about what the compiler
   * is doing.
   */
  void info(String message,
      [SourceSpan span, SourceSpan span1, SourceSpan span2]) {
    if (options.showInfo) {
      _message(_GREEN_COLOR, 'info: ', message, span, span1, span2, false);
    }
  }

  /** Run [fn] without the forceDynamic option enabeld. */
  withoutForceDynamic(void fn()) {
    var oldForceDynamic = options.forceDynamic;
    options.forceDynamic = false;

    try {
      return fn();
    } finally {
      options.forceDynamic = oldForceDynamic;
    }
  }

  bool get hasErrors() => errors > 0;

  void printStatus() {
    counters.info();
    info('compiled $dartBytesRead bytes Dart -> $jsBytesWritten bytes JS');
    if (hasErrors) {
      print('compilation failed with $errors errors');
    } else {
      if (warnings > 0) {
        info('compilation completed successfully with $warnings warnings');
      } else {
        info('compilation completed sucessfully');
      }
    }
  }

  withTiming(String name, f()) {
    final sw = new Stopwatch();
    sw.start();
    var result = f();
    sw.stop();
    info('$name in ${sw.elapsedInMs()}msec');
    return result;
  }
}
