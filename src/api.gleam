import gleam/dynamic/decode
import gleam/json
import lustre/effect
import rsvp

pub type User {
  User(
    id: String,
    username: String,
    email: String,
    password: String,
    created_at: String,
    active: Bool,
  )
}

pub type Post {
  Post(id: Int, title: String, content: String, created_at: String)
}

pub fn get_me(msg_wrapper wrapper) {
  let handler = {
    rsvp.expect_json(decode.at(["user"], user_decoder()), wrapper)
  }

  rsvp.get(base_url() <> "/auth/me", handler)
}

fn user_decoder() -> decode.Decoder(User) {
  use id <- decode.field("userId", decode.string)
  use email <- decode.field("email", decode.string)
  use username <- decode.field("username", decode.string)
  use password <- decode.field("password", decode.string)
  use created_at <- decode.field("createdAt", decode.string)
  use active <- decode.field("active", decode.bool)
  decode.success(User(id:, username:, email:, password:, created_at:, active:))
}

fn post_decoder() -> decode.Decoder(Post) {
  use id <- decode.field("id", decode.int)
  use title <- decode.field("title", decode.string)
  use content <- decode.field("content", decode.string)
  use created_at <- decode.field("created_at", decode.string)

  decode.success(Post(id:, title:, content:, created_at:))
}

fn base_url() -> String {
  "/api/v0"
}

pub fn post_create_post(
  msg_wrapper wrapper,
  id id,
  title title,
  content content,
) {
  let handler = {
    rsvp.expect_json(
      decode.at(["newPost"], decode.list(post_decoder())),
      wrapper,
    )
  }

  rsvp.post(
    base_url() <> "/posts",
    json.object([
      #("id", json.int(id)),
      #("title", json.string(title)),
      #("content", json.string(content)),
    ]),
    handler,
  )
}

pub fn get_posts(msg_wrapper wrapper) {
  let handler = {
    rsvp.expect_json(decode.list(post_decoder()), wrapper)
  }

  rsvp.get(base_url() <> "/posts", handler)
}
