class Ponyc < Formula
  desc "Object-oriented, actor-model, capabilities-secure programming language"
  homepage "http://www.ponylang.org"
  url "https://github.com/ponylang/ponyc.git",
    :revision => "5f061fa201b47dc6a767d3bbe8a8999ada66993e"
  # 0.2.2 tag requested in https://github.com/ponylang/ponyc/issues/1029
  version "0.2.2-alpha2"
  revision 1

  bottle do
    cellar :any
    sha256 "59a03fc7a83f5c97262e9a70f383b3105f6d03062aac9ceac4729a6e3a19e7d3" => :el_capitan
    sha256 "c3527fecac254cd94a2f6d42f9418fbd80ca9bf41f46a4d807141516e9f849f9" => :yosemite
    sha256 "38b605078fd9cbc5010995b41327c9161d4b309b0c1696890abf572543f36a63" => :mavericks
  end

  patch :DATA

  depends_on "llvm"
  depends_on "libressl"
  depends_on "pcre2"
  needs :cxx11

  def install
    ENV.cxx11
    ENV["LLVM_CONFIG"]="#{Formula["llvm"].opt_bin}/llvm-config"

    inreplace "packages/regex/regex.pony",
              /^(use "lib:pcre2-8")\n/,
              "use \"path:#{Formula["pcre2"].opt_lib}\" if osx\n\\1\n"

    inreplace "packages/net/ssl/sslinit.pony",
              %r{^use "path:/usr/local/opt/libressl/lib" if osx\n},
              "use \"path:#{Formula["libressl"].opt_lib}\" if osx\n"

    args = %W[
      config=release
      destdir=#{prefix}
      osx_version_min=#{MacOS.version}
      verbose=1
    ]

    system "make", "install", *args
    system "make", "test", *args
  end

  test do
    system "#{bin}/ponyc", "-rexpr", "#{prefix}/packages/stdlib"

    (testpath/"test/main.pony").write <<-EOS.undent
    actor Main
      new create(env: Env) =>
        env.out.print("Hello World!")
    EOS
    system "#{bin}/ponyc", "test"
    assert_equal "Hello World!", shell_output("./test1").strip
  end
end

__END__
diff --git i/Makefile w/Makefile
index bb6254c9..bac02803 100644
--- i/Makefile
+++ w/Makefile
@@ -90,6 +90,15 @@ ifdef config
   endif
 endif

+ifeq ($(OSTYPE),osx)
+  osx_version_min ?= 10.8
+  ALL_CFLAGS += -DPONY_OSX_VERSION_MIN=\"$(osx_version_min)\"
+
+  ifneq ($(destdir),/usr/local)
+    ALL_CFLAGS += -DPONY_LIBRARY_PATH=\"$(destdir)/lib\"
+  endif
+endif
+
 ifeq ($(config),release)
   BUILD_FLAGS += -O3 -DNDEBUG

@@ -110,8 +119,8 @@ else
 endif

 ifeq ($(OSTYPE),osx)
-  ALL_CFLAGS += -mmacosx-version-min=10.8
-  ALL_CXXFLAGS += -stdlib=libc++ -mmacosx-version-min=10.8
+  ALL_CFLAGS += -mmacosx-version-min=$(osx_version_min)
+  ALL_CXXFLAGS += -stdlib=libc++ -mmacosx-version-min=$(osx_version_min)
 endif

 ifndef LLVM_CONFIG
diff --git i/src/libponyc/codegen/genexe.c w/src/libponyc/codegen/genexe.c
index 3f22058e..a08f2391 100644
--- i/src/libponyc/codegen/genexe.c
+++ w/src/libponyc/codegen/genexe.c
@@ -286,6 +286,10 @@ static bool link_exe(compile_t* c, ast_t* program,
   const char* file_exe = suffix_filename(c->opt->output, "", c->filename, "");
   printf("Linking %s\n", file_exe);

+#if defined(PONY_LIBRARY_PATH)
+  use_path(program, PONY_LIBRARY_PATH, NULL, NULL);
+#endif
+
   program_lib_build_args(program, "-L", "", "", "-l", "");
   const char* lib_args = program_lib_args(program);

@@ -295,7 +299,8 @@ static bool link_exe(compile_t* c, ast_t* program,
   char* ld_cmd = (char*)pool_alloc_size(ld_len);

   snprintf(ld_cmd, ld_len,
-    "ld -execute -no_pie -dead_strip -arch %.*s -macosx_version_min 10.8 "
+    "ld -execute -no_pie -dead_strip -arch %.*s "
+    "-macosx_version_min " PONY_OSX_VERSION_MIN " "
     "-o %s %s %s -lponyrt -lSystem",
     (int)arch_len, c->opt->triple, file_exe, file_o, lib_args
     );
