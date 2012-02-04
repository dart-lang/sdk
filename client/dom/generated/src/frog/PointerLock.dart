
class _PointerLockJs extends _DOMTypeJs implements PointerLock native "*PointerLock" {

  final bool isLocked;

  void lock(_ElementJs target, [VoidCallback successCallback = null, VoidCallback failureCallback = null]) native;

  void unlock() native;
}
