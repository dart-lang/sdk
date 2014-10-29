#!/usr/bin/env dart

// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/generated/java_io.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/sdk.dart' show DartSdk;
import 'package:analyzer/src/generated/sdk_io.dart' show DirectoryBasedDartSdk;
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart';

import 'dart:io';

main(List<String> args) {
  print('working dir ${new File('.').resolveSymbolicLinksSync()}');

  if (args.length != 2) {
    print('Usage: resolve_driver [path_to_sdk] [file_to_resolve]');
    exit(0);
  }

  JavaSystemIO.setProperty("com.google.dart.sdk", args[0]);
  DartSdk sdk = DirectoryBasedDartSdk.defaultSdk;

  AnalysisContext context = AnalysisEngine.instance.createAnalysisContext();
  context.sourceFactory = new SourceFactory([new DartUriResolver(sdk), new FileUriResolver()]);
  Source source = new FileBasedSource.con1(new JavaFile(args[1]));
  //
  ChangeSet changeSet = new ChangeSet();
  changeSet.addedSource(source);
  context.applyChanges(changeSet);
  LibraryElement libElement = context.computeLibraryElement(source);
  print("libElement: $libElement");

  CompilationUnit resolvedUnit = context.resolveCompilationUnit(source, libElement);
  var visitor = new _ASTVisitor();
  resolvedUnit.accept(visitor);
}

class _ASTVisitor extends GeneralizingAstVisitor {
  visitNode(AstNode node) {
    String text = '${node.runtimeType} : <"$node">';
    if (node is SimpleIdentifier) {
      Element element = node.staticElement;
      if (element != null) {
        text += " element: ${element.runtimeType}";
        LibraryElement library = element.library;
        if (library != null) {
          text += " from ${element.library.definingCompilationUnit.source.fullName}";
        }
      }
    }
    print(text);
    return super.visitNode(node);
  }
}

