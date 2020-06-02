// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of debugger;

class DebuggerLocation {
  DebuggerLocation.file(this.script, this.line, this.col);
  DebuggerLocation.func(this.function);
  DebuggerLocation.error(this.errorMessage);

  static RegExp sourceLocMatcher = new RegExp(r'^([^\d:][^:]+:)?(\d+)(:\d+)?');
  static RegExp packageLocMatcher =
      new RegExp(r'^package:([^\d:][^:]+:)?(\d+)(:\d+)?');
  static RegExp functionMatcher = new RegExp(r'^([^.]+)([.][^.]+)?');

  /// Parses a source location description.
  ///
  /// Formats:
  ///   ''                     -  current position
  ///   13                     -  line 13, current script
  ///   13:20                  -  line 13, col 20, current script
  ///   script.dart:13         -  line 13, script.dart
  ///   script.dart:13:20      -  line 13, col 20, script.dart
  ///   package:a/b.dart:13    -  line 13, "b.dart" in package "a".
  ///   package:a/b.dart:13:20 -  line 13, col 20, "b.dart" in package "a".
  ///   main                   -  function
  ///   FormatException        -  constructor
  ///   _SHA1._updateHash      -  method
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
    match = packageLocMatcher.firstMatch(locDesc);
    if (match != null) {
      return _parseScriptLine(debugger, match, package: true);
    }
    match = functionMatcher.firstMatch(locDesc);
    if (match != null) {
      return _parseFunction(debugger, match);
    }
    return new Future.value(
        new DebuggerLocation.error("Invalid source location '${locDesc}'"));
  }

  static Future<Frame?> _currentFrame(Debugger debugger) async {
    ServiceMap? stack = debugger.stack;
    if (stack == null || stack['frames'].length == 0) {
      return null;
    }
    return stack['frames'][debugger.currentFrame] as Frame?;
  }

  static Future<DebuggerLocation> _currentLocation(Debugger debugger) async {
    var frame = await _currentFrame(debugger);
    if (frame == null) {
      return new DebuggerLocation.error(
          'A script must be provided when the stack is empty');
    }
    Script script = frame.location!.script;
    await script.load();
    var line = script.tokenToLine(frame.location!.tokenPos);
    var col = script.tokenToCol(frame.location!.tokenPos);
    return new DebuggerLocation.file(script, line, col);
  }

  static Future<DebuggerLocation> _parseScriptLine(
      Debugger debugger, Match match,
      {bool package = false}) async {
    var scriptName = match.group(1);
    if (package) {
      scriptName = "package:$scriptName";
    }
    if (scriptName != null) {
      scriptName = scriptName.substring(0, scriptName.length - 1);
    }
    var lineStr = match.group(2);
    assert(lineStr != null);
    var colStr = match.group(3);
    if (colStr != null) {
      colStr = colStr.substring(1);
    }
    var line = int.tryParse(lineStr!) ?? -1;
    var col = (colStr != null ? int.tryParse(colStr) ?? -1 : null);
    if (line == -1) {
      return new Future.value(
          new DebuggerLocation.error("Line '${lineStr}' must be an integer"));
    }
    if (col == -1) {
      return new Future.value(
          new DebuggerLocation.error("Column '${colStr}' must be an integer"));
    }

    if (scriptName != null) {
      // Resolve the script.
      Set<Script> scripts = await _lookupScript(debugger.isolate, scriptName);
      if (scripts.length == 0) {
        scripts =
            await _lookupScript(debugger.isolate, scriptName, useUri: true);
      }
      if (scripts.length == 0) {
        return new DebuggerLocation.error("Script '${scriptName}' not found");
      } else if (scripts.length == 1) {
        return new DebuggerLocation.file(scripts.single, line, col);
      } else {
        // TODO(turnidge): Allow the user to disambiguate.
        return new DebuggerLocation.error(
            "Script '${scriptName}' is ambiguous");
      }
    } else {
      // No script provided.  Default to top of stack for now.
      var frame = await _currentFrame(debugger);
      if (frame == null) {
        return new Future.value(new DebuggerLocation.error(
            'A script must be provided when the stack is empty'));
      }
      Script script = frame.location!.script;
      await script.load();
      return new DebuggerLocation.file(script, line, col);
    }
  }

  static Future<Set<Script>> _lookupScript(Isolate isolate, String name,
      {bool allowPrefix: false, bool useUri: false}) {
    var pending = <Future>[];
    for (var lib in isolate.libraries) {
      if (!lib.loaded) {
        pending.add(lib.load());
      }
    }
    return Future.wait(pending).then((_) {
      var matches = <Script>{};
      for (var lib in isolate.libraries) {
        for (var script in lib.scripts) {
          final String haystack = useUri ? script.uri : script.name!;
          if (allowPrefix) {
            if (haystack.startsWith(name)) {
              matches.add(script);
            }
          } else {
            if (name == haystack) {
              matches.add(script);
            }
          }
        }
      }
      return matches;
    });
  }

  static List<ServiceFunction> _lookupFunction(Isolate isolate, String name,
      {bool allowPrefix: false}) {
    var matches = <ServiceFunction>[];
    for (var lib in isolate.libraries) {
      assert(lib.loaded);
      for (var function in lib.functions) {
        if (allowPrefix) {
          if (function.name!.startsWith(name)) {
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

  static Future<List<Class>> _lookupClass(Isolate isolate, String name,
      {bool allowPrefix: false}) async {
    if (isolate == null) {
      return [];
    }
    var pending = <Future>[];
    for (var lib in isolate.libraries) {
      assert(lib.loaded);
      for (var cls in lib.classes) {
        if (!cls.loaded) {
          pending.add(cls.load());
        }
      }
    }
    await Future.wait(pending);
    var matches = <Class>[];
    for (var lib in isolate.libraries) {
      for (var cls in lib.classes) {
        if (allowPrefix) {
          if (cls.name!.startsWith(name)) {
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
  }

  static ServiceFunction? _getConstructor(Class cls, String name) {
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
  static Future<DebuggerLocation> _parseFunction(
      Debugger debugger, Match match) {
    Isolate isolate = debugger.isolate;
    var base = match.group(1)!;
    var qualifier = match.group(2);
    assert(base != null);

    return _lookupClass(isolate, base).then((classes) {
      var functions = [];
      if (qualifier == null) {
        // Unqualified name is either a function or a constructor.
        functions.addAll(_lookupFunction(isolate, base));

        for (var cls in classes) {
          // Look for a self-named constructor.
          var constructor = _getConstructor(cls, cls.name!);
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
            if (function.kind == M.FunctionKind.constructor) {
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
            "Function '${match.group(0)}' is ambiguous");
      }
    });
  }

  static RegExp partialSourceLocMatcher =
      new RegExp(r'^([^\d:]?[^:]+[:]?)?(\d+)?([:]\d*)?');
  static RegExp partialFunctionMatcher = new RegExp(r'^([^.]*)([.][^.]*)?');

  /// Completes a partial source location description.
  static Future<List<String>> complete(Debugger debugger, String locDesc) {
    var pending = <Future<List<String>>>[];
    var match = partialFunctionMatcher.firstMatch(locDesc);
    if (match != null) {
      pending.add(_completeFunction(debugger, match));
    }

    match = partialSourceLocMatcher.firstMatch(locDesc);
    if (match != null) {
      pending.add(_completeFile(debugger, match));
    }

    return Future.wait(pending).then((List<List<String>> responses) {
      var completions = <String>[];
      for (var response in responses) {
        completions.addAll(response);
      }
      return completions;
    });
  }

  static Future<List<String>> _completeFunction(
      Debugger debugger, Match match) {
    Isolate isolate = debugger.isolate;
    var base = match.group(1) ?? '';
    var qualifier = match.group(2);

    if (qualifier == null) {
      return _lookupClass(isolate, base, allowPrefix: true).then((classes) {
        var completions = <String>[];

        // Complete top-level function names.
        var functions = _lookupFunction(isolate, base, allowPrefix: true);
        var funcNames = functions.map((f) => f.name!).toList();
        funcNames.sort();
        completions.addAll(funcNames);

        // Complete class names.
        var classNames = classes.map((f) => f.name!).toList();
        classNames.sort();
        completions.addAll(classNames);

        return completions;
      });
    } else {
      return _lookupClass(isolate, base, allowPrefix: false).then((classes) {
        var completions = <String>[];
        for (var cls in classes) {
          for (var function in cls.functions) {
            if (function.kind == M.FunctionKind.constructor) {
              if (function.name!.startsWith(match.group(0)!)) {
                completions.add(function.name!);
              }
            } else {
              if (function.qualifiedName!.startsWith(match.group(0)!)) {
                completions.add(function.qualifiedName!);
              }
            }
          }
        }
        completions.sort();
        return completions;
      });
    }
  }

  static bool _startsWithDigit(String s) {
    return '0'.compareTo(s[0]) <= 0 && '9'.compareTo(s[0]) >= 0;
  }

  static Future<List<String>> _completeFile(
      Debugger debugger, Match match) async {
    var scriptName;
    var scriptNameComplete = false;
    var lineStr;
    var lineStrComplete = false;
    var colStr;
    if (_startsWithDigit(match.group(1)!)) {
      // CASE 1: We have matched a prefix of (lineStr:)(colStr)
      var frame = await _currentFrame(debugger);
      if (frame == null) {
        return [];
      }
      scriptName = frame.location!.script.name;
      scriptNameComplete = true;
      lineStr = match.group(1) ?? '';
      if (lineStr.endsWith(':')) {
        lineStr = lineStr.substring(0, lineStr.length - 1);
        lineStrComplete = true;
      }
      colStr = match.group(2) ?? '';
    } else {
      // CASE 2: We have matched a prefix of (scriptName:)(lineStr)(:colStr)
      scriptName = match.group(1) ?? '';
      if (scriptName.endsWith(':')) {
        scriptName = scriptName.substring(0, scriptName.length - 1);
        scriptNameComplete = true;
      }
      lineStr = match.group(2) ?? '';
      colStr = match.group(3) ?? '';
      if (colStr.startsWith(':')) {
        lineStrComplete = true;
        colStr = colStr.substring(1);
      }
    }

    if (!scriptNameComplete) {
      // The script name is incomplete.  Complete it.
      var scripts =
          await _lookupScript(debugger.isolate, scriptName, allowPrefix: true);
      var completions = <String>[];
      for (var script in scripts) {
        completions.add(script.name! + ':');
      }
      completions.sort();
      return completions;
    } else {
      // The script name is complete.  Look it up.
      var scripts =
          await _lookupScript(debugger.isolate, scriptName, allowPrefix: false);
      if (scripts.isEmpty) {
        return [];
      }
      var script = scripts.first;
      await script.load();
      if (!lineStrComplete) {
        // Complete the line.
        var sharedPrefix = '${script.name}:';
        var completions = <String>[];
        var report = await script.isolate!.getSourceReport(
            [Isolate.kPossibleBreakpointsReport], script) as ServiceMap;
        Set<int> possibleBpts = getPossibleBreakpointLines(report, script);
        for (var line in possibleBpts) {
          var currentLineStr = line.toString();
          if (currentLineStr.startsWith(lineStr)) {
            completions.add('${sharedPrefix}${currentLineStr} ');
            completions.add('${sharedPrefix}${currentLineStr}:');
          }
        }
        return completions;
      } else {
        // Complete the column.
        int lineNum = int.parse(lineStr);
        var scriptLine = script.getLine(lineNum)!;
        var sharedPrefix = '${script.name}:${lineStr}:';
        var completions = <String>[];
        int maxCol = scriptLine.text.trimRight().runes.length;
        for (int i = 1; i <= maxCol; i++) {
          var currentColStr = i.toString();
          if (currentColStr.startsWith(colStr)) {
            completions.add('${sharedPrefix}${currentColStr} ');
          }
        }
        return completions;
      }
    }
  }

  String toString() {
    if (valid) {
      if (function != null) {
        return '${function!.qualifiedName}';
      } else if (col != null) {
        return '${script!.name}:${line}:${col}';
      } else {
        return '${script!.name}:${line}';
      }
    }
    return 'invalid source location (${errorMessage})';
  }

  Script? script;
  int? line;
  int? col;
  ServiceFunction? function;
  String? errorMessage;
  bool get valid => (errorMessage == null);
}
