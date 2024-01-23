// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/macros/api.dart' as macro;
import 'package:_fe_analyzer_shared/src/macros/executor.dart' as macro;
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';

import '../../../base/common.dart';
import '../../builder/builder.dart';
import '../../builder/declaration_builders.dart';
import '../../builder/member_builder.dart';
import '../../builder/prefix_builder.dart';
import '../../builder/type_builder.dart';
import '../../fasta_codes.dart';
import '../../source/source_class_builder.dart';
import '../../source/source_constructor_builder.dart';
import '../../source/source_extension_builder.dart';
import '../../source/source_factory_builder.dart';
import '../../source/source_field_builder.dart';
import '../../source/source_library_builder.dart';
import '../../source/source_loader.dart';
import '../../source/source_procedure_builder.dart';
import '../../source/source_type_alias_builder.dart';
import '../benchmarker.dart' show BenchmarkSubdivides, Benchmarker;
import '../hierarchy/hierarchy_builder.dart';
import 'annotation_parser.dart';
import 'introspectors.dart';

const String augmentationScheme = 'org-dartlang-augmentation';

final Uri macroLibraryUri =
    Uri.parse('package:_fe_analyzer_shared/src/macros/api.dart');
const String macroClassName = 'Macro';

class MacroDeclarationData {
  bool macrosAreAvailable = false;
  Map<Uri, List<String>> macroDeclarations = {};
  List<List<Uri>>? compilationSequence;
  List<Map<Uri, Map<String, List<String>>>> neededPrecompilations = [];
}

class MacroApplication {
  final int fileOffset;
  final ClassBuilder classBuilder;
  final String constructorName;
  final macro.Arguments arguments;
  final String? errorReason;
  final Set<macro.Phase> appliedPhases = {};

  MacroApplication(this.classBuilder, this.constructorName, this.arguments,
      {required this.fileOffset})
      : errorReason = null;

  MacroApplication.error(String this.errorReason, this.classBuilder,
      {required this.fileOffset})
      : constructorName = '',
        arguments = new macro.Arguments(const [], const {});

  bool get isErroneous => errorReason != null;

  late macro.MacroInstanceIdentifier instanceIdentifier;

  @override
  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write(classBuilder.name);
    sb.write('.');
    if (constructorName.isEmpty) {
      sb.write('new');
    } else {
      sb.write(constructorName);
    }
    sb.write('(');
    String comma = '';
    for (Object? positional in arguments.positional) {
      sb.write(comma);
      sb.write(positional);
      comma = ',';
    }
    for (MapEntry<String, Object?> named in arguments.named.entries) {
      sb.write(comma);
      sb.write(named.key);
      sb.write(':');
      sb.write(named.value);
      comma = ',';
    }
    sb.write(')');
    return sb.toString();
  }
}

class MacroApplicationDataForTesting {
  Map<SourceLibraryBuilder, LibraryMacroApplicationData> libraryData = {};
  Map<SourceLibraryBuilder, String> libraryTypesResult = {};
  Map<SourceLibraryBuilder, String> libraryDefinitionResult = {};

  Map<SourceClassBuilder, List<macro.MacroExecutionResult>> classTypesResults =
      {};

  Map<SourceClassBuilder, List<macro.MacroExecutionResult>>
      classDeclarationsResults = {};
  Map<SourceClassBuilder, List<String>> classDeclarationsSources = {};

  Map<SourceClassBuilder, List<macro.MacroExecutionResult>>
      classDefinitionsResults = {};

  Map<MemberBuilder, List<macro.MacroExecutionResult>> memberTypesResults = {};
  Map<MemberBuilder, List<String>> memberTypesSources = {};

  Map<MemberBuilder, List<macro.MacroExecutionResult>>
      memberDeclarationsResults = {};
  Map<MemberBuilder, List<String>> memberDeclarationsSources = {};

  Map<MemberBuilder, List<macro.MacroExecutionResult>>
      memberDefinitionsResults = {};

  List<ApplicationDataForTesting> typesApplicationOrder = [];
  List<ApplicationDataForTesting> declarationsApplicationOrder = [];
  List<ApplicationDataForTesting> definitionApplicationOrder = [];

  void registerTypesResults(
      Builder builder, List<macro.MacroExecutionResult> results) {
    if (builder is SourceClassBuilder) {
      (classTypesResults[builder] ??= []).addAll(results);
    } else {
      (memberTypesResults[builder as MemberBuilder] ??= []).addAll(results);
    }
  }

