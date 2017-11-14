// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of html;

class _Property {
  _Property(this.name)
      : _hasValue = false,
        writable = false,
        isMethod = false,
        isOwn = true,
        wasThrown = false;

  bool get hasValue => _hasValue;
  get value => _value;
  set value(v) {
    _value = v;
    _hasValue = true;
  }

  final String name;
  Function setter;
  Function getter;
  var _value;
  bool _hasValue;
  bool writable;
  bool isMethod;
  bool isOwn;
  bool wasThrown;
}

/**
 * Manager for navigating between libraries from the devtools console.
 */
class _LibraryManager {
  /**
   * Current active library
   */
  static var _currentLibrary;
  static var _validCache = false;

  static List<Uri> _libraryUris;

  // List of all maps to check to determine if there is an exact match.
  static Map<String, List<Uri>> _fastPaths;

  static void _addFastPath(String key, Uri uri) {
    _fastPaths.putIfAbsent(key, () => <Uri>[]).add(uri);
  }

  static cache() {
    if (_validCache) return;
    _validCache = true;
    _libraryUris = <Uri>[];
    _fastPaths = new Map<String, List<Uri>>();
    var system = currentMirrorSystem();
    system.libraries.forEach((uri, library) {
      _libraryUris.add(uri);
      _addFastPath(uri.toString(), uri);
      _addFastPath(MirrorSystem.getName(library.simpleName), uri);
    });
  }

  static String get currentLibrary {
    if (_currentLibrary == null) {
      _currentLibrary =
          currentMirrorSystem().isolate.rootLibrary.uri.toString();
    }
    return _currentLibrary;
  }

  /**
   * Find libraries matching a given name.
   *
   * Uses heuristics to only return a single match when the user intent is
   * generally unambiguous.
   */
  static List<Uri> findMatches(String name) {
    cache();
    var nameAsFile = name.endsWith('.dart') ? name : '${name}.dart';
    // Perfect match first.
    var fastPatchMatches = _fastPaths[name];
    if (fastPatchMatches != null) {
      return fastPatchMatches.toList();
    }

    // Exact match for file path.
    var matches = new LinkedHashSet<Uri>();
    for (var uri in _libraryUris) {
      if (uri.path == name || uri.path == nameAsFile) matches.add(uri);
    }
    if (matches.isNotEmpty) return matches.toList();

    // Exact match for file name.
    if (name != nameAsFile) {
      for (var uri in _libraryUris) {
        if (uri.pathSegments.isNotEmpty &&
            (uri.pathSegments.last == nameAsFile)) {
          matches.add(uri);
        }
      }
      if (matches.isNotEmpty) return matches.toList();
    }

    for (var uri in _libraryUris) {
      if (uri.pathSegments.isNotEmpty && (uri.pathSegments.last == name)) {
        matches.add(uri);
      }
    }
    if (matches.isNotEmpty) return matches.toList();

    // Partial match on path.
    for (var uri in _libraryUris) {
      if (uri.path.contains(name)) {
        matches.add(uri);
      }
    }
    if (matches.isNotEmpty) return matches.toList();

    // Partial match on entire uri.
    for (var uri in _libraryUris) {
      if (uri.toString().contains(name)) {
        matches.add(uri);
      }
    }

    if (matches.isNotEmpty) return matches.toList();

    // Partial match on entire uri ignoring case.
    name = name.toLowerCase();
    for (var uri in _libraryUris) {
      if (uri.toString().toLowerCase().contains(name)) {
        matches.add(uri);
      }
    }
    return matches.toList();
  }

  static setLibrary([String name]) {
    // Bust cache in case library list has changed. Ideally we would listen for
    // when libraries are loaded and invalidate based on that.
    _validCache = false;
    cache();
    if (name == null) {
      window.console
        ..group("Current library: $_currentLibrary")
        ..groupCollapsed("All libraries:");
      _listLibraries();
      window.console..groupEnd()..groupEnd();
      return;
    }
    var matches = findMatches(name);
    if (matches.length != 1) {
      if (matches.length > 1) {
        window.console.warn("Ambiguous library name: $name");
      }
      showMatches(name, matches);
      return;
    }
    _currentLibrary = matches.first.toString();
    window.console.log("Set library to $_currentLibrary");
  }

  static getLibrary() {
    return currentLibrary;
  }

  static List<Uri> _sortUris(Iterable<Uri> uris) {
    return (uris.toList())
      ..sort((Uri a, Uri b) {
        if (a.scheme != b.scheme) {
          if (a.scheme == 'dart') return -1;
          if (b.scheme == 'dart') return 1;
          return a.scheme.compareTo(b.scheme);
        }
        return a.toString().compareTo(b.toString());
      });
  }

  static void listLibraries() {
    _validCache = false;
    cache();
    _listLibraries();
  }

  static void _listLibraries() {
    window.console.log(_sortUris(_libraryUris).join("\n"));
  }

  // Workaround to allow calling console.log with an arbitrary number of
  // arguments.
  static void _log(List<String> args) {
    js.JsNative.callMethod(window.console, 'log', args);
  }

  static showMatches(String key, Iterable<Uri> uris) {
    var boldPairs = [];
    var sb = new StringBuffer();
    if (uris.isEmpty) {
      window.console.group("All libraries:");
      _listLibraries();
      window.console
        ..groupEnd()
        ..error("No library names or URIs match '$key'");
      return;
    }
    sb.write("${uris.length} matches\n");
    var lowerCaseKey = key.toLowerCase();
    for (var uri in uris) {
      var txt = uri.toString();
      int index = txt.toLowerCase().indexOf(lowerCaseKey);
      if (index != -1) {
        // %c enables styling console log messages with css
        // specified at the end of the console.
        sb..write(txt.substring(0, index))..write('%c');
        var matchEnd = index + key.length;
        sb
          ..write(txt.substring(index, matchEnd))
          ..write('%c')
          ..write(txt.substring(matchEnd))
          ..write('\n');
        boldPairs..add('font-weight: bold')..add('font-weight: normal');
      }
    }
    _log([sb.toString()]..addAll(boldPairs));
  }
}

