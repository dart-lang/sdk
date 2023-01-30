// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Tool used mainly by dart2js developers to debug the generated info and check
/// that it is consistent and that it covers all the data we expect it to cover.
library dart2js_info.bin.debug_info;

import 'package:args/command_runner.dart';
import 'package:dart2js_info/info.dart';
import 'package:dart2js_info/src/graph.dart';
import 'package:dart2js_info/src/io.dart';
import 'package:dart2js_info/src/util.dart';

import 'usage_exception.dart';

class DebugCommand extends Command<void> with PrintUsageException {
  @override
  final String name = "debug";
  @override
  final String description = "Dart2js-team diagnostics on a dump-info file.";

  DebugCommand() {
    argParser.addOption('show-library',
        help: "Show detailed data for a library with the given name");
  }

  @override
  void run() async {
    final argRes = argResults!;
    final args = argRes.rest;
    if (args.isEmpty) {
      usageException('Missing argument: info.data');
    }

    final info = await infoFromFile(args.first);
    final debugLibName = argRes['show-library'];

    validateSize(info, debugLibName);
    validateParents(info);
    compareGraphs(info);
    verifyDeps(info);
  }
}

/// Validates that codesize of elements adds up to total codesize.
void validateSize(AllInfo info, String debugLibName) {
  // Gather data from visiting all info elements.
  final tracker = _SizeTracker(debugLibName);
  info.accept(tracker);

  // Validate that listed elements include elements of each library.
  final listed = {...info.functions, ...info.fields};
  // For our sanity we do some validation of dump-info invariants
  final diff1 = listed.difference(tracker.discovered);
  final diff2 = tracker.discovered.difference(listed);
  if (diff1.isEmpty || diff2.isEmpty) {
    _pass('all fields and functions are covered');
  } else {
    if (diff1.isNotEmpty) {
      _fail("some elements where listed globally that weren't part of any "
          "library (non-zero ${diff1.where((f) => f.size > 0).length})");
    }
    if (diff2.isNotEmpty) {
      _fail("some elements found in libraries weren't part of the global list"
          " (non-zero ${diff2.where((f) => f.size > 0).length})");
    }
  }

  // Validate that code-size adds up.
  final realTotal = info.program!.size;
  int totalLib = info.libraries.fold(0, (n, lib) => n + lib.size);
  int constantsSize = info.constants.fold(0, (n, c) => n + c.size);
  int accounted = totalLib + constantsSize;

  if (accounted != realTotal) {
    var percent =
        ((realTotal - accounted) * 100 / realTotal).toStringAsFixed(2);
    _fail('$percent% size missing: $accounted (all libs + consts) '
        '< $realTotal (total)');
  }
  int missingTotal = tracker.missing.values.fold(0, (a, b) => a + b);
  if (missingTotal > 0) {
    var percent = (missingTotal * 100 / realTotal).toStringAsFixed(2);
    _fail('$percent% size missing in libraries (sum of elements > lib.size)');
  }
}

/// Validates that every element in the model has a parent (except libraries).
void validateParents(AllInfo info) {
  final parentlessInfos = <Info>{};

  void failIfNoParents(List<Info> infos) {
    for (var info in infos) {
      if (info.parent == null) {
        parentlessInfos.add(info);
      }
    }
  }

  failIfNoParents(info.functions);
  failIfNoParents(info.typedefs);
  failIfNoParents(info.classes);
  failIfNoParents(info.classTypes);
  failIfNoParents(info.fields);
  failIfNoParents(info.closures);
  if (parentlessInfos.isEmpty) {
    _pass('all elements have a parent');
  } else {
    _fail('${parentlessInfos.length} elements have no parent');
  }
}

class _SizeTracker extends RecursiveInfoVisitor {
  /// A library name for which to print debugging information (if not null).
  final String? _debugLibName;

  _SizeTracker(this._debugLibName);

  /// [FunctionInfo]s and [FieldInfo]s transitively reachable from [LibraryInfo]
  /// elements.
  final Set<Info> discovered = <Info>{};

  /// Total number of bytes missing if you look at the reported size compared
  /// to the sum of the nested infos (e.g. if a class size is smaller than the
  /// sum of its methods). Used for validation and debugging of the dump-info
  /// invariants.
  final Map<Info, int> missing = {};

  /// Set of [FunctionInfo]s that appear to be unused by the app (they are not
  /// registered [coverage]).
  final List unused = [];

  /// Tracks the current state of this visitor.
  List<_State> stack = [_State()];

  /// Code discovered for a [LibraryInfo], only used for debugging.
  final StringBuffer _debugCode = StringBuffer();
  int _indent = 2;

  void _push() => stack.add(_State());

  void _pop(Info info) {
    var last = stack.removeLast();
    var size = last._totalSize;
    if (size > info.size) {
      // record dump-info inconsistencies.
      missing[info] = size - info.size;
    } else {
      // if size < info.size, that is OK, the enclosing element might have code
      // of it's own (e.g. a class declaration includes the name of the class,
      // but the discovered size only counts the size of the members.)
      size = info.size;
    }
    stack.last
      .._totalSize += size
      .._count += last._count
      .._bodySize += last._bodySize;
  }

