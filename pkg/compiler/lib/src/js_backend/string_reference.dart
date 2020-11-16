// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// StringReferences are 'holes' in the generated JavaScript that are filled in
/// by the emitter with code to access a large string.
///
/// The Dart code
///
///     foo1() => 'A very long string';
///
/// might be compiled to something like the following, where StringReference1 is
/// assocatied with the string `'A very long string'`.
///
///     foo1: function() {
///       return StringReference1;
///     }
///
/// The dart method `foo2` would be compiled separately, with the generated code
/// containing StringReference2, also 3 referring to `int`:
///
///     foo2() => 'A very long string';
/// -->
///     foo2: function() {
///       return StringReference2;
///     }
///
/// When the code for an output unit (main unit or deferred loaded unit) is
/// assembled, there will also be a StringReferenceResource 'hole', so the
/// assembled looks something like
///
///     foo: function() {
///       return StringReference1;
///     }
///     foo2: function() {
///       return StringReference2;
///     }
///     ...
///     StringReferenceResource
///
/// The StringReferenceFinalizer decides on a strategy for accessing the
/// strings. In most cases a string will have one reference and it should be
/// generated in-place. Shared strings can be referenced via a object. The
/// StringReference nodes are filled in with property access expressions and the
/// StringReferenceResource is filled in with the precomputed data, something
/// like:
///
///     foo1: function() {
///       return string$.A_very;
///     }
///     foo2: function() {
///       return string$.A_very;
///     }
///     ...
///     var string$ = {
///       A_very: "A very long string",
///     };
///
/// In minified mode, the properties (`A_very`) can be replaced by shorter
/// names.
library js_backend.string_reference;

import '../constants/values.dart' show StringConstantValue;
import '../js/js.dart' as js;
import '../serialization/serialization.dart';
import '../util/util.dart' show Hashing;
import 'frequency_assignment.dart';
import 'name_sequence.dart';
import 'string_abbreviation.dart';

class StringReferencePolicy {
  /// Minimum length to generate a StringReference for further processing.
  static const int minimumLength = 11;

  /// Strings shorter that [shortestSharedLength] are not shared.
  // TODO(sra): Split this into different settings depending on code contexts
  // (hot, cold, execute-once, etc).
  static const int shortestSharedLength = 40;

  // TODO(sra): Add policy for huge non-shared strings, strings occuring in
  // run-once code, etc. Maybe make policy settings assignable for testing or
  // command-line configuration.
}

/// A [StringReference] is a deferred JavaScript expression that refers to the
/// runtime representation of a ground type or ground type environment.  The
/// deferred expression is filled in by the StringReferenceFinalizer which is
/// called from the fragment emitter. The replacement expression could be any
/// expression, e.g. a call, or a reference to a variable, or property of a
/// variable.
class StringReference extends js.DeferredExpression implements js.AstContainer {
  static const String tag = 'string-reference';

  final StringConstantValue constant;

  js.Expression _value;

  @override
  final js.JavaScriptNodeSourceInformation sourceInformation;

  StringReference(this.constant) : sourceInformation = null;
  StringReference._(this.constant, this._value, this.sourceInformation);

  factory StringReference.readFromDataSource(DataSource source) {
    source.begin(tag);
    StringConstantValue constant = source.readConstant() as StringConstantValue;
    source.end(tag);
    return StringReference(constant);
  }

  void writeToDataSink(DataSink sink) {
    sink.begin(tag);
    sink.writeConstant(constant);
    sink.end(tag);
  }

  set value(js.Expression value) {
    assert(!isFinalized && value != null);
    _value = value;
  }

  @override
  js.Expression get value {
    assert(isFinalized, 'StringReference is unassigned');
    return _value;
  }

  @override
  bool get isFinalized => _value != null;

  // Precedence will be CALL or LEFT_HAND_SIDE depending on what expression the
  // reference is resolved to.
  @override
  int get precedenceLevel => value.precedenceLevel;

  @override
  StringReference withSourceInformation(
      js.JavaScriptNodeSourceInformation newSourceInformation) {
    if (newSourceInformation == sourceInformation) return this;
    if (newSourceInformation == null) return this;
    return StringReference._(constant, _value, newSourceInformation);
  }

  @override
  Iterable<js.Node> get containedNodes => isFinalized ? [_value] : const [];
}

