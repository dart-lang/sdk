// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of html;

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
      return Function.apply(_data[member], invocation.positionalArguments, invocation.namedArguments);
    }
  }

  void clear() => _data.clear();

  /**
   * List all variables currently defined.
   */
  List variables() => _data.keys.toList(growable: false);
}

class _Utils {
  static double dateTimeToDouble(DateTime dateTime) =>
      dateTime.millisecondsSinceEpoch.toDouble();
  static DateTime doubleToDateTime(double dateTime) {
    try {
      return new DateTime.fromMillisecondsSinceEpoch(dateTime.toInt());
    } catch(_) {
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

  static window() native "Utils_window";
  static forwardingPrint(String message) native "Utils_forwardingPrint";

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
    for (int i = 0; i < localVariables.length; i+=2) {
      map[stripMemberName(localVariables[i])] = localVariables[i+1];
    }
    return map;
  }

  static _ConsoleVariables _consoleTempVariables = new _ConsoleVariables();

  /**
   * Header passed in from the Dartium Developer Tools when an expression is
   * evaluated in the console as opposed to the watch window or another context
   * that does not expect REPL support.
   */
  static const _CONSOLE_API_SUPPORT_HEADER =
      'with ((console && console._commandLineAPI) || {}) {\n';

  static bool expectsConsoleApi(String expression) {
    return expression.indexOf(_CONSOLE_API_SUPPORT_HEADER) == 0;;
  }

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
   * wrapExpressionAsClosure("${_CONSOLE_API_SUPPORT_HEADER}foo + bar + a",
   *                         ["bar", 40, "foo", 2])
   * </code>
   * will return:
   * <code>
   * ["""(final $consoleVariables, final bar, final foo, final a, final b) =>
   * (foo + bar + a
   * )""",
   * [_consoleTempVariables, 40, 2, someValue, someOtherValue]]
   * </code>
   */
  static List wrapExpressionAsClosure(String expression, List locals) {
    // FIXME: dartbug.com/10434 find a less fragile way to determine whether
    // we need to strip off console API support added by InjectedScript.
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
      if (args.isNotEmpty) {
        sb.write(", ");
      }
      sb.write("final $arg");
      args[arg] = value;
    }

    if (expectsConsoleApi(expression)) {
      expression = expression.substring(expression.indexOf('\n') + 1);
      expression = expression.substring(0, expression.lastIndexOf('\n'));

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
      expression = expression.replaceAllMapped(_VARIABLE_DECLARATION,
          (match) {
            var variableName = match[2];
            // Set the console variable if it isn't already set.
            if (!_consoleTempVariables._data.containsKey(variableName)) {
              _consoleTempVariables._data[variableName] = null;
            }
            return "${match[1]}\$consoleVariables.${variableName}";
          });

      expression = expression.replaceAllMapped(_SET_VARIABLE,
          (match) {
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
      for (int i = 0; i < locals.length; i+= 2) {
        addArg(locals[i], locals[i+1]);
      }
    }
    // Inject all the already defined console variables.
    _consoleTempVariables._data.forEach(addArg);

    // TODO(jacobr): remove the parentheses around the expresson once
    // dartbug.com/13723 is fixed. Currently we wrap expression in parentheses
    // to ensure only valid Dart expressions are allowed. Otherwise the DartVM
    // quietly ignores trailing Dart statements resulting in user confusion
    // when part of an invalid expression they entered is ignored.
    sb..write(') => (\n$expression\n)');
    return [sb.toString(), args.values.toList(growable: false)];
  }

  /**
   * TODO(jacobr): this is a big hack to get around the fact that we are still
   * passing some JS expression to the evaluate method even when in a Dart
   * context.
   */
  static bool isJsExpression(String expression) =>
    expression.startsWith("(function getCompletions");

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
      if (mirror == null)
        return;
      addAll(mirror.declarations, isStatic);
      if (mirror.superclass != null)
        addForClass(mirror.superclass, isStatic);
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
   * Convenience helper to get the keys of a [Map] as a [List].
   */
  static List getMapKeyList(Map map) => map.keys.toList();

 /**
   * Returns the keys of an arbitrary Dart Map encoded as unique Strings.
   * Keys that are strings are left unchanged except that the prefix ":" is
   * added to disambiguate keys from other Dart members.
   * Keys that are not strings have # followed by the index of the key in the map
   * prepended to disambuguate. This scheme is simplistic but easy to encode and
   * decode. The use case for this method is displaying all map keys in a human
   * readable way in debugging tools.
   */
  static List<String> getEncodedMapKeyList(dynamic obj) {
    if (obj is! Map) return null;

    var ret = new List<String>();
    int i = 0;
    return obj.keys.map((key) {
      var encodedKey;
      if (key is String) {
        encodedKey = ':$key';
      } else {
        // If the key isn't a string, return a guaranteed unique for this map
        // string representation of the key that is still somewhat human
        // readable.
        encodedKey = '#${i}:$key';
      }
      i++;
      return encodedKey;
    }).toList(growable: false);
  }

  static final RegExp _NON_STRING_KEY_REGEXP = new RegExp("^#(\\d+):(.+)\$");

  static _decodeKey(Map map, String key) {
    // The key is a regular old String.
    if (key.startsWith(':')) return key.substring(1);

    var match = _NON_STRING_KEY_REGEXP.firstMatch(key);
    if (match != null) {
      int index = int.parse(match.group(1));
      var iter = map.keys.skip(index);
      if (iter.isNotEmpty) {
        var ret = iter.first;
        // Validate that the toString representation of the key matches what we
        // expect. FIXME: throw an error if it does not.
        assert(match.group(2) == '$ret');
        return ret;
      }
    }
    return null;
  }

  /**
   * Converts keys encoded with [getEncodedMapKeyList] to their actual keys.
   */
  static lookupValueForEncodedMapKey(Map obj, String key) => obj[_decodeKey(obj, key)];

  /**
   * Builds a constructor name with the form expected by the C Dart mirrors API.
   */
  static String buildConstructorName(String className, String constructorName) => '$className.$constructorName';

  /**
   * Strips the class name from an expression of the form "className.someName".
   */
  static String stripClassName(String str, String className) {
    if (str.length > className.length + 1 &&
        str.startsWith(className) && str[className.length] == '.') {
      return str.substring(className.length + 1);
    } else {
      return str;
    }
  }

  /**
   * Removes the trailing dot from an expression ending in a dot.
   * This method is used as Library prefixes include a trailing dot when using
   * the C Dart debugger API.
   */
  static String stripTrailingDot(String str) =>
    (str != null && str[str.length - 1] == '.') ? str.substring(0, str.length - 1) : str;

  static String addTrailingDot(String str) => '${str}.';

  static String demangle(String str) {
    var atPos = str.indexOf('@');
    return atPos == -1 ? str : str.substring(0, atPos);
  }

  static bool isNoSuchMethodError(obj) => obj is NoSuchMethodError;

  static bool _isBuiltinType(ClassMirror cls) {
    // TODO(vsm): Find a less hackish way to do this.
    LibraryMirror lib = cls.owner;
    String libName = lib.uri.toString();
    return libName.startsWith('dart:');
  }

  static void register(Document document, String tag, Type type,
      String extendsTagName) {
    // TODO(vsm): Move these checks into native code.
    ClassMirror cls = reflectClass(type);
    if (_isBuiltinType(cls)) {
      throw new UnsupportedError("Invalid custom element from ${(cls.owner as LibraryMirror).uri}.");
    }
    var className = MirrorSystem.getName(cls.simpleName);
    var createdConstructor = cls.declarations[new Symbol('$className.created')];
    if (createdConstructor == null ||
        createdConstructor is! MethodMirror ||
        !createdConstructor.isConstructor) {
      throw new UnsupportedError(
          'Class is missing constructor $className.created');
    }

    if (createdConstructor.parameters.length > 0) {
      throw new UnsupportedError(
          'Constructor $className.created must take zero arguments');
    }

    Symbol objectName = reflectClass(Object).qualifiedName;
    bool isRoot(ClassMirror cls) =>
        cls == null || cls.qualifiedName == objectName;
    Symbol elementName = reflectClass(HtmlElement).qualifiedName;
    bool isElement(ClassMirror cls) =>
        cls != null && cls.qualifiedName == elementName;
    ClassMirror superClass = cls.superclass;
    ClassMirror nativeClass = _isBuiltinType(superClass) ? superClass : null;
    while(!isRoot(superClass) && !isElement(superClass)) {
      superClass = superClass.superclass;
      if (nativeClass == null && _isBuiltinType(superClass)) {
        nativeClass = superClass;
      }
    }
    if (extendsTagName == null) {
      if (nativeClass.reflectedType != HtmlElement) {
        throw new UnsupportedError('Class must provide extendsTag if base '
            'native class is not HTMLElement');
      }
    }

    _register(document, tag, type, extendsTagName);
  }

  static void _register(Document document, String tag, Type customType,
      String extendsTagName) native "Utils_register";

  static Element createElement(Document document, String tagName) native "Utils_createElement";

  static void initializeCustomElement(HtmlElement element) native "Utils_initializeCustomElement";
}

class _DOMWindowCrossFrame extends NativeFieldWrapperClass2 implements
    WindowBase {
  _DOMWindowCrossFrame.internal();

  // Fields.
  HistoryBase get history native "Window_history_cross_frame_Getter";
  LocationBase get location native "Window_location_cross_frame_Getter";
  bool get closed native "Window_closed_Getter";
  int get length native "Window_length_Getter";
  WindowBase get opener native "Window_opener_Getter";
  WindowBase get parent native "Window_parent_Getter";
  WindowBase get top native "Window_top_Getter";

  // Methods.
  void close() native "Window_close_Callback";
  void postMessage(/*SerializedScriptValue*/ message, String targetOrigin, [List messagePorts]) native "Window_postMessage_Callback";

  // Implementation support.
  String get typeName => "Window";
}

class _HistoryCrossFrame extends NativeFieldWrapperClass2 implements HistoryBase {
  _HistoryCrossFrame.internal();

  // Methods.
  void back() native "History_back_Callback";
  void forward() native "History_forward_Callback";
  void go(int distance) native "History_go_Callback";

  // Implementation support.
  String get typeName => "History";
}

class _LocationCrossFrame extends NativeFieldWrapperClass2 implements LocationBase {
  _LocationCrossFrame.internal();

  // Fields.
  void set href(String) native "Location_href_Setter";

  // Implementation support.
  String get typeName => "Location";
}

class _DOMStringMap extends NativeFieldWrapperClass2 implements Map<String, String> {
  _DOMStringMap.internal();

  bool containsValue(String value) => Maps.containsValue(this, value);
  bool containsKey(String key) native "DOMStringMap_containsKey_Callback";
  String operator [](String key) native "DOMStringMap_item_Callback";
  void operator []=(String key, String value) native "DOMStringMap_setItem_Callback";
  String putIfAbsent(String key, String ifAbsent()) => Maps.putIfAbsent(this, key, ifAbsent);
  String remove(String key) native "DOMStringMap_remove_Callback";
  void clear() => Maps.clear(this);
  void forEach(void f(String key, String value)) => Maps.forEach(this, f);
  Iterable<String> get keys native "DOMStringMap_getKeys_Callback";
  Iterable<String> get values => Maps.getValues(this);
  int get length => Maps.length(this);
  bool get isEmpty => Maps.isEmpty(this);
  bool get isNotEmpty => Maps.isNotEmpty(this);
  void addAll(Map<String, String> other) {
    other.forEach((key, value) => this[key] = value);
  }
}

final _printClosure = window.console.log;
final _pureIsolatePrintClosure = (s) {
  throw new UnimplementedError("Printing from a background isolate "
                               "is not supported in the browser");
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
      }, milliSeconds) << 1) | _STATE_INTERVAL;
    } else {
      _state = (window._setTimeout(() {
        _state = null;
        callback(this);
      }, milliSeconds) << 1) | _STATE_TIMEOUT;
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

get _pureIsolateTimerFactoryClosure =>
    ((int milliSeconds, void callback(Timer time), bool repeating) =>
  throw new UnimplementedError("Timers on background isolates "
                               "are not supported in the browser"));

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

void _initializeCustomElement(Element e) {
  _Utils.initializeCustomElement(e);
}