  void registerDeclarationsResult(
      Builder builder, macro.MacroExecutionResult result, String source) {
    if (builder is SourceClassBuilder) {
      (classDeclarationsResults[builder] ??= []).add(result);
      (classDeclarationsSources[builder] ??= []).add(source);
    } else {
      (memberDeclarationsResults[builder as MemberBuilder] ??= []).add(result);
      (memberDeclarationsSources[builder] ??= []).add(source);
    }
  }

  void registerDefinitionsResults(
      Builder builder, List<macro.MacroExecutionResult> results) {
    if (builder is SourceClassBuilder) {
      (classDefinitionsResults[builder] ??= []).addAll(results);
    } else {
      (memberDefinitionsResults[builder as MemberBuilder] ??= [])
          .addAll(results);
    }
  }
}

class ApplicationDataForTesting {
  final ApplicationData applicationData;
  final MacroApplication macroApplication;

  ApplicationDataForTesting(this.applicationData, this.macroApplication);

  @override
  String toString() {
    StringBuffer sb = new StringBuffer();
    Builder builder = applicationData.builder;
    if (builder is MemberBuilder) {
      if (builder.classBuilder != null) {
        sb.write(builder.classBuilder!.name);
        sb.write('.');
      }
      sb.write(builder.name);
    } else {
      sb.write((builder as ClassBuilder).name);
    }
    sb.write(':');
    sb.write(macroApplication);
    return sb.toString();
  }
}

class LibraryMacroApplicationData {
  Map<SourceClassBuilder, ClassMacroApplicationData> classData = {};
  Map<MemberBuilder, ApplicationData> memberApplications = {};
}

class ClassMacroApplicationData {
  ApplicationData? classApplications;
  Map<MemberBuilder, ApplicationData> memberApplications = {};
}

/// Macro classes that need to be precompiled.
class NeededPrecompilations {
  /// Map from library uris to macro class names and the names of constructor
  /// their constructors is returned for macro classes that need to be
  /// precompiled.
  final Map<Uri, Map<String, List<String>>> macroDeclarations;

  NeededPrecompilations(this.macroDeclarations);
}

