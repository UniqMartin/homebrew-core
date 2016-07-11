class Elementary < Formula
  desc "Widgets and abstractions from the Enlightenment window manager"
  homepage "https://www.enlightenment.org"
  url "https://download.enlightenment.org/rel/libs/elementary/elementary-1.17.1.tar.gz"
  sha256 "1ea60e4fdc823588096b449b3cfc6eff2fea86114ad5bd7f7990ace14c119aac"

  bottle do
    sha256 "2cc0ee68850d60c93d6210064142e6d20a575a4bca57e51976bbf0f0df987c2a" => :el_capitan
    sha256 "ea7a9a2b8b2802500298f56f7537e896056949a86f9083bf50ea0f2adbd41d95" => :yosemite
    sha256 "c4a030c6c4f72f1f46ddc4d7ee5c359cfaae92917f591615a0096d1cd67bf009" => :mavericks
    sha256 "858edeafe89d5a790c0b84169d0a1937741603443e2cd7dafa1554ac7d1bd80e" => :mountain_lion
  end

  depends_on "pkg-config" => :build
  depends_on "efl"

  def install
    system "./configure", "--disable-debug",
                          "--disable-dependency-tracking",
                          "--disable-silent-rules",
                          "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    system "#{bin}/elementary_codegen", "-V"
  end
end