  bool _debug = false;
  @override
  void visitLibrary(LibraryInfo info) {
    if (_debugLibName != null) _debug = info.name.contains(_debugLibName!);
    _push();
    if (_debug) {
      _debugCode.write('{\n');
      _indent = 4;
    }
    super.visitLibrary(info);
    _pop(info);
    if (_debug) {
      _debug = false;
      _indent = 4;
      _debugCode.write('}\n');
    }
  }

  void _handleCodeInfo(BasicInfo info) {
    discovered.add(info);
    // ignore: avoid_dynamic_calls
    var code = (info as dynamic).code as String?;
    if (_debug && code != null) {
      bool isClosureClass = info.name.endsWith('.call');
      if (isClosureClass) {
        var cname = info.name.substring(0, info.name.indexOf('.'));
        _debugCode.write(' ' * _indent);
        _debugCode.write(cname);
        _debugCode.write(': {\n');
        _indent += 2;
        _debugCode.write(' ' * _indent);
        _debugCode.write('...\n');
      }

      print('$info $isClosureClass \n$code');
      _debugCode.write(' ' * _indent);
      var endsInNewLine = code.endsWith('\n');
      if (endsInNewLine) code = code.substring(0, code.length - 1);
      _debugCode.write(code.replaceAll('\n', '\n${' ' * _indent}'));
      if (endsInNewLine) _debugCode.write(',\n');
      if (isClosureClass) {
        _indent -= 2;
        _debugCode.write(' ' * _indent);
        _debugCode.write('},\n');
      }
    }
    stack.last._totalSize += info.size;
    stack.last._bodySize += info.size;
    stack.last._count++;
  }

  @override
  void visitField(FieldInfo info) {
    _handleCodeInfo(info);
    super.visitField(info);
  }

  @override
  void visitFunction(FunctionInfo info) {
    _handleCodeInfo(info);
    super.visitFunction(info);
  }

  @override
  void visitTypedef(TypedefInfo info) {
    if (_debug) print('$info');
    stack.last._totalSize += info.size;
    super.visitTypedef(info);
  }

  @override
  void visitClass(ClassInfo info) {
    if (_debug) {
      print('$info');
      _debugCode.write(' ' * _indent);
      _debugCode.write('${info.name}: {\n');
      _indent += 2;
    }
    _push();
    super.visitClass(info);
    _pop(info);
    if (_debug) {
      _debugCode.write(' ' * _indent);
      _debugCode.write('},\n');
      _indent -= 2;
    }
  }

  @override
  void visitClassType(ClassTypeInfo info) {
    if (_debug) {
      print('$info');
      _debugCode.write(' ' * _indent);
      _debugCode.write('ClassType: ${info.name}: {\n');
      _indent += 2;
    }
    _push();
    super.visitClassType(info);
    _pop(info);
    if (_debug) {
      _debugCode.write(' ' * _indent);
      _debugCode.write('},\n');
      _indent -= 2;
    }
  }
}

class _State {
  int _count = 0;
  int _totalSize = 0;
  int _bodySize = 0;
}

/// Validates that both forms of dependency information match.
void compareGraphs(AllInfo info) {
  var g1 = EdgeListGraph<Info>();
  var g2 = EdgeListGraph<Info>();
  for (var f in info.functions) {
    g1.addNode(f);
    for (var g in f.uses) {
      g1.addEdge(f, g.target);
    }
    g2.addNode(f);
    if (info.dependencies[f] != null) {
      for (var g in info.dependencies[f]!) {
        g2.addEdge(f, g);
      }
    }
  }

  for (var f in info.fields) {
    g1.addNode(f);
    for (var g in f.uses) {
      g1.addEdge(f, g.target);
    }
    g2.addNode(f);
    if (info.dependencies[f] != null) {
      for (var g in info.dependencies[f]!) {
        g2.addEdge(f, g);
      }
    }
  }

  // Note: these checks right now show that 'uses' links are computed
  // differently than 'deps' links
  int inUsesNotInDependencies = 0;
  int inDependenciesNotInUses = 0;
  void sameEdges(f) {
    var targets1 = g1.targetsOf(f).toSet();
    var targets2 = g2.targetsOf(f).toSet();
    inUsesNotInDependencies += targets1.difference(targets2).length;
    inDependenciesNotInUses += targets2.difference(targets1).length;
  }

  info.functions.forEach(sameEdges);
  info.fields.forEach(sameEdges);
  if (inUsesNotInDependencies == 0 && inDependenciesNotInUses == 0) {
    _pass('dependency data is consistent');
  } else {
    _fail('inconsistencies in dependency data:\n'
        '   $inUsesNotInDependencies edges missing from "dependencies" graph\n'
        '   $inDependenciesNotInUses edges missing from "uses" graph');
  }
}

// Validates that all elements are reachable from `main` in the dependency
// graph.
void verifyDeps(AllInfo info) {
  var graph = graphFromInfo(info);
  var entrypoint = info.program!.entrypoint;
  var reachables = Set.from(graph.preOrder(entrypoint));

  var functionsAndFields = <BasicInfo>[...info.functions, ...info.fields];
  var unreachables =
      functionsAndFields.where((func) => !reachables.contains(func));
  if (unreachables.isNotEmpty) {
    _fail('${unreachables.length} elements are unreachable from the '
        'entrypoint');
  } else {
    _pass('all elements are reachable from the entrypoint');
  }
}

void _pass(String msg) => print('\x1b[32mPASS\x1b[0m: $msg');
void _fail(String msg) => print('\x1b[31mFAIL\x1b[0m: $msg');
