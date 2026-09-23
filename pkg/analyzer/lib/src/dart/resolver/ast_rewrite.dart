// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/scope.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/resolver/scope_context.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer/src/error/listener.dart';

/// Handles possible rewrites of AST.
///
/// Ambiguous parsed expressions retain their syntax until lexical binding can
/// select their semantic role. For example, `a.b()` can denote a constructor,
/// a method, or a callable property. This rewriter lowers identified roles to
/// canonical V2 nodes and prepares receiver invocations for member resolution.
///
/// The public methods of this class form a complete accounting of possible
/// node replacements.
class AstRewriter {
  final DiagnosticReporter _diagnosticReporter;
  final ScopeContext _scopeContext;
  final LibraryElementImpl _libraryElement;

  AstRewriter(
    this._diagnosticReporter,
    this._scopeContext,
    this._libraryElement,
  );

  AssignmentTargetImpl parsedAssignmentTarget(
    Scope nameScope,
    ParsedAssignmentTargetImpl node,
  ) {
    AssignmentTargetImpl target;
    switch (node) {
      case ParsedUnqualifiedNameAssignmentTargetImpl(:var name):
        target = UnqualifiedNameAssignmentTargetImpl(name: name);
      case ParsedNameAccessAssignmentTargetImpl(
        :var operand,
        :var operator,
        :var name,
      ):
        if (operand is ParsedTypeArgumentsImpl) {
          if (_parsedConstructorType(nameScope, operand)
              case var typeReference?) {
            target = InvalidExpressionAssignmentTargetImpl(
              expression: ConstructorTearOffImpl(
                typeReference: typeReference,
                selector: ConstructorSelectorImpl.v2(
                  period: operator,
                  name2: name,
                ),
              ),
            );
            break;
          }
        }
        NamedReceiverImpl receiver;
        if (operand is ParsedUnqualifiedNameImpl) {
          var lookup = nameScope.lookup(operand.name.lexeme);
          if (lookup.getter case PrefixElement prefix) {
            if (operator.type == TokenType.PERIOD) {
              target = ImportPrefixedAssignmentTargetImpl(
                importPrefix: ImportPrefixReferenceImpl(
                  name: operand.name,
                  period: operator,
                )..element = prefix,
                name: name,
              );
              break;
            }
            // As for reads, invalid prefix syntax still records import usage.
            prefix.scope.lookup(name.lexeme);
          }
          receiver = _parsedNameReceiver(
            null,
            operand.name,
            lookup,
            hasSelector: true,
          );
        } else {
          receiver = _parsedNestedReceiver(
            nameScope,
            operand,
            head: _parsedReceiverHead(operand),
            hasSelector: true,
          );
        }
        target = ReceiverPropertyAssignmentTargetImpl(
          receiver: receiver,
          operator: operator,
          name: name,
        );
    }
    node.replaceWith(target);
    return target;
  }

