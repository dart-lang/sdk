import 'package:analyzer/dart/analysis/results.dart';
import 'package:nnbd_migration/src/messages.dart';

/// A [StateError] specific to the ways that the NNBD experiment can be
/// misconfigured which may prevent the tool from working.
class ExperimentStatusException extends StateError {
  /// All files included in the migration dir have already been migrated.
  ExperimentStatusException.migratedAlready() : super(migratedAlready);

  /// The SDK was analyzed without NNBD semantics.
  ExperimentStatusException.sdkExperimentDisabled() : super(nnbdExperimentOff);

  /// The SDK does not contain the NNBD sources, it is the pre-unfork copy.
  ExperimentStatusException.sdkPreforkSources() : super(sdkNnbdOff);

  /// Throw an [ExperimentStatusException] if the [result] seems to have
  /// incorrectly configured experiment flags/nnbd sources.
  static void sanityCheck(ResolvedUnitResult result) {
    final equalsParamType = result.typeProvider.objectType
        .getMethod('==')
        .parameters[0]
        .type
        .getDisplayString(withNullability: true);
    if (equalsParamType == 'Object*') {
      throw ExperimentStatusException.sdkExperimentDisabled();
    }

    if (equalsParamType != 'Object') {
      throw ExperimentStatusException.sdkPreforkSources();
    }
  }
}
