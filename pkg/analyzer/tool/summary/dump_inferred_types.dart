// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/summary/base.dart';
import 'package:analyzer/src/summary/idl.dart';

/**
 * Collect the inferred types from all the summary files listed in [args] and
 * print them in alphabetical order.
 */
main(List<String> args) {
  InferredTypeCollector collector = new InferredTypeCollector();
  for (String arg in args) {
    PackageBundle bundle =
        new PackageBundle.fromBuffer(new File(arg).readAsBytesSync());
    collector.visitPackageBundle(bundle);
  }
  collector.dumpCollectedTypes();
}

/**
 * Visitor class that visits the contents of a summary file and collects the
 * inferred types in it.
 */
class InferredTypeCollector {
  UnlinkedUnit unlinkedUnit;
  LinkedUnit linkedUnit;
  final Map<String, String> inferredTypes = <String, String>{};
  List<String> typeParamsInScope = <String>[];

  /**
   * If an inferred type exists matching the given [slot], record that it is the
   * type of the entity reachable via [path].
   */
  void collectInferredType(int slot, String path) {
    for (EntityRef type in linkedUnit.types) {
      if (type.slot == slot) {
        inferredTypes[path] = formatType(type);
        return;
      }
    }
  }

  /**
   * Collect the inferred type in summary object [obj] (if any), which is
   * reachable via [path].
   *
   * This method may modify [properties] in order to affect how sub-elements
   * are visited.
   */
  void collectInferredTypes(
      SummaryClass obj, Map<String, Object> properties, String path) {
    if (obj is UnlinkedVariable) {
      collectInferredType(obj.inferredTypeSlot, path);
    } else if (obj is UnlinkedExecutable) {
      collectInferredType(obj.inferredReturnTypeSlot, path);
    } else if (obj is UnlinkedParam) {
      collectInferredType(obj.inferredTypeSlot, path);
      // As a temporary measure, prevent recursion into the parameter's
      // initializer, since AST-based type inference doesn't infer its type
      // correctly yet.  TODO(paulberry): fix.
      properties.remove('initializer');
    }
  }

  /**
   * Print out all the inferred types collected so far, in alphabetical order.
   */
  void dumpCollectedTypes() {
    List<String> paths = inferredTypes.keys.toList();
    paths.sort();
    for (String path in paths) {
      print('$path -> ${inferredTypes[path]}');
    }
  }

  /**
   * Convert the reference with index [index] into a string.  If [typeOf] is
   * `true`, the reference is being used in the context of naming a type, so
   * if the entity being referenced is not a type, it will be enclosed in
   * `typeof()` for clarity.
   */
  String formatReference(int index, {bool typeOf: false}) {
    LinkedReference linkedRef = linkedUnit.references[index];
    switch (linkedRef.kind) {
      case ReferenceKind.classOrEnum:
      case ReferenceKind.function:
      case ReferenceKind.propertyAccessor:
      case ReferenceKind.topLevelFunction:
        break;
      default:
        // TODO(paulberry): fix this case.
        return 'BAD(${JSON.encode(linkedRef.toJson())})';
    }
    int containingReference;
    String name;
    if (index < unlinkedUnit.references.length) {
      containingReference = unlinkedUnit.references[index].prefixReference;
      name = unlinkedUnit.references[index].name;
    } else {
      containingReference = linkedRef.containingReference;
      name = linkedRef.name;
    }
    String result;
    if (containingReference != 0) {
      result = '${formatReference(containingReference)}.$name';
    } else {
      result = name;
    }
    if (linkedRef.kind == ReferenceKind.function) {
      assert(name.isEmpty);
      result += 'localFunction[${linkedRef.localIndex}]';
    }
    if (!typeOf || linkedRef.kind == ReferenceKind.classOrEnum) {
      return result;
    } else {
      return 'typeof($result)';
    }
  }

  /**
   * Interpret the given [entityRef] as a reference to a type, and format it as
   * a string.
   */
  String formatType(EntityRef entityRef) {
    if (entityRef.implicitFunctionTypeIndices.isNotEmpty ||
        entityRef.syntheticParams.isNotEmpty ||
        entityRef.syntheticReturnType != null) {
      // TODO(paulberry): fix these cases.
      return 'BAD(${JSON.encode(entityRef.toJson())})';
    }
    if (entityRef.paramReference != 0) {
      return typeParamsInScope[
          typeParamsInScope.length - entityRef.paramReference];
    }
    String result = formatReference(entityRef.reference, typeOf: true);
    if (entityRef.typeArguments.isNotEmpty) {
      result += '<${entityRef.typeArguments.map(formatType).join(', ')}>';
    }
    return result;
  }

