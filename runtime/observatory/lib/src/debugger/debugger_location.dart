// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of debugger;

class DebuggerLocation {
  DebuggerLocation.file(this.script, this.line, this.col);
  DebuggerLocation.func(this.function);
  DebuggerLocation.error(this.errorMessage);

  static RegExp sourceLocMatcher = new RegExp(r'^([^\d:][^:]+:)?(\d+)(:\d+)?');
  static RegExp functionMatcher = new RegExp(r'^([^.]+)([.][^.]+)?');

  /// Parses a source location description.
  ///
  /// Formats:
  ///   ''                -  current position
  ///   13                -  line 13, current script
  ///   13:20             -  line 13, col 20, current script
  ///   script.dart:13    -  line 13, script.dart
  ///   script.dart:13:20 -  line 13, col 20, script.dart
  ///   main              -  function
  ///   FormatException   -  constructor
  ///   _SHA1._updateHash -  method
  static Future<DebuggerLocation> parse(Debugger debugger, String locDesc) {
    if (locDesc == '') {
      // Special case: '' means return current location.
      return _currentLocation(debugger);
    }

    // Parse the location description.
    var match = sourceLocMatcher.firstMatch(locDesc);
    if (match != null) {
      return _parseScriptLine(debugger, match);
    }
    match = functionMatcher.firstMatch(locDesc);
    if (match != null) {
      return _parseFunction(debugger, match);
    }
    return new Future.value(new DebuggerLocation.error(
        "Invalid source location '${locDesc}'"));
  }

  static Future<DebuggerLocation> _currentLocation(Debugger debugger) {
    ServiceMap stack = debugger.stack;
    if (stack == null || stack['frames'].length == 0) {
      return new Future.value(new DebuggerLocation.error(
          'A script must be provided when the stack is empty'));
    }
    var frame = stack['frames'][debugger.currentFrame];
    Script script = frame.location.script;
    return script.load().then((_) {
      var line = script.tokenToLine(frame.location.tokenPos);
      // TODO(turnidge): Pass in the column here once the protocol supports it.
      return new Future.value(new DebuggerLocation.file(script, line, null));
    });
  }

  static Future<DebuggerLocation> _parseScriptLine(Debugger debugger,
                                                   Match match) {
    var scriptName = match.group(1);
    if (scriptName != null) {
      scriptName = scriptName.substring(0, scriptName.length - 1);
    }
    var lineStr = match.group(2);
    assert(lineStr != null);
    var colStr = match.group(3);
    if (colStr != null) {
      colStr = colStr.substring(1);
    }
    var line = int.parse(lineStr, onError:(_) => -1);
    var col = (colStr != null
               ? int.parse(colStr, onError:(_) => -1)
               : null);
    if (line == -1) {
      return new Future.value(new DebuggerLocation.error(
          "Line '${lineStr}' must be an integer"));
    }
    if (col == -1) {
      return new Future.value(new DebuggerLocation.error(
          "Column '${colStr}' must be an integer"));
    }

    if (scriptName != null) {
      // Resolve the script.
      return _lookupScript(debugger.isolate, scriptName).then((scripts) {
        if (scripts.length == 0) {
          return new DebuggerLocation.error("Script '${scriptName}' not found");
        } else if (scripts.length == 1) {
          return new DebuggerLocation.file(scripts[0], line, col);
        } else {
          // TODO(turnidge): Allow the user to disambiguate.
          return new DebuggerLocation.error("Script '${scriptName}' is ambigous");
        }
      });
    } else {
      // No script provided.  Default to top of stack for now.
      ServiceMap stack = debugger.stack;
      if (stack == null || stack['frames'].length == 0) {
        return new Future.value(new DebuggerLocation.error(
            'A script must be provided when the stack is empty'));
      }
      Script script = stack['frames'][0].location.script;
      return new Future.value(new DebuggerLocation.file(script, line, col));
    }
  }

  static Future<List<Script>> _lookupScript(Isolate isolate,
                                            String name,
                                            {bool allowPrefix: false}) {
    var pending = [];
    for (var lib in isolate.libraries) {
      if (!lib.loaded) {
        pending.add(lib.load());
      }
    }
    return Future.wait(pending).then((_) {
      List matches = [];
      for (var lib in isolate.libraries) {
        for (var script in lib.scripts) {
          if (allowPrefix) {
            if (script.name.startsWith(name)) {
              matches.add(script);
            }
          } else {
            if (name == script.name) {
              matches.add(script);
            }
          }
        }
      }
      return matches;
    });
  }

  static List<ServiceFunction> _lookupFunction(Isolate isolate,
                                               String name,
                                               { bool allowPrefix: false }) {
    var matches = [];
    for (var lib in isolate.libraries) {
      assert(lib.loaded);
      for (var function in lib.functions) {
        if (allowPrefix) {
          if (function.name.startsWith(name)) {
            matches.add(function);
          }
        } else {
          if (name == function.name) {
            matches.add(function);
          }
        }
      }
    }
    return matches;
  }

  static Future<List<Class>> _lookupClass(Isolate isolate,
                                          String name,
                                          { bool allowPrefix: false }) {
    var pending = [];
    for (var lib in isolate.libraries) {
      assert(lib.loaded);
      for (var cls in lib.classes) {
        if (!cls.loaded) {
          pending.add(cls.load());
        }
      }
    }
    return Future.wait(pending).then((_) {
      var matches = [];
      for (var lib in isolate.libraries) {
        for (var cls in lib.classes) {
          if (allowPrefix) {
            if (cls.name.startsWith(name)) {
              matches.add(cls);
            }
          } else {
            if (name == cls.name) {
              matches.add(cls);
            }
          }
        }
      }
      return matches;
    });
  }

