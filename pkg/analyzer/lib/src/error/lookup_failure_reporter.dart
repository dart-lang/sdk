// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/error/listener.dart';

/// A lookup in the static members of the context type of a dot shorthand.
///
/// For example, `.foo` and `.foo()`.
///
/// A dot shorthand without a context type is reported as missing a context
/// instead, so this domain always has a context type.
final class DotShorthandLookupDomain extends LookupDomain
    with _LegacyWriteFailure {
  /// The context type of the dot shorthand.
  final TypeImpl contextType;

  /// The declaration whose static members were searched, or `null` if the
  /// context type doesn't denote an accessible interface declaration.
  final InterfaceElement? declaration;

  /// A lookup in the declaration that [context] denotes.
  DotShorthandLookupDomain.declaration(
    ValidDotShorthandContextResolutionImpl context,
  ) : contextType = context.contextType,
      declaration = context.lookupType.element;

  /// A lookup in a [contextType] that doesn't denote an accessible interface
  /// declaration, such as a function type, so nothing could be found.
  DotShorthandLookupDomain.type(this.contextType) : declaration = null;

  /// The context type, as it is displayed in messages.
  ///
  /// If the context type denotes a declaration, this is its name, without
  /// type arguments or nullability.
  String get contextTypeName {
    return declaration?.displayName ?? contextType.getDisplayString();
  }

  @override
  LocatableDiagnostic _readFailure(
    String name,
    ReadSyntax syntax,
    _FoundInstead foundInstead,
  ) {
    switch (syntax) {
      case ReadSyntax.invocation:
        return diag.dotShorthandUndefinedInvocation.withArguments(
          name: name,
          contextType: contextTypeName,
        );
      case ReadSyntax.reference:
      case ReadSyntax.typeInstantiation:
        return diag.dotShorthandUndefinedGetter.withArguments(
          getterName: name,
          typeName: contextTypeName,
        );
    }
  }

  @override
  LocatableDiagnostic _writeNotFound(String name) {
    throw StateError('A dot shorthand cannot be written.');
  }
}

/// A lookup in the members of an explicit extension override.
///
/// For example, `E(x).foo` and `E(x).foo = 0`.
final class ExtensionOverrideLookupDomain extends LookupDomain {
  /// The extension that the override names.
  final ExtensionElement extension;

  ExtensionOverrideLookupDomain(this.extension);

  String get _extensionName {
    // An extension override can only name a named extension.
    // TODO(scheglov): Prove this with types, instead of a null check.
    return extension.name!;
  }

  @override
  LocatableDiagnostic _readFailure(
    String name,
    ReadSyntax syntax,
    _FoundInstead foundInstead,
  ) {
    switch (foundInstead) {
      case _FoundNothing():
        return diag.undefinedExtensionMemberReadNotFound.withArguments(
          name: name,
          extensionName: _extensionName,
        );
      case _FoundPrivate(:var libraryUri):
        return diag.undefinedExtensionMemberReadPrivate.withArguments(
          name: name,
          libraryUri: libraryUri,
        );
      case _FoundDeclaration(element: ExecutableElement(isStatic: true)):
        return diag.extensionOverrideAccessToStaticMember;
      case _FoundDeclaration():
        // Only a setter has the name.
        return diag.undefinedExtensionMemberReadSetterOnly.withArguments(
          name: name,
          extensionName: _extensionName,
        );
    }
  }

  @override
  LocatableDiagnostic? _writeFailure(String name, _FoundInstead foundInstead) {
    switch (foundInstead) {
      case _FoundNothing():
        return diag.undefinedExtensionMemberWriteNotFound.withArguments(
          name: name,
          extensionName: _extensionName,
        );
      case _FoundPrivate(:var libraryUri):
        return diag.undefinedExtensionMemberWritePrivate.withArguments(
          name: name,
          libraryUri: libraryUri,
        );
      case _FoundDeclaration(element: ExecutableElement(isStatic: true)):
        return diag.extensionOverrideAccessToStaticMember;
      case _FoundDeclaration(element: GetterElement(:var variable)):
        if (variable.isOriginGetterSetter) {
          return diag.undefinedExtensionMemberWriteGetterOnly.withArguments(
            name: name,
            extensionName: _extensionName,
          );
        } else {
          // An extension can't declare an instance field, and the field
          // declaration already reports that.
          return null;
        }
      case _FoundDeclaration(:var element):
        return diag.undefinedExtensionMemberWriteWrongKind.withArguments(
          kind: element.kind.displayName,
          name: name,
          extensionName: _extensionName,
        );
    }
  }
}