  /**
   * Collect all the inferred types contained in [obj], which is reachable via
   * [path].  [properties] is the result of calling `obj.toMap()`, and may be
   * modified before returning.
   */
  void visit(SummaryClass obj, Map<String, Object> properties, String path) {
    List<String> oldTypeParamsInScope = typeParamsInScope;
    Object newTypeParams = properties['typeParameters'];
    if (newTypeParams is List && newTypeParams.isNotEmpty) {
      typeParamsInScope = typeParamsInScope.toList();
      for (Object typeParam in newTypeParams) {
        if (typeParam is UnlinkedTypeParam) {
          typeParamsInScope.add(typeParam.name);
        } else {
          throw new StateError(
              'Unexpected type param type: ${typeParam.runtimeType}');
        }
      }
    }
    collectInferredTypes(obj, properties, path);
    properties.forEach((String key, Object value) {
      if (value is SummaryClass) {
        visit(value, value.toMap(), '$path.$key');
      } else if (value is List) {
        for (int i = 0; i < value.length; i++) {
          Object item = value[i];
          if (item is SummaryClass) {
            Map<String, Object> itemProperties = item.toMap();
            String indexOrName = itemProperties['name'] ?? i.toString();
            visit(item, itemProperties, '$path.$key[$indexOrName]');
          }
        }
      }
    });
    typeParamsInScope = oldTypeParamsInScope;
  }

  /**
   * Collect all the inferred types contained in [bundle].
   */
  void visitPackageBundle(PackageBundle bundle) {
    Map<String, LinkedLibrary> linkedLibraries = <String, LinkedLibrary>{};
    Map<String, UnlinkedUnit> unlinkedUnits = <String, UnlinkedUnit>{};
    for (int i = 0; i < bundle.linkedLibraryUris.length; i++) {
      linkedLibraries[bundle.linkedLibraryUris[i]] = bundle.linkedLibraries[i];
    }
    for (int i = 0; i < bundle.unlinkedUnitUris.length; i++) {
      unlinkedUnits[bundle.unlinkedUnitUris[i]] = bundle.unlinkedUnits[i];
    }
    // Figure out which unlinked units are a part of another library so we won't
    // visit them redundantly.
    Set<String> partOfUris = new Set<String>();
    unlinkedUnits.forEach((String unitUriString, UnlinkedUnit unlinkedUnit) {
      Uri unitUri = Uri.parse(unitUriString);
      for (String relativePartUriString in unlinkedUnit.publicNamespace.parts) {
        partOfUris.add(
            resolveRelativeUri(unitUri, Uri.parse(relativePartUriString))
                .toString());
      }
    });
    linkedLibraries
        .forEach((String libraryUriString, LinkedLibrary linkedLibrary) {
      if (partOfUris.contains(libraryUriString)) {
        return;
      }
      Uri libraryUri = Uri.parse(libraryUriString);
      UnlinkedUnit definingUnlinkedUnit = unlinkedUnits[libraryUriString];
      visitUnit(definingUnlinkedUnit, linkedLibrary.units[0], libraryUriString);
      for (int i = 0;
          i < definingUnlinkedUnit.publicNamespace.parts.length;
          i++) {
        Uri relativePartUri =
            Uri.parse(definingUnlinkedUnit.publicNamespace.parts[i]);
        String unitUriString =
            resolveRelativeUri(libraryUri, relativePartUri).toString();
        visitUnit(unlinkedUnits[unitUriString], linkedLibrary.units[i + 1],
            libraryUriString);
      }
    });
  }

  /**
   * Collect all the inferred types contained in the compilation unit described
   * by [unlinkedUnit] and [linkedUnit], which has URI [libraryUriString].
   */
  void visitUnit(UnlinkedUnit unlinkedUnit, LinkedUnit linkedUnit,
      String libraryUriString) {
    this.unlinkedUnit = unlinkedUnit;
    this.linkedUnit = linkedUnit;
    visit(unlinkedUnit, unlinkedUnit.toMap(), libraryUriString);
    this.unlinkedUnit = null;
    this.linkedUnit = null;
  }
}
