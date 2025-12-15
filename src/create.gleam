import lustre/attribute.{class}
import lustre/element/html
import lustre/event
import message

pub fn view() {
  html.div([class("text-2xl pt-[100px]")], [
    html.div([class("text-center")], [html.text("CREATE POST")]),
    html.form([class("flex flex-col mx-auto max-w-[600px] my-10")], [
      html.input([
        attribute.placeholder("Title"),
        class("p-2 border border-white my-2"),
      ]),
      html.textarea(
        [
          attribute.placeholder("Content"),
          class("p-2 border border-white my-2 h-[100px]"),
        ],
        "",
      ),
      html.button(
        [
          class(
            "px-5 py-2 bg-[#9253E4] rounded-[4px] my-5 cursor-pointer text-bold",
          ),
          event.on_submit(fn(_) { message.UserSubmittedCreatePost }),
        ],
        [
          html.text("CREATE"),
        ],
      ),
    ]),
  ])
}
