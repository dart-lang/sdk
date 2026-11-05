// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:convert" show json, ByteConversionSink;
import "dart:io" show File, gzip;
import "dart:typed_data";

import "package:_fe_analyzer_shared/src/scanner/characters.dart";
import "package:front_end/src/api_prototype/compiler_options.dart"
    show CompilerOptions;
import "package:front_end/src/base/compiler_context.dart" show CompilerContext;
import "package:front_end/src/base/processed_options.dart"
    show ProcessedOptions;
import "package:front_end/src/base/ticker.dart" show Ticker;
import "package:front_end/src/builder/declaration_builders.dart";
import "package:front_end/src/dill/dill_loader.dart" show DillLoader;
import "package:front_end/src/dill/dill_target.dart" show DillTarget;
import "package:front_end/src/kernel/hierarchy/hierarchy_builder.dart"
    show ClassHierarchyBuilder;
import "package:kernel/ast.dart" show Component, DartType, Library;
import "package:kernel/class_hierarchy.dart" show ClassHierarchy;
import "package:kernel/core_types.dart" show CoreTypes;
import "package:kernel/target/targets.dart" show NoneTarget, TargetFlags;
import 'package:kernel/testing/type_parser_environment.dart'
    show TypeParserEnvironment, parseLibrary;
import "package:kernel/type_environment.dart" show TypeEnvironment;

class SubtypesBenchmark {
  final Library library;
  final List<SubtypeCheck> checks;

  new(this.library, this.checks);
}

class SubtypeCheck {
  final DartType s;
  final DartType t;
  final bool isSubtype;

  new(this.s, this.t, this.isSubtype);

  @override
  String toString() {
    return (new StringBuffer()
          ..write(s)
          ..write(isSubtype ? " <: " : " !<: ")
          ..write(t))
        .toString();
  }
}

class ParseBenchMark extends ByteConversionSink {
  bool _closed = false;
  late TypeParserEnvironment environment;
  late Library library;

  List<SubtypeCheck> subtypeChecks = <SubtypeCheck>[];
  Map<String, DartType> _sTypeDeduplication = {};
  Map<String, DartType> _tTypeDeduplication = {};

  final BytesBuilder _data = new BytesBuilder();
  int _mapNesting = 0;
  int _listNesting = 0;
  bool _inString = false;
  bool _collect = false;
  _Found _foundClasses = _Found.NotFound;
  _Found _foundChecks = _Found.NotFound;

  void _foundClass(List classes) {
    // Ensure the classes required by the subtyping algorithm implementation are
    // in 'dart:core'.
    List<String> coreClassesForSubtyping = [
      "class Object;",
      "class Function extends Object;",
      "class Record extends Object;",
    ];
    for (dynamic classEntry in classes) {
      coreClassesForSubtyping.remove(classEntry);
    }
    classes.addAll(coreClassesForSubtyping);

    Uri uri = Uri.parse("dart:core");
    environment = new TypeParserEnvironment(uri, uri);
    library = parseLibrary(uri, classes.join("\n"), environment: environment);
  }

  void _processCheck(Map<dynamic, dynamic> check) {
    String kind = check["kind"];
    List<dynamic> arguments = check["arguments"];
    String sSource = arguments[0];
    String tSource = arguments[1];
    if (sSource.contains("?")) return;
    if (tSource.contains("?")) return;
    DartType s;
    DartType t;
    if (arguments.length > 2) {
      List<dynamic> typeParametersSource = arguments[2];
      TypeParserEnvironment localEnvironment = environment
          .extendWithTypeParameters("${typeParametersSource.join(', ')}");
      s = localEnvironment.parseType(sSource);
      t = localEnvironment.parseType(tSource);
    } else {
      // Use two different caches so that it can't shortcut with identical.
      s = _sTypeDeduplication[sSource] ??= environment.parseType(sSource);
      t = _tTypeDeduplication[tSource] ??= environment.parseType(tSource);
    }
    subtypeChecks.add(new SubtypeCheck(s, t, kind == "isSubtype"));
  }

  SubtypesBenchmark parseBenchMark(Uint8List? bytes) {
    if (bytes!.length > 3 &&
        bytes[0] == 0x1f &&
        bytes[1] == 0x8b &&
        bytes[2] == 0x08) {
      ByteConversionSink gzipDecoder = gzip.decoder.startChunkedConversion(
        this,
      );
      gzipDecoder.add(bytes);
      gzipDecoder.close();
    } else {
      add(bytes);
      close();
    }

    if (!_closed) throw "Not closed?!?";
    if (_foundChecks != _Found.Processed) throw "Didn't find 'checks'";
    if (subtypeChecks.isEmpty) throw "Found no checks.";

    return new SubtypesBenchmark(library, subtypeChecks);
  }

  dynamic _decode() {
    assert(_collect);
    dynamic result = json.decode(String.fromCharCodes(_data.takeBytes()));
    _collect = false;
    assert(_data.isEmpty);
    return result;
  }

  void _startCollect(int byte) {
    assert(!_collect);
    assert(_data.isEmpty);
    _collect = true;
    _data.addByte(byte);
  }

  bool _atNest(int map, int list) {
    return _mapNesting == map && _listNesting == list;
  }