  /// Rewrites [node], or prepares a receiver invocation for member lookup.
  ParsedExpressionResult parsedExpression(
    Scope nameScope,
    ParsedExpressionImpl node,
  ) {
    if (node is ParsedCascadeNameImpl) {
      var expression = CascadePropertyExtractionImpl(name: node.name);
      node.replaceWith(expression);
      return RewrittenParsedExpression._(expression);
    }
    if (node is ParsedDotShorthandNameImpl) {
      var expression = DotShorthandNameExpressionImpl(
        period: node.period,
        name: node.name,
      );
      node.replaceWith(expression);
      return RewrittenParsedExpression._(expression);
    }
    if (node is ParsedValueArgumentsImpl &&
        node.cascadeInvocationParts != null) {
      return PreparedCascadeInvocation(node);
    }
    if (node is ParsedValueArgumentsImpl &&
        node.dotShorthandInvocationParts != null) {
      return PreparedDotShorthandInvocation(node);
    }
    var constructorSelector = switch (node) {
      ParsedNameAccessImpl selector => selector,
      ParsedValueArgumentsImpl(operand: ParsedNameAccessImpl selector) =>
        selector,
      _ => null,
    };
    if (constructorSelector?.operand case ParsedTypeArgumentsImpl qualifier) {
      if (_parsedConstructorType(
            nameScope,
            qualifier,
            invocation: node is ParsedValueArgumentsImpl ? node : null,
          )
          case var typeReference?) {
        var selector = ConstructorSelectorImpl.v2(
          period: constructorSelector!.operator,
          name2: constructorSelector.name,
        );
        var expression = node is ParsedValueArgumentsImpl
            ? ConstructorInvocationImpl(
                keyword: null,
                constructorReference: ConstructorReference2Impl(
                  typeReference: typeReference,
                  selector: selector,
                ),
                argumentList: node.argumentList,
                typeArguments: null,
              )
            : ConstructorTearOffImpl(
                typeReference: typeReference,
                selector: selector,
              );
        node.replaceWith(expression);
        return RewrittenParsedExpression._(expression);
      }
    }
    if (node is ParsedTypeArgumentsImpl) {
      var expression = _parsedTypeArguments(nameScope, node);
      node.replaceWith(expression);
      return RewrittenParsedExpression._(expression);
    }
    if (_prepareReceiverInvocation(nameScope, node) case var result?) {
      if (result case RewrittenParsedExpression(:var expression)) {
        node.replaceWith(expression);
      }
      return result;
    }
    var invocationParts = switch (node) {
      ParsedValueArgumentsImpl(
        operand: ParsedUnqualifiedNameImpl(:var name),
        :var argumentList,
      ) =>
        (
          name: name,
          access: null,
          typeArguments: null,
          argumentList: argumentList,
        ),
      ParsedValueArgumentsImpl(
        operand: ParsedTypeArgumentsImpl(
          operand: ParsedUnqualifiedNameImpl(:var name),
          :var typeArguments,
        ),
        :var argumentList,
      ) =>
        (
          name: name,
          access: null,
          typeArguments: typeArguments,
          argumentList: argumentList,
        ),
      ParsedValueArgumentsImpl(
        operand: ParsedNameAccessImpl(
              operand: ParsedUnqualifiedNameImpl(:var name),
            ) &&
            var access,
        :var argumentList,
      ) =>
        (
          name: name,
          access: access,
          typeArguments: null,
          argumentList: argumentList,
        ),
      ParsedValueArgumentsImpl(
        operand: ParsedTypeArgumentsImpl(
          operand: ParsedNameAccessImpl(
                operand: ParsedUnqualifiedNameImpl(:var name),
              ) &&
              var access,
          :var typeArguments,
        ),
        :var argumentList,
      ) =>
        (
          name: name,
          access: access,
          typeArguments: typeArguments,
          argumentList: argumentList,
        ),
      _ => null,
    };
    if (invocationParts case (
      :var name,
      :var access,
      :var typeArguments,
      :var argumentList,
    )) {
      var lookup = nameScope.lookup(name.lexeme);
      ImportPrefixReferenceImpl? importPrefix;
      if (access != null) {
        var prefix = lookup.getter;
        // Non-prefix receivers were handled by _prepareReceiverInvocation.
        prefix as PrefixElement;
        if (access.operator.type != TokenType.PERIOD) {
          _diagnosticReporter.report(
            diag.prefixIdentifierNotFollowedByDot
                .withArguments(name: name.lexeme)
                .at(name),
          );
        }
        importPrefix = ImportPrefixReferenceImpl(
          name: name,
          period: access.operator,
        )..element = prefix;
        name = access.name;
        lookup = prefix.scope.lookup(name.lexeme);
      }
      var element = lookup.getter;
      ExpressionImpl expression;
      if (element is InterfaceElement ||
          element is TypeAliasElement && element.aliasedType is InterfaceType) {
        expression = ConstructorInvocationImpl(
          keyword: null,
          constructorReference: ConstructorReference2Impl(
            typeReference: ConstructorTypeReferenceImpl(
              importPrefix: importPrefix,
              name: name,
              typeArguments: typeArguments,
            ),
            selector: null,
          ),
          argumentList: argumentList,
          typeArguments: null,
        );
      } else if (element is ExtensionElementImpl) {
        var receiver = ExtensionOverride2Impl(
          importPrefix: importPrefix,
          name: name,
          element: element,
          typeArguments: typeArguments,
          argumentList: argumentList,
        );
        return RewrittenParsedExpression._(
          _replaceWithExtensionOverride(node, receiver),
        );
      } else if (importPrefix != null) {
        expression = ImportPrefixedFunctionInvocationImpl(
          importPrefix: importPrefix,
          name: name,
          typeArguments: typeArguments,
          argumentList: argumentList,
        );
      } else {
        expression = UnqualifiedFunctionInvocationImpl(
          name: name,
          typeArguments: typeArguments,
          argumentList: argumentList,
        )..scopeLookupResult = lookup;
      }
      node.replaceWith(expression);
      return RewrittenParsedExpression._(expression);
    }
    var head = _parsedReceiverHead(node);
    var expression =
        _parsedNestedReceiver(nameScope, node, head: head, hasSelector: false)
            as ExpressionImpl;
    node.replaceWith(expression);
    return RewrittenParsedExpression._(expression);
  }