class _ConsoleVariables {
  Map<String, Object> _data = new Map<String, Object>();

  /**
   * Forward member accesses to the backing JavaScript object.
   */
  noSuchMethod(Invocation invocation) {
    String member = MirrorSystem.getName(invocation.memberName);
    if (invocation.isGetter) {
      return _data[member];
    } else if (invocation.isSetter) {
      assert(member.endsWith('='));
      member = member.substring(0, member.length - 1);
      _data[member] = invocation.positionalArguments[0];
    } else {
      return Function.apply(_data[member], invocation.positionalArguments,
          invocation.namedArguments);
    }
  }

  void clear() => _data.clear();

  /**
   * List all variables currently defined.
   */
  List variables() => _data.keys.toList();

  void setVariable(String name, value) {
    _data[name] = value;
  }
}

/**
 * Base class for invocation trampolines used to closurize methods, getters
 * and setters.
 */
abstract class _Trampoline implements Function {
  final ObjectMirror _receiver;
  final MethodMirror _methodMirror;
  final Symbol _selector;

  _Trampoline(this._receiver, this._methodMirror, this._selector);
}

class _MethodTrampoline extends _Trampoline {
  _MethodTrampoline(
      ObjectMirror receiver, MethodMirror methodMirror, Symbol selector)
      : super(receiver, methodMirror, selector);

  noSuchMethod(Invocation msg) {
    if (msg.memberName != #call) return super.noSuchMethod(msg);
    return _receiver
        .invoke(_selector, msg.positionalArguments, msg.namedArguments)
        .reflectee;
  }
}

/**
 * Invocation trampoline class used to closurize getters.
 */
class _GetterTrampoline extends _Trampoline {
  _GetterTrampoline(
      ObjectMirror receiver, MethodMirror methodMirror, Symbol selector)
      : super(receiver, methodMirror, selector);

  call() => _receiver.getField(_selector).reflectee;
}

/**
 * Invocation trampoline class used to closurize setters.
 */
class _SetterTrampoline extends _Trampoline {
  _SetterTrampoline(
      ObjectMirror receiver, MethodMirror methodMirror, Symbol selector)
      : super(receiver, methodMirror, selector);

  call(value) {
    _receiver.setField(_selector, value);
  }
}

class _Utils {
  static double dateTimeToDouble(DateTime dateTime) =>
      dateTime.millisecondsSinceEpoch.toDouble();
  static DateTime doubleToDateTime(double dateTime) {
    try {
      return new DateTime.fromMillisecondsSinceEpoch(dateTime.toInt());
    } catch (_) {
      // TODO(antonnm): treat exceptions properly in bindings and
      // find out how to treat NaNs.
      return null;
    }
  }

  static List convertToList(List list) {
    // FIXME: [possible optimization]: do not copy the array if Dart_IsArray is fine w/ it.
    final length = list.length;
    List result = new List(length);
    result.setRange(0, length, list);
    return result;
  }

  static List convertMapToList(Map map) {
    List result = [];
    map.forEach((k, v) => result.addAll([k, v]));
    return result;
  }

  static int convertCanvasElementGetContextMap(Map map) {
    int result = 0;
    if (map['alpha'] == true) result |= 0x01;
    if (map['depth'] == true) result |= 0x02;
    if (map['stencil'] == true) result |= 0x4;
    if (map['antialias'] == true) result |= 0x08;
    if (map['premultipliedAlpha'] == true) result |= 0x10;
    if (map['preserveDrawingBuffer'] == true) result |= 0x20;

    return result;
  }

  static void populateMap(Map result, List list) {
    for (int i = 0; i < list.length; i += 2) {
      result[list[i]] = list[i + 1];
    }
  }

  static bool isMap(obj) => obj is Map;

  static List toListIfIterable(obj) => obj is Iterable ? obj.toList() : null;

  static Map createMap() => {};

  static parseJson(String jsonSource) =>
      const JsonDecoder().convert(jsonSource);

  static String getLibraryUrl() => _LibraryManager.currentLibrary;

  static makeUnimplementedError(String fileName, int lineNo) {
    return new UnsupportedError('[info: $fileName:$lineNo]');
  }

  static bool isTypeSubclassOf(Type type, Type other) {
    if (type == other) {
      return true;
    }
    var superclass = reflectClass(type).superclass;
    if (superclass != null) {
      return isTypeSubclassOf(superclass.reflectedType, other);
    }
    return false;
  }

  static Element getAndValidateNativeType(Type type, String tagName) {
    var element = new Element.tag(tagName);
    if (!isTypeSubclassOf(type, element.runtimeType)) {
      return null;
    }
    return element;
  }

  static forwardingPrint(String message) =>
      _blink.Blink_Utils.forwardingPrint(message);
  static void spawnDomHelper(Function f, int replyTo) =>
      _blink.Blink_Utils.spawnDomHelper(f, replyTo);

  // TODO(vsm): Make this API compatible with spawnUri.  It should also
  // return a Future<Isolate>.
  // TODO(jacobr): IS THIS RIGHT? I worry we have broken conversion from Promise to Future.
  static spawnDomUri(String uri) => _blink.Blink_Utils.spawnDomUri(uri);