  void _processChunk(List<int> bytes) {
    // We know the data. It's all ascii, looks like this:
    // {
    //   "classes": [
    //     lots of strings
    //   ],
    //   "checks": [
    //     lots of maps
    //   ]
    // }
    // and there are no escaping etc.

    // Though, for good measure:
    for (int i = 0; i < bytes.length; i++) {
      if (bytes[i] >= 128) throw "Unexpected input: ${bytes[i]}";
    }

    // Process this chunk. Find all of "classes", json decode and process it.
    // Find each object in the "checks" list, json decode and process it
    for (int i = 0; i < bytes.length; i++) {
      int char = bytes[i];
      if (_collect) _data.addByte(char);
      if (!_inString) {
        if (char == $OPEN_CURLY_BRACKET) {
          _mapNesting++;
          if (_foundChecks == _Found.Found && _atNest(2, 1)) {
            _startCollect(char);
          }
        } else if (char == $CLOSE_CURLY_BRACKET) {
          _mapNesting--;
          if (_foundChecks == _Found.Found && _atNest(1, 1)) {
            assert(_foundClasses == _Found.Processed);
            _processCheck(_decode());
          }
        } else if (char == $OPEN_SQUARE_BRACKET) {
          _listNesting++;
          if (_foundClasses == _Found.Found && _atNest(1, 1)) {
            _startCollect(char);
          }
        } else if (char == $CLOSE_SQUARE_BRACKET) {
          _listNesting--;
          if (_foundClasses == _Found.Found && _atNest(1, 0)) {
            _foundClasses = _Found.Processed;
            _foundClass(_decode());
          } else if (_foundChecks == _Found.Found && _atNest(1, 0)) {
            _foundChecks = _Found.Processed;
          }
        } else if (char == $DQ) {
          if (_atNest(1, 0)) {
            _startCollect(char);
          }
          _inString = true;
        }
      } else if (char == $DQ) {
        if (_atNest(1, 0)) {
          String s = _decode();
          if (s == "classes" && _foundClasses == _Found.NotFound) {
            _foundClasses = _Found.Found;
          } else if (s == "checks" && _foundChecks == _Found.NotFound) {
            _foundChecks = _Found.Found;
          } else {
            throw "Unexpected data: $s";
          }
        }
        _inString = false;
      }
    }
  }

  @override
  void add(List<int> chunk) {
    _processChunk(chunk);
  }

  @override
  void close() {
    _closed = true;
  }
}

enum _Found { NotFound, Found, Processed }

void performKernelChecks(
  List<SubtypeCheck> checks,
  TypeEnvironment environment,
) {
  for (int i = 0; i < checks.length; i++) {
    SubtypeCheck check = checks[i];
    bool isSubtype = environment.isSubtypeOf(check.s, check.t);
    if (isSubtype != check.isSubtype) {
      throw "Check failed: $check";
    }
  }
}

void performBuilderChecks(
  List<SubtypeCheck> checks,
  ClassHierarchyBuilder hierarchy,
) {
  for (int i = 0; i < checks.length; i++) {
    SubtypeCheck check = checks[i];
    bool isSubtype = hierarchy.types.isSubtypeOf(check.s, check.t);
    if (isSubtype != check.isSubtype) {
      throw "Check failed: $check";
    }
  }
}

Future<void> run(Uri benchmarkInput, String name) async {
  const int runs = 50;
  final Ticker ticker = new Ticker(isVerbose: false);
  Stopwatch kernelWatch = new Stopwatch();
  Stopwatch builderWatch = new Stopwatch();
  SubtypesBenchmark bench = new ParseBenchMark().parseBenchMark(
    new File.fromUri(benchmarkInput).readAsBytesSync(),
  );
  ticker.logMs("Parsed benchmark file");
  Component c = new Component(libraries: [bench.library]);
  CoreTypes coreTypes = new CoreTypes(c);
  ClassHierarchy hierarchy = new ClassHierarchy(c, coreTypes);
  TypeEnvironment environment = new TypeEnvironment(coreTypes, hierarchy);

  final CompilerContext context = new CompilerContext(
    new ProcessedOptions(
      options: new CompilerOptions()
        ..packagesFileUri = Uri.base.resolve(".dart_tool/package_config.json"),
    ),
  );
  await context.runInContext<void>((_) async {
    DillTarget target = new DillTarget(
      context,
      ticker,
      await context.options.getUriTranslator(),
      new NoneTarget(new TargetFlags()),
    );
    final DillLoader loader = target.loader;
    loader.appendLibraries(c);
    target.buildOutlines();
    ClassBuilder objectClass =
        loader.coreLibrary.lookupRequiredLocalMember("Object") as ClassBuilder;
    ClassHierarchyBuilder hierarchy = new ClassHierarchyBuilder(
      objectClass,
      loader,
      coreTypes,
    );

    for (int i = 0; i < runs; i++) {
      kernelWatch.start();
      performKernelChecks(bench.checks, environment);
      kernelWatch.stop();

      builderWatch.start();
      performBuilderChecks(bench.checks, hierarchy);
      builderWatch.stop();

      if (i == 0) {
        print(
          "SubtypeKernel${name}First(RuntimeRaw): "
          "${kernelWatch.elapsedMilliseconds} ms",
        );
        print(
          "SubtypeFasta${name}First(RuntimeRaw): "
          "${builderWatch.elapsedMilliseconds} ms",
        );
      }
    }
  });

  print(
    "SubtypeKernel${name}Avg${runs}(RuntimeRaw): "
    "${kernelWatch.elapsedMilliseconds / runs} ms",
  );
  print(
    "SubtypeFasta${name}Avg${runs}(RuntimeRaw): "
    "${builderWatch.elapsedMilliseconds / runs} ms",
  );
}

void main() => run(Uri.base.resolve("type_checks.json"), "***");
