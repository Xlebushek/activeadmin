module ActiveAdmin
  class ApplicationGenerator
    attr_reader :base_dir, :template, :parallel

    def initialize(opts = {})
      @base_dir = opts[:base_dir] || 'spec/rails'
      @template = opts[:template] || 'rails_template'
      @parallel = opts[:parallel]
    end

    def generate
      unless !parallel || parallel_tests_setup?
        puts "parallel_tests is not set up. (Re)building #{app_dir} App. Please wait."
        system("rm -Rf #{app_dir}")
      end

      if File.exist? app_dir
        puts "test app #{app_dir} already exists; skipping"
      else
        system "mkdir -p #{base_dir}"
        args = %W(
          -m spec/support/#{template}.rb
          --skip-bundle
          --skip-gemfile
          --skip-listen
          --skip-turbolinks
          --skip-test-unit
          --skip-coffee
        )

        command = ['bundle', 'exec', 'rails', 'new', app_dir, *args].join(' ')

        env = { 'BUNDLE_GEMFILE' => ENV['BUNDLE_GEMFILE'] }
        env['INSTALL_PARALLEL'] = 'yes' if parallel

        Bundler.with_original_env { Kernel.exec(env, command) }

        rails_app_rake "parallel:load_schema" if parallel
      end
    end

    private

    def rails_app_rake(task)
      system "cd #{app_dir}; rake #{task}"
    end

    def app_dir
      @app_dir ||= begin
                     require 'rails/version'
                     "#{base_dir}/rails-#{Rails::VERSION::STRING}"
                   end
    end

    def parallel_tests_setup?
      database_config = File.join app_dir, "config", "database.yml"
      File.exist?(database_config) && File.read(database_config).include?("TEST_ENV_NUMBER")
    end
  end
end
