import 'package:analyzer/src/fasta/resolution_storer.dart';
import 'package:front_end/src/api_prototype/file_system.dart';
import 'package:front_end/src/fasta/builder/builder.dart';
import 'package:front_end/src/fasta/builder/library_builder.dart';
import 'package:front_end/src/fasta/dill/dill_target.dart';
import 'package:front_end/src/fasta/kernel/kernel_target.dart';
import 'package:front_end/src/fasta/source/diet_listener.dart';
import 'package:front_end/src/fasta/source/source_library_builder.dart';
import 'package:front_end/src/fasta/source/source_loader.dart';
import 'package:front_end/src/fasta/source/stack_listener.dart';
import 'package:front_end/src/fasta/target_implementation.dart';
import 'package:front_end/src/fasta/type_inference/type_inference_engine.dart';
import 'package:front_end/src/fasta/type_inference/type_inference_listener.dart';
import 'package:front_end/src/fasta/uri_translator.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/kernel.dart' as kernel;

class AnalyzerDietListener extends DietListener {
  final Uri _requestedLibraryFileUri;
  final List<CollectedResolution> _resolutions;

  AnalyzerDietListener(
      SourceLibraryBuilder library,
      ClassHierarchy hierarchy,
      CoreTypes coreTypes,
      TypeInferenceEngine typeInferenceEngine,
      this._requestedLibraryFileUri,
      this._resolutions)
      : super(library, hierarchy, coreTypes, typeInferenceEngine);

  StackListener createListener(
      ModifierBuilder builder, Scope memberScope, bool isInstanceMember,
      [Scope formalParameterScope, TypeInferenceListener listener]) {
    InstrumentedResolutionStorer storer;
    if (_isInRequestedLibrary(builder)) {
      var resolution = new CollectedResolution();
      _resolutions.add(resolution);
      storer = new InstrumentedResolutionStorer(
          resolution.kernelDeclarations,
          resolution.kernelReferences,
          resolution.kernelTypes,
          resolution.declarationOffsets,
          resolution.referenceOffsets,
          resolution.typeOffsets);
    }
    return super.createListener(
        builder, memberScope, isInstanceMember, formalParameterScope, storer);
  }

  /// Return `true` if the given [builder] is in the requested library.
  bool _isInRequestedLibrary(Builder builder) {
    return builder.computeLibraryUri() == _requestedLibraryFileUri;
  }
}

class AnalyzerLoader<L> extends SourceLoader<L> {
  final Uri _requestedLibraryFileUri;
  final List<CollectedResolution> _resolutions;

  AnalyzerLoader(FileSystem fileSystem, TargetImplementation target,
      this._requestedLibraryFileUri, this._resolutions)
      : super(fileSystem, false, target);

  @override
  AnalyzerDietListener createDietListener(LibraryBuilder library) {
    return new AnalyzerDietListener(library, hierarchy, coreTypes,
        typeInferenceEngine, _requestedLibraryFileUri, _resolutions);
  }
}

class AnalyzerTarget extends KernelTarget {
  final Uri requestedLibraryFileUri;
  final List<CollectedResolution> resolutions = [];

  AnalyzerTarget(
      FileSystem fileSystem,
      DillTarget dillTarget,
      UriTranslator uriTranslator,
      bool strongMode,
      this.requestedLibraryFileUri)
      : super(fileSystem, false, dillTarget, uriTranslator);

  @override
  AnalyzerLoader<kernel.Library> createLoader() {
    return new AnalyzerLoader<kernel.Library>(
        fileSystem, this, requestedLibraryFileUri, resolutions);
  }
}

/// Resolution information in a single function body.
class CollectedResolution {
  /// The list of local declarations stored by body builders while
  /// compiling the library.
  final List<kernel.TreeNode> kernelDeclarations = [];

  /// The list of references to local or external stored by body builders
  /// while compiling the library.
  final List<kernel.Node> kernelReferences = [];

  /// The list of types stored by body builders while compiling the library.
  final List<kernel.DartType> kernelTypes = [];

  /// File offsets corresponding to the declarations in [kernelDeclarations].
  ///
  /// These are used strictly for validation purposes.
  final List<int> declarationOffsets = [];

  /// File offsets corresponding to the objects in [kernelReferences].
  ///
  /// These are used strictly for validation purposes.
  final List<int> referenceOffsets = [];

  /// File offsets corresponding to the types in [kernelTypes].
  ///
  /// These are used strictly for validation purposes.
  final List<int> typeOffsets = [];
}
