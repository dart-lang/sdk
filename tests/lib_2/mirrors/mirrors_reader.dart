// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICESNE file.

library mirrors.reader;

import 'dart:mirrors';
import 'mirrors_visitor.dart';

class ReadError {
  final String tag;
  final exception;
  final StackTrace stackTrace;

  ReadError(this.tag, this.exception, this.stackTrace);
}

class MirrorsReader extends MirrorsVisitor {
  /// Produce verbose output.
  final bool verbose;

  /// Include stack trace in the error report.
  final bool includeStackTrace;

  bool fatalError = false;
  Set<Mirror> visited = new Set<Mirror>();
  Set<TypeMirror> declarations = new Set<TypeMirror>();
  Set<TypeMirror> instantiations = new Set<TypeMirror>();
  List<ReadError> errors = <ReadError>[];
  List<Mirror> queue = <Mirror>[];

  MirrorsReader({this.verbose: false, this.includeStackTrace: false});

  void checkMirrorSystem(MirrorSystem mirrorSystem) {
    visitMirrorSystem(mirrorSystem);
    if (!errors.isEmpty) {
      Set<String> errorMessages = new Set<String>();
      for (ReadError error in errors) {
        String text = 'Mirrors read error: ${error.tag}=${error.exception}';
        if (includeStackTrace) {
          text = '$text\n${error.stackTrace}';
        }
        if (errorMessages.add(text)) {
          print(text);
        }
      }
      throw 'Unexpected errors occurred reading mirrors.';
    }
  }

  // Skip mirrors so that each mirror is only visited once.
  bool skipMirror(Mirror mirror) {
    if (fatalError) return true;
    if (mirror is TypeMirror) {
      if (mirror.isOriginalDeclaration) {
        // Visit the declaration once.
        return !declarations.add(mirror);
      } else {
        // Visit only one instantiation.
        return !instantiations.add(mirror.originalDeclaration);
      }
    }
    return !visited.add(mirror);
  }

  reportError(var receiver, String tag, var exception, StackTrace stackTrace) {
    String errorTag = '${receiver.runtimeType}.$tag';
    errors.add(new ReadError(errorTag, exception, stackTrace));
  }

  visitUnsupported(var receiver, String tag, UnsupportedError exception,
      StackTrace stackTrace) {
    if (verbose) print('visitUnsupported:$receiver.$tag:$exception');
    if (!expectUnsupported(receiver, tag, exception) &&
        !allowUnsupported(receiver, tag, exception)) {
      reportError(receiver, tag, exception, stackTrace);
    }
  }

  /// Override to specify that access is expected to be unsupported.
  bool expectUnsupported(
          var receiver, String tag, UnsupportedError exception) =>
      false;

  /// Override to allow unsupported access.
  bool allowUnsupported(var receiver, String tag, UnsupportedError exception) =>
      false;

  /// Evaluates the function [f]. Subclasses can override this to handle
  /// specific exceptions.
  evaluate(f()) => f();

  visit(var receiver, String tag, var value) {
    if (value is Function) {
      try {
        var result = evaluate(value);
        if (expectUnsupported(receiver, tag, null)) {
          reportError(receiver, tag, 'Expected UnsupportedError.', null);
        }
        return visit(receiver, tag, result);
      } on UnsupportedError catch (e, s) {
        visitUnsupported(receiver, tag, e, s);
      } on OutOfMemoryError catch (e, s) {
        reportError(receiver, tag, e, s);
        fatalError = true;
      } on StackOverflowError catch (e, s) {
        reportError(receiver, tag, e, s);
        fatalError = true;
      } catch (e, s) {
        reportError(receiver, tag, e, s);
      }
    } else {
      if (value is Mirror) {
        if (!skipMirror(value)) {
          if (verbose) print('visit:$receiver.$tag=$value');
          bool drain = queue.isEmpty;
          queue.add(value);
          if (drain) {
            while (!queue.isEmpty) {
              visitMirror(queue.removeLast());
            }
          }
        }
      } else if (value is MirrorSystem) {
        visitMirrorSystem(value);
      } else if (value is SourceLocation) {
        visitSourceLocation(value);
      } else if (value is Iterable) {
        // TODO(johnniwinther): Merge with `immutable_collections_test.dart`.
        value.forEach((e) {
          visit(receiver, tag, e);
        });
      } else if (value is Map) {
        value.forEach((k, v) {
          visit(receiver, tag, k);
          visit(receiver, tag, v);
        });
      }
    }
    return value;
  }

  visitMirrorSystem(MirrorSystem mirrorSystem) {
    visit(mirrorSystem, 'dynamicType', () => mirrorSystem.dynamicType);
    visit(mirrorSystem, 'voidType', () => mirrorSystem.voidType);
    visit(mirrorSystem, 'libraries', () => mirrorSystem.libraries);
  }