/// A lookup in the static members of a function-type alias.
///
/// For example, `F.foo` and `F.foo = 0`. A function-type alias has no static
/// members, so every lookup in it fails.
final class FunctionTypeAliasLookupDomain extends LookupDomain
    with _LegacyWriteFailure {
  /// The name of the alias, with its import prefix if one is written.
  final String aliasName;

  FunctionTypeAliasLookupDomain({
    required ImportPrefixReferenceImpl? importPrefix,
    required Token name,
  }) : aliasName = importPrefix != null
           ? '${importPrefix.name.lexeme}.${name.lexeme}'
           : name.lexeme;

  @override
  LocatableDiagnostic _readFailure(
    String name,
    ReadSyntax syntax,
    _FoundInstead foundInstead,
  ) {
    switch (syntax) {
      case ReadSyntax.invocation:
        return diag.undefinedMethodOnFunctionType.withArguments(
          methodName: name,
          functionTypeAliasName: aliasName,
        );
      case ReadSyntax.reference:
      case ReadSyntax.typeInstantiation:
        return diag.undefinedGetterOnFunctionType.withArguments(
          getterName: name,
          functionTypeAliasName: aliasName,
        );
    }
  }

  @override
  LocatableDiagnostic _writeNotFound(String name) {
    return diag.undefinedSetterOnFunctionType.withArguments(
      setterName: name,
      functionTypeAliasName: aliasName,
    );
  }
}

/// A lookup in the instance members of the static type of a receiver.
///
/// For example, `x.foo` and `x.foo = 0`. The members of applicable extensions
/// are included.
final class InstanceLookupDomain extends LookupDomain with _LegacyWriteFailure {
  /// The static type of the receiver.
  final TypeImpl receiverType;

  InstanceLookupDomain(this.receiverType);

  @override
  LocatableDiagnostic _readFailure(
    String name,
    ReadSyntax syntax,
    _FoundInstead foundInstead,
  ) {
    switch (syntax) {
      case ReadSyntax.invocation:
        return diag.undefinedMethod.withArguments(
          methodName: name,
          type: receiverType,
        );
      case ReadSyntax.reference:
      case ReadSyntax.typeInstantiation:
        return diag.undefinedGetter.withArguments(
          memberName: name,
          type: receiverType,
        );
    }
  }

  @override
  LocatableDiagnostic _writeNotFound(String name) {
    return diag.undefinedSetter.withArguments(
      setterName: name,
      type: receiverType,
    );
  }
}

/// A namespace in which a name was looked up.
///
/// Together with the required capability, read or write, the domain decides
/// which diagnostic reports a failed lookup.
///
/// Domains are created only when a lookup has failed, so that resolving valid
/// code, which is almost all code, doesn't allocate them.
sealed class LookupDomain {
  /// Whether a failed lookup of [name] in this domain is not reported.
  bool _isIgnored(LibraryFragmentImpl libraryFragment, String name) {
    return false;
  }

  /// The diagnostic for a lookup of [name] that found nothing that can be
  /// read, used in [syntax], but [foundInstead].
  LocatableDiagnostic _readFailure(
    String name,
    ReadSyntax syntax,
    _FoundInstead foundInstead,
  );

  /// The diagnostic for a lookup of [name] that found no setter, but
  /// [foundInstead], or `null` if nothing is reported.
  LocatableDiagnostic? _writeFailure(String name, _FoundInstead foundInstead);
}

/// A reporter of names that a lookup failed to resolve for the required
/// capability.
///
/// Call sites describe the failure: the [LookupDomain] that was searched, the
/// capability, read or write, and for writes what was found instead of a
/// setter. Each domain chooses its diagnostics, and this class applies the
/// rules that are shared by all lookups, such as not reporting synthetic
/// names, and the diagnostics for what was found instead of a setter.
///
/// The current diagnostics also depend on the syntax, see [ReadSyntax]. The
/// planned family of diagnostics for each domain and capability is described
/// in https://github.com/dart-lang/sdk/issues/64411.
class LookupFailureReporter {
  final DiagnosticReporter _diagnosticReporter;
  final LibraryFragmentImpl _libraryFragment;

  LookupFailureReporter(this._diagnosticReporter, this._libraryFragment);

