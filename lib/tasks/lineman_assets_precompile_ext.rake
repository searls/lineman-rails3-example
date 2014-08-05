#shamelessly ripped from rails-lineman@0.3.0
module Rake
  TaskManager.class_eval do
    def __lineman_rails__alias_task(fq_name)
      new_name = "#{fq_name}:original"
      @tasks[new_name] = @tasks.delete(fq_name)
    end
  end
end

module RailsLineman
  module TaskHelpers
    def self.alias_task(fq_name)
      Rake.application.__lineman_rails__alias_task(fq_name)
    end

    def self.override_task(*args, &block)
      name, params, deps = Rake.application.resolve_args(args.dup)
      scope = Rake.application.instance_variable_get(:@scope).dup
      fq_name = if scope.respond_to?(:push)
        scope.push(name).join(':')
      else
        scope.to_a.reverse.push(name).join(':')
      end
      self.alias_task(fq_name)
      Rake::Task.define_task(*args, &block)
    end
  end
end
#/shamelessly

RAILS_MANIFEST_PATH = "public/assets/manifest.yml"
LINEMAN_MANIFEST_PATH = "public/assets/lineman/assets.json"
LINEMAN_PROJECT_PATH = Rails.root.join("lineman-app")

def build_lineman_project
  system <<-BASH
    cd "#{LINEMAN_PROJECT_PATH}"
    npm install
    ./node_modules/.bin/lineman clean build
  BASH
end

def copy_lineman_dist_to_public_assets
  puts "Copying built Lineman project from '#{File.join(LINEMAN_PROJECT_PATH, "dist")}' to '#{Rails.root.join("public/assets/lineman")}'"
  FileUtils.cp_r(File.join(LINEMAN_PROJECT_PATH, "dist"), Rails.root.join("public/assets/lineman"))
end

def add_lineman_entries_to_asset_manifest
  puts "Adding Lineman asset fingerprints to '#{RAILS_MANIFEST_PATH}' from '#{LINEMAN_MANIFEST_PATH}'"
  if [RAILS_MANIFEST_PATH, LINEMAN_MANIFEST_PATH].all? {|p| File.exist?(p)}
    rails_plus_lineman = YAML.load_file(RAILS_MANIFEST_PATH).merge(
      Hash[JSON.parse(File.read(LINEMAN_MANIFEST_PATH)).map do |(k,v)|
        ["lineman/#{k}", "lineman/#{v}"]
      end]
    )
    File.write(RAILS_MANIFEST_PATH, rails_plus_lineman.to_yaml)
  end
end

namespace :assets do
  desc 'Compile all the assets named in config.assets.precompile (Wrapped by rails-lineman)'
  namespace :precompile do
    # In case you need before-advice
    # RailsLineman::TaskHelpers.override_task :all => [] do
    #   # Do stuff before assets precompile
    #   Rake::Task["assets:precompile:all:original"].execute
    # end

    RailsLineman::TaskHelpers.override_task :nondigest => ["assets:environment", "tmp:cache:clear"] do
      Rake::Task["assets:precompile:nondigest:original"].execute
      build_lineman_project
      copy_lineman_dist_to_public_assets
      add_lineman_entries_to_asset_manifest
    end
  end
end