  visitClassMirror(ClassMirror mirror) {
    super.visitClassMirror(mirror);
    visit(mirror, 'declarations', () => mirror.declarations);
    bool hasReflectedType =
        visit(mirror, 'hasReflectedType', () => mirror.hasReflectedType);
    visit(mirror, 'instanceMembers', () => mirror.instanceMembers);
    visit(mirror, 'mixin', () => mirror.mixin);
    if (hasReflectedType) {
      visit(mirror, 'reflectedType', () => mirror.reflectedType);
    }
    visit(mirror, 'staticMembers', () => mirror.staticMembers);
    visit(mirror, 'superclass', () => mirror.superclass);
    visit(mirror, 'superinterfaces', () => mirror.superinterfaces);
  }

  visitDeclarationMirror(DeclarationMirror mirror) {
    super.visitDeclarationMirror(mirror);
    visit(mirror, 'isPrivate', () => mirror.isPrivate);
    visit(mirror, 'isTopLevel', () => mirror.isTopLevel);
    visit(mirror, 'location', () => mirror.location);
    visit(mirror, 'metadata', () => mirror.metadata);
    visit(mirror, 'owner', () => mirror.owner);
    visit(mirror, 'qualifiedName', () => mirror.qualifiedName);
    visit(mirror, 'simpleName', () => mirror.simpleName);
  }

  visitFunctionTypeMirror(FunctionTypeMirror mirror) {
    super.visitFunctionTypeMirror(mirror);
    visit(mirror, 'callMethod', () => mirror.callMethod);
    visit(mirror, 'parameters', () => mirror.parameters);
    visit(mirror, 'returnType', () => mirror.returnType);
  }

  visitInstanceMirror(InstanceMirror mirror) {
    super.visitInstanceMirror(mirror);
    bool hasReflectee =
        visit(mirror, 'hasReflectee', () => mirror.hasReflectee);
    if (hasReflectee) {
      visit(mirror, 'reflectee', () => mirror.reflectee);
    }
    visit(mirror, 'type', () => mirror.type);
  }

  visitLibraryMirror(LibraryMirror mirror) {
    super.visitLibraryMirror(mirror);
    visit(mirror, 'declarations', () => mirror.declarations);
    visit(mirror, 'uri', () => mirror.uri);
  }

  visitMethodMirror(MethodMirror mirror) {
    super.visitMethodMirror(mirror);
    visit(mirror, 'constructorName', () => mirror.constructorName);
    visit(mirror, 'isAbstract', () => mirror.isAbstract);
    visit(mirror, 'isConstConstructor', () => mirror.isConstConstructor);
    visit(mirror, 'isConstructor', () => mirror.isConstructor);
    visit(mirror, 'isFactoryConstructor', () => mirror.isFactoryConstructor);
    visit(mirror, 'isGenerativeConstructor',
        () => mirror.isGenerativeConstructor);
    visit(mirror, 'isGetter', () => mirror.isGetter);
    visit(mirror, 'isOperator', () => mirror.isOperator);
    visit(mirror, 'isRedirectingConstructor',
        () => mirror.isRedirectingConstructor);
    visit(mirror, 'isRegularMethod', () => mirror.isRegularMethod);
    visit(mirror, 'isSetter', () => mirror.isSetter);
    visit(mirror, 'isStatic', () => mirror.isStatic);
    visit(mirror, 'isSynthetic', () => mirror.isSynthetic);
    visit(mirror, 'parameters', () => mirror.parameters);
    visit(mirror, 'returnType', () => mirror.returnType);
    visit(mirror, 'source', () => mirror.source);
  }

  visitParameterMirror(ParameterMirror mirror) {
    super.visitParameterMirror(mirror);
    bool hasDefaultValue =
        visit(mirror, 'hasDefaultValue', () => mirror.hasDefaultValue);
    if (hasDefaultValue) {
      visit(mirror, 'defaultValue', () => mirror.defaultValue);
    }
    visit(mirror, 'isNamed', () => mirror.isNamed);
    visit(mirror, 'isOptional', () => mirror.isOptional);
    visit(mirror, 'type', () => mirror.type);
  }

  visitSourceLocation(SourceLocation location) {}

  visitTypedefMirror(TypedefMirror mirror) {
    super.visitTypedefMirror(mirror);
    visit(mirror, 'referent', () => mirror.referent);
  }

  visitTypeMirror(TypeMirror mirror) {
    super.visitTypeMirror(mirror);
    visit(mirror, 'isOriginalDeclaration', () => mirror.isOriginalDeclaration);
    visit(mirror, 'originalDeclaration', () => mirror.originalDeclaration);
    visit(mirror, 'typeArguments', () => mirror.typeArguments);
    visit(mirror, 'typeVariables', () => mirror.typeVariables);
  }

  visitTypeVariableMirror(TypeVariableMirror mirror) {
    super.visitTypeVariableMirror(mirror);
    visit(mirror, 'upperBound', () => mirror.upperBound);
    visit(mirror, 'isStatic', () => mirror.isStatic);
  }

  visitVariableMirror(VariableMirror mirror) {
    super.visitVariableMirror(mirror);
    visit(mirror, 'isConst', () => mirror.isConst);
    visit(mirror, 'isFinal', () => mirror.isFinal);
    visit(mirror, 'isStatic', () => mirror.isStatic);
    visit(mirror, 'type', () => mirror.type);
  }
}
