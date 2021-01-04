// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.kernel_target;

import 'package:front_end/src/api_prototype/experimental_flags.dart';
import 'package:front_end/src/fasta/dill/dill_library_builder.dart'
    show DillLibraryBuilder;
import 'package:kernel/ast.dart'
    show
        Arguments,
        CanonicalName,
        Class,
        Component,
        Constructor,
        DartType,
        EmptyStatement,
        Expression,
        Field,
        FieldInitializer,
        FunctionNode,
        Initializer,
        InterfaceType,
        InvalidInitializer,
        InvalidType,
        Library,
        Name,
        NamedExpression,
        NonNullableByDefaultCompiledMode,
        NullLiteral,
        Procedure,
        RedirectingInitializer,
        Reference,
        Source,
        SuperInitializer,
        Supertype,
        TypeParameter,
        TypeParameterType,
        VariableDeclaration,
        VariableGet;
import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;
import 'package:kernel/clone.dart' show CloneVisitorNotMembers;
import 'package:kernel/core_types.dart';
import 'package:kernel/reference_from_index.dart' show IndexedClass;
import 'package:kernel/target/changed_structure_notifier.dart'
    show ChangedStructureNotifier;
import 'package:kernel/target/targets.dart' show DiagnosticReporter;
import 'package:kernel/transformations/value_class.dart' as valueClass;
import 'package:kernel/type_algebra.dart' show substitute;
import 'package:kernel/type_environment.dart' show TypeEnvironment;
import 'package:package_config/package_config.dart';

import '../../api_prototype/file_system.dart' show FileSystem;
import '../../base/nnbd_mode.dart';
import '../builder/builder.dart';
import '../builder/class_builder.dart';
import '../builder/constructor_builder.dart';
import '../builder/dynamic_type_declaration_builder.dart';
import '../builder/field_builder.dart';
import '../builder/invalid_type_declaration_builder.dart';
import '../builder/library_builder.dart';
import '../builder/member_builder.dart';
import '../builder/named_type_builder.dart';
import '../builder/never_type_declaration_builder.dart';
import '../builder/nullability_builder.dart';
import '../builder/procedure_builder.dart';
import '../builder/type_alias_builder.dart';
import '../builder/type_builder.dart';
import '../builder/type_declaration_builder.dart';
import '../builder/type_variable_builder.dart';
import '../builder/void_type_declaration_builder.dart';
import '../compiler_context.dart' show CompilerContext;
import '../crash.dart' show withCrashReporting;
import '../dill/dill_member_builder.dart' show DillMemberBuilder;
import '../dill/dill_target.dart' show DillTarget;
import '../fasta_codes.dart' show LocatedMessage, Message;
import '../loader.dart' show Loader;
import '../messages.dart'
    show
        FormattedMessage,
        messageAgnosticWithStrongDillLibrary,
        messageAgnosticWithWeakDillLibrary,
        messageConstConstructorLateFinalFieldCause,
        messageConstConstructorLateFinalFieldError,
        messageConstConstructorNonFinalField,
        messageConstConstructorNonFinalFieldCause,
        messageConstConstructorRedirectionToNonConst,
        messageInvalidNnbdDillLibrary,
        messageStrongWithWeakDillLibrary,
        messageWeakWithStrongDillLibrary,
        noLength,
        templateFieldNonNullableNotInitializedByConstructorError,
        templateFieldNonNullableWithoutInitializerError,
        templateFinalFieldNotInitialized,
        templateFinalFieldNotInitializedByConstructor,
        templateInferredPackageUri,
        templateMissingImplementationCause,
        templateSuperclassHasNoDefaultConstructor;
import '../problems.dart' show unhandled;
import '../scope.dart' show AmbiguousBuilder;
import '../source/source_class_builder.dart' show SourceClassBuilder;
import '../source/source_library_builder.dart' show SourceLibraryBuilder;
import '../source/source_loader.dart' show SourceLoader;
import '../target_implementation.dart' show TargetImplementation;
import '../uri_translator.dart' show UriTranslator;
import 'constant_evaluator.dart' as constants
    show
        EvaluationMode,
        transformLibraries,
        transformProcedure,
        ConstantCoverage;
import 'kernel_constants.dart' show KernelConstantErrorReporter;
import 'metadata_collector.dart' show MetadataCollector;
import 'verifier.dart' show verifyComponent, verifyGetStaticType;

class KernelTarget extends TargetImplementation {
  /// The [FileSystem] which should be used to access files.
  final FileSystem fileSystem;

  /// Whether comments should be scanned and parsed.
  final bool includeComments;

  final DillTarget dillTarget;

  /// The [MetadataCollector] to write metadata to.
  final MetadataCollector metadataCollector;

  SourceLoader loader;

  Component component;

  // 'dynamic' is always nullable.
  // TODO(johnniwinther): Why isn't this using a FixedTypeBuilder?
  final TypeBuilder dynamicType = new NamedTypeBuilder(
      "dynamic",
      const NullabilityBuilder.nullable(),
      /* arguments = */ null,
      /* fileUri = */ null,
      /* charOffset = */ null);

  final NamedTypeBuilder objectType = new NamedTypeBuilder(
      "Object",
      const NullabilityBuilder.omitted(),
      /* arguments = */ null,
      /* fileUri = */ null,
      /* charOffset = */ null);

  // Null is always nullable.
  // TODO(johnniwinther): This could (maybe) use a FixedTypeBuilder when we
  //  have NullType?
  final TypeBuilder nullType = new NamedTypeBuilder(
      "Null",
      const NullabilityBuilder.nullable(),
      /* arguments = */ null,
      /* fileUri = */ null,
      /* charOffset = */ null);

  // TODO(johnniwinther): Why isn't this using a FixedTypeBuilder?
  final TypeBuilder bottomType = new NamedTypeBuilder(
      "Never",
      const NullabilityBuilder.omitted(),
      /* arguments = */ null,
      /* fileUri = */ null,
      /* charOffset = */ null);

  final bool excludeSource = !CompilerContext.current.options.embedSourceText;

  final Map<String, String> environmentDefines =
      CompilerContext.current.options.environmentDefines;

  final bool errorOnUnevaluatedConstant =
      CompilerContext.current.options.errorOnUnevaluatedConstant;

  final List<ClonedFunctionNode> clonedFunctionNodes = <ClonedFunctionNode>[];

  KernelTarget(this.fileSystem, this.includeComments, DillTarget dillTarget,
      UriTranslator uriTranslator,
      {MetadataCollector metadataCollector})
      : dillTarget = dillTarget,
        metadataCollector = metadataCollector,
        super(dillTarget.ticker, uriTranslator, dillTarget.backendTarget) {
    loader = createLoader();
  }

  SourceLoader createLoader() =>
      new SourceLoader(fileSystem, includeComments, this);

