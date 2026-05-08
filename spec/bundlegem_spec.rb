require 'spec_helper'


describe Bundlegem do
  before :each do
    @mocked_home = "/tmp/bundlegem_mock_home"
    @template_root = "#{@mocked_home}/.bundlegem/templates"
    @dst_dir = "/tmp/bundle_gem_dst_dir"

    reset_test_env
    FileUtils.chdir(@dst_dir)
  end

  it 'has a version number' do
    expect(Bundlegem::VERSION).not_to be nil
  end

  it 'has a cheat sheet it will share' do
    output = Bundlegem.cheat_sheet

    expect(output).to match(/foo-bar: \W* good-dog/x)
    expect(output).to match(/FOO_BAR: \W* GOOD_DOG/x)
    expect(output).to match(/FOO_IMAGE_PATH: \W* test\/good-dog/x)
  end

  # List

  it 'gives the user a helpful output when there are no templates installed' do
    list_output = Bundlegem.list

    expect(list_output).to start_with "You have no templates."
    expect(File).to exist("#{ENV['HOME']}/.bundlegem")
  end

  it 'creates a config file if needed and lists properly' do
    create_user_defined_template

    list_output = Bundlegem.list

    expect(list_output).to eq " MISC:\n   empty_template\n\n"
    expect(File).to exist("#{ENV['HOME']}/.bundlegem")
  end

  it "lists with good categories" do
    category = "ARDUINO"
    create_user_defined_template(category)

    list_output = Bundlegem.list
    expect(list_output).to include category
  end

  it "lists omit the prefix 'template-' if present in repo" do
    category = "ANYTHING"
    full_template_name = "template-happy-burger"
    create_user_defined_template(category, "template-happy-burger")

    list_output = Bundlegem.list
    # expect(list_output.include?(full_template_name)).to be false
    expect(list_output).not_to include full_template_name
    expect(list_output).to include "happy-burger"
  end

  it "lists leaf templates inside monorepo containers" do
    create_monorepo_template(["template-platform"], monorepo: true)
    create_monorepo_template(["template-platform", "template-api"], monorepo: false, category: "services")
    create_monorepo_template(["template-platform", "template-ui"], monorepo: false, category: "frontend")

    list_output = Bundlegem.list

    expect(list_output).to include "api"
    expect(list_output).to include "ui"
    expect(list_output).not_to include "platform"
    expect(list_output).to include "SERVICES"
    expect(list_output).to include "FRONTEND"
  end

  it "recursively traverses nested monorepo containers" do
    create_monorepo_template(["template-org"], monorepo: true)
    create_monorepo_template(["template-org", "template-team"], monorepo: true)
    create_monorepo_template(["template-org", "template-team", "template-console"], monorepo: false, category: "cli")

    list_output = Bundlegem.list

    expect(list_output).to include "console"
    expect(list_output).to include "CLI"
    expect(list_output).not_to include "org"
    expect(list_output).not_to include "team"
  end

  # Generate

  it "generates from a monorepo leaf template and uses leaf bootstrap config" do
    root_dir = create_monorepo_template(["template-platform"], monorepo: true)
    leaf_dir = create_monorepo_template(["template-platform", "template-api"], monorepo: false, category: "services")

    File.write("#{root_dir}/bundlegem.yml", "monorepo: true\nbootstrap_command: echo root-config\n")
    File.write("#{leaf_dir}/bundlegem.yml", "bootstrap_command: echo leaf-config\n")
    File.write("#{leaf_dir}/foo-bar.rb", "puts 'foo-bar'\n")

    options = { bin: false, ext: false, coc: false, template: "api" }
    gem_name = "tool-go-good-dog"

    output = capture_stdout { Bundlegem.generate_template(options, gem_name) }

    expect(output).to include "leaf-config"
    expect(output).not_to include "root-config"
    expect(File).to exist("#{@dst_dir}/#{gem_name}/#{gem_name}.rb")
  end

  it "finds the template-test template even if the template- prefix was omitted" do
    options = {bin: false, ext: false, coc:  false, template: "test"}
    gem_name = "tmp_gem"

    capture_stdout { Bundlegem.generate_template(options, gem_name) }
    expect(File).to exist("#{@dst_dir}/#{gem_name}/test_confirmed")
    expect(File).to exist("#{@dst_dir}/#{gem_name}/.vscode/launch.json")
  end

  it "has a useful dynamically_generate_template_directories method" do
    options = { bin: false, ext: false, coc:  false, template: "test_template" }
    gem_name = "good-dog"
    my_gem = Bundlegem::CLI::TemplateGenerator.new(options, gem_name)

    src_dst_map = my_gem.send('dynamically_generate_template_directories')

    expect(src_dst_map['foo-bar']).to eq "good-dog"
    expect(src_dst_map['foo_bar']).to eq "good_dog"
    expect(src_dst_map['simple_dir']).to eq 'simple_dir'
  end

  it "returns the expected interpolated string when substitute_template_values is called" do
    options = { bin: false, ext: false, coc:  false, template: "test_template" }
    gem_name = "good-dog"
    my_gem = Bundlegem::CLI::TemplateGenerator.new(options, gem_name)

    short_path = 'foo-bar'
    long_path = 'hello/foo-bar/blah/foo-bar'

    short_interpolated_string = my_gem.send('substitute_template_values', short_path)
    expect(short_interpolated_string).to eq gem_name

    long_interpolated_string = my_gem.send('substitute_template_values', long_path)
    expect(long_interpolated_string).to eq "hello/good-dog/blah/good-dog"
  end

  it "has a useful dynamically_generate_templates_files method" do
    options = { bin: false, ext: false, coc:  false, template: "test_template" }
    gem_name = "good-dog"
    my_gem = Bundlegem::CLI::TemplateGenerator.new(options, gem_name)

    src_dst_map = my_gem.send('dynamically_generate_templates_files')

    expect(src_dst_map['foo-bar/keep']).to eq "good-dog/keep"
    expect(src_dst_map['foo-bar.rb']).to eq 'good-dog.rb'
    expect(src_dst_map['foo_bar/keep']).to eq 'good_dog/keep'
    expect(src_dst_map['simple_dir/keep']).to eq 'simple_dir/keep'
  end

  it "won't generate template files that are listed under the gitignore" do
    template_dir = create_user_defined_template("testing", "template-user-supplied")
    options = { bin: false, ext: false, coc:  false, template: "template-user-supplied" }
    gem_name = "good-dog"

    File.write("#{template_dir}/.gitignore", "node_modules/")
    File.write("#{template_dir}/README.md", "Hello")
    FileUtils.mkdir("#{template_dir}/node_modules")
    File.write("#{template_dir}/node_modules/dont_template.rb", "I must not be interpretted")
    `git init #{template_dir}`

    capture_stdout { Bundlegem.generate_template(options, gem_name) }

    expect(File).not_to exist "#{@dst_dir}/#{gem_name}/node_modules/dont_template.rb"
    expect(File).not_to exist "#{@dst_dir}/#{gem_name}/node_modules"
  end

  it "executes the bootstrap_command if supplied" do
    template_dir = create_user_defined_template("testing", "template-user-supplied")
    options = { bin: false, ext: false, coc:  false, template: "template-user-supplied" }
    gem_name = "good-dog"

    File.write("#{template_dir}/bundlegem.yml", "bootstrap_command: echo hihihi")
    File.write("#{template_dir}/README.md", "# Readme...")
    `git init #{template_dir}`

    output = capture_stdout { Bundlegem.generate_template(options, gem_name) }

    expect(output).to include "hihihi"
  end

  it "interpolates variables into the bootstrap_command" do
    # this is quite pointless, we're literally allowing the user to execute a command on their shell...
    template_dir = create_user_defined_template("testing", "template-user-supplied")
    options = { bin: false, ext: false, coc:  false, template: "template-user-supplied" }
    gem_name = "good-dog"

    File.write("#{template_dir}/bundlegem.yml", 'bootstrap_command: "echo foo-bar"')
    File.write("#{template_dir}/README.md", "# Readme...")
    `git init #{template_dir}`

    output = capture_stdout { Bundlegem.generate_template(options, gem_name) }

    expect(output).to include "echo #{gem_name}"
  end

  it "has a test proving every interpolation in one file" do
    expected_manifest = File.read("#{ENV['SPEC_DATA_DIR']}/variable_manifest_test.rb")
    options = { bin: false, ext: false, coc:  false, template: "test_template" }
    gem_name = "good-dog"

    capture_stdout { Bundlegem.generate_template(options, gem_name) }

    resulting_manifest = File.read("#{@dst_dir}/#{gem_name}/#{gem_name}.rb")
    expect(resulting_manifest).to eq expected_manifest
  end

  it "has config[:unprefixed_name] removing purpose-tool- from name" do
    options = { bin: false, ext: false, coc:  false, template: "test_template" }
    gem_name = "tool-go-good-dog"
    my_gem = Bundlegem::CLI::TemplateGenerator.new(options, gem_name)

    config = my_gem.build_interpolation_config

    expect(config[:unprefixed_name]).to eq "good-dog"
  end

  describe "domain config prompting" do
    it "prompts for missing domain values when template requires them" do
      template_dir = create_user_defined_template("testing", "template-needs-registry")
      File.write("#{template_dir}/README.md", "Deploy to FOO_REGISTRY_DOMAIN please")
      `git init #{template_dir}`

      # Remove registry_domain from config so it triggers a prompt
      config_path = "#{@mocked_home}/.bundlegem/config"
      config_data = YAML.load_file(config_path)
      config_data.delete('registry_domain')
      File.write(config_path, "# Comments made to this file will not be preserved\n#{YAML.dump(config_data)}")

      options = { bin: false, ext: false, coc: false, template: "template-needs-registry" }
      gem_name = "prompted-app"

      # Simulate user typing "my-prompted-registry.io"
      allow($stdin).to receive(:gets).and_return("my-prompted-registry.io\n")

      output = capture_stdout { Bundlegem.generate_template(options, gem_name) }

      expect(output).to include "registry-domain"
      expect(output).to include "~/.bundlegem/config"

      # Verify value was saved to config
      saved_config = YAML.load_file(config_path)
      expect(saved_config['registry_domain']).to eq "my-prompted-registry.io"
    end

    it "does not prompt when domain values are already configured" do
      template_dir = create_user_defined_template("testing", "template-has-domains")
      File.write("#{template_dir}/README.md", "FOO_REGISTRY_DOMAIN and FOO_K8S_DOMAIN")
      `git init #{template_dir}`

      options = { bin: false, ext: false, coc: false, template: "template-has-domains" }
      gem_name = "no-prompt-app"

      # $stdin.gets should NOT be called
      expect($stdin).not_to receive(:gets)

      capture_stdout { Bundlegem.generate_template(options, gem_name) }
    end

    it "does not prompt for templates without domain placeholders" do
      template_dir = create_user_defined_template("testing", "template-simple")
      File.write("#{template_dir}/README.md", "Just a simple template with foo-bar name")
      `git init #{template_dir}`

      options = { bin: false, ext: false, coc: false, template: "template-simple" }
      gem_name = "simple-app"

      expect($stdin).not_to receive(:gets)

      capture_stdout { Bundlegem.generate_template(options, gem_name) }
    end

    it "defaults repo_domain to github.com when user enters empty string" do
      template_dir = create_user_defined_template("testing", "template-needs-repo")
      File.write("#{template_dir}/README.md", "Clone from FOO_GIT_REPO_URL")
      `git init #{template_dir}`

      config_path = "#{@mocked_home}/.bundlegem/config"
      config_data = YAML.load_file(config_path)
      config_data.delete('repo_domain')
      File.write(config_path, "# Comments made to this file will not be preserved\n#{YAML.dump(config_data)}")

      options = { bin: false, ext: false, coc: false, template: "template-needs-repo" }
      gem_name = "default-repo-app"

      allow($stdin).to receive(:gets).and_return("\n")

      capture_stdout { Bundlegem.generate_template(options, gem_name) }

      saved_config = YAML.load_file(config_path)
      expect(saved_config['repo_domain']).to eq "github.com"
    end
  end

  describe "git init behavior" do
    it "skips git init when generating inside an existing git repo" do
      # Initialize a git repo in the destination directory
      `git init #{@dst_dir}`

      template_dir = create_user_defined_template("testing", "template-git-test")
      File.write("#{template_dir}/README.md", "Hello foo-bar")
      `git init #{template_dir}`

      options = { bin: false, ext: false, coc: false, template: "template-git-test" }
      gem_name = "git-skip-app"

      capture_stdout { Bundlegem.generate_template(options, gem_name) }

      # The generated project should NOT have its own .git directory
      expect(File).not_to exist("#{@dst_dir}/#{gem_name}/.git")
      # But the files should still exist
      expect(File).to exist("#{@dst_dir}/#{gem_name}/README.md")
    end

    it "runs git init when generating outside a git repo" do
      template_dir = create_user_defined_template("testing", "template-git-test2")
      File.write("#{template_dir}/README.md", "Hello foo-bar")
      `git init #{template_dir}`

      options = { bin: false, ext: false, coc: false, template: "template-git-test2" }
      gem_name = "git-init-app"

      capture_stdout { Bundlegem.generate_template(options, gem_name) }

      # The generated project SHOULD have its own .git directory
      expect(File).to exist("#{@dst_dir}/#{gem_name}/.git")
    end

    it "always runs git init when always_perform_git_init is true" do
      # Initialize a git repo in the destination directory
      `git init #{@dst_dir}`

      # Set always_perform_git_init to true in config
      config_path = "#{@mocked_home}/.bundlegem/config"
      config_data = YAML.load_file(config_path)
      config_data['always_perform_git_init'] = true
      File.write(config_path, "# Comments made to this file will not be preserved\n#{YAML.dump(config_data)}")

      template_dir = create_user_defined_template("testing", "template-git-test3")
      File.write("#{template_dir}/README.md", "Hello foo-bar")
      `git init #{template_dir}`

      options = { bin: false, ext: false, coc: false, template: "template-git-test3" }
      gem_name = "git-force-app"

      capture_stdout { Bundlegem.generate_template(options, gem_name) }

      # The generated project SHOULD have its own .git directory even though parent is a repo
      expect(File).to exist("#{@dst_dir}/#{gem_name}/.git")
    end
  end

  describe "install public templates" do
    before :each do
      setup_mock_web_template
    end
    after :each do
      remove_mock_web_template
    end

    it "can download public templates from the web" do
      capture_stdout { Bundlegem.install_public_templates }
      expect(File).to exist("#{ENV['HOME']}/.bundlegem/templates/template-arduino/README.md")
    end
  end

  describe "create personal templates" do
    let(:github_name) { "Test" } # set by reset_test_env via `git config --global user.name "Test"`
    let(:local_dir)   { "#{ENV['HOME']}/.bundlegem/templates/templates-#{github_name}" }

    before :each do
      # Default: no remote — skip network calls.
      allow(Bundlegem).to receive(:remote_repo_exists?).and_return(false)
    end

    it "errors when repo_domain is not configured" do
      config_path = "#{ENV['HOME']}/.bundlegem/config"
      data = YAML.load_file(config_path)
      data['repo_domain'] = nil
      File.write(config_path, "# Comments made to this file will not be preserved\n#{YAML.dump(data)}")

      out = StringIO.new
      Bundlegem.setup_personal_templates(input: StringIO.new(""), output: out)

      expect(out.string).to include("`repo_domain` is not set")
      expect(File).not_to exist(local_dir)
    end

    it "creates the mono-repo with bundlegem.yml and README when no remote exists" do
      out = StringIO.new
      Bundlegem.setup_personal_templates(input: StringIO.new(""), output: out)

      expect(File).to exist("#{local_dir}/bundlegem.yml")
      expect(File.read("#{local_dir}/bundlegem.yml")).to include("monorepo: true")

      expect(File).to exist("#{local_dir}/README.md")
      expect(File.read("#{local_dir}/README.md")).to include("https://github.com/thenotary/bundlegem")

      expect(File).to exist("#{local_dir}/.git")
      expect(out.string).to include("Created personal templates mono-repo")
    end

    it "refuses to overwrite an existing local templates directory" do
      FileUtils.mkdir_p(local_dir)

      out = StringIO.new
      Bundlegem.setup_personal_templates(input: StringIO.new(""), output: out)

      expect(out.string).to include("The template directory already exists, #{local_dir}")
      expect(File).not_to exist("#{local_dir}/bundlegem.yml")
    end

    it "prompts to clone when the remote repo exists and aborts on 'n'" do
      allow(Bundlegem::CLI::SetupPersonalTemplatesRepo).to receive(:remote_repo_exists?).and_return(true)

      out = StringIO.new
      Bundlegem.setup_personal_templates(input: StringIO.new("n\n"), output: out)

      expect(out.string).to include("clone it down? [Y/n]")
      expect(out.string).to include("Aborted")
      expect(File).not_to exist(local_dir)
    end

    it "prompts for github name when git user.name is unset" do
      `git config --global --unset user.name`

      out = StringIO.new
      Bundlegem.setup_personal_templates(input: StringIO.new("octocat\n"), output: out)

      expect(out.string).to include("Enter your GitHub user name")
      expect(File).to exist("#{ENV['HOME']}/.bundlegem/templates/templates-octocat/bundlegem.yml")
    ensure
      `git config --global user.name "Test"`
    end
  end

end
