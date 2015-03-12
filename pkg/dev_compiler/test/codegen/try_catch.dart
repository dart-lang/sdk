main() {
  try {
    throw "hi there";
  } on String catch (e, t) {
  } catch (e, t) {
    rethrow;
  }
}