  void addSourceInformation(
      Uri importUri, Uri fileUri, List<int> lineStarts, List<int> sourceCode) {
    uriToSource[fileUri] =
        new Source(lineStarts, sourceCode, importUri, fileUri);
  }

  /// Return list of same size as input with possibly translated uris.
  List<Uri> setEntryPoints(List<Uri> entryPoints) {
    List<Uri> result = <Uri>[];
    for (Uri entryPoint in entryPoints) {
      Uri translatedEntryPoint =
          getEntryPointUri(entryPoint, issueProblem: true);
      result.add(translatedEntryPoint);
      loader.read(translatedEntryPoint, -1,
          accessor: loader.first,
          fileUri: translatedEntryPoint != entryPoint ? entryPoint : null);
    }
    return result;
  }

  /// Return list of same size as input with possibly translated uris.
  Uri getEntryPointUri(Uri entryPoint, {bool issueProblem: false}) {
    String scheme = entryPoint.scheme;
    switch (scheme) {
      case "package":
      case "dart":
      case "data":
        break;
      default:
        // Attempt to reverse-lookup [entryPoint] in package config.
        String asString = "$entryPoint";
        Package package = uriTranslator.packages.packageOf(entryPoint);
        if (package != null) {
          String packageName = package.name;
          Uri packageUri = package.packageUriRoot;
          if (packageUri?.hasFragment == true) {
            packageUri = packageUri.removeFragment();
          }
          String prefix = "${packageUri}";
          if (asString.startsWith(prefix)) {
            Uri reversed = Uri.parse(
                "package:$packageName/${asString.substring(prefix.length)}");
            if (entryPoint == uriTranslator.translate(reversed)) {
              if (issueProblem) {
                loader.addProblem(
                    templateInferredPackageUri.withArguments(reversed),
                    -1,
                    1,
                    entryPoint);
              }
              entryPoint = reversed;
              break;
            }
          }
        }
    }
    return entryPoint;
  }

  @override
  LibraryBuilder createLibraryBuilder(
      Uri uri,
      Uri fileUri,
      Uri packageUri,
      SourceLibraryBuilder origin,
      Library referencesFrom,
      bool referenceIsPartOwner) {
    if (dillTarget.isLoaded) {
      LibraryBuilder builder = dillTarget.loader.builders[uri];
      if (builder != null) {
        if (!builder.isNonNullableByDefault &&
            (loader.nnbdMode == NnbdMode.Strong ||
                loader.nnbdMode == NnbdMode.Agnostic)) {
          loader.registerStrongOptOutLibrary(builder);
        } else if (builder is DillLibraryBuilder) {
          NonNullableByDefaultCompiledMode libraryMode =
              builder.library.nonNullableByDefaultCompiledMode;
          if (libraryMode == NonNullableByDefaultCompiledMode.Invalid) {
            loader.registerNnbdMismatchLibrary(
                builder, messageInvalidNnbdDillLibrary);
          } else {
            switch (loader.nnbdMode) {
              case NnbdMode.Weak:
                if (libraryMode != NonNullableByDefaultCompiledMode.Agnostic &&
                    libraryMode != NonNullableByDefaultCompiledMode.Weak) {
                  loader.registerNnbdMismatchLibrary(
                      builder, messageWeakWithStrongDillLibrary);
                }
                break;
              case NnbdMode.Strong:
                if (libraryMode != NonNullableByDefaultCompiledMode.Agnostic &&
                    libraryMode != NonNullableByDefaultCompiledMode.Strong) {
                  loader.registerNnbdMismatchLibrary(
                      builder, messageStrongWithWeakDillLibrary);
                }
                break;
              case NnbdMode.Agnostic:
                if (libraryMode != NonNullableByDefaultCompiledMode.Agnostic) {
                  if (libraryMode == NonNullableByDefaultCompiledMode.Strong) {
                    loader.registerNnbdMismatchLibrary(
                        builder, messageAgnosticWithStrongDillLibrary);
                  } else {
                    loader.registerNnbdMismatchLibrary(
                        builder, messageAgnosticWithWeakDillLibrary);
                  }
                }
                break;
            }
          }
        }
        return builder;
      }
    }
    return new SourceLibraryBuilder(uri, fileUri, packageUri, loader, origin,
        referencesFrom: referencesFrom,
        referenceIsPartOwner: referenceIsPartOwner);
  }

  /// Returns classes defined in libraries in [loader].
  List<SourceClassBuilder> collectMyClasses() {
    List<SourceClassBuilder> result = <SourceClassBuilder>[];
    loader.builders.forEach((Uri uri, LibraryBuilder library) {
      if (library.loader == loader) {
        Iterator<Builder> iterator = library.iterator;
        while (iterator.moveNext()) {
          Builder member = iterator.current;
          if (member is SourceClassBuilder && !member.isPatch) {
            result.add(member);
          }
        }
      }
    });
    return result;
  }

  void breakCycle(ClassBuilder builder) {
    Class cls = builder.cls;
    cls.implementedTypes.clear();
    cls.supertype = null;
    cls.mixedInType = null;
    builder.supertypeBuilder = new NamedTypeBuilder(
        "Object",
        const NullabilityBuilder.omitted(),
        /* arguments = */ null,
        /* fileUri = */ null,
        /* charOffset = */ null)
      ..bind(objectClassBuilder);
    builder.interfaceBuilders = null;
    builder.mixedInTypeBuilder = null;
  }

  @override
  Future<Component> buildOutlines({CanonicalName nameRoot}) async {
    if (loader.first == null) return null;
    return withCrashReporting<Component>(() async {
      await loader.buildOutlines();
      loader.createTypeInferenceEngine();
      loader.coreLibrary.becomeCoreLibrary();
      loader.resolveParts();
      loader.computeLibraryScopes();
      setupTopAndBottomTypes();
      loader.resolveTypes();
      loader.computeVariances();
      loader.computeDefaultTypes(
          dynamicType, nullType, bottomType, objectClassBuilder);
      List<SourceClassBuilder> myClasses =
          loader.checkSemantics(objectClassBuilder);
      loader.finishTypeVariables(objectClassBuilder, dynamicType);
      loader.buildComponent();
      installDefaultSupertypes();
      installSyntheticConstructors(myClasses);
      loader.resolveConstructors();
      component =
          link(new List<Library>.from(loader.libraries), nameRoot: nameRoot);
      computeCoreTypes();
      loader.buildClassHierarchy(myClasses, objectClassBuilder);
      loader.computeHierarchy();
      loader.performTopLevelInference(myClasses);
      loader.checkSupertypes(myClasses);
      loader.checkOverrides(myClasses);
      loader.checkAbstractMembers(myClasses);
      loader.addNoSuchMethodForwarders(myClasses);
      loader.checkMixins(myClasses);
      loader.buildOutlineExpressions(loader.coreTypes);
      loader.checkTypes();
      loader.checkRedirectingFactories(myClasses);
      loader.checkMainMethods();
      _updateDelayedParameterTypes();
      installAllComponentProblems(loader.allComponentProblems);
      loader.allComponentProblems.clear();
      return component;
    }, () => loader?.currentUriForCrashReporting);
  }

