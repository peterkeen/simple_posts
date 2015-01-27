Encoding.default_internal, Encoding.default_external = ['utf-8'] * 2

require 'redcarpet'
require 'date'
require 'redcarpet'
require 'rouge'
require 'rouge/plugins/redcarpet'

class HTMLwithHighlights < Redcarpet::Render::HTML
  include Rouge::Plugins::Redcarpet

  def postprocess(document)
    document.gsub('&#39;', "'")
  end
end

class Posts
  attr_reader :posts, :non_blog_posts, :renderer
  
  def initialize
    @posts_by_post_name = {}
    @posts_by_post_id = {}
    @posts_by_tag = {}
    @posts_by_topic = {}
    @blog_posts = []
    @non_blog_posts = []

    setup_renderer
    parse_all
  end

  def setup_renderer
    @renderer = Redcarpet::Markdown.new(
      HTMLwithHighlights, :fenced_code_blocks => true)
  end

  def parse_all
    @posts = find_all_files.map do |post|
      next if File.basename(post).start_with?('_')
      Post.new(post, @renderer)
    end.compact

    @posts.each do |post|
      @posts_by_post_name[post.name] = post
      @posts_by_post_id[post.post_id] = post
      if post.topic
        topic = post.topic.downcase
        @posts_by_topic[topic] ||= []
        @posts_by_topic[topic] << post
      end

      post.alternate_links.each do |link|
        @posts_by_post_id[link] = post
      end

      post.tags.each do |tag|
        @posts_by_tag[tag.downcase] ||= []
        @posts_by_tag[tag.downcase] << post
      end

      if post.is_blog_post?
        @blog_posts << post
      else
        @non_blog_posts << post
      end
    end
  end

  def find(thing)
    @posts_by_post_id[thing] || @posts_by_post_name[thing]
  end

  def tagged(tag)
    (@posts_by_tag[tag.downcase] || [])
  end

  def find_all_files
    basepath = Rails.root.join('app', 'posts').to_s
    Dir.glob(File.join(basepath, "**/*")).map do |fullpath|
      next if File.directory?(fullpath)
      fullpath.gsub(basepath + "/", '')
    end.compact
  end

  def each
    @posts.each do |post|
      yield post
    end
  end

  def topics
    @posts_by_topic.keys.sort
  end

  def for_topic(topic)
    @posts_by_topic[topic].sort { |a,b| b.date <=> a.date }
  end

  def tag_frequencies
    tags = Hash.new(0)
    @posts.each do |post|
      post.tags.each do |tag|
        tags[tag] += 1
      end
    end
    tags
  end

  def related_posts(target)
    freqs = tag_frequencies
    
    highest_freq = freqs.values.max
    related_scores = Hash.new(0)

    blog_posts.each do |post|
      post.tags.each do |tag|
        if target.tags.include?(tag) && target != post
          tag_freq = freqs[tag]
          related_scores[post] += (1 + highest_freq - tag_freq)
        end
      end
    end

    related_scores.sort do |a,b|
     if a[1] < b[1]
          1
        elsif a[1] > b[1]
          -1
        else
          b[0].date <=> a[0].date
        end
    end.select{|post,freq| freq > 1}.collect {|post,freq| post}
  end

  def blog_posts
    @blog_posts.sort { |a, b| a.date <=> b.date }
  end
end

class Post

  DATE_REGEX = /\d{4}-\d{2}-\d{2}/
  SHORT_DATE_FORMAT = "%Y-%m-%d"
  DATE_FORMAT = "%Y-%m-%d %H:%M:%S"

  attr_accessor :docid
  attr_reader :name, :body, :original_filename, :original_body, :headers

  def initialize(filename, renderer)
    @file = filename
    @original_filename = filename
    @name = self.class.normalize_name(filename)
    @renderer = renderer
    parse_post
  end

  def parse_post
    if contents =~ /\A(---\s*\n.*?\n?)^(---\s*$\n?)(.*)/m
      @headers = YAML.load($1)
      parse_body($3)
    end
  end

  def parse_body(body_text)
    @original_body = body_text
    @before_fold, after_fold = body_text.split("--fold--")
    @body = body_text.sub("--fold--", '')
  end

  def self.normalize_name(post)
    return post.downcase.strip.sub(/\.(html|md|pdf)(\.erb)?$/,'').sub(/\d{4}-\d{2}-\d{2}-/, '')
  end

  def is_blog_post?
    return filename =~ DATE_REGEX
  end

  def render(renderer=nil, app=nil)
    content = is_erb? ? render_erb(@body, app) : @body
    if is_html?
      content
    else
      (renderer || @renderer).render(content)
    end
  end

  def render_erb(content, app)
    template = ERB.new(content)
    @app = app
    template.result(binding)
  end

  def is_erb?
    original_filename.end_with?('.erb')
  end

  def is_html?
    original_filename =~ /\.html(\.erb)?$/
  end

  def id_matches?(id)
    links = alternate_links + [self.post_id]
    links.include? id
  end

  def render_before_fold
    @renderer.render(@before_fold)
  end

  def contents
    @contents ||= File.open(filename, 'r:utf-8') do |file|
      file.read
    end
  end

  def filename
    Rails.root.join("app", "posts", @file).to_s
  end

  def matches_path(path)
    normalized = self.class.normalize_name(path)
    return @name == normalized || @headers['id'] == normalized
  end

  def [](key)
    return @headers[key]
  end

  def tags
    if @headers.has_key?('tags')
      return @headers['tags'].split(/,\s+/)
    else
      return []
    end
  end

  def alternate_links
    if @headers.has_key?('alternate_links')
      return @headers['alternate_links'].split(/\s+/)
    else
      return []
    end
  end

  def has_tag(tag)
    tags.detect { |t| t == tag }
  end

  def title
    @headers['title']
  end

  def post_id
    @headers['id']
  end

  def id
    post_id
  end

  def date
    if is_blog_post?
      if @headers['date']
        Time.strptime(@headers['date'], DATE_FORMAT)
      else
        Time.strptime(@file, SHORT_DATE_FORMAT)
      end
    elsif @headers['date']
      Time.strptime(@headers['date'], SHORT_DATE_FORMAT)
    end
  end

  def reading_time
    ([body.split(/\s+/).length / 180.0, 1].max).to_i
  end

  def natural_date
    date ? date.strftime("%e %B %Y") : ''
  end

  def short_date
    date ? date.strftime("%e %b %Y") : ''
  end

  def topic
    headers['topic']
  end

  def html_path
    "/blog/#{@name}"
  end

  def view
    @headers.has_key?('view') ? @headers['view'].to_sym : nil
  end

  def layout
    @headers.has_key?('layout') ? @headers['layout'].to_sym : nil
  end

  def show_byline?
    is_blog_post?
  end
end
