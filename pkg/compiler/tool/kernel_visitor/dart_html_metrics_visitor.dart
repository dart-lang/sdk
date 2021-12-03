// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import "dart:convert";
import "dart:io";
import "package:kernel/kernel.dart";

main(List<String> args) async {
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

  // Save data to file.
  visitor.saveDataToFile("dart2html_metrics.json");
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
    classInfo[currentClass].methods.add(ClassMetricsMethod(
        node.name.text,
        node.containsSuperCalls,
        node.isInstanceMember,
        node.isExternal,
        node.isAbstract,
        node.kind.toString()));
  }

  @override
  void visitClass(Class node) {
    // Dont want to add duplicate info.
    // When mixed, anonymous mixin class generated so we want to ignore.
    if (!node.isAnonymousMixin) {
      currentClass = node.name;
      var metrics = ClassMetrics();

      // Check if class contains native members.
      if (node.annotations.any(_isNativeMarkerAnnotation)) {
        metrics.containsNativeMember = true;
      }

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

      // Check for implemented classes.
      if (node.implementedTypes.length > 0) {
        var implementedTypes =
            node.implementedTypes.map((type) => type.className.asClass.name);
        metrics.implementedTypes = implementedTypes.toList();
      }

      classInfo[currentClass] = metrics;

      super.visitClass(node);
    }
  }

  // Returns List of parsed mixins from superclass name.
  List<String> _filterMixins(String superWithMixins) {
    var start = superWithMixins.indexOf("with") + 4;
    var mixins = superWithMixins.substring(start);
    mixins = mixins.replaceAll(" ", "");

    return mixins.split(",");
  }

  // Recursively searches superclasses, filtering anonymous mixins,
  // and returns parent class name.
  String _getParent(Class node) {
    if (node.isAnonymousMixin) {
      return _getParent(node.superclass);
    }

    return node.name;
  }

  // Returns true if a class Annotation is Native.
  bool _isNativeMarkerAnnotation(Expression annotation) {
    if (annotation is ConstructorInvocation) {
      var type = annotation.constructedType;
      if (type.classNode.name == "Native") {
        return true;
      }
    }
    return false;
  }

  // Passes through the aggregated data and processes,
  // adding child classes and overridden methods from parent.
  void _processData() {
    classInfo.keys.forEach((className) {
      var parentName = classInfo[className].parent;
      if (classInfo[parentName] != null) {
        classInfo[parentName].inheritedBy.add(className);

        var notOverridden = <String>[];
        var parentMethods = classInfo[parentName].methods.map((m) => m.name);
        var classMethods = classInfo[className].methods.map((m) => m.name);

        parentMethods.forEach((method) =>
            {if (!classMethods.contains(method)) notOverridden.add(method)});

        // Update Method Info.
        classInfo[className].notOverriddenMethods = notOverridden;
      }
    });
  }

  // Saves the data to file.
  void saveDataToFile(String filename) {
    var formatted = jsonFormat(classInfo);

    File(filename).writeAsStringSync(formatted);
  }

  // Converts the passed Map to a pretty print JSON string.
  String jsonFormat(Map<String, ClassMetrics> info) {
    JsonEncoder encoder = new JsonEncoder.withIndent("  ");
    return encoder.convert(info);
  }
}

/// Tracks info compiled for a class.
class ClassMetrics {
  List<ClassMetricsMethod> methods;
  List<String> mixins;
  List<String> implementedTypes;
  List<String> notOverriddenMethods;
  List<String> inheritedBy;
  String parent;
  bool mixed;
  bool containsNativeMember;

  ClassMetrics(
      {this.mixed = false,
      this.containsNativeMember = false,
      this.parent,
      methods,
      mixins,
      notOverridden,
      implementedTypes,
      inheritedBy}) {
    this.methods = methods ?? [];
    this.mixins = mixins ?? [];
    this.notOverriddenMethods = notOverridden ?? [];
    this.implementedTypes = implementedTypes ?? [];
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
      "containsNativeMember": containsNativeMember,
      "notOverriddenMethods": notOverriddenMethods,
      "implementedTypes": implementedTypes
    };
  }
}

/// Tracks info related to a specific method.
class ClassMetricsMethod {
  String name;
  String methodKind;
  bool invokesSuper;
  bool isInstanceMember;
  bool isExternal;
  bool isAbstract;

  ClassMetricsMethod(this.name,
      [this.invokesSuper = false,
      this.isInstanceMember = false,
      this.isExternal = false,
      this.isAbstract = false,
      this.methodKind = ""]);

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "invokesSuper": invokesSuper,
      "isInstanceMember": isInstanceMember,
      "isExternal": isExternal,
      "isAbstract": isAbstract,
      "methodKind": methodKind
    };
  }
}
