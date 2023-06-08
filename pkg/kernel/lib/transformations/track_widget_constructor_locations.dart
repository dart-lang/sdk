// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library kernel.transformations.track_widget_constructor_locations;

import '../ast.dart';
import '../target/changed_structure_notifier.dart';

// Parameter name used to track where widget constructor calls were made from.
//
// The parameter name contains a randomly generated hex string to avoid
// collision with user generated parameters.
const String _creationLocationParameterName =
    r'$creationLocationd_0dea112b090073317d4';

/// Name of private field added to the Widget class and any other classes that
/// implement Widget.
///
/// Regardless of what library a class implementing Widget is defined in, the
/// private field will always be defined in the context of the widget_inspector
/// library ensuring no name conflicts with regular fields.
const String _locationFieldName = r'_location';

bool _hasNamedParameter(FunctionNode function, String name) {
  return function.namedParameters
      .any((VariableDeclaration parameter) => parameter.name == name);
}

bool _hasNamedArgument(Arguments arguments, String argumentName) {
  return arguments.named
      .any((NamedExpression argument) => argument.name == argumentName);
}

VariableDeclaration? _getNamedParameter(
  FunctionNode function,
  String parameterName,
) {
  for (VariableDeclaration parameter in function.namedParameters) {
    if (parameter.name == parameterName) {
      return parameter;
    }
  }
  return null;
}

// TODO(jacobr): find a solution that supports optional positional parameters.
/// Add the creation location to the arguments list if possible.
///
/// Returns whether the creation location argument could be added. We cannot
/// currently add the named argument for functions with optional positional
/// parameters as the current scheme requires adding the creation location as a
/// named parameter. Fortunately that is not a significant issue in practice as
/// no Widget classes in package:flutter have optional positional parameters.
/// This code degrades gracefully for constructors with optional positional
/// parameters by skipping adding the creation location argument rather than
/// failing.
void _maybeAddCreationLocationArgument(
  Arguments arguments,
  FunctionNode function,
  Expression creationLocation,
  Class locationClass,
) {
  if (_hasNamedArgument(arguments, _creationLocationParameterName)) {
    return;
  }
  if (!_hasNamedParameter(function, _creationLocationParameterName)) {
    // TODO(jakemac): We don't apply the transformation to dependencies kernel
    // outlines, so instead we just assume the named parameter exists.
    //
    // The only case in which it shouldn't exist is if the function has optional
    // positional parameters so it cannot have optional named parameters.
    if (function.requiredParameterCount !=
        function.positionalParameters.length) {
      return;
    }
  }

  final NamedExpression namedArgument =
      new NamedExpression(_creationLocationParameterName, creationLocation);
  namedArgument.parent = arguments;
  arguments.named.add(namedArgument);
}

/// Adds a named parameter to a function if the function does not already have
/// a named parameter with the name or optional positional parameters.
bool _maybeAddNamedParameter(
  FunctionNode function,
  VariableDeclaration variable,
) {
  if (_hasNamedParameter(function, _creationLocationParameterName)) {
    // Gracefully handle if this method is called on a function that has already
    // been transformed.
    return false;
  }
  // Function has optional positional parameters so cannot have optional named
  // parameters.
  if (function.requiredParameterCount != function.positionalParameters.length) {
    return false;
  }
  variable.parent = function;
  function.namedParameters.add(variable);
  return true;
}

/// Transformer that modifies all calls to Widget constructors and "Widget
/// factories" to include a _Location parameter specifying the location where
/// the constructor or widget factory call was made.
///
/// This transformer requires that all Widget constructors and Widget factories
/// have already been transformed to have a named parameter with the name
/// specified by `_locationParameterName`.
///
/// A "Widget factory" is an extension instance method annotated with the
/// `@widgetFactory` annotations. A _Location parameter is added to such methods
/// and this is used as the location value for all Widget constructor
/// invocations within the method.
class _WidgetCallSiteTransformer extends Transformer {
  /// The [Widget] class defined in the `package:flutter` library.
  ///
  /// Used to perform is-tests to determine whether Dart constructor calls are
  /// creating [Widget] objects.
  final Class _widgetClass;

  /// The _Location class defined in the `package:flutter` library.
  final Class _locationClass;

  final WidgetCreatorTracker _tracker;

  /// The creation location parameter of the extension factory method enclosing
  /// the node that is currently being transformed.
  ///
  /// Used to flow the creation location parameter to the call sites of widget
  /// constructors and extension factory methods within an enclosing extension
  /// factory method.
  Expression? _currentExtensionFactoryLocationParameter;

