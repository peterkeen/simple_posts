require "simple_posts/engine"

module SimplePosts

  class << self
    attr_accessor :site_title,
      :site_author,
      :site_url,
      :feed_link,
      :feed_id_url
 
    def self.reset!
      self.site_title = 'Exampleville'
      self.site_author = 'Example Author'
      self.feed_link = lambda { |post| SimplePosts::Engine.routes.url_helpers.post_path(id: post.name) }
    end
  end
end
