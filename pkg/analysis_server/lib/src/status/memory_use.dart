// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analysis_server.src.status.memory_use;

import 'dart:collection';

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:analyzer/src/context/cache.dart';
import 'package:analyzer/src/context/context.dart' show AnalysisContextImpl;
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/task/dart.dart';
import 'package:analyzer/task/model.dart';

/**
 * A visitor that will count the number of instances of each type of AST node.
 */
class AstNodeCounter extends UnifyingAstVisitor<Null> {
  /**
   * A table mapping the types of the AST nodes to the number of instances
   * visited.
   */
  final Map<Type, int> nodeCounts;

  /**
   * Initialize a newly created counter to increment the counts in the given map
   * of [nodeCounts].
   */
  AstNodeCounter(this.nodeCounts);

  @override
  visitNode(AstNode node) {
    Type type = node.runtimeType;
    int count = nodeCounts[type] ?? 0;
    nodeCounts[type] = count + 1;
    super.visitNode(node);
  }
}

/**
 * A visitor that will count the number of instances of each type of element.
 */
class ElementCounter extends GeneralizingElementVisitor<Null> {
  /**
   * A table mapping the types of the elements to the number of instances
   * visited.
   */
  final Map<Type, int> elementCounts;

  /**
   * A table mapping the types of the AST nodes to the number of instances
   * visited.
   */
  final Map<Type, int> nodeCounts;

  /**
   * Initialize a newly created counter to increment the counts in the given map
   * of [elementCounts].
   */
  ElementCounter(this.elementCounts, this.nodeCounts);

  @override
  visitConstructorElement(ConstructorElement element) {
    if (element is ConstructorElementImpl) {
      List<ConstructorInitializer> initializers = element.constantInitializers;
      if (initializers != null) {
        initializers.forEach((ConstructorInitializer initializer) {
          _countNodes(initializer);
        });
      }
    }
    visitElement(element);
  }

  @override
  visitElement(Element element) {
    Type type = element.runtimeType;
    int count = elementCounts[type] ?? 0;
    elementCounts[type] = count + 1;
    element.metadata.forEach((ElementAnnotation annotation) {
      if (annotation is ElementAnnotationImpl) {
        _countNodes(annotation.annotationAst);
      }
    });
    super.visitElement(element);
  }

  visitFieldElement(FieldElement element) {
    if (element is ConstVariableElement) {
      _countInitializer(element as ConstVariableElement);
    }
    visitElement(element);
  }

  visitLocalVariableElement(LocalVariableElement element) {
    if (element is ConstVariableElement) {
      _countInitializer(element as ConstVariableElement);
    }
    visitElement(element);
  }

  visitParameterElement(ParameterElement element) {
    if (element is ConstVariableElement) {
      _countInitializer(element as ConstVariableElement);
    }
    visitElement(element);
  }

  visitTopLevelVariableElement(TopLevelVariableElement element) {
    if (element is ConstVariableElement) {
      _countInitializer(element as ConstVariableElement);
    }
    visitElement(element);
  }

  void _countInitializer(ConstVariableElement element) {
    _countNodes(element.constantInitializer);
  }

  void _countNodes(AstNode node) {
    if (node != null) {
      node.accept(new AstNodeCounter(nodeCounts));
    }
  }
}

/**
 * A set used when the number of instances of some type is too large to be kept.
 */
class InfiniteSet implements Set {
  /**
   * The unique instance of this class.
   */
  static final InfiniteSet instance = new InfiniteSet();

  @override
  int get length => -1;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw new UnsupportedError('Do not use instances of InfiniteSet');
  }
}

/**
 * Computes memory usage data by traversing the data structures reachable from
 * an analysis server.
 */
class MemoryUseData {
  /**
   * The maximum size of an instance set.
   */
  static const int maxInstanceSetSize = 1000000;

  /**
   * A table mapping classes to instances of the class.
   */
  Map<Type, Set> instances = new HashMap<Type, Set>();

  /**
   * A set of all the library specific units, using equality rather than
   * identity in order to determine whether re-using equal instances would save
   * significant space.
   */
  Set<LibrarySpecificUnit> uniqueLSUs = new HashSet<LibrarySpecificUnit>();

