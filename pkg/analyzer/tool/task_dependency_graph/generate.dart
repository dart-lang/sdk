// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * This file contains code to output a description of tasks and their
 * dependencies in ".dot" format.  Prior to running, the user should run "pub
 * get" in the analyzer directory to ensure that a "packages" folder exists.
 *
 * TODO(paulberry):
 * - Add general.dart and html.dart for completeness.
 * - Use Graphviz's "record" feature to produce more compact output
 *   (http://www.graphviz.org/content/node-shapes#record)
 * - Produce a warning if a result descriptor is found which isn't the output
 *   of exactly one task.
 * - Convert this tool to use package_config to find the package map.
 */
library analyzer.tool.task_dependency_graph.generate;

import 'dart:io' hide File;
import 'dart:io' as io;

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/codegen/tools.dart';
import 'package:analyzer/src/generated/constant.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/java_io.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/sdk_io.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:path/path.dart' as path;
import 'package:path/path.dart';

/**
 * Generate the target .dot file.
 */
main() {
  String script = Platform.script.toFilePath(windows: Platform.isWindows);
  String pkgPath = normalize(join(dirname(script), '..', '..'));
  GeneratedContent.generateAll(pkgPath, <GeneratedContent>[target]);
}

final GeneratedFile target = new GeneratedFile(
    'tool/task_dependency_graph/tasks.dot',
    (String pkgPath) => new Driver(pkgPath).generateFileContents());

typedef void GetterFinderCallback(PropertyAccessorElement element);

class Driver {
  PhysicalResourceProvider resourceProvider;
  AnalysisContext context;
  InterfaceType resultDescriptorType;
  InterfaceType listOfResultDescriptorType;
  ClassElement enginePluginClass;
  CompilationUnitElement taskUnitElement;
  InterfaceType extensionPointIdType;
  final String rootDir;

  Driver(String pkgPath) : rootDir = new Directory(pkgPath).absolute.path;

  /**
   * Get an [io.File] object corresponding to the file in which the generated
   * graph should be output.
   */
  io.File get file => new io.File(
      path.join(rootDir, 'tool', 'task_dependency_graph', 'tasks.dot'));

  /**
   * Starting at [node], find all calls to registerExtension() which refer to
   * the given [extensionIdVariable], and execute [callback] for the associated
   * result descriptors.
   */
  void findExtensions(AstNode node, TopLevelVariableElement extensionIdVariable,
      void callback(descriptorName)) {
    Set<PropertyAccessorElement> resultDescriptors =
        new Set<PropertyAccessorElement>();
    node.accept(new ExtensionFinder(
        resultDescriptorType, extensionIdVariable, resultDescriptors.add));
    for (PropertyAccessorElement resultDescriptor in resultDescriptors) {
      callback(resultDescriptor.name);
    }
  }

  /**
   * Starting at [node], find all references to a getter of type
   * `List<ResultDescriptor>`, and execute [callback] on the getter names.
   */
  void findResultDescriptorLists(
      AstNode node, void callback(String descriptorListName)) {
    Set<PropertyAccessorElement> resultDescriptorLists =
        new Set<PropertyAccessorElement>();
    node.accept(new GetterFinder(
        listOfResultDescriptorType, resultDescriptorLists.add));
    for (PropertyAccessorElement resultDescriptorList
        in resultDescriptorLists) {
      // We only care about result descriptor lists associated with getters in
      // the engine plugin class.
      if (resultDescriptorList.enclosingElement != enginePluginClass) {
        continue;
      }
      callback(resultDescriptorList.name);
    }
  }

  void findResultDescriptors(
      AstNode node, void callback(String descriptorName)) {
    Set<PropertyAccessorElement> resultDescriptors =
        new Set<PropertyAccessorElement>();
    node.accept(new GetterFinder(resultDescriptorType, resultDescriptors.add));
    for (PropertyAccessorElement resultDescriptor in resultDescriptors) {
      callback(resultDescriptor.name);
    }
  }

  /**
   * Generate the task dependency graph and return it as a [String].
   */
  String generateFileContents() {
    AnalysisEngine.instance.processRequiredPlugins();
    List<String> lines = <String>[];
    resourceProvider = PhysicalResourceProvider.INSTANCE;
    DartSdk sdk = DirectoryBasedDartSdk.defaultSdk;
    context = AnalysisEngine.instance.createAnalysisContext();
    String packageRootPath;
    if (Platform.packageRoot != null) {
      packageRootPath = Uri.parse(Platform.packageRoot).toFilePath();
    } else {
      packageRootPath = path.join(rootDir, 'packages');
    }
    JavaFile packagesDir = new JavaFile(packageRootPath);
    List<UriResolver> uriResolvers = [
      new DartUriResolver(sdk),
      new PackageUriResolver(<JavaFile>[packagesDir]),
      new FileUriResolver()
    ];
    context.sourceFactory = new SourceFactory(uriResolvers);
    Source dartDartSource =
        setupSource(path.join('lib', 'src', 'task', 'dart.dart'));
    Source taskSource = setupSource(path.join('lib', 'plugin', 'task.dart'));
    Source modelSource = setupSource(path.join('lib', 'task', 'model.dart'));
    Source enginePluginSource =
        setupSource(path.join('lib', 'src', 'plugin', 'engine_plugin.dart'));
    CompilationUnitElement modelElement = getUnit(modelSource).element;
    InterfaceType analysisTaskType = modelElement.getType('AnalysisTask').type;
    DartType dynamicType = context.typeProvider.dynamicType;
    resultDescriptorType = modelElement
        .getType('ResultDescriptor')
        .type
        .instantiate([dynamicType]);
    listOfResultDescriptorType =
        context.typeProvider.listType.instantiate([resultDescriptorType]);
    CompilationUnitElement enginePluginUnitElement =
        getUnit(enginePluginSource).element;
    enginePluginClass = enginePluginUnitElement.getType('EnginePlugin');
    extensionPointIdType =
        enginePluginUnitElement.getType('ExtensionPointId').type;
    CompilationUnit dartDartUnit = getUnit(dartDartSource);
    CompilationUnitElement dartDartUnitElement = dartDartUnit.element;
    CompilationUnit taskUnit = getUnit(taskSource);
    taskUnitElement = taskUnit.element;
    Set<String> results = new Set<String>();
    Set<String> resultLists = new Set<String>();
    for (ClassElement cls in dartDartUnitElement.types) {
      if (!cls.isAbstract && cls.type.isSubtypeOf(analysisTaskType)) {
        String task = cls.name;
        AstNode buildInputsAst = cls.getMethod('buildInputs').computeNode();
        findResultDescriptors(buildInputsAst, (String input) {
          results.add(input);
          lines.add('  $input -> $task');
        });
        findResultDescriptorLists(buildInputsAst, (String input) {
          resultLists.add(input);
          lines.add('  $input -> $task');
        });
        findResultDescriptors(cls.getField('DESCRIPTOR').computeNode(),
            (String out) {
          results.add(out);
          lines.add('  $task -> $out');
        });
      }
    }
    AstNode enginePluginAst = enginePluginUnitElement.computeNode();
    for (String resultList in resultLists) {
      lines.add('  $resultList [shape=hexagon]');
      TopLevelVariableElement extensionIdVariable = _getExtensionId(resultList);
      findExtensions(enginePluginAst, extensionIdVariable, (String extension) {
        results.add(extension);
        lines.add('  $extension -> $resultList');
      });
    }
    for (String result in results) {
      lines.add('  $result [shape=box]');
    }
    lines.sort();
    return '''
// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This file has been automatically generated.  Please do not edit it manually.
// To regenerate the file, use the script
// "pkg/analyzer/tool/task_dependency_graph/generate.dart".
//
// To render this graph using Graphviz (www.graphviz.org) use the command:
// "dot tasks.dot -Tpdf -O".
digraph G {
${lines.join('\n')}
}
''';
  }

  CompilationUnit getUnit(Source source) =>
      context.resolveCompilationUnit2(source, source);

  Source setupSource(String filename) {
    String filePath = path.join(rootDir, filename);
    File file = resourceProvider.getResource(filePath);
    Source source = file.createSource();
    Uri restoredUri = context.sourceFactory.restoreUri(source);
    if (restoredUri != null) {
      source = file.createSource(restoredUri);
    }
    ChangeSet changeSet = new ChangeSet();
    changeSet.addedSource(source);
    context.applyChanges(changeSet);
    return source;
  }

  /**
   * Find the result list getter having name [resultListGetterName] in the
   * [EnginePlugin] class, and use the [ExtensionPointId] annotation on that
   * getter to find the associated [TopLevelVariableElement] which can be used
   * to register extensions for that getter.
   */
  TopLevelVariableElement _getExtensionId(String resultListGetterName) {
    PropertyAccessorElement getter =
        enginePluginClass.getGetter(resultListGetterName);
    for (ElementAnnotation annotation in getter.metadata) {
      DartObjectImpl annotationValue = annotation.constantValue;
      if (annotationValue.type.isSubtypeOf(extensionPointIdType)) {
        String extensionPointId =
            annotationValue.fields['extensionPointId'].toStringValue();
        for (TopLevelVariableElement variable
            in taskUnitElement.topLevelVariables) {
          if (variable.name == extensionPointId) {
            return variable;
          }
        }
      }
    }
    throw new Exception(
        'Could not find extension ID corresponding to $resultListGetterName');
  }
}

/**
 * Visitor that finds calls that register extension points.  Specifically, we
 * look for calls of the form `method(extensionIdVariable, resultDescriptor)`,
 * where `resultDescriptor` has type [resultDescriptorType], and we pass the
 * corresponding result descriptor names to [callback].
 */
class ExtensionFinder extends GeneralizingAstVisitor {
  final InterfaceType resultDescriptorType;
  final TopLevelVariableElement extensionIdVariable;
  final GetterFinderCallback callback;

  ExtensionFinder(
      this.resultDescriptorType, this.extensionIdVariable, this.callback);

  @override
  visitIdentifier(Identifier node) {
    Element element = node.staticElement;
    if (element is PropertyAccessorElement &&
        element.isGetter &&
        element.variable == extensionIdVariable) {
      AstNode parent = node.parent;
      if (parent is ArgumentList &&
          parent.arguments.length == 2 &&
          parent.arguments[0] == node) {
        Expression extension = parent.arguments[1];
        if (extension is Identifier) {
          Element element = extension.staticElement;
          if (element is PropertyAccessorElement &&
              element.isGetter &&
              element.returnType.isSubtypeOf(resultDescriptorType)) {
            callback(element);
            return;
          }
        }
      }
      throw new Exception('Could not decode extension setup: $parent');
    }
  }
}

/**
 * Visitor that finds references to getters having a specific type (or a
 * subtype of that type)
 */
class GetterFinder extends GeneralizingAstVisitor {
  final InterfaceType type;
  final GetterFinderCallback callback;

  GetterFinder(this.type, this.callback);

  @override
  visitIdentifier(Identifier node) {
    Element element = node.staticElement;
    if (element is PropertyAccessorElement &&
        element.isGetter &&
        element.returnType.isSubtypeOf(type)) {
      callback(element);
    }
  }
}
