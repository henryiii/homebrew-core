# Reference: https://github.com/macvim-dev/macvim/wiki/building
class Macvim < Formula
  desc "GUI for vim, made for macOS"
  homepage "https://github.com/macvim-dev/macvim"
  version "8.1-157"
  head "https://github.com/macvim-dev/macvim.git"

  # Issue #44995, needed for XCode 11, drop after snapshot-157
  stable do
    url "https://github.com/macvim-dev/macvim/archive/snapshot-157.tar.gz"
    sha256 "6447bce4ec7b7f67327da8f7b2e9d4f4b748c1afb90f781fecb6b4a3f54cf0a0"
    patch do
      url "https://github.com/macvim-dev/macvim/pull/946.patch?full_index=1"
      sha256 "662548205298fa918606009e3e99151d760f2f042ef2a59215845b14cdb4e85d"
    end
  end

  bottle do
    cellar :any
    sha256 "5ce9df18a54e2aeb9101366da65b850c1d07a123c887a782658a9a55668e4219" => :mojave
    sha256 "3d337903a891f23a97dd13a488085113e325c25606ece59da9dafa897f353946" => :high_sierra
    sha256 "7c190d79f4cf1226fe4e0c9b11a90feab83cc9546b83cd18b5cba05d1ce6f322" => :sierra
  end

  depends_on :xcode => :build
  depends_on "cscope"
  depends_on "lua"
  depends_on "python"

  conflicts_with "vim",
    :because => "vim and macvim both install vi* binaries"

  def install
    # Avoid issues finding Ruby headers
    if MacOS.version == :sierra || MacOS.version == :yosemite
      ENV.delete("SDKROOT")
    end

    # MacVim doesn't have or require any Python package, so unset PYTHONPATH
    ENV.delete("PYTHONPATH")

    # make sure that CC is set to "clang"
    ENV.clang

    system "./configure", "--with-features=huge",
                          "--enable-multibyte",
                          "--with-macarchs=#{MacOS.preferred_arch}",
                          "--enable-perlinterp",
                          "--enable-rubyinterp",
                          "--enable-tclinterp",
                          "--enable-terminal",
                          "--with-tlib=ncurses",
                          "--with-compiledby=Homebrew",
                          "--with-local-dir=#{HOMEBREW_PREFIX}",
                          "--enable-cscope",
                          "--enable-luainterp",
                          "--with-lua-prefix=#{Formula["lua"].opt_prefix}",
                          "--enable-luainterp",
                          "--enable-python3interp"
    system "make"

    prefix.install "src/MacVim/build/Release/MacVim.app"
    bin.install_symlink prefix/"MacVim.app/Contents/bin/mvim"

    # Create MacVim vimdiff, view, ex equivalents
    executables = %w[mvimdiff mview mvimex gvim gvimdiff gview gvimex]
    executables += %w[vi vim vimdiff view vimex]
    executables.each { |e| bin.install_symlink "mvim" => e }
  end

  test do
    output = shell_output("#{bin}/mvim --version")
    assert_match "+ruby", output

    # Simple test to check if MacVim was linked to Homebrew's Python 3
    py3_exec_prefix = Utils.popen_read("python3-config", "--exec-prefix")
    assert_match py3_exec_prefix.chomp, output
    (testpath/"commands.vim").write <<~EOS
      :python3 import vim; vim.current.buffer[0] = 'hello python3'
      :wq
    EOS
    system bin/"mvim", "-v", "-T", "dumb", "-s", "commands.vim", "test.txt"
    assert_equal "hello python3", (testpath/"test.txt").read.chomp
  end
end
