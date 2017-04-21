// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Script that generates different approaches to initialize classes in
// JavaScript.
// Also benchmarks the approaches.

import 'dart:io';
import 'dart:async';

class Config {
  /// Number of classes that should be generated.
  final int nbClasses;

  /// Number of methods per class.
  final int nbMethodsPerClass;

  /// Should the JavaScript classes share a common super class?
  ///
  /// Currently unused for Dart, since it always has a common super class
  /// anyways.
  // TODO(floitsch): also create a common super class in Dart?
  final bool shareCommonSuperclass;

  /// Assign unique names to the methods or let them share the same one?
  ///
  /// Independent of this flag, the `callAll` and `instantiatePrevious` method
  /// names are the same for all classes.
  final bool sameMethodNames;

  /// Adds a `print` statement to the method.
  final bool shouldPrintInMethod;

  /// Adds while loops to the method body.
  ///
  /// This has the effect that dart2js won't be able to inline the method and
  /// controls the size of the method bodies.
  final int nbWhileLoopsInBody;

  /// Should the JavaScript output be wrapped into an anonymous function?
  ///
  /// When enabled wraps the program with the following pattern:
  /// `(function() { <program> })()`.
  final bool shouldWrapProgram;

  /// Adds a `callAll` method that invokes all other methods of the class.
  ///
  /// This is necessary for dart2js to avoid tree-shaking.
  /// Should probably always be on (except for presentations to demonstrate that
  /// dart2js knows how to tree-shake).
  ///
  /// This method counts towards the [nbMethodsPerClass] limit.
  final bool shouldEmitCallAllMethods;

  /// Adds an `instantiatePrevious` method that instantiates the previous class.
  ///
  /// A "previous" class is the class that was generated before the current
  /// class. The first class returns `null`.
  final bool shouldEmitInstantiatePreviousMethod;

  /// Makes sure that the dart2js tree-shaker doesn't remove classes.
  ///
  /// When set to `-1`, all classes are kept alive.
  final int fakeInstantiateClass;

  /// Defines the percent of classes that are dynamically instantiated.
  final int instantiateClassesPercent;

  Config(
      {this.nbClasses,
      this.nbMethodsPerClass,
      this.shareCommonSuperclass,
      this.sameMethodNames,
      this.shouldPrintInMethod,
      this.nbWhileLoopsInBody,
      this.shouldWrapProgram,
      this.shouldEmitCallAllMethods,
      this.shouldEmitInstantiatePreviousMethod,
      this.fakeInstantiateClass,
      this.instantiateClassesPercent});
}

String get d8Path {
  Uri scriptPath = Platform.script;
  String d8Executable = "../../../third_party/d8/";
  if (Platform.isWindows) {
    d8Executable += "windows/d8.exe";
  } else if (Platform.isMacOS) {
    d8Executable += "macos/d8";
  } else if (Platform.isLinux) {
    d8Executable += "linux/d8";
  } else {
    return null;
  }
  return scriptPath.resolve(d8Executable).path;
}

String get jsShellPath {
  Uri scriptPath = Platform.script;
  if (!Platform.isLinux) {
    return null;
  }
  return scriptPath.resolve("../../../tools/testing/bin/jsshell").path;
}

String get dart2jsPath {
  Uri scriptPath = Platform.script;
  return scriptPath.resolve("../../../sdk/bin/dart2js").path;
}

abstract class ClassGenerator {
  final StringBuffer buffer = new StringBuffer();
  // By convention all methods should take one argument with this name.
  final String argumentName = "x";
  final String callOtherMethodsName = "callAll";
  final String instantiatePreviousMethodName = "instantiatePrevious";

  final Config config;

  ClassGenerator(this.config);

  int get nbClasses => config.nbClasses;
  int get nbMethodsPerClass => config.nbMethodsPerClass;
  bool get shouldPrintInMethod => config.shouldPrintInMethod;
  bool get sameMethodNames => config.sameMethodNames;
  int get nbWhileLoopsInMethod => config.nbWhileLoopsInBody;
  bool get shareCommonSuperclass => config.shareCommonSuperclass;
  bool get shouldEmitCallAllMethods => config.shouldEmitCallAllMethods;
  bool get shouldEmitInstantiatePreviousMethod =>
      config.shouldEmitInstantiatePreviousMethod;
  int get fakeInstantiateClass => config.fakeInstantiateClass;
  int get instantiateClassesPercent => config.instantiateClassesPercent;

