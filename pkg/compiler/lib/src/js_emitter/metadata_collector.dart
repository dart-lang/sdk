// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_emitter.metadata_collector;

import 'package:js_ast/src/precedence.dart' as js_precedence;

import '../common.dart';
import '../constants/values.dart';
import '../deferred_load.dart' show OutputUnit;
import '../elements/entities.dart' show FunctionEntity;

import '../elements/entities.dart';
import '../elements/types.dart';
import '../js/js.dart' as jsAst;
import '../js/js.dart' show js;
import '../js_backend/runtime_types.dart' show RuntimeTypesEncoder;
import '../options.dart';
import '../universe/codegen_world_builder.dart';

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

  int compareTo(covariant _MetadataEntry other) => other._rc - this._rc;

  String toString() => '_BoundMetadataEntry($hashCode,rc=$_rc,_value=$_value)';
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
  final Emitter _emitter;
  final RuntimeTypesEncoder _rtiEncoder;
  final CodegenWorldBuilder _codegenWorldBuilder;

  /// A map with a token per output unit for a list of expressions that
  /// represent metadata, parameter names and type variable types.
  Map<OutputUnit, _MetadataList> _metadataTokens =
      new Map<OutputUnit, _MetadataList>();

  jsAst.Expression getMetadataForOutputUnit(OutputUnit outputUnit) {
    return _metadataTokens.putIfAbsent(outputUnit, () => new _MetadataList());
  }

  /// A map used to canonicalize the entries of metadata.
  Map<OutputUnit, Map<String, _BoundMetadataEntry>> _metadataMap =
      <OutputUnit, Map<String, _BoundMetadataEntry>>{};

  /// A map with a token for a lists of JS expressions, one token for each
  /// output unit. Once finalized, the entries represent types including
  /// function types and typedefs.
  Map<OutputUnit, _MetadataList> _typesTokens =
      new Map<OutputUnit, _MetadataList>();

  jsAst.Expression getTypesForOutputUnit(OutputUnit outputUnit) {
    return _typesTokens.putIfAbsent(outputUnit, () => new _MetadataList());
  }

  /// A map used to canonicalize the entries of types.
  Map<OutputUnit, Map<DartType, _BoundMetadataEntry>> _typesMap =
      <OutputUnit, Map<DartType, _BoundMetadataEntry>>{};

  MetadataCollector(this._options, this.reporter, this._emitter,
      this._rtiEncoder, this._codegenWorldBuilder);

  List<jsAst.DeferredNumber> reifyDefaultArguments(
      FunctionEntity function, OutputUnit outputUnit) {
    // TODO(sra): These are stored on the InstanceMethod or StaticDartMethod.
    List<jsAst.DeferredNumber> defaultValues = <jsAst.DeferredNumber>[];
    _codegenWorldBuilder.forEachParameter(function,
        (_, String name, ConstantValue constant) {
      if (constant == null) return;
      jsAst.Expression expression = _emitter.constantReference(constant);
      defaultValues.add(_addGlobalMetadata(expression, outputUnit));
    });
    return defaultValues;
  }

  jsAst.Expression reifyType(DartType type, OutputUnit outputUnit) {
    return addTypeInOutputUnit(type, outputUnit);
  }

  jsAst.Expression reifyName(String name, OutputUnit outputUnit) {
    return _addGlobalMetadata(js.string(name), outputUnit);
  }

  jsAst.Expression reifyExpression(
      jsAst.Expression expression, OutputUnit outputUnit) {
    return _addGlobalMetadata(expression, outputUnit);
  }

  _MetadataEntry _addGlobalMetadata(jsAst.Node node, OutputUnit outputUnit) {
    String nameToKey(jsAst.Name name) => "${name.key}";
    String printed = jsAst.prettyPrint(node,
        enableMinification: _options.enableMinification,
        renamerForNames: nameToKey);
    _metadataMap[outputUnit] ??= new Map<String, _BoundMetadataEntry>();
    return _metadataMap[outputUnit].putIfAbsent(printed, () {
      return new _BoundMetadataEntry(node);
    });
  }

  jsAst.Expression _computeTypeRepresentation(DartType type) {
    jsAst.Expression representation =
        _rtiEncoder.getTypeRepresentation(_emitter, type, (variable) {
      failedAt(
          NO_LOCATION_SPANNABLE,
          "Type representation for type variable $variable in "
          "$type is not supported.");
      return jsAst.LiteralNull();
    }, (TypedefType typedef) {
      return false;
    });

    if (representation is jsAst.LiteralString) {
      // We don't want the representation to be a string, since we use
      // strings as indicator for non-initialized types in the lazy emitter.
      reporter.internalError(
          NO_LOCATION_SPANNABLE, 'reified types should not be strings.');
    }

    return representation;
  }

  jsAst.Expression addTypeInOutputUnit(DartType type, OutputUnit outputUnit) {
    _typesMap[outputUnit] ??= new Map<DartType, _BoundMetadataEntry>();
    return _typesMap[outputUnit].putIfAbsent(type, () {
      return new _BoundMetadataEntry(_computeTypeRepresentation(type));
    });
  }

  @override
  void finalizeTokens() {
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

    _metadataTokens.forEach((OutputUnit outputUnit, _MetadataList token) {
      Map metadataMap = _metadataMap[outputUnit];
      if (metadataMap != null) {
        token.setExpression(finalizeMap(metadataMap));
      } else {
        token.setExpression(new jsAst.ArrayInitializer([]));
      }
    });

    _typesTokens.forEach((OutputUnit outputUnit, _MetadataList token) {
      Map typesMap = _typesMap[outputUnit];
      if (typesMap != null) {
        countTokensInTypes(typesMap.values);
        token.setExpression(finalizeMap(typesMap));
      } else {
        token.setExpression(new jsAst.ArrayInitializer([]));
      }
    });
  }
}
