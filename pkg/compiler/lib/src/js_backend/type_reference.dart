// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// TypeReferences are 'holes' in the generated JavaScript that are filled in by
/// the emitter with code to access a type.
///
/// The Dart code
///
///     foo1() => bar<int>(X<String>());
///
/// might be compiled to something like the following, with TypeReference1
/// referring to the constructed type `X<String>`, and TypeReference2 referring
/// to the method type argument `int`:
///
///     foo1: function() {
///       return bar(new X(TypeReference1), TypeReference2);
///     }
///
/// The dart method `foo2` would be compiled separately, with the generated code
/// containing TypeReference3 referring to `int`:
///
///     foo2() => bar<int>(null);
/// -->
///     foo2: function() {
///       return bar(null, TypeReference3);
///     }
///
/// When the code for an output unit (main unit or deferred loaded unit) is
/// assembled, there will also be a TypeReferenceResource 'hole', so the
/// assembled looks something like
///
///     foo: function() {
///       return bar(new X(TypeReference1), TypeReference2);
///     }
///     foo2: function() {
///       return bar(null, TypeReference3);
///     }
///     ...
///     TypeReferenceResource
///
/// The TypeReferenceFinalizer decides on a strategy for accessing the types. In
/// most cases it is best to precompute the types and access them via a
/// object. The TypeReference nodes are filled in with property access
/// expressions and the TypeReferenceResource is filled in with the precomputed
/// data, something like:
///
///     foo1: function() {
///       return bar(new X(type$.X_String), type$.int);
///     }
///     foo2: function() {
///       return bar(null, type$.int);
///     }
///     ...
///     var type$ = {
///       int: findType("int"),
///       X_String: findType("X<String>")
///     };
///
/// In minified mode, the properties `int` and `X_String` can be replaced by
/// shorter names.
library js_backend.type_reference;

import 'package:front_end/src/api_unstable/dart2js.dart'
    show $0, $9, $A, $Z, $_, $a, $z;

import '../common_elements.dart' show CommonElements;
import '../elements/types.dart';
import '../js/js.dart' as js;
import '../js_emitter/code_emitter_task.dart' show Emitter;
import '../js_model/type_recipe.dart'
    show
        TypeRecipe,
        TypeExpressionRecipe,
        SingletonTypeEnvironmentRecipe,
        FullTypeEnvironmentRecipe;
import '../serialization/serialization.dart';
import '../util/util.dart' show Hashing;
import 'frequency_assignment.dart';
import 'runtime_types_new.dart' show RecipeEncoder;

/// Run the minifier for 'type$' property names even in non-minified mode,
/// making a name from minified name and the readable name. Usage:
///
///     DART_VM_OPTIONS='-DDebugMinifyTypesHolder=true' dart2js ...
///
const _debugMinify = bool.fromEnvironment('DebugMinifyTypesHolder');

/// A [TypeReference] is a deferred JavaScript expression that refers to the
/// runtime representation of a ground type or ground type environment.  The
/// deferred expression is filled in by the TypeReferenceFinalizer which is
/// called from the fragment emitter. The replacement expression could be any
/// expression, e.g. a call, or a reference to a variable, or property of a
/// variable.
class TypeReference extends js.DeferredExpression implements js.AstContainer {
  static const String tag = 'type-reference';

  /// [typeRecipe] is a recipe for a ground type or type environment.
  final TypeRecipe typeRecipe;

  // TODO(sra): Refine the concept of reference context and replace the
  // 'forConstant' and 'forLazyInitializer' flags.

  // `true` if TypeReference is in code that initializes constant value.
  bool forConstant = false;

  // `true` if TypeReference is in code for a lazy initializer of a static
  // variable.
  bool forLazyInitializer = false;

  js.Expression _value;

  @override
  final js.JavaScriptNodeSourceInformation sourceInformation;

  TypeReference(this.typeRecipe) : sourceInformation = null;
  TypeReference._(this.typeRecipe, this._value, this.sourceInformation);

