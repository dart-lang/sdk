// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/test_utilities/function_ast_visitor.dart';
import 'package:analyzer/src/utilities/extensions/element.dart';
import 'package:collection/collection.dart';

/// Helper for finding elements declared in the resolved [unit].
class FindElement2 extends _FindElementBase {
  final CompilationUnit unit;

  FindElement2(this.unit);

  @override
  LibraryFragment get libraryFragment => unit.declaredFragment!;

  LibraryExportImpl export(String targetUri) {
    LibraryExport? result;

    for (var export in libraryFragment.libraryExports) {
      var exportedUri = export.exportedLibrary?.uri.toString();
      if (exportedUri == targetUri) {
        if (result != null) {
          throw StateError('Not unique: $targetUri');
        }
        result = export;
      }
    }

    if (result != null) {
      return result as LibraryExportImpl;
    }
    throw StateError('Not found: $targetUri');
  }

  FieldFormalParameterElement fieldFormalParameter(String name) {
    return parameter(name) as FieldFormalParameterElement;
  }

  TopLevelFunctionElement function(String name) {
    for (var function in libraryElement.topLevelFunctions) {
      if (function.name == name) {
        return function;
      }
    }
    throw StateError('Not found: $name');
  }

  LibraryImportImpl import(String targetUri, {bool mustBeUnique = true}) {
    LibraryImport? importElement;

    for (var libraryFragment in libraryFragment.withEnclosing2) {
      for (var import in libraryFragment.libraryImports) {
        var importedUri = import.importedLibrary?.uri.toString();
        if (importedUri == targetUri) {
          if (importElement == null) {
            importElement = import;
          } else if (mustBeUnique) {
            throw StateError('Not unique: $targetUri');
          }
        }
      }
    }

    if (importElement != null) {
      return importElement as LibraryImportImpl;
    }
    throw StateError('Not found: $targetUri');
  }

  ImportFindElement importFind(String targetUri, {bool mustBeUnique = true}) {
    var import = this.import(targetUri, mustBeUnique: mustBeUnique);
    return ImportFindElement(import);
  }

  LabelElement label(String name) {
    LabelElement? result;

    void updateResult(Element element) {
      if (element is LabelElement && element.name == name) {
        if (result != null) {
          throw StateError('Not unique: $name');
        }
        result = element;
      }
    }

    unit.accept(
      FunctionAstVisitor(
        label: (node) {
          updateResult(node.label.element!);
        },
      ),
    );

    if (result == null) {
      throw StateError('Not found: $name');
    }
    return result!;
  }

  LocalFunctionElement localFunction(String name) {
    LocalFunctionElement? result;

    unit.accept(
      FunctionAstVisitor(
        functionDeclarationStatement: (node) {
          var element = node.functionDeclaration.declaredFragment?.element;
          if (element is LocalFunctionElement && element.name == name) {
            if (result != null) {
              throw StateError('Not unique: $name');
            }
            result = element;
          }
        },
      ),
    );

    if (result == null) {
      throw StateError('Not found: $name');
    }
    return result!;
  }

  LocalVariableElement localVar(String name) {
    LocalVariableElement? result;

    void updateResult(Element element) {
      if (element is LocalVariableElement && element.name == name) {
        if (result != null) {
          throw StateError('Not unique: $name');
        }
        result = element;
      }
    }

    unit.accept(
      FunctionAstVisitor(
        catchClauseParameter: (node) {
          updateResult(node.declaredFragment!.element);
        },
        declaredIdentifier: (node) {
          updateResult(node.declaredFragment!.element);
        },
        declaredVariablePattern: (node) {
          updateResult(node.declaredFragment!.element);
        },
        variableDeclaration: (node) {
          updateResult(node.declaredFragment!.element);
        },
      ),
    );

    if (result == null) {
      throw StateError('Not found: $name');
    }
    return result!;
  }

