
class _DynamicsCompressorNodeImpl extends _AudioNodeImpl implements DynamicsCompressorNode native "*DynamicsCompressorNode" {

  final _AudioParamImpl knee;

  final _AudioParamImpl ratio;

  final _AudioParamImpl reduction;

  final _AudioParamImpl threshold;
}