  /// Reports that the lookup of [name] in [domain] found nothing that can be
  /// read, invoked, or torn off.
  ///
  /// The [foundInstead] is the declaration that has the name, but can't be
  /// read, such as a setter, or a private declaration of another library. It
  /// is `null` if nothing has the name, or if the caller reports every failed
  /// read in [domain] as not found.
  void reportReadFailure({
    required LookupDomain domain,
    required Token name,
    required ReadSyntax syntax,
    required Element? foundInstead,
  }) {
    if (_isIgnored(domain, name)) {
      return;
    }
    var found = _FoundInstead.of(foundInstead, _libraryFragment.element);
    _diagnosticReporter.report(
      domain._readFailure(name.lexeme, syntax, found).at(name),
    );
  }

  /// Reports that the lookup of [name] in [domain] found no setter.
  ///
  /// The [foundInstead] is the declaration that has the name of the missing
  /// setter, such as a getter, a method, a function, a type, or a private
  /// declaration of another library. It is `null` if nothing has the name, or
  /// if the caller reports every missing setter in [domain] as not found.
  void reportWriteFailure({
    required LookupDomain domain,
    required Token name,
    required Element? foundInstead,
  }) {
    var found = _FoundInstead.of(foundInstead, _libraryFragment.element);
    if (found is _FoundNothing && _isIgnored(domain, name)) {
      return;
    }
    if (domain._writeFailure(name.lexeme, found) case var diagnostic?) {
      _diagnosticReporter.report(diagnostic.at(name));
    }
  }

  /// Whether a failed lookup of [name] in [domain] is not reported.
  bool _isIgnored(LookupDomain domain, Token name) {
    // The parser has already reported the missing name.
    return name.isSynthetic || domain._isIgnored(_libraryFragment, name.lexeme);
  }
}

/// A lookup in the names imported through an import prefix.
///
/// For example, `p.foo` and `p.foo = 0`.
final class PrefixedLookupDomain extends LookupDomain with _LegacyWriteFailure {
  /// The import prefix.
  final PrefixElement prefix;

  PrefixedLookupDomain(this.prefix);

  @override
  bool _isIgnored(LibraryFragmentImpl libraryFragment, String name) {
    return libraryFragment.shouldIgnoreUndefined(
      prefix: prefix.name,
      name: name,
    );
  }

  @override
  LocatableDiagnostic _readFailure(
    String name,
    ReadSyntax syntax,
    _FoundInstead foundInstead,
  ) {
    switch (syntax) {
      case ReadSyntax.invocation:
        return diag.undefinedFunction.withArguments(name: name);
      case ReadSyntax.reference:
      case ReadSyntax.typeInstantiation:
        return diag.undefinedPrefixedName.withArguments(
          referenceName: name,
          prefixName: prefix.name!,
        );
    }
  }

  @override
  LocatableDiagnostic _writeNotFound(String name) {
    return diag.undefinedPrefixedName.withArguments(
      referenceName: name,
      prefixName: prefix.name!,
    );
  }
}

/// The syntax in which a name that failed to resolve for reading appears.
///
/// The current diagnostics guess the kind of the missing declaration from it,
/// for example `undefined_method` for `x.foo()` and `undefined_getter` for
/// `x.foo`, although the lookup is the same.
enum ReadSyntax {
  /// An invocation of the name, as in `foo()`.
  invocation,

  /// A read or a tear-off of the name, as in `foo`.
  reference,

  /// A tear-off of the name that is instantiated with type arguments, as in
  /// `foo<int>`.
  typeInstantiation,
}

/// A lookup in the static members of a class, enum, mixin, extension type,
/// or extension.
///
/// For example, `C.foo` and `C.foo = 0`.
final class StaticLookupDomain extends LookupDomain with _LegacyWriteFailure {
  /// The declaration whose static members were searched.
  final InstanceElementImpl declaration;

  StaticLookupDomain(this.declaration);

  LocatableDiagnostic _extensionReadFailure(
    ExtensionElement extension,
    String name,
    ReadSyntax syntax,
  ) {
    // Only a named extension can be a qualifier.
    // TODO(scheglov): Prove this with types, instead of a null check.
    var extensionName = extension.name!;
    switch (syntax) {
      case ReadSyntax.invocation:
        return diag.undefinedExtensionMethod.withArguments(
          methodName: name,
          extensionName: extensionName,
        );
      case ReadSyntax.reference:
      case ReadSyntax.typeInstantiation:
        return diag.undefinedExtensionGetter.withArguments(
          getterName: name,
          extensionName: extensionName,
        );
    }
  }