  static ServiceFunction _getConstructor(Class cls, String name) {
    for (var function in cls.functions) {
      assert(cls.loaded);
      if (name == function.name) {
        return function;
      }
    }
    return null;
  }

  // TODO(turnidge): This does not handle named functions which are
  // inside of named functions, e.g. foo.bar.baz.
  static Future<DebuggerLocation> _parseFunction(Debugger debugger,
                                               Match match) {
    Isolate isolate = debugger.isolate;
    var base = match.group(1);
    var qualifier = match.group(2);
    assert(base != null);

    return _lookupClass(isolate, base).then((classes) {
      var functions = [];
      if (qualifier == null) {
        // Unqualified name is either a function or a constructor.
        functions.addAll(_lookupFunction(isolate, base));

        for (var cls in classes) {
          // Look for a self-named constructor.
          var constructor = _getConstructor(cls, cls.name);
          if (constructor != null) {
            functions.add(constructor);
          }
        }
      } else {
        // Qualified name.
        var functionName = qualifier.substring(1);
        for (var cls in classes) {
          assert(cls.loaded);
          for (var function in cls.functions) {
            if (function.kind == FunctionKind.kConstructor) {
              // Constructor names are class-qualified.
              if (match.group(0) == function.name) {
                functions.add(function);
              }
            } else {
              if (functionName == function.name) {
                functions.add(function);
              }
            }
          }
        }
      }
      if (functions.length == 0) {
        return new DebuggerLocation.error(
            "Function '${match.group(0)}' not found");
      } else if (functions.length == 1) {
        return new DebuggerLocation.func(functions[0]);
      } else {
        // TODO(turnidge): Allow the user to disambiguate.
        return new DebuggerLocation.error(
            "Function '${match.group(0)}' is ambigous");
      }
      return new DebuggerLocation.error('foo');
    });
  }

  static RegExp partialSourceLocMatcher =
      new RegExp(r'^([^\d:]?[^:]+[:]?)?(\d+)?([:]\d+)?');
  static RegExp partialFunctionMatcher = new RegExp(r'^([^.]*)([.][^.]*)?');

  /// Completes a partial source location description.
  static Future<List<String>> complete(Debugger debugger, String locDesc) {
    List<Future<List<String>>> pending = [];
    var match = partialFunctionMatcher.firstMatch(locDesc);
    if (match != null) {
      pending.add(_completeFunction(debugger, match));
    }

    match = partialSourceLocMatcher.firstMatch(locDesc);
    if (match != null) {
      pending.add(_completeFile(debugger, match));
    }

    return Future.wait(pending).then((List<List<String>> responses) {
      var completions = [];
      for (var response in responses) {
        completions.addAll(response);
      }
      return completions;
    });
  }

  static Future<List<String>> _completeFunction(Debugger debugger,
                                                Match match) {
    Isolate isolate = debugger.isolate;
    var base = match.group(1);
    var qualifier = match.group(2);
    base = (base == null ? '' : base);
    
    if (qualifier == null) {
      return _lookupClass(isolate, base, allowPrefix:true).then((classes) {
        var completions = [];

        // Complete top-level function names.
        var functions = _lookupFunction(isolate, base, allowPrefix:true);
        var funcNames = functions.map((f) => f.name).toList();
        funcNames.sort();
        completions.addAll(funcNames);

        // Complete class names.
        var classNames = classes.map((f) => f.name).toList();
        classNames.sort();
        completions.addAll(classNames);

        return completions;
      });
    } else {
      return _lookupClass(isolate, base, allowPrefix:false).then((classes) {
        var completions = [];
        for (var cls in classes) {
          for (var function in cls.functions) {
            if (function.kind == FunctionKind.kConstructor) {
              if (function.name.startsWith(match.group(0))) {
                completions.add(function.name);
              }
            } else {
              if (function.qualifiedName.startsWith(match.group(0))) {
                completions.add(function.qualifiedName);
              }
            }
          }
        }
        completions.sort();
        return completions;
      });
    }
  }

  static Future<List<String>> _completeFile(Debugger debugger, Match match) {
    var scriptName = match.group(1);
    var lineStr = match.group(2);
    var colStr = match.group(3);
    if (lineStr != null || colStr != null) {
      // TODO(turnidge): Complete valid line and column numbers.
      return new Future.value([]);
    }
    scriptName = (scriptName == null ? '' : scriptName);

    return _lookupScript(debugger.isolate, scriptName, allowPrefix:true)
      .then((scripts) {
        List completions = [];
        for (var script in scripts) {
          completions.add(script.name + ':');
        }
        completions.sort();
        return completions;
      });
  }

  String toString() {
    if (valid) {
      if (function != null) {
        return '${function.qualifiedName}';
      } else if (col != null) {
        return '${script.name}:${line}:${col}';
      } else {
        return '${script.name}:${line}';
      }
    }
    return 'invalid source location (${errorMessage})';
  }

  Script script;
  int line;
  int col;
  ServiceFunction function;
  String errorMessage;
  bool get valid => (errorMessage == null);
}