  factory TypeReference.readFromDataSource(DataSource source) {
    source.begin(tag);
    TypeRecipe recipe = source.readTypeRecipe();
    bool forLazyInitializer = source.readBool();
    source.end(tag);
    return TypeReference(recipe)..forLazyInitializer = forLazyInitializer;
  }

  void writeToDataSink(DataSink sink) {
    sink.begin(tag);
    sink.writeTypeRecipe(typeRecipe);
    sink.writeBool(forLazyInitializer);
    sink.end(tag);
  }

  set value(js.Expression value) {
    assert(!isFinalized && value != null);
    _value = value;
  }

  @override
  js.Expression get value {
    assert(isFinalized, 'TypeReference is unassigned');
    return _value;
  }

  @override
  bool get isFinalized => _value != null;

  // Precedence will be CALL or LEFT_HAND_SIDE depending on what expression the
  // reference is resolved to.
  @override
  int get precedenceLevel => value.precedenceLevel;

  @override
  TypeReference withSourceInformation(
      js.JavaScriptNodeSourceInformation newSourceInformation) {
    if (newSourceInformation == sourceInformation) return this;
    if (newSourceInformation == null) return this;
    return TypeReference._(typeRecipe, _value, newSourceInformation);
  }

  @override
  Iterable<js.Node> get containedNodes => isFinalized ? [_value] : const [];
}