  // The following methods were added for debugger integration to make working
  // with the Dart C mirrors API simpler.
  // TODO(jacobr): consider moving them to a separate library.
  // If Dart supported dynamic code injection, we would only inject this code
  // when the debugger is invoked.

  /**
   * Strips the private secret prefix from member names of the form
   * someName@hash.
   */
  static String stripMemberName(String name) {
    int endIndex = name.indexOf('@');
    return endIndex > 0 ? name.substring(0, endIndex) : name;
  }

  /**
   * Takes a list containing variable names and corresponding values and
   * returns a map from normalized names to values. Variable names are assumed
   * to have list offsets 2*n values at offset 2*n+1. This method is required
   * because Dart_GetLocalVariables returns a list instead of an object that
   * can be queried to lookup names and values.
   */
  static Map<String, dynamic> createLocalVariablesMap(List localVariables) {
    var map = {};
    for (int i = 0; i < localVariables.length; i += 2) {
      map[stripMemberName(localVariables[i])] = localVariables[i + 1];
    }
    return map;
  }

  static _ConsoleVariables _consoleTempVariables = new _ConsoleVariables();

  /**
   * Takes an [expression] and a list of [local] variable and returns an
   * expression for a closure with a body matching the original expression
   * where locals are passed in as arguments. Returns a list containing the
   * String expression for the closure and the list of arguments that should
   * be passed to it. The expression should then be evaluated using
   * Dart_EvaluateExpr which will generate a closure that should be invoked
   * with the list of arguments passed to this method.
   *
   * For example:
   * <code>
   * _consoleTempVariables = {'a' : someValue, 'b': someOtherValue}
   * wrapExpressionAsClosure("foo + bar + a", ["bar", 40, "foo", 2], true)
   * </code>
   * will return:
   * <code>
   * ["""(final $consoleVariables, final bar, final foo, final a, final b) =>
   * (foo + bar + a
   * )""",
   * [_consoleTempVariables, 40, 2, someValue, someOtherValue]]
   * </code>
   */
  static List wrapExpressionAsClosure(
      String expression, List locals, bool includeCommandLineAPI) {
    var args = {};
    var sb = new StringBuffer("(");
    addArg(arg, value) {
      arg = stripMemberName(arg);
      if (args.containsKey(arg)) return;
      // We ignore arguments with the name 'this' rather than throwing an
      // exception because Dart_GetLocalVariables includes 'this' and it
      // is more convenient to filter it out here than from C++ code.
      // 'this' needs to be handled by calling Dart_EvaluateExpr with
      // 'this' as the target rather than by passing it as an argument.
      if (arg == 'this') return;
      // Avoid being broken by bogus ':async_op' local passed in when within
      // an async method.
      if (arg.startsWith(':')) return;
      if (args.isNotEmpty) {
        sb.write(", ");
      }
      sb.write("final $arg");
      args[arg] = value;
    }

    if (includeCommandLineAPI) {
      addArg("\$consoleVariables", _consoleTempVariables);

      // FIXME: use a real Dart tokenizer. The following regular expressions
      // only allow setting variables at the immediate start of the expression
      // to limit the number of edge cases we have to handle.

      // Match expressions that start with "var x"
      final _VARIABLE_DECLARATION = new RegExp("^(\\s*)var\\s+(\\w+)");
      // Match expressions that start with "someExistingConsoleVar ="
      final _SET_VARIABLE = new RegExp("^(\\s*)(\\w+)(\\s*=)");
      // Match trailing semicolons.
      final _ENDING_SEMICOLONS = new RegExp("(;\\s*)*\$");
      expression = expression.replaceAllMapped(_VARIABLE_DECLARATION, (match) {
        var variableName = match[2];
        // Set the console variable if it isn't already set.
        if (!_consoleTempVariables._data.containsKey(variableName)) {
          _consoleTempVariables._data[variableName] = null;
        }
        return "${match[1]}\$consoleVariables.${variableName}";
      });

      expression = expression.replaceAllMapped(_SET_VARIABLE, (match) {
        var variableName = match[2];
        // Only rewrite if the name matches an existing console variable.
        if (_consoleTempVariables._data.containsKey(variableName)) {
          return "${match[1]}\$consoleVariables.${variableName}${match[3]}";
        } else {
          return match[0];
        }
      });

      // We only allow dart expressions not Dart statements. Silently remove
      // trailing semicolons the user might have added by accident to reduce the
      // number of spurious compile errors.
      expression = expression.replaceFirst(_ENDING_SEMICOLONS, "");
    }

    if (locals != null) {
      for (int i = 0; i < locals.length; i += 2) {
        addArg(locals[i], locals[i + 1]);
      }
    }
    // Inject all the already defined console variables.
    _consoleTempVariables._data.forEach(addArg);

    // TODO(jacobr): remove the parentheses around the expression once
    // dartbug.com/13723 is fixed. Currently we wrap expression in parentheses
    // to ensure only valid Dart expressions are allowed. Otherwise the DartVM
    // quietly ignores trailing Dart statements resulting in user confusion
    // when part of an invalid expression they entered is ignored.
    sb..write(') => (\n$expression\n)');
    return [sb.toString(), args.values.toList(growable: false)];
  }

  static String _getShortSymbolName(
      Symbol symbol, DeclarationMirror declaration) {
    var name = MirrorSystem.getName(symbol);
    if (declaration is MethodMirror) {
      if (declaration.isSetter && name[name.length - 1] == "=") {
        return name.substring(0, name.length - 1);
      }
      if (declaration.isConstructor) {
        return name.substring(name.indexOf('.') + 1);
      }
    }
    return name;
  }