  /// Possibly rewrites [node] as a [ConstructorTearOff].
  ///
  /// Code such as `List.filled;` is parsed as (an [ExpressionStatement] with) a
  /// [PrefixedIdentifier] with 'prefix' of `List` and 'identifier' of `filled`.
  /// The [PrefixedIdentifier] may need to be rewritten as a
  /// [ConstructorTearOff].
  AstNode prefixedIdentifier(Scope nameScope, PrefixedIdentifierImpl node) {
    var parent = node.parent2;
    if (parent is AnnotationImpl) {
      // An annotations which is a const constructor invocation can initially be
      // represented with a [PrefixedIdentifier]. Do not rewrite such nodes.
      return node;
    }
    if (parent is CommentReferenceImpl) {
      // TODO(srawlins): This probably should be allowed to be rewritten to a
      // [ConstructorTearOff] at some point.
      return node;
    }
    if (parent is AssignmentExpressionImpl && parent.leftHandSide2 == node) {
      // A constructor cannot be assigned to, in some expression like
      // `C.new = foo`; do not rewrite.
      return node;
    }
    // Only rewrite value occurrences here. Assignment targets are specialized
    // separately by ResolutionVisitor once their qualifier is known.
    if (node.identifier.inSetterContext()) {
      return node;
    }
    var identifier = node.identifier;
    if (identifier.isSynthetic) {
      // This isn't a constructor tear-off.
      return node;
    }
    var prefix = node.prefix;
    var prefixElement = nameScope.lookup(prefix.name).getter;
    if (_isTypeLiteralContext(parent, node)) {
      if (prefixElement is PrefixElement) {
        var element = prefixElement.scope.lookup(node.identifier.name).getter;
        switch (element) {
          case DynamicElementImpl():
          case InterfaceElementImpl():
          case NeverElementImpl():
          case TypeAliasElementImpl():
            return _toTypeLiteral(node);
        }
      }
    }

    if (prefixElement is InterfaceElement) {
      // Example:
      //     class C { C.named(); }
      //     C.named
      return _toConstructorTearOff_prefixed(
        node: node,
        classElement: prefixElement,
      );
    } else if (prefixElement is TypeAliasElement) {
      var aliasedType = prefixElement.aliasedType;
      if (aliasedType is InterfaceType) {
        // Example:
        //     class C { C.named(); }
        //     typedef X = C;
        //     X.named
        return _toConstructorTearOff_prefixed(
          node: node,
          classElement: aliasedType.element,
        );
      }
    }

    if (prefixElement is PrefixElement && _isTypeLiteralContext(parent, node)) {
      var expression = ImportPrefixedNameExpressionImpl(
        importPrefix: ImportPrefixReferenceImpl(
          name: node.prefix.token,
          period: node.period,
        )..element = prefixElement,
        name: node.identifier.token,
      );
      node.replaceWith(expression);
      return expression;
    }
    return node;
  }