/// A [StringReferenceResource] is a deferred JavaScript expression determined
/// by the finalization of string references. It is the injection point for data
/// or code to support string references. For example, if the
/// [StringReferenceFinalizer] decides that a string should be referred to via a
/// variable, the [StringReferenceResource] would be set to code that declares
/// and initializes the variable.
class StringReferenceResource extends js.DeferredExpression
    implements js.AstContainer {
  js.Expression _value;

  @override
  final js.JavaScriptNodeSourceInformation sourceInformation;

  StringReferenceResource() : sourceInformation = null;
  StringReferenceResource._(this._value, this.sourceInformation);

  set value(js.Expression value) {
    assert(!isFinalized && value != null);
    _value = value;
  }

  @override
  js.Expression get value {
    assert(isFinalized, 'StringReferenceResource is unassigned');
    return _value;
  }

  @override
  int get precedenceLevel => value.precedenceLevel;

  @override
  bool get isFinalized => _value != null;

  @override
  StringReferenceResource withSourceInformation(
      js.JavaScriptNodeSourceInformation newSourceInformation) {
    if (newSourceInformation == sourceInformation) return this;
    if (newSourceInformation == null) return this;
    return StringReferenceResource._(_value, newSourceInformation);
  }

  @override
  Iterable<js.Node> get containedNodes => isFinalized ? [_value] : const [];

  @override
  void visitChildren<T>(js.NodeVisitor<T> visitor) {
    _value?.accept<T>(visitor);
  }

  @override
  void visitChildren1<R, A>(js.NodeVisitor1<R, A> visitor, A arg) {
    _value?.accept1<R, A>(visitor, arg);
  }
}

abstract class StringReferenceFinalizer {
  /// Collects StringReference and StringReferenceResource nodes from the
  /// JavaScript AST [code];
  void addCode(js.Node code);

  /// Performs analysis on all collected StringReference nodes finalizes the
  /// values to expressions to access the types.
  void finalize();
}

class StringReferenceFinalizerImpl implements StringReferenceFinalizer {
  final bool _minify;
  final int shortestSharedLength; // Configurable for testing.

  /*late final*/ _StringReferenceCollectorVisitor _visitor;
  StringReferenceResource _resource;

  /// Maps the recipe (type expression) to the references with the same recipe.
  /// Much of the algorithm's state is stored in the _ReferenceSet objects.
  Map<StringConstantValue, _ReferenceSet> _referencesByString = {};

  StringReferenceFinalizerImpl(this._minify,
      {this.shortestSharedLength =
          StringReferencePolicy.shortestSharedLength}) {
    _visitor = _StringReferenceCollectorVisitor(this);
  }

  @override
  void addCode(js.Node code) {
    code.accept(_visitor);
  }

  @override
  void finalize() {
    assert(_resource != null, 'StringReferenceFinalizer needs resource');
    _allocateNames();
    _updateReferences();
  }

  // Called from collector visitor.
  void registerStringReference(StringReference node) {
    StringConstantValue constant = node.constant;
    _ReferenceSet refs =
        _referencesByString[constant] ??= _ReferenceSet(constant);
    refs.count++;
    refs._references.add(node);
  }

  // Called from collector visitor.
  void registerStringReferenceResource(StringReferenceResource node) {
    assert(_resource == null);
    _resource = node;
  }

  void _updateReferences() {
    // Emit generate-at-use references.
    for (_ReferenceSet referenceSet in _referencesByString.values) {
      if (referenceSet.generateAtUse) {
        StringConstantValue constant = referenceSet.constant;
        js.Expression reference =
            js.js.escapedString(constant.stringValue, ascii: true);
        for (StringReference ref in referenceSet._references) {
          ref.value = reference;
        }
      }
    }

    List<_ReferenceSet> referenceSetsUsingProperties =
        _referencesByString.values.where((ref) => !ref.generateAtUse).toList();

    // Sort by string (which is unique and stable) so that similar strings are
    // grouped together.
    referenceSetsUsingProperties.sort(_ReferenceSet.compareByString);

    List<js.Property> properties = [];
    for (_ReferenceSet referenceSet in referenceSetsUsingProperties) {
      String string = referenceSet.constant.stringValue;
      var propertyName = js.string(referenceSet.propertyName);
      properties.add(
          js.Property(propertyName, js.js.escapedString(string, ascii: true)));
      var access = js.js('#.#', [holderLocalName, propertyName]);
      for (StringReference ref in referenceSet._references) {
        ref.value = access;
      }
    }

    if (properties.isEmpty) {
      // We don't have a deferred statement sequence. "0;" is the smallest we
      // can do with an expression statement.
      // TODO(sra): Add deferred expression statement sequences.
      _resource.value = js.js('0');
    } else {
      js.Expression initializer =
          js.ObjectInitializer(properties, isOneLiner: false);
      _resource.value = js.js(
          r'var # = #', [js.VariableDeclaration(holderLocalName), initializer]);
    }
  }