  Future measure(String filePrefix) async {
    String fileName = await generateRawJs(filePrefix);
    if (fileName == null) return;
    Directory dir = Directory.systemTemp.createTempSync('classes');
    try {
      File measuring = new File("${dir.path}/measuring.js");
      IOSink sink = measuring.openWrite();
      sink.writeln("var start = new Date();");
      await sink.addStream(new File(fileName).openRead());
      sink.writeln("print(new Date() - start)");
      String command;
      List<String> args;
      bool runJsShell = false;
      if (runJsShell) {
        command = jsShellPath;
        print("Running $command");
        args = [measuring.path];
      } else {
        command = d8Path;
        print("Running $command");
        args = ["--harmony-sloppy", measuring.path];
      }
      print("Running: $fileName");
      int nbRuns = 10;
      int sum = 0;
      int sumSw = 0;
      Stopwatch watch = new Stopwatch();
      for (int i = 0; i < nbRuns; i++) {
        watch.reset();
        watch.start();
        ProcessResult result = await Process.run(command, args);
        if (result.exitCode != 0) {
          print("run failed");
          print(result.stdout);
          print(result.stderr);
        }
        int elapsed = watch.elapsedMilliseconds;
        print("  output: ${result.stdout.trim()} ($elapsed)");
        sum += int.parse(result.stdout, onError: (str) => 0);
        sumSw += elapsed;
      }
      int mean = sum == 0 ? 0 : sum ~/ nbRuns;
      int meanSw = sumSw == 0 ? 0 : sumSw ~/ nbRuns;
      print("  mean: $mean ($meanSw)");
    } finally {
      dir.deleteSync(recursive: true);
    }
  }

  Future<String> generateRawJs(String filePrefix);

  String buildFileName(String filePrefix, String extension) {
    // TODO(floitsch): store other config info in the file name.
    return "$filePrefix.$nbClasses.$nbMethodsPerClass."
        "$instantiateClassesPercent.$description.$extension";
  }

  String writeFile(String filePrefix) {
    buffer.clear();
    emitClasses(); // Output is stored in `buffer`.

    String fileName = buildFileName(filePrefix, fileExtension);
    new File(fileName).writeAsStringSync(buffer.toString());
    print("wrote: $fileName");
    return fileName;
  }

  void writeln(x) => buffer.writeln(x);

  String classIdToName(int id) {
    if (id < 0) id = nbClasses + id;
    return "Class$id";
  }

  /// [id] is per class.
  String methodIdToName(int id, int classId) {
    if (sameMethodNames) return "method$id";
    return "method${classId}_$id";
  }

  // Must work for Dart and JS.
  void emitMethodBody(int methodId, int classId) {
    writeln("{");
    if (shouldPrintInMethod) {
      writeln("print('class: $classId, method: $methodId');");
    }
    if (nbWhileLoopsInMethod > 0) {
      writeln("var sum = 0;");
      for (int i = 0; i < nbWhileLoopsInMethod; i++) {
        writeln("for (var i = 0; i < $argumentName; i++) {");
        writeln("  sum++;");
        writeln("}");
      }
      writeln("return sum;");
    }
    writeln("}");
  }

  // Must work for Dart and JS.
  void emitCallOtherMethodsBody(List<int> methodIds, int classId) {
    writeln("{");
    writeln("var sum = 0;");
    for (int methodId in methodIds) {
      String methodName = methodIdToName(methodId, classId);
      writeln("sum += this.$methodName($argumentName);");
    }
    writeln("return sum;");
    writeln("}");
  }

  // Must work for Dart and JS.
  void emitInstantiatePrevious(int classId) {
    writeln("{");
    if (classId == 0) {
      writeln("return null;");
    } else {
      String previousClass = classIdToName(classId - 1);
      writeln("return new $previousClass();");
    }
    writeln("}");
  }

  /// Should write the class using [writeln].
  void emitClasses();

  String get description;
  String get fileExtension;
}

abstract class JavaScriptClassGenerator extends ClassGenerator {
  bool get wrapProgram => config.shouldWrapProgram;
  final String methodsObjectName = "methods";

