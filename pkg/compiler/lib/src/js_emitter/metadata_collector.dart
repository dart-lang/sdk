// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_emitter.metadata_collector;

import 'package:js_ast/src/precedence.dart' as js_precedence;

import '../common.dart';
import '../constants/values.dart';
import '../elements/resolution_types.dart'
    show ResolutionDartType, ResolutionTypedefType;
import '../deferred_load.dart' show DeferredLoadTask, OutputUnit;
import '../elements/elements.dart'
    show
        ClassElement,
        ConstructorElement,
        Element,
        FieldElement,
        FunctionSignature,
        LibraryElement,
        MemberElement,
        MethodElement,
        MetadataAnnotation,
        ParameterElement;
import '../elements/entities.dart';
import '../js/js.dart' as jsAst;
import '../js/js.dart' show js;
import '../js_backend/constant_handler_javascript.dart';
import '../js_backend/mirrors_data.dart';
import '../js_backend/runtime_types.dart' show RuntimeTypesEncoder;
import '../js_backend/type_variable_handler.dart'
    show TypeVariableCodegenAnalysis;
import '../options.dart';

import 'code_emitter_task.dart' show Emitter;

/// Represents an entry's position in one of the global metadata arrays.
///
/// [_rc] is used to count the number of references of the token in the
/// ast for a program.
/// [value] is the actual position, once they have been finalized.
abstract class _MetadataEntry extends jsAst.DeferredNumber
    implements Comparable, jsAst.ReferenceCountedAstNode {
  jsAst.Expression get entry;
  int get value;
  int get _rc;

  // Mark this entry as seen. On the first time this is seen, the visitor
  // will be applied to the [entry] to also mark potential [_MetadataEntry]
  // instances in the [entry] as seen.
  markSeen(jsAst.TokenCounter visitor);
}

class _BoundMetadataEntry extends _MetadataEntry {
  int _value = -1;
  int _rc = 0;
  final jsAst.Expression entry;

  _BoundMetadataEntry(this.entry);

  bool get isFinalized => _value != -1;

  finalize(int value) {
    assert(!isFinalized);
    _value = value;
  }

  int get value {
    assert(isFinalized);
    return _value;
  }

  bool get isUsed => _rc > 0;

  markSeen(jsAst.BaseVisitor visitor) {
    _rc++;
    if (_rc == 1) entry.accept(visitor);
  }

  int compareTo(_MetadataEntry other) => other._rc - this._rc;
}

abstract class Placeholder implements jsAst.DeferredNumber {
  bind(_MetadataEntry entry);
}

class _ForwardingMetadataEntry extends _MetadataEntry implements Placeholder {
  _MetadataEntry _forwardTo;
  var debug;

  bool get isBound => _forwardTo != null;

  _ForwardingMetadataEntry([this.debug]);

  _MetadataEntry get forwardTo {
    assert(isBound);
    return _forwardTo;
  }

  jsAst.Expression get entry {
    assert(isBound);
    return forwardTo.entry;
  }

  int get value {
    assert(isBound);
    return forwardTo.value;
  }

  int get _rc => forwardTo._rc;

  markSeen(jsAst.BaseVisitor visitor) => forwardTo.markSeen(visitor);

  int compareTo(other) => forwardTo.compareTo(other);

  bind(_MetadataEntry entry) {
    assert(!isBound);
    _forwardTo = entry;
  }
}

class _MetadataList extends jsAst.DeferredExpression {
  jsAst.Expression _value;

  void setExpression(jsAst.Expression value) {
    assert(_value == null);
    assert(value.precedenceLevel == this.precedenceLevel);
    _value = value;
  }

  jsAst.Expression get value {
    assert(_value != null);
    return _value;
  }

  int get precedenceLevel => js_precedence.PRIMARY;
}

class MetadataCollector implements jsAst.TokenFinalizer {
  final CompilerOptions _options;
  final DiagnosticReporter reporter;
  final DeferredLoadTask _deferredLoadTask;
  final Emitter _emitter;
  final JavaScriptConstantCompiler _constants;
  final TypeVariableCodegenAnalysis _typeVariableCodegenAnalysis;
  final MirrorsData _mirrorsData;
  final RuntimeTypesEncoder _rtiEncoder;

