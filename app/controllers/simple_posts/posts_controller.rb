require 'rss'

module SimplePosts
  class PostsController < ::ApplicationController
    before_filter :load_posts

    def index
      @blog_posts = @posts.blog_posts.reverse
      render layout: SimplePosts.layout
    end

    def show
      @post = @posts.find(params[:id])
      raise ActionController::RoutingError.new('Not Found') unless @post

      if request.path != post_path(id: @post.name)
        redirect_to post_url(id: @post.name)
        return
      end

      render layout: SimplePosts.layout
    end

    def atom
      posts = @posts.blog_posts.reverse

      feed = RSS::Maker.make("atom") do |f|
        f.channel.title = SimplePosts.site_title
        f.channel.author = SimplePosts.site_author
        f.channel.about = SimplePosts::Engine.routes.url_helpers.posts_url
        f.channel.updated = posts[0].date.to_time

        posts.each do |post|
          f.items.new_item do |e|
            e.title = post.title
            e.link = SimplePosts::Engine.routes.url_helpers.post_url(id: post.name)
            e.id = SimplePosts::Engine.routes.url_helpers.post_url(id: post.id)
            e.updated = post.date.to_time
            e.pubDate = post.date.to_time
            e.content.content = post.render
          end
        end
      end

      render text: feed, content_type: 'application/atom+xml'
    end

    private

    def load_posts
      @posts = Posts.new
    end
  end
end
