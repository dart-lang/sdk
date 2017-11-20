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
  final InstrumentedResolutionStorer _resolutionStorer;

  AnalyzerDietListener(
      SourceLibraryBuilder library,
      ClassHierarchy hierarchy,
      CoreTypes coreTypes,
      TypeInferenceEngine typeInferenceEngine,
      this._resolutionStorer)
      : super(library, hierarchy, coreTypes, typeInferenceEngine);

  StackListener createListener(
      ModifierBuilder builder, Scope memberScope, bool isInstanceMember,
      [Scope formalParameterScope, TypeInferenceListener listener]) {
    return super.createListener(builder, memberScope, isInstanceMember,
        formalParameterScope, _resolutionStorer);
  }
}

class AnalyzerLoader<L> extends SourceLoader<L> {
  final InstrumentedResolutionStorer _resolutionStorer;

  AnalyzerLoader(FileSystem fileSystem, TargetImplementation target,
      this._resolutionStorer)
      : super(fileSystem, false, target);

  @override
  AnalyzerDietListener createDietListener(LibraryBuilder library) {
    return new AnalyzerDietListener(
        library, hierarchy, coreTypes, typeInferenceEngine, _resolutionStorer);
  }
}

class AnalyzerTarget extends KernelTarget {
  /// The list of types stored by body builders while compiling the library.
  final List<kernel.DartType> kernelTypes = [];

  /// File offsets corresponding to the types in [kernelTypes].
  ///
  /// These are used strictly for validation purposes.
  final List<int> typeOffsets = [];

  AnalyzerTarget(FileSystem fileSystem, DillTarget dillTarget,
      UriTranslator uriTranslator, bool strongMode)
      : super(fileSystem, false, dillTarget, uriTranslator);

  @override
  AnalyzerLoader<kernel.Library> createLoader() {
    var storer = new InstrumentedResolutionStorer(kernelTypes, typeOffsets);
    return new AnalyzerLoader<kernel.Library>(fileSystem, this, storer);
  }
}
