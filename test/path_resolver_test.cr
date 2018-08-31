require "./test_helper"

module Shards
  class PathResolverTest < Minitest::Test
    def setup
      create_path_repository "library", "1.2.3"
    end

    def test_available_versions
      assert_equal ["1.2.3"], resolver("library").available_versions
    end

    def test_read_spec
      assert_equal "name: library\nversion: 1.2.3\n", resolver("library").read_spec
    end

    def test_install
      resolver("library").tap do |library|
        library.install
        assert File.exists?(install_path("library", "src/library.cr"))
        assert File.exists?(install_path("library", "shard.yml"))
        assert_equal "1.2.3", library.installed_spec.not_nil!.version
      end
    end

    def test_install_fails_when_path_doesnt_exist
      assert_raises(Error) { resolver("unknown").install }
    end

    def test_installed_reports_library_is_installed
      resolver("library").tap do |resolver|
        refute resolver.installed?

        resolver.install
        assert resolver.installed?
      end
    end

    def test_installed_when_target_is_incorrect_link
      resolver("library").tap do |resolver|
        resolver.install
        assert resolver.installed?
      end
    end

    def test_installed_when_target_is_incorrect_broken_link
      resolver("library").tap do |resolver|
        File.symlink("/does-not-exist", resolver.install_path)
        refute resolver.installed?

        resolver.install
        assert resolver.installed?
      end
    end

    def test_installed_when_target_is_dir
      resolver("library").tap do |resolver|
        Dir.mkdir_p(resolver.install_path)
        File.touch(File.join(resolver.install_path, "foo"))
        refute resolver.installed?

        resolver.install
        assert resolver.installed?
      end
    end

    def test_installed_when_target_is_file
      resolver("library").tap do |resolver|
        File.touch(resolver.install_path)
        refute resolver.installed?

        resolver.install
        assert resolver.installed?
      end
    end

    private def resolver(name, config = {} of String => String)
      config["path"] = git_path(name)
      dependency = Dependency.new(name, config)
      PathResolver.new(dependency)
    end
  end
end