  /**
   * Handle special console commands such as $lib and $libs that should not be
   * evaluated as Dart expressions and instead should be interpreted directly.
   * Commands supported:
   * library <-- shows the current library and lists all libraries.
   * library "library_uri" <-- select a specific library
   * library "library_uri_fragment"
   */
  static bool maybeHandleSpecialConsoleCommand(String expression) {
    expression = expression.trim();
    var setLibraryCommand = r'library ';
    if (expression == r'library') {
      _LibraryManager.setLibrary();
      return true;
    }
    if (expression.startsWith(setLibraryCommand)) {
      expression = expression.substring(setLibraryCommand.length);
      if (expression.length >= 2) {
        String start = expression[0];
        String end = expression[expression.length - 1];
        // TODO(jacobr): maybe we should require quotes.
        if ((start == "'" && end == "'") || (start == '"' && end == '"')) {
          expression = expression.substring(1, expression.length - 1);
        }
      }

      _LibraryManager.setLibrary(expression);
      return true;
    }
    return false;
  }

  /**
   * Returns a list of completions to use if the receiver is o.
   */
  static List<String> getCompletions(o) {
    MirrorSystem system = currentMirrorSystem();
    var completions = new Set<String>();
    addAll(Map<Symbol, dynamic> map, bool isStatic) {
      map.forEach((symbol, mirror) {
        if (mirror.isStatic == isStatic && !mirror.isPrivate) {
          var name = MirrorSystem.getName(symbol);
          if (mirror is MethodMirror && mirror.isSetter)
            name = name.substring(0, name.length - 1);
          completions.add(name);
        }
      });
    }

    addForClass(ClassMirror mirror, bool isStatic) {
      if (mirror == null) return;
      addAll(mirror.declarations, isStatic);
      if (mirror.superclass != null) addForClass(mirror.superclass, isStatic);
      for (var interface in mirror.superinterfaces) {
        addForClass(interface, isStatic);
      }
    }

    if (o is Type) {
      addForClass(reflectClass(o), true);
    } else {
      addForClass(reflect(o).type, false);
    }
    return completions.toList(growable: false);
  }

  /**
   * Adds all candidate String completions from [declarations] to [output]
   * filtering based on [staticContext] and [includePrivate].
   */
  static void _getCompletionsHelper(ClassMirror classMirror, bool staticContext,
      LibraryMirror libraryMirror, Set<String> output) {
    bool includePrivate = libraryMirror == classMirror.owner;
    classMirror.declarations.forEach((symbol, declaration) {
      if (!includePrivate && declaration.isPrivate) return;
      if (declaration is VariableMirror) {
        if (staticContext != declaration.isStatic) return;
      } else if (declaration is MethodMirror) {
        if (declaration.isOperator) return;
        if (declaration.isConstructor) {
          if (!staticContext) return;
          var name = MirrorSystem.getName(declaration.constructorName);
          if (name.isNotEmpty) output.add(name);
          return;
        }
        if (staticContext != declaration.isStatic) return;
      } else if (declaration is TypeMirror) {
        return;
      }
      output.add(_getShortSymbolName(symbol, declaration));
    });

    if (!staticContext) {
      for (var interface in classMirror.superinterfaces) {
        _getCompletionsHelper(interface, staticContext, libraryMirror, output);
      }
      if (classMirror.superclass != null) {
        _getCompletionsHelper(
            classMirror.superclass, staticContext, libraryMirror, output);
      }
    }
  }

  static void _getLibraryCompletionsHelper(
      LibraryMirror library, bool includePrivate, Set<String> output) {
    library.declarations.forEach((symbol, declaration) {
      if (!includePrivate && declaration.isPrivate) return;
      output.add(_getShortSymbolName(symbol, declaration));
    });
  }

  static LibraryMirror getLibraryMirror(String url) =>
      currentMirrorSystem().libraries[Uri.parse(url)];

  /**
   * Get code completions for [o] only showing privates from [libraryUrl].
   */
  static List<String> getObjectCompletions(o, String libraryUrl) {
    var classMirror;
    bool staticContext;
    if (o is Type) {
      classMirror = reflectClass(o);
      staticContext = true;
    } else {
      classMirror = reflect(o).type;
      staticContext = false;
    }
    var names = new Set<String>();
    getClassCompletions(classMirror, names, staticContext, libraryUrl);
    return names.toList()..sort();
  }

  static void getClassCompletions(ClassMirror classMirror, Set<String> names,
      bool staticContext, String libraryUrl) {
    LibraryMirror libraryMirror = getLibraryMirror(libraryUrl);
    _getCompletionsHelper(classMirror, staticContext, libraryMirror, names);
  }

  static List<String> getLibraryCompletions(String url) {
    var names = new Set<String>();
    _getLibraryCompletionsHelper(getLibraryMirror(url), true, names);
    return names.toList();
  }

  /**
   * Get valid code completions from within a library and all libraries
   * imported by that library.
   */
  static List<String> getLibraryCompletionsIncludingImports(String url) {
    var names = new Set<String>();
    var libraryMirror = getLibraryMirror(url);
    _getLibraryCompletionsHelper(libraryMirror, true, names);
    for (var dependency in libraryMirror.libraryDependencies) {
      if (dependency.isImport) {
        if (dependency.prefix == null) {
          _getLibraryCompletionsHelper(dependency.targetLibrary, false, names);
        } else {
          names.add(MirrorSystem.getName(dependency.prefix));
        }
      }
    }
    return names.toList();
  }