  /// Current factory constructor that node being transformed is inside.
  ///
  /// Used to flow the location passed in as an argument to the factory to the
  /// actual constructor call within the factory.
  Procedure? _currentFactory;

  /// Library that contains the transformed call sites.
  ///
  /// The transformation of the call sites is affected by the NNBD opt-in status
  /// of the library.
  Library? _currentLibrary;

  _WidgetCallSiteTransformer({
    required Class widgetClass,
    required Class locationClass,
    required WidgetCreatorTracker tracker,
  })  : _widgetClass = widgetClass,
        _locationClass = locationClass,
        _tracker = tracker;

  /// Builds a call to the const constructor of the _Location
  /// object specifying the location where a constructor call was made and
  /// optionally the locations for all parameters passed in.
  ///
  /// Specifying the parameters passed in is an experimental feature. With
  /// access to the source code of an application you could determine the
  /// locations of the parameters passed in from the source location of the
  /// constructor call but it is convenient to bundle the location and names
  /// of the parameters passed in so that tools can show parameter locations
  /// without re-parsing the source code.
  ConstructorInvocation _constructLocation(
    Location location, {
    String? name,
  }) {
    final List<NamedExpression> arguments = <NamedExpression>[
      new NamedExpression('file', new StringLiteral(location.file.toString())),
      new NamedExpression('line', new IntLiteral(location.line)),
      new NamedExpression('column', new IntLiteral(location.column)),
      if (name != null) new NamedExpression('name', new StringLiteral(name))
    ];

    return new ConstructorInvocation(
      _locationClass.constructors.first,
      new Arguments(<Expression>[], named: arguments),
      isConst: true,
    );
  }

  @override
  Procedure visitProcedure(Procedure node) {
    if (_isWidgetFactory(node)) {
      final VariableDeclaration locationParameter =
          node.function.namedParameters.firstWhere(
        (parameter) => parameter.name == _creationLocationParameterName,
      );
      _currentExtensionFactoryLocationParameter =
          VariableGet(locationParameter);
      node.transformChildren(this);
      _currentExtensionFactoryLocationParameter = null;
      return node;
    }
    if (node.isFactory) {
      _currentFactory = node;
      node.transformChildren(this);
      _currentFactory = null;
      return node;
    }
    node.transformChildren(this);
    return node;
  }

  bool _isSubclassOfWidget(Class clazz) {
    return _tracker._isSubclassOf(clazz, _widgetClass);
  }

  bool _isWidgetFactory(Procedure node) {
    return node.isExtensionMember &&
        _hasNamedParameter(node.function, _creationLocationParameterName);
  }

  @override
  StaticInvocation visitStaticInvocation(StaticInvocation node) {
    node.transformChildren(this);
    final Procedure target = node.target;
    if (target.isFactory) {
      final Class constructedClass = target.enclosingClass!;
      if (!_isSubclassOfWidget(constructedClass)) {
        return node;
      }

      _addLocationArgument(
        node,
        target.function,
        constructedClass: constructedClass,
        isConst: node.isConst,
      );
      return node;
    }
    if (_isWidgetFactory(target)) {
      _addLocationArgument(node, target.function);
      return node;
    }
    return node;
  }

  void _addLocationArgument(
    InvocationExpression node,
    FunctionNode function, {
    Class? constructedClass,
    bool isConst = false,
  }) {
    Expression? location = _currentExtensionFactoryLocationParameter;
    if (location == null ||
        // We cannot pass the location parameter of the enclosing extension
        // factory method to a const constructor call, so we fallback to
        // passing the location of the constructor call.
        isConst) {
      location =
          _computeLocation(node, function, constructedClass, isConst: isConst);
    }
    _maybeAddCreationLocationArgument(
      node.arguments,
      function,
      location,
      _locationClass,
    );
  }

  @override
  ConstructorInvocation visitConstructorInvocation(ConstructorInvocation node) {
    node.transformChildren(this);

    final Constructor constructor = node.target;
    final Class constructedClass = constructor.enclosingClass;
    if (!_isSubclassOfWidget(constructedClass)) {
      return node;
    }

    _addLocationArgument(
      node,
      constructor.function,
      constructedClass: constructedClass,
      isConst: node.isConst,
    );
    return node;
  }

