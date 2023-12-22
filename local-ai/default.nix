{ stdenv
, lib
, fetchFromGitHub
, ncurses
, abseil-cpp
, protobuf
, grpc
, openssl
, openblas
, cmake
, buildGoModule
, pkg-config
, cudaPackages
, makeWrapper
, runCommand
, buildType ? ""
}:
let
  go-llama = fetchFromGitHub {
    owner = "go-skynet";
    repo = "go-llama.cpp";
    rev = "aeba71ee842819da681ea537e78846dc75949ac0";
    hash = "sha256-ELoaJg7wOHloQws+do6TZUo7zOxUP0E85v80BlpUOJA=";
    fetchSubmodules = true;
  };

  go-llama-ggml = fetchFromGitHub {
    owner = "go-skynet";
    repo = "go-llama.cpp";
    rev = "50cee7712066d9e38306eccadcfbb44ea87df4b7";
    hash = "sha256-5qwUSg56fyHk5x8NgwLrgl+9Ibl2GTBP1Aq5sAvTs+s=";
    fetchSubmodules = true;
  };

  llama_cpp = fetchFromGitHub {
    owner = "ggerganov";
    repo = "llama.cpp";
    rev = "328b83de23b33240e28f4e74900d1d06726f5eb1";
    hash = "sha256-Nc9r5wU8OB6AUcb0By5fWMGyFZL5FUP7Oe/aVkiouWg=";
    fetchSubmodules = true;
  };

  llama_cpp' = runCommand "llama_cpp_src" { } ''
    cp -r --no-preserve=mode,ownership ${llama_cpp} $out
    sed -i $out/CMakeLists.txt \
      -e 's;pkg_check_modules(DepBLAS REQUIRED openblas);pkg_check_modules(DepBLAS REQUIRED openblas64);'
  '';

  llama_cpp_grammar = fetchFromGitHub {
    owner = "mudler";
    repo = "llama.cpp";
    rev = "48ce8722a05a018681634af801fd0fd45b3a87cc";
    hash = "sha256-V2MrTl3AZc0oMV6A0JkLzsEbcPOpLTQKzX84Y1j3mHA=";
    fetchSubmodules = true;
  };

  go-ggml-transformers = fetchFromGitHub {
    owner = "go-skynet";
    repo = "go-ggml-transformers.cpp";
    rev = "ffb09d7dd71e2cbc6c5d7d05357d230eea6f369a";
    hash = "sha256-WdCj6cfs98HvG3jnA6CWsOtACjMkhSmrKw9weHkLQQ4=";
    fetchSubmodules = true;
  };

  gpt4all = fetchFromGitHub {
    owner = "nomic-ai";
    repo = "gpt4all";
    rev = "27a8b020c36b0df8f8b82a252d261cda47cf44b8";
    hash = "sha256-djq1eK6ncvhkO3MNDgasDBUY/7WWcmZt/GJsHAulLdI=";
    fetchSubmodules = true;
  };

  go-piper = fetchFromGitHub {
    owner = "mudler";
    repo = "go-piper";
    rev = "d6b6275ba037dabdba4a8b65dfdf6b2a73a67f07";
    hash = "sha256-p589giBsEPsoR+RQU7qfGfpfqpTdBI51lvnLs4DmE0Y=";
    fetchSubmodules = true;
  };

  go-rwkv = fetchFromGitHub {
    owner = "donomii";
    repo = "go-rwkv.cpp";
    rev = "8f6d062fa80ed4ac4a00d1ac53aa4de54183fffe";
    hash = "sha256-ueSoJ1MHXvBPfCyg63C3bE5oxo5Bkd7k7mle7cntqCE=";
    fetchSubmodules = true;
  };

  whisper = fetchFromGitHub {
    owner = "ggerganov";
    repo = "whisper.cpp";
    rev = "9286d3f584240ba58bd44a1bd1e85141579c78d4";
    hash = "sha256-hLPtfJVYiopnSdDqu9n/k9Avb4ibgbjmrVr81BTWW/w=";
    fetchSubmodules = true;
  };

  go-bert = fetchFromGitHub {
    owner = "go-skynet";
    repo = "go-bert.cpp";
    rev = "6abe312cded14042f6b7c3cd8edf082713334a4d";
    hash = "sha256-lh9cvXc032Eq31kysxFOkRd0zPjsCznRl0tzg9P2ygo=";
    fetchSubmodules = true;
  };

  go-stable-diffusion = fetchFromGitHub {
    owner = "mudler";
    repo = "go-stable-diffusion";
    rev = "902db5f066fd137697e3b69d0fa10d4782bd2c2f";
    hash = "sha256-MbVYeWQF/aJNsg2NpTMVx5tD31BK5pQ8Zg92uoWRkcU=";
    fetchSubmodules = true;
  };