  /// Build the kernel representation of the component loaded by this
  /// target. The component will contain full bodies for the code loaded from
  /// sources, and only references to the code loaded by the [DillTarget],
  /// which may or may not include method bodies (depending on what was loaded
  /// into that target, an outline or a full kernel component).
  ///
  /// If [verify], run the default kernel verification on the resulting
  /// component.
  @override
  Future<Component> buildComponent({bool verify: false}) async {
    if (loader.first == null) return null;
    return withCrashReporting<Component>(() async {
      ticker.logMs("Building component");
      await loader.buildBodies();
      finishClonedParameters();
      loader.finishDeferredLoadTearoffs();
      loader.finishNoSuchMethodForwarders();
      List<SourceClassBuilder> myClasses = collectMyClasses();
      loader.finishNativeMethods();
      loader.finishPatchMethods();
      finishAllConstructors(myClasses);
      runBuildTransformations();

      if (verify) this.verify();
      installAllComponentProblems(loader.allComponentProblems);
      return component;
    }, () => loader?.currentUriForCrashReporting);
  }

  void installAllComponentProblems(
      List<FormattedMessage> allComponentProblems) {
    if (allComponentProblems.isNotEmpty) {
      component.problemsAsJson ??= <String>[];
    }
    for (int i = 0; i < allComponentProblems.length; i++) {
      FormattedMessage formattedMessage = allComponentProblems[i];
      component.problemsAsJson.add(formattedMessage.toJsonString());
    }
  }

  /// Creates a component by combining [libraries] with the libraries of
  /// `dillTarget.loader.component`.
  Component link(List<Library> libraries, {CanonicalName nameRoot}) {
    libraries.addAll(dillTarget.loader.libraries);

    Map<Uri, Source> uriToSource = new Map<Uri, Source>();
    void copySource(Uri uri, Source source) {
      uriToSource[uri] = excludeSource
          ? new Source(source.lineStarts, const <int>[], source.importUri,
              source.fileUri)
          : source;
    }

    this.uriToSource.forEach(copySource);

    Component component = backendTarget.configureComponent(new Component(
        nameRoot: nameRoot, libraries: libraries, uriToSource: uriToSource));

    NonNullableByDefaultCompiledMode compiledMode = null;
    if (isExperimentEnabledGlobally(ExperimentalFlag.nonNullable)) {
      switch (loader.nnbdMode) {
        case NnbdMode.Weak:
          compiledMode = NonNullableByDefaultCompiledMode.Weak;
          break;
        case NnbdMode.Strong:
          compiledMode = NonNullableByDefaultCompiledMode.Strong;
          break;
        case NnbdMode.Agnostic:
          compiledMode = NonNullableByDefaultCompiledMode.Agnostic;
          break;
      }
    } else {
      compiledMode = NonNullableByDefaultCompiledMode.Weak;
    }
    if (loader.hasInvalidNnbdModeLibrary) {
      compiledMode = NonNullableByDefaultCompiledMode.Invalid;
    }

    Reference mainReference;

    if (loader.first != null) {
      // TODO(sigmund): do only for full program
      Builder declaration = loader.first.exportScope.lookup("main", -1, null);
      if (declaration is AmbiguousBuilder) {
        AmbiguousBuilder problem = declaration;
        declaration = problem.getFirstDeclaration();
      }
      if (declaration is ProcedureBuilder) {
        mainReference = declaration.actualProcedure?.reference;
      } else if (declaration is DillMemberBuilder) {
        if (declaration.member is Procedure) {
          mainReference = declaration.member?.reference;
        }
      }
    }
    component.setMainMethodAndMode(mainReference, true, compiledMode);

    if (metadataCollector != null) {
      component.addMetadataRepository(metadataCollector.repository);
    }
    assert(_getLibraryNnbdModeError(component) == null,
        "Got error: ${_getLibraryNnbdModeError(component)}");

    ticker.logMs("Linked component");
    return component;
  }

  String _getLibraryNnbdModeError(Component component) {
    if (loader.hasInvalidNnbdModeLibrary) {
      // At least 1 library should be invalid or there should be a mix of strong
      // and weak. For libraries we've just compiled it will be marked as
      // invalid, but for libraries loaded from dill they have their original
      // value (i.e. either strong or weak).
      bool foundInvalid = false;
      bool foundStrong = false;
      bool foundWeak = false;
      for (Library library in component.libraries) {
        if (library.nonNullableByDefaultCompiledMode ==
            NonNullableByDefaultCompiledMode.Invalid) {
          foundInvalid = true;
          break;
        } else if (!foundWeak &&
            library.nonNullableByDefaultCompiledMode ==
                NonNullableByDefaultCompiledMode.Weak) {
          foundWeak = true;
          if (foundStrong) break;
        } else if (!foundStrong &&
            library.nonNullableByDefaultCompiledMode ==
                NonNullableByDefaultCompiledMode.Strong) {
          foundStrong = true;
          if (foundWeak) break;
        }
      }
      if (!foundInvalid && !(foundStrong && foundWeak)) {
        return "hasInvalidNnbdModeLibrary is true, but no library was invalid "
            "and there was no weak/strong mix.";
      }
      if (component.mode != NonNullableByDefaultCompiledMode.Invalid) {
        return "Component mode is not invalid as expected";
      }
    } else {
      // No libraries are allowed to be invalid, and should all be compatible
      // with the component nnbd mode setting.
      if (component.mode == NonNullableByDefaultCompiledMode.Invalid) {
        return "Component mode is invalid which was not expected";
      }
      if (component.modeRaw == null) {
        return "Component mode not set at all";
      }
      for (Library library in component.libraries) {
        if (component.mode == NonNullableByDefaultCompiledMode.Strong) {
          if (library.nonNullableByDefaultCompiledMode !=
                  NonNullableByDefaultCompiledMode.Strong &&
              library.nonNullableByDefaultCompiledMode !=
                  NonNullableByDefaultCompiledMode.Agnostic) {
            return "Expected library ${library.importUri} to be strong or "
                "agnostic, but was ${library.nonNullableByDefaultCompiledMode}";
          }
        } else if (component.mode == NonNullableByDefaultCompiledMode.Weak) {
          if (library.nonNullableByDefaultCompiledMode !=
                  NonNullableByDefaultCompiledMode.Weak &&
              library.nonNullableByDefaultCompiledMode !=
                  NonNullableByDefaultCompiledMode.Agnostic) {
            return "Expected library ${library.importUri} to be weak or "
                "agnostic, but was ${library.nonNullableByDefaultCompiledMode}";
          }
        } else if (component.mode ==
            NonNullableByDefaultCompiledMode.Agnostic) {
          if (library.nonNullableByDefaultCompiledMode !=
              NonNullableByDefaultCompiledMode.Agnostic) {
            return "Expected library ${library.importUri} to be agnostic, "
                "but was ${library.nonNullableByDefaultCompiledMode}";
          }
        } else {
          return "Expected component mode to be either strong, "
              "weak or agnostic but was ${component.mode}";
        }
      }
    }
    return null;
  }

