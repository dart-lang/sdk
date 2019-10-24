// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:core' hide MapEntry;

import 'package:front_end/src/fasta/kernel/kernel_api.dart';
import 'package:kernel/ast.dart' hide Variance;

import 'package:kernel/type_algebra.dart';

import '../../base/common.dart';

import '../kernel/redirecting_factory_body.dart' show RedirectingFactoryBody;

import '../loader.dart' show Loader;

import '../messages.dart'
    show messageConstFactoryRedirectionToNonConst, noLength;

import '../problems.dart' show unexpected;

import '../source/source_library_builder.dart' show SourceLibraryBuilder;

import 'builder.dart';
import 'constructor_reference_builder.dart';
import 'extension_builder.dart';
import 'formal_parameter_builder.dart';
import 'function_builder.dart';
import 'metadata_builder.dart';
import 'type_builder.dart';
import 'type_variable_builder.dart';

abstract class ProcedureBuilder implements FunctionBuilder {
  int get charOpenParenOffset;

  ProcedureBuilder get patchForTesting;

  AsyncMarker actualAsyncModifier;

  Procedure get actualProcedure;

  bool hadTypesInferred;

  @override
  ProcedureBuilder get origin;

  void set asyncModifier(AsyncMarker newModifier);

  bool get isEligibleForTopLevelInference;

  /// Returns `true` if this procedure is declared in an extension declaration.
  bool get isExtensionMethod;

  Procedure build(SourceLibraryBuilder libraryBuilder);
}