  /// Possibly rewrites [node] as a [ConstructorTearOff].
  ///
  /// Code such as `async.Future.value;` is parsed as (an [ExpressionStatement]
  /// with) a [PropertyAccess] with a 'target' of [PrefixedIdentifier] (with
  /// 'prefix' of `List` and 'identifier' of `filled`) and a 'propertyName' of
  /// `value`. The [PropertyAccess] may need to be rewritten as a
  /// [ConstructorTearOff].
  AstNode propertyAccess(Scope nameScope, PropertyAccessImpl node) {
    if (node.isCascaded) {
      // For example, `List..filled`: this is a property access on an instance
      // `Type`.
      return node;
    }
    if (node.parent2 is CommentReferenceImpl) {
      // TODO(srawlins): This probably should be allowed to be rewritten to a
      // [ConstructorTearOff] at some point.
      return node;
    }
    var receiver = node.target2!;

    IdentifierImpl receiverIdentifier;
    TypeArgumentListImpl? typeArguments;
    if (receiver is PrefixedIdentifierImpl) {
      receiverIdentifier = receiver;
    } else if (receiver is FunctionReferenceImpl) {
      // A [ConstructorTearOff] with explicit type arguments is initially
      // parsed as a [PropertyAccess] with a [FunctionReference] target; for
      // example: `List<int>.filled` or `core.List<int>.filled`.
      var function = receiver.function2;
      if (function is! IdentifierImpl) {
        // If [receiverIdentifier] is not an Identifier then [node] is not a
        // ConstructorTearOff.
        return node;
      }
      receiverIdentifier = function;
      typeArguments = receiver.typeArguments;
    } else {
      // If the receiver is not (initially) a prefixed identifier or a function
      // reference, then [node] is not a constructor tear-off.
      return node;
    }

    Element? element;
    if (receiverIdentifier is SimpleIdentifierImpl) {
      element = nameScope.lookup(receiverIdentifier.name).getter;
    } else if (receiverIdentifier is PrefixedIdentifierImpl) {
      var prefixElement = nameScope
          .lookup(receiverIdentifier.prefix.name)
          .getter;
      if (prefixElement is PrefixElement) {
        element = prefixElement.scope
            .lookup(receiverIdentifier.identifier.name)
            .getter;
      } else {
        // This expression is something like `foo.List<int>.filled` where `foo`
        // is not an import prefix.
        // TODO(srawlins): Tease out a `null` prefixElement from others for
        // specific errors.
        return node;
      }
    }

    if (element is InterfaceElement) {
      // Example:
      //     class C<T> { C.named(); }
      //     C<int>.named
      return _toConstructorTearOff_propertyAccess(
        node: node,
        receiver: receiverIdentifier,
        typeArguments: typeArguments,
        classElement: element,
      );
    } else if (element is TypeAliasElement) {
      var aliasedType = element.aliasedType;
      if (aliasedType is InterfaceType) {
        // Example:
        //     class C<T> { C.named(); }
        //     typedef X<T> = C<T>;
        //     X<int>.named
        return _toConstructorTearOff_propertyAccess(
          node: node,
          receiver: receiverIdentifier,
          typeArguments: typeArguments,
          classElement: aliasedType.element,
        );
      }
    }

    // If [receiverIdentifier] is an Identifier, but could not be resolved to
    // an Element, we cannot assume [node] is a ConstructorTearOff.
    //
    // TODO(srawlins): However, take an example like `Lisst<int>.filled;`
    // (where 'Lisst' does not resolve to any element). Possibilities include:
    // the user tried to write a TypeLiteral or a FunctionReference, then access
    // a property on that (these include: hashCode, runtimeType, tearoff of
    // toString, and extension methods on Type); or the user tried to write a
    // ConstructorTearOff. It seems much more likely that the user is trying to
    // do the latter. Consider doing the work so that the user gets an error in
    // this case about `Lisst` not being a type, or `Lisst.filled` not being a
    // known constructor.
    return node;
  }

  AstNode simpleIdentifier(Scope nameScope, SimpleIdentifierImpl node) {
    if (node.isSynthetic) {
      return node;
    }
    var parent = node.parent2;
    if (parent is ReceiverPropertyAssignmentTargetImpl &&
        identical(parent.receiver, node) &&
        nameScope.lookup(node.name).getter is PrefixElement) {
      // Import-prefixed read/write targets currently retain their legacy
      // prefix receiver until they have a dedicated canonical target node.
      return node;
    }
    if (_isTypeLiteralContext(parent, node)) {
      var element = nameScope.lookup(node.name).getter;
      switch (element) {
        case DynamicElementImpl():
        case InterfaceElementImpl():
        case NeverElementImpl():
        case TypeAliasElementImpl():
        case TypeParameterElementImpl():
          return _toTypeLiteral(node);
      }

      var expression = UnqualifiedNameExpressionImpl(name: node.token);
      node.replaceWith(expression);
      return expression;
    }

    return node;
  }

  bool _isTypeLiteralContext(AstNode? parent, ExpressionImpl node) {
    if (parent is AstNodeImpl) {
      return parent.isInValueExpressionSlot(node);
    }
    return false;
  }

  Element? _lookupReceiverName(Scope nameScope, String name) {
    var element = nameScope.lookup(name).getter;
    if (element == null) {
      if (_scopeContext.enclosingInstanceElement
          case InterfaceElementImpl enclosingElement) {
        element = enclosingElement.inheritanceManager.getMember(
          enclosingElement,
          Name(_libraryElement.uri, name),
        );
      }
    }
    return element;
  }

