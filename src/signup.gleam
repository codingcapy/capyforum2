import lustre/attribute.{class}
import lustre/element/html
import lustre/event
import message

pub fn view() {
  html.div([class("text-2xl pt-[100px]")], [
    html.div([class("text-center")], [html.text("SIGN UP")]),
    html.form(
      [
        event.on_submit(fn(_) { message.UserSubmittedSignup }),
        class("flex flex-col mx-auto max-w-[600px] my-10"),
      ],
      [
        html.input([
          attribute.type_("text"),
          attribute.placeholder("username"),
          class("p-2 border border-white my-2"),
        ]),
        html.input([
          attribute.type_("email"),
          attribute.placeholder("email"),
          class("p-2 border border-white my-2"),
        ]),
        html.input([
          attribute.type_("password"),
          attribute.placeholder("password"),
          class("p-2 border border-white my-2"),
        ]),
        html.button(
          [
            class(
              "px-5 py-2 bg-[#9253E4] rounded-[4px] my-5 cursor-pointer text-bold",
            ),
          ],
          [
            html.text("SIGNUP"),
          ],
        ),
      ],
    ),
  ])
}