  void installDefaultSupertypes() {
    Class objectClass = this.objectClass;
    loader.builders.forEach((Uri uri, LibraryBuilder library) {
      if (library.loader == loader) {
        Iterator<Builder> iterator = library.iterator;
        while (iterator.moveNext()) {
          Builder declaration = iterator.current;
          if (declaration is SourceClassBuilder) {
            Class cls = declaration.cls;
            if (cls != objectClass) {
              cls.supertype ??= objectClass.asRawSupertype;
              declaration.supertypeBuilder ??= new NamedTypeBuilder(
                  "Object",
                  const NullabilityBuilder.omitted(),
                  /* arguments = */ null,
                  /* fileUri = */ null,
                  /* charOffset = */ null)
                ..bind(objectClassBuilder);
            }
            if (declaration.isMixinApplication) {
              cls.mixedInType = declaration.mixedInTypeBuilder.buildMixedInType(
                  library, declaration.charOffset, declaration.fileUri);
            }
          }
        }
      }
    });
    ticker.logMs("Installed Object as implicit superclass");
  }

  void installSyntheticConstructors(List<SourceClassBuilder> builders) {
    Class objectClass = this.objectClass;
    for (SourceClassBuilder builder in builders) {
      if (builder.cls != objectClass && !builder.isPatch) {
        if (builder.isPatch ||
            builder.isMixinDeclaration ||
            builder.isExtension) {
          continue;
        }
        if (builder.isMixinApplication) {
          installForwardingConstructors(builder);
        } else {
          installDefaultConstructor(builder);
        }
      }
    }
    ticker.logMs("Installed synthetic constructors");
  }

  List<DelayedParameterType> _delayedParameterTypes = <DelayedParameterType>[];

  /// Update the type of parameters cloned from parameters with inferred
  /// parameter types.
  void _updateDelayedParameterTypes() {
    for (DelayedParameterType delayedParameterType in _delayedParameterTypes) {
      delayedParameterType.updateType();
    }
    _delayedParameterTypes.clear();
  }

  ClassBuilder get objectClassBuilder => objectType.declaration;

  Class get objectClass => objectClassBuilder.cls;

  /// If [builder] doesn't have a constructors, install the defaults.
  void installDefaultConstructor(SourceClassBuilder builder) {
    assert(!builder.isMixinApplication);
    assert(!builder.isExtension);
    // TODO(askesc): Make this check light-weight in the absence of patches.
    if (builder.cls.constructors.isNotEmpty) return;
    if (builder.cls.redirectingFactoryConstructors.isNotEmpty) return;
    for (Procedure proc in builder.cls.procedures) {
      if (proc.isFactory) return;
    }

    IndexedClass indexedClass = builder.referencesFromIndexed;
    Constructor referenceFrom;
    if (indexedClass != null) {
      referenceFrom = indexedClass.lookupConstructor("");
    }

    /// From [Dart Programming Language Specification, 4th Edition](
    /// https://ecma-international.org/publications/files/ECMA-ST/ECMA-408.pdf):
    /// >Iff no constructor is specified for a class C, it implicitly has a
    /// >default constructor C() : super() {}, unless C is class Object.
    // The superinitializer is installed below in [finishConstructors].
    builder.addSyntheticConstructor(
        _makeDefaultConstructor(builder, referenceFrom));
  }

  void installForwardingConstructors(SourceClassBuilder builder) {
    assert(builder.isMixinApplication);
    if (builder.library.loader != loader) return;
    if (builder.cls.constructors.isNotEmpty) {
      // These were installed by a subclass in the recursive call below.
      return;
    }

    /// From [Dart Programming Language Specification, 4th Edition](
    /// https://ecma-international.org/publications/files/ECMA-ST/ECMA-408.pdf):
    /// >A mixin application of the form S with M; defines a class C with
    /// >superclass S.
    /// >...

    /// >Let LM be the library in which M is declared. For each generative
    /// >constructor named qi(Ti1 ai1, . . . , Tiki aiki), i in 1..n of S
    /// >that is accessible to LM , C has an implicitly declared constructor
    /// >named q'i = [C/S]qi of the form q'i(ai1,...,aiki) :
    /// >super(ai1,...,aiki);.
    TypeBuilder type = builder.supertypeBuilder;
    TypeDeclarationBuilder supertype;
    if (type is NamedTypeBuilder) {
      supertype = type.declaration;
    } else {
      unhandled("${type.runtimeType}", "installForwardingConstructors",
          builder.charOffset, builder.fileUri);
    }
    if (supertype is TypeAliasBuilder) {
      TypeAliasBuilder aliasBuilder = supertype;
      NamedTypeBuilder namedBuilder = type;
      supertype = aliasBuilder.unaliasDeclaration(namedBuilder.arguments);
    }
    if (supertype is SourceClassBuilder && supertype.isMixinApplication) {
      installForwardingConstructors(supertype);
    }

    IndexedClass indexedClass = builder.referencesFromIndexed;
    Constructor referenceFrom;
    if (indexedClass != null) {
      referenceFrom = indexedClass.lookupConstructor("");
    }

    if (supertype is ClassBuilder) {
      ClassBuilder superclassBuilder = supertype;
      bool isConstructorAdded = false;
      Map<TypeParameter, DartType> substitutionMap;

      void addSyntheticConstructor(String name, MemberBuilder memberBuilder) {
        if (memberBuilder.member is Constructor) {
          substitutionMap ??= builder.getSubstitutionMap(superclassBuilder.cls);
          Constructor referenceFrom = indexedClass?.lookupConstructor(name);
          builder.addSyntheticConstructor(_makeMixinApplicationConstructor(
              builder,
              builder.cls.mixin,
              memberBuilder,
              substitutionMap,
              referenceFrom));
          isConstructorAdded = true;
        }
      }

      superclassBuilder.forEachConstructor(addSyntheticConstructor,
          includeInjectedConstructors: true);

      if (!isConstructorAdded) {
        builder.addSyntheticConstructor(
            _makeDefaultConstructor(builder, referenceFrom));
      }
    } else if (supertype is InvalidTypeDeclarationBuilder ||
        supertype is TypeVariableBuilder ||
        supertype is DynamicTypeDeclarationBuilder ||
        supertype is VoidTypeDeclarationBuilder ||
        supertype is NeverTypeDeclarationBuilder) {
      builder.addSyntheticConstructor(
          _makeDefaultConstructor(builder, referenceFrom));
    } else {
      unhandled("${supertype.runtimeType}", "installForwardingConstructors",
          builder.charOffset, builder.fileUri);
    }
  }

