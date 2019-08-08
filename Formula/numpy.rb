class Numpy < Formula
  desc "Package for scientific computing with Python"
  homepage "https://www.numpy.org/"
  url "https://files.pythonhosted.org/packages/da/32/1b8f2bb5fb50e4db68543eb85ce37b9fa6660cd05b58bddfafafa7ed62da/numpy-1.17.0.zip"
  sha256 "951fefe2fb73f84c620bec4e001e80a80ddaa1b84dce244ded7f1e0cbe0ed34a"
  head "https://github.com/numpy/numpy.git"

  bottle do
    cellar :any
    sha256 "9f2a8c3995cf8006fead37307be70846d54fe0df3c6a45ee7362ca59c8976076" => :mojave
    sha256 "3467b05ecef335d207da6962c9ab590cc1a15fa15dcac0153814aed96e1130d0" => :high_sierra
    sha256 "c360813a390241fad7104d8f0f848739c0752def0e147df4c48411df24a9ba80" => :sierra
  end

  depends_on "gcc" => :build # for gfortran
  depends_on "openblas"
  depends_on "python"

  resource "Cython" do
    url "https://files.pythonhosted.org/packages/a5/1f/c7c5450c60a90ce058b47ecf60bb5be2bfe46f952ed1d3b95d1d677588be/Cython-0.29.13.tar.gz"
    sha256 "c29d069a4a30f472482343c866f7486731ad638ef9af92bfe5fca9c7323d638e"
  end

  resource "pytest" do
    url "https://files.pythonhosted.org/packages/60/23/de5604e58f4eba7a90f70486c8d4ece25f1a404bae29683903ffd2aea425/pytest-5.0.1.tar.gz"
    sha256 "6ef6d06de77ce2961156013e9dff62f1b2688aa04d0dc244299fe7d67e09370d"
  end

  def install
    openblas = Formula["openblas"].opt_prefix
    ENV["ATLAS"] = "None" # avoid linking against Accelerate.framework
    ENV["BLAS"] = ENV["LAPACK"] = "#{openblas}/lib/libopenblas.dylib"

    config = <<~EOS
      [openblas]
      libraries = openblas
      library_dirs = #{openblas}/lib
      include_dirs = #{openblas}/include
    EOS

    Pathname("site.cfg").write config

    python = "python3"

    version = Language::Python.major_minor_version python
    dest_path = lib/"python#{version}/site-packages"
    dest_path.mkpath

    pytest_path = libexec/"pytest/lib/python#{version}/site-packages"
    resource("pytest").stage do
      system python, *Language::Python.setup_install_args(libexec/"pytest")
      (dest_path/"homebrew-numpy-pytest.pth").write "#{pytest_path}\n"
    end

    ENV.prepend_create_path "PYTHONPATH", buildpath/"tools/lib/python#{version}/site-packages"
    resource("Cython").stage do
      system python, *Language::Python.setup_install_args(buildpath/"tools")
    end

    system python, "setup.py",
      "build", "--fcompiler=gnu95", "--parallel=#{ENV.make_jobs}",
      "install", "--prefix=#{prefix}",
      "--single-version-externally-managed", "--record=installed.txt"
  end

  test do
    system "python3", "-c", <<~EOS
      import numpy as np
      t = np.ones((3,3), int)
      assert t.sum() == 9
      assert (t @ t).sum() == 27
    EOS
  end
end
