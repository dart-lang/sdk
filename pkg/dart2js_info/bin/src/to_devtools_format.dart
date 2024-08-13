// ignore_for_file: avoid_dynamic_calls

import 'dart:convert';
import 'dart:io' as io;

import 'package:args/command_runner.dart';
import 'package:dart2js_info/info.dart';
import 'package:dart2js_info/src/io.dart';
import 'package:dart2js_info/src/util.dart' show longName, libraryGroupName;
import 'package:vm_snapshot_analysis/program_info.dart' as vm;
import 'package:vm_snapshot_analysis/treemap.dart';
import 'usage_exception.dart';

/// Command that converts a `--dump-info` JSON output into a format ingested by Devtools.
///
/// Achieves this by converting an [AllInfo] tree into a [vm.ProgramInfo]
/// tree, which is then converted into the format ingested by DevTools via a
/// [TreeMap] intermediary. Initially built to enable display of code size
/// distribution from all info in a dart web app.
class DevtoolsFormatCommand extends Command<void> with PrintUsageException {
  @override
  final String name = "to_devtools_format";
  @override
  final String description =
      "Converts dart2js info into a format accepted by Dart Devtools' "
      "app size analysis panel.";

  DevtoolsFormatCommand() {
    argParser.addOption('out',
        abbr: 'o', help: 'Output treemap.json file (defaults to stdout');
  }

  @override
  void run() async {
    final args = argResults!;
    if (args.rest.isEmpty) {
      usageException('Missing argument: info.data or info.json');
    }
    final outputPath = args['out'];
    final AllInfo allInfo = await infoFromFile(args.rest.first);

    /// Mapping between the filename of the outputUnit and the name
    /// of the corresponding outputUnit root to store in the treemap.
    final Map<String, String> treemapRoots = {};

    /// Mapping between the filename and size of the outputUnit.
    final Map<String, int> treemapSizes = {};
    for (var outputUnit in allInfo.outputUnits) {
      treemapRoots[outputUnit.filename] = outputUnit.name;
      treemapSizes[outputUnit.filename] = outputUnit.size;
    }
    final builder = ProgramInfoBuilder(allInfo);
    final outputUnits = builder.outputUnitMap(allInfo);

    /// For deferred apps, VM Devtools expects an artificial root whose children
    /// are a single main unit followed by each of the deferred units. For non-
    /// deferred apps, VM Devtools expects a root with its children in the main
    /// unit.
    Map<String, dynamic> output = {};
    output['n'] = '';
    output['type'] = "web";

    /// Adds "isDeferred" flag to each child of a treeMap using a helper stack.
    void addDeferredFlag(Map<String, dynamic> treeMap, bool flag) {
      List<dynamic> stack = [];
      treeMap['isDeferred'] = flag;
      stack.add(treeMap);
      while (stack.isNotEmpty) {
        var item = stack.removeLast();
        item['isDeferred'] = flag;
        stack.addAll(item['children'] ?? []);
      }
    }

    if (outputUnits.length == 1) {
      vm.ProgramInfo programInfoTree =
          builder.build(allInfo, outputUnits.keys.first);
      Map<String, dynamic> treeMap = treemapFromInfo(programInfoTree);
      output = treeMap;
      output['n'] = 'Root';
    } else {
      output['n'] = "ArtificialRoot";
      output['children'] = [];
      Map<String, dynamic> mainOutput = {};
      List<dynamic> deferredOutputs = [];
      for (var outputUnitName in outputUnits.keys) {
        vm.ProgramInfo programInfoTree = builder.build(allInfo, outputUnitName);
        Map<String, dynamic> treeMap = treemapFromInfo(programInfoTree);
        treeMap['n'] = treemapRoots[outputUnitName];
        if (treeMap['n'] == 'main') {
          mainOutput.addAll(treeMap);
          // Recursively tag each child in treeMap with "isDeferred" flag
          addDeferredFlag(treeMap, false);
        } else {
          Map<String, dynamic> deferredOutput = {};
          deferredOutput.addAll(treeMap);
          addDeferredFlag(treeMap, true);
          deferredOutputs.add(deferredOutput);
        }
        treeMap['value'] = treemapSizes[outputUnitName];
      }
      output['children'].add(mainOutput);
      output['children'].addAll(deferredOutputs);
    }
    if (outputPath == null) {
      print(jsonEncode(output));
    } else {
      await io.File(outputPath).writeAsString(jsonEncode(output));
    }
  }
}