void checkMacroApplications(
    ClassHierarchy hierarchy,
    Class macroClass,
    List<SourceLibraryBuilder> sourceLibraryBuilders,
    MacroApplications? macroApplications) {
  Map<Library, List<LibraryMacroApplicationData>> libraryData = {};
  if (macroApplications != null) {
    for (MapEntry<SourceLibraryBuilder, LibraryMacroApplicationData> entry
        in macroApplications._libraryData.entries) {
      (libraryData[entry.key.library] ??= []).add(entry.value);
    }
  }
  for (SourceLibraryBuilder libraryBuilder in sourceLibraryBuilders) {
    void checkAnnotations(List<Expression> annotations,
        List<ApplicationData>? applicationDataList,
        {required Uri fileUri}) {
      if (annotations.isEmpty) {
        return;
      }
      // We cannot currently identify macro applications by offsets because
      // file offsets on annotations are not stable.
      // TODO(johnniwinther): Handle file uri + offset on annotations.
      Map<Class, Map<int, MacroApplication>> macroApplications = {};
      if (applicationDataList != null) {
        for (ApplicationData applicationData in applicationDataList) {
          for (MacroApplication application
              in applicationData.macroApplications) {
            Map<int, MacroApplication> applications =
                macroApplications[application.classBuilder.cls] ??= {};
            int fileOffset = application.fileOffset;
            assert(
                !applications.containsKey(fileOffset),
                "Multiple annotations at offset $fileOffset: "
                "${applications[fileOffset]} and ${application}.");
            applications[fileOffset] = application;
          }
        }
      }
      for (Expression annotation in annotations) {
        if (annotation is ConstantExpression) {
          Constant constant = annotation.constant;
          if (constant is InstanceConstant &&
              hierarchy.isSubInterfaceOf(constant.classNode, macroClass)) {
            Map<int, MacroApplication>? applications =
                macroApplications[constant.classNode];
            MacroApplication? macroApplication =
                applications?.remove(annotation.fileOffset);
            if (macroApplication != null) {
              if (macroApplication.isErroneous) {
                libraryBuilder.addProblem(
                    templateUnhandledMacroApplication
                        .withArguments(macroApplication.errorReason!),
                    annotation.fileOffset,
                    noLength,
                    fileUri);
              }
            } else {
              // TODO(johnniwinther): Improve the diagnostics about why the
              // macro didn't apply here.
              libraryBuilder.addProblem(messageUnsupportedMacroApplication,
                  annotation.fileOffset, noLength, fileUri);
            }
          }
        }
      }
    }

    void checkMembers(Iterable<Member> members,
        Map<Annotatable, List<ApplicationData>> memberData) {
      for (Member member in members) {
        checkAnnotations(member.annotations, memberData[member],
            fileUri: member.fileUri);
      }
    }

    Map<Class, List<ClassMacroApplicationData>> classData = {};
    Map<Annotatable, List<ApplicationData>> libraryMemberData = {};
    List<LibraryMacroApplicationData>? libraryMacroApplicationDataList =
        libraryData[libraryBuilder.library];
    if (libraryMacroApplicationDataList != null) {
      for (LibraryMacroApplicationData libraryMacroApplicationData
          in libraryMacroApplicationDataList) {
        for (MapEntry<SourceClassBuilder, ClassMacroApplicationData> entry
            in libraryMacroApplicationData.classData.entries) {
          (classData[entry.key.cls] ??= []).add(entry.value);
        }
        for (MapEntry<MemberBuilder, ApplicationData> entry
            in libraryMacroApplicationData.memberApplications.entries) {
          for (Annotatable annotatable in entry.key.annotatables) {
            (libraryMemberData[annotatable] ??= []).add(entry.value);
          }
        }
      }
    }

    Library library = libraryBuilder.library;
    checkMembers(library.members, libraryMemberData);
    for (Class cls in library.classes) {
      List<ClassMacroApplicationData>? classMacroApplications = classData[cls];
      List<ApplicationData> applicationDataList = [];
      if (classMacroApplications != null) {
        for (ClassMacroApplicationData classMacroApplicationData
            in classMacroApplications) {
          ApplicationData? classApplications =
              classMacroApplicationData.classApplications;
          if (classApplications != null) {
            applicationDataList.add(classApplications);
          }
        }
      }
      checkAnnotations(cls.annotations, applicationDataList,
          fileUri: cls.fileUri);

      Map<Annotatable, List<ApplicationData>> classMemberData = {};
      if (classMacroApplications != null) {
        for (ClassMacroApplicationData classMacroApplicationData
            in classMacroApplications) {
          for (MapEntry<MemberBuilder, ApplicationData> entry
              in classMacroApplicationData.memberApplications.entries) {
            for (Annotatable annotatable in entry.key.annotatables) {
              (classMemberData[annotatable] ??= []).add(entry.value);
            }
          }
        }
      }
      checkMembers(cls.members, classMemberData);
    }
  }
}

class MacroApplications {
  final macro.MacroExecutor _macroExecutor;
  final MacroIntrospection _macroIntrospection;
  final Map<SourceLibraryBuilder, LibraryMacroApplicationData> _libraryData =
      {};
  final MacroApplicationDataForTesting? dataForTesting;

  List<LibraryMacroApplicationData> _pendingLibraryData = [];

  MacroApplications(
      SourceLoader sourceLoader, this._macroExecutor, this.dataForTesting)
      : _macroIntrospection = new MacroIntrospection(sourceLoader) {}

  macro.MacroExecutor get macroExecutor => _macroExecutor;

  bool get hasLoadableMacroIds => _pendingLibraryData.isNotEmpty;

  void computeLibrariesMacroApplicationData(
      Iterable<SourceLibraryBuilder> libraryBuilders) {
    for (SourceLibraryBuilder libraryBuilder in libraryBuilders) {
      _computeSourceLibraryMacroApplicationData(libraryBuilder);
    }
  }