  /// Binds the type-shaped qualifier in `C<T>.name` or `p.C<T>.name`.
  ///
  /// Written type arguments make this constructor syntax even when the named
  /// constructor is missing or a function-type alias cannot have constructors.
  /// Function values retain their instance selector interpretation.
  ConstructorTypeReferenceImpl? _parsedConstructorType(
    Scope nameScope,
    ParsedTypeArgumentsImpl qualifier, {
    ParsedValueArgumentsImpl? invocation,
  }) {
    Token name;
    ImportPrefixReferenceImpl? importPrefix;
    Element? element;
    var constructorTearoffsEnabled = _libraryElement.featureSet.isEnabled(
      Feature.constructor_tearoffs,
    );
    switch (qualifier.operand) {
      case ParsedUnqualifiedNameImpl(name: var typeName):
        name = typeName;
        element = _lookupReceiverName(nameScope, name.lexeme);
      case ParsedNameAccessImpl(
            operand: ParsedUnqualifiedNameImpl(name: var prefixName),
            :var operator,
            name: var typeName,
          )
          when operator.type == TokenType.PERIOD:
        var prefix = nameScope.lookup(prefixName.lexeme).getter;
        if (prefix is! PrefixElement) {
          if (invocation != null && !constructorTearoffsEnabled) {
            _diagnosticReporter.report(
              diag.sdkVersionConstructorTearoffs.at(invocation),
            );
          }
          return null;
        }
        name = typeName;
        element = prefix.scope.lookup(name.lexeme).getter;
        importPrefix = ImportPrefixReferenceImpl(
          name: prefixName,
          period: operator,
        )..element = prefix;
      default:
        return null;
    }
    if (element is! InterfaceElement &&
        !(element is TypeAliasElement &&
            (element.aliasedType is InterfaceType ||
                element.aliasedType is FunctionType))) {
      if (invocation == null) return null;
      if (element is ExecutableElement || element is VariableElement) {
        if (constructorTearoffsEnabled) return null;
        // The parser allows this constructor-shaped syntax in old language
        // versions. Preserve their function-declaration interpretation and
        // constructor recovery for variables and imported accessors.
        if (element is ExecutableElement &&
            (importPrefix == null || element is TopLevelFunctionElement)) {
          _diagnosticReporter.report(
            diag.sdkVersionConstructorTearoffs.at(invocation),
          );
          return null;
        }
      }
      // An unknown type-shaped call retains constructor recovery. A property
      // read alone does not commit to a constructor without a known type.
    }
    return ConstructorTypeReferenceImpl(
      importPrefix: importPrefix,
      name: name,
      typeArguments: qualifier.typeArguments,
    );
  }

  NamedReceiverImpl _parsedNestedReceiver(
    Scope nameScope,
    InstanceReceiverImpl root, {
    required InstanceReceiverImpl head,
    required bool hasSelector,
  }) {
    if (head is ParsedUnqualifiedNameImpl) {
      head.scopeLookupResult = nameScope.lookup(head.name.lexeme);
    }
    if (head is ParsedTypeArgumentsImpl && !identical(head, root)) {
      if (_parsedConstructorType(nameScope, head) case var typeReference?) {
        var selector = head.parent2 as ParsedNameAccessImpl;
        var expression = ConstructorTearOffImpl(
          typeReference: typeReference,
          selector: ConstructorSelectorImpl.v2(
            period: selector.operator,
            name2: selector.name,
          ),
        );
        selector.replaceWith(expression);
        if (identical(selector, root)) return expression;
        head = expression;
      }
    }
    return _boundParsedReceiver(root, head: head, hasSelector: hasSelector);
  }

  /// Classifies a standalone type application before resolving its operand as
  /// a value. Constructor qualifiers are lowered with their enclosing selector
  /// and do not pass through this standalone path.
  ExpressionImpl _parsedTypeArguments(
    Scope nameScope,
    ParsedTypeArgumentsImpl node,
  ) {
    var operand = node.operand;
    Token? name;
    ImportPrefixReferenceImpl? importPrefix;
    Element? element;
    if (operand is ParsedUnqualifiedNameImpl) {
      name = operand.name;
      element = nameScope.lookup(name.lexeme).getter;
    } else if (operand case ParsedNameAccessImpl(
      operand: ParsedUnqualifiedNameImpl(name: var prefixName),
      :var operator,
      name: var selectorName,
    ) when operator.type == TokenType.PERIOD) {
      if (nameScope.lookup(prefixName.lexeme).getter
          case PrefixElement prefix) {
        name = selectorName;
        element = prefix.scope.lookup(name.lexeme).getter;
        importPrefix = ImportPrefixReferenceImpl(
          name: prefixName,
          period: operator,
        )..element = prefix;
      }
    }
    if (element is InterfaceElement ||
        element is TypeAliasElement ||
        element is DynamicElementImpl ||
        element is NeverElementImpl ||
        element is TypeParameterElementImpl) {
      return TypeLiteralImpl(
        type: NamedTypeImpl(
          importPrefix: importPrefix,
          name: name!,
          typeArguments: node.typeArguments,
          question: null,
        ),
      );
    }
    if (operand is ParsedNameAccessImpl) {
      var result = parsedExpression(nameScope, operand);
      // Rewriting a name access produces an expression. A bare extension
      // override is produced only when rewriting value arguments.
      operand =
          (result as RewrittenParsedExpression).expression as ExpressionImpl;
      // As with calls, an uninstantiated function alias receives members of
      // Type, rather than static members of its aliased function type.
      if (operand case ReceiverPropertyExtractionImpl(
        receiver: StaticQualifierImpl(
              element: TypeAliasElement(aliasedType: FunctionType()),
            ) &&
            var receiver,
      )) {
        operand.receiver = _parsedNameExpression(
          receiver.importPrefix,
          receiver.name,
          receiver.element,
        );
      }
    }
    return FunctionInstantiationImpl(
      operand: operand,
      typeArguments: node.typeArguments,
    );
  }

