import gleam/option

fn some_function() {
  option.Some("asdf")
}

fn combine_two_options(arg: option.Option(String)) {
  option.map(arg, fn(inside) {
    option.map(some_function(), fn(inside2) { inside <> inside2 })
  })
}

fn combine_two_options_better(arg: option.Option(String)) {
  option.then(arg, fn(inside) {
    option.then(some_function(), fn(inside2) { option.Some(inside <> inside2) })
  })
}

fn combine_two_options_best_maybe(arg: option.Option(String)) {
  use inside <- option.then(arg)
  use inside2 <- option.map(some_function())
  inside <> inside2
}