  void _computeSourceLibraryMacroApplicationData(
      SourceLibraryBuilder libraryBuilder) {
    // TODO(johnniwinther): Handle patch libraries.
    LibraryMacroApplicationData libraryMacroApplicationData =
        new LibraryMacroApplicationData();
    Iterator<Builder> iterator = libraryBuilder.localMembersIterator;
    while (iterator.moveNext()) {
      Builder builder = iterator.current;
      if (builder is SourceClassBuilder) {
        SourceClassBuilder classBuilder = builder;
        ClassMacroApplicationData classMacroApplicationData =
            new ClassMacroApplicationData();
        List<MacroApplication>? classMacroApplications = prebuildAnnotations(
            enclosingLibrary: libraryBuilder,
            scope: classBuilder.scope,
            fileUri: classBuilder.fileUri,
            metadataBuilders: classBuilder.metadata);
        if (classMacroApplications != null) {
          classMacroApplicationData.classApplications =
              new ClassApplicationData(_macroIntrospection, libraryBuilder,
                  classBuilder, classMacroApplications);
        }
        Iterator<Builder> memberIterator = classBuilder.localMemberIterator();
        while (memberIterator.moveNext()) {
          Builder memberBuilder = memberIterator.current;
          if (memberBuilder is SourceProcedureBuilder) {
            List<MacroApplication>? macroApplications = prebuildAnnotations(
                enclosingLibrary: libraryBuilder,
                scope: classBuilder.scope,
                fileUri: memberBuilder.fileUri,
                metadataBuilders: memberBuilder.metadata);
            if (macroApplications != null) {
              classMacroApplicationData.memberApplications[memberBuilder] =
                  new MemberApplicationData(_macroIntrospection, libraryBuilder,
                      memberBuilder, macroApplications);
            }
          } else if (memberBuilder is SourceFieldBuilder) {
            List<MacroApplication>? macroApplications = prebuildAnnotations(
                enclosingLibrary: libraryBuilder,
                scope: classBuilder.scope,
                fileUri: memberBuilder.fileUri,
                metadataBuilders: memberBuilder.metadata);
            if (macroApplications != null) {
              classMacroApplicationData.memberApplications[memberBuilder] =
                  new MemberApplicationData(_macroIntrospection, libraryBuilder,
                      memberBuilder, macroApplications);
            }
          } else {
            throw new UnsupportedError("Unexpected class member "
                "$memberBuilder (${memberBuilder.runtimeType})");
          }
        }
        Iterator<MemberBuilder> constructorIterator =
            classBuilder.localConstructorIterator();
        while (constructorIterator.moveNext()) {
          MemberBuilder memberBuilder = constructorIterator.current;
          if (memberBuilder is DeclaredSourceConstructorBuilder) {
            List<MacroApplication>? macroApplications = prebuildAnnotations(
                enclosingLibrary: libraryBuilder,
                scope: classBuilder.scope,
                fileUri: memberBuilder.fileUri,
                metadataBuilders: memberBuilder.metadata);
            if (macroApplications != null) {
              classMacroApplicationData.memberApplications[memberBuilder] =
                  new MemberApplicationData(_macroIntrospection, libraryBuilder,
                      memberBuilder, macroApplications);
            }
          } else if (memberBuilder is SourceFactoryBuilder) {
            List<MacroApplication>? macroApplications = prebuildAnnotations(
                enclosingLibrary: libraryBuilder,
                scope: classBuilder.scope,
                fileUri: memberBuilder.fileUri,
                metadataBuilders: memberBuilder.metadata);
            if (macroApplications != null) {
              classMacroApplicationData.memberApplications[memberBuilder] =
                  new MemberApplicationData(_macroIntrospection, libraryBuilder,
                      memberBuilder, macroApplications);
            }
          } else {
            throw new UnsupportedError("Unexpected constructor "
                "$memberBuilder (${memberBuilder.runtimeType})");
          }
        }

        if (classMacroApplicationData.classApplications != null ||
            classMacroApplicationData.memberApplications.isNotEmpty) {
          libraryMacroApplicationData.classData[builder] =
              classMacroApplicationData;
        }
      } else if (builder is SourceProcedureBuilder) {
        List<MacroApplication>? macroApplications = prebuildAnnotations(
            enclosingLibrary: libraryBuilder,
            scope: libraryBuilder.scope,
            fileUri: builder.fileUri,
            metadataBuilders: builder.metadata);
        if (macroApplications != null) {
          libraryMacroApplicationData.memberApplications[builder] =
              new MemberApplicationData(_macroIntrospection, libraryBuilder,
                  builder, macroApplications);
        }
      } else if (builder is SourceFieldBuilder) {
        List<MacroApplication>? macroApplications = prebuildAnnotations(
            enclosingLibrary: libraryBuilder,
            scope: libraryBuilder.scope,
            fileUri: builder.fileUri,
            metadataBuilders: builder.metadata);
        if (macroApplications != null) {
          libraryMacroApplicationData.memberApplications[builder] =
              new MemberApplicationData(_macroIntrospection, libraryBuilder,
                  builder, macroApplications);
        }
      } else if (builder is PrefixBuilder ||
          builder is SourceExtensionBuilder ||
          builder is SourceTypeAliasBuilder) {
        // Macro applications are not supported.
      } else {
        throw new UnsupportedError("Unexpected library member "
            "$builder (${builder.runtimeType})");
      }
    }
    if (libraryMacroApplicationData.classData.isNotEmpty ||
        libraryMacroApplicationData.memberApplications.isNotEmpty) {
      _libraryData[libraryBuilder] = libraryMacroApplicationData;
      dataForTesting?.libraryData[libraryBuilder] = libraryMacroApplicationData;
      _pendingLibraryData.add(libraryMacroApplicationData);
    }
  }