  /// Binds the receiver of a named call and lowers constructor calls.
  ///
  /// Other calls keep their parsed selector and arguments until type-based
  /// lookup distinguishes a method from a property whose value is invoked.
  /// Static qualifiers keep their bound parsed names because selector operands
  /// only accept expressions.
  ParsedExpressionResult? _prepareReceiverInvocation(
    Scope nameScope,
    ParsedExpressionImpl node,
  ) {
    if (node is! ParsedValueArgumentsImpl) return null;

    var parts = node.namedInvocationParts;
    if (parts == null) return null;
    var (:selector, :typeArguments) = parts;

    var head = _parsedReceiverHead(selector.operand);

    // Leave `p.f()` to import-prefixed call handling; `p` is not a value.
    if (selector.operand case ParsedUnqualifiedNameImpl(:var name)) {
      if (nameScope.lookup(name.lexeme).getter is PrefixElement) {
        return null;
      }
    }

    var receiver = _parsedNestedReceiver(
      nameScope,
      selector.operand,
      head: head,
      hasSelector: true,
    );
    // Uninstantiated function aliases can receive methods on Type. Preserve
    // this established invocation behavior independently of property recovery.
    if (receiver case StaticQualifierImpl(
      element: TypeAliasElement(aliasedType: FunctionType()),
    )) {
      receiver = _parsedNameExpression(
        receiver.importPrefix,
        receiver.name,
        receiver.element,
      );
    }
    if (receiver is StaticQualifierImpl && !selector.name.isSynthetic) {
      var interface = switch (receiver.element) {
        InterfaceElement element => element,
        TypeAliasElement(aliasedType: InterfaceType(:var element)) => element,
        _ => null,
      };
      var constructor = selector.name.lexeme == 'new'
          ? interface?.unnamedConstructor
          : interface?.getNamedConstructor(selector.name.lexeme);
      if (interface != null &&
          (constructor != null || selector.name.lexeme == 'new')) {
        if (typeArguments != null) {
          _diagnosticReporter.report(
            diag.wrongNumberOfTypeArgumentsConstructor
                .withArguments(
                  className: receiver.toSource(),
                  constructorName: selector.name.lexeme,
                )
                .at(typeArguments),
          );
        }
        return RewrittenParsedExpression._(
          ConstructorInvocationImpl(
            keyword: null,
            constructorReference: ConstructorReference2Impl(
              typeReference: ConstructorTypeReferenceImpl(
                importPrefix: receiver.importPrefix,
                name: receiver.name,
                typeArguments: receiver.importPrefix != null
                    ? typeArguments
                    : null,
              ),
              selector: ConstructorSelectorImpl.v2(
                period: selector.operator,
                name2: selector.name,
              ),
            ),
            typeArguments: receiver.importPrefix == null ? typeArguments : null,
            argumentList: node.argumentList,
          ),
        );
      }
    }
    if (receiver is ExpressionImpl) {
      selector.operand = receiver;
    }
    return PreparedReceiverInvocation._(
      receiver: receiver,
      typeArguments: typeArguments,
      valueArguments: node,
    );
  }

  AstNode _toConstructorTearOff_prefixed({
    required PrefixedIdentifierImpl node,
    required InterfaceElement classElement,
  }) {
    var name = node.identifier.name;
    var constructorElement = name == 'new'
        ? classElement.unnamedConstructor
        : classElement.getNamedConstructor(name);
    if (constructorElement == null) {
      return node;
    }

    var constructorTearOff = ConstructorTearOffImpl(
      typeReference: node.prefix.toConstructorTypeReference(
        typeArguments: null,
      ),
      selector: ConstructorSelectorImpl.v2(
        period: node.period,
        name2: node.identifier.token,
      ),
    );
    node.replaceWith(constructorTearOff);
    return constructorTearOff;
  }

