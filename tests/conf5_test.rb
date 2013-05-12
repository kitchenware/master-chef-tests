require File.join(File.dirname(__FILE__), '..', 'helper.rb')
require 'tempfile'

class TestConf5 < Test::Unit::TestCase

  include VmTestHelper
  include WaitHelper

  @dir = nil

  def test_conf5
    @vm.upload_json "conf5.json"
    @vm.run_chef

    # Check sonar
    wait "Waiting sonar init", 300, 10 do
      @http.get 80, "/sonar/sessions/new?return_to=%2Fsonar%2F"
      @http.assert_last_response_code 200
      @http.assert_last_response_body_regex /Login/
    end

    # Check nexus
    wait "Waiting nexus init", 300, 10 do
      @http.get 80, "/nexus/index.html#welcome"
      @http.assert_last_response_code 200
      @http.assert_last_response_body_regex /Sonatype Nexus/
    end

    # Check gitlab
    wait "Waiting gitlab", 300, 2 do
      @http.get 80, "/"
      @http.assert_last_response_code 302
    end

    cookie = @http.extract_set_cookie

    username = "toto"
    mail = "test@toto.com"
    project = "prj_#{Time.now.to_i}"
    password = "totototo"

    token = @vm.capture("echo 'SELECT authentication_token FROM users WHERE email = \\\"#{mail}\\\";'| sudo /opt/gitlab/shared/mysql.sh | tail -n 1").strip

    if token == ""

      token = @vm.capture("echo 'SELECT authentication_token FROM users WHERE email = \\\"admin@local.host\\\";'| sudo /opt/gitlab/shared/mysql.sh | tail -n 1").strip

      @http.get 80, "/api/v3/user?private_token=#{token}"
      @http.assert_last_response_code 200

      @http.post_form 80, "/api/v3/users?private_token=#{token}", {
        :email => mail,
        :username => username,
        :name => username,
        :password => password,
        :projects_limit => 200,
      }
      @http.assert_last_response_code 201

      token = @vm.capture("echo 'SELECT authentication_token FROM users WHERE email = \\\"#{mail}\\\";'| sudo /opt/gitlab/shared/mysql.sh | tail -n 1").strip

      @http.get 80, "/api/v3/user?private_token=#{token}"
      @http.assert_last_response_code 200

      @http.post_form 80, "/api/v3/user/keys?private_token=#{token}", {:title => "my", :key => File.read(File.join(ENV['HOME'], '.ssh', 'id_rsa.pub'))}
      @http.assert_last_response_code 201

    else

      @http.get 80, "/api/v3/user?private_token=#{token}"
      @http.assert_last_response_code 200

    end

    wait "Waiting gitlab sign_in", 300, 2 do
      @http.get 80, "/users/sign_in", nil, nil, {'cookie' => cookie}
      @http.assert_last_response_code 200
    end

    @http.response.body =~ /authenticity_token\"[^>]+value=\"([^\"]+)\"/
    authenticity_token = $1

    cookie = @http.extract_set_cookie

    @http.post_form 80, "/users/sign_in", {"user[remember_me]" => 0, "user[email]" => mail, "user[password]" => password, "authenticity_token" => authenticity_token}, nil, nil, {'cookie' => cookie}
    @http.assert_last_response_code 302
    assert_nil @http.response['location'] =~ /sign_in/

    cookie = @http.extract_set_cookie

    @http.get 80, "/", nil, nil, {'cookie' => cookie}
    @http.assert_last_response_code 200

    @http.post_form 80, "/api/v3/projects?private_token=#{token}", {:name => project}
    @http.assert_last_response_code 201

    @dir = "/tmp/#{project}"

    f = Tempfile.new "git_ssh"
    f.write "ssh #{SSH_OPTS} \"$@\""
    f.close

    exec_local "chmod +x #{f.path}"

    exec_local "cd /tmp && mkdir #{project} && cd #{project} && git init && echo burp_#{project} > README && git add README && git commit -m 'Init' && git remote add origin git@#{@vm.ip}:#{username}/#{project}.git"

    wait "Waiting push", 40, 5 do
      exec_local "cd /tmp/#{project} && GIT_SSH=#{f.path} git push -u origin master"
    end

    exec_local "cd /tmp/#{project} && date >> README && git add README && git commit -a -m 'Update Readme' && GIT_SSH=#{f.path} git push"

    wait "Waiting push processed", 40, 2 do
      @http.get 80, "/dashboard.atom?private_token=#{token}"
      @http.assert_last_response_code 200
      @http.assert_last_response_body_regex /#{username} pushed new branch master at #{project}/
    end

    last_commit = capture_local "cd /tmp/#{project} && git log -n 1 | head -n 1 | awk '{print $2}'"

    @http.get 80, "/#{username}/#{project}/commit/#{last_commit}", nil, nil, {'cookie' => cookie}
    @http.assert_last_response_code 200
    assert @http.response.body =~ /burp_#{project}/

  end

  def teardown
    FileUtils.remove_dir @dir if @dir
    VmTestHelper.instance_method(:teardown).bind(self).call
  end

end