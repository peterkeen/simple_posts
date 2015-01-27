require "simple_posts/engine"
require 'simple_posts/posts'

module SimplePosts
  class << self
    attr_accessor :site_title,
      :site_author,
      :layout
 
    def reset!
      self.site_title = 'Exampleville'
      self.site_author = 'Example Author'
      self.layout = 'application'
    end

    def configure(&block)
      raise ArgumentError, "must provide a block" unless block_given?
      block.arity.zero? ? instance_eval(&block) : yield(self)
    end
  end

  self.reset!
end
