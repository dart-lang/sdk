// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/kernel.dart' hide Pattern;
import 'package:kernel/src/replacement_visitor.dart';

import 'constants.dart';

Never throwUnsupportedInvalidType(InvalidType type) => throw UnsupportedError(
    'Unsupported invalid type $type (${type.runtimeType}).');

Never throwUnsupportedAuxiliaryType(AuxiliaryType type) =>
    throw UnsupportedError(
        'Unsupported auxiliary type $type (${type.runtimeType}).');

/// Returns [type] with the immediate type erasure applied.
///
/// When [type] is an [ExtensionType] this is equivalent to `type.typeErasure`.
/// The immediately returned value will not be an [ExtensionType] but it could
/// still contain other [ExtensionType]s embedded within.
DartType shallowExtensionTypeErasure(DartType type) =>
    type is ExtensionType ? type.extensionTypeErasure : type;

Constructor? unnamedConstructor(Class c) =>
    c.constructors.firstWhereOrNull((c) => c.name.text == '');

/// Returns the enclosing library for reference [node].
Library getLibrary(NamedNode node) {
  for (TreeNode? n = node; n != null; n = n.parent) {
    if (n is Library) return n;
  }
  throw UnsupportedError('Could not find a containing library for $node');
}

final Pattern _syntheticTypeCharacters = RegExp('[&^#.|]');

String? escapeIdentifier(String? identifier) {
  // Remove the special characters used to encode mixin application class names
  // and extension method / parameter names which are legal in Kernel, but not
  // in JavaScript.
  //
  // Note, there is an implicit assumption here that we won't have
  // collisions since everything is mapped to \$.  That may work out fine given
  // how these are synthesized, but may need to revisit.
  return identifier?.replaceAll(_syntheticTypeCharacters, r'$');
}

/// Returns the escaped name for class [node].
///
/// The caller of this function has to make sure that this name is unique in
/// the current scope.
///
/// In the current encoding, generic classes are generated in a function scope
/// which avoids name clashes of the escaped class name.
String getLocalClassName(Class node) => escapeIdentifier(node.name)!;

/// Returns the escaped name for the type parameter [node].
///
/// In the current encoding, generic classes are generated in a function scope
/// which avoids name clashes of the escaped parameter name.
String getTypeParameterName(
    /* TypeParameter | StructuralParameter */ Object node) {
  assert(node is TypeParameter || node is StructuralParameter);
  if (node is TypeParameter) {
    return escapeIdentifier(node.name)!;
  } else {
    node as StructuralParameter;
    return escapeIdentifier(node.name)!;
  }
}

String getTopLevelName(NamedNode n) {
  if (n is Procedure) return n.name.text;
  if (n is Class) return n.name;
  if (n is Typedef) return n.name;
  if (n is Field) return n.name.text;
  return n.reference.canonicalName!.name;
}

/// Given an annotated [node] and a [test] function, returns the first matching
/// constant valued annotation.
///
/// For example if we had the ClassDeclaration node for `FontElement`:
///
///    @js.JS('HTMLFontElement')
///    @deprecated
///    class FontElement { ... }
///
/// We could match `@deprecated` with a test function like:
///
///    (v) => v.type.name == 'Deprecated' && v.type.element.library.isDartCore
///
Expression? findAnnotation(TreeNode node, bool Function(Expression) test) {
  List<Expression> annotations;
  if (node is Class) {
    annotations = node.annotations;
  } else if (node is Typedef) {
    annotations = node.annotations;
  } else if (node is Procedure) {
    annotations = node.annotations;
  } else if (node is Member) {
    annotations = node.annotations;
  } else if (node is Library) {
    annotations = node.annotations;
  } else {
    return null;
  }
  return annotations.firstWhereOrNull(test);
}

/// Returns true if [value] represents an annotation for class [className] in
/// "dart:" library [libraryName].
bool isBuiltinAnnotation(
    Expression value, String libraryName, String className) {
  var c = getAnnotationClass(value);
  if (c != null && c.name == className) {
    var uri = c.enclosingLibrary.importUri;
    return uri.isScheme('dart') && uri.path == libraryName;
  }
  return false;
}

/// Gets the class of the instance referred to by metadata annotation [node].
///
/// For example:
///
/// - `@JS()` would return the "JS" class in "dart:_js_annotations".
/// - `@anonymous` would return the "_Anonymous" class in
/// "dart:_js_annotations".
///
/// This function works regardless of whether the CFE is evaluating constants,
/// or whether the constant is a field reference (such as "anonymous" above).
Class? getAnnotationClass(Expression node) {
  if (node is ConstantExpression) {
    var constant = node.constant;
    if (constant is InstanceConstant) return constant.classNode;
  } else if (node is ConstructorInvocation) {
    return node.target.enclosingClass;
  } else if (node is StaticGet) {
    var type = node.target.getterType;
    if (type is InterfaceType) return type.classNode;
  }
  return null;
}

