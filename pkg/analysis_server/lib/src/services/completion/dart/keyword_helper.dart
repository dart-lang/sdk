// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/completion/dart/candidate_suggestion.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_collector.dart';
import 'package:analysis_server/src/utilities/extensions/ast.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';

/// A helper class that produces candidate suggestions for the keywords that are
/// valid at the completion location.
class KeywordHelper {
  /// The suggestion collector to which suggestions will be added.
  final SuggestionCollector collector;

  /// The feature set used to determine which keywords should be suggested.
  final FeatureSet featureSet;

  /// The offset of the completion location.
  final int offset;

  /// Initialize a newly created helper to add suggestions to the [collector].
  KeywordHelper(
      {required this.collector,
      required this.featureSet,
      required this.offset});

  /// Add the keywords that are appropriate when the selection is in a class
  /// declaration between the name of the class and the body. The [node] is the
  /// class declaration containing the selection point.
  void addClassDeclarationKeywords(ClassDeclaration node) {
    // We intentionally add all keywords, even when they would be out of order,
    // in order to help users discover what keywords are available. If the
    // keywords are in the wrong order a diagnostic (and fix) will help them get
    // the keywords in the correct location.
    if (node.extendsClause == null) {
      addKeyword(Keyword.EXTENDS);
    }
    if (node.withClause == null) {
      addKeyword(Keyword.WITH);
    }
    if (node.implementsClause == null) {
      addKeyword(Keyword.IMPLEMENTS);
    }
  }

  /// Add the keywords that are appropriate when the selection is at the
  /// beginning of a member in a class.
  void addClassMemberKeywords() {
    addKeyword(Keyword.CONST);
    addKeyword(Keyword.COVARIANT);
    addKeyword(Keyword.DYNAMIC);
    addKeyword(Keyword.FACTORY);
    addKeyword(Keyword.FINAL);
    addKeyword(Keyword.GET);
    addKeyword(Keyword.OPERATOR);
    addKeyword(Keyword.SET);
    addKeyword(Keyword.STATIC);
    addKeyword(Keyword.VAR);
    addKeyword(Keyword.VOID);
    if (featureSet.isEnabled(Feature.non_nullable)) {
      addKeyword(Keyword.LATE);
    }
  }

  /// Add the keywords that are appropriate when the selection is in a class
  /// declaration before the `class` keyword. The [node] is the class
  /// declaration containing the selection point.
  void addClassModifiers(ClassDeclaration node) {
    if (featureSet.isEnabled(Feature.class_modifiers) &&
        featureSet.isEnabled(Feature.sealed_class)) {
      if (node.baseKeyword == null &&
          node.finalKeyword == null &&
          node.interfaceKeyword == null &&
          node.mixinKeyword == null &&
          node.sealedKeyword == null) {
        if (node.abstractKeyword == null) {
          addKeyword(Keyword.SEALED);
        } else {
          // abstract ^ class A {}
          addKeyword(Keyword.BASE);
          addKeyword(Keyword.FINAL);
          addKeyword(Keyword.INTERFACE);
          addKeyword(Keyword.MIXIN);
        }
      }
      if (node.baseKeyword != null && node.mixinKeyword == null) {
        // base ^ class A {}
        // abstract base ^ class A {}
        addKeyword(Keyword.MIXIN);
      }
      if (node.mixinKeyword != null && node.baseKeyword == null) {
        // abstract ^ mixin class A {}
        addKeyword(Keyword.BASE);
      }
    }
  }

  /// Add the keywords that are appropriate when the selection is at the
  /// beginning of an element in a collection [literal].
  void addCollectionElementKeywords(
      TypedLiteral literal, NodeList<CollectionElement> elements) {
    // TODO(brianwilkerson) Consider determining whether there is a comma before
    //  the selection and inserting the comma if there isn't one.
    addKeyword(Keyword.FOR);
    addKeyword(Keyword.IF);
    // TODO(brianwilkerson) Consider replacing the lines above with the
    // following lines:
    // addKeywordFromText(Keyword.FOR, ' (^)');
    // addKeywordFromText(Keyword.IF, ' (^)');
    var preceedingElement = elements.elementBefore(offset);
    if (preceedingElement != null) {
      var nextToken = preceedingElement.endToken.next!;
      if ( //nextToken.type == TokenType.COMMA &&
          (nextToken.isSynthetic || offset <= nextToken.offset) &&
              preceedingElement.couldHaveTrailingElse) {
        addKeyword(Keyword.ELSE);
      }
    }
    addExpressionKeywords(literal);
  }