  SyntheticConstructorBuilder _makeMixinApplicationConstructor(
      SourceClassBuilder classBuilder,
      Class mixin,
      MemberBuilderImpl memberBuilder,
      Map<TypeParameter, DartType> substitutionMap,
      Constructor referenceFrom) {
    VariableDeclaration copyFormal(VariableDeclaration formal) {
      VariableDeclaration copy = new VariableDeclaration(formal.name,
          isFinal: formal.isFinal, isConst: formal.isConst);
      if (formal.type != null) {
        copy.type = substitute(formal.type, substitutionMap);
      } else {
        _delayedParameterTypes
            .add(new DelayedParameterType(formal, copy, substitutionMap));
      }
      return copy;
    }

    Class cls = classBuilder.cls;
    Constructor constructor = memberBuilder.member;
    bool isConst = constructor.isConst;
    if (isConst && mixin.fields.isNotEmpty) {
      for (Field field in mixin.fields) {
        if (!field.isStatic) {
          isConst = false;
          break;
        }
      }
    }
    List<VariableDeclaration> positionalParameters = <VariableDeclaration>[];
    List<VariableDeclaration> namedParameters = <VariableDeclaration>[];
    List<Expression> positional = <Expression>[];
    List<NamedExpression> named = <NamedExpression>[];

    for (VariableDeclaration formal
        in constructor.function.positionalParameters) {
      positionalParameters.add(copyFormal(formal));
      positional.add(new VariableGet(positionalParameters.last));
    }
    for (VariableDeclaration formal in constructor.function.namedParameters) {
      VariableDeclaration clone = copyFormal(formal);
      namedParameters.add(clone);
      named.add(new NamedExpression(
          formal.name, new VariableGet(namedParameters.last)));
    }
    FunctionNode function = new FunctionNode(new EmptyStatement(),
        positionalParameters: positionalParameters,
        namedParameters: namedParameters,
        requiredParameterCount: constructor.function.requiredParameterCount,
        returnType: makeConstructorReturnType(cls));
    SuperInitializer initializer = new SuperInitializer(
        constructor, new Arguments(positional, named: named));
    ClonedFunctionNode clonedFunctionNode =
        new ClonedFunctionNode(substitutionMap, constructor.function, function);
    if (!isConst) {
      // For constant constructors default values are computed and cloned part
      // of the outline expression and therefore passed to the
      // [SyntheticConstructorBuilder] below.
      //
      // For non-constant constructors default values are cloned as part of the
      // full compilation using [clonedFunctionNodes].
      clonedFunctionNodes.add(clonedFunctionNode);
    }
    return new SyntheticConstructorBuilder(
        classBuilder,
        new Constructor(function,
            name: constructor.name,
            initializers: <Initializer>[initializer],
            isSynthetic: true,
            isConst: isConst,
            reference: referenceFrom?.reference)
          ..isNonNullableByDefault = cls.enclosingLibrary.isNonNullableByDefault
          ..fileUri = cls.fileUri,
        // If the constructor is constant, the default values must be part of
        // the outline expressions. We pass on the original constructor and
        // cloned function nodes to ensure that the default values are computed
        // and cloned for the outline.
        origin: isConst ? memberBuilder : null,
        clonedFunctionNode: isConst ? clonedFunctionNode : null);
  }

  void finishClonedParameters() {
    for (ClonedFunctionNode clonedFunctionNode in clonedFunctionNodes) {
      clonedFunctionNode.cloneDefaultValues();
    }
    clonedFunctionNodes.clear();
    ticker.logMs("Cloned default values of formals");
  }

  SyntheticConstructorBuilder _makeDefaultConstructor(
      SourceClassBuilder classBuilder, Constructor referenceFrom) {
    Class enclosingClass = classBuilder.cls;
    return new SyntheticConstructorBuilder(
        classBuilder,
        new Constructor(
            new FunctionNode(new EmptyStatement(),
                returnType: makeConstructorReturnType(enclosingClass)),
            name: new Name(""),
            isSynthetic: true,
            reference: referenceFrom?.reference)
          ..isNonNullableByDefault =
              enclosingClass.enclosingLibrary.isNonNullableByDefault);
  }

  DartType makeConstructorReturnType(Class enclosingClass) {
    List<DartType> typeParameterTypes = <DartType>[];
    for (int i = 0; i < enclosingClass.typeParameters.length; i++) {
      TypeParameter typeParameter = enclosingClass.typeParameters[i];
      typeParameterTypes.add(
          new TypeParameterType.withDefaultNullabilityForLibrary(
              typeParameter, enclosingClass.enclosingLibrary));
    }
    return new InterfaceType(enclosingClass,
        enclosingClass.enclosingLibrary.nonNullable, typeParameterTypes);
  }

  void setupTopAndBottomTypes() {
    objectType
        .bind(loader.coreLibrary.lookupLocalMember("Object", required: true));
    dynamicType
        .bind(loader.coreLibrary.lookupLocalMember("dynamic", required: true));
    ClassBuilder nullClassBuilder =
        loader.coreLibrary.lookupLocalMember("Null", required: true);
    nullType.bind(nullClassBuilder..isNullClass = true);
    bottomType
        .bind(loader.coreLibrary.lookupLocalMember("Never", required: true));
  }

  void computeCoreTypes() {
    List<Library> libraries = <Library>[];
    for (String platformLibrary in [
      "dart:_internal",
      "dart:async",
      "dart:core",
      "dart:mirrors",
      ...backendTarget.extraIndexedLibraries
    ]) {
      Uri uri = Uri.parse(platformLibrary);
      LibraryBuilder libraryBuilder = loader.builders[uri];
      if (libraryBuilder == null) {
        // TODO(ahe): This is working around a bug in kernel_driver_test or
        // kernel_driver.
        bool found = false;
        for (Library target in dillTarget.loader.libraries) {
          if (target.importUri == uri) {
            libraries.add(target);
            found = true;
            break;
          }
        }
        if (!found && uri.path != "mirrors") {
          // dart:mirrors is optional.
          throw "Can't find $uri";
        }
      } else {
        libraries.add(libraryBuilder.library);
      }
    }
    Component platformLibraries =
        backendTarget.configureComponent(new Component());
    // Add libraries directly to prevent that their parents are changed.
    platformLibraries.libraries.addAll(libraries);
    loader.computeCoreTypes(platformLibraries);
  }

  void finishAllConstructors(List<SourceClassBuilder> builders) {
    Class objectClass = this.objectClass;
    for (SourceClassBuilder builder in builders) {
      Class cls = builder.cls;
      if (cls != objectClass) {
        finishConstructors(builder);
      }
    }
    ticker.logMs("Finished constructors");
  }

