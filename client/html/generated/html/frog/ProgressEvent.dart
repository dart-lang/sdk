
class _ProgressEventImpl extends _EventImpl implements ProgressEvent native "*ProgressEvent" {

  final bool lengthComputable;

  final int loaded;

  final int total;
}