  Expression _computeLocation(
    InvocationExpression node,
    FunctionNode function,
    Class? constructedClass, {
    bool isConst = false,
  }) {
    assert(constructedClass != null || !isConst);

    // For factory constructors we need to use the location specified as an
    // argument to the factory constructor rather than the location
    if (constructedClass != null &&
        _currentFactory != null &&
        _tracker._isSubclassOf(
            constructedClass, _currentFactory!.enclosingClass!) &&
        // If the constructor invocation is constant we cannot refer to the
        // location parameter of the surrounding factory since it isn't a
        // constant expression.
        !isConst) {
      final VariableDeclaration? creationLocationParameter = _getNamedParameter(
        _currentFactory!.function,
        _creationLocationParameterName,
      );
      if (creationLocationParameter != null) {
        return new VariableGet(creationLocationParameter);
      }
    }

    return _constructLocation(
      node.location!,
      name: constructedClass?.name ??
          // For extension factory methods we use the name of the method.
          (function.parent! as Procedure).name.text,
    );
  }

  void enterLibrary(Library library) {
    assert(
        _currentLibrary == null,
        "Attempting to enter library '${library.fileUri}' "
        "without having exited library '${_currentLibrary!.fileUri}'.");
    _currentLibrary = library;
  }

  void exitLibrary() {
    assert(_currentLibrary != null,
        "Attempting to exit a library without having entered one.");
    _currentLibrary = null;
  }
}

/// Rewrites all Widget constructors, constructor invocations,
/// "Widget factories", and Widget factory invocations to add a
/// parameter specifying the location the constructor/factory was called from.
///
/// The creation location is stored as a private field named `_location`
/// on the base Widget class and flowed through the constructors using a named
/// parameter.
///
/// A "Widget factory" is an extension instance method annotated with the
/// `@widgetFactory` annotations. A _Location parameter is added to such methods
/// and this is used as the location value for all Widget constructor
/// invocations within the method.
class WidgetCreatorTracker {
  bool _foundClasses = false;
  late Class _widgetClass;
  late Class _locationClass;

  /// Marker interface indicating that a private _location field is
  /// available.
  late Class _hasCreationLocationClass;

  /// Annotation class used to mark an extension method as a "Widget factory".
  ///
  /// Widgets created within the body of an extension factory method will have
  /// their creation location set to the call site of the extension factory
  /// method.
  Class? _widgetFactoryClass;

  void _resolveFlutterClasses(Iterable<Library> libraries) {
    // If the Widget or Debug location classes have been updated we need to get
    // the latest version
    bool foundWidgetClass = false;
    bool foundHasCreationLocationClass = false;
    bool foundLocationClass = false;
    for (Library library in libraries) {
      final Uri importUri = library.importUri;
      if (importUri.isScheme('package')) {
        if (importUri.path == 'flutter/src/widgets/framework.dart') {
          for (Class class_ in library.classes) {
            if (class_.name == 'Widget') {
              _widgetClass = class_;
              foundWidgetClass = true;
            }
          }
        } else {
          if (importUri.path == 'flutter/src/widgets/widget_inspector.dart') {
            for (Class class_ in library.classes) {
              if (class_.name == '_HasCreationLocation') {
                _hasCreationLocationClass = class_;
                foundHasCreationLocationClass = true;
              } else if (class_.name == '_Location') {
                _locationClass = class_;
                foundLocationClass = true;
              } else if (class_.name == '_WidgetFactory') {
                _widgetFactoryClass = class_;
              }
            }
          }
        }
      }
    }
    // TODO(johnniwinther): Require the [_widgetFactoryClass] once the
    //  `widgetFactory` is stably in flutter.
    _foundClasses =
        foundWidgetClass && foundHasCreationLocationClass && foundLocationClass;
  }

