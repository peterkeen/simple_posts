Rails.application.routes.draw do
  default_url_options host: 'dummy.example.com'
  mount SimplePosts::Engine => "/blog", as: 'simple_posts'
end