  /// Add the keywords that are appropriate when the selection is after the
  /// directives.
  void addCompilationUnitDeclarationKeywords() {
    addKeyword(Keyword.ABSTRACT);
    addKeyword(Keyword.CLASS);
    addKeyword(Keyword.CONST);
    addKeyword(Keyword.COVARIANT);
    addKeyword(Keyword.DYNAMIC);
    addKeyword(Keyword.FINAL);
    addKeyword(Keyword.MIXIN);
    addKeyword(Keyword.TYPEDEF);
    addKeyword(Keyword.VAR);
    addKeyword(Keyword.VOID);
    if (featureSet.isEnabled(Feature.extension_methods)) {
      addKeyword(Keyword.EXTENSION);
    }
    if (featureSet.isEnabled(Feature.non_nullable)) {
      addKeyword(Keyword.LATE);
    }
    if (featureSet.isEnabled(Feature.class_modifiers)) {
      addKeyword(Keyword.BASE);
      addKeyword(Keyword.INTERFACE);
    }
    if (featureSet.isEnabled(Feature.sealed_class)) {
      addKeyword(Keyword.SEALED);
    }
  }

  /// Add the keywords that are appropriate when the selection is at the
  /// beginning of a constant expression. The flag [inConstantContext] should be
  /// `true` if the expression is inside a constant context.
  void addConstantExpressionKeywords({required bool inConstantContext}) {
    // TODO(brianwilkerson) Use this method in place of `addExpressionKeywords`
    //  when in a constant context in order to not suggest invalid keywords.
    addKeyword(Keyword.FALSE);
    addKeyword(Keyword.NULL);
    addKeyword(Keyword.TRUE);
    if (!inConstantContext) {
      addKeyword(Keyword.CONST);
    }
  }

  /// Add the keywords that are appropriate when the selection is in the
  /// initializer list of the given [node].
  void addConstructorInitializerKeywords(ConstructorDeclaration node) {
    addKeyword(Keyword.ASSERT);
    var suggestSuper = node.parent is! ExtensionTypeDeclaration;
    var initializers = node.initializers;
    if (initializers.isNotEmpty) {
      var last = initializers.lastNonSynthetic;
      if (offset >= last.end &&
          last is! SuperConstructorInvocation &&
          last is! RedirectingConstructorInvocation) {
        if (suggestSuper) {
          addKeyword(Keyword.SUPER);
        }
        addKeyword(Keyword.THIS);
      }
    } else {
      // if (separator.end <= offset && offset <= separator.next!.offset) {
      if (suggestSuper) {
        addKeyword(Keyword.SUPER);
      }
      addKeyword(Keyword.THIS);
      // }
    }
  }

  /// Add the keywords that are appropriate when the selection is in an enum
  /// declaration between the name of the enum and the body. The [node] is the
  /// enum declaration containing the selection point.
  void addEnumDeclarationKeywords(EnumDeclaration node) {
    // We intentionally add all keywords, even when they would be out of order,
    // in order to help users discover what keywords are available. If the
    // keywords are in the wrong order a diagnostic (and fix) will help them get
    // the keywords in the correct location.
    if (node.withClause == null) {
      addKeyword(Keyword.WITH);
    }
    if (node.implementsClause == null) {
      addKeyword(Keyword.IMPLEMENTS);
    }
  }

  /// Add the keywords that are appropriate when the selection is at the
  /// beginning of a member in an enum.
  void addEnumMemberKeywords() {
    addKeyword(Keyword.CONST);
    addKeyword(Keyword.DYNAMIC);
    addKeyword(Keyword.FINAL);
    addKeyword(Keyword.GET);
    addKeyword(Keyword.LATE);
    addKeyword(Keyword.OPERATOR);
    addKeyword(Keyword.SET);
    addKeyword(Keyword.STATIC);
    addKeyword(Keyword.VAR);
    addKeyword(Keyword.VOID);
  }

  /// Add the keywords that are appropriate when the selection is at the
  /// beginning of an expression. The [node] provides context to determine which
  /// keywords to include.
  void addExpressionKeywords(AstNode? node) {
    /// Return `true` if `const` should be suggested for the given [node].
    bool constIsValid(AstNode? node) {
      if (node is CollectionElement && node is! Expression) {
        node = node.parent;
      }
      if (node is Expression) {
        return !node.inConstantContext;
      } else if (node is IfStatement) {
        return true;
      } else if (node is PatternVariableDeclaration) {
        return true;
      } else if (node is RecordPattern) {
        // This might be a parenthesized pattern.
        return node.fields.isEmpty;
      } else if (node is SwitchPatternCase) {
        return true;
      } else if (node is SwitchStatement) {
        return true;
      } else if (node is VariableDeclaration) {
        return !node.isConst;
      } else if (node is WhenClause) {
        return true;
      }
      return false;
    }

    /// Return `true` if `switch` should be suggested for the given [node].
    bool switchIsValid(AstNode? node) {
      if (node is CollectionElement && node is! Expression) {
        node = node.parent;
      }
      if (node is SwitchPatternCase) {
        return false;
      }
      return true;
    }

    addKeyword(Keyword.FALSE);
    addKeyword(Keyword.NULL);
    addKeyword(Keyword.TRUE);
    if (node != null) {
      if (constIsValid(node)) {
        addKeyword(Keyword.CONST);
      }
      if (node.inClassMemberBody) {
        addKeyword(Keyword.SUPER);
        addKeyword(Keyword.THIS);
      }
      if (node.inAsyncMethodOrFunction) {
        addKeyword(Keyword.AWAIT);
      }
      if (switchIsValid(node) && featureSet.isEnabled(Feature.patterns)) {
        addKeyword(Keyword.SWITCH);
      }
    } else if (featureSet.isEnabled(Feature.patterns)) {
      addKeyword(Keyword.SWITCH);
    }
  }