  JavaScriptClassGenerator(Config config) : super(config);

  Future<String> generateRawJs(String filePrefix) =>
      new Future.value(writeFile(filePrefix));

  void emitUtilityFunctions();
  void emitClass(int classId, int superclassId);

  void emitClasses() {
    if (wrapProgram) writeln("(function() {");
    writeln("var $methodsObjectName;");
    emitUtilityFunctions();
    for (int i = 0; i < nbClasses; i++) {
      int superclassId = shareCommonSuperclass && i != 0 ? 0 : null;
      emitClass(i, superclassId);
    }

    if (fakeInstantiateClass != null) {
      String className = classIdToName(fakeInstantiateClass);
      writeln("""
        if (new Date() == 42) {
          var o = new $className();
          do {
            o.$callOtherMethodsName(99);
            o = o.$instantiatePreviousMethodName();
          } while(o != null);
        }""");
    }
    if (instantiateClassesPercent != null) {
      int targetClassId = ((nbClasses - 1) * instantiateClassesPercent) ~/ 100;
      String targetClassName = classIdToName(targetClassId);
      writeln("""
        var o = new $targetClassName();
        do {
          o = o.$instantiatePreviousMethodName();
        } while(o != null);
      """);
    }
    if (wrapProgram) writeln("})();");
  }

  String get fileExtension => "js";
}

enum PrototypeApproach { tmpFunction, internalProto, objectCreate }

class PlainJavaScriptClassGenerator extends JavaScriptClassGenerator {
  final PrototypeApproach prototypeApproach;
  final bool shouldInlineInherit;
  final bool useMethodsObject;

  PlainJavaScriptClassGenerator(Config config,
      {this.prototypeApproach, this.shouldInlineInherit, this.useMethodsObject})
      : super(config) {
    if (prototypeApproach == null) {
      throw "Must provide prototype approach";
    }
    if (shouldInlineInherit == null) {
      throw "Must provide inlining approach";
    }
    if (useMethodsObject == null) {
      throw "Must provide object-proto approach";
    }
    if (shouldInlineInherit &&
        prototypeApproach == PrototypeApproach.tmpFunction) {
      throw "Can't inline tmp-function approach";
    }
  }

  void emitInherit(cls, superclassId) {
    if (superclassId == null && !useMethodsObject) return;
    String sup = (superclassId == null) ? "null" : classIdToName(superclassId);
    if (!shouldInlineInherit) {
      if (useMethodsObject) {
        writeln("inherit($cls, $sup, $methodsObjectName);");
      } else {
        writeln("inherit($cls, $sup);");
      }
      return;
    }
    switch (prototypeApproach) {
      case PrototypeApproach.tmpFunction:
        throw "Should not happen";
        break;
      case PrototypeApproach.internalProto:
        if (useMethodsObject) {
          writeln("$cls.prototype = $methodsObjectName;");
        }
        if (superclassId != null) {
          writeln("$cls.prototype.__proto__ = $sup.prototype;");
        }
        break;
      case PrototypeApproach.objectCreate:
        if (useMethodsObject) {
          if (superclassId == null) {
            writeln("$cls.prototype = $methodsObjectName;");
          } else {
            writeln("$cls.prototype = Object.create($sup.prototype);");
            writeln("copyProperties($methodsObjectName, $cls.prototype);");
          }
        } else {
          writeln("$cls.prototype = Object.create($sup.prototype);");
        }
        break;
    }
  }

