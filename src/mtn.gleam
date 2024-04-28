import gleam/bool
import gleam/io
import types

pub fn main() {
  let animal = types.Trait("Animal", [])
  let dog = types.Trait("Dog", [animal])

  io.println("Hello from mtn!")

  io.print(
    bool.to_string(types.value_type_is_subtype_of(
      types.ValueTypeTrait(dog),
      types.ValueTypeTrait(animal),
    )),
  )
}