in
buildGoModule rec {
  pname = "local-ai";
  version = "2.2.0";

  src = fetchFromGitHub {
    owner = "go-skynet";
    repo = "LocalAI";
    rev = "v${version}";
    hash = "sha256-u4QMtaWt8SsvgHWr0xvdyHYx07R2kyGLaWeDlXEZcQ4=";
  };

  vendorHash = "sha256-nKeNEaFfPCnPCEW7pvTNjCVawa3aX0M/6skmfZYO0DI=";

  # Workaround for
  # `cc1plus: error: '-Wformat-security' ignored without '-Wformat' [-Werror=format-security]`
  # when building jtreg
  env.NIX_CFLAGS_COMPILE = "-Wformat";

  postPatch =
    let
      cp = "cp -r --no-preserve=mode,ownership";
    in
    ''
      sed -i Makefile \
        -e 's;git clone.*go-llama$;${cp} ${go-llama} sources/go-llama;' \
        -e 's;git clone.*go-llama-ggml$;${cp} ${go-llama-ggml} sources/go-llama-ggml;' \
        -e 's;git clone.*llama\.cpp.*$;${cp} ${llama_cpp_grammar} sources/llama\.cpp;' \
        -e 's;git clone.*go-ggml-transformers$;${cp} ${go-ggml-transformers} sources/go-ggml-transformers;' \
        -e 's;git clone.*gpt4all$;${cp} ${gpt4all} sources/gpt4all;' \
        -e 's;git clone.*go-piper$;${cp} ${go-piper} sources/go-piper;' \
        -e 's;git clone.*go-rwkv$;${cp} ${go-rwkv} sources/go-rwkv;' \
        -e 's;git clone.*whisper\.cpp$;${cp} ${whisper} sources/whisper\.cpp;' \
        -e 's;git clone.*go-bert$;${cp} ${go-bert} sources/go-bert;' \
        -e 's;git clone.*diffusion$;${cp} ${go-stable-diffusion} sources/go-stable-diffusion;' \
        -e 's, && git checkout.*,,g' \
        -e '/mod download/ d' \

      sed -i backend/cpp/llama/Makefile \
        -e 's;git clone.*llama\.cpp$;${cp} ${llama_cpp'} llama\.cpp;' \
        -e 's, && git checkout.*,,g' \

    ''
  ;

  modBuildPhase = ''
    mkdir sources
    make prepare-sources
    go mod tidy -v
  '';

  proxyVendor = true;

  buildPhase = ''
    mkdir sources
    make \
      VERSION=v${version} \
      BUILD_TYPE=${buildType} \
      build
  '';

  installPhase = ''
    install -Dt $out/bin ${pname}
  '';

  buildInputs = [
    abseil-cpp
    protobuf
    grpc
    openssl
  ]
  ++ lib.optional (buildType == "cublas") cudaPackages.cudatoolkit
  ++ lib.optional (buildType == "openblas") openblas.dev
  ;

  # patching rpath with patchelf doens't work. The execuable
  # raises an segmentation fault
  postFixup = lib.optionalString (buildType == "cublas") ''
    wrapProgram $out/bin/${pname} \
      --prefix LD_LIBRARY_PATH : "${cudaPackages.libcublas}/lib:${cudaPackages.cuda_cudart}/lib"
  ''
  + lib.optionalString (buildType == "openblas") ''
    wrapProgram $out/bin/${pname} \
      --prefix LD_LIBRARY_PATH : "${openblas}/lib"
  '';

  nativeBuildInputs = [
    ncurses
    cmake
    makeWrapper
  ]
  ++ lib.optional (buildType == "openblas") pkg-config
  ++ lib.optional (buildType == "cublas") cudaPackages.cuda_nvcc
  ;
}