  static final SIDE_EFFECT_FREE_LIBRARIES = new Set<String>()
    ..add('dart:html')
    ..add('dart:indexed_db')
    ..add('dart:svg')
    ..add('dart:typed_data')
    ..add('dart:web_audio')
    ..add('dart:web_gl')
    ..add('dart:web_sql');

  static LibraryMirror _getLibrary(MethodMirror methodMirror) {
    var owner = methodMirror.owner;
    if (owner is ClassMirror) {
      return owner;
    } else if (owner is LibraryMirror) {
      return owner;
    }
    return null;
  }

  /**
   * For parity with the JavaScript debugger, we treat some getters as if
   * they are fields so that users can see their values immediately.
   * This matches JavaScript's behavior for getters on DOM objects.
   * In the future we should consider adding an annotation to tag getters
   * in user libraries as side effect free.
   */
  static bool _isSideEffectFreeGetter(
      MethodMirror methodMirror, LibraryMirror libraryMirror) {
    // This matches JavaScript behavior. We should consider displaying
    // getters for all dart platform libraries rather than just the DOM
    // libraries.
    return libraryMirror.uri.scheme == 'dart' &&
        SIDE_EFFECT_FREE_LIBRARIES.contains(libraryMirror.uri.toString());
  }

  /**
   * Whether we should treat a property as a field for the purposes of the
   * debugger.
   */
  static bool treatPropertyAsField(
      MethodMirror methodMirror, LibraryMirror libraryMirror) {
    return (methodMirror.isGetter || methodMirror.isSetter) &&
        (methodMirror.isSynthetic ||
            _isSideEffectFreeGetter(methodMirror, libraryMirror));
  }

  // TODO(jacobr): generate more concise function descriptions instead of
  // dumping the entire function source.
  static String describeFunction(function) {
    if (function is _Trampoline) return function._methodMirror.source;
    try {
      var mirror = reflect(function);
      return mirror.function.source;
    } catch (e) {
      return function.toString();
    }
  }

  static List getInvocationTrampolineDetails(_Trampoline method) {
    var loc = method._methodMirror.location;
    return [
      loc.line,
      loc.column,
      loc.sourceUri.toString(),
      MirrorSystem.getName(method._selector)
    ];
  }

  static List getLibraryProperties(
      String libraryUrl, bool ownProperties, bool accessorPropertiesOnly) {
    var properties = new Map<String, _Property>();
    var libraryMirror = getLibraryMirror(libraryUrl);
    _addInstanceMirrors(
        libraryMirror,
        libraryMirror,
        libraryMirror.declarations,
        ownProperties,
        accessorPropertiesOnly,
        false,
        false,
        properties);
    if (!accessorPropertiesOnly) {
      // We need to add class properties for all classes in the library.
      libraryMirror.declarations.forEach((symbol, declarationMirror) {
        if (declarationMirror is ClassMirror) {
          var name = MirrorSystem.getName(symbol);
          if (declarationMirror.hasReflectedType &&
              !properties.containsKey(name)) {
            properties[name] = new _Property(name)
              ..value = declarationMirror.reflectedType;
          }
        }
      });
    }
    return packageProperties(properties);
  }

  static List getObjectProperties(
      o, bool ownProperties, bool accessorPropertiesOnly) {
    var properties = new Map<String, _Property>();
    var names = new Set<String>();
    var objectMirror = reflect(o);
    var classMirror = objectMirror.type;
    _addInstanceMirrors(
        objectMirror,
        classMirror.owner,
        classMirror.instanceMembers,
        ownProperties,
        accessorPropertiesOnly,
        false,
        true,
        properties);
    return packageProperties(properties);
  }

  static List getObjectClassProperties(
      o, bool ownProperties, bool accessorPropertiesOnly) {
    var properties = new Map<String, _Property>();
    var objectMirror = reflect(o);
    var classMirror = objectMirror.type;
    _addInstanceMirrors(
        objectMirror,
        classMirror.owner,
        classMirror.instanceMembers,
        ownProperties,
        accessorPropertiesOnly,
        true,
        false,
        properties);
    _addStatics(classMirror, properties, accessorPropertiesOnly);
    return packageProperties(properties);
  }

  static List getClassProperties(
      Type t, bool ownProperties, bool accessorPropertiesOnly) {
    var properties = new Map<String, _Property>();
    var classMirror = reflectClass(t);
    _addStatics(classMirror, properties, accessorPropertiesOnly);
    return packageProperties(properties);
  }

  static void _addStatics(ClassMirror classMirror,
      Map<String, _Property> properties, bool accessorPropertiesOnly) {
    var libraryMirror = classMirror.owner;
    classMirror.declarations.forEach((symbol, declaration) {
      var name = _getShortSymbolName(symbol, declaration);
      if (name.isEmpty) return;
      if (declaration is VariableMirror) {
        if (accessorPropertiesOnly) return;
        if (!declaration.isStatic) return;
        properties.putIfAbsent(name, () => new _Property(name))
          ..value = classMirror.getField(symbol).reflectee
          ..writable = !declaration.isFinal && !declaration.isConst;
      } else if (declaration is MethodMirror) {
        MethodMirror methodMirror = declaration;
        // FIXMEDART: should we display constructors?
        if (methodMirror.isConstructor) return;
        if (!methodMirror.isStatic) return;
        if (accessorPropertiesOnly) {
          if (methodMirror.isRegularMethod ||
              treatPropertyAsField(methodMirror, libraryMirror)) {
            return;
          }
        } else if (!methodMirror.isRegularMethod &&
            !treatPropertyAsField(methodMirror, libraryMirror)) {
          return;
        }
        var property = properties.putIfAbsent(name, () => new _Property(name));
        _fillMethodMirrorProperty(libraryMirror, classMirror, methodMirror,
            symbol, accessorPropertiesOnly, property);
      }
    });
  }