  Future<void> loadMacroIds(Benchmarker? benchmarker) async {
    Map<MacroApplication, macro.MacroInstanceIdentifier> instanceIdCache = {};

    Future<void> ensureMacroClassIds(
        List<MacroApplication>? applications) async {
      if (applications != null) {
        for (MacroApplication application in applications) {
          if (application.isErroneous) {
            continue;
          }
          Uri libraryUri = application.classBuilder.libraryBuilder.importUri;
          String macroClassName = application.classBuilder.name;
          try {
            benchmarker?.beginSubdivide(
                BenchmarkSubdivides.macroApplications_macroExecutorLoadMacro);
            benchmarker?.endSubdivide();
            try {
              benchmarker?.beginSubdivide(BenchmarkSubdivides
                  .macroApplications_macroExecutorInstantiateMacro);
              application.instanceIdentifier = instanceIdCache[application] ??=
                  // TODO: Dispose of these instances using
                  // `macroExecutor.disposeMacro` once we are done with them.
                  await macroExecutor.instantiateMacro(
                      libraryUri,
                      macroClassName,
                      application.constructorName,
                      application.arguments);
              benchmarker?.endSubdivide();
            } catch (e, s) {
              throw "Error instantiating macro `${application}`: "
                  "$e\n$s";
            }
          } catch (e, s) {
            throw "Error loading macro class "
                "'${application.classBuilder.name}' from "
                "'${application.classBuilder.libraryBuilder.importUri}': "
                "$e\n$s";
          }
        }
      }
    }

    for (LibraryMacroApplicationData libraryData in _pendingLibraryData) {
      for (ClassMacroApplicationData classData
          in libraryData.classData.values) {
        await ensureMacroClassIds(
            classData.classApplications?.macroApplications);
        for (ApplicationData applicationData
            in classData.memberApplications.values) {
          await ensureMacroClassIds(applicationData.macroApplications);
        }
      }
      for (ApplicationData applicationData
          in libraryData.memberApplications.values) {
        await ensureMacroClassIds(applicationData.macroApplications);
      }
    }
    _pendingLibraryData.clear();
  }

  Future<List<macro.MacroExecutionResult>> _applyTypeMacros(
      ApplicationData applicationData) async {
    macro.Declaration declaration = applicationData.declaration;
    List<macro.MacroExecutionResult> results = [];
    for (MacroApplication macroApplication
        in applicationData.macroApplications) {
      if (!macroApplication.appliedPhases.add(macro.Phase.types)) {
        continue;
      }
      if (macroApplication.isErroneous) {
        continue;
      }
      if (macroApplication.instanceIdentifier
          .shouldExecute(_declarationKind(declaration), macro.Phase.types)) {
        if (retainDataForTesting) {
          dataForTesting!.typesApplicationOrder.add(
              new ApplicationDataForTesting(applicationData, macroApplication));
        }
        macro.MacroExecutionResult result =
            await _macroExecutor.executeTypesPhase(
                macroApplication.instanceIdentifier,
                declaration,
                _macroIntrospection.typePhaseIntrospector);
        result.reportDiagnostics(applicationData);
        if (result.isNotEmpty) {
          results.add(result);
        }
      }
    }

    if (retainDataForTesting) {
      dataForTesting?.registerTypesResults(applicationData.builder, results);
    }
    return results;
  }

  void enterTypeMacroPhase() {
    _macroIntrospection.enterTypeMacroPhase();
  }