/// Returns true if [name] is an operator method that is available on primitive
/// types (`int`, `double`, `num`, `String`, `bool`).
///
/// This does not include logical operators that cannot be user-defined
/// (`!`, `&&` and `||`).
bool isOperatorMethodName(String name) {
  switch (name) {
    case '==':
    case '~':
    case '^':
    case '|':
    case '&':
    case '>>':
    case '<<':
    case '>>>':
    case '+':
    case 'unary-':
    case '-':
    case '*':
    case '/':
    case '~/':
    case '>':
    case '<':
    case '>=':
    case '<=':
    case '%':
      return true;
  }
  return false;
}

bool isFromEnvironmentInvocation(CoreTypes coreTypes, StaticInvocation node) {
  var target = node.target;
  return node.isConst &&
      target.name.text == 'fromEnvironment' &&
      target.enclosingLibrary == coreTypes.coreLibrary;
}

List<Class> getSuperclasses(Class? c) {
  var result = <Class>[];
  var visited = HashSet<Class>();
  while (c != null && visited.add(c)) {
    for (var m = c.mixedInClass; m != null; m = m.mixedInClass) {
      result.add(m);
    }
    var superclass = c.superclass;
    if (superclass == null) break;
    result.add(superclass);
    c = superclass;
  }
  return result;
}

List<Class> getImmediateSuperclasses(Class c) {
  var result = <Class>[];
  var m = c.mixedInClass;
  if (m != null) result.add(m);
  var s = c.superclass;
  if (s != null) result.add(s);
  return result;
}

Expression? getInvocationReceiver(InvocationExpression node) {
  if (node is InstanceInvocation) {
    return node.receiver;
  } else if (node is DynamicInvocation) {
    return node.receiver;
  } else if (node is FunctionInvocation) {
    return node.receiver;
  } else if (node is LocalFunctionInvocation) {
    return VariableGet(node.variable);
  }
  return null;
}

bool isInlineJS(Member e) =>
    e is Procedure && _isProcedureFromForeignHelper('JS', e);

/// Returns `true` if [p] is the procedure named [name] from the
/// 'dart:_foreign_helper' library.
bool _isProcedureFromForeignHelper(String name, Procedure p) =>
    p.name.text == name &&
    p.enclosingLibrary.importUri.toString() == 'dart:_foreign_helper';

/// Whether the parameter [p] is covariant (either explicitly `covariant` or
/// implicitly due to generics) and needs a check for soundness.
bool isCovariantParameter(VariableDeclaration p) {
  return p.isCovariantByDeclaration || p.isCovariantByClass;
}

/// Whether the field [p] is covariant (either explicitly `covariant` or
/// implicitly due to generics) and needs a check for soundness.
bool isCovariantField(Field f) {
  return f.isCovariantByDeclaration || f.isCovariantByClass;
}

/// Returns true iff this factory constructor just throws [UnsupportedError]/
///
/// `dart:html` has many of these.
bool isUnsupportedFactoryConstructor(Procedure node) {
  if (node.name.isPrivate && node.enclosingLibrary.importUri.isScheme('dart')) {
    var body = node.function.body;
    if (body is Block) {
      var statements = body.statements;
      if (statements.length == 1) {
        var statement = statements[0];
        if (statement is ExpressionStatement) {
          var expr = statement.expression;
          if (expr is Throw) {
            var error = expr.expression;

            // HTML adds a lot of private constructors that are unreachable.
            // Skip these.
            return isBuiltinAnnotation(error, 'core', 'UnsupportedError');
          }
        }
      }
    }
  }
  return false;
}

/// Gets the real supertype of [c] and the list of [mixins] in reverse
/// application order (mixins will appear before ones they override).
///
/// This is used to ignore synthetic mixin application classes.
///
// TODO(jmesserly): consider replacing this with Kernel's mixin unrolling
Class getSuperclassAndMixins(Class c, List<Class> mixins) {
  assert(mixins.isEmpty);
  assert(c.superclass != null);

  var mixedInClass = c.mixedInClass;
  if (mixedInClass != null) mixins.add(mixedInClass);

  var sc = c.superclass!;
  for (; sc.isAnonymousMixin; sc = sc.superclass!) {
    mixedInClass = sc.mixedInClass;
    if (mixedInClass != null) mixins.add(sc.mixedInClass!);
  }
  return sc;
}

/// Returns true if a switch statement contains any continues with a label.
bool hasLabeledContinue(SwitchStatement node) {
  var visitor = LabelContinueFinder();
  node.accept(visitor);
  return visitor.found;
}

class LabelContinueFinder extends RecursiveVisitor<void> {
  var found = false;

