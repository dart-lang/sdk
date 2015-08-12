// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * This file contains code to output a description of tasks and their
 * dependencies in ".dot" format.  Prior to running, the user should run "pub
 * get" in the analyzer directory to ensure that a "packages" folder exists.
 *
 * The ".dot" file is output to standard out.  To convert it to a pdf, store it
 * in a file (e.g. "tasks.dot"), and post-process it with
 * "dot tasks.dart -Tpdf -O".
 *
 * TODO(paulberry):
 * - Add general.dart and html.dart for completeness.
 * - Use Graphviz's "record" feature to produce more compact output
 *   (http://www.graphviz.org/content/node-shapes#record)
 * - Produce a warning if a result descriptor is found which isn't the output
 *   of exactly one task.
 * - Convert this tool to use package_config to find the package map.
 */
library task_dependency_graph;

import 'dart:io' hide File;

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/java_io.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/sdk_io.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:path/path.dart' as path;

main() {
  new Driver().run();
}

typedef void ResultDescriptorFinderCallback(PropertyAccessorElement element);

class Driver {
  PhysicalResourceProvider resourceProvider;
  AnalysisContext context;
  InterfaceType resultDescriptorType;
  String rootDir;

  void findResultDescriptors(
      AstNode node, void callback(String descriptorName)) {
    Set<PropertyAccessorElement> resultDescriptors =
        new Set<PropertyAccessorElement>();
    node.accept(new ResultDescriptorFinder(
        resultDescriptorType, resultDescriptors.add));
    for (PropertyAccessorElement resultDescriptor in resultDescriptors) {
      callback(resultDescriptor.name);
    }
  }

  /**
   * Find the root directory of the analyzer package by proceeding
   * upward to the 'tool' dir, and then going up one more directory.
   */
  String findRoot(String pathname) {
    while (path.basename(pathname) != 'tool') {
      String parent = path.dirname(pathname);
      if (parent.length >= pathname.length) {
        throw new Exception("Can't find root directory");
      }
      pathname = parent;
    }
    return path.dirname(pathname);
  }

  CompilationUnit getUnit(Source source) =>
      context.resolveCompilationUnit2(source, source);

  void run() {
    rootDir = findRoot(Platform.script.toFilePath(windows: Platform.isWindows));
    resourceProvider = PhysicalResourceProvider.INSTANCE;
    DartSdk sdk = DirectoryBasedDartSdk.defaultSdk;
    context = AnalysisEngine.instance.createAnalysisContext();
    JavaFile packagesDir = new JavaFile(path.join(rootDir, 'packages'));
    List<UriResolver> uriResolvers = [
      new DartUriResolver(sdk),
      new PackageUriResolver(<JavaFile>[packagesDir]),
      new FileUriResolver()
    ];
    context.sourceFactory = new SourceFactory(uriResolvers);
    Source taskSource =
        setupSource(path.join('lib', 'src', 'task', 'dart.dart'));
    Source modelSource = setupSource(path.join('lib', 'task', 'model.dart'));
    CompilationUnitElement modelElement = getUnit(modelSource).element;
    InterfaceType analysisTaskType = modelElement.getType('AnalysisTask').type;
    DartType dynamicType = context.typeProvider.dynamicType;
    resultDescriptorType = modelElement.getType('ResultDescriptor').type
        .substitute4([dynamicType]);
    CompilationUnit taskUnit = getUnit(taskSource);
    CompilationUnitElement taskUnitElement = taskUnit.element;
    print('digraph G {');
    Set<String> results = new Set<String>();
    for (ClassElement cls in taskUnitElement.types) {
      if (!cls.isAbstract && cls.type.isSubtypeOf(analysisTaskType)) {
        String task = cls.name;
        // TODO(paulberry): node is deprecated.  What am I supposed to do
        // instead?
        findResultDescriptors(cls.getMethod('buildInputs').node,
            (String input) {
          results.add(input);
          print('  $input -> $task');
        });
        findResultDescriptors(cls.getField('DESCRIPTOR').node, (String output) {
          results.add(output);
          print('  $task -> $output');
        });
      }
    }
    for (String result in results) {
      print('  $result [shape=box]');
    }
    print('}');
  }

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
}

class ResultDescriptorFinder extends GeneralizingAstVisitor {
  final InterfaceType resultDescriptorType;
  final ResultDescriptorFinderCallback callback;

  ResultDescriptorFinder(this.resultDescriptorType, this.callback);

  @override
  visitIdentifier(Identifier node) {
    Element element = node.staticElement;
    if (element is PropertyAccessorElement &&
        element.isGetter &&
        element.returnType.isSubtypeOf(resultDescriptorType)) {
      callback(element);
    }
  }
}
