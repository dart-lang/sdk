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
  void visitComponent(Component node) {
    super.visitComponent(node);
    _processData();
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
    // Dont want to add duplicate info.
    // When mixed, anonymous mixin class generated so we want to ignore.
    if (!node.isAnonymousMixin) {
      currentClass = node.name;
      var metrics = ClassMetrics();

      // Check if Mixed.
      if (node.superclass?.isAnonymousMixin ?? false) {
        metrics.mixed = true;
        metrics.mixins = _filterMixins(node.superclass.demangledName);
      }

      // Add parents.
      if (node.superclass != null) {
        var unmangledParent = _getParent(node.superclass);
        metrics.parent = unmangledParent;
      }

      classInfo[currentClass] = metrics;
      super.visitClass(node);
    }
  }

  // Returns List of parsed mixins from superclass name.
  List<String> _filterMixins(String superWithMixins) {
    var start = superWithMixins.indexOf('with') + 4;
    var mixins = superWithMixins.substring(start);
    mixins = mixins.replaceAll(' ', '');

    return mixins.split(',');
  }

  // Recursively searches superclasses, filtering anonymous mixins,
  // and returns parent class name.
  String _getParent(Class node) {
    if (node.isAnonymousMixin) {
      return _getParent(node.superclass);
    }

    return node.name;
  }

  // Passes through the aggregated data and does post processing,
  // adding classes that inherit.
  void _processData() {
    classInfo.keys.forEach((className) {
      var parentName = classInfo[className].parent;

      if (classInfo[parentName] != null) {
        classInfo[parentName].inheritedBy.add(className);
      }
    });
  }
}

/// Tracks info compiled for a class.
class ClassMetrics {
  List<ClassMetricsMethod> methods;
  List<String> mixins;
  List<String> inheritedBy;
  String parent;
  bool mixed;

  ClassMetrics(
      {this.parent, this.mixed = false, mixins, methods, inheritedBy}) {
    this.mixins = mixins ?? [];
    this.methods = methods ?? [];
    this.inheritedBy = inheritedBy ?? [];
  }

  bool get invokesSuper {
    if (methods.isNotEmpty) {
      return methods.any((e) => e.invokesSuper);
    }

    return false;
  }

  Map<String, dynamic> toJson() {
    return {
      "invokesSuper": invokesSuper,
      "methods": methods,
      "mixed": mixed,
      "mixins": mixins,
      "parent": parent,
      "inheritedBy": inheritedBy,
    };
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