class ProcedureBuilderImpl extends FunctionBuilderImpl
    implements ProcedureBuilder {
  final Procedure _procedure;

  @override
  final int charOpenParenOffset;

  @override
  final ProcedureKind kind;

  @override
  ProcedureBuilder patchForTesting;

  @override
  AsyncMarker actualAsyncModifier = AsyncMarker.Sync;

  @override
  ProcedureBuilder actualOrigin;

  @override
  Procedure get actualProcedure => _procedure;

  @override
  bool hadTypesInferred = false;

  /// If this is an extension instance method then [_extensionTearOff] holds
  /// the synthetically created tear off function.
  Procedure _extensionTearOff;

  /// If this is an extension instance method then
  /// [_extensionTearOffParameterMap] holds a map from the parameters of
  /// the methods to the parameter of the closure returned in the tear-off.
  ///
  /// This map is used to set the default values on the closure parameters when
  /// these have been built.
  Map<VariableDeclaration, VariableDeclaration> _extensionTearOffParameterMap;

  ProcedureBuilderImpl(
      List<MetadataBuilder> metadata,
      int modifiers,
      TypeBuilder returnType,
      String name,
      List<TypeVariableBuilder> typeVariables,
      List<FormalParameterBuilder> formals,
      this.kind,
      SourceLibraryBuilder compilationUnit,
      int startCharOffset,
      int charOffset,
      this.charOpenParenOffset,
      int charEndOffset,
      [String nativeMethodName])
      : _procedure =
            new Procedure(null, kind, null, fileUri: compilationUnit?.fileUri)
              ..startFileOffset = startCharOffset
              ..fileOffset = charOffset
              ..fileEndOffset = charEndOffset,
        super(metadata, modifiers, returnType, name, typeVariables, formals,
            compilationUnit, charOffset, nativeMethodName);

  @override
  ProcedureBuilder get origin => actualOrigin ?? this;

  @override
  AsyncMarker get asyncModifier => actualAsyncModifier;

  @override
  Statement get body {
    if (bodyInternal == null && !isAbstract && !isExternal) {
      bodyInternal = new EmptyStatement();
    }
    return bodyInternal;
  }

  @override
  void set asyncModifier(AsyncMarker newModifier) {
    actualAsyncModifier = newModifier;
    if (function != null) {
      // No parent, it's an enum.
      function.asyncMarker = actualAsyncModifier;
      function.dartAsyncMarker = actualAsyncModifier;
    }
  }

  @override
  bool get isEligibleForTopLevelInference {
    if (isDeclarationInstanceMember) {
      if (returnType == null) return true;
      if (formals != null) {
        for (FormalParameterBuilder formal in formals) {
          if (formal.type == null) return true;
        }
      }
    }
    return false;
  }

  @override
  bool get isExtensionMethod {
    return parent is ExtensionBuilder;
  }

  @override
  Procedure build(SourceLibraryBuilder libraryBuilder) {
    // TODO(ahe): I think we may call this twice on parts. Investigate.
    if (_procedure.name == null) {
      _procedure.function = buildFunction(libraryBuilder);
      _procedure.function.parent = _procedure;
      _procedure.function.fileOffset = charOpenParenOffset;
      _procedure.function.fileEndOffset = _procedure.fileEndOffset;
      _procedure.isAbstract = isAbstract;
      _procedure.isExternal = isExternal;
      _procedure.isConst = isConst;
      if (isExtensionMethod) {
        ExtensionBuilder extensionBuilder = parent;
        _procedure.isExtensionMember = true;
        _procedure.isStatic = true;
        String kindInfix = '';
        if (isExtensionInstanceMember) {
          // Instance getter and setter are converted to methods so we use an
          // infix to make their names unique.
          switch (kind) {
            case ProcedureKind.Getter:
              kindInfix = 'get#';
              break;
            case ProcedureKind.Setter:
              kindInfix = 'set#';
              break;
            case ProcedureKind.Method:
            case ProcedureKind.Operator:
              kindInfix = '';
              break;
            case ProcedureKind.Factory:
              throw new UnsupportedError(
                  'Unexpected extension method kind ${kind}');
          }
          _procedure.kind = ProcedureKind.Method;
        }
        _procedure.name = new Name(
            '${extensionBuilder.name}|${kindInfix}${name}',
            libraryBuilder.library);
      } else {
        _procedure.isStatic = isStatic;
        _procedure.name = new Name(name, libraryBuilder.library);
      }
      if (extensionTearOff != null) {
        _buildExtensionTearOff(libraryBuilder, parent);
      }
    }
    return _procedure;
  }

  /// Creates a top level function that creates a tear off of an extension
  /// instance method.
  ///
  /// For this declaration
  ///
  ///     extension E<T> on A<T> {
  ///       X method<S>(S s, Y y) {}
  ///     }
  ///
  /// we create the top level function
  ///
  ///     X E|method<T, S>(A<T> #this, S s, Y y) {}
  ///
  /// and the tear off function
  ///
  ///     X Function<S>(S, Y) E|get#method<T>(A<T> #this) {
  ///       return (S s, Y y) => E|method<T, S>(#this, s, y);
  ///     }
  ///
  void _buildExtensionTearOff(
      SourceLibraryBuilder libraryBuilder, ExtensionBuilder extensionBuilder) {
    assert(
        _extensionTearOff != null, "No extension tear off created for $this.");
    if (_extensionTearOff.name != null) return;

    _extensionTearOffParameterMap = {};

    int fileOffset = _procedure.fileOffset;

    int extensionTypeParameterCount =
        extensionBuilder.typeParameters?.length ?? 0;

    List<TypeParameter> typeParameters = <TypeParameter>[];

    Map<TypeParameter, DartType> substitutionMap = {};
    List<DartType> typeArguments = <DartType>[];
    for (TypeParameter typeParameter in function.typeParameters) {
      TypeParameter newTypeParameter = new TypeParameter(typeParameter.name);
      typeParameters.add(newTypeParameter);
      typeArguments.add(substitutionMap[typeParameter] =
          new TypeParameterType(newTypeParameter));
    }

    List<TypeParameter> tearOffTypeParameters = <TypeParameter>[];
    List<TypeParameter> closureTypeParameters = <TypeParameter>[];
    Substitution substitution = Substitution.fromMap(substitutionMap);
    for (int index = 0; index < typeParameters.length; index++) {
      TypeParameter newTypeParameter = typeParameters[index];
      newTypeParameter.bound =
          substitution.substituteType(function.typeParameters[index].bound);
      newTypeParameter.defaultType = function.typeParameters[index].defaultType;
      if (index < extensionTypeParameterCount) {
        tearOffTypeParameters.add(newTypeParameter);
      } else {
        closureTypeParameters.add(newTypeParameter);
      }
    }

    VariableDeclaration copyParameter(
        VariableDeclaration parameter, DartType type,
        {bool isOptional}) {
      VariableDeclaration newParameter = new VariableDeclaration(parameter.name,
          type: type, isFinal: parameter.isFinal)
        ..fileOffset = parameter.fileOffset;
      _extensionTearOffParameterMap[parameter] = newParameter;
      return newParameter;
    }

    VariableDeclaration extensionThis = copyParameter(
        function.positionalParameters.first,
        substitution.substituteType(function.positionalParameters.first.type),
        isOptional: false);

    DartType closureReturnType =
        substitution.substituteType(function.returnType);
    List<VariableDeclaration> closurePositionalParameters = [];
    List<Expression> closurePositionalArguments = [];

    for (int position = 0;
        position < function.positionalParameters.length;
        position++) {
      VariableDeclaration parameter = function.positionalParameters[position];
      if (position == 0) {
        /// Pass `this` as a captured variable.
        closurePositionalArguments
            .add(new VariableGet(extensionThis)..fileOffset = fileOffset);
      } else {
        DartType type = substitution.substituteType(parameter.type);
        VariableDeclaration newParameter = copyParameter(parameter, type,
            isOptional: position >= function.requiredParameterCount);
        closurePositionalParameters.add(newParameter);
        closurePositionalArguments
            .add(new VariableGet(newParameter)..fileOffset = fileOffset);
      }
    }
    List<VariableDeclaration> closureNamedParameters = [];
    List<NamedExpression> closureNamedArguments = [];
    for (VariableDeclaration parameter in function.namedParameters) {
      DartType type = substitution.substituteType(parameter.type);
      VariableDeclaration newParameter =
          copyParameter(parameter, type, isOptional: true);
      closureNamedParameters.add(newParameter);
      closureNamedArguments.add(new NamedExpression(parameter.name,
          new VariableGet(newParameter)..fileOffset = fileOffset));
    }

    Statement closureBody = new ReturnStatement(
        new StaticInvocation(
            _procedure,
            new Arguments(closurePositionalArguments,
                types: typeArguments, named: closureNamedArguments))
          ..fileOffset = fileOffset)
      ..fileOffset = fileOffset;

    FunctionExpression closure = new FunctionExpression(new FunctionNode(
        closureBody,
        typeParameters: closureTypeParameters,
        positionalParameters: closurePositionalParameters,
        namedParameters: closureNamedParameters,
        requiredParameterCount: _procedure.function.requiredParameterCount - 1,
        returnType: closureReturnType,
        asyncMarker: _procedure.function.asyncMarker,
        dartAsyncMarker: _procedure.function.dartAsyncMarker))
      ..fileOffset = fileOffset;

    _extensionTearOff
      ..name = new Name(
          '${extensionBuilder.name}|get#${name}', libraryBuilder.library)
      ..function = new FunctionNode(
          new ReturnStatement(closure)..fileOffset = fileOffset,
          typeParameters: tearOffTypeParameters,
          positionalParameters: [extensionThis],
          requiredParameterCount: 1,
          returnType: closure.function.functionType)
      ..fileUri = fileUri
      ..fileOffset = fileOffset;
    _extensionTearOff.function.parent = _extensionTearOff;
  }

  @override
  VariableDeclaration getExtensionTearOffParameter(int index) {
    if (_extensionTearOffParameterMap != null) {
      return _extensionTearOffParameterMap[getFormalParameter(index)];
    }
    return null;
  }

  @override
  Procedure get procedure => isPatch ? origin.procedure : _procedure;

  @override
  Procedure get extensionTearOff {
    if (isExtensionInstanceMember && kind == ProcedureKind.Method) {
      _extensionTearOff ??= new Procedure(null, ProcedureKind.Method, null,
          isStatic: true, isExtensionMember: true);
    }
    return _extensionTearOff;
  }

  @override
  Member get member => procedure;

  @override
  int finishPatch() {
    if (!isPatch) return 0;

    // TODO(ahe): restore file-offset once we track both origin and patch file
    // URIs. See https://github.com/dart-lang/sdk/issues/31579
    origin.procedure.fileUri = fileUri;
    origin.procedure.startFileOffset = _procedure.startFileOffset;
    origin.procedure.fileOffset = _procedure.fileOffset;
    origin.procedure.fileEndOffset = _procedure.fileEndOffset;
    origin.procedure.annotations
        .forEach((m) => m.fileOffset = _procedure.fileOffset);

    origin.procedure.isAbstract = _procedure.isAbstract;
    origin.procedure.isExternal = _procedure.isExternal;
    origin.procedure.function = _procedure.function;
    origin.procedure.function.parent = origin.procedure;
    return 1;
  }

  @override
  void becomeNative(Loader loader) {
    _procedure.isExternal = true;
    super.becomeNative(loader);
  }

  @override
  void applyPatch(Builder patch) {
    if (patch is ProcedureBuilderImpl) {
      if (checkPatch(patch)) {
        patch.actualOrigin = this;
        if (retainDataForTesting) {
          patchForTesting = patch;
        }
      }
    } else {
      reportPatchMismatch(patch);
    }
  }
}

