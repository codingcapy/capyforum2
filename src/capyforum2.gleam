import api
import create
import gleam/http/response
import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import gleam/uri
import lib/async_data
import login
import lustre
import lustre/attribute.{class}
import lustre/effect.{type Effect}
import lustre/element/html
import message
import model.{type Model, Model}
import modem
import plinth/browser/window
import posts
import rsvp
import signup

pub fn main() -> Nil {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  io.println("Hello!")
}

pub fn init(_) -> #(Model, effect.Effect(message.Msg)) {
  let route = initial_route()
  let model =
    Model(
      route:,
      user: async_data.NotAsked,
      posts: async_data.NotAsked,
      create_post_ui: model.initial_create_post_ui(),
    )
  let #(model, data_fx) = ensure_data(model)
  let fx = effect.batch([modem.init(on_url_change), data_fx])
  #(model, fx)
}

fn initial_route() -> model.Route {
  modem.initial_uri()
  |> result.map(fn(uri) { echo uri.path_segments(uri.path) })
  |> fn(path) {
    case path {
      Ok([]) -> model.NotAuthenticated(model.Posts)
      Ok(["login"]) -> model.NotAuthenticated(model.Login)
      Ok(["signup"]) -> model.NotAuthenticated(model.Signup)
      Ok(["create"]) -> model.NotAuthenticated(model.Create)
      Ok(["dashboard", user_id]) -> {
        let user_id = int.parse(user_id)
        case user_id {
          Error(_) -> model.Authenticated(model.Dashboard)
          Ok(id) -> model.Authenticated(model.Dashboard)
        }
      }
      Ok(["logout"]) -> model.NotAuthenticated(model.Posts)
      _ -> model.Authenticated(model.Dashboard)
    }
  }
}

fn ensure_data(model: model.Model) {
  let model.Model(user:, ..) = model
  let #(user, user_fx) = case user {
    async_data.NotAsked -> #(
      async_data.Loading,
      api.get_me(message.ApiReturnedUser),
    )

    async_data.Loading -> #(user, effect.none())
    async_data.Done(_) -> #(user, effect.none())
  }
  #(Model(..model, user: user), effect.batch([user_fx]))
}

fn on_url_change(uri: uri.Uri) -> message.Msg {
  case uri.path_segments(uri.path) {
    [] -> model.NotAuthenticated(model.Posts) |> message.OnRouteChange
    ["create"] -> model.NotAuthenticated(model.Create) |> message.OnRouteChange
    ["login"] -> model.NotAuthenticated(model.Login) |> message.OnRouteChange
    ["signup"] -> model.NotAuthenticated(model.Signup) |> message.OnRouteChange
    [_, ..] -> model.NotAuthenticated(model.Posts) |> message.OnRouteChange
  }
}