  Future<List<SourceLibraryBuilder>> applyTypeMacros() async {
    // TODO(johnniwinther): Maintain a pending list instead of running through
    // all annotations to find the once have to be applied now.
    List<SourceLibraryBuilder> augmentationLibraries = [];
    for (MapEntry<SourceLibraryBuilder, LibraryMacroApplicationData> entry
        in _libraryData.entries) {
      List<macro.MacroExecutionResult> executionResults = [];
      SourceLibraryBuilder libraryBuilder = entry.key;
      LibraryMacroApplicationData data = entry.value;
      for (ApplicationData applicationData in data.memberApplications.values) {
        executionResults.addAll(await _applyTypeMacros(applicationData));
      }
      for (MapEntry<ClassBuilder, ClassMacroApplicationData> entry
          in data.classData.entries) {
        ClassMacroApplicationData classApplicationData = entry.value;
        for (ApplicationData applicationData
            in classApplicationData.memberApplications.values) {
          executionResults.addAll(await _applyTypeMacros(applicationData));
        }
        if (classApplicationData.classApplications != null) {
          executionResults.addAll(
              await _applyTypeMacros(classApplicationData.classApplications!));
        }
      }
      if (executionResults.isNotEmpty) {
        Map<macro.OmittedTypeAnnotation, String> omittedTypes = {};
        String result = _macroExecutor
            .buildAugmentationLibrary(
                executionResults,
                _macroIntrospection.resolveDeclaration,
                _macroIntrospection.resolveIdentifier,
                _macroIntrospection.types.inferOmittedType,
                omittedTypes: omittedTypes)
            .trim();
        assert(
            result.trim().isNotEmpty,
            "Empty types phase augmentation library source for "
            "$libraryBuilder}");
        if (result.isNotEmpty) {
          if (retainDataForTesting) {
            dataForTesting?.libraryTypesResult[libraryBuilder] = result;
          }
          Map<String, OmittedTypeBuilder>? omittedTypeBuilders =
              _macroIntrospection.types
                  .computeOmittedTypeBuilders(omittedTypes);
          augmentationLibraries.add(await libraryBuilder.origin
              .createAugmentationLibrary(result,
                  omittedTypes: omittedTypeBuilders));
        }
      }
    }

    return augmentationLibraries;
  }

  Future<void> _applyDeclarationsMacros(ApplicationData applicationData,
      Future<void> Function(SourceLibraryBuilder) onAugmentationLibrary) async {
    List<macro.MacroExecutionResult> results = [];
    macro.Declaration declaration = applicationData.declaration;
    for (MacroApplication macroApplication
        in applicationData.macroApplications) {
      if (!macroApplication.appliedPhases.add(macro.Phase.declarations)) {
        continue;
      }
      if (macroApplication.isErroneous) {
        continue;
      }
      if (macroApplication.instanceIdentifier.shouldExecute(
          _declarationKind(declaration), macro.Phase.declarations)) {
        if (retainDataForTesting) {
          dataForTesting!.declarationsApplicationOrder.add(
              new ApplicationDataForTesting(applicationData, macroApplication));
        }
        macro.MacroExecutionResult result =
            await _macroExecutor.executeDeclarationsPhase(
                macroApplication.instanceIdentifier,
                declaration,
                _macroIntrospection.declarationPhaseIntrospector);
        result.reportDiagnostics(applicationData);
        if (result.isNotEmpty) {
          Map<macro.OmittedTypeAnnotation, String> omittedTypes = {};
          String source = _macroExecutor.buildAugmentationLibrary(
              [result],
              _macroIntrospection.resolveDeclaration,
              _macroIntrospection.resolveIdentifier,
              _macroIntrospection.types.inferOmittedType,
              omittedTypes: omittedTypes);
          if (retainDataForTesting) {
            dataForTesting?.registerDeclarationsResult(
                applicationData.builder, result, source);
          }
          Map<String, OmittedTypeBuilder>? omittedTypeBuilders =
              _macroIntrospection.types
                  .computeOmittedTypeBuilders(omittedTypes);

          SourceLibraryBuilder augmentationLibrary = await applicationData
              .libraryBuilder.origin
              .createAugmentationLibrary(source,
                  omittedTypes: omittedTypeBuilders);
          await onAugmentationLibrary(augmentationLibrary);
          if (retainDataForTesting) {
            results.add(result);
          }
        }
      }
    }
    if (retainDataForTesting) {
      Builder builder = applicationData.builder;
      if (builder is SourceClassBuilder) {
        dataForTesting?.classDeclarationsResults[builder] = results;
      } else {
        dataForTesting?.memberDeclarationsResults[builder as MemberBuilder] =
            results;
      }
    }
  }