  /// A token for a list of expressions that represent metadata, parameter names
  /// and type variable types.
  final _MetadataList _globalMetadata = new _MetadataList();
  jsAst.Expression get globalMetadata => _globalMetadata;

  /// A map used to canonicalize the entries of globalMetadata.
  Map<String, _BoundMetadataEntry> _globalMetadataMap;

  /// A map with a token for a lists of JS expressions, one token for each
  /// output unit. Once finalized, the entries represent types including
  /// function types and typedefs.
  Map<OutputUnit, _MetadataList> _typesTokens =
      new Map<OutputUnit, _MetadataList>();

  jsAst.Expression getTypesForOutputUnit(OutputUnit outputUnit) {
    return _typesTokens.putIfAbsent(outputUnit, () => new _MetadataList());
  }

  /// A map used to canonicalize the entries of types.
  Map<OutputUnit, Map<ResolutionDartType, _BoundMetadataEntry>> _typesMap =
      <OutputUnit, Map<ResolutionDartType, _BoundMetadataEntry>>{};

  MetadataCollector(
      this._options,
      this.reporter,
      this._deferredLoadTask,
      this._emitter,
      this._constants,
      this._typeVariableCodegenAnalysis,
      this._mirrorsData,
      this._rtiEncoder) {
    _globalMetadataMap = new Map<String, _BoundMetadataEntry>();
  }

  jsAst.Fun buildLibraryMetadataFunction(LibraryEntity element) {
    if (!_mirrorsData.mustRetainMetadata ||
        !_mirrorsData.isLibraryReferencedFromMirrorSystem(element)) {
      return null;
    }
    return _buildMetadataFunction(element as LibraryElement);
  }

  jsAst.Fun buildClassMetadataFunction(ClassEntity cls) {
    if (!_mirrorsData.mustRetainMetadata ||
        !_mirrorsData.isClassReferencedFromMirrorSystem(cls)) {
      return null;
    }
    // TODO(johnniwinther): Handle class entities.
    ClassElement element = cls;
    return _buildMetadataFunction(element);
  }

  bool _mustEmitMetadataForMember(MemberEntity member) {
    if (!_mirrorsData.mustRetainMetadata) {
      return false;
    }
    // TODO(johnniwinther): Handle member entities.
    MemberElement element = member;
    return _mirrorsData.isMemberReferencedFromMirrorSystem(element);
  }

  jsAst.Fun buildFieldMetadataFunction(FieldEntity field) {
    if (!_mustEmitMetadataForMember(field)) return null;
    // TODO(johnniwinther): Handle field entities.
    FieldElement element = field;
    return _buildMetadataFunction(element);
  }

  /// The metadata function returns the metadata associated with
  /// [element] in generated code.  The metadata needs to be wrapped
  /// in a function as it refers to constants that may not have been
  /// constructed yet.  For example, a class is allowed to be
  /// annotated with itself.  The metadata function is used by
  /// mirrors_patch to implement DeclarationMirror.metadata.
  jsAst.Fun _buildMetadataFunction(Element element) {
    return reporter.withCurrentElement(element, () {
      List<jsAst.Expression> metadata = <jsAst.Expression>[];
      for (MetadataAnnotation annotation in element.metadata) {
        ConstantValue constant =
            _constants.getConstantValueForMetadata(annotation);
        if (constant == null) {
          reporter.internalError(annotation, 'Annotation value is null.');
        } else {
          metadata.add(_emitter.constantReference(constant));
        }
      }
      if (metadata.isEmpty) return null;
      return js(
          'function() { return # }', new jsAst.ArrayInitializer(metadata));
    });
  }