  /// Add the keywords that are appropriate when the selection is in an
  /// extension declaration between the name of the extension and the body. The
  /// [node] is the extension declaration containing the selection point.
  void addExtensionDeclarationKeywords(ExtensionDeclaration node) {
    if (node.onKeyword.isSynthetic) {
      addKeyword(Keyword.ON);
    }
  }

  /// Add the keywords that are appropriate when the selection is at the
  /// beginning of a member in an extension.
  void addExtensionMemberKeywords() {
    addKeyword(Keyword.CONST);
    addKeyword(Keyword.DYNAMIC);
    addKeyword(Keyword.FINAL);
    addKeyword(Keyword.GET);
    addKeyword(Keyword.OPERATOR);
    addKeyword(Keyword.SET);
    addKeyword(Keyword.STATIC);
    addKeyword(Keyword.VAR);
    addKeyword(Keyword.VOID);
    if (featureSet.isEnabled(Feature.non_nullable)) {
      addKeyword(Keyword.LATE);
    }
  }

  /// Add the keywords that are appropriate when the selection is before the `{`
  /// or `=>` in a function body. The [body] is used to determine which keywords
  /// are appropriate.
  void addFunctionBodyModifiers(FunctionBody? body) {
    if (body?.keyword == null) {
      addKeyword(Keyword.ASYNC);
      if (body is! ExpressionFunctionBody) {
        addKeywordFromText(Keyword.ASYNC, '*');
        addKeywordFromText(Keyword.SYNC, '*');
      }
    }
  }

  /// Add the keywords that are appropriate when the selection is in an import
  /// directive between the URI and the semicolon. The [node] is the import
  /// directive containing the selection point.
  void addImportDirectiveKeywords(ImportDirective node) {
    var deferredKeyword = node.deferredKeyword;
    var asKeyword = node.asKeyword;
    var firstCombinator = node.combinators.firstOrNull;
    if (firstCombinator == null || offset < firstCombinator.offset) {
      if (deferredKeyword == null) {
        if (asKeyword == null) {
          addKeywordFromText(Keyword.DEFERRED, ' as');
          addKeyword(Keyword.AS);
          addKeyword(Keyword.HIDE);
          addKeyword(Keyword.SHOW);
        } else if (offset < asKeyword.offset) {
          addKeyword(Keyword.DEFERRED);
        } else {
          var prefix = node.prefix;
          if (prefix != null && offset > prefix.end) {
            addKeyword(Keyword.HIDE);
            addKeyword(Keyword.SHOW);
          }
        }
      } else if (offset > deferredKeyword.end && asKeyword == null) {
        addKeyword(Keyword.AS);
      } else {
        addKeyword(Keyword.HIDE);
        addKeyword(Keyword.SHOW);
      }
    } else {
      addKeyword(Keyword.HIDE);
      addKeyword(Keyword.SHOW);
    }
  }

  /// Add a keyword suggestion to suggest the [keyword].
  void addKeyword(Keyword keyword) {
    collector.addSuggestion(KeywordSuggestion.fromKeyword(keyword));
  }

  /// Add a keyword suggestion to suggest the [keyword] followed by the
  /// [annotatedText]. The annotated text is used in cases where there is
  /// boilerplate that always follows the keyword that should also be suggested.
  ///
  /// If the annotated text contains a caret (^), then the completion will use
  /// the annotated text with the caret removed and the index of the caret will
  /// be used as the selection offset. If the text doesn't contain a caret, then
  /// the insert text will be the annotated text and the selection offset will
  /// be at the end of the text.
  void addKeywordFromText(Keyword keyword, String annotatedText) {
    collector.addSuggestion(
        KeywordSuggestion.fromKeywordAndText(keyword, annotatedText));
  }

