import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dart2js_info/info.dart';
import 'package:dart2js_info/src/io.dart';
import 'package:dart2js_info/src/util.dart';
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
    final builder = ProgramInfoBuilder(allInfo);
    vm.ProgramInfo programInfo = builder.build(allInfo);
    Map<String, dynamic> treeMap = treemapFromInfo(programInfo);
    var treeMapJson = jsonEncode(treeMap);
    if (outputPath == null) {
      print(treeMapJson);
    } else {
      await File(outputPath).writeAsString(treeMapJson);
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

  /// Mapping between the name of a [Info] object and the corresponding
  /// [vm.ProgramInfoNode] object.
  Map<String, vm.ProgramInfoNode> infoNodesByName = {};

  /// Mapping between the id (aka coverageId) of an [AllInfo] node and the
  /// corresponding [vm.ProgramInfoNode] object.
  final Map<String, vm.ProgramInfoNode> infoNodesById = {};

  /// Mapping between package names and the corresponding [vm.ProgramInfoNode]
  /// objects of [vm.NodeType.packageNode].
  final Map<String, vm.ProgramInfoNode> packageInfoNodes = {};

  /// Mapping between an <unnamed> [LibraryInfo] object and the name of the
  /// corresponding [vm.ProgramInfoNode] object.
  final Map<Info, String> unnamedLibraries = {};

  ProgramInfoBuilder(this.info);

  @override
  vm.ProgramInfoNode visitAll(AllInfo info) {
    outputInfo.add(program.root);
    info.libraries.forEach(makePackage);
    info.packages.forEach(visitPackage);
    info.libraries.forEach(makeLibrary);
    info.libraries.forEach(visitLibrary);
    info.constants.forEach(makeConstant);
    info.constants.forEach(visitConstant);
    return program.root;
  }

  @override
  vm.ProgramInfoNode visitProgram(ProgramInfo info) {
    throw Exception('Not supported for devtools format.');
  }

  @override
  vm.ProgramInfoNode visitPackage(PackageInfo info) {
    info.libraries.forEach(makePackage);
    info.libraries.forEach(makeLibrary);
    info.libraries.forEach(visitLibrary);
    return infoNodesByName[info.name]!;
  }

  @override
  vm.ProgramInfoNode visitLibrary(LibraryInfo info) {
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
    return infoNodesByName[info.name] ??
        infoNodesByName[unnamedLibraries[info]]!;
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
    return infoNodesByName[info.code.first.text!]!;
  }

  @override
  vm.ProgramInfoNode visitTypedef(TypedefInfo info) {
    return infoNodesByName[info.name]!;
  }

  @override
  vm.ProgramInfoNode visitOutput(OutputUnitInfo info) {
    throw Exception("For deferred loading.");
  }

  vm.ProgramInfo build(AllInfo info) {
    visitAll(info);
    return program;
  }

  /// Collect libraries into packages and aggregate their sizes.
  void makePackage(LibraryInfo libraryInfo) {
    String packageName = libraryGroupName(libraryInfo) ?? libraryInfo.name;
    vm.ProgramInfoNode? packageInfoNode = packageInfoNodes[packageName];
    if (packageInfoNode == null) {
      vm.ProgramInfoNode newPackage = program.makeNode(
          name: packageName,
          parent: program.root,
          type: vm.NodeType.packageNode);
      newPackage.size = libraryInfo.size;
      packageInfoNodes[packageName] = newPackage;
      program.root.children[packageName] = newPackage;
      outputInfo.add(newPackage);
      var packageNode = infoNodesByName[newPackage.name];
      assert(packageNode == null, "encountered package with duplicated name");
      infoNodesByName[newPackage.name] = newPackage;
    } else {
      packageInfoNode.size = (packageInfoNode.size ?? 0) + libraryInfo.size;
    }
  }

  void makeLibrary(LibraryInfo libraryInfo) {
    String packageName = libraryGroupName(libraryInfo) ?? libraryInfo.name;
    vm.ProgramInfoNode parentNode = infoNodesByName[packageName]!;
    String libraryName = libraryInfo.name;
    if (libraryName == '<unnamed>') {
      libraryName = longName(libraryInfo, useLibraryUri: true, forId: true);
      unnamedLibraries[libraryInfo] = libraryName;
    }
    vm.ProgramInfoNode newLibrary = program.makeNode(
        name: libraryName, parent: parentNode, type: vm.NodeType.libraryNode);
    newLibrary.size = libraryInfo.size;
    parentNode.children[newLibrary.name] = newLibrary;
    vm.ProgramInfoNode? libraryNode = infoNodesByName[newLibrary.name];
    assert(libraryNode == null, "encountered library with duplicated name");
    infoNodesByName[newLibrary.name] = newLibrary;
    outputInfo.add(newLibrary);
  }

  void makeFunction(FunctionInfo functionInfo) {
    Info? parent = functionInfo.parent;
    if (parent != null) {
      vm.ProgramInfoNode parentNode;
      if (parent.name == "<unnamed>" &&
          parent.kind == kindFromString('library')) {
        parentNode = infoNodesByName[unnamedLibraries[parent]]!;
      } else {
        parentNode = infoNodesByName[parent.name]!;
      }
      vm.ProgramInfoNode newFunction = program.makeNode(
          name: functionInfo.name,
          parent: parentNode,
          type: vm.NodeType.functionNode);
      newFunction.size = functionInfo.size;
      parentNode.children[newFunction.name] = newFunction;
      vm.ProgramInfoNode? functionNode = infoNodesByName[newFunction.name];
      assert(functionNode == null, "encountered function with duplicated name");
      infoNodesByName[newFunction.name] = newFunction;
      outputInfo.add(newFunction);
    }
  }

  void makeClass(ClassInfo classInfo) {
    Info? parent = classInfo.parent;
    if (parent != null) {
      vm.ProgramInfoNode parentNode;
      if (parent.name == "<unnamed>" &&
          parent.kind == kindFromString('library')) {
        parentNode = infoNodesByName[unnamedLibraries[parent]]!;
      } else {
        parentNode = infoNodesByName[parent.name]!;
      }
      vm.ProgramInfoNode newClass = program.makeNode(
          name: classInfo.name,
          parent: parentNode,
          type: vm.NodeType.classNode);
      newClass.size = classInfo.size;
      parentNode.children[newClass.name] = newClass;
      vm.ProgramInfoNode? classNode = infoNodesByName[newClass.name];
      assert(classNode == null, "encountered class with duplicated name");
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
    if (parent != null) {
      vm.ProgramInfoNode parentNode;
      if (parent.name == "<unnamed>" &&
          parent.kind == kindFromString('library')) {
        parentNode = infoNodesByName[unnamedLibraries[parent]]!;
      } else {
        parentNode = infoNodesByName[parent.name]!;
      }
      vm.ProgramInfoNode newField = program.makeNode(
          name: fieldInfo.name, parent: parentNode, type: vm.NodeType.other);
      newField.size = fieldInfo.size;
      parentNode.children[newField.name] = newField;
      vm.ProgramInfoNode? fieldNode = infoNodesByName[newField.name];
      assert(fieldNode == null, "encountered field with duplicated name");
      infoNodesByName[newField.name] = newField;
      outputInfo.add(newField);
    }
  }

  void makeConstant(ConstantInfo constantInfo) {
    String constantName = constantInfo.code.first.text!;
    vm.ProgramInfoNode newConstant = program.makeNode(
        name: constantName, parent: program.root, type: vm.NodeType.other);
    newConstant.size = constantInfo.size;
    program.root.children[newConstant.name] = newConstant;
    vm.ProgramInfoNode? constantNode = infoNodesByName[newConstant.name];
    assert(constantNode == null, "encountered constant with duplicated name");
    infoNodesByName[newConstant.name] = newConstant;
    outputInfo.add(newConstant);
  }

  void makeTypedef(TypedefInfo typedefInfo) {
    vm.ProgramInfoNode newTypedef = program.makeNode(
        name: typedefInfo.name, parent: program.root, type: vm.NodeType.other);
    newTypedef.size = typedefInfo.size;
    infoNodesByName[newTypedef.name] = newTypedef;
    outputInfo.add(newTypedef);
  }

  void makeClassType(ClassTypeInfo classTypeInfo) {
    Info? parent = classTypeInfo.parent;
    if (parent != null) {
      vm.ProgramInfoNode parentNode;
      if (parent.name == "<unnamed>" &&
          parent.kind == kindFromString('library')) {
        parentNode = infoNodesByName[unnamedLibraries[parent]]!;
      } else {
        parentNode = infoNodesByName[parent.name]!;
      }
      vm.ProgramInfoNode newClassType = program.makeNode(
          name: classTypeInfo.name,
          parent: parentNode,
          type: vm.NodeType.other);
      newClassType.size = classTypeInfo.size;
      vm.ProgramInfoNode? classTypeNode = infoNodesByName[newClassType.name];
      assert(
          classTypeNode == null, "encountered classType with duplicated name");
      infoNodesByName[newClassType.name] = newClassType;
      outputInfo.add(newClassType);
    }
  }

  void makeClosure(ClosureInfo closureInfo) {
    Info? parent = closureInfo.parent;
    if (parent != null) {
      vm.ProgramInfoNode parentNode;
      if (parent.name == "<unnamed>" &&
          parent.kind == kindFromString('library')) {
        parentNode = infoNodesByName[unnamedLibraries[parent]]!;
      } else {
        parentNode = infoNodesByName[parent.name]!;
      }
      vm.ProgramInfoNode newClosure = program.makeNode(
          name: closureInfo.name,
          parent: parentNode,
          // ProgramInfo trees consider closures and functions to both be of the functionNode type.
          type: vm.NodeType.functionNode);
      newClosure.size = closureInfo.size;
      parentNode.children[newClosure.name] = newClosure;
      vm.ProgramInfoNode? closureNode = infoNodesByName[newClosure.name];
      assert(closureNode == null, "encountered closure with duplicated name");
      infoNodesByName[newClosure.name] = newClosure;
      outputInfo.add(newClosure);
    }
  }
}
