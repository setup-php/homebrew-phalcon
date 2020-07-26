require File.join(File.dirname(__FILE__), "abstract-php-version")

class String
  def undent
    gsub(/^.{#{(slice(/^ +/) || '').length}}/, "")
  end
end

class AbstractPhpExtension < Formula
  desc "Abstract class for PHP Extension Formula"
  homepage "https://github.com/shivammathur/homebrew-phalcon"

  PHP_REGEX = /[P,p][H,h][P,p]@*([5,7,8])\.([0-9]+)/.freeze

  def self.init
    depends_on "autoconf" => :build
  end

  def php_version
    class_name = self.class::PHP_FORMULA
    matches = PHP_REGEX.match(class_name)
    matches[1] + "." + matches[2] if matches
  end

  def php_formula
    "php@" + php_version
  end

  def safe_phpize
    ENV["PHP_AUTOCONF"] = "#{Formula["autoconf"].opt_bin}/autoconf"
    ENV["PHP_AUTOHEADER"] = "#{Formula["autoconf"].opt_bin}/autoheader"
    system "#{Formula[php_formula].opt_bin}/phpize"
  end

  def phpconfig
    "--with-php-config=#{Formula[php_formula].opt_bin}/php-config"
  end

  def extension
    class_name = self.class.name.split("::").last.split("AT").first
    if class_name
      class_name.downcase
    else
      raise "Unable to guess PHP extension name for #{class_name}"
    end
  end

  def extension_type
    "extension"
  end

  def module_path
    opt_prefix / "#{extension}.so"
  end

  def config_file
    <<-EOS.undent
      [#{extension}]
      #{extension_type}="#{module_path}"
    EOS
  rescue error
    raise error
  end

  def caveats
    <<~EOS
      To finish installing #{extension} for PHP #{php_version}:
        * #{config_filepath} was created,"
          do not forget to remove it upon extension removal."
        * Validate installation by running php -m
    EOS
  end

  test do
    output = shell_output("#{Formula[php_formula].opt_bin}/php -m").downcase
    assert_match /#{extension.downcase}/, output, "failed to find extension in php -m output"
  end

  def config_scandir_path
    etc / "php" / php_version / "conf.d"
  end

  def config_filepath
    config_scandir_path / "#{extension}.ini"
  end

  def write_config_file
    if config_filepath.file?
      inreplace config_filepath do |s|
        s.gsub!(/^(;)?(\s*)(zend_)?extension=.+$/, "\\1\\2#{extension_type}=\"#{module_path}\"")
      end
    elsif config_file
      config_scandir_path.mkpath
      config_filepath.write(config_file)
    end
  end
end

class AbstractPhp56Extension < AbstractPhpExtension
  include AbstractPhpVersion::Php56Defs

  def self.init
    super()
    depends_on AbstractPhpVersion::Php56Defs::PHP_FORMULA => [:build, :test]
  end
end

class AbstractPhp70Extension < AbstractPhpExtension
  include AbstractPhpVersion::Php70Defs

  def self.init
    super()
    depends_on AbstractPhpVersion::Php70Defs::PHP_FORMULA => [:build, :test]
  end
end

class AbstractPhp71Extension < AbstractPhpExtension
  include AbstractPhpVersion::Php71Defs

  def self.init
    super()
    depends_on AbstractPhpVersion::Php71Defs::PHP_FORMULA => [:build, :test]
  end
end

class AbstractPhp72Extension < AbstractPhpExtension
  include AbstractPhpVersion::Php72Defs

  def self.init
    super()
    depends_on AbstractPhpVersion::Php72Defs::PHP_FORMULA => [:build, :test]
  end
end

class AbstractPhp73Extension < AbstractPhpExtension
  include AbstractPhpVersion::Php73Defs

  def self.init
    super()
    depends_on AbstractPhpVersion::Php73Defs::PHP_FORMULA => [:build, :test]
  end
end

class AbstractPhp74Extension < AbstractPhpExtension
  include AbstractPhpVersion::Php74Defs

  def self.init
    super()
    depends_on AbstractPhpVersion::Php74Defs::PHP_FORMULA => [:build, :test]
  end
end

class AbstractPhp80Extension < AbstractPhpExtension
  include AbstractPhpVersion::Php80Defs

  def self.init
    super()
    depends_on AbstractPhpVersion::Php80Defs::PHP_FORMULA => [:build, :test]
  end
end