  LocatableDiagnostic _interfaceReadFailure(
    InterfaceElement interface,
    String name,
    ReadSyntax syntax,
  ) {
    switch (syntax) {
      case ReadSyntax.invocation:
        return diag.undefinedMethodOnTypeLiteral.withArguments(
          methodName: name,
          typeName: interface.displayName,
        );
      case ReadSyntax.reference:
      case ReadSyntax.typeInstantiation:
        if (interface is EnumElement) {
          return diag.undefinedEnumConstant.withArguments(
            memberName: name,
            type: interface.thisType,
          );
        } else {
          return diag.undefinedGetter.withArguments(
            memberName: name,
            type: interface.thisType,
          );
        }
    }
  }

  @override
  LocatableDiagnostic _readFailure(
    String name,
    ReadSyntax syntax,
    _FoundInstead foundInstead,
  ) {
    switch (declaration) {
      case ExtensionElementImpl declaration:
        return _extensionReadFailure(declaration, name, syntax);
      case InterfaceElementImpl declaration:
        return _interfaceReadFailure(declaration, name, syntax);
    }
  }

  @override
  LocatableDiagnostic _writeNotFound(String name) {
    switch (declaration) {
      case ExtensionElementImpl declaration:
        // Only a named extension can be a qualifier.
        // TODO(scheglov): Prove this with types, instead of a null check.
        return diag.undefinedExtensionSetter.withArguments(
          setterName: name,
          extensionName: declaration.name!,
        );
      case InterfaceElementImpl declaration:
        return diag.undefinedSetter.withArguments(
          setterName: name,
          type: declaration.thisType,
        );
    }
  }
}

/// A lookup in the members that `super` refers to in the enclosing
/// declaration.
///
/// For example, `super.foo` and `super.foo = 0`. These are the members of the
/// superclass, or of the superclass constraints of a mixin.
final class SuperLookupDomain extends LookupDomain {
  /// The type of `this` in the enclosing declaration.
  final InterfaceTypeImpl type;

  SuperLookupDomain(this.type);

  @override
  LocatableDiagnostic _readFailure(
    String name,
    ReadSyntax syntax,
    _FoundInstead foundInstead,
  ) {
    switch (foundInstead) {
      case _FoundNothing():
        return diag.undefinedSuperMemberReadNotFound.withArguments(
          name: name,
          type: type,
        );
      case _FoundPrivate(:var libraryUri):
        return diag.undefinedSuperMemberReadPrivate.withArguments(
          name: name,
          libraryUri: libraryUri,
        );
      case _FoundDeclaration():
        // Only a setter has the name.
        return diag.undefinedSuperMemberReadSetterOnly.withArguments(
          name: name,
          type: type,
        );
    }
  }

  @override
  LocatableDiagnostic? _writeFailure(String name, _FoundInstead foundInstead) {
    switch (foundInstead) {
      case _FoundNothing():
        return diag.undefinedSuperMemberWriteNotFound.withArguments(
          name: name,
          type: type,
        );
      case _FoundPrivate(:var libraryUri):
        return diag.undefinedSuperMemberWritePrivate.withArguments(
          name: name,
          libraryUri: libraryUri,
        );
      case _FoundDeclaration(element: GetterElement(:var variable)):
        if (variable.isConst) {
          // An instance field can't be constant, and its declaration already
          // reports that.
          return null;
        } else if (variable.isFinal && !variable.isOriginGetterSetter) {
          // A final field, declared in a field declaration, or by a declaring
          // formal parameter of a primary constructor.
          return diag.undefinedSuperMemberWriteFinal.withArguments(
            name: name,
            type: type,
          );
        } else {
          // There is no setter in the interface that `super` has. Either no
          // superclass declares one, or the setters that the interface would
          // combine conflict, which can drop the setter of a non-final field
          // too.
          return diag.undefinedSuperMemberWriteGetterOnly.withArguments(
            name: name,
            type: type,
          );
        }
      case _FoundDeclaration(:var element):
        return diag.undefinedSuperMemberWriteWrongKind.withArguments(
          kind: element.kind.displayName,
          name: name,
          type: type,
        );
    }
  }
}

