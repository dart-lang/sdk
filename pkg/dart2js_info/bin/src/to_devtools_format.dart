library dart2js_info.bin.to_devtools_format;

import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dart2js_info/info.dart';
import 'package:dart2js_info/src/io.dart';
import 'package:dart2js_info/src/util.dart' show longName, libraryGroupName;
import 'package:vm_snapshot_analysis/program_info.dart' as vm;
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
    final builder = ProgramInfoBuilder(allInfo);
    vm.ProgramInfo programInfo = builder.build(allInfo);
    Map<String, dynamic> programInfoTree = programInfo.toJson();
    // TODO: convert the programInfo tree to a treemap
    if (outputPath == null) {
      print(jsonEncode(programInfoTree));
    } else {
      await File(outputPath).writeAsString(jsonEncode(programInfoTree));
    }
  }
}

/// Recover [vm.ProgramInfoNode] tree structure from the [AllInfo] profile.
///
/// The [vm.ProgramInfoNode] tree has a similar structure to the [AllInfo] tree
/// except that the root has packages, libraries, constants, and typedefs as
/// immediate children.
class ProgramInfoBuilder extends VMProgramInfoVisitor<vm.ProgramInfoNode> {
  final AllInfo info;

  final program = vm.ProgramInfo();

  final List<vm.ProgramInfoNode> outputInfo = [];

  /// Mapping between the filename of the outputUnit and the [vm.ProgramInfo]
  /// subtree representing a program unit (main or deferred).
  final Map<String, vm.ProgramInfo> outputUnits = {};

  /// Mapping between the name of the library [vm.ProgramInfoNode]
  /// object and its corresponding outputUnit [vm.ProgramInfo] tree.
  final Map<String, vm.ProgramInfo> libraryUnits = {};

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

  /// Mapping between the name of a [Info] object and the corresponding
  /// [vm.ProgramInfoNode] object.
  final Map<String, vm.ProgramInfoNode> infoNodesById = {};

  /// Mapping between the composite name of a package and the corresponding
  /// [vm.ProgramInfoNode] objects of [vm.NodeType.packageNode].
  final Map<String, dynamic> packageInfoNodes = {};

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
    vm.ProgramInfoNode? packageInfoNode = packageInfoNodes[packageName];
    if (packageInfoNode == null) {
      String compositePackageName = compositeName(packageName, outputUnitName);
      vm.ProgramInfoNode newPackage = outputUnit.makeNode(
          name: compositePackageName,
          parent: outputUnit.root,
          type: vm.NodeType.packageNode);
      newPackage.size = libraryInfo.size;
      packageInfoNodes[compositePackageName] = newPackage;
      outputUnit.root.children[compositePackageName] = newPackage;
      outputInfo.add(newPackage);
      var packageNode = infoNodesByName[compositePackageName];
      assert(packageNode == null,
          "encountered package with duplicated name: $compositePackageName");
      infoNodesByName[compositePackageName] = newPackage;
    } else {
      packageInfoNode.size = (packageInfoNode.size ?? 0) + libraryInfo.size;
    }
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
        name: compositeLibraryName,
        parent: parentNode,
        type: vm.NodeType.libraryNode);
    newLibrary.size = libraryInfo.size;
    parentNode.children[newLibrary.name] = newLibrary;
    vm.ProgramInfoNode? libraryNode = infoNodesByName[compositeLibraryName];
    assert(libraryNode == null,
        "encountered library with duplicated name: $compositeLibraryName");
    infoNodesByName[compositeLibraryName] = newLibrary;
    outputInfo.add(newLibrary);
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
      outputInfo.add(newFunction);
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
      outputInfo.add(newClass);
    }
  }

  /// Fields are currently assigned [vm.NodeType.other].
  ///
  /// Note: we might want to create a separate [vm.NodeType.fieldNode] to
  /// differentiate fields from other miscellaneous nodes for constructing
  /// the call graph.
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
      outputInfo.add(newField);
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
    outputInfo.add(newConstant);
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
    outputInfo.add(newTypedef);
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
      outputInfo.add(newClassType);
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
      outputInfo.add(newClosure);
    }
  }

  @override
  vm.ProgramInfoNode visitAll(AllInfo info, String outputUnitName) {
    outputInfo.add(outputUnits[outputUnitName]!.root);
    visitProgram(info.program!);
    for (var package in info.packages) {
      visitPackage(package, outputUnitName);
    }
    for (var library in info.libraries) {
      visitLibrary(library, outputUnitName);
    }
    info.constants.forEach(makeConstant);
    info.constants.forEach(visitConstant);
    return outputUnits[outputUnitName]!.root;
  }

  @override
  vm.ProgramInfoNode visitOutput(OutputUnitInfo info) {
    vm.ProgramInfo? outputUnit = outputUnits[info.filename];
    assert(outputUnit == null, "encountered outputUnit with duplicated name");
    var newUnit = vm.ProgramInfo();
    outputUnits[info.filename] = newUnit;
    outputUnits[info.filename]!.root.size = info.size;
    return outputUnits[info.filename]!.root;
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
  vm.ProgramInfoNode visitLibrary(LibraryInfo info, String outputUnitName) {
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
    return infoNodesByName[compositeName(info.name, outputUnitName)] ??
        infoNodesByName[
            compositeName(unnamedLibraries[info]!, outputUnitName)]!;
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

  vm.ProgramInfo build(AllInfo info) {
    info.outputUnits.forEach(visitOutput);
    for (var outputUnitName in outputUnits.keys) {
      for (var library in info.libraries) {
        makePackage(library, outputUnitName);
        makeLibrary(library, outputUnitName);
      }
    }
    for (var outputUnitName in outputUnits.keys) {
      visitAll(info, outputUnitName);
      program.root.children[outputUnitName] = outputUnits[outputUnitName]!.root;
    }
    return program;
  }
}