  static void _fillMethodMirrorProperty(
      LibraryMirror libraryMirror,
      methodOwner,
      MethodMirror methodMirror,
      Symbol symbol,
      bool accessorPropertiesOnly,
      _Property property) {
    if (methodMirror.isRegularMethod) {
      property
        ..value = new _MethodTrampoline(methodOwner, methodMirror, symbol)
        ..isMethod = true;
    } else if (methodMirror.isGetter) {
      if (treatPropertyAsField(methodMirror, libraryMirror)) {
        try {
          property.value = methodOwner.getField(symbol).reflectee;
        } catch (e) {
          property
            ..wasThrown = true
            ..value = e;
        }
      } else if (accessorPropertiesOnly) {
        property.getter =
            new _GetterTrampoline(methodOwner, methodMirror, symbol);
      }
    } else if (methodMirror.isSetter) {
      if (accessorPropertiesOnly &&
          !treatPropertyAsField(methodMirror, libraryMirror)) {
        property.setter = new _SetterTrampoline(methodOwner, methodMirror,
            MirrorSystem.getSymbol(property.name, libraryMirror));
      }
      property.writable = true;
    }
  }

  /**
   * Helper method that handles collecting up properties from classes
   * or libraries using the filters [ownProperties], [accessorPropertiesOnly],
   * [hideFields], and [hideMethods] to determine which properties are
   * collected. [accessorPropertiesOnly] specifies whether all properties
   * should be returned or just accessors. [hideFields] specifies whether
   * fields should be hidden. hideMethods specifies whether methods should be
   * shown or hidden. [ownProperties] is not currently used but is part of the
   * Blink devtools API for enumerating properties.
   */
  static void _addInstanceMirrors(
      ObjectMirror objectMirror,
      LibraryMirror libraryMirror,
      Map<Symbol, Mirror> declarations,
      bool ownProperties,
      bool accessorPropertiesOnly,
      bool hideFields,
      bool hideMethods,
      Map<String, _Property> properties) {
    declarations.forEach((symbol, declaration) {
      if (declaration is TypedefMirror || declaration is ClassMirror) return;
      var name = _getShortSymbolName(symbol, declaration);
      if (name.isEmpty) return;
      bool isField = declaration is VariableMirror ||
          (declaration is MethodMirror &&
              treatPropertyAsField(declaration, libraryMirror));
      if ((isField && hideFields) || (hideMethods && !isField)) return;
      if (accessorPropertiesOnly) {
        if (declaration is VariableMirror ||
            declaration.isRegularMethod ||
            isField) {
          return;
        }
      } else if (declaration is MethodMirror &&
          (declaration.isGetter || declaration.isSetter) &&
          !treatPropertyAsField(declaration, libraryMirror)) {
        return;
      }
      var property = properties.putIfAbsent(name, () => new _Property(name));
      if (declaration is VariableMirror) {
        property
          ..value = objectMirror.getField(symbol).reflectee
          ..writable = !declaration.isFinal && !declaration.isConst;
        return;
      }
      _fillMethodMirrorProperty(libraryMirror, objectMirror, declaration,
          symbol, accessorPropertiesOnly, property);
    });
  }

  /**
   * Flatten down the properties data structure into a List that is easy to
   * access from native code.
   */
  static List packageProperties(Map<String, _Property> properties) {
    var ret = [];
    for (var property in properties.values) {
      ret.addAll([
        property.name,
        property.setter,
        property.getter,
        property.value,
        property.hasValue,
        property.writable,
        property.isMethod,
        property.isOwn,
        property.wasThrown
      ]);
    }
    return ret;
  }

  /**
   * Get a property, returning null if the property does not exist.
   * For private property names, we attempt to resolve the property in the
   * context of each library that the property name could be associated with.
   */
  static getObjectPropertySafe(o, String propertyName) {
    var objectMirror = reflect(o);
    var classMirror = objectMirror.type;
    if (propertyName.startsWith("_")) {
      var attemptedLibraries = new Set<LibraryMirror>();
      while (classMirror != null) {
        LibraryMirror library = classMirror.owner;
        if (!attemptedLibraries.contains(library)) {
          try {
            return objectMirror
                .getField(MirrorSystem.getSymbol(propertyName, library))
                .reflectee;
          } catch (e) {}
          attemptedLibraries.add(library);
        }
        classMirror = classMirror.superclass;
      }
      return null;
    }
    try {
      return objectMirror
          .getField(MirrorSystem.getSymbol(propertyName))
          .reflectee;
    } catch (e) {
      return null;
    }
  }

  /**
   * Helper to wrap the inspect method on InjectedScriptHost to provide the
   * inspect method required for the
   */
  static List consoleApi(host) {
    return [
      "inspect",
      (o) {
        js.JsNative.callMethod(host, "_inspect", [o]);
        return o;
      },
      "dir",
      window.console.dir,
      "dirxml",
      window.console.dirxml
      // FIXME: add copy method.
    ];
  }

  static List getMapKeyList(Map map) => map.keys.toList();

  static bool isNoSuchMethodError(obj) => obj is NoSuchMethodError;

  static void register(
      Document document, String tag, Type type, String extendsTagName) {
    var nativeClass = _validateCustomType(type);

    if (extendsTagName == null) {
      if (nativeClass.reflectedType != HtmlElement) {
        throw new UnsupportedError('Class must provide extendsTag if base '
            'native class is not HTMLElement');
      }
    }

    _register(document, tag, type, extendsTagName);
  }