  /// Ensure constructors of [builder] have the correct initializers and other
  /// requirements.
  void finishConstructors(SourceClassBuilder builder) {
    if (builder.isPatch) return;
    Class cls = builder.cls;

    /// Quotes below are from [Dart Programming Language Specification, 4th
    /// Edition](http://www.ecma-international.org/publications/files/ECMA-ST/ECMA-408.pdf):
    List<FieldBuilder> uninitializedFields = <FieldBuilder>[];
    List<FieldBuilder> nonFinalFields = <FieldBuilder>[];
    List<FieldBuilder> lateFinalFields = <FieldBuilder>[];

    builder.forEachDeclaredField((String name, FieldBuilder fieldBuilder) {
      if (fieldBuilder.isAbstract || fieldBuilder.isExternal) {
        // Skip abstract and external fields. These are abstract/external
        // getters/setters and have no initialization.
        return;
      }
      if (fieldBuilder.isDeclarationInstanceMember && !fieldBuilder.isFinal) {
        nonFinalFields.add(fieldBuilder);
      }
      if (fieldBuilder.isDeclarationInstanceMember &&
          fieldBuilder.isLate &&
          fieldBuilder.isFinal) {
        lateFinalFields.add(fieldBuilder);
      }
      if (!fieldBuilder.hasInitializer) {
        // In case of duplicating fields the earliest ones (those that
        // declared towards the beginning of the file) come last in the list.
        // To report errors on the first definition of a field, we need to
        // iterate until that last element.
        FieldBuilder earliest = fieldBuilder;
        Builder current = fieldBuilder;
        while (current.next != null) {
          current = current.next;
          if (current is FieldBuilder && !fieldBuilder.hasInitializer) {
            earliest = current;
          }
        }
        uninitializedFields.add(earliest);
      }
    });

    Constructor superTarget;
    // In the underlying Kernel IR the patches are already applied, so
    // cls.constructors should contain both constructors from the original
    // declaration and the constructors from the patch.  The assert checks that
    // it's so.
    assert(() {
      Set<String> patchConstructorNames = {};
      builder.forEachDeclaredConstructor(
          (String name, ConstructorBuilder constructorBuilder) {
        // Don't add the default constructor's name.
        if (name.isNotEmpty) {
          patchConstructorNames.add(name);
        }
      });
      builder.constructors.forEach((String name, Builder builder) {
        if (builder is ConstructorBuilder) {
          patchConstructorNames.remove(name);
        }
      });
      Set<String> kernelConstructorNames =
          cls.constructors.map((c) => c.name.text).toSet().difference({""});
      return kernelConstructorNames.containsAll(patchConstructorNames);
    }(),
        "Constructors of class '${builder.fullNameForErrors}' "
        "aren't fully patched.");
    for (Constructor constructor in cls.constructors) {
      bool isRedirecting = false;
      for (Initializer initializer in constructor.initializers) {
        if (initializer is RedirectingInitializer) {
          if (constructor.isConst && !initializer.target.isConst) {
            builder.addProblem(messageConstConstructorRedirectionToNonConst,
                initializer.fileOffset, initializer.target.name.text.length);
          }
          isRedirecting = true;
          break;
        }
      }
      if (!isRedirecting) {
        /// >If no superinitializer is provided, an implicit superinitializer
        /// >of the form super() is added at the end of k’s initializer list,
        /// >unless the enclosing class is class Object.
        if (constructor.initializers.isEmpty) {
          superTarget ??= defaultSuperConstructor(cls);
          Initializer initializer;
          if (superTarget == null) {
            int offset = constructor.fileOffset;
            if (offset == -1 && constructor.isSynthetic) {
              offset = cls.fileOffset;
            }
            builder.addProblem(
                templateSuperclassHasNoDefaultConstructor
                    .withArguments(cls.superclass.name),
                offset,
                noLength);
            initializer = new InvalidInitializer();
          } else {
            initializer =
                new SuperInitializer(superTarget, new Arguments.empty())
                  ..isSynthetic = true;
          }
          constructor.initializers.add(initializer);
          initializer.parent = constructor;
        }
        if (constructor.function.body == null) {
          /// >If a generative constructor c is not a redirecting constructor
          /// >and no body is provided, then c implicitly has an empty body {}.
          /// We use an empty statement instead.
          constructor.function.body = new EmptyStatement();
          constructor.function.body.parent = constructor.function;
        }

        if (constructor.isConst && nonFinalFields.isNotEmpty) {
          builder.addProblem(messageConstConstructorNonFinalField,
              constructor.fileOffset, noLength,
              context: nonFinalFields
                  .map((field) => messageConstConstructorNonFinalFieldCause
                      .withLocation(field.fileUri, field.charOffset, noLength))
                  .toList());
          nonFinalFields.clear();
        }
        SourceLibraryBuilder library = builder.library;
        if (library.isNonNullableByDefault) {
          if (constructor.isConst && lateFinalFields.isNotEmpty) {
            for (FieldBuilder field in lateFinalFields) {
              builder.addProblem(messageConstConstructorLateFinalFieldError,
                  field.charOffset, noLength,
                  context: [
                    messageConstConstructorLateFinalFieldCause.withLocation(
                        constructor.fileUri, constructor.fileOffset, noLength)
                  ]);
            }
            lateFinalFields.clear();
          }
        }
      }
    }

    Map<ConstructorBuilder, Set<FieldBuilder>> constructorInitializedFields =
        new Map<ConstructorBuilder, Set<FieldBuilder>>.identity();
    Set<FieldBuilder> initializedFields = null;

    builder
        .forEachDeclaredConstructor((String name, Builder constructorBuilder) {
      if (constructorBuilder is ConstructorBuilder) {
        if (constructorBuilder.isExternal) return;
        // In case of duplicating constructors the earliest ones (those that
        // declared towards the beginning of the file) come last in the list.
        // To report errors on the first definition of a constructor, we need to
        // iterate until that last element.
        ConstructorBuilder earliest = constructorBuilder;
        while (earliest.next != null) {
          earliest = earliest.next;
        }

        bool isRedirecting = false;
        for (Initializer initializer in earliest.constructor.initializers) {
          if (initializer is RedirectingInitializer) {
            isRedirecting = true;
          }
        }
        if (!isRedirecting) {
          Set<FieldBuilder> fields =
              earliest.takeInitializedFields() ?? const {};
          constructorInitializedFields[earliest] = fields;
          (initializedFields ??= new Set<FieldBuilder>.identity())
              .addAll(fields);
        }
      }
    });

    // Run through all fields that aren't initialized by any constructor, and
    // set their initializer to `null`.
    for (FieldBuilder fieldBuilder in uninitializedFields) {
      if (initializedFields == null ||
          !initializedFields.contains(fieldBuilder)) {
        bool uninitializedFinalOrNonNullableFieldIsError =
            cls.enclosingLibrary.isNonNullableByDefault ||
                (cls.constructors.isNotEmpty || cls.isMixinDeclaration);
        if (!fieldBuilder.isLate) {
          if (fieldBuilder.isFinal &&
              uninitializedFinalOrNonNullableFieldIsError) {
            String uri = '${fieldBuilder.library.importUri}';
            String file = fieldBuilder.fileUri.pathSegments.last;
            if (uri == 'dart:html' ||
                uri == 'dart:svg' ||
                uri == 'dart:_native_typed_data' ||
                uri == 'dart:_interceptors' && file == 'js_string.dart') {
              // TODO(johnniwinther): Use external getters instead of final
              // fields. See https://github.com/dart-lang/sdk/issues/33762
            } else {
              builder.library.addProblem(
                  templateFinalFieldNotInitialized
                      .withArguments(fieldBuilder.name),
                  fieldBuilder.charOffset,
                  fieldBuilder.name.length,
                  fieldBuilder.fileUri);
            }
          } else if (fieldBuilder.fieldType is! InvalidType &&
              fieldBuilder.fieldType.isPotentiallyNonNullable &&
              uninitializedFinalOrNonNullableFieldIsError) {
            SourceLibraryBuilder library = builder.library;
            if (library.isNonNullableByDefault) {
              library.addProblem(
                  templateFieldNonNullableWithoutInitializerError.withArguments(
                      fieldBuilder.name,
                      fieldBuilder.fieldType,
                      library.isNonNullableByDefault),
                  fieldBuilder.charOffset,
                  fieldBuilder.name.length,
                  fieldBuilder.fileUri);
            }
          }
        }
      }
    }

    // Run through all fields that are initialized by some constructor, and
    // make sure that all other constructors also initialize them.
    constructorInitializedFields.forEach((ConstructorBuilder constructorBuilder,
        Set<FieldBuilder> fieldBuilders) {
      for (FieldBuilder fieldBuilder
          in initializedFields.difference(fieldBuilders)) {
        if (!fieldBuilder.hasInitializer && !fieldBuilder.isLate) {
          FieldInitializer initializer =
              new FieldInitializer(fieldBuilder.field, new NullLiteral())
                ..isSynthetic = true;
          initializer.parent = constructorBuilder.constructor;
          constructorBuilder.constructor.initializers.insert(0, initializer);
          if (fieldBuilder.isFinal) {
            builder.library.addProblem(
                templateFinalFieldNotInitializedByConstructor
                    .withArguments(fieldBuilder.name),
                constructorBuilder.charOffset,
                constructorBuilder.name.length,
                constructorBuilder.fileUri,
                context: [
                  templateMissingImplementationCause
                      .withArguments(fieldBuilder.name)
                      .withLocation(fieldBuilder.fileUri,
                          fieldBuilder.charOffset, fieldBuilder.name.length)
                ]);
          } else if (fieldBuilder.field.type is! InvalidType &&
              !fieldBuilder.isLate &&
              fieldBuilder.field.type.isPotentiallyNonNullable) {
            SourceLibraryBuilder library = builder.library;
            if (library.isNonNullableByDefault) {
              library.addProblem(
                  templateFieldNonNullableNotInitializedByConstructorError
                      .withArguments(fieldBuilder.name, fieldBuilder.field.type,
                          library.isNonNullableByDefault),
                  constructorBuilder.charOffset,
                  noLength,
                  constructorBuilder.fileUri,
                  context: [
                    templateMissingImplementationCause
                        .withArguments(fieldBuilder.name)
                        .withLocation(fieldBuilder.fileUri,
                            fieldBuilder.charOffset, fieldBuilder.name.length)
                  ]);
            }
          }
        }
      }
    });

    Set<Field> initializedFieldsKernel = null;
    if (initializedFields != null) {
      for (FieldBuilder fieldBuilder in initializedFields) {
        (initializedFieldsKernel ??= new Set<Field>.identity())
            .add(fieldBuilder.field);
      }
    }
    // In the underlying Kernel IR the patches are already applied, so
    // cls.fields should contain both fields from the original
    // declaration and the fields from the patch.  The assert checks that
    // it's so.
    assert(() {
      Set<String> patchFieldNames = {};
      builder.forEachDeclaredField((String name, FieldBuilder fieldBuilder) {
        patchFieldNames.add(SourceFieldBuilder.createFieldName(
          FieldNameType.Field,
          name,
          isInstanceMember: fieldBuilder.isClassInstanceMember,
          className: builder.name,
          isSynthesized:
              fieldBuilder is SourceFieldBuilder && fieldBuilder.isLateLowered,
        ));
      });
      builder.forEach((String name, Builder builder) {
        if (builder is FieldBuilder) {
          patchFieldNames.remove(name);
        }
      });
      Set<String> kernelFieldNames = cls.fields.map((f) => f.name.text).toSet();
      return kernelFieldNames.containsAll(patchFieldNames);
    }(),
        "Fields of class '${builder.fullNameForErrors}' "
        "aren't fully patched.");
    for (Field field in cls.fields) {
      if (field.initializer == null &&
          !field.isLate &&
          (initializedFieldsKernel == null ||
              !initializedFieldsKernel.contains(field))) {
        field.initializer = new NullLiteral()..parent = field;
      }
    }
  }