/// Recover [vm.ProgramInfoNode] tree structure from the [AllInfo] profile.
///
/// The [vm.ProgramInfoNode] tree has a similar structure to the [AllInfo] tree
/// except that the root has packages, libraries, constants, and typedefs as
/// immediate children.
class ProgramInfoBuilder extends VMProgramInfoVisitor<vm.ProgramInfoNode?> {
  final AllInfo info;

  final program = vm.ProgramInfo();

  /// Mapping between the filename of the outputUnit and the [vm.ProgramInfo]
  /// subtree representing a program unit (main or deferred).
  final Map<String, vm.ProgramInfo> outputUnits = {};

  /// Mapping between the name of an [Info] object and the corresponding
  /// [vm.ProgramInfoNode] object.
  ///
  /// For packages and libraries, since their children can be split among
  /// different outputUnits, a composite name is used instead to differentiate
  /// between [vm.ProgramInfoNode] in different outputUnits.
  final Map<String, vm.ProgramInfoNode> infoNodesByName = {};

  /// A unique key composed of the name of an [Info] object and the
  /// filename of the outputUnit.
  String compositeName(String name, String outputUnitName) =>
      "$name/$outputUnitName";

  /// Mapping between the name of an OutputUnitInfo and the OutputUnitInfo object.
  Map<String, OutputUnitInfo> outputUnitInfos = {};

  /// Mapping between the composite name of a package and the corresponding
  /// [PackageInfo] objects.
  final Map<String, PackageInfo> packageInfos = {};

  /// Mapping between an <unnamed> [LibraryInfo] object and the name of the
  /// corresponding [vm.ProgramInfoNode] object.
  final Map<Info, String> unnamedLibraries = {};

  ProgramInfoBuilder(this.info);

  /// Collect libraries into packages and aggregate their sizes.
  void makePackage(LibraryInfo libraryInfo, String outputUnitName) {
    vm.ProgramInfo outputUnit = outputUnits[outputUnitName]!;
    String libraryName = libraryInfo.name;
    if (libraryInfo.name == '<unnamed>') {
      libraryName = longName(libraryInfo, useLibraryUri: true, forId: true);
    }
    String packageName = libraryGroupName(libraryInfo) ?? libraryName;
    String compositePackageName = compositeName(packageName, outputUnitName);
    vm.ProgramInfoNode? packageInfoNode = infoNodesByName[compositePackageName];
    if (packageInfoNode == null) {
      vm.ProgramInfoNode newPackage = outputUnit.makeNode(
          name: packageName,
          parent: outputUnit.root,
          type: vm.NodeType.packageNode);
      newPackage.size = 0;
      outputUnit.root.children[compositePackageName] = newPackage;
      var packageNode = infoNodesByName[compositePackageName];
      assert(packageNode == null,
          "encountered package with duplicated name: $compositePackageName");
      infoNodesByName[compositePackageName] = newPackage;

      /// Add the corresponding [PackageInfo] node in the [AllInfo] tree.
      OutputUnitInfo packageUnit = outputUnitInfos[outputUnitName]!;
      PackageInfo newPackageInfo =
          PackageInfo(packageName, packageUnit, newPackage.size!);
      newPackageInfo.libraries.add(libraryInfo);
      info.packages.add(newPackageInfo);
    }
  }

  /// Aggregates the size of a library [vm.ProgramInfoNode] from the sizes of
  /// its top level children in the same output unit.
  int collectSizesForOutputUnit(
      Iterable<BasicInfo> infos, String outputUnitName) {
    int sizes = 0;
    for (var info in infos) {
      if (info.outputUnit!.filename == outputUnitName) {
        sizes += info.size;
      }
    }
    return sizes;
  }

