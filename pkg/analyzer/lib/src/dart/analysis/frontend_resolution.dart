import 'package:analyzer/src/fasta/resolution_storer.dart';
import 'package:front_end/file_system.dart';
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
  final List<CollectedResolution> _resolutions;

  AnalyzerDietListener(
      SourceLibraryBuilder library,
      ClassHierarchy hierarchy,
      CoreTypes coreTypes,
      TypeInferenceEngine typeInferenceEngine,
      this._resolutions)
      : super(library, hierarchy, coreTypes, typeInferenceEngine);

  StackListener createListener(
      ModifierBuilder builder, Scope memberScope, bool isInstanceMember,
      [Scope formalParameterScope, TypeInferenceListener listener]) {
    var resolution = new CollectedResolution();
    _resolutions.add(resolution);
    var storer = new InstrumentedResolutionStorer(
        resolution.kernelDeclarations,
        resolution.kernelReferences,
        resolution.kernelTypes,
        resolution.declarationOffsets,
        resolution.referenceOffsets,
        resolution.typeOffsets);
    return super.createListener(
        builder, memberScope, isInstanceMember, formalParameterScope, storer);
  }
}

class AnalyzerLoader<L> extends SourceLoader<L> {
  final List<CollectedResolution> _resolutions;

  AnalyzerLoader(
      FileSystem fileSystem, TargetImplementation target, this._resolutions)
      : super(fileSystem, false, target);

  @override
  AnalyzerDietListener createDietListener(LibraryBuilder library) {
    return new AnalyzerDietListener(
        library, hierarchy, coreTypes, typeInferenceEngine, _resolutions);
  }
}

class AnalyzerTarget extends KernelTarget {
  final List<CollectedResolution> resolutions = [];

  AnalyzerTarget(FileSystem fileSystem, DillTarget dillTarget,
      UriTranslator uriTranslator, bool strongMode)
      : super(fileSystem, false, dillTarget, uriTranslator);

  @override
  AnalyzerLoader<kernel.Library> createLoader() {
    return new AnalyzerLoader<kernel.Library>(fileSystem, this, resolutions);
  }
}

/// Resolution information in a single function body.
class CollectedResolution {
  /// The list of local declarations stored by body builders while
  /// compiling the library.
  final List<kernel.Statement> kernelDeclarations = [];

  /// The list of references to local or external stored by body builders
  /// while compiling the library.
  final List<kernel.TreeNode> kernelReferences = [];

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