  /// Run all transformations that are needed when building a bundle of
  /// libraries for the first time.
  void runBuildTransformations() {
    backendTarget.performPreConstantEvaluationTransformations(
        component,
        loader.coreTypes,
        loader.libraries,
        new KernelDiagnosticReporter(loader),
        logger: (String msg) => ticker.logMs(msg),
        changedStructureNotifier: changedStructureNotifier);

    TypeEnvironment environment =
        new TypeEnvironment(loader.coreTypes, loader.hierarchy);
    constants.EvaluationMode evaluationMode = _getConstantEvaluationMode();

    constants.ConstantCoverage coverage = constants.transformLibraries(
        loader.libraries,
        backendTarget.constantsBackend(loader.coreTypes),
        environmentDefines,
        environment,
        new KernelConstantErrorReporter(loader),
        evaluationMode,
        evaluateAnnotations: true,
        enableTripleShift:
            isExperimentEnabledGlobally(ExperimentalFlag.tripleShift),
        errorOnUnevaluatedConstant: errorOnUnevaluatedConstant);
    ticker.logMs("Evaluated constants");

    coverage.constructorCoverage.forEach((Uri fileUri, Set<Reference> value) {
      Source source = uriToSource[fileUri];
      if (source != null && fileUri != null) {
        source.constantCoverageConstructors ??= new Set<Reference>();
        source.constantCoverageConstructors.addAll(value);
      }
    });
    ticker.logMs("Added constant coverage");

    if (loader.target.context.options
        .isExperimentEnabledGlobally(ExperimentalFlag.valueClass)) {
      valueClass.transformComponent(
          component, loader.coreTypes, loader.hierarchy, environment);
      ticker.logMs("Lowered value classes");
    }

    backendTarget.performModularTransformationsOnLibraries(
        component,
        loader.coreTypes,
        loader.hierarchy,
        loader.libraries,
        environmentDefines,
        new KernelDiagnosticReporter(loader),
        loader.referenceFromIndex,
        logger: (String msg) => ticker.logMs(msg),
        changedStructureNotifier: changedStructureNotifier);
  }