  void enterDeclarationsMacroPhase(ClassHierarchyBuilder classHierarchy) {
    _macroIntrospection.enterDeclarationsMacroPhase(classHierarchy);
  }

  Future<void> applyDeclarationsMacros(
      List<SourceClassBuilder> sortedSourceClassBuilders,
      Future<void> Function(SourceLibraryBuilder) onAugmentationLibrary) async {
    // TODO(johnniwinther): Maintain a pending list instead of running through
    // all annotations to find the once have to be applied now.
    Future<void> applyClassMacros(SourceClassBuilder classBuilder) async {
      LibraryMacroApplicationData? libraryApplicationData =
          _libraryData[classBuilder.libraryBuilder];
      if (libraryApplicationData == null) return;

      ClassMacroApplicationData? classApplicationData =
          libraryApplicationData.classData[classBuilder];
      if (classApplicationData == null) return;
      for (ApplicationData applicationData
          in classApplicationData.memberApplications.values) {
        await _applyDeclarationsMacros(applicationData, onAugmentationLibrary);
      }
      if (classApplicationData.classApplications != null) {
        await _applyDeclarationsMacros(
            classApplicationData.classApplications!, onAugmentationLibrary);
      }
    }

    // Apply macros to classes first, in class hierarchy order.
    for (SourceClassBuilder classBuilder in sortedSourceClassBuilders) {
      await applyClassMacros(classBuilder);
      // TODO(johnniwinther): Avoid accessing augmentations from the outside.
      List<SourceClassBuilder>? augmentationClassBuilders =
          classBuilder.patchesForTesting;
      if (augmentationClassBuilders != null) {
        for (SourceClassBuilder augmentationClassBuilder
            in augmentationClassBuilders) {
          await applyClassMacros(augmentationClassBuilder);
        }
      }
    }

    // Apply macros to library members second.
    for (MapEntry<SourceLibraryBuilder, LibraryMacroApplicationData> entry
        in _libraryData.entries) {
      LibraryMacroApplicationData data = entry.value;
      for (ApplicationData applicationData in data.memberApplications.values) {
        await _applyDeclarationsMacros(applicationData, onAugmentationLibrary);
      }
    }
  }

  Future<List<macro.MacroExecutionResult>> _applyDefinitionMacros(
      ApplicationData applicationData) async {
    List<macro.MacroExecutionResult> results = [];
    macro.Declaration declaration = applicationData.declaration;
    for (MacroApplication macroApplication
        in applicationData.macroApplications) {
      if (!macroApplication.appliedPhases.add(macro.Phase.definitions)) {
        continue;
      }
      if (macroApplication.isErroneous) {
        continue;
      }
      if (macroApplication.instanceIdentifier.shouldExecute(
          _declarationKind(declaration), macro.Phase.definitions)) {
        if (retainDataForTesting) {
          dataForTesting!.definitionApplicationOrder.add(
              new ApplicationDataForTesting(applicationData, macroApplication));
        }
        macro.MacroExecutionResult result =
            await _macroExecutor.executeDefinitionsPhase(
                macroApplication.instanceIdentifier,
                declaration,
                _macroIntrospection.definitionPhaseIntrospector);
        result.reportDiagnostics(applicationData);
        if (result.isNotEmpty) {
          results.add(result);
        }
      }
    }
    if (retainDataForTesting) {
      dataForTesting?.registerDefinitionsResults(
          applicationData.builder, results);
    }
    return results;
  }

  void enterDefinitionMacroPhase() {
    _macroIntrospection.enterDefinitionMacroPhase();
  }

