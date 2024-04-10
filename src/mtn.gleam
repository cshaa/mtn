import gleam/io
import gleam/bool
import types

pub fn main() {
  let animal = types.Trait("Animal", [])
  let dog = types.Trait("Dog", [animal])

  io.println("Hello from mtn!")

  io.print(
    bool.to_string(types.type_satisfies(
      types.TypeTrait(dog),
      types.TypeTrait(animal),
    )),
  )
}