  ChangedStructureNotifier get changedStructureNotifier => null;

  void runProcedureTransformations(Procedure procedure) {
    TypeEnvironment environment =
        new TypeEnvironment(loader.coreTypes, loader.hierarchy);
    constants.EvaluationMode evaluationMode = _getConstantEvaluationMode();

    constants.transformProcedure(
        procedure,
        backendTarget.constantsBackend(loader.coreTypes),
        environmentDefines,
        environment,
        new KernelConstantErrorReporter(loader),
        evaluationMode,
        evaluateAnnotations: true,
        enableTripleShift:
            isExperimentEnabledGlobally(ExperimentalFlag.tripleShift),
        errorOnUnevaluatedConstant: errorOnUnevaluatedConstant);
    ticker.logMs("Evaluated constants");

    backendTarget.performTransformationsOnProcedure(
        loader.coreTypes, loader.hierarchy, procedure,
        logger: (String msg) => ticker.logMs(msg));
  }

  constants.EvaluationMode getConstantEvaluationModeForTesting() =>
      _getConstantEvaluationMode();

  constants.EvaluationMode _getConstantEvaluationMode() {
    constants.EvaluationMode evaluationMode;
    // If nnbd is not enabled we will use weak evaluation mode. This is needed
    // because the SDK might be agnostic and therefore needs to be weakened
    // for legacy mode.
    assert(
        isExperimentEnabledGlobally(ExperimentalFlag.nonNullable) ||
            loader.nnbdMode == NnbdMode.Weak,
        "Non-weak nnbd mode found without experiment enabled: "
        "${loader.nnbdMode}.");
    switch (loader.nnbdMode) {
      case NnbdMode.Weak:
        evaluationMode = constants.EvaluationMode.weak;
        break;
      case NnbdMode.Strong:
        evaluationMode = constants.EvaluationMode.strong;
        break;
      case NnbdMode.Agnostic:
        evaluationMode = constants.EvaluationMode.agnostic;
        break;
    }
    return evaluationMode;
  }

  void verify() {
    // TODO(ahe): How to handle errors.
    verifyComponent(component,
        skipPlatform: context.options.verifySkipPlatform);
    ClassHierarchy hierarchy =
        new ClassHierarchy(component, new CoreTypes(component),
            onAmbiguousSupertypes: (Class cls, Supertype a, Supertype b) {
      // An error has already been reported.
    });
    verifyGetStaticType(
        new TypeEnvironment(loader.coreTypes, hierarchy), component,
        skipPlatform: context.options.verifySkipPlatform);
    ticker.logMs("Verified component");
  }

  /// Return `true` if the given [library] was built by this [KernelTarget]
  /// from sources, and not loaded from a [DillTarget].
  bool isSourceLibrary(Library library) {
    return loader.libraries.contains(library);
  }

  @override
  void readPatchFiles(SourceLibraryBuilder library) {
    assert(library.importUri.scheme == "dart");
    List<Uri> patches = uriTranslator.getDartPatches(library.importUri.path);
    if (patches != null) {
      SourceLibraryBuilder first;
      for (Uri patch in patches) {
        if (first == null) {
          first = library.loader.read(patch, -1,
              fileUri: patch, origin: library, accessor: library);
        } else {
          // If there's more than one patch file, it's interpreted as a part of
          // the patch library.
          SourceLibraryBuilder part = library.loader.read(patch, -1,
              origin: library, fileUri: patch, accessor: library);
          first.parts.add(part);
          first.partOffsets.add(-1);
          part.partOfUri = first.importUri;
        }
      }
    }
  }

  void releaseAncillaryResources() {
    component = null;
  }
}

/// Looks for a constructor call that matches `super()` from a constructor in
/// [cls]. Such a constructor may have optional arguments, but no required
/// arguments.
Constructor defaultSuperConstructor(Class cls) {
  Class superclass = cls.superclass;
  if (superclass != null) {
    for (Constructor constructor in superclass.constructors) {
      if (constructor.name.text.isEmpty) {
        return constructor.function.requiredParameterCount == 0
            ? constructor
            : null;
      }
    }
  }
  return null;
}

class KernelDiagnosticReporter
    extends DiagnosticReporter<Message, LocatedMessage> {
  final Loader loader;

  KernelDiagnosticReporter(this.loader);

  void report(Message message, int charOffset, int length, Uri fileUri,
      {List<LocatedMessage> context}) {
    loader.addProblem(message, charOffset, noLength, fileUri, context: context);
  }
}

/// Data for updating cloned parameters of parameters with inferred parameter
/// types.
///
/// The type of [source] is not declared so the type of [target] needs to be
/// updated when the type of [source] has been inferred.
class DelayedParameterType {
  final VariableDeclaration source;
  final VariableDeclaration target;
  final Map<TypeParameter, DartType> substitutionMap;

  DelayedParameterType(this.source, this.target, this.substitutionMap);

  void updateType() {
    assert(source.type != null, "No type computed for $source.");
    target.type = substitute(source.type, substitutionMap);
  }
}

class ClonedFunctionNode {
  final Map<TypeParameter, DartType> _typeSubstitution;
  final FunctionNode _original;
  final FunctionNode _clone;

  ClonedFunctionNode(this._typeSubstitution, this._original, this._clone);

  void cloneDefaultValues() {
    // TODO(ahe): It is unclear if it is legal to use type variables in
    // default values, but Fasta is currently allowing it, and the VM
    // accepts it. If it isn't legal, the we can speed this up by using a
    // single cloner without substitution.
    CloneVisitorNotMembers cloner;

    void cloneInitializer(VariableDeclaration originalParameter,
        VariableDeclaration clonedParameter) {
      if (originalParameter.initializer != null) {
        cloner ??=
            new CloneVisitorNotMembers(typeSubstitution: _typeSubstitution);
        clonedParameter.initializer = cloner
            .clone(originalParameter.initializer)
              ..parent = clonedParameter;
      }
    }

    for (int i = 0; i < _original.positionalParameters.length; i++) {
      cloneInitializer(
          _original.positionalParameters[i], _clone.positionalParameters[i]);
    }

    for (int i = 0; i < _original.namedParameters.length; i++) {
      cloneInitializer(_original.namedParameters[i], _clone.namedParameters[i]);
    }
  }
}