  List<jsAst.DeferredNumber> reifyDefaultArguments(MethodElement function) {
    function = function.implementation;
    FunctionSignature signature = function.functionSignature;
    if (signature.optionalParameterCount == 0) return const [];

    // Optional parameters of redirecting factory constructors take their
    // defaults from the corresponding parameters of the redirection target.
    Map<ParameterElement, ParameterElement> targetParameterMap;
    if (function is ConstructorElement) {
      // TODO(sra): dart2js generates a redirecting factory constructor body
      // that has the signature of the redirecting constructor that calls the
      // redirection target. This is wrong - it should have the signature of the
      // target. This would make the reified default arguments trivial.

      ConstructorElement constructor = function;
      while (constructor.isRedirectingFactory &&
          !constructor.isCyclicRedirection) {
        // TODO(sra): Remove the loop once effectiveTarget forwards to patches.
        constructor = constructor.effectiveTarget.implementation;
      }

      if (constructor != function) {
        if (signature.hasOptionalParameters) {
          targetParameterMap =
              mapRedirectingFactoryConstructorOptionalParameters(
                  signature, constructor.functionSignature);
        }
      }
    }

    List<jsAst.DeferredNumber> defaultValues = <jsAst.DeferredNumber>[];
    for (ParameterElement element in signature.optionalParameters) {
      ParameterElement parameter =
          (targetParameterMap == null) ? element : targetParameterMap[element];
      ConstantValue constant = (parameter == null)
          ? null
          : _constants.getConstantValue(parameter.constant);
      jsAst.Expression expression = (constant == null)
          ? new jsAst.LiteralNull()
          : _emitter.constantReference(constant);
      defaultValues.add(_addGlobalMetadata(expression));
    }
    return defaultValues;
  }

  Map<ParameterElement, ParameterElement>
      mapRedirectingFactoryConstructorOptionalParameters(
          FunctionSignature source, FunctionSignature target) {
    var map = <ParameterElement, ParameterElement>{};

    if (source.optionalParametersAreNamed !=
        target.optionalParametersAreNamed) {
      // No legal optional arguments due to mismatch between named vs positional
      // optional arguments.
      return map;
    }

    if (source.optionalParametersAreNamed) {
      for (ParameterElement element in source.optionalParameters) {
        for (ParameterElement redirectedElement in target.optionalParameters) {
          if (element.name == redirectedElement.name) {
            map[element] = redirectedElement;
            break;
          }
        }
      }
    } else {
      int i = source.requiredParameterCount;
      for (ParameterElement element in source.orderedOptionalParameters) {
        if (i >= target.requiredParameterCount && i < target.parameterCount) {
          map[element] = target
              .orderedOptionalParameters[i - target.requiredParameterCount];
        }
        ++i;
      }
    }
    return map;
  }

  jsAst.Expression reifyMetadata(MetadataAnnotation annotation) {
    ConstantValue constant = _constants.getConstantValueForMetadata(annotation);
    if (constant == null) {
      reporter.internalError(annotation, 'Annotation value is null.');
      return null;
    }
    return _addGlobalMetadata(_emitter.constantReference(constant));
  }

  jsAst.Expression reifyType(ResolutionDartType type,
      {ignoreTypeVariables: false}) {
    return reifyTypeForOutputUnit(type, _deferredLoadTask.mainOutputUnit,
        ignoreTypeVariables: ignoreTypeVariables);
  }

  jsAst.Expression reifyTypeForOutputUnit(
      ResolutionDartType type, OutputUnit outputUnit,
      {ignoreTypeVariables: false}) {
    return addTypeInOutputUnit(type, outputUnit,
        ignoreTypeVariables: ignoreTypeVariables);
  }

  jsAst.Expression reifyName(String name) {
    return _addGlobalMetadata(js.string(name));
  }

  jsAst.Expression reifyExpression(jsAst.Expression expression) {
    return _addGlobalMetadata(expression);
  }

  Placeholder getMetadataPlaceholder([debug]) {
    return new _ForwardingMetadataEntry(debug);
  }

  _MetadataEntry _addGlobalMetadata(jsAst.Node node) {
    String nameToKey(jsAst.Name name) => "${name.key}";
    String printed =
        jsAst.prettyPrint(node, _options, renamerForNames: nameToKey);
    return _globalMetadataMap.putIfAbsent(printed, () {
      return new _BoundMetadataEntry(node);
    });
  }