/// A [TypeReferenceResource] is a deferred JavaScript expression determined by
/// the finalization of type references. It is the injection point for data or
/// code to support type references. For example, if the
/// [TypeReferenceFinalizer] decides that type should be referred to via a
/// variable, the [TypeReferenceResource] would be set to code that declares and
/// initializes the variable.
class TypeReferenceResource extends js.DeferredExpression
    implements js.AstContainer {
  js.Expression _value;

  @override
  final js.JavaScriptNodeSourceInformation sourceInformation;

  TypeReferenceResource() : sourceInformation = null;
  TypeReferenceResource._(this._value, this.sourceInformation);

  set value(js.Expression value) {
    assert(!isFinalized && value != null);
    _value = value;
  }

  @override
  js.Expression get value {
    assert(isFinalized, 'TypeReferenceResource is unassigned');
    return _value;
  }

  @override
  bool get isFinalized => _value != null;

  @override
  int get precedenceLevel => value.precedenceLevel;

  @override
  TypeReferenceResource withSourceInformation(
      js.JavaScriptNodeSourceInformation newSourceInformation) {
    if (newSourceInformation == sourceInformation) return this;
    if (newSourceInformation == null) return this;
    return TypeReferenceResource._(_value, newSourceInformation);
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

abstract class TypeReferenceFinalizer {
  /// Collects TypeReference and TypeReferenceResource nodes from the JavaScript
  /// AST [code];
  void addCode(js.Node code);

  /// Performs analysis on all collected TypeReference nodes finalizes the
  /// values to expressions to access the types.
  void finalize();
}

class TypeReferenceFinalizerImpl implements TypeReferenceFinalizer {
  final Emitter _emitter;
  final CommonElements _commonElements;
  final RecipeEncoder _recipeEncoder;
  final bool _minify;

  /*late final*/ _TypeReferenceCollectorVisitor _visitor;
  TypeReferenceResource _resource;

  /// Maps the recipe (type expression) to the references with the same recipe.
  /// Much of the algorithm's state is stored in the _ReferenceSet objects.
  Map<TypeRecipe, _ReferenceSet> _referencesByRecipe = {};

  TypeReferenceFinalizerImpl(
      this._emitter, this._commonElements, this._recipeEncoder, this._minify) {
    _visitor = _TypeReferenceCollectorVisitor(this);
  }

  @override
  void addCode(js.Node code) {
    code.accept(_visitor);
  }

  @override
  void finalize() {
    assert(_resource != null, 'TypeReferenceFinalizer needs resource');
    _allocateNames();
    _updateReferences();
  }

  // Called from collector visitor.
  void _registerTypeReference(TypeReference node) {
    TypeRecipe recipe = node.typeRecipe;
    _ReferenceSet refs = _referencesByRecipe[recipe] ??= _ReferenceSet(recipe);
    refs.count++;
    if (node.forConstant) refs.countInConstant++;
    if (node.forLazyInitializer) refs.countInLazyInitializer++;
    refs._references.add(node);
  }

  // Called from collector visitor.
  void _registerTypeReferenceResource(TypeReferenceResource node) {
    assert(_resource == null);
    _resource = node;
  }

  void _updateReferences() {
    js.Expression helperAccess =
        _emitter.staticFunctionAccess(_commonElements.findType);

    js.Expression loadTypeCall(TypeRecipe recipe, String helperLocal) {
      js.Expression recipeExpression =
          _recipeEncoder.encodeGroundRecipe(_emitter, recipe);
      return js.js(r'#(#)', [helperLocal ?? helperAccess, recipeExpression]);
    }

    // Emit generate-at-use references.
    for (_ReferenceSet referenceSet in _referencesByRecipe.values) {
      if (referenceSet.generateAtUse) {
        TypeRecipe recipe = referenceSet.recipe;
        js.Expression reference = loadTypeCall(recipe, null);
        for (TypeReference ref in referenceSet._references) {
          ref.value = reference;
        }
      }
    }

    List<_ReferenceSet> referenceSetsUsingProperties =
        _referencesByRecipe.values.where((ref) => !ref.generateAtUse).toList();

    // Sort by name (which is unique and mostly stable) so that similar recipes
    // are grouped together.
    referenceSetsUsingProperties.sort((a, b) => a.name.compareTo(b.name));

    // We can generate a literal with calls to H.findType (minified to typically
    // e.g. H.xy) or cache H.findType in a local in a scope created by an IIFE.
    // Doing so saves 2-3 bytes per entry, but with an overhead of 30+ bytes for
    // the IIFE.  So it is smaller to use the IIFE only for over 10 or so types.
    const minUseIIFE = 10;
    String helperLocal =
        referenceSetsUsingProperties.length < minUseIIFE ? null : 'findType';

    List<js.Property> properties = [];
    for (_ReferenceSet referenceSet in referenceSetsUsingProperties) {
      TypeRecipe recipe = referenceSet.recipe;
      var propertyName = js.string(referenceSet.propertyName);
      properties
          .add(js.Property(propertyName, loadTypeCall(recipe, helperLocal)));
      var access = js.js('#.#', [typesHolderLocalName, propertyName]);
      for (TypeReference ref in referenceSet._references) {
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
      if (helperLocal != null) {
        // A named IIFE helps attribute startup time in profiling.
        var function = js.js(r'function rtii(){var # = #; return #}',
            [js.VariableDeclaration(helperLocal), helperAccess, initializer]);
        initializer = js.js('#()', js.Parentheses(function));
      }
      _resource.value = js.js(r'var # = #',
          [js.VariableDeclaration(typesHolderLocalName), initializer]);
    }
  }

  // This is a top-level local name in the generated JavaScript top-level
  // function, so will be minified automatically. The name should not collide
  // with any other locals.
  static const typesHolderLocalName = r'type$';

  void _allocateNames() {
    // Filter out generate-at-use cases and allocate unique names to the rest.
    List<_ReferenceSet> referencesInTable = [];
    Set<String> usedNames = {};
    for (_ReferenceSet referenceSet in _referencesByRecipe.values) {
      // - If a type is used only once from a constant then the findType can be
      // a subexpression of constant since it will be evaluated exactly once and
      // need not be stored anywhere else.
      if (referenceSet.count == 1 && referenceSet.countInConstant == 1) {
        continue;
      }

      // - Lazy initializers are usually evaluated on demand and only once, so
      // it is worth deferrering evaluating the type references until the lazy
      // initializer is executed, provided it does not increase program
      // size too much.
      //
      // Assuming minification in a large program, the size for precomputed is
      //
      //     abc:f("TTT"),/*once*/ +  type$.abc/*N times*/
      //
      // i.e. 13 + 5N. The size for repeated generate-at-use is
      //
      //      H.lookupType("TTT") /*N times*/
      //
      // i.e. 10N. Repeated is smaller when 10N < 13+5N, or N < 2.6. Since we
      // get a startup benefit of not evaluating the type recipe, lets round
      // up. Note that we don't know the size of the recipe ("TTT" assumes an
      // infrequently referenced non-generic interface type), but if the recipe
      // is larger, it is in a string so the program has the same number of
      // tokens and the extra bytes will be parsed efficiently.
      const int maxRepeatedLookups = 3;

      if (referenceSet.countInLazyInitializer == referenceSet.count &&
          referenceSet.count <= maxRepeatedLookups) {
        continue;
      }

      // TODO(sra): There are other contexts that would be beneficial, e.g. a
      // type reference occuring only in a throw expression.

      String suggestedName = _RecipeToIdentifier().run(referenceSet.recipe);
      if (usedNames.contains(suggestedName)) {
        for (int i = 2; true; i++) {
          String next = '${suggestedName}_$i';
          if (usedNames.contains(next)) continue;
          suggestedName = next;
          break;
        }
      }
      usedNames.add(suggestedName);
      referenceSet.name = suggestedName;
      referencesInTable.add(referenceSet);
    }

    if (!_minify && !_debugMinify) {
      // For unminified code, use the characteristic names as property names.
      // TODO(sra): Some of these names are long. We could truncate the names
      // after the unique prefix.
      for (_ReferenceSet referenceSet in referencesInTable) {
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
        return a.name.compareTo(b.name); // Tie-break with characteristic name.
      });

    for (var referenceSet in referencesByFrequency) {
      referenceSet.hash = _hashCharacteristicString(referenceSet.name);
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

    //naiveFrequencyAssignment(
    semistableFrequencyAssignment(referencesByFrequency.length,
        minifiedNameSequence(), hashOf, countOf, assign);
  }

  static int _hashCharacteristicString(String s) {
    int hash = 0;
    for (int i = 0; i < s.length; i++) {
      hash = Hashing.mixHashCodeBits(hash, s.codeUnitAt(i));
    }
    return hash;
  }

  /// Returns an infinite sequence of property names in increasing size.
  static Iterable<String> minifiedNameSequence() sync* {
    List<int> nextName = [$a];

    /// Increments the letter at [pos] in the current name. Also takes care of
    /// overflows to the left. Returns the carry bit, i.e., it returns `true`
    /// if all positions to the left have wrapped around.
    ///
    /// If [nextName] is initially 'a', this will generate the sequence
    ///
    ///     [a-zA-Z_]
    ///     [a-zA-Z_][0-9a-zA-Z_]
    ///     [a-zA-Z_][0-9a-zA-Z_][0-9a-zA-Z_]
    ///     ...
    bool incrementPosition(int pos) {
      bool overflow = false;
      if (pos < 0) return true;
      int value = nextName[pos];
      if (value == $9) {
        value = $a;
      } else if (value == $z) {
        value = $A;
      } else if (value == $Z) {
        value = $_;
      } else if (value == $_) {
        overflow = incrementPosition(pos - 1);
        value = (pos > 0) ? $0 : $a;
      } else {
        value++;
      }
      nextName[pos] = value;
      return overflow;
    }

    while (true) {
      yield String.fromCharCodes(nextName);
      if (incrementPosition(nextName.length - 1)) {
        nextName.add($0);
      }
    }
  }
}

/// Set of references to a single recipe.
class _ReferenceSet {
  final TypeRecipe recipe;

  // Number of times a TypeReference for [recipe] occurs in the tree-scan of the
  // JavaScript ASTs.
  int count = 0;

  // Number tree-scan occurrences in a constant initializer.
  int countInConstant = 0;
  // Number tree-scan occurrences in a static lazy initializer.
  int countInLazyInitializer = 0;

  // It is possible for the JavaScript AST to be a DAG, so collect
  // [TypeReference]s as set so we don't try to update one twice.
  final Set<TypeReference> _references = Set.identity();

  /// Characteristic name of the recipe - this can be used as a property name
  /// for emitting unminified code, and as a stable hash source for minified
  /// names.  [name] is `null` if [recipe] should always be generated at use.
  String name;

  /// Property name for 'indexing' into the precomputed types.
  String propertyName;

  /// A stable hash code that can be used for picking stable minified names.
  int hash = 0;

  _ReferenceSet(this.recipe);

  // If we don't assign a name it means we should not precompute the recipe.
  bool get generateAtUse => name == null;
}

/// Scans a JavaScript AST to collect all the TypeReference nodes.
///
/// The state is kept in the finalizer so that this scan could be extended to
/// look for other deferred expressions in one pass.
class _TypeReferenceCollectorVisitor extends js.BaseVisitor<void> {
  final TypeReferenceFinalizerImpl _finalizer;

  _TypeReferenceCollectorVisitor(this._finalizer);

  @override
  void visitNode(js.Node node) {
    assert(node is! TypeReference);
    assert(node is! TypeReferenceResource);
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
    if (node is TypeReference) {
      _finalizer._registerTypeReference(node);
    } else if (node is TypeReferenceResource) {
      _finalizer._registerTypeReferenceResource(node);
    } else {
      visitNode(node);
    }
  }
}

/// Returns a valid JavaScript identifier characterizing the recipe. The names
/// tend to look like the type expression with the non-identifier characters
/// removed.  Separators 'of' and 'and' are sometimes used to separate complex
/// types.
///
///     Map<int,int>        "Map_int_int"
///     Map<int,List<int>>  "Map_of_int_and_List_int"
///
///
/// For many common types the strings are unique, but this is not
/// guaranteed. This needs to be disambiguated at a higher level.
///
/// Different types can have the same string if the types contain different
/// interface types with the same name (i.e. from different libraries), or types
/// with names that contain underscores or dollar signs. There is also some
/// ambiguity in the generated names in the interest of keeping most names
/// short, e.g. "FutureOr_int_Function" could be "FutureOr<int> Function()" or
/// "FutureOr<int Function()>".
class _RecipeToIdentifier extends DartTypeVisitor<void, DartType> {
  final Map<DartType, int> _backrefs = Map.identity();
  final List<String> _fragments = [];

  static RegExp identifierStartRE = RegExp(r'[A-Za-z_$]');
  static RegExp nonIdentifierRE = RegExp(r'[^A-Za-z0-9_$]');

  String run(TypeRecipe recipe) {
    if (recipe is TypeExpressionRecipe) {
      _visit(recipe.type, null);
    } else if (recipe is SingletonTypeEnvironmentRecipe) {
      _add(r'$env');
      _visit(recipe.type, null);
    } else if (recipe is FullTypeEnvironmentRecipe) {
      _add(r'$env');
      if (recipe.classType != null) _visit(recipe.classType, null);
      _add('${recipe.types.length}');
      int index = 0;
      for (DartType type in recipe.types) {
        ++index;
        _add('${index}');
        _visit(type, null);
      }
    } else {
      throw StateError('Unexpected recipe: $recipe');
    }
    String result = _fragments.join('_');
    if (result.startsWith(identifierStartRE)) return result;
    return 'z' + result;
  }

  void _add(String text) {
    _fragments.add(text);
  }

  void _identifier(String text) {
    _add(text.replaceAll(nonIdentifierRE, '_'));
  }

  bool _comma(bool needsComma) {
    if (needsComma) _add('and');
    return true;
  }

  void _visit(DartType type, DartType parent) {
    type.accept(this, parent);
  }

  @override
  void visitLegacyType(covariant LegacyType type, _) {
    _add('legacy');
    _visit(type.baseType, type);
  }

  @override
  void visitNullableType(covariant NullableType type, _) {
    _add('nullable');
    _visit(type.baseType, type);
  }

  @override
  void visitNeverType(covariant NeverType type, _) {
    _add('Never');
  }

  @override
  void visitVoidType(covariant VoidType type, _) {
    _add('void');
  }

  @override
  void visitDynamicType(covariant DynamicType type, _) {
    _add('dynamic');
  }

  @override
  void visitErasedType(covariant ErasedType type, _) {
    _add('erased');
  }

  @override
  void visitAnyType(covariant AnyType type, _) {
    _add('any');
  }

  @override
  void visitTypeVariableType(covariant TypeVariableType type, DartType parent) {
    if (parent != type.element.typeDeclaration) {
      _identifier(type.element.typeDeclaration.name);
    }
    _identifier(type.element.name);
  }

  @override
  void visitFunctionTypeVariable(covariant FunctionTypeVariable type, _) {
    int index = type.index;
    String name = index < 26 ? String.fromCharCode($A + index) : 'v\$${index}';
    _add(name);
  }

  @override
  void visitFunctionType(covariant FunctionType type, DartType parent) {
    if (_dagCheck(type)) return;

    _visit(type.returnType, type);
    _add('Function');
    var typeVariables = type.typeVariables;
    if (typeVariables.isNotEmpty) {
      bool needsComma = false;
      for (FunctionTypeVariable typeVariable in typeVariables) {
        needsComma = _comma(needsComma);
        _visit(typeVariable, type);
        DartType bound = typeVariable.bound;
        if (!bound.isObject) {
          _add('extends');
          _visit(typeVariable.bound, typeVariable);
        }
      }
    }
    var parameterTypes = type.parameterTypes;
    var optionalParameterTypes = type.optionalParameterTypes;
    var namedParameters = type.namedParameters;
    var requiredNamedParameters = type.requiredNamedParameters;

    if (optionalParameterTypes.isEmpty &&
        namedParameters.isEmpty &&
        parameterTypes.every(_isSimple)) {
      // e.g.  "void_Function_int_int"
      for (DartType parameterType in parameterTypes) {
        _visit(parameterType, type);
      }
      return;
    }
    if (parameterTypes.length > 1) {
      _add('${parameterTypes.length}');
    }
    bool needsComma = false;
    for (DartType parameterType in parameterTypes) {
      needsComma = _comma(needsComma);
      _visit(parameterType, type);
    }
    if (optionalParameterTypes.isNotEmpty) {
      _add(r'$opt');
      bool needsOptionalComma = false;
      for (DartType typeArgument in optionalParameterTypes) {
        needsOptionalComma = _comma(needsOptionalComma);
        _visit(typeArgument, type);
      }
    }
    if (namedParameters.isNotEmpty) {
      _add(r'$named');
      bool needsNamedComma = false;
      for (int index = 0; index < namedParameters.length; index++) {
        needsNamedComma = _comma(needsNamedComma);
        if (requiredNamedParameters.contains(namedParameters[index])) {
          _add(r'$req');
        }
        _identifier(namedParameters[index]);
        _visit(type.namedParameterTypes[index], type);
      }
    }
  }

  @override
  void visitInterfaceType(covariant InterfaceType type, _) {
    var arguments = type.typeArguments;

    // Don't bother DAG-checking (generating back-ref encodings) for interface
    // types which 'print' as a single identifier.
    if (arguments.isNotEmpty && _dagCheck(type)) return;

    _identifier(type.element.name);

    if (arguments.isEmpty) return;
    if (arguments.length == 1) {
      // e.g. "List_of_int_Function"
      if (arguments.first.withoutNullability is FunctionType) {
        _add('of');
      }
      // e.g. "List_int"
      _visit(arguments.first, type);
      return;
    }
    if (arguments.every(_isSimple)) {
      // e.g. "Map_String_String"
      for (DartType argument in arguments) {
        _visit(argument, type);
      }
      return;
    }
    // e.g "Map_of_String_and_int_Function"
    _add('of');
    bool needsComma = false;
    for (DartType argument in arguments) {
      needsComma = _comma(needsComma);
      _visit(argument, type);
    }
  }

  bool _dagCheck(DartType type) {
    int /*?*/ ref = _backrefs[type];
    if (ref != null) {
      _add('\$$ref');
      return true;
    }
    _backrefs[type] = _backrefs.length;
    return false;
  }

  /// Returns `true` for types which print as a single identifier.
  static bool _isSimple(DartType type) {
    return type is DynamicType ||
        type is VoidType ||
        type is AnyType ||
        (type is InterfaceType && type.typeArguments.isEmpty);
  }

  @override
  void visitFutureOrType(covariant FutureOrType type, _) {
    _identifier('FutureOr');
    _visit(type.typeArgument, type);
  }
}