/// A lookup of a name in the lexical scope.
///
/// For example, `foo` and `foo = 0`. Inside an instance declaration, the
/// scope includes its members, which are found through an implicit `this`.
final class UnqualifiedLookupDomain extends LookupDomain
    with _LegacyWriteFailure {
  /// The type of `this`, if the scope includes the members of an enclosing
  /// instance declaration.
  ///
  /// It names the type in messages for failed invocations, so write failures
  /// don't use it.
  final TypeImpl? thisType;

  UnqualifiedLookupDomain({required this.thisType});

  @override
  bool _isIgnored(LibraryFragmentImpl libraryFragment, String name) {
    return libraryFragment.shouldIgnoreUndefined(prefix: null, name: name);
  }

  @override
  LocatableDiagnostic _readFailure(
    String name,
    ReadSyntax syntax,
    _FoundInstead foundInstead,
  ) {
    var thisType = this.thisType;
    switch (syntax) {
      case ReadSyntax.invocation:
        if (thisType != null) {
          return diag.undefinedMethod.withArguments(
            methodName: name,
            type: thisType,
          );
        } else {
          return diag.undefinedFunction.withArguments(name: name);
        }
      case ReadSyntax.reference:
        return diag.undefinedIdentifier.withArguments(name: name);
      case ReadSyntax.typeInstantiation:
        if (thisType != null) {
          return diag.undefinedMethod.withArguments(
            methodName: name,
            type: thisType,
          );
        } else {
          return diag.undefinedIdentifier.withArguments(name: name);
        }
    }
  }

  @override
  LocatableDiagnostic _writeNotFound(String name) {
    return diag.undefinedIdentifier.withArguments(name: name);
  }
}

/// A declaration that has the name, but not the required capability, such as
/// a setter for a read, or a getter for a write.
final class _FoundDeclaration extends _FoundInstead {
  final Element element;

  _FoundDeclaration(this.element);
}

/// What a failed lookup found instead of a declaration with the required
/// capability.
sealed class _FoundInstead {
  const _FoundInstead();

  /// What a lookup in [library] found instead: the [element] that the caller
  /// found, or nothing if it is `null`.
  factory _FoundInstead.of(Element? element, LibraryElement library) {
    if (element == null) {
      return const _FoundNothing();
    } else if (element.isPrivate && element.library != library) {
      return _FoundPrivate(element);
    } else {
      return _FoundDeclaration(element);
    }
  }
}

/// Nothing that has the name.
final class _FoundNothing extends _FoundInstead {
  const _FoundNothing();
}

/// A private declaration of another library that has the name, which is
/// visible only in its own library.
final class _FoundPrivate extends _FoundInstead {
  final Element element;

  _FoundPrivate(this.element);

  /// The URI of the library that declares the [element].
  Uri get libraryUri => element.library!.uri;
}

/// The write diagnostics that are used before
/// https://github.com/dart-lang/sdk/issues/64411, such as
/// `assignment_to_final`, for the domains that still use them.
mixin _LegacyWriteFailure on LookupDomain {
  @override
  LocatableDiagnostic? _writeFailure(String name, _FoundInstead foundInstead) {
    switch (foundInstead) {
      case _FoundNothing():
      case _FoundPrivate():
        return _writeNotFound(name);
      case _FoundDeclaration(:var element):
        switch (element) {
          case VariableElement(isConst: true):
            return diag.assignmentToConst;
          case DynamicElementImpl():
          case InterfaceElement():
          case TypeAliasElement():
          case TypeParameterElement():
            return diag.assignmentToType;
          case LocalFunctionElement():
          case TopLevelFunctionElement():
            return diag.assignmentToFunction;
          case MethodElement():
            return diag.assignmentToMethod;
          case PrefixElement(name: var prefixName?):
            return diag.prefixIdentifierNotFollowedByDot.withArguments(
              name: prefixName,
            );
          case PrefixElement():
            return null;
          case GetterElement(:var variable):
            return _writeOfGetter(variable);
          case MultiplyDefinedElementImpl():
            // Reported as an ambiguous import by the caller, or by
            // ErrorVerifier.
            return null;
          default:
            return _writeNotFound(name);
        }
    }
  }

  /// The diagnostic for a lookup of [name] that found no setter, and nothing
  /// else instead.
  LocatableDiagnostic _writeNotFound(String name);

  LocatableDiagnostic? _writeOfGetter(PropertyInducingElement variable) {
    var variableName = variable.name;
    if (variableName == null) {
      return null;
    } else if (variable.isConst) {
      return diag.assignmentToConst;
    } else if (variable is FieldElement && variable.isOriginGetterSetter) {
      return diag.assignmentToFinalNoSetter.withArguments(
        variableName: variableName,
        className: variable.enclosingElement.displayName,
      );
    } else {
      return diag.assignmentToFinal.withArguments(variableName: variableName);
    }
  }
}