class RedirectingFactoryBuilder extends ProcedureBuilderImpl {
  final ConstructorReferenceBuilder redirectionTarget;
  List<DartType> typeArguments;

  RedirectingFactoryBuilder(
      List<MetadataBuilder> metadata,
      int modifiers,
      TypeBuilder returnType,
      String name,
      List<TypeVariableBuilder> typeVariables,
      List<FormalParameterBuilder> formals,
      SourceLibraryBuilder compilationUnit,
      int startCharOffset,
      int charOffset,
      int charOpenParenOffset,
      int charEndOffset,
      [String nativeMethodName,
      this.redirectionTarget])
      : super(
            metadata,
            modifiers,
            returnType,
            name,
            typeVariables,
            formals,
            ProcedureKind.Factory,
            compilationUnit,
            startCharOffset,
            charOffset,
            charOpenParenOffset,
            charEndOffset,
            nativeMethodName);

  @override
  Statement get body => bodyInternal;

  @override
  void setRedirectingFactoryBody(Member target, List<DartType> typeArguments) {
    if (bodyInternal != null) {
      unexpected("null", "${bodyInternal.runtimeType}", charOffset, fileUri);
    }

    // Ensure that constant factories only have constant targets/bodies.
    if (isConst && !target.isConst) {
      library.addProblem(messageConstFactoryRedirectionToNonConst, charOffset,
          noLength, fileUri);
    }

    bodyInternal = new RedirectingFactoryBody(target, typeArguments);
    function.body = bodyInternal;
    bodyInternal?.parent = function;
    if (isPatch) {
      if (function.typeParameters != null) {
        Map<TypeParameter, DartType> substitution = <TypeParameter, DartType>{};
        for (int i = 0; i < function.typeParameters.length; i++) {
          substitution[function.typeParameters[i]] =
              new TypeParameterType(actualOrigin.function.typeParameters[i]);
        }
        List<DartType> newTypeArguments =
            new List<DartType>(typeArguments.length);
        for (int i = 0; i < newTypeArguments.length; i++) {
          newTypeArguments[i] = substitute(typeArguments[i], substitution);
        }
        typeArguments = newTypeArguments;
      }
      actualOrigin.setRedirectingFactoryBody(target, typeArguments);
    }
  }

  @override
  Procedure build(SourceLibraryBuilder library) {
    Procedure result = super.build(library);
    result.isRedirectingFactoryConstructor = true;
    if (redirectionTarget.typeArguments != null) {
      typeArguments =
          new List<DartType>(redirectionTarget.typeArguments.length);
      for (int i = 0; i < typeArguments.length; i++) {
        typeArguments[i] = redirectionTarget.typeArguments[i].build(library);
      }
    }
    return result;
  }

  @override
  int finishPatch() {
    if (!isPatch) return 0;

    super.finishPatch();

    if (origin is RedirectingFactoryBuilder) {
      RedirectingFactoryBuilder redirectingOrigin = origin;
      redirectingOrigin.typeArguments = typeArguments;
    }

    return 1;
  }
}