  AstNode _toConstructorTearOff_propertyAccess({
    required PropertyAccessImpl node,
    required IdentifierImpl receiver,
    required TypeArgumentListImpl? typeArguments,
    required InterfaceElement classElement,
  }) {
    var name = node.propertyName.name;
    var constructorElement = name == 'new'
        ? classElement.unnamedConstructor
        : classElement.getNamedConstructor(name);
    if (constructorElement == null && typeArguments == null) {
      // If there is no constructor by this name, and no type arguments,
      // do not rewrite the node. If there _are_ type arguments (like
      // `prefix.C<int>.name`, then it looks more like a constructor tearoff
      // than anything else, so continue with the rewrite.
      return node;
    }

    var operator = node.operator;

    var constructorTearOff = ConstructorTearOffImpl(
      typeReference: receiver.toConstructorTypeReference(
        typeArguments: typeArguments,
      ),
      selector: ConstructorSelectorImpl.v2(
        period: operator,
        name2: node.propertyName.token,
      ),
    );
    node.replaceWith(constructorTearOff);
    return constructorTearOff;
  }

  TypeLiteralImpl _toTypeLiteral(IdentifierImpl node) {
    var result = TypeLiteralImpl(
      type: node.toNamedType(typeArguments: null, question: null),
    );
    node.replaceWith(result);
    return result;
  }

  /// Finishes interpreting a receiver whose lexical names have been bound.
  static NamedReceiverImpl receiverInvocationReceiver(
    ParsedValueArgumentsImpl node,
  ) {
    var root = node.namedInvocationParts!.selector.operand;
    return _boundParsedReceiver(
      root,
      head: _parsedReceiverHead(root),
      hasSelector: true,
    );
  }

  static NamedReceiverImpl _boundParsedReceiver(
    InstanceReceiverImpl root, {
    required InstanceReceiverImpl head,
    required bool hasSelector,
  }) {
    var node = head;
    NamedReceiverImpl receiver;
    if (node is ParsedUnqualifiedNameImpl) {
      var name = node.name;
      var lookup = node.scopeLookupResult!;
      ImportPrefixReferenceImpl? importPrefix;
      if (lookup.getter case PrefixElement prefix when !identical(node, root)) {
        var selector = node.parent2 as ParsedNameAccessImpl;
        var prefixedLookup = prefix.scope.lookup(selector.name.lexeme);
        if (selector.operator.type == TokenType.PERIOD) {
          importPrefix = ImportPrefixReferenceImpl(
            name: name,
            period: selector.operator,
          )..element = prefix;
          name = selector.name;
          lookup = prefixedLookup;
          node = selector;
        }
      }
      receiver = _parsedNameReceiver(
        importPrefix,
        name,
        lookup,
        hasSelector: hasSelector || !identical(node, root),
      );
    } else if (node is ParsedCascadeNameImpl) {
      receiver = CascadePropertyExtractionImpl(name: node.name);
    } else {
      // Nested call syntax and ordinary expressions use their own visitors,
      // including constructor and extension-override selection.
      receiver = node;
    }
    var parent = node.parent2;
    while (!identical(node, root)) {
      var selector = parent as ParsedNameAccessImpl;
      parent = selector.parent2;
      receiver = _parsedReceiverAccess(
        receiver,
        selector.operator,
        selector.name,
      );
      node = selector;
    }
    return receiver;
  }

  static ExpressionImpl _parsedNameExpression(
    ImportPrefixReferenceImpl? importPrefix,
    Token name,
    Element? element,
  ) {
    switch (element) {
      case DynamicElementImpl():
      case InterfaceElementImpl():
      case NeverElementImpl():
      case TypeAliasElementImpl():
      case TypeParameterElementImpl():
        return TypeLiteralImpl(
          type: NamedTypeImpl(
            importPrefix: importPrefix,
            name: name,
            typeArguments: null,
            question: null,
          ),
        );
      default:
        if (importPrefix != null) {
          return ImportPrefixedNameExpressionImpl(
            importPrefix: importPrefix,
            name: name,
          );
        }
        return UnqualifiedNameExpressionImpl(name: name);
    }
  }

  static NamedReceiverImpl _parsedNameReceiver(
    ImportPrefixReferenceImpl? importPrefix,
    Token name,
    ScopeLookupResult lookup, {
    required bool hasSelector,
  }) {
    var element = lookup.getter;
    if (hasSelector &&
        (element is InterfaceElement ||
            element is TypeAliasElement &&
                (element.aliasedType is InterfaceType ||
                    // Preserve invalid static access on function-type aliases,
                    // rather than selecting a member of Type.
                    element.aliasedType is FunctionType) ||
            element is ExtensionElement)) {
      return StaticQualifierImpl(importPrefix: importPrefix, name: name)
        ..element = element
        ..scopeLookupResult = lookup;
    }
    return _parsedNameExpression(importPrefix, name, element);
  }

