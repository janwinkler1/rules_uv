"uv based pip compile rules"

load("@bazel_skylib//lib:types.bzl", "types")
load("@bazel_skylib//rules:write_file.bzl", "write_file")
load("//uv:pip_internal.bzl", "pip_compile_test", _pip_compile = "pip_compile")

def pip_compile(
        name,
        requirements_in = None,
        requirements_overrides = None,
        requirements_txt = None,
        target_compatible_with = None,
        python_platform = None,
        universal = False,
        args = None,
        extra_args = None,
        data = None,
        tags = None,
        size = None,
        env = None,
        **kwargs):
    """
    Produce targets to compile a requirements.in or pyproject.toml file into a requirements.txt file.

    Args:
        name: name of the primary compilation target.
        requirements_in: (optional, default "//:requirements.in") a label for the requirements.in file.
            May also be provided as a list of strings which represent the requirements file lines.
        requirements_overrides: (optional, default None) a label for the file that is used to override dependencies.
        requirements_txt: (optional, default "//:requirements.txt") a label for the requirements.txt file.
        python_platform: (optional) a uv pip compile compatible value for --python-platform.
        universal: (optional, default False) use uv's `--universal` option
        target_compatible_with: (optional) specify that a particular target is compatible only with certain
          Bazel platforms.
        args: (optional) override the default arguments passed to uv pip compile, default arguments are:
           --generate-hashes  (Include distribution hashes in the output file)
           --emit-index-url   (Include `--index-url` and `--extra-index-url` entries in the generated output file)
           --no-strip-extras  (Include extras in the output file)
        extra_args: (optional) appends to the default arguments passed to uv pip compile. If both args and
            extra_args are provided, extra_args will be appended to args.
        data: (optional) a list of labels of additional files to include
        tags: (optional) tags to apply to the generated test target
        size: (optional) size of the test target, see https://bazel.build/reference/test-encyclopedia#role-test-runner
        env: (optional) a dictionary of environment variables to set for uv pip compile and the test target
        **kwargs: (optional) other fields passed through to all underlying rules

    Targets produced by this macro are:
      [name]: a runnable target that will use requirements_in to generate and overwrite requirements_txt
      [name].update: an alias for [name]
      [name]_test: a testable target that will check that requirements_txt is up to date with requirements_in
    """
    requirements_in = requirements_in or "//:requirements.in"
    requirements_txt = requirements_txt or "//:requirements.txt"
    tags = tags or []
    size = size or "small"
    if types.is_list(requirements_in):
        write_target = "_{}.write".format(name)
        write_file(
            name = write_target,
            out = "_{}.in".format(name),
            content = requirements_in,
        )
        requirements_in = write_target

    _pip_compile(
        name = name,
        requirements_in = requirements_in,
        requirements_overrides = requirements_overrides,
        requirements_txt = requirements_txt,
        python_platform = python_platform,
        universal = universal,
        target_compatible_with = target_compatible_with,
        data = data,
        uv_args = args,
        extra_args = extra_args,
        env = env,
        **kwargs
    )

    # Also allow 'bazel run' with a "custom verb" https://bazel.build/rules/verbs-tutorial
    # Provides compatibility with rules_python's compile_pip_requirements [name].update target.
    native.alias(
        name = name + ".update",
        actual = name,
    )

    pip_compile_test(
        name = name + "_test",
        generator_label = name,
        requirements_in = requirements_in,
        requirements_overrides = requirements_overrides,
        requirements_txt = requirements_txt,
        python_platform = python_platform or "",
        universal = universal,
        target_compatible_with = target_compatible_with,
        data = data,
        uv_args = args,
        extra_args = extra_args,
        tags = ["requires-network"] + tags,
        size = size,
        env = env,
        **kwargs
    )