  // This is a top-level local name in the generated JavaScript top-level
  // function, so will be minified automatically. The name should not collide
  // with any other locals.
  static const holderLocalName = r'string$';

  void _allocateNames() {
    // Filter out generate-at-use cases and allocate unique names to the rest.
    List<_ReferenceSet> referencesInTable = [];

    for (final referenceSet in _referencesByString.values) {
      String text = referenceSet.constant.stringValue;
      if (referenceSet.count == 1) continue;
      // TODO(sra): We might want to always extract very large strings,
      // e.g. replace above with:
      //
      //     if (referenceSet.count == 1 && text.length < 1000) continue;
      if (text.length <= shortestSharedLength) continue;
      referencesInTable.add(referenceSet);
    }

    if (referencesInTable.isEmpty) return;

    List<String> names = abbreviateToIdentifiers(
        referencesInTable.map((r) => r.constant.stringValue));
    assert(referencesInTable.length == names.length);
    for (int i = 0; i < referencesInTable.length; i++) {
      referencesInTable[i].name = names[i];
    }

    if (!_minify) {
      // For unminified code, use the characteristic names as property names.
      for (final referenceSet in referencesInTable) {
        referenceSet.propertyName = referenceSet.name;
      }

      return;
    }

    // Step 2. Sort by frequency to arrange common entries have shorter property
    // names.
    List<_ReferenceSet> referencesByFrequency = referencesInTable.toList()
      ..sort((a, b) {
        assert(a.name != b.name);
        int r = b.count.compareTo(a.count); // Decreasing frequency.
        if (r != 0) return r;
        // Tie-break with raw string.
        return _ReferenceSet.compareByString(a, b);
      });

    for (final referenceSet in referencesByFrequency) {
      // TODO(sra): Assess the dispersal of this hash function in the
      // semistableFrequencyAssignment algorithm.
      // TODO(sra): Consider a cheaper but stable hash. We are generally hashing
      // a relatively small set of large strings.
      referenceSet.hash = Hashing.stringHash(referenceSet.constant.stringValue);
    }

    int hashOf(int index) => referencesByFrequency[index].hash;
    int countOf(int index) => referencesByFrequency[index].count;
    void assign(int index, String name) {
      if (_minify) {
        referencesByFrequency[index].propertyName = name;
      } else {
        var refSet = referencesByFrequency[index];
        refSet.propertyName = name + '_' + refSet.name;
      }
    }

    semistableFrequencyAssignment(referencesByFrequency.length,
        generalMinifiedNameSequence(), hashOf, countOf, assign);
  }
}

/// Set of references to a single recipe.
class _ReferenceSet {
  final StringConstantValue constant;

  // Number of times a StringReference for [constant] occurs in the tree-scan of
  // the JavaScript ASTs.
  int count = 0;

  // It is possible for the JavaScript AST to be a DAG, so collect
  // [StringReference]s as set so we don't try to update one twice.
  final Set<StringReference> _references = Set.identity();

  /// Characteristic name of the recipe - this can be used as a property name
  /// for emitting unminified code, and as a stable hash source for minified
  /// names.  [name] is `null` if [recipe] should always be generated at use.
  String name;

  /// Property name for 'indexing' into the precomputed types.
  String propertyName;

  /// A stable hash code that can be used for picking stable minified names.
  int hash = 0;

  _ReferenceSet(this.constant);

  // If we don't assign a name it means we should not precompute the recipe.
  bool get generateAtUse => name == null;

  static int compareByString(_ReferenceSet a, _ReferenceSet b) {
    return a.constant.stringValue.compareTo(b.constant.stringValue);
  }
}

/// Scans a JavaScript AST to collect all the StringReference nodes.
///
/// The state is kept in the finalizer so that this scan could be extended to
/// look for other deferred expressions in one pass.
// TODO(sra): Merge with TypeReferenceCollectorVisitor.
class _StringReferenceCollectorVisitor extends js.BaseVisitor<void> {
  final StringReferenceFinalizerImpl _finalizer;

  _StringReferenceCollectorVisitor(this._finalizer);

  @override
  void visitNode(js.Node node) {
    assert(node is! StringReference);
    assert(node is! StringReferenceResource);
    if (node is js.AstContainer) {
      for (js.Node element in node.containedNodes) {
        element.accept(this);
      }
    } else {
      super.visitNode(node);
    }
  }

  @override
  void visitDeferredExpression(js.DeferredExpression node) {
    if (node is StringReference) {
      _finalizer.registerStringReference(node);
    } else if (node is StringReferenceResource) {
      _finalizer.registerStringReferenceResource(node);
    } else {
      visitNode(node);
    }
  }
}