  /// Modify [clazz] to add a field named [_locationFieldName] that is the
  /// first parameter of all constructors of the class.
  ///
  /// This method should only be called for classes that implement but do not
  /// extend [Widget].
  void _transformClassImplementingWidget(
      Class clazz, ChangedStructureNotifier? changedStructureNotifier) {
    if (clazz.fields
        .any((Field field) => field.name.text == _locationFieldName)) {
      // This class has already been transformed. Skip
      return;
    }
    clazz.implementedTypes
        .add(new Supertype(_hasCreationLocationClass, <DartType>[]));
    changedStructureNotifier?.registerClassHierarchyChange(clazz);

    // We intentionally use the library context of the _HasCreationLocation
    // class for the private field even if [clazz] is in a different library
    // so that all classes implementing Widget behave consistently.
    final Name fieldName = new Name(
      _locationFieldName,
      _hasCreationLocationClass.enclosingLibrary,
    );
    final Field locationField = new Field.immutable(fieldName,
        type:
            new InterfaceType(_locationClass, clazz.enclosingLibrary.nullable),
        isFinal: true,
        fieldReference: clazz.reference.canonicalName
            ?.getChildFromFieldWithName(fieldName)
            .reference,
        getterReference: clazz.reference.canonicalName
            ?.getChildFromFieldGetterWithName(fieldName)
            .reference,
        fileUri: clazz.fileUri);
    clazz.addField(locationField);

    final Set<Constructor> _handledConstructors =
        new Set<Constructor>.identity();

    void handleConstructor(Constructor constructor) {
      if (!_handledConstructors.add(constructor)) {
        return;
      }
      assert(!_hasNamedParameter(
        constructor.function,
        _creationLocationParameterName,
      ));
      final VariableDeclaration variable = new VariableDeclaration(
          _creationLocationParameterName,
          type: new InterfaceType(
              _locationClass, clazz.enclosingLibrary.nullable),
          initializer: new NullLiteral());
      if (!_maybeAddNamedParameter(constructor.function, variable)) {
        return;
      }

      bool hasRedirectingInitializer = false;
      for (Initializer initializer in constructor.initializers) {
        if (initializer is RedirectingInitializer) {
          if (initializer.target.enclosingClass == clazz) {
            // We need to handle this constructor first or the call to
            // addDebugLocationArgument below will fail due to the named
            // parameter not yet existing on the constructor.
            handleConstructor(initializer.target);
          }
          _maybeAddCreationLocationArgument(
            initializer.arguments,
            initializer.target.function,
            new VariableGet(variable),
            _locationClass,
          );
          hasRedirectingInitializer = true;
          break;
        }
      }
      if (!hasRedirectingInitializer) {
        constructor.initializers.add(
            new FieldInitializer(locationField, new VariableGet(variable)));
        // TODO(jacobr): add an assert verifying the locationField is not
        // null. Currently, we cannot safely add this assert because we do not
        // handle Widget classes with optional positional arguments. There are
        // no Widget classes in the flutter repo with optional positional
        // arguments but it is possible users could add classes with optional
        // positional arguments.
        //
        // constructor.initializers.add(new AssertInitializer(
        //   new AssertStatement(
        //     new IsExpression(
        //         new VariableGet(variable), _locationClass.thisType),
        //     conditionStartOffset: constructor.fileOffset,
        //     conditionEndOffset: constructor.fileOffset,
        // )));
      }
    }

    // Add named parameters to all constructors.
    clazz.constructors.forEach(handleConstructor);
  }

  /// Transform the given [libraries].
  ///
  /// The libraries from [module] is searched for the Widget class,
  /// the _Location class, the _HasCreationLocation class and the
  /// _WidgetFactory class.
  /// If the component does not contain them, the ones from a previous run is
  /// used (if any), otherwise no transformation is performed.
  ///
  /// Upon transformation the [changedStructureNotifier] (if provided) is used
  /// to notify the listener that  that class hierarchy of certain classes has
  /// changed. This is necessary for instance when doing an incremental
  /// compilation where the class hierarchy is kept between compiles and thus
  /// has to be kept up to date.
  void transform(Component module, List<Library> libraries,
      ChangedStructureNotifier? changedStructureNotifier) {
    if (libraries.isEmpty) {
      return;
    }

    _resolveFlutterClasses(module.libraries);

    if (!_foundClasses) {
      // This application doesn't actually use the package:flutter library.
      return;
    }

    final Set<Class> transformedClasses = new Set<Class>.identity();
    final Set<Extension> transformedExtensions = new Set<Extension>.identity();
    final Set<Library> librariesToTransform = new Set<Library>.identity()
      ..addAll(libraries);

    for (Library library in libraries) {
      for (Class class_ in library.classes) {
        _transformWidgetConstructors(
          librariesToTransform,
          transformedClasses,
          class_,
          changedStructureNotifier,
        );
      }
      if (_widgetFactoryClass != null) {
        for (Extension extension in library.extensions) {
          _transformWidgetFactories(
            librariesToTransform,
            transformedExtensions,
            extension,
          );
        }
      }
    }

    // Transform call sites to pass the location parameter.
    final _WidgetCallSiteTransformer callsiteTransformer =
        new _WidgetCallSiteTransformer(
      widgetClass: _widgetClass,
      locationClass: _locationClass,
      tracker: this,
    );

    for (Library library in libraries) {
      callsiteTransformer.enterLibrary(library);
      library.transformChildren(callsiteTransformer);
      callsiteTransformer.exitLibrary();
    }
  }

  bool _isSubclassOfWidget(Class clazz) => _isSubclassOf(clazz, _widgetClass);

  bool _isSubclassOf(Class a, Class b) {
    // TODO(askesc): Cache results.
    // TODO(askesc): Test for subtype rather than subclass.
    Class? current = a;
    while (current != null) {
      if (current == b) return true;
      current = current.superclass;
    }
    return false;
  }