  static void _register(Document document, String tag, Type customType,
          String extendsTagName) =>
      _blink.Blink_Utils.register(document, tag, customType, extendsTagName);

  static Element createElement(Document document, String tagName) =>
      _blink.Blink_Utils.createElement(document, tagName);
}

class _DOMWindowCrossFrame extends DartHtmlDomObject implements WindowBase {
  _DOMWindowCrossFrame.internal();

  static _createSafe(win) {
    if (identical(win, window)) {
      // The current Window object is the only window object that should not
      // use _DOMWindowCrossFrame.
      return window;
    }
    return win is _DOMWindowCrossFrame
        ? win
        : _blink.Blink_Utils.setInstanceInterceptor(win, _DOMWindowCrossFrame);
  }

  // Fields.
  HistoryBase get history {
    var history = _blink.BlinkWindow.instance.history_Getter_(this);
    return history is _HistoryCrossFrame
        ? history
        : _blink.Blink_Utils
            .setInstanceInterceptor(history, _HistoryCrossFrame);
  }

  LocationBase get location {
    var location = _blink.BlinkWindow.instance.location_Getter_(this);
    return location is _LocationCrossFrame
        ? location
        : _blink.Blink_Utils
            .setInstanceInterceptor(location, _LocationCrossFrame);
  }

  bool get closed => _blink.BlinkWindow.instance.closed_Getter_(this);
  WindowBase get opener => _convertNativeToDart_Window(
      _blink.BlinkWindow.instance.opener_Getter_(this));
  WindowBase get parent => _convertNativeToDart_Window(
      _blink.BlinkWindow.instance.parent_Getter_(this));
  WindowBase get top => _convertNativeToDart_Window(
      _blink.BlinkWindow.instance.top_Getter_(this));

  // Methods.
  void close() => _blink.BlinkWindow.instance.close_Callback_0_(this);
  void postMessage(Object message, String targetOrigin,
          [List<MessagePort> transfer]) =>
      _blink.BlinkWindow.instance.postMessage_Callback_3_(
          this,
          convertDartToNative_SerializedScriptValue(message),
          targetOrigin,
          transfer);

  // Implementation support.
  String get typeName => "Window";

  // TODO(efortuna): Remove this method. dartbug.com/16814
  Events get on => throw new UnsupportedError(
      'You can only attach EventListeners to your own window.');
  // TODO(efortuna): Remove this method. dartbug.com/16814
  void _addEventListener(
          [String type, EventListener listener, bool useCapture]) =>
      throw new UnsupportedError(
          'You can only attach EventListeners to your own window.');
  // TODO(efortuna): Remove this method. dartbug.com/16814
  void addEventListener(String type, EventListener listener,
          [bool useCapture]) =>
      throw new UnsupportedError(
          'You can only attach EventListeners to your own window.');
  // TODO(efortuna): Remove this method. dartbug.com/16814
  bool dispatchEvent(Event event) => throw new UnsupportedError(
      'You can only attach EventListeners to your own window.');
  // TODO(efortuna): Remove this method. dartbug.com/16814
  void _removeEventListener(
          [String type, EventListener listener, bool useCapture]) =>
      throw new UnsupportedError(
          'You can only attach EventListeners to your own window.');
  // TODO(efortuna): Remove this method. dartbug.com/16814
  void removeEventListener(String type, EventListener listener,
          [bool useCapture]) =>
      throw new UnsupportedError(
          'You can only attach EventListeners to your own window.');
}

class _HistoryCrossFrame extends DartHtmlDomObject implements HistoryBase {
  _HistoryCrossFrame.internal();

  // Methods.
  void back() => _blink.BlinkHistory.instance.back_Callback_0_(this);
  void forward() => _blink.BlinkHistory.instance.forward_Callback_0_(this);
  void go([int delta]) {
    if (delta != null) {
      _blink.BlinkHistory.instance.go_Callback_1_(this, delta);
      return;
    }
    _blink.BlinkHistory.instance.go_Callback_0_(this);
    return;
  }

  // Implementation support.
  String get typeName => "History";
}

class _LocationCrossFrame extends DartHtmlDomObject implements LocationBase {
  _LocationCrossFrame.internal();

  // Fields.
  set href(String value) =>
      _blink.BlinkLocation.instance.href_Setter_(this, value);