  void makeLibrary(LibraryInfo libraryInfo, String outputUnitName) {
    vm.ProgramInfo outputUnit = outputUnits[outputUnitName]!;
    String libraryName = libraryInfo.name;
    if (libraryName == '<unnamed>') {
      libraryName = longName(libraryInfo, useLibraryUri: true, forId: true);
      unnamedLibraries[libraryInfo] = libraryName;
    }
    String packageName = libraryGroupName(libraryInfo) ?? libraryName;
    String compositePackageName = compositeName(packageName, outputUnitName);
    vm.ProgramInfoNode parentNode = infoNodesByName[compositePackageName]!;
    String compositeLibraryName = compositeName(libraryName, outputUnitName);
    vm.ProgramInfoNode newLibrary = outputUnit.makeNode(
        name: libraryName, parent: parentNode, type: vm.NodeType.libraryNode);
    newLibrary.size = 0;
    newLibrary.size = (newLibrary.size ?? 0) +
        collectSizesForOutputUnit(
            libraryInfo.topLevelFunctions, outputUnitName) +
        collectSizesForOutputUnit(
            libraryInfo.topLevelVariables, outputUnitName) +
        collectSizesForOutputUnit(libraryInfo.classes, outputUnitName) +
        collectSizesForOutputUnit(libraryInfo.classTypes, outputUnitName) +
        collectSizesForOutputUnit(libraryInfo.typedefs, outputUnitName);
    parentNode.children[newLibrary.name] = newLibrary;
    parentNode.size = (parentNode.size ?? 0) + newLibrary.size!;
    vm.ProgramInfoNode? libraryNode = infoNodesByName[compositeLibraryName];
    assert(libraryNode == null,
        "encountered library with duplicated name: $compositeLibraryName");
    infoNodesByName[compositeLibraryName] = newLibrary;
  }

  void makeFunction(FunctionInfo functionInfo) {
    Info? parent = functionInfo.parent;
    String outputUnitName = functionInfo.outputUnit!.filename;
    vm.ProgramInfo? outputUnit = outputUnits[outputUnitName];
    if (parent != null && outputUnit != null) {
      assert(parent.kind == kindFromString('library'));
      vm.ProgramInfoNode parentNode;
      if (parent.kind == kindFromString('library')) {
        if (parent.name == "<unnamed>") {
          var tempName =
              compositeName(unnamedLibraries[parent]!, outputUnitName);
          parentNode = infoNodesByName[tempName]!;
        } else {
          parentNode =
              infoNodesByName[compositeName(parent.name, outputUnitName)]!;
        }
      } else {
        parentNode = infoNodesByName[parent.name]!;
      }
      vm.ProgramInfoNode newFunction = outputUnit.makeNode(
          name: functionInfo.name,
          parent: parentNode,
          type: vm.NodeType.functionNode);
      newFunction.size = functionInfo.size;
      parentNode.children[newFunction.name] = newFunction;
      vm.ProgramInfoNode? functionNode = infoNodesByName[newFunction.name];
      assert(functionNode == null,
          "encountered function with duplicated name: $newFunction.name");
      infoNodesByName[newFunction.name] = newFunction;
    }
  }

  void makeClass(ClassInfo classInfo) {
    Info? parent = classInfo.parent;
    String outputUnitName = classInfo.outputUnit!.filename;
    vm.ProgramInfo? outputUnit = outputUnits[outputUnitName];
    if (parent != null && outputUnit != null) {
      vm.ProgramInfoNode parentNode;
      if (parent.kind == kindFromString('library')) {
        if (parent.name == "<unnamed>") {
          var tempName =
              compositeName(unnamedLibraries[parent]!, outputUnitName);
          parentNode = infoNodesByName[tempName]!;
        } else {
          parentNode =
              infoNodesByName[compositeName(parent.name, outputUnitName)]!;
        }
      } else {
        parentNode = infoNodesByName[parent.name]!;
      }
      vm.ProgramInfoNode newClass = outputUnit.makeNode(
          name: classInfo.name,
          parent: parentNode,
          type: vm.NodeType.classNode);
      newClass.size = classInfo.size;
      parentNode.children[newClass.name] = newClass;
      vm.ProgramInfoNode? classNode = infoNodesByName[newClass.name];
      assert(classNode == null,
          "encountered class with duplicated name: $newClass.name");
      infoNodesByName[newClass.name] = newClass;
    }
  }

  /// Fields are currently assigned [vm.NodeType.other].
  ///
  /// Note: we might want to create a separate [vm.NodeType.fieldNode] to
  /// differentiate fields from other miscellaneous nodes for constructing
  /// the call graph in the future.
  void makeField(FieldInfo fieldInfo) {
    Info? parent = fieldInfo.parent;
    String outputUnitName = fieldInfo.outputUnit!.filename;
    vm.ProgramInfo? outputUnit = outputUnits[outputUnitName];
    if (parent != null && outputUnit != null) {
      vm.ProgramInfoNode parentNode;
      if (parent.kind == kindFromString('library')) {
        if (parent.name == "<unnamed>") {
          var tempName =
              compositeName(unnamedLibraries[parent]!, outputUnitName);
          parentNode = infoNodesByName[tempName]!;
        } else {
          parentNode =
              infoNodesByName[compositeName(parent.name, outputUnitName)]!;
        }
      } else {
        parentNode = infoNodesByName[parent.name]!;
      }
      vm.ProgramInfoNode newField = outputUnit.makeNode(
          name: fieldInfo.name, parent: parentNode, type: vm.NodeType.other);
      newField.size = fieldInfo.size;
      parentNode.children[newField.name] = newField;
      vm.ProgramInfoNode? fieldNode = infoNodesByName[newField.name];
      assert(fieldNode == null,
          "encountered field with duplicated name: $newField.name");
      infoNodesByName[newField.name] = newField;
    }
  }