  @override
  // TODO(fshcheglov): rename to formalParameter()
  FormalParameterElement parameter(String name) {
    FormalParameterElement? result;

    void findIn(List<FormalParameterElement> formalParameters) {
      for (var formalParameter in formalParameters) {
        if (formalParameter.name == name) {
          if (result != null) {
            throw StateError('Not unique: $name');
          }
          result = formalParameter;
        }
      }
    }

    void findInExecutables(List<ExecutableElement> executables) {
      for (var executable in executables) {
        findIn(executable.formalParameters);
      }
    }

    void findInClasses(List<InterfaceElement> classes) {
      for (var class_ in classes) {
        findInExecutables(class_.getters);
        findInExecutables(class_.setters);
        findInExecutables(class_.constructors);
        findInExecutables(class_.methods);
      }
    }

    findInExecutables(libraryElement.getters);
    findInExecutables(libraryElement.setters);
    findInExecutables(libraryElement.topLevelFunctions);

    findInClasses(libraryElement.classes);
    findInClasses(libraryElement.enums);
    findInClasses(libraryElement.extensionTypes);
    findInClasses(libraryElement.mixins);

    for (var extension_ in libraryElement.extensions) {
      findInExecutables(extension_.getters);
      findInExecutables(extension_.setters);
      findInExecutables(extension_.methods);
    }

    unit.accept(
      FunctionAstVisitor(
        functionExpression: (node, local) {
          if (local) {
            var functionElement = node.declaredFragment!.element;
            findIn(functionElement.formalParameters);
          }
        },
      ),
    );

    if (result != null) {
      return result!;
    }
    throw StateError('Not found: $name');
  }

  LibraryFragmentImpl part(String targetUri) {
    LibraryFragment? result;

    for (var partElement in libraryFragment.partIncludes) {
      var uri = partElement.uri;
      if (uri is DirectiveUriWithUnit) {
        var unitElement = uri.libraryFragment;
        if ('${unitElement.source.uri}' == targetUri) {
          if (result != null) {
            throw StateError('Not unique: $targetUri');
          }
          result = unitElement;
        }
      }
    }

    if (result != null) {
      return result as LibraryFragmentImpl;
    }
    throw StateError('Not found: $targetUri');
  }

  PartFindElement partFind(String targetUri) {
    var part = this.part(targetUri);
    return PartFindElement(part);
  }

  PrefixElement prefix(String name) {
    for (var libraryFragment in libraryFragment.withEnclosing2) {
      for (var importPrefix in libraryFragment.prefixes) {
        if (importPrefix.name == name) {
          return importPrefix;
        }
      }
    }
    throw StateError('Not found: $name');
  }

  TypeParameterElement typeParameter(String name) {
    TypeParameterElement? result;

    unit.accept(
      FunctionAstVisitor(
        typeParameter: (node) {
          var element = node.declaredFragment!.element;
          if (element.name == name) {
            if (result != null) {
              throw StateError('Not unique: $name');
            }
            result = element;
          }
        },
      ),
    );

    if (result != null) {
      return result!;
    }
    throw StateError('Not found: $name');
  }
}

/// Helper for searching imported elements.
class ImportFindElement extends _FindElementBase {
  final LibraryImport import;

  ImportFindElement(this.import);

  LibraryElement get importedLibrary => import.importedLibrary!;

  @override
  LibraryFragment get libraryFragment {
    return importedLibrary.firstFragment;
  }

  PrefixElement? get prefix => import.prefix?.element;
}

class PartFindElement extends _FindElementBase {
  @override
  final LibraryFragment libraryFragment;

  PartFindElement(this.libraryFragment);
}

abstract class _FindElementBase {
  LibraryElement get libraryElement => libraryFragment.element;

  LibraryFragment get libraryFragment;

  ClassElement class_(String name) {
    for (var class_ in libraryElement.classes) {
      if (class_.name == name) {
        return class_;
      }
    }
    throw StateError('Not found: $name');
  }

  InterfaceElement classOrMixin(String name) {
    for (var class_ in libraryElement.classes) {
      if (class_.name == name) {
        return class_;
      }
    }
    for (var mixin in libraryElement.mixins) {
      if (mixin.name == name) {
        return mixin;
      }
    }
    throw StateError('Not found: $name');
  }

  ConstructorElement constructor(String name, {String? of}) {
    assert(name != '');

    ConstructorElement? result;

    void findIn(List<ConstructorElement> constructors) {
      for (var constructor in constructors) {
        if (constructor.name == name) {
          if (result != null) {
            throw StateError('Not unique: $name');
          }
          result = constructor;
        }
      }
    }

    for (var class_ in libraryElement.classes) {
      if (of == null || class_.name == of) {
        findIn(class_.constructors);
      }
    }

    for (var enum_ in libraryElement.enums) {
      if (of == null || enum_.name == of) {
        findIn(enum_.constructors);
      }
    }

    for (var extensionType in libraryElement.extensionTypes) {
      if (of == null || extensionType.name == of) {
        findIn(extensionType.constructors);
      }
    }

    if (result != null) {
      return result!;
    }
    throw StateError('Not found: $name');
  }

  EnumElement enum_(String name) {
    for (var enum_ in libraryElement.enums) {
      if (enum_.name == name) {
        return enum_;
      }
    }
    throw StateError('Not found: $name');
  }

  ExtensionElement extension_(String name) {
    for (var extension_ in libraryElement.extensions) {
      if (extension_.name == name) {
        return extension_;
      }
    }
    throw StateError('Not found: $name');
  }

