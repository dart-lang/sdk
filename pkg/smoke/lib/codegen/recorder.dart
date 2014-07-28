// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Records accesses to Dart program declarations and generates code that will
/// allow to do the same accesses at runtime using `package:smoke/static.dart`.
/// Internally, this library relies on the `analyzer` to extract data from the
/// program, and then uses [SmokeCodeGenerator] to produce the code needed by
/// the smoke system.
///
/// This library only uses the analyzer to consume data previously produced by
/// running the resolver. This library does not provide any hooks to integrate
/// running the analyzer itself. See `package:code_transformers` to integrate
/// the analyzer into pub transformers.
library smoke.codegen.recorder;

import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'generator.dart';

typedef String ImportUrlResolver(LibraryElement lib);

/// A recorder that tracks how elements are accessed in order to generate code
/// that replicates those accesses with the smoke runtime.
class Recorder {
  /// Underlying code generator.
  SmokeCodeGenerator generator;

  /// Function that provides the import url for a library element. This may
  /// internally use the resolver to resolve the import url.
  ImportUrlResolver importUrlFor;

  Recorder(this.generator, this.importUrlFor);

  /// Stores mixins that have been recorded and associates a type identifier
  /// with them. Mixins don't have an associated identifier in the code, so we
  /// generate a unique identifier for them and use it throughout the code.
  Map<TypeIdentifier, Map<ClassElement, TypeIdentifier>> _mixins = {};

  /// Adds the superclass information of [type] (including intermediate mixins).
  /// This will not generate data for direct subtypes of Object, as that is
  /// considered redundant information.
  void lookupParent(ClassElement type) {
    var parent = type.supertype;
    var mixins = type.mixins;
    if (parent == null && mixins.isEmpty) return; // type is Object
    var baseType = parent.element;
    var baseId = _typeFor(baseType);
    if (mixins.isNotEmpty) {
      _mixins.putIfAbsent(baseId, () => {});
      for (var m in mixins) {
        var mixinType = m.element;
        var mixinId = _mixins[baseId].putIfAbsent(mixinType, () {
          var comment = '${baseId.name} & ${mixinType.name}';
          return generator.createMixinType(comment);
        });
        if (!baseType.type.isObject) generator.addParent(mixinId, baseId);
        baseType = mixinType;
        baseId = mixinId;
        _mixins.putIfAbsent(mixinId, () => {});
      }
    }
    if (!baseType.type.isObject) generator.addParent(_typeFor(type), baseId);
  }

  TypeIdentifier _typeFor(Element type) => new TypeIdentifier(
      type.library == null ? 'dart:core' : importUrlFor(type.library),
      type.displayName);

  /// Adds any declaration and superclass information that is needed to answer a
  /// query on [type] that matches [options]. Also adds symbols, getters, and
  /// setters if [includeAccessors] is true. If [results] is not null, it will
  /// be filled up with the members that match the query.
  void runQuery(ClassElement type, QueryOptions options,
      {bool includeAccessors: true, List results}) {
    if (type.type.isObject) return; // We don't include Object in query results.
    var id = _typeFor(type);
    var parent = type.supertype != null ? type.supertype.element : null;
    if (options.includeInherited && parent != null &&
        parent != options.includeUpTo) {
      lookupParent(type);
      runQuery(parent, options, includeAccessors: includeAccessors);
      var parentId = _typeFor(parent);
      for (var m in type.mixins) {
        var mixinClass = m.element;
        var mixinId = _mixins[parentId][mixinClass];
        _runQueryInternal(
            mixinClass, mixinId, options, includeAccessors, results);
        parentId = mixinId;
      }
    }
    _runQueryInternal(type, id, options, includeAccessors, results);
  }