  void makeConstant(ConstantInfo constantInfo) {
    String? constantName = constantInfo.code.first.text ??
        "${constantInfo.code.first.start}/${constantInfo.code.first.end}";
    String outputUnitName = constantInfo.outputUnit!.filename;
    vm.ProgramInfo? outputUnit = outputUnits[outputUnitName];
    vm.ProgramInfoNode newConstant = outputUnit!.makeNode(
        name: constantName, parent: outputUnit.root, type: vm.NodeType.other);
    newConstant.size = constantInfo.size;
    outputUnit.root.children[newConstant.name] = newConstant;
    vm.ProgramInfoNode? constantNode = infoNodesByName[newConstant.name];
    assert(constantNode == null,
        "encountered constant with duplicated name: $newConstant.name");
    infoNodesByName[newConstant.name] = newConstant;
  }

  void makeTypedef(TypedefInfo typedefInfo) {
    String outputUnitName = typedefInfo.outputUnit!.filename;
    vm.ProgramInfo? outputUnit = outputUnits[outputUnitName];
    vm.ProgramInfoNode newTypedef = outputUnit!.makeNode(
        name: typedefInfo.name,
        parent: outputUnit.root,
        type: vm.NodeType.other);
    newTypedef.size = typedefInfo.size;
    vm.ProgramInfoNode? typedefNode = infoNodesByName[newTypedef.name];
    assert(typedefNode == null,
        "encountered constant with duplicated name: $newTypedef.name");
  }

  void makeClassType(ClassTypeInfo classTypeInfo) {
    Info? parent = classTypeInfo.parent;
    String outputUnitName = classTypeInfo.outputUnit!.filename;
    vm.ProgramInfo? outputUnit = outputUnits[outputUnitName];
    if (parent != null && outputUnit != null) {
      assert(parent.kind == kindFromString('library'));
      vm.ProgramInfoNode parentNode;
      if (parent.name == "<unnamed>") {
        var tempName = compositeName(unnamedLibraries[parent]!, outputUnitName);
        parentNode = infoNodesByName[tempName]!;
      } else {
        parentNode =
            infoNodesByName[compositeName(parent.name, outputUnitName)]!;
      }
      vm.ProgramInfoNode newClassType = outputUnit.makeNode(
          name: classTypeInfo.name,
          parent: parentNode,
          type: vm.NodeType.other);
      newClassType.size = classTypeInfo.size;
      vm.ProgramInfoNode? classTypeNode = infoNodesByName[newClassType.name];
      assert(classTypeNode == null,
          "encountered classType with duplicated name: $newClassType.name");
      infoNodesByName[newClassType.name] = newClassType;
    }
  }

  void makeClosure(ClosureInfo closureInfo) {
    Info? parent = closureInfo.parent;
    String outputUnitName = closureInfo.outputUnit!.filename;
    vm.ProgramInfo? outputUnit = outputUnits[outputUnitName];
    if (parent != null && outputUnit != null) {
      vm.ProgramInfoNode parentNode;
      if (parent.kind == kindFromString('library')) {
        if (parent.name == "<unnamed>") {
          var tempName =
              compositeName(unnamedLibraries[parent]!, outputUnitName);
          parentNode = infoNodesByName[tempName]!;
        } else {
          parentNode =
              infoNodesByName[compositeName(parent.name, outputUnitName)]!;
        }
      } else {
        parentNode = infoNodesByName[parent.name]!;
      }
      vm.ProgramInfoNode newClosure = outputUnit.makeNode(
          name: closureInfo.name,
          parent: parentNode,
          // ProgramInfo trees consider closures and functions to both be of the functionNode type.
          type: vm.NodeType.functionNode);
      newClosure.size = closureInfo.size;
      parentNode.children[newClosure.name] = newClosure;
      vm.ProgramInfoNode? closureNode = infoNodesByName[newClosure.name];
      assert(closureNode == null,
          "encountered closure with duplicated name: $newClosure.name");
      infoNodesByName[newClosure.name] = newClosure;
    }
  }