  static NamedReceiverImpl _parsedReceiverAccess(
    NamedReceiverImpl receiver,
    Token operator,
    Token name,
  ) {
    if (receiver is StaticQualifierImpl) {
      var interfaceElement = switch (receiver.element) {
        InterfaceElement element => element,
        TypeAliasElement(aliasedType: InterfaceType(:var element)) => element,
        _ => null,
      };
      var constructor = name.lexeme == 'new'
          ? interfaceElement?.unnamedConstructor
          : interfaceElement?.getNamedConstructor(name.lexeme);
      if (constructor != null) {
        return ConstructorTearOffImpl(
          typeReference: ConstructorTypeReferenceImpl(
            importPrefix: receiver.importPrefix,
            name: receiver.name,
            typeArguments: null,
          ),
          selector: ConstructorSelectorImpl.v2(period: operator, name2: name),
        );
      }
    }
    return ReceiverPropertyExtractionImpl(
      receiver: receiver,
      operator: operator,
      name: name,
    );
  }

  static InstanceReceiverImpl _parsedReceiverHead(InstanceReceiverImpl root) {
    var head = root;
    while (head is ParsedNameAccessImpl) {
      head = head.operand;
    }
    return head;
  }

  /// Installs an override only after lookup has selected extension dispatch.
  /// Value and destination slots retain their own precise recovery nodes.
  static InstanceReceiverImpl _replaceWithExtensionOverride(
    ExpressionImpl node,
    ExtensionOverride2Impl receiver,
  ) {
    var parent = node.parent2;
    if (parent is InvalidExpressionAssignmentTargetImpl) {
      parent.replaceWith(
        InvalidExtensionOverrideAssignmentTargetImpl(
          extensionOverride: receiver,
        ),
      );
      return receiver;
    }
    if (parent is AssignmentExpressionImpl &&
        identical(parent.leftHandSide2, node)) {
      // For `=` or `??=`, the AST builder creates a DirectAssignmentImpl or
      // IfNullAssignmentImpl with an InvalidExpressionAssignmentTargetImpl,
      // which is handled above.
      assert(
        parent.operator.type != TokenType.EQ &&
            parent.operator.type != TokenType.QUESTION_QUESTION_EQ,
      );
      parent.replaceWith(
        CompoundAssignmentImpl(
          target: InvalidExtensionOverrideAssignmentTargetImpl(
            extensionOverride: receiver,
          ),
          operator: parent.operator,
          value: parent.rightHandSide2,
        ),
      );
      return receiver;
    }
    var isReceiver = switch (parent) {
      ParsedNameAccessImpl(:var operand) => identical(operand, node),
      ReceiverPropertyExtractionImpl(:var receiver) => identical(
        receiver,
        node,
      ),
      ReceiverPropertyAssignmentTargetImpl(:var receiver) => identical(
        receiver,
        node,
      ),
      ReceiverMethodInvocationImpl(:var receiver) => identical(receiver, node),
      ReceiverIndexExpressionImpl(:var receiver) => identical(receiver, node),
      ReceiverIndexAssignmentTargetImpl(:var receiver) => identical(
        receiver,
        node,
      ),
      CallInvocationImpl(:var receiver) => identical(receiver, node),
      BinaryOperatorInvocationImpl(:var leftOperand) => identical(
        leftOperand,
        node,
      ),
      UnaryOperatorInvocationImpl(:var operand) => identical(operand, node),
      _ => false,
    };
    InstanceReceiverImpl replacement = isReceiver
        ? receiver
        : InvalidExtensionOverrideExpressionImpl(extensionOverride: receiver);
    node.replaceWith(replacement);
    return replacement;
  }
}

/// The outcome of interpreting a parsed expression during lexical binding.
sealed class ParsedExpressionResult {}

/// A cascade call awaits member lookup on the once-evaluated cascade receiver.
final class PreparedCascadeInvocation extends ParsedExpressionResult {
  final ParsedValueArgumentsImpl valueArguments;

  PreparedCascadeInvocation(this.valueArguments);
}

/// A shorthand call needs the context established by its enclosing expression
/// before lookup can distinguish a constructor, method, or callable property.
final class PreparedDotShorthandInvocation extends ParsedExpressionResult {
  final ParsedValueArgumentsImpl valueArguments;

  PreparedDotShorthandInvocation(this.valueArguments);
}

/// A call ready for receiver traversal and subsequent member lookup.
final class PreparedReceiverInvocation extends ParsedExpressionResult {
  final NamedReceiverImpl receiver;
  final TypeArgumentListImpl? typeArguments;
  final ParsedValueArgumentsImpl valueArguments;

  PreparedReceiverInvocation._({
    required this.receiver,
    required this.typeArguments,
    required this.valueArguments,
  });
}

/// A replacement expression ready for the lexical binding visitor.
final class RewrittenParsedExpression extends ParsedExpressionResult {
  final InstanceReceiverImpl expression;

  RewrittenParsedExpression._(this.expression);
}