  jsAst.Expression _computeTypeRepresentation(ResolutionDartType type,
      {ignoreTypeVariables: false}) {
    jsAst.Expression representation =
        _rtiEncoder.getTypeRepresentation(_emitter, type, (variable) {
      if (ignoreTypeVariables) return new jsAst.LiteralNull();
      return _typeVariableCodegenAnalysis.reifyTypeVariable(variable.element);
    }, (ResolutionTypedefType typedef) {
      return _mirrorsData.isTypedefAccessibleByReflection(typedef.element);
    });

    if (representation is jsAst.LiteralString) {
      // We don't want the representation to be a string, since we use
      // strings as indicator for non-initialized types in the lazy emitter.
      reporter.internalError(
          NO_LOCATION_SPANNABLE, 'reified types should not be strings.');
    }

    return representation;
  }

  jsAst.Expression addTypeInOutputUnit(
      ResolutionDartType type, OutputUnit outputUnit,
      {ignoreTypeVariables: false}) {
    if (_typesMap[outputUnit] == null) {
      _typesMap[outputUnit] =
          new Map<ResolutionDartType, _BoundMetadataEntry>();
    }
    return _typesMap[outputUnit].putIfAbsent(type, () {
      return new _BoundMetadataEntry(_computeTypeRepresentation(type,
          ignoreTypeVariables: ignoreTypeVariables));
    });
  }

  List<jsAst.DeferredNumber> computeMetadata(MethodElement element) {
    return reporter.withCurrentElement(element, () {
      if (!_mustEmitMetadataForMember(element))
        return const <jsAst.DeferredNumber>[];
      List<jsAst.DeferredNumber> metadata = <jsAst.DeferredNumber>[];
      for (MetadataAnnotation annotation in element.metadata) {
        metadata.add(reifyMetadata(annotation));
      }
      return metadata;
    });
  }

  @override
  void finalizeTokens() {
    bool checkTokensInTypes(OutputUnit outputUnit, entries) {
      UnBoundDebugger debugger = new UnBoundDebugger(outputUnit);
      for (_BoundMetadataEntry entry in entries) {
        if (!entry.isUsed) continue;
        if (debugger.findUnboundPlaceholders(entry.entry)) {
          return false;
        }
      }
      return true;
    }

    void countTokensInTypes(Iterable<_BoundMetadataEntry> entries) {
      jsAst.TokenCounter counter = new jsAst.TokenCounter();
      entries
          .where((_BoundMetadataEntry e) => e._rc > 0)
          .map((_BoundMetadataEntry e) => e.entry)
          .forEach(counter.countTokens);
    }

    jsAst.ArrayInitializer finalizeMap(Map<dynamic, _BoundMetadataEntry> map) {
      bool isUsed(_BoundMetadataEntry entry) => entry.isUsed;
      List<_BoundMetadataEntry> entries = map.values.where(isUsed).toList();
      entries.sort();

      // TODO(herhut): Bucket entries by index length and use a stable
      //               distribution within buckets.
      int count = 0;
      for (_BoundMetadataEntry entry in entries) {
        entry.finalize(count++);
      }

      List<jsAst.Node> values =
          entries.map((_BoundMetadataEntry e) => e.entry).toList();

      return new jsAst.ArrayInitializer(values);
    }

    _globalMetadata.setExpression(finalizeMap(_globalMetadataMap));

    _typesTokens.forEach((OutputUnit outputUnit, _MetadataList token) {
      Map typesMap = _typesMap[outputUnit];
      if (typesMap != null) {
        assert(checkTokensInTypes(outputUnit, typesMap.values));
        countTokensInTypes(typesMap.values);
        token.setExpression(finalizeMap(typesMap));
      } else {
        token.setExpression(new jsAst.ArrayInitializer([]));
      }
    });
  }
}

class UnBoundDebugger extends jsAst.BaseVisitor {
  OutputUnit outputUnit;
  bool _foundUnboundToken = false;

  UnBoundDebugger(this.outputUnit);

  @override
  visitDeferredNumber(jsAst.DeferredNumber token) {
    if (token is _ForwardingMetadataEntry && !token.isBound) {
      _foundUnboundToken = true;
    }
  }

  bool findUnboundPlaceholders(jsAst.Node node) {
    node.accept(this);
    return _foundUnboundToken;
  }
}
