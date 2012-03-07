
class _DynamicsCompressorNodeJs extends _AudioNodeJs implements DynamicsCompressorNode native "*DynamicsCompressorNode" {

  final _AudioParamJs knee;

  final _AudioParamJs ratio;

  final _AudioParamJs reduction;

  final _AudioParamJs threshold;
}