fn update(model: Model, msg: message.Msg) -> #(Model, Effect(message.Msg)) {
  case echo msg {
    message.OnRouteChange(route) -> {
      echo "function running"
      // let #(guarded_route, auth_fx) = guard_route(route, model.user)
      let model = Model(..model, route: route)
      echo "function running 2"
      let #(model, load_fx) = ensure_data(Model(..model, route:))

      let fx = effect.batch([load_fx])

      echo #(model, fx)
    }
    message.Navigate(to) -> {
      window.set_location(window.self(), to)

      #(model, effect.none())
    }
    message.ApiReturnedUser(user_result) -> {
      let user = async_data.Done(user_result)
      let model = Model(..model, user: user)

      // now that we know user, we may need to load workspaces/projects/memories
      let #(model, load_fx) = ensure_data(model)

      case user_result, model.route {
        // Logged in but currently on login screen -> go to dashboard
        Ok(_), model.NotAuthenticated(model.Posts) -> {
          let route = model.Authenticated(model.Dashboard)
          let model = Model(..model, route: route)

          let #(model, more_fx) = ensure_data(model)

          let fx =
            effect.batch([
              modem.push("/dashboard", option.None, option.None),
              load_fx,
              more_fx,
            ])

          #(model, fx)
        }

        // 401 while on secure screen -> kick to login
        Error(rsvp.HttpError(response.Response(401, ..))),
          model.Authenticated(_)
        -> {
          let route = model.NotAuthenticated(model.Posts)
          let model = Model(..model, route: route)

          let #(model, more_fx) = ensure_data(model)

          let fx =
            effect.batch([
              modem.push("/login", option.None, option.None),
              load_fx,
              more_fx,
            ])

          #(model, fx)
        }

        // Any other combination -> just store the user + any needed loads
        _, _ -> #(model, load_fx)
      }
    }
    message.UserSubmittedCreatePost -> {
      let post_title = model.create_post_ui.post_title |> string.trim()
      let post_content = model.create_post_ui.post_content |> string.trim()

      case post_title == "" {
        True -> #(model, effect.none())
        False -> {
          let model_fx = {
            use posts <- async_data.map(model.posts)

            let post =
              api.Post(
                id: 0,
                title: post_title,
                content: post_content,
                created_at: todo,
              )

            let fx =
              api.post_create_post(
                fn(returned) {
                  returned
                  |> result.try(fn(items) {
                    list.first(items)
                    |> result.map_error(fn(_) {
                      rsvp.HttpError(response.Response(404, [], ""))
                    })
                  })
                  |> message.ApiCreatedPost
                },
                id: post.id,
                title: post.title,
                content: post.content,
              )

            let create_post_ui =
              model.CreatePostUi(
                ..model.create_post_ui,
                is_creating: async_data.Loading,
              )

            #(
              Model(
                ..model,
                posts: posts
                  |> list.append([post])
                  |> Ok
                  |> async_data.Done,
                create_post_ui:,
              ),
              fx,
            )
          }

          model_fx |> async_data.unwrap(#(model, effect.none()))
        }
      }
    }
    message.ApiCreatedPost(Ok(new_post)) -> {
      let posts = case model.posts {
        async_data.Done(Ok(existing_posts)) ->
          async_data.Done(Ok(
            existing_posts
            |> list.map(fn(post) {
              case post.id == 0 {
                True -> new_post
                False -> post
              }
            }),
          ))
        async_data.NotAsked | async_data.Loading ->
          async_data.Done(Ok([new_post]))
        async_data.Done(Error(e)) -> async_data.Done(Error(e))
      }

      let create_post_ui = model.initial_create_post_ui()

      #(
        Model(..model, posts:, create_post_ui:),
        effect.batch([
          api.get_posts(message.ApiReturnedPosts),
        ]),
      )
    }

    message.ApiCreatedPost(Error(error)) -> {
      echo error

      let posts = {
        use posts <- async_data.map(model.posts)
        posts
        |> list.filter(fn(post) { post.id != 0 })
      }

      #(Model(..model, posts:), effect.none())
    }
    message.ApiReturnedPosts(posts) ->
      Model(..model, posts: posts |> async_data.Done) |> ensure_data()
    message.UserSubmittedSignup -> todo
    message.None -> #(model, effect.none())
  }
}

fn view(model: Model) {
  html.div(
    [class("flex flex-col min-h-screen bg-[#202020] text-white text-2xl")],
    [
      view_header(),
      case model.route {
        model.Authenticated(model.Dashboard) -> posts.view()
        model.NotAuthenticated(model.Posts) -> posts.view()
        model.NotAuthenticated(model.Create) -> create.view()
        model.NotAuthenticated(model.Login) -> login.view()
        model.NotAuthenticated(model.Signup) -> signup.view()
      },
    ],
  )
}

fn view_header() {
  html.header(
    [class("fixed top-0 left-0 w-screen bg-[#202020] p-5 flex justify-between")],
    [
      html.a([attribute.href("/")], [
        html.div([class("flex")], [
          html.img([attribute.src("/logo.png")]),
          html.div([class("tracking-[0.25rem] ml-2 cursor-pointer")], [
            html.text("CAPYFORUM"),
          ]),
        ]),
      ]),

      html.div([class("flex")], [
        html.a(
          [
            class(
              "px-2 hover:text-[#8778D7] transition-all ease-in-out duration-300 cursor-pointer",
            ),
            attribute.href("/create"),
          ],
          [html.text("+ Create")],
        ),
        html.a(
          [
            class(
              "px-2 hover:text-[#8778D7] transition-all ease-in-out duration-300 cursor-pointer",
            ),
            attribute.href("/login"),
          ],
          [html.text("Login")],
        ),
        html.a(
          [
            class(
              "px-2 hover:text-[#8778D7] transition-all ease-in-out duration-300 cursor-pointer",
            ),
            attribute.href("/signup"),
          ],
          [html.text("Signup")],
        ),
      ]),
    ],
  )
}

fn guard_route(
  route: model.Route,
  async_data: async_data.AsyncData(api.User, rsvp.Error),
) -> #(model.Route, Effect(message.Msg)) {
  todo
}