  ExtensionTypeElement extensionType(String name) {
    for (var element in libraryElement.extensionTypes) {
      if (element.name == name) {
        return element;
      }
    }
    throw StateError('Not found: $name');
  }

  FieldElement field(String name, {String? of}) {
    return _findInClassesLike(
      className: of,
      fromClass: (element) => element.fields.named(name),
      fromExtension: (element) => element.fields.named(name),
    );
  }

  GetterElement getter(String name, {String? of}) {
    return _findInClassesLike(
      className: of,
      fromClass: (element) => element.getters.named(name),
      fromExtension: (element) => element.getters.named(name),
    );
  }

  MethodElement method(String name, {String? of}) {
    return _findInClassesLike(
      className: of,
      fromClass: (element) => element.methods.named(name),
      fromExtension: (element) => element.methods.named(name),
    );
  }

  MixinElement mixin(String name) {
    for (var mixin in libraryElement.mixins) {
      if (mixin.name == name) {
        return mixin;
      }
    }
    throw StateError('Not found: $name');
  }

  FormalParameterElement parameter(String name) {
    FormalParameterElement? result;

    for (var class_ in libraryElement.classes) {
      for (var constructor in class_.constructors) {
        for (var formalParameter in constructor.formalParameters) {
          if (formalParameter.name == name) {
            if (result != null) {
              throw StateError('Not unique: $name');
            }
            result = formalParameter;
          }
        }
      }
    }

    if (result != null) {
      return result;
    }
    throw StateError('Not found: $name');
  }

  SetterElement setter(String name, {String? of}) {
    return _findInClassesLike(
      className: of,
      fromClass: (element) => element.setters.named(name),
      fromExtension: (element) => element.setters.named(name),
    );
  }

  TopLevelFunctionElement topFunction(String name) {
    for (var function in libraryElement.topLevelFunctions) {
      if (function.name == name) {
        return function;
      }
    }
    throw StateError('Not found: $name');
  }

  GetterElement topGet(String name) {
    return topVar(name).getter!;
  }

  SetterElement topSet(String name) {
    return topVar(name).setter!;
  }

  TopLevelVariableElementImpl topVar(String name) {
    for (var variable in libraryElement.topLevelVariables) {
      if (variable.name == name) {
        return variable as TopLevelVariableElementImpl;
      }
    }
    throw StateError('Not found: $name');
  }

  TypeAliasElement typeAlias(String name) {
    for (var element in libraryElement.typeAliases) {
      if (element.name == name) {
        return element;
      }
    }
    throw StateError('Not found: $name');
  }

  ConstructorElement unnamedConstructor(String name) {
    return _findInClassesLike(
      className: name,
      fromClass: (e) => e.constructors.firstWhereOrNull((element) {
        return element.name == 'new';
      }),
      fromExtension: (_) => null,
    );
  }

  ExtensionElement unnamedExtension() {
    for (var extension_ in libraryElement.extensions) {
      if (extension_.name == null) {
        return extension_;
      }
    }
    throw StateError('Not found: an unnamed extension');
  }

  T _findInClassesLike<T extends Element>({
    required String? className,
    required T? Function(InterfaceElement element) fromClass,
    required T? Function(ExtensionElement element) fromExtension,
  }) {
    bool filter(InstanceElement element) {
      return className == null || element.name == className;
    }

    var classes = [
      ...libraryElement.classes,
      ...libraryElement.enums,
      ...libraryElement.extensionTypes,
      ...libraryElement.mixins,
    ];

    var results = [
      ...classes.where(filter).map(fromClass),
      ...libraryElement.extensions.where(filter).map(fromExtension),
    ].nonNulls.toList();

    var result = results.singleOrNull;
    if (result != null) {
      return result;
    }

    if (results.isEmpty) {
      throw StateError('Not found');
    } else {
      throw StateError('Not unique');
    }
  }
}

extension<T extends Element> on List<T> {
  T? named(String targetName) {
    for (var element in this) {
      if (element.name == targetName) {
        return element;
      }
    }
    return null;
  }
}

extension ExecutableElementExtensions on ExecutableElement {
  FormalParameterElement parameter(String name) {
    for (var formalParameter in formalParameters) {
      if (formalParameter.name == name) {
        return formalParameter;
      }
    }
    throw StateError('Not found: $name');
  }

  SuperFormalParameterElement superFormalParameter(String name) {
    for (var formalParameter in formalParameters) {
      if (formalParameter is SuperFormalParameterElement &&
          formalParameter.name == name) {
        return formalParameter;
      }
    }
    throw StateError('Not found: $name');
  }
}
