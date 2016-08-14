// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/summary/base.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/link.dart';
import 'package:analyzer/src/summary/package_bundle_reader.dart';

/**
 * Collect the inferred types from all the summary files listed in [args] and
 * print them in alphabetical order.
 */
main(List<String> args) {
  SummaryDataStore summaryDataStore = new SummaryDataStore(args);
  InferredTypeCollector collector = new InferredTypeCollector(
      (String uri) => summaryDataStore.linkedMap[uri],
      (String uri) => summaryDataStore.unlinkedMap[uri]);
  collector.visitSummaryDataStore(summaryDataStore);
  collector.dumpCollectedTypes();
}

/**
 * Visitor class that visits the contents of a summary file and collects the
 * inferred types in it.
 */
class InferredTypeCollector {
  UnlinkedUnit unlinkedUnit;
  LinkedUnit linkedUnit;
  CompilationUnitElementForLink unitForLink;
  final Map<String, String> inferredTypes = <String, String>{};
  List<String> typeParamsInScope = <String>[];
  final Linker _linker;

  InferredTypeCollector(
      GetDependencyCallback getDependency, GetUnitCallback getUnit)
      : _linker = new Linker({}, getDependency, getUnit, true);

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
      // As a temporary measure, prevent recursion into the variable's
      // initializer, since AST-based type inference doesn't infer its type
      // correctly yet.  TODO(paulberry): fix.
      properties.remove('initializer');
    } else if (obj is UnlinkedExecutable) {
      collectInferredType(obj.inferredReturnTypeSlot, path);
      // As a temporary measure, prevent recursion into the executable's local
      // variables and local functions, since AST-based type inference doesn't
      // infer locals correctly yet.  TODO(paulberry): fix if necessary.
      properties.remove('localFunctions');
      properties.remove('localVariables');
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
    print('Collected types (${inferredTypes.length}):');
    List<String> paths = inferredTypes.keys.toList();
    paths.sort();
    for (String path in paths) {
      print('$path -> ${inferredTypes[path]}');
    }
  }

  /**
   * Format the given [type] as a string.  Unlike the type's [toString] method,
   * this formats types using their complete URI to avoid ambiguity.
   */
  String formatDartType(DartType type) {
    if (type is FunctionType) {
      List<String> argStrings =
          type.normalParameterTypes.map(formatDartType).toList();
      List<DartType> optionalParameterTypes = type.optionalParameterTypes;
      if (optionalParameterTypes.isNotEmpty) {
        List<String> optionalArgStrings =
            optionalParameterTypes.map(formatDartType).toList();
        argStrings.add('[${optionalArgStrings.join(', ')}]');
      }
      Map<String, DartType> namedParameterTypes = type.namedParameterTypes;
      if (namedParameterTypes.isNotEmpty) {
        List<String> namedArgStrings = <String>[];
        namedParameterTypes.forEach((String name, DartType type) {
          namedArgStrings.add('$name: ${formatDartType(type)}');
        });
        argStrings.add('{${namedArgStrings.join(', ')}}');
      }
      return '(${argStrings.join(', ')}) → ${formatDartType(type.returnType)}';
    } else if (type is InterfaceType) {
      if (type.typeArguments.isNotEmpty) {
        // TODO(paulberry): implement.
        throw new UnimplementedError('type args');
      }
      return formatElement(type.element);
    } else if (type is DynamicTypeImpl) {
      return type.toString();
    } else {
      // TODO(paulberry): implement.
      throw new UnimplementedError(
          "Don't know how to format type of type ${type.runtimeType}");
    }
  }

  /**
   * Format the given [element] as a string, assuming it represents a type.
   * Unlike the element's [toString] method, this formats elements using their
   * complete URI to avoid ambiguity.
   */
  String formatElement(Element element) {
    if (element is ClassElementForLink_Class ||
        element is MethodElementForLink ||
        element is ClassElementForLink_Enum ||
        element is SpecialTypeElementForLink ||
        element is FunctionTypeAliasElementForLink ||
        element is TopLevelFunctionElementForLink) {
      return element.toString();
    } else if (element is FunctionElementForLink_Local_NonSynthetic) {
      return formatDartType(element.type);
    } else if (element is UndefinedElementForLink) {
      return '???';
    } else {
      throw new UnimplementedError(
          "Don't know how to format reference of type ${element.runtimeType}");
    }
  }

  /**
   * Interpret the given [param] as a parameter in a synthetic typedef, and
   * format it as a string.
   */
  String formatParam(UnlinkedParam param) {
    if (param.isFunctionTyped) {
      // TODO(paulberry): fix this case.
      return 'BAD(${JSON.encode(param)})';
    }
    String result;
    if (param.type != null) {
      result = '${formatType(param.type)} ${param.name}';
    } else {
      result = param.name;
    }
    if (param.kind == UnlinkedParamKind.named) {
      result = '{$result}';
    } else if (param.kind == UnlinkedParamKind.positional) {
      result = '[$result]';
    }
    return result;
  }

  /**
   * Convert the reference with index [index] into a string.  If [typeOf] is
   * `true`, the reference is being used in the context of naming a type, so
   * if the entity being referenced is not a type, it will be enclosed in
   * `typeof()` for clarity.
   */
  String formatReference(int index, {bool typeOf: false}) {
    ReferenceableElementForLink element = unitForLink.resolveRef(index);
    return formatElement(element);
  }

  /**
   * Interpret the given [entityRef] as a reference to a type, and format it as
   * a string.
   */
  String formatType(EntityRef entityRef) {
    List<int> implicitFunctionTypeIndices =
        entityRef.implicitFunctionTypeIndices;
    if (entityRef.syntheticReturnType != null) {
      String params = entityRef.syntheticParams.map(formatParam).join(', ');
      String retType = formatType(entityRef.syntheticReturnType);
      return '($params) -> $retType';
    }
    if (entityRef.paramReference != 0) {
      return typeParamsInScope[
          typeParamsInScope.length - entityRef.paramReference];
    }
    String result = formatReference(entityRef.reference, typeOf: true);
    List<EntityRef> typeArguments = entityRef.typeArguments.toList();
    while (typeArguments.isNotEmpty && isDynamic(typeArguments.last)) {
      typeArguments.removeLast();
    }
    if (typeArguments.isNotEmpty) {
      result += '<${typeArguments.map(formatType).join(', ')}>';
    }
    if (implicitFunctionTypeIndices.isNotEmpty) {
      result =
          'parameterOf($result, ${implicitFunctionTypeIndices.join(', ')})';
    }
    return result;
  }

  /**
   * Determine if the given [entityRef] represents the pseudo-type `dynamic`.
   */
  bool isDynamic(EntityRef entityRef) {
    if (entityRef.syntheticReturnType != null ||
        entityRef.paramReference != 0) {
      return false;
    }
    return formatReference(entityRef.reference, typeOf: true) == 'dynamic';
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
   * Collect all the inferred types contained in [summaryDataStore].
   */
  void visitSummaryDataStore(SummaryDataStore summaryDataStore) {
    // Figure out which unlinked units are a part of another library so we won't
    // visit them redundantly.
    Set<String> partOfUris = new Set<String>();
    summaryDataStore.unlinkedMap
        .forEach((String unitUriString, UnlinkedUnit unlinkedUnit) {
      Uri unitUri = Uri.parse(unitUriString);
      for (String relativePartUriString in unlinkedUnit.publicNamespace.parts) {
        partOfUris.add(
            resolveRelativeUri(unitUri, Uri.parse(relativePartUriString))
                .toString());
      }
    });
    summaryDataStore.linkedMap
        .forEach((String libraryUriString, LinkedLibrary linkedLibrary) {
      if (partOfUris.contains(libraryUriString)) {
        return;
      }
      if (libraryUriString.startsWith('dart:')) {
        // Don't bother dumping inferred types from the SDK.
        return;
      }
      Uri libraryUri = Uri.parse(libraryUriString);
      UnlinkedUnit definingUnlinkedUnit =
          summaryDataStore.unlinkedMap[libraryUriString];
      if (definingUnlinkedUnit != null) {
        visitUnit(
            definingUnlinkedUnit, linkedLibrary.units[0], libraryUriString, 0);
        for (int i = 0;
            i < definingUnlinkedUnit.publicNamespace.parts.length;
            i++) {
          Uri relativePartUri =
              Uri.parse(definingUnlinkedUnit.publicNamespace.parts[i]);
          String unitUriString =
              resolveRelativeUri(libraryUri, relativePartUri).toString();
          UnlinkedUnit unlinkedUnit =
              summaryDataStore.unlinkedMap[unitUriString];
          if (unlinkedUnit != null) {
            visitUnit(unlinkedUnit, linkedLibrary.units[i + 1],
                libraryUriString, i + 1);
          }
        }
      }
    });
  }

  /**
   * Collect all the inferred types contained in the compilation unit described
   * by [unlinkedUnit] and [linkedUnit], which has URI [libraryUriString].
   */
  void visitUnit(UnlinkedUnit unlinkedUnit, LinkedUnit linkedUnit,
      String libraryUriString, int unitNum) {
    this.unlinkedUnit = unlinkedUnit;
    this.linkedUnit = linkedUnit;
    this.unitForLink =
        _linker.getLibrary(Uri.parse(libraryUriString)).units[unitNum];
    visit(unlinkedUnit, unlinkedUnit.toMap(), libraryUriString);
    this.unlinkedUnit = null;
    this.linkedUnit = null;
    this.unitForLink = null;
  }
}
