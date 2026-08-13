// TODO(johnniwinther): Improve error recovery.
class C {
  new() : this.new = 0;
  const new() this.new = 0;
  new() : this.new = 0 {}
  const new() : this.new = 0 {}
  new named() : this.new = 0;
  const new named() : this.new = 0;
  new named() : this.new = 0 {}
  const new named() : this.new = 0 {}
}