  @override
  vm.ProgramInfoNode visitOutput(OutputUnitInfo info) {
    vm.ProgramInfo? outputUnit = outputUnits[info.filename];
    outputUnitInfos[info.filename] = info;
    assert(outputUnit == null, "encountered outputUnit with duplicated name");
    var newUnit = vm.ProgramInfo();
    outputUnits[info.filename] = newUnit;
    outputUnits[info.filename]!.root.size = info.size;
    return outputUnits[info.filename]!.root;
  }

  @override
  vm.ProgramInfoNode visitAll(AllInfo info, String outputUnitName) {
    for (var package in info.packages) {
      visitPackage(package, outputUnitName);
    }
    info.constants.forEach(makeConstant);
    info.constants.forEach(visitConstant);
    return outputUnits[outputUnitName]!.root;
  }

  @override
  vm.ProgramInfoNode visitProgram(ProgramInfo info) {
    program.root.size = info.size;
    return program.root;
  }

  @override
  vm.ProgramInfoNode visitPackage(PackageInfo info, String outputUnitName) {
    for (var library in info.libraries) {
      visitLibrary(library, outputUnitName);
    }
    return infoNodesByName[compositeName(info.name, outputUnitName)]!;
  }

  @override
  vm.ProgramInfoNode? visitLibrary(LibraryInfo info, String outputUnitName) {
    info.topLevelFunctions.forEach(makeFunction);
    info.topLevelFunctions.forEach(visitFunction);
    info.topLevelVariables.forEach(makeField);
    info.topLevelVariables.forEach(visitField);
    info.classes.forEach(makeClass);
    info.classes.forEach(visitClass);
    info.classTypes.forEach(makeClassType);
    info.classTypes.forEach(visitClassType);
    info.typedefs.forEach(makeTypedef);
    info.typedefs.forEach(visitTypedef);
    vm.ProgramInfoNode currentLibrary =
        infoNodesByName[compositeName(info.name, outputUnitName)] ??
            infoNodesByName[
                compositeName(unnamedLibraries[info]!, outputUnitName)]!;
    return currentLibrary;
  }

  @override
  vm.ProgramInfoNode visitClass(ClassInfo info) {
    info.functions.forEach(makeFunction);
    info.functions.forEach(visitFunction);
    info.fields.forEach(makeField);
    info.fields.forEach(visitField);
    return infoNodesByName[info.name]!;
  }

  @override
  vm.ProgramInfoNode visitField(FieldInfo info) {
    info.closures.forEach(makeClosure);
    info.closures.forEach(visitClosure);
    return infoNodesByName[info.name]!;
  }

  @override
  vm.ProgramInfoNode visitFunction(FunctionInfo info) {
    info.closures.forEach(makeClosure);
    info.closures.forEach(visitClosure);
    return infoNodesByName[info.name]!;
  }

  @override
  vm.ProgramInfoNode visitClassType(ClassTypeInfo info) {
    return infoNodesByName[info.name]!;
  }

  @override
  vm.ProgramInfoNode visitClosure(ClosureInfo info) {
    makeFunction(info.function);
    visitFunction(info.function);
    return infoNodesByName[info.name]!;
  }

  @override
  vm.ProgramInfoNode visitConstant(ConstantInfo info) {
    return infoNodesByName[info.code.first.text] ??
        infoNodesByName["${info.code.first.start}/${info.code.first.end}"]!;
  }

  @override
  vm.ProgramInfoNode visitTypedef(TypedefInfo info) {
    return infoNodesByName[info.name]!;
  }

  /// Populate a map of the name of each outputUnit to the [vm.ProgramInfo]
  /// subtree representing each outputUnit.
  Map<String, vm.ProgramInfo> outputUnitMap(AllInfo info) {
    info.outputUnits.forEach(visitOutput);
    for (var outputUnitName in outputUnits.keys) {
      for (var library in info.libraries) {
        makePackage(library, outputUnitName);
        makeLibrary(library, outputUnitName);
      }
    }
    return outputUnits;
  }

  vm.ProgramInfo build(AllInfo info, String outputUnitName) {
    visitAll(info, outputUnitName);
    return outputUnits[outputUnitName]!;
  }
}
