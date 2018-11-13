class Hest<TypeX extends Fisk> {}

typedef Fisk = void Function // don't merge lines
    <TypeY extends Hest> //# 01: compile-time error
        ();

main() {
  Hest hest = new Hest();
}
