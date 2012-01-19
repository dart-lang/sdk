
class PointerLock native "*PointerLock" {

  bool isLocked;

  void lock(Element target, [VoidCallback successCallback = null, VoidCallback failureCallback = null]) native;

  void unlock() native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
