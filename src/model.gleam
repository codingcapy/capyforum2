import api
import lib/async_data
import rsvp

pub type Model {
  Model(
    route: Route,
    user: async_data.AsyncData(api.User, rsvp.Error),
    posts: async_data.AsyncData(List(api.Post), rsvp.Error),
    create_post_ui: CreatePostUi,
  )
}

pub type Route {
  Authenticated(SecureRoute)
  NotAuthenticated(PublicRoute)
}

pub type PublicRoute {
  Posts
  Create
  Login
  Signup
}

pub type SecureRoute {
  Dashboard
}

pub type CreatePostUi {
  CreatePostUi(
    post_title: String,
    post_content: String,
    is_creating: async_data.AsyncData(Nil, rsvp.Error),
  )
}

pub fn initial_create_post_ui() -> CreatePostUi {
  CreatePostUi(
    post_title: "",
    post_content: "",
    is_creating: async_data.NotAsked,
  )
}