  Future<List<SourceLibraryBuilder>> applyDefinitionMacros() async {
    // TODO(johnniwinther): Maintain a pending list instead of running through
    // all annotations to find the once have to be applied now.
    List<SourceLibraryBuilder> augmentationLibraries = [];
    for (MapEntry<SourceLibraryBuilder, LibraryMacroApplicationData> entry
        in _libraryData.entries) {
      List<macro.MacroExecutionResult> executionResults = [];
      SourceLibraryBuilder libraryBuilder = entry.key;
      LibraryMacroApplicationData data = entry.value;
      for (ApplicationData applicationData in data.memberApplications.values) {
        executionResults.addAll(await _applyDefinitionMacros(applicationData));
      }
      for (MapEntry<ClassBuilder, ClassMacroApplicationData> entry
          in data.classData.entries) {
        ClassMacroApplicationData classApplicationData = entry.value;
        for (ApplicationData applicationData
            in classApplicationData.memberApplications.values) {
          executionResults
              .addAll(await _applyDefinitionMacros(applicationData));
        }
        if (classApplicationData.classApplications != null) {
          executionResults.addAll(await _applyDefinitionMacros(
              classApplicationData.classApplications!));
        }
      }
      if (executionResults.isNotEmpty) {
        String result = _macroExecutor
            .buildAugmentationLibrary(
                executionResults,
                _macroIntrospection.resolveDeclaration,
                _macroIntrospection.resolveIdentifier,
                _macroIntrospection.types.inferOmittedType)
            .trim();
        assert(
            result.trim().isNotEmpty,
            "Empty definitions phase augmentation library source for "
            "$libraryBuilder}");
        if (retainDataForTesting) {
          dataForTesting?.libraryDefinitionResult[libraryBuilder] = result;
        }
        augmentationLibraries
            .add(await libraryBuilder.origin.createAugmentationLibrary(result));
      }
    }
    return augmentationLibraries;
  }

  void close() {
    _macroExecutor.close();
    _macroIntrospection.clear();
    if (!retainDataForTesting) {
      _libraryData.clear();
    }
  }
}

macro.DeclarationKind _declarationKind(macro.Declaration declaration) {
  if (declaration is macro.ConstructorDeclaration) {
    return macro.DeclarationKind.constructor;
  } else if (declaration is macro.MethodDeclaration) {
    return macro.DeclarationKind.method;
  } else if (declaration is macro.FunctionDeclaration) {
    return macro.DeclarationKind.function;
  } else if (declaration is macro.FieldDeclaration) {
    return macro.DeclarationKind.field;
  } else if (declaration is macro.VariableDeclaration) {
    return macro.DeclarationKind.variable;
  } else if (declaration is macro.ClassDeclaration) {
    return macro.DeclarationKind.classType;
  } else if (declaration is macro.EnumDeclaration) {
    return macro.DeclarationKind.enumType;
  } else if (declaration is macro.MixinDeclaration) {
    return macro.DeclarationKind.mixinType;
  }
  throw new UnsupportedError(
      "Unexpected declaration ${declaration} (${declaration.runtimeType})");
}

/// Data needed to apply a list of macro applications to a class or member.
abstract class ApplicationData {
  final MacroIntrospection _macroIntrospection;
  final SourceLibraryBuilder libraryBuilder;
  final List<MacroApplication> macroApplications;

  ApplicationData(
      this._macroIntrospection, this.libraryBuilder, this.macroApplications);

  macro.Declaration get declaration;

  Builder get builder;
}

class ClassApplicationData extends ApplicationData {
  final SourceClassBuilder _classBuilder;

  macro.ParameterizedTypeDeclaration? _declaration;

  ClassApplicationData(super.macroIntrospection, super.libraryBuilder,
      this._classBuilder, super.macroApplications);

  @override
  macro.Declaration get declaration {
    return _declaration ??=
        _macroIntrospection.getClassDeclaration(_classBuilder);
  }

  @override
  Builder get builder => _classBuilder;
}

class MemberApplicationData extends ApplicationData {
  final MemberBuilder _memberBuilder;

  macro.Declaration? _declaration;

  MemberApplicationData(super.macroIntrospection, super.libraryBuilder,
      this._memberBuilder, super.macroApplications);

  @override
  macro.Declaration get declaration {
    return _declaration ??=
        _macroIntrospection.getMemberDeclaration(_memberBuilder);
  }

  @override
  Builder get builder => _memberBuilder;
}

extension on macro.MacroExecutionResult {
  bool get isNotEmpty =>
      enumValueAugmentations.isNotEmpty ||
      libraryAugmentations.isNotEmpty ||
      typeAugmentations.isNotEmpty;

  void reportDiagnostics(ApplicationData applicationData) {
    for (macro.Diagnostic diagnostic in diagnostics) {
      // TODO(johnniwinther): Improve reporting.
      applicationData.libraryBuilder.addProblem(
          templateUnspecified.withArguments(diagnostic.message.message),
          -1,
          -1,
          null);
    }
  }
}