  /**
   * A set of all the targeted results, using equality rather than identity in
   * order to determine whether re-using equal instances would save significant
   * space.
   */
  Set<TargetedResult> uniqueTargetedResults = new HashSet<TargetedResult>();

  /**
   * A table mapping the types of AST nodes to the number of instances being
   * held directly (as values in the cache).
   */
  Map<Type, int> directNodeCounts = new HashMap<Type, int>();

  /**
   * A table mapping the types of AST nodes to the number of instances being
   * held indirectly (such as nodes reachable from element models).
   */
  Map<Type, int> indirectNodeCounts = new HashMap<Type, int>();

  /**
   * A table mapping the types of the elements to the number of instances being
   * held directly (as values in the cache).
   */
  final Map<Type, int> elementCounts = new HashMap<Type, int>();

  /**
   * Initialize a newly created instance.
   */
  MemoryUseData();

  /**
   * Traverse an analysis [server] to compute memory usage data.
   */
  void processAnalysisServer(AnalysisServer server) {
    _recordInstance(server);
    Iterable<AnalysisContext> contexts = server.analysisContexts;
    for (AnalysisContextImpl context in contexts) {
      _processAnalysisContext(context);
    }
    DartSdkManager manager = server.sdkManager;
    List<SdkDescription> descriptors = manager.sdkDescriptors;
    for (SdkDescription descriptor in descriptors) {
      _processAnalysisContext(manager.getSdk(descriptor, () => null).context);
    }
  }

  void _processAnalysisContext(AnalysisContextImpl context) {
    _recordInstance(context);
    _recordInstance(context.analysisCache);
    Map<AnalysisTarget, CacheEntry> map =
        context.privateAnalysisCachePartition.entryMap;
    map.forEach((AnalysisTarget target, CacheEntry entry) {
      _processAnalysisTarget(target);
      _processCacheEntry(entry);
    });
  }

  void _processAnalysisTarget(AnalysisTarget target) {
    _recordInstance(target);
  }

  void _processCacheEntry(CacheEntry entry) {
    _recordInstance(entry);
    List<ResultDescriptor> descriptors = entry.nonInvalidResults;
    for (ResultDescriptor descriptor in descriptors) {
      _recordInstance(descriptor);
      _processResultData(entry.getResultDataOrNull(descriptor));
    }
  }

  void _processResultData(ResultData resultData) {
    _recordInstance(resultData);
    if (resultData != null) {
      _recordInstance(resultData.state);
      _recordInstance(resultData.value, onFirstOccurrence: (Object object) {
        if (object is AstNode) {
          object.accept(new AstNodeCounter(directNodeCounts));
        } else if (object is Element) {
          object.accept(new ElementCounter(elementCounts, indirectNodeCounts));
        }
      });
      resultData.dependedOnResults.forEach(_processTargetedResult);
      resultData.dependentResults.forEach(_processTargetedResult);
    }
  }

  void _processTargetedResult(TargetedResult result) {
    _recordInstance(result);
    uniqueTargetedResults.add(result);
    _recordInstance(result.target);
    _recordInstance(result.result);
  }

  /**
   * Record the given [instance] that was found. If this is the first time that
   * the instance has been found, execute the [onFirstOccurrence] function.
   *
   * Note that instances will not be recorded if there are more than
   * [maxInstanceSetSize] instances of the same type, and that the
   * [onFirstOccurrence] function will not be executed if the instance is not
   * recorded.
   */
  void _recordInstance(Object instance,
      {void onFirstOccurrence(Object object)}) {
    Type type = instance.runtimeType;
    Set instanceSet = instances.putIfAbsent(type, () => new HashSet.identity());
    if (instanceSet != InfiniteSet.instance) {
      if (instanceSet.add(instance) && onFirstOccurrence != null) {
        onFirstOccurrence(instance);
      }
      if (instanceSet.length >= maxInstanceSetSize) {
        instances[type] = InfiniteSet.instance;
      }
    }
    if (instance is LibrarySpecificUnit) {
      uniqueLSUs.add(instance);
    }
  }
}