  /// Helper for [runQuery]. This runs the query only on a specific [type],
  /// which could be a class or a mixin labeled by [id].
  // TODO(sigmund): currently we materialize mixins in smoke/static.dart,
  // we should consider to include the mixin declaration information directly,
  // and remove the duplication we have for mixins today.
  void _runQueryInternal(ClassElement type, TypeIdentifier id,
      QueryOptions options, bool includeAccessors, List results) {

    skipBecauseOfAnnotations(Element e) {
      if (options.withAnnotations == null) return false;
      return !_matchesAnnotation(e.metadata, options.withAnnotations);
    }

    if (options.includeFields) {
      for (var f in type.fields) {
        if (f.isStatic) continue;
        if (f.isSynthetic) continue; // exclude getters
        if (options.excludeFinal && f.isFinal) continue;
        var name = f.displayName;
        if (options.matches != null && !options.matches(name)) continue;
        if (skipBecauseOfAnnotations(f)) continue;
        if (results != null) results.add(f);
        generator.addDeclaration(id, name, _typeFor(f.type.element),
            isField: true, isFinal: f.isFinal,
            annotations: _copyAnnotations(f));
        if (includeAccessors) _addAccessors(name, !f.isFinal);
      }
    }

    if (options.includeProperties) {
      for (var a in type.accessors) {
        if (a is! PropertyAccessorElement) continue;
        if (a.isStatic || !a.isGetter) continue;
        var v = a.variable;
        if (v is FieldElement && !v.isSynthetic) continue; // exclude fields
        if (options.excludeFinal && v.isFinal) continue;
        var name = v.displayName;
        if (options.matches != null && !options.matches(name)) continue;
        if (skipBecauseOfAnnotations(a)) continue;
        if (results != null) results.add(a);
        generator.addDeclaration(id, name, _typeFor(a.type.returnType.element),
            isProperty: true, isFinal: v.isFinal,
            annotations: _copyAnnotations(a));
        if (includeAccessors) _addAccessors(name, !v.isFinal);
      }
    }

    if (options.includeMethods) {
      for (var m in type.methods) {
        if (m.isStatic) continue;
        var name = m.displayName;
        if (options.matches != null && !options.matches(name)) continue;
        if (skipBecauseOfAnnotations(m)) continue;
        if (results != null) results.add(m);
        generator.addDeclaration(id, name,
            new TypeIdentifier('dart:core', 'Function'), isMethod: true,
            annotations: _copyAnnotations(m));
        if (includeAccessors) _addAccessors(name, false);
      }
    }
  }

  /// Adds the declaration of [name] if it was found in [type]. If [recursive]
  /// is true, then we continue looking up [name] in the parent classes until we
  /// find it or we reach [includeUpTo] or Object. Returns whether the
  /// declaration was found.  When a declaration is found, add also a symbol,
  /// getter, and setter if [includeAccessors] is true.
  bool lookupMember(ClassElement type, String name, {bool recursive: false,
      bool includeAccessors: true, ClassElement includeUpTo}) =>
    _lookupMemberInternal(type, _typeFor(type), name, recursive,
        includeAccessors, includeUpTo);

  /// Helper for [lookupMember] that walks up the type hierarchy including mixin
  /// classes.
  bool _lookupMemberInternal(ClassElement type, TypeIdentifier id, String name,
      bool recursive, bool includeAccessors, ClassElement includeUpTo) {
    // Exclude members from [Object].
    if (type.type.isObject) return false;
    generator.addEmptyDeclaration(id);
    for (var f in type.fields) {
      if (f.displayName != name) continue;
      if (f.isSynthetic) continue; // exclude getters
      generator.addDeclaration(id, name,
          _typeFor(f.type.element), isField: true, isFinal: f.isFinal,
          isStatic: f.isStatic, annotations: _copyAnnotations(f));
      if (includeAccessors && !f.isStatic) _addAccessors(name, !f.isFinal);
      return true;
    }

    for (var a in type.accessors) {
      if (a is! PropertyAccessorElement) continue;
      // TODO(sigmund): support setters without getters.
      if (!a.isGetter) continue;
      if (a.displayName != name) continue;
      var v = a.variable;
      if (v is FieldElement && !v.isSynthetic) continue; // exclude fields
      generator.addDeclaration(id, name,
          _typeFor(a.type.returnType.element), isProperty: true,
          isFinal: v.isFinal, isStatic: a.isStatic,
          annotations: _copyAnnotations(a));
      if (includeAccessors && !v.isStatic) _addAccessors(name, !v.isFinal);
      return true;
    }

    for (var m in type.methods) {
      if (m.displayName != name) continue;
      generator.addDeclaration(id, name,
          new TypeIdentifier('dart:core', 'Function'), isMethod: true,
          isStatic: m.isStatic, annotations: _copyAnnotations(m));
      if (includeAccessors) {
        if (m.isStatic) {
          generator.addStaticMethod(id, name);
          generator.addSymbol(name);
        } else {
          _addAccessors(name, false);
        }
      }
      return true;
    }

    if (recursive) {
      lookupParent(type);
      var parent = type.supertype != null ? type.supertype.element : null;
      if (parent == null || parent == includeUpTo) return false;
      var parentId = _typeFor(parent);
      for (var m in type.mixins) {
        var mixinClass = m.element;
        var mixinId = _mixins[parentId][mixinClass];
        if (_lookupMemberInternal(mixinClass, mixinId, name, false,
              includeAccessors, includeUpTo)) {
          return true;
        }
        parentId = mixinId;
      }
      return _lookupMemberInternal(parent, parentId, name, true,
          includeAccessors, includeUpTo);
    }
    return false;
  }

  /// Add information so smoke can invoke the static method [type].[name].
  void addStaticMethod(ClassElement type, String name) {
    generator.addStaticMethod(_typeFor(type), name);
  }

  /// Adds [name] as a symbol, a getter, and optionally a setter in [generator].
  _addAccessors(String name, bool includeSetter) {
    generator.addSymbol(name);
    generator.addGetter(name);
    if (includeSetter) generator.addSetter(name);
  }