  void emitUtilityFunctions() {
    switch (prototypeApproach) {
      case PrototypeApproach.internalProto:
        if (useMethodsObject) {
          writeln('''
            function inherit(cls, sup, methods) {
              cls.prototype = methods;
              if (sup != null) {
                cls.prototype.__proto__ = sup.prototype;
              }
            }
            ''');
        } else {
          writeln('''
            function inherit(cls, sup) {
              cls.prototype.__proto__ = sup.prototype;
            }
            ''');
        }
        break;
      case PrototypeApproach.tmpFunction:
        if (useMethodsObject) {
          writeln('''
            function inherit(cls, sup, methods) {
              if (sup != null) {
                function tmp() {}
                tmp.prototype = sup.prototype;
                var proto = new tmp();
                proto.constructor = cls;
                cls.prototype = proto;
              }
              copyProperties(methods, cls.prototype);
            }''');
        } else {
          writeln('''
            function inherit(cls, sup) {
              function tmp() {}
              tmp.prototype = sup.prototype;
              var proto = new tmp();
              proto.constructor = cls;
              cls.prototype = proto;
            }''');
        }
        break;
      case PrototypeApproach.objectCreate:
        if (useMethodsObject) {
          writeln('''
            function inherit(cls, sup, methods) {
              if (sup == null) {
                cls.prototype = methods;
              } else {
                cls.prototype = Object.create(sup.prototype);
                copyProperties(methods, cls.prototype);
              }
            }
            ''');
        } else {
          writeln('''
            function inherit(cls, sup) {
              cls.prototype = Object.create(sup.prototype);
            }
            ''');
        }
        break;
    }
    writeln("""
    function copyProperties(from, to) {
      var props = Object.keys(from);
      for (var i = 0; i < props.length; i++) {
        var p = props[i];
        to[p] = from[p];
      }
    }""");
  }

  void emitMethod(int classId, String methodName, Function bodyEmitter,
      {bool emitArgument: true}) {
    String argumentString = emitArgument ? argumentName : "";
    if (useMethodsObject) {
      writeln("$methodName: function($argumentString)");
      bodyEmitter();
      writeln(",");
    } else {
      String className = classIdToName(classId);
      String proto = "$className.prototype";
      writeln("$proto.$methodName = function($argumentString)");
      bodyEmitter();
    }
  }

  /// Returns the methods object, if we use an object.
  void emitMethods(int classId) {
    List<int> methodIds = [];
    int nbGenericMethods = nbMethodsPerClass;
    if (useMethodsObject) {
      writeln("$methodsObjectName = {");
    }
    if (shouldEmitCallAllMethods) nbGenericMethods--;
    for (int j = 0; j < nbGenericMethods; j++) {
      String methodName = methodIdToName(j, classId);
      emitMethod(classId, methodName, () => emitMethodBody(j, classId));
      methodIds.add(j);
    }
    if (shouldEmitCallAllMethods) {
      emitMethod(classId, callOtherMethodsName,
          () => emitCallOtherMethodsBody(methodIds, classId));
    }
    if (shouldEmitInstantiatePreviousMethod) {
      emitMethod(classId, instantiatePreviousMethodName,
          () => emitInstantiatePrevious(classId),
          emitArgument: false);
    }
    if (useMethodsObject) {
      writeln("};");
    }
  }

  void emitClass(int classId, int superclassId) {
    String className = classIdToName(classId);
    writeln("function $className() {}");
    switch (prototypeApproach) {
      case PrototypeApproach.objectCreate:
        if (useMethodsObject) {
          emitMethods(classId);
          emitInherit(className, superclassId);
        } else {
          emitInherit(className, superclassId);
          emitMethods(classId);
        }
        break;
      case PrototypeApproach.tmpFunction:
        if (useMethodsObject) {
          emitMethods(classId);
          emitInherit(className, superclassId);
        } else {
          emitInherit(className, superclassId);
          emitMethods(classId);
        }
        break;
      case PrototypeApproach.internalProto:
        emitMethods(classId);
        emitInherit(className, superclassId);
        break;
    }
  }

  String get description {
    String protoApproachDescription;
    switch (prototypeApproach) {
      case PrototypeApproach.objectCreate:
        protoApproachDescription = "objectCreate";
        break;
      case PrototypeApproach.tmpFunction:
        protoApproachDescription = "tmpFunction";
        break;
      case PrototypeApproach.internalProto:
        protoApproachDescription = "internalProto";
        break;
    }
    String inline = shouldInlineInherit ? "inl" : "noInl";
    String objectProto = useMethodsObject ? "obj" : "noObj";
    return "plain_${protoApproachDescription}_${inline}_$objectProto";
  }
}

class Es6ClassGenerator extends JavaScriptClassGenerator {
  Es6ClassGenerator(Config config) : super(config);

  void emitUtilityFunctions() {}

