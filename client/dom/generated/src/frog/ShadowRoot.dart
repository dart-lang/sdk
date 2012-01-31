
class ShadowRootJs extends NodeJs implements ShadowRoot native "*ShadowRoot" {

  ElementJs get host() native "return this.host;";
}