  /// Copy metadata associated with the declaration of [target].
  List<ConstExpression> _copyAnnotations(Element target) {
    var node = target.node;
    // [node] is the initialization expression, we walk up to get to the actual
    // member declaration where the metadata is attached to.
    while (node is! ClassMember) node = node.parent;
    return node.metadata.map(_convertAnnotation).toList();
  }

  /// Converts annotations into [ConstExpression]s supported by the codegen
  /// library.
  ConstExpression _convertAnnotation(Annotation annotation) {
    var element = annotation.element;
    if (element is ConstructorElement) {
      if (!element.name.isEmpty) {
        throw new UnimplementedError(
            'named constructors are not implemented in smoke.codegen.recorder');
      }

      var positionalArgs = [];
      var namedArgs = {};
      for (var arg in annotation.arguments.arguments) {
        if (arg is NamedExpression) {
          namedArgs[arg.name.label.name] = _convertExpression(arg.expression);
        } else {
          positionalArgs.add(_convertExpression(arg));
        }
      }

      return new ConstructorExpression(importUrlFor(element.library),
          element.enclosingElement.name, positionalArgs, namedArgs);
    }

    if (element is PropertyAccessorElement) {
      return new TopLevelIdentifier(
          importUrlFor(element.library), element.name);
    }

    throw new UnsupportedError('unsupported annotation $annotation');
  }

  /// Converts [expression] into a [ConstExpression].
  ConstExpression _convertExpression(Expression expression) {
    if (expression is StringLiteral) {
      return new ConstExpression.string(expression.stringValue);
    }

    if (expression is BooleanLiteral || expression is DoubleLiteral ||
        expression is IntegerLiteral || expression is NullLiteral) {
      return new CodeAsConstExpression("${(expression as dynamic).value}");
    }

    if (expression is Identifier) {
      var element = expression.bestElement;
      if (element == null || !element.isPublic) {
        throw new UnsupportedError('private constants are not supported');
      }

      var url = importUrlFor(element.library);
      if (element is ClassElement) {
        return new TopLevelIdentifier(url, element.name);
      }

      if (element is PropertyAccessorElement) {
        var variable = element.variable;
        if (variable is FieldElement) {
          var cls = variable.enclosingElement;
          return new TopLevelIdentifier(url, '${cls.name}.${variable.name}');
        } else if (variable is TopLevelVariableElement) {
          return new TopLevelIdentifier(url, variable.name);
        }
      }
    }

    throw new UnimplementedError('expression convertion not implemented in '
        'smoke.codegen.recorder (${expression.runtimeType} $expression)');
  }
}

/// Returns whether [metadata] contains any annotation that is either equal to
/// an annotation in [queryAnnotations] or whose type is a subclass of a type
/// listed in [queryAnnotations]. This is equivalent to the check done in
/// `src/common.dart#matchesAnnotation`, except that this is applied to
/// static metadata as it was provided by the analyzer.
bool _matchesAnnotation(Iterable<ElementAnnotation> metadata,
    Iterable<Element> queryAnnotations) {
  for (var meta in metadata) {
    var element = meta.element;
    var exp;
    var type;
    if (element is PropertyAccessorElement) {
      exp = element.variable;
      type = exp.evaluationResult.value.type;
    } else if (element is ConstructorElement) {
      exp = element;
      type = element.enclosingElement.type;
    } else {
      throw new UnimplementedError('Unsupported annotation: ${meta}');
    }
    for (var queryMeta in queryAnnotations) {
      if (exp == queryMeta) return true;
      if (queryMeta is ClassElement && type.isSubtypeOf(queryMeta.type)) {
        return true;
      }
    }
  }
  return false;
}

/// Options equivalent to `smoke.dart#QueryOptions`, except that type
/// information and annotations are denoted by resolver's elements.
class QueryOptions {
  /// Whether to include fields (default is true).
  final bool includeFields;

  /// Whether to include getters and setters (default is true). Note that to
  /// include fields you also need to enable [includeFields].
  final bool includeProperties;

  /// Whether to include symbols from the given type and its superclasses
  /// (except [Object]).
  final bool includeInherited;

  /// If [includeInherited], walk up the type hierarchy up to this type
  /// (defaults to [Object]).
  final ClassElement includeUpTo;

  /// Whether to include final fields and getter-only properties.
  final bool excludeFinal;

  /// Whether to include methods (default is false).
  final bool includeMethods;

  /// If [withAnnotation] is not null, then it should be a list of types, so
  /// only symbols that are annotated with instances of those types are
  /// included.
  final List<Element> withAnnotations;

  /// If [matches] is not null, then only those fields, properties, or methods
  /// that match will be included.
  final NameMatcher matches;

  const QueryOptions({
      this.includeFields: true,
      this.includeProperties: true,
      this.includeInherited: true,
      this.includeUpTo: null,
      this.excludeFinal: false,
      this.includeMethods: false,
      this.withAnnotations: null,
      this.matches: null});
}

/// Predicate that tells whether [name] should be included in query results.
typedef bool NameMatcher(String name);