  void emitClass(int classId, int superclassId) {
    String className = classIdToName(classId);
    if (superclassId != null) {
      String superclassName = classIdToName(superclassId);
      buffer.writeln("class $className extends $superclassName {");
    } else {
      buffer.writeln("class $className {");
    }
    List<int> methodIds = [];
    int nbGenericMethods = nbMethodsPerClass;
    if (shouldEmitCallAllMethods) nbGenericMethods--;
    for (int j = 0; j < nbGenericMethods; j++) {
      String methodName = methodIdToName(j, classId);
      writeln("$methodName($argumentName) ");
      emitMethodBody(j, classId);
      methodIds.add(j);
    }
    if (shouldEmitCallAllMethods) {
      writeln("$callOtherMethodsName($argumentName)");
      emitCallOtherMethodsBody(methodIds, classId);
    }
    if (shouldEmitInstantiatePreviousMethod) {
      writeln("$instantiatePreviousMethodName()");
      emitInstantiatePrevious(classId);
    }
    writeln("}");
  }

  String get description => "es6";
}

class DartClassGenerator extends ClassGenerator {
  final bool shouldUseNewEmitter;

  DartClassGenerator(Config config, {this.shouldUseNewEmitter: false})
      : super(config);

  void emitClasses() {
    // TODO(flo): instantiateAndCallPrevious
    for (int i = 0; i < nbClasses; i++) {
      String className = classIdToName(i);
      writeln("class $className {");
      List<int> methodIds = [];
      int nbGenericMethods = nbMethodsPerClass;
      if (shouldEmitCallAllMethods) nbGenericMethods--;
      for (int j = 0; j < nbGenericMethods; j++) {
        String methodName = methodIdToName(j, i);
        writeln("$methodName($argumentName)");
        emitMethodBody(j, i);
        methodIds.add(j);
      }
      if (shouldEmitCallAllMethods) {
        writeln("$callOtherMethodsName($argumentName)");
        emitCallOtherMethodsBody(methodIds, i);
      }
      if (shouldEmitInstantiatePreviousMethod) {
        writeln("$instantiatePreviousMethodName()");
        emitInstantiatePrevious(i);
      }
      writeln("}");
    }
    writeln("main() {");
    if (fakeInstantiateClass != null) {
      String className = classIdToName(fakeInstantiateClass);
      writeln("""
        if (new DateTime.now().millisecondsSinceEpoch == 42) {
          var o = new $className();
          do {
            o.$callOtherMethodsName(99);
            o = o.$instantiatePreviousMethodName();
          } while(o != null);
        }""");
    }
    if (instantiateClassesPercent != null) {
      int targetClassId = ((nbClasses - 1) * instantiateClassesPercent) ~/ 100;
      String targetClassName = classIdToName(targetClassId);
      writeln("""
        var o = new $targetClassName();
        do {
          o = o.$instantiatePreviousMethodName();
        } while(o != null);
      """);
    }
    writeln("}");
  }

  Future<String> generateRawJs(String filePrefix) async {
    String dartFile = writeFile(filePrefix);
    String outFile = buildFileName(filePrefix, "js");
    Map<String, String> env = {};
    if (shouldUseNewEmitter) {
      env["DART_VM_OPTIONS"] = '-Ddart2js.use.new.emitter=true';
    }
    print("compiling");
    print("dart2jsPath: $dart2jsPath");
    ProcessResult result = await Process
        .run(dart2jsPath, [dartFile, "--out=$outFile"], environment: env);
    if (result.exitCode != 0) {
      print("compilation failed");
      print(result.stdout);
      print(result.stderr);
      return null;
    }
    print("compilation done");
    return outFile;
  }

  Future measureDart(String filePrefix, {bool useSnapshot: false}) async {
    String dartFile = writeFile(filePrefix);
    String command = Platform.executable;
    Stopwatch watch = new Stopwatch();
    Directory dir = Directory.systemTemp.createTempSync('snapshot');
    try {
      String measuring = dartFile;
      if (useSnapshot) {
        print("creating snapshot");
        measuring = new File("${dir.path}/measuring.snapshot").path;
        ProcessResult result =
            await Process.run(command, ["--snapshot=$measuring", dartFile]);
        if (result.exitCode != 0) {
          print("snapshot creation failed");
          print(result.stdout);
          print(result.stderr);
          return;
        }
      }
      List<String> args = [measuring];
      print("Running: $command ${args.join(' ')}");
      int nbRuns = 10;
      int sum = 0;
      for (int i = 0; i < nbRuns; i++) {
        watch.reset();
        watch.start();
        ProcessResult result = await Process.run(command, args);
        int elapsedMilliseconds = watch.elapsedMilliseconds;
        if (result.exitCode != 0) {
          print("run failed");
          print(result.stdout);
          print(result.stderr);
          return;
        }
        print("  measured time (including VM startup): $elapsedMilliseconds");
        sum += elapsedMilliseconds;
      }
      if (sum != 0) {
        print("  mean: ${sum ~/ nbRuns}");
      }
    } finally {
      dir.deleteSync(recursive: true);
    }
  }