  void visit(Statement? s) {
    if (!found && s != null) s.accept(this);
  }

  @override
  void visitContinueSwitchStatement(ContinueSwitchStatement node) =>
      found = true;
}

/// Whether [member] is declared native, as in:
///
///    void foo() native;
///
/// This syntax is only allowed in sdk libraries and native tests.
bool isNative(Member member) =>
    // The CFE represents `native` members with the `external` bit and with an
    // internal @ExternalName annotation as a marker.
    member.isExternal && member.annotations.any(_isNativeMarkerAnnotation);

bool _isNativeMarkerAnnotation(Expression annotation) {
  if (annotation is ConstantExpression) {
    var constant = annotation.constant;
    if (constant is InstanceConstant &&
        constant.classNode.name == 'ExternalName' &&
        _isDartInternal(constant.classNode.enclosingLibrary.importUri)) {
      return true;
    }
  }
  return false;
}

bool _isDartInternal(Uri uri) =>
    uri.isScheme('dart') && uri.path == '_internal';

/// Collects all `TypeParameter`s from the `TypeParameterType`s present in the
/// visited `DartType`.
class TypeParameterFinder extends RecursiveVisitor<void> {
  final _found = < /* TypeParameter | StructuralParameter */ Object>{};
  static TypeParameterFinder? _instance;

  TypeParameterFinder._();
  factory TypeParameterFinder.instance() {
    if (_instance != null) return _instance!;
    return TypeParameterFinder._();
  }

  Set< /* TypeParameter | StructuralParameter */ Object> find(DartType type) {
    _found.clear();
    type.accept(this);
    return _found;
  }

  @override
  void visitTypeParameterType(TypeParameterType node) =>
      _found.add(node.parameter);

  @override
  void visitStructuralParameterType(StructuralParameterType node) =>
      _found.add(node.parameter);
}

/// Collects [InterfaceType] nodes that appear in in a DartType.
class InterfaceTypeExtractor extends RecursiveVisitor<DartType> {
  final Set<InterfaceType> _found = {};

  @override
  void visitInterfaceType(InterfaceType node) {
    _found.add(node);
    node.visitChildren(this);
  }

  /// Returns all [InterfaceType]s that appear in [type].
  Iterable<InterfaceType> extract(DartType type) {
    type.accept(this);
    return _found;
  }
}

class ExtensionTypeEraser extends ReplacementVisitor {
  const ExtensionTypeEraser();

  /// Erases all `ExtensionType` nodes found in [type].
  DartType erase(DartType type) =>
      type.accept1(this, Variance.unrelated) ?? type;

  @override
  DartType? visitExtensionType(ExtensionType node, int variance) =>
      node.extensionTypeErasure.accept1(this, Variance.unrelated) ??
      node.extensionTypeErasure;
}

/// Replaces [VariableGet] nodes with a different expression defined by a
/// replacement map.
class VariableGetReplacer extends Transformer {
  final Map<VariableDeclaration, Expression> _replacements;

  VariableGetReplacer(this._replacements);

  @override
  TreeNode visitVariableGet(VariableGet node) {
    var replacement = _replacements[node.variable];
    return replacement ?? node;
  }
}

/// Tests a [StaticInvocation] node to determine if it would be safe to inline.
///
/// Each static invocation should be inspected individually as this class only
/// inspects the body of a given invocation target, and does not recurse
/// transitively into the bodies of other invocations it finds.
///
/// The determination of what is safe to inline is specifically targeting simple
/// methods in the dart:_rti library and has not been validated to use as an
/// inliner for static methods from any other libraries. Instead of inlining by
/// introducing let variables that preserve the evaluation order of the call,
/// only code where it is safe to replace the argument of the call at the
/// place where it used is considered suitable.
///
/// The body of the target method may only contain simple expressions known to
/// have no side-effects like null, bool or string literals, constants, enum
/// values, and variable accesses. Additionally some static invocations from the
/// runtime libraries are permitted in the body when they have been manually
/// inspected for side effects and annotated as safe with
/// `@pragma('ddc:trust-inline`). After the last method argument has been used,
/// this restriction is weakened to allow any static invocations to appear.
class BasicInlineTester extends TreeVisitorDefault<bool> {
  /// The constants used to access constant evaluation for annotations.
  final DevCompilerConstants _constants;

  /// The order that the arguments are expected to used in the body of the
  /// function for it to be considered safe for inlining.
  ///
  /// This is essential to preserve the execution order of the expressions
  /// passed as arguments.
  List<VariableDeclaration>? _expectedArgumentOrder;

  /// The position in [_expectedArgumentOrder] to begin looking for the next
  /// used argument.
  int _nextArgIndex = 0;

  /// Returns `true` if uses of all the expected arguments have already been
  /// seen by the visitor.
  bool get _allArgumentsUsed => _nextArgIndex >= _expectedArgumentOrder!.length;

