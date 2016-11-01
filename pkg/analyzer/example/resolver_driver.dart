#!/usr/bin/env dart
// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/file_system.dart' hide File;
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/source/package_map_resolver.dart';
import 'package:analyzer/src/context/builder.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/sdk.dart' show DartSdk;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/source/source_resource.dart';

void main(List<String> args) {
  print('working dir ${new File('.').resolveSymbolicLinksSync()}');

  if (args.length < 2 || args.length > 3) {
    print(_usage);
    exit(0);
  }

  String packageRoot;
  if (args.length == 3) {
    packageRoot = args[2];
  }

  PhysicalResourceProvider resourceProvider = PhysicalResourceProvider.INSTANCE;
  DartSdk sdk = new FolderBasedDartSdk(
      resourceProvider, resourceProvider.getFolder(args[0]));

  var resolvers = [
    new DartUriResolver(sdk),
    new ResourceUriResolver(resourceProvider)
  ];

  if (packageRoot != null) {
    ContextBuilder builder = new ContextBuilder(resourceProvider, null, null);
    resolvers.add(new PackageMapUriResolver(resourceProvider,
        builder.convertPackagesToMap(builder.createPackageMap(packageRoot))));
  }

  AnalysisContext context = AnalysisEngine.instance.createAnalysisContext()
    ..sourceFactory = new SourceFactory(resolvers);

  Source source = new FileSource(resourceProvider.getFile(args[1]));
  ChangeSet changeSet = new ChangeSet()..addedSource(source);
  context.applyChanges(changeSet);
  LibraryElement libElement = context.computeLibraryElement(source);
  print("libElement: $libElement");

  CompilationUnit resolvedUnit =
      context.resolveCompilationUnit(source, libElement);
  var visitor = new _ASTVisitor();
  resolvedUnit.accept(visitor);
}

const _usage =
    'Usage: resolve_driver <path_to_sdk> <file_to_resolve> [<packages_root>]';

class _ASTVisitor extends GeneralizingAstVisitor {
  @override
  visitNode(AstNode node) {
    var lines = <String>['${node.runtimeType} : <"$node">'];
    if (node is SimpleIdentifier) {
      Element element = node.staticElement;
      if (element != null) {
        lines.add('  element: ${element.runtimeType}');
        LibraryElement library = element.library;
        if (library != null) {
          var fullName =
              element.library.definingCompilationUnit.source.fullName;
          lines.add("  from $fullName");
        }
      }
    }
    print(lines.join('\n'));
    return super.visitNode(node);
  }
}