  String get fileExtension => "dart";
  String get description {
    if (shouldUseNewEmitter) return "dartNew";
    return "dart";
  }
}

main(List<String> arguments) async {
  String filePrefix = arguments.length > 0
      ? arguments.first
      : Directory.systemTemp.uri.resolve("classes").path;

  Config config = new Config(
      nbClasses: 2000,
      nbMethodsPerClass: 20,
      fakeInstantiateClass: -1,
      instantiateClassesPercent: 20,
      shareCommonSuperclass: true,
      sameMethodNames: true,
      shouldPrintInMethod: true,
      nbWhileLoopsInBody: 1,
      shouldWrapProgram: true,
      shouldEmitCallAllMethods: true,
      shouldEmitInstantiatePreviousMethod: true);

  var plain = new PlainJavaScriptClassGenerator(config,
      prototypeApproach: PrototypeApproach.tmpFunction,
      useMethodsObject: false,
      shouldInlineInherit: false);
  var plainProto = new PlainJavaScriptClassGenerator(config,
      prototypeApproach: PrototypeApproach.internalProto,
      useMethodsObject: false,
      shouldInlineInherit: false);
  var plainObjectCreate = new PlainJavaScriptClassGenerator(config,
      prototypeApproach: PrototypeApproach.objectCreate,
      useMethodsObject: false,
      shouldInlineInherit: false);
  var plainProtoInline = new PlainJavaScriptClassGenerator(config,
      prototypeApproach: PrototypeApproach.internalProto,
      useMethodsObject: false,
      shouldInlineInherit: true);
  var plainObjectCreateInline = new PlainJavaScriptClassGenerator(config,
      prototypeApproach: PrototypeApproach.objectCreate,
      useMethodsObject: false,
      shouldInlineInherit: true);
  var plainObj = new PlainJavaScriptClassGenerator(config,
      prototypeApproach: PrototypeApproach.tmpFunction,
      useMethodsObject: true,
      shouldInlineInherit: false);
  var plainProtoObj = new PlainJavaScriptClassGenerator(config,
      prototypeApproach: PrototypeApproach.internalProto,
      useMethodsObject: true,
      shouldInlineInherit: false);
  var plainObjectCreateObj = new PlainJavaScriptClassGenerator(config,
      prototypeApproach: PrototypeApproach.objectCreate,
      useMethodsObject: true,
      shouldInlineInherit: false);
  var plainProtoInlineObj = new PlainJavaScriptClassGenerator(config,
      prototypeApproach: PrototypeApproach.internalProto,
      useMethodsObject: true,
      shouldInlineInherit: true);
  var plainObjectCreateInlineObj = new PlainJavaScriptClassGenerator(config,
      prototypeApproach: PrototypeApproach.objectCreate,
      useMethodsObject: true,
      shouldInlineInherit: true);
  var es6 = new Es6ClassGenerator(config);
  var dart = new DartClassGenerator(config);
  var dartNew = new DartClassGenerator(config, shouldUseNewEmitter: true);

  await plain.measure(filePrefix);
  await plainProto.measure(filePrefix);
  await plainObjectCreate.measure(filePrefix);
  await plainProtoInline.measure(filePrefix);
  await plainObjectCreateInline.measure(filePrefix);
  await plainObj.measure(filePrefix);
  await plainProtoObj.measure(filePrefix);
  await plainObjectCreateObj.measure(filePrefix);
  await plainProtoInlineObj.measure(filePrefix);
  await plainObjectCreateInlineObj.measure(filePrefix);
  await es6.measure(filePrefix);
  await dartNew.measure(filePrefix);
  await dart.measure(filePrefix);
  await dart.measureDart(filePrefix);
  await dart.measureDart(filePrefix, useSnapshot: true);
}
