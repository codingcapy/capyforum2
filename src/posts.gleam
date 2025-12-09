import lustre/attribute.{class}
import lustre/element/html

pub fn view() {
  html.div([class("text-2xl pt-[100px]")], [
    html.div([class("text-center")], [html.text("POSTS")]),
  ])
}
