require File.expand_path("../Abstract/abstract-php-extension", __dir__)

class PsrAT73 < AbstractPhp73Extension
  init
  desc "PHP extension providing the accepted PSR interfaces "
  homepage "https://github.com/jbboehr/php-psr"
  url "https://github.com/jbboehr/php-psr/archive/v1.0.1.tar.gz"
  sha256 "d76d62835d6ad22153f3b39cfcc040a2fbb0cf2700173112642131c95f55a27c"
  head "https://github.com/jbboehr/php-psr.git"

  bottle do
    root_url "https://dl.bintray.com/shivammathur/phalcon"
    cellar :any_skip_relocation
    sha256 "ee9846c31c5869d8118f12212c89e65ff2319e15c45d8056181679110ff7d384" => :catalina
  end

  depends_on "pcre"

  def install
    safe_phpize
    system "./configure", "--prefix=#{prefix}", phpconfig, "--enable-psr"
    system "make"
    prefix.install "modules/psr.so"
    prefix.install "modules/psr.la"
    write_config_file
  end
end