  BasicInlineTester(this._constants);

  /// Returns `true` when [possibleInline] is considered simple enough to
  /// be safe to inline.
  ///
  /// The considerations for inlining are designed specifically to target select
  /// invocations in the dart:_rti library.
  bool canInline(FunctionNode possibleInline) {
    if (possibleInline.namedParameters.isNotEmpty ||
        possibleInline.typeParameters.isNotEmpty ||
        possibleInline.positionalParameters.length !=
            possibleInline.requiredParameterCount) {
      // Only consider functions with required positional arguments.
      return false;
    }
    final body = possibleInline.body;
    // No code available here to inline.
    if (body == null) return false;

    _expectedArgumentOrder = possibleInline.positionalParameters;
    _nextArgIndex = 0;
    // Important to note that the static invocation being considered for inline
    // is not visited. Instead the body of the target function being invoked is
    // visited to determine if inlining is feasible. Any other static
    // invocations appearing within that body *will* be visited.
    final result = body.accept(this);
    // Avoid retaining any of the arguments after returning.
    _expectedArgumentOrder = null;
    return result;
  }

  /// Returns `true` when [node] is annotated with
  /// `@pragma('ddc:trust-inline`)`.
  bool _hasTrustInlinePragma(NamedNode node) {
    var annotation = findAnnotation(node, (e) {
      if (!isBuiltinAnnotation(e, 'core', 'pragma')) return false;
      var name = _constants.getFieldValueFromAnnotation(e, 'name') as String?;
      return name == 'ddc:trust-inline';
    });
    return annotation != null;
  }

  @override
  bool defaultTreeNode(Node _) => false;

  @override
  bool visitReturnStatement(ReturnStatement node) {
    var returnExpression = node.expression;
    return returnExpression == null ? false : returnExpression.accept(this);
  }

  @override
  bool visitBlock(Block node) {
    if (node.statements.length != 1) return false;
    return node.statements.single.accept(this);
  }

  @override
  bool visitStaticInvocation(StaticInvocation node) {
    // Reaching this visitor means that a static invocation appears in the body
    // of the function being evaluated for inlining.
    var positionalArgs = node.arguments.positional;
    if (isInlineJS(node.target)) {
      // Ensure JS expressions do not span multiple statements. Since these are
      // inlined elsewhere we don't want to accidentally combine multiple
      // Javascript statements into a position where they don't belong. Instead
      // of inspecting if it is valid, just reject any source templates that
      // contain ';' characters.
      var codeLiteral = positionalArgs[1];
      String? code;
      if (codeLiteral is StringLiteral) {
        code = codeLiteral.value;
      } else if (codeLiteral is ConstantExpression) {
        var constant = codeLiteral.constant;
        if (constant is StringConstant) {
          code = constant.value;
        }
      }
      if (code == null || code.contains(';')) return false;
    }
    // Inspect the arguments.
    for (var argument in positionalArgs) {
      if (!argument.accept(this)) return false;
    }
    // While all of the uses of the arguments are still being discovered,
    // only allow additional static invocations explicitly annotated as
    // trusted. This prevents inlining a static invocation that could
    // change the evaluation order of the expressions passed as arguments.
    // Example:
    // ```
    // echo(s) {
    //   print(s);
    //   return s;
    // }
    //
    // dangerous(arg1, arg2) {
    //   return fn(arg1, echo('third'), arg2);
    // }
    // ```
    // Calls to `dangerous()` should not be inlined without let variables
    // because the expression evaluation order would be disrupted:
    // ```
    // dangerous(echo('first'), echo('second'));
    //    |   |
    //    V   V
    // fn(echo('first'), echo('third'), echo('second')) // INVALID!
    return _allArgumentsUsed || _hasTrustInlinePragma(node.target);
  }

  @override
  bool visitBoolLiteral(BoolLiteral _) => true;

  @override
  bool visitNullLiteral(NullLiteral _) => true;

  @override
  bool visitStringLiteral(StringLiteral _) => true;

  @override
  bool visitConstantExpression(ConstantExpression _) => true;

  @override
  bool visitVariableGet(VariableGet node) {
    // The variable is an argument of the function to be inlined. Verify it
    // appears in an order consistent with the order the arguments appeared
    // in the call.
    final location =
        _expectedArgumentOrder!.indexOf(node.variable, _nextArgIndex);
    // Either the variable isn't one of the expected arguments at all, or it is
    // appearing out of the expected order.
    if (location == -1) return false;
    // Advance the start of the expected range past the variable just found to
    // ensure the variable can only be used once.
    _nextArgIndex = location + 1;
    return true;
  }

  @override
  bool visitField(Field node) => node.isEnumElement;

  @override
  bool visitStaticGet(StaticGet node) {
    return node.target.accept(this);
  }
}