  bool _hasWidgetFactoryAnnotation(Procedure node) =>
      _isAnnotatedWithNamedValueOfType(node, _widgetFactoryClass!);

  bool _isAnnotatedWithNamedValueOfType(
    Annotatable node,
    Class annotationClass,
  ) {
    return node.annotations.any((annotation) {
      if (annotation is! StaticGet) {
        return false;
      }
      final Member target = annotation.target;
      if (target is! Field) {
        return false;
      }
      final DartType type = target.type;
      if (type is! InterfaceType) {
        return false;
      }
      if (type.nullability == Nullability.nullable) {
        return false;
      }
      return type.classNode == _widgetFactoryClass;
    });
  }

  void _transformWidgetConstructors(
      Set<Library> librariesToBeTransformed,
      Set<Class> transformedClasses,
      Class clazz,
      ChangedStructureNotifier? changedStructureNotifier) {
    if (!_isSubclassOfWidget(clazz) ||
        !librariesToBeTransformed.contains(clazz.enclosingLibrary) ||
        !transformedClasses.add(clazz)) {
      return;
    }

    // Ensure super classes have been transformed before this class.
    if (clazz.superclass != null &&
        !transformedClasses.contains(clazz.superclass)) {
      _transformWidgetConstructors(
        librariesToBeTransformed,
        transformedClasses,
        clazz.superclass!,
        changedStructureNotifier,
      );
    }

    for (Procedure procedure in clazz.procedures) {
      if (procedure.isFactory) {
        _maybeAddNamedParameter(
          procedure.function,
          new VariableDeclaration(_creationLocationParameterName,
              type: new InterfaceType(
                  _locationClass, clazz.enclosingLibrary.nullable),
              initializer: new NullLiteral()),
        );
      }
    }

    // Handle the widget class and classes that implement but do not extend the
    // widget class.
    if (!_isSubclassOfWidget(clazz.superclass!)) {
      _transformClassImplementingWidget(clazz, changedStructureNotifier);
      return;
    }

    final Set<Constructor> _handledConstructors =
        new Set<Constructor>.identity();

    void handleConstructor(Constructor constructor) {
      if (!_handledConstructors.add(constructor)) {
        return;
      }

      final VariableDeclaration variable = new VariableDeclaration(
          _creationLocationParameterName,
          type: new InterfaceType(
              _locationClass, clazz.enclosingLibrary.nullable),
          initializer: new NullLiteral());
      if (_hasNamedParameter(
          constructor.function, _creationLocationParameterName)) {
        // Constructor was already rewritten.
        // TODO(jacobr): is this case actually hit?
        return;
      }
      if (!_maybeAddNamedParameter(constructor.function, variable)) {
        return;
      }
      for (Initializer initializer in constructor.initializers) {
        if (initializer is RedirectingInitializer) {
          if (initializer.target.enclosingClass == clazz) {
            // We need to handle this constructor first or the call to
            // addDebugLocationArgument could fail due to the named parameter
            // not existing.
            handleConstructor(initializer.target);
          }

          _maybeAddCreationLocationArgument(
            initializer.arguments,
            initializer.target.function,
            new VariableGet(variable),
            _locationClass,
          );
        } else if (initializer is SuperInitializer &&
            _isSubclassOfWidget(initializer.target.enclosingClass)) {
          _maybeAddCreationLocationArgument(
            initializer.arguments,
            initializer.target.function,
            new VariableGet(variable),
            _locationClass,
          );
        }
      }
    }

    clazz.constructors.forEach(handleConstructor);
  }

  void _transformWidgetFactories(
    Set<Library> librariesToBeTransformed,
    Set<Extension> transformedExtensions,
    Extension extension,
  ) {
    // TODO(johnniwinther): We should have a lint for unsupported use of
    // `@widgetFactory`.
    assert(_widgetFactoryClass != null);

    if (!librariesToBeTransformed.contains(extension.enclosingLibrary) ||
        !transformedExtensions.add(extension)) {
      return;
    }

    for (ExtensionMemberDescriptor member in extension.members) {
      if (member.isStatic) {
        // We could support static extension methods but it is not clear that
        // there is a use case for this.
        continue;
      }
      final Procedure method = member.member.asProcedure;
      if (_hasWidgetFactoryAnnotation(method)) {
        _maybeAddNamedParameter(
          method.function,
          new VariableDeclaration(
            _creationLocationParameterName,
            type: new InterfaceType(
              _locationClass,
              extension.enclosingLibrary.nullable,
            ),
            initializer: new NullLiteral(),
          ),
        );
      }
    }
  }
}