  // Implementation support.
  String get typeName => "Location";
}

// TODO(vsm): Remove DOM isolate code once we have Dartium isolates
// as workers.  This is only used to support
// printing and timers in background isolates. As workers they should
// be able to just do those things natively.

_makeSendPortFuture(spawnRequest) {
  final completer = new Completer<SendPort>.sync();
  final port = new ReceivePort();
  port.listen((result) {
    completer.complete(result);
    port.close();
  });
  // TODO: SendPort.hashCode is ugly way to access port id.
  spawnRequest(port.sendPort.hashCode);
  return completer.future;
}

Future<SendPort> _spawnDomHelper(Function f) => _makeSendPortFuture((portId) {
      _Utils.spawnDomHelper(f, portId);
    });

final Future<SendPort> __HELPER_ISOLATE_PORT =
    _spawnDomHelper(_helperIsolateMain);

// Tricky part.
// Once __HELPER_ISOLATE_PORT gets resolved, it will still delay in .then
// and to delay Timer.run is used. However, Timer.run will try to register
// another Timer and here we got stuck: event cannot be posted as then
// callback is not executed because it's delayed with timer.
// Therefore once future is resolved, it's unsafe to call .then on it
// in Timer code.
SendPort __SEND_PORT;

_sendToHelperIsolate(msg, SendPort replyTo) {
  if (__SEND_PORT != null) {
    __SEND_PORT.send([msg, replyTo]);
  } else {
    __HELPER_ISOLATE_PORT.then((port) {
      __SEND_PORT = port;
      __SEND_PORT.send([msg, replyTo]);
    });
  }
}

final _TIMER_REGISTRY = new Map<SendPort, Timer>();

const _NEW_TIMER = 'NEW_TIMER';
const _CANCEL_TIMER = 'CANCEL_TIMER';
const _TIMER_PING = 'TIMER_PING';
const _PRINT = 'PRINT';

_helperIsolateMain(originalSendPort) {
  var port = new ReceivePort();
  originalSendPort.send(port.sendPort);
  port.listen((args) {
    var msg = args.first;
    var replyTo = args.last;
    final cmd = msg[0];
    if (cmd == _NEW_TIMER) {
      final duration = new Duration(milliseconds: msg[1]);
      bool periodic = msg[2];
      ping() {
        replyTo.send(_TIMER_PING);
      }

      ;
      _TIMER_REGISTRY[replyTo] = periodic
          ? new Timer.periodic(duration, (_) {
              ping();
            })
          : new Timer(duration, ping);
    } else if (cmd == _CANCEL_TIMER) {
      _TIMER_REGISTRY.remove(replyTo).cancel();
    } else if (cmd == _PRINT) {
      final message = msg[1];
      // TODO(antonm): we need somehow identify those isolates.
      print('[From isolate] $message');
    }
  });
}

final _printClosure = (s) => window.console.log(s);
final _pureIsolatePrintClosure = (s) {
  _sendToHelperIsolate([_PRINT, s], null);
};

final _forwardingPrintClosure = _Utils.forwardingPrint;

final _uriBaseClosure = () => Uri.parse(window.location.href);

final _pureIsolateUriBaseClosure = () {
  throw new UnimplementedError("Uri.base on a background isolate "
      "is not supported in the browser");
};

class _Timer implements Timer {
  static const int _STATE_TIMEOUT = 0;
  static const int _STATE_INTERVAL = 1;
  int _state;

  _Timer(int milliSeconds, void callback(Timer timer), bool repeating) {
    if (repeating) {
      _state = (window._setInterval(() {
                callback(this);
              }, milliSeconds) <<
              1) |
          _STATE_INTERVAL;
    } else {
      _state = (window._setTimeout(() {
                _state = null;
                callback(this);
              }, milliSeconds) <<
              1) |
          _STATE_TIMEOUT;
    }
  }

  void cancel() {
    if (_state == null) return;
    int id = _state >> 1;
    if ((_state & 1) == _STATE_TIMEOUT) {
      window._clearTimeout(id);
    } else {
      window._clearInterval(id);
    }
    _state = null;
  }

  bool get isActive => _state != null;
}

get _timerFactoryClosure =>
    (int milliSeconds, void callback(Timer timer), bool repeating) {
      return new _Timer(milliSeconds, callback, repeating);
    };

class _PureIsolateTimer implements Timer {
  bool _isActive = true;
  final ReceivePort _port = new ReceivePort();
  SendPort _sendPort; // Effectively final.

  //  static SendPort _SEND_PORT;

  _PureIsolateTimer(int milliSeconds, callback, repeating) {
    _sendPort = _port.sendPort;
    _port.listen((msg) {
      assert(msg == _TIMER_PING);
      _isActive = repeating;
      callback(this);
      if (!repeating) _cancel();
    });

    _send([_NEW_TIMER, milliSeconds, repeating]);
  }

  void cancel() {
    _cancel();
    _send([_CANCEL_TIMER]);
  }

  void _cancel() {
    _isActive = false;
    _port.close();
  }

  _send(msg) {
    _sendToHelperIsolate(msg, _sendPort);
  }

  bool get isActive => _isActive;
}

get _pureIsolateTimerFactoryClosure =>
    ((int milliSeconds, void callback(Timer time), bool repeating) =>
        new _PureIsolateTimer(milliSeconds, callback, repeating));

class _ScheduleImmediateHelper {
  MutationObserver _observer;
  final DivElement _div = new DivElement();
  Function _callback;

  _ScheduleImmediateHelper() {
    // Run in the root-zone as the DOM callback would otherwise execute in the
    // current zone.
    Zone.ROOT.run(() {
      // Mutation events get fired as soon as the current event stack is unwound
      // so we just make a dummy event and listen for that.
      _observer = new MutationObserver(_handleMutation);
      _observer.observe(_div, attributes: true);
    });
  }

  void _schedule(callback) {
    if (_callback != null) {
      throw new StateError(
          'Only one immediate callback can be scheduled at once');
    }
    _callback = callback;
    // Toggle it to trigger the mutation event.
    _div.hidden = !_div.hidden;
  }

  _handleMutation(List<MutationRecord> mutations, MutationObserver observer) {
    var tmp = _callback;
    _callback = null;
    tmp();
  }
}

final _ScheduleImmediateHelper _scheduleImmediateHelper =
    new _ScheduleImmediateHelper();

get _scheduleImmediateClosure => (void callback()) {
      _scheduleImmediateHelper._schedule(callback);
    };

get _pureIsolateScheduleImmediateClosure => ((void callback()) =>
    throw new UnimplementedError("scheduleMicrotask in background isolates "
        "are not supported in the browser"));

// Class for unsupported native browser 'DOM' objects.
class _UnsupportedBrowserObject extends DartHtmlDomObject {}
