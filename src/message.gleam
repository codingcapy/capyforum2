import api
import model
import rsvp

pub type Msg {
  OnRouteChange(model.Route)
  ApiReturnedUser(Result(api.User, rsvp.Error))
  Navigate(route: String)
  UserSubmittedCreatePost
  ApiCreatedPost(Result(api.Post, rsvp.Error))
  ApiReturnedPosts(Result(List(api.Post), rsvp.Error))
  UserSubmittedSignup
  None
}
