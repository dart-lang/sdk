// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import "dart:io";
import "package:kernel/kernel.dart";
import "package:kernel/ast.dart";

main(List<String> args) {
  // Ensure right args are passed.
  if (args.length < 1) {
    print("usage: ${Platform.script} a.dill");
  }

  // Parse .dill and extract component.
  var dill = args[0];
  var component = loadComponentFromBinary(dill);
  var visitor = MetricsVisitor(["dart:html"]);

  // Visit component.
  component.accept(visitor);

  // Print compiled data.
  print(visitor.classInfo);
}

/// Visits classes in libraries specified by `libraryFilter`
/// and aggregates metrics by class.
class MetricsVisitor extends RecursiveVisitor {
  String currentClass;
  List<String> libraryFilter;
  Map<String, ClassMetrics> classInfo = {};

  MetricsVisitor([filter]) {
    libraryFilter = filter ?? [];
  }

  @override
  void visitLibrary(Library node) {
    // Check if this is a library we want to visit.
    var visit = libraryFilter.isNotEmpty
        ? libraryFilter
            .contains("${node.importUri.scheme}:${node.importUri.path}")
        : true;

    if (visit) {
      super.visitLibrary(node);
    }
  }

  @override
  void visitProcedure(Procedure node) {
    // If this method invokes super, track for class.
    if (node.containsSuperCalls) {
      classInfo[currentClass]
          .methods
          .add(ClassMetricsMethod(node.name.text, true));
    }
  }

  @override
  void visitClass(Class node) {
    currentClass = node.name;
    classInfo[currentClass] = ClassMetrics();

    super.visitClass(node);
  }
}

/// Tracks info compiled for a class.
class ClassMetrics {
  List<ClassMetricsMethod> methods;

  ClassMetrics([methods]) {
    this.methods = methods ?? [];
  }

  bool get invokesSuper {
    if (methods.isNotEmpty) {
      return methods.any((e) => e.invokesSuper);
    }

    return false;
  }

  Map<String, dynamic> toJson() {
    return {"invokesSuper": invokesSuper, "methods": methods};
  }
}

/// Tracks info related to a specific method.
class ClassMetricsMethod {
  String name;
  bool invokesSuper;

  ClassMetricsMethod(this.name, [this.invokesSuper = false]);

  Map<String, dynamic> toJson() {
    return {"name": name, "invokesSuper": invokesSuper};
  }
}
