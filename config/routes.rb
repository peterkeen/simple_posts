SimplePosts::Engine.routes.draw do
  get '/'          => 'posts#index', as: :posts
  get '/index.xml' => 'posts#atom',  as: :atom
  get '/:id'       => 'posts#show',  as: :post

  default_url_options Rails.application.routes.default_url_options
end