  /// Add the keywords that are appropriate when the selection is in a mixin
  /// declaration between the name of the mixin and the body. The [node] is the
  /// mixin declaration containing the selection point.
  void addMixinDeclarationKeywords(MixinDeclaration node) {
    // We intentionally add all keywords, even when they would be out of order,
    // in order to help users discover what keywords are available. If the
    // keywords are in the wrong order a diagnostic (and fix) will help them get
    // the keywords in the correct location.
    if (node.onClause == null) {
      addKeyword(Keyword.ON);
    }
    if (node.implementsClause == null) {
      addKeyword(Keyword.IMPLEMENTS);
    }
  }

  /// Add the keywords that are appropriate when the selection is at the
  /// beginning of a member in a mixin.
  void addMixinMemberKeywords() {
    addKeyword(Keyword.CONST);
    addKeyword(Keyword.COVARIANT);
    addKeyword(Keyword.DYNAMIC);
    addKeyword(Keyword.FINAL);
    addKeyword(Keyword.GET);
    addKeyword(Keyword.OPERATOR);
    addKeyword(Keyword.SET);
    addKeyword(Keyword.STATIC);
    addKeyword(Keyword.VAR);
    addKeyword(Keyword.VOID);
    if (featureSet.isEnabled(Feature.non_nullable)) {
      addKeyword(Keyword.LATE);
    }
  }

  /// Add the keywords that are appropriate when the selection is in a mixin
  /// declaration before the `mixin` keyword. The [node] is the mixin
  /// declaration containing the selection point.
  void addMixinModifiers(MixinDeclaration node) {
    if (node.baseKeyword == null) {
      addKeyword(Keyword.BASE);
    }
  }

  /// Add the keywords that are appropriate when the selection is at the
  /// beginning of a pattern.
  void addPatternKeywords() {
    addConstantExpressionKeywords(inConstantContext: false);
    addVariablePatternKeywords();
  }

  /// Add the keywords that are appropriate when the selection is at the
  /// beginning of a statement. The [node] provides context to determine which
  /// keywords to include.
  void addStatementKeywords(AstNode node) {
    if (node.inClassMemberBody) {
      addKeyword(Keyword.SUPER);
      addKeyword(Keyword.THIS);
    }
    if (node.inAsyncMethodOrFunction) {
      addKeyword(Keyword.AWAIT);
    } else if (node.inAsyncStarOrSyncStarMethodOrFunction) {
      addKeyword(Keyword.AWAIT);
      addKeyword(Keyword.YIELD);
      addKeywordFromText(Keyword.YIELD, '*');
    }
    if (node.inLoop) {
      addKeyword(Keyword.BREAK);
      addKeyword(Keyword.CONTINUE);
    }
    if (node.inSwitch) {
      addKeyword(Keyword.BREAK);
    }
    // TODO(brianwilkerson) Add `else` when after an `if` statement, similar to
    //  the way `addCollectionElementKeywords` works.
    addKeyword(Keyword.ASSERT);
    addKeyword(Keyword.CONST);
    addKeyword(Keyword.DO);
    addKeyword(Keyword.DYNAMIC);
    addKeyword(Keyword.FINAL);
    addKeyword(Keyword.FOR);
    addKeyword(Keyword.IF);
    addKeyword(Keyword.RETURN);
    addKeyword(Keyword.SWITCH);
    addKeyword(Keyword.THROW);
    addKeyword(Keyword.TRY);
    addKeyword(Keyword.VAR);
    addKeyword(Keyword.VOID);
    addKeyword(Keyword.WHILE);
    if (featureSet.isEnabled(Feature.non_nullable)) {
      addKeyword(Keyword.LATE);
    }
  }

  /// Add the keywords that are appropriate when the selection is after the
  /// end of a `try` statement. [canHaveFinally] indicates whether it's valid to
  /// suggest a `finally` clause.
  void addTryClauseKeywords({required bool canHaveFinally}) {
    addKeyword(Keyword.CATCH);
    if (canHaveFinally) {
      addKeyword(Keyword.FINALLY);
    }
    addKeyword(Keyword.ON);
  }

  /// Add the keywords that are appropriate when the selection is at the
  /// beginning of a pattern.
  void addVariablePatternKeywords() {
    addKeyword(Keyword.FINAL);
    addKeyword(Keyword.VAR);
  }
}

extension on CollectionElement? {
  bool get couldHaveTrailingElse {
    var finalElement = this;
    while (finalElement is IfElement || finalElement is ForElement) {
      if (finalElement is IfElement) {
        var elseElement = finalElement.elseElement;
        if (elseElement == null) {
          break;
        }
        finalElement = elseElement;
      } else if (finalElement is ForElement) {
        finalElement = finalElement.body;
      }
    }
    return finalElement is IfElement &&
        finalElement.elseKeyword == null &&
        !finalElement.thenElement.isSynthetic;
  }
}

extension on NodeList<ConstructorInitializer> {
  ConstructorInitializer get lastNonSynthetic {
    final last = this.last;
    if (last.beginToken.isSynthetic && length > 1) {
      return this[length - 2];
    }
    return last;
  }
}
