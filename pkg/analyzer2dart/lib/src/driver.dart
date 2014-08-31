// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer2dart.driver;

import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/java_io.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source_io.dart';

import 'closed_world.dart';
import 'tree_shaker.dart';

/**
 * Top level driver for Analyzer2Dart.
 */
class Driver {
  AnalysisContext context;

  Driver(DartSdk sdk) : context = AnalysisEngine.instance.createAnalysisContext() {
    // Set up the source factory.
    // TODO(paulberry): do we want to use ExplicitPackageUriResolver?
    List<UriResolver> uriResolvers = [
        new FileUriResolver(),
        new DartUriResolver(sdk) /* ,
        new PackageUriResolver(packagesDirectories) */
    ];
    context.sourceFactory = new SourceFactory(uriResolvers);
  }

  /**
   * Compute the closed world that is reachable from an entry point.
   */
  ClosedWorld computeWorld(FunctionElement entryPointElement) {
    TreeShaker treeShaker = new TreeShaker();
    treeShaker.addElement(entryPointElement);
    return treeShaker.shake();
  }

  /**
   * Given a source, resolve it and return its entry point.
   */
  FunctionElement resolveEntryPoint(Source source) {
    // Get the library element associated with the source.
    LibraryElement libraryElement = context.computeLibraryElement(source);

    // Get the resolved AST for main
    FunctionElement entryPointElement = libraryElement.entryPoint;
    if (entryPointElement == null) {
      throw new Exception('No main()!');
    }
    return entryPointElement;
  }

  /**
   * Add the given file as the root of analysis, and return the corresponding
   * source.
   */
  Source setRealRoot(String path) {
    // Tell the analysis server about the root
    ChangeSet changeSet = new ChangeSet();
    JavaFile javaFile = new JavaFile(path);
    Source source = new FileBasedSource.con1(javaFile);
    changeSet.addedSource(source);
    context.applyChanges(changeSet);
    return source;
  }

  /**
   * Add the given file contents as the root of analysis.  For unit testing.
   */
  Source setFakeRoot(String contents) {
    String path = 'root.dart';
    // Tell the analysis server about the root
    ChangeSet changeSet = new ChangeSet();
    JavaFile javaFile = new JavaFile(path);
    Source source = new FileBasedSource.con1(javaFile);
    changeSet.addedSource(source);
    changeSet.changedContent(source, contents);
    context.applyChanges(changeSet);
    return source;
  }
}

