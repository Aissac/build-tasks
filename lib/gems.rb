require File.dirname(__FILE__) + '/helpers'
require File.dirname(__FILE__) + '/git_helpers'
require 'fileutils'

class Gems
  class << self
    def each(&block)
      gems.each { |name, config| yield Gem.new(name, config).to_args }
    end
    
    def update!
      {}.tap do |gem_versions|
        gems.each do |name, config|
          url = config['git']
          version = TempGemRepo.new(name, url).version
          
          gem_versions[name] = {
            'git'     => url,
            'version' => version,
            'tag'     => "v#{version}"
          }
        end
        
        File.open(yaml_path, 'w') do |f|
          f.write YAML.dump(gem_versions)
        end
      end
      
    end
    
    def install!(dir)
      # system "cd '#{dir}' && bundle install"
      # raise "Failed to install bundle." if $?.exitstatus > 0
      require 'bundler/cli'
      Bundler::CLI.new.send(:update)
    end
    
    private
      def gems
        YAML.load(File.read(yaml_path))
      end
      
      def yaml_path
        File.expand_path File.dirname(__FILE__) + '/../../GEMS.yml'
      end
  end
  
  class TempGemRepo
    include Helpers
    include GitHelpers
    
    TMP_PATH = "tmp/gem_repos"
    
    def initialize(name, url)
      @name = name
      @url = url
    end
    
    def git
      @git ||= begin
        begin
          Git.open(repo_path)
        rescue ArgumentError
          FileUtils.mkdir_p repo_root
          Git.clone(@url, @name, :path => repo_root)
        end
      end
    end
    
    def refresh
      git.fetch
      git.checkout('master')
      git.pull
    end
    
    def version
      refresh
      read_version
    end
    
    def read_version
      yaml = YAML.load(File.read("#{repo_path}/VERSION.yml"))
      [yaml[:major], yaml[:minor], yaml[:patch], yaml[:build]].compact.join('.')
    end
    
    private
      def repo_root
        "#{root}/#{TMP_PATH}"
      end
      
      def repo_path
        "#{repo_root}/#{@name}"
      end
      
      def root
        File.expand_path File.dirname(__FILE__) + "/../../"
      end
  end
  
  class Gem
    def initialize(name, config)
      @name = name
      @config = config
    end
    
    def to_args
      [@name, version, options]
    end
    
    def version
      @config['version']
    end
    
    def options
      {
        :git => @config['git'],
        :tag => @config['tag'],
        :ref => @config['ref']
      }
    end
  end
end
