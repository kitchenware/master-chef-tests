require File.join(File.dirname(__FILE__), '..', 'helper.rb')

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

    wait "Waiting gitlab", 20, 2 do
      @http.get 80, "/"
      @http.assert_last_response_code 302
    end

    username = "toto"
    mail = "test@toto.com"
    project = "prj_#{Time.now.to_i}"

    token = @vm.capture("echo 'SELECT authentication_token FROM users WHERE email = \\\"#{mail}\\\";'| sudo /opt/gitlab/shared/mysql.sh | tail -n 1").strip

    if token == ""
      token = @vm.capture("echo 'SELECT authentication_token FROM users WHERE email = \\\"admin@local.host\\\";'| sudo /opt/gitlab/shared/mysql.sh | tail -n 1").strip

      @http.get 80, "/api/v2/user?private_token=#{token}"
      @http.assert_last_response_code 200

      @http.post_form 80, "/api/v2/users?private_token=#{token}", {
        :email => mail,
        :name => username,
        :password => "totototo",
        :password_confirmation => "totototo",
        :projects_limit => 200,
      }
      @http.assert_last_response_code 201

      token = @vm.capture("echo 'SELECT authentication_token FROM users WHERE email = \\\"#{mail}\\\";'| sudo /opt/gitlab/shared/mysql.sh | tail -n 1").strip

      @http.get 80, "/api/v2/user?private_token=#{token}"
      @http.assert_last_response_code 200

      @http.post_form 80, "/api/v2/user/keys?private_token=#{token}", {:title => "my", :key => File.read(File.join(ENV['HOME'], '.ssh', 'id_rsa.pub'))}
      @http.assert_last_response_code 201

    else

      @http.get 80, "/api/v2/user?private_token=#{token}"
      @http.assert_last_response_code 200

    end

    @http.post_form 80, "/api/v2/projects?private_token=#{token}", {:name => project}
    @http.assert_last_response_code 201

    @dir = "/tmp/#{project}"

    exec_local "cd /tmp && mkdir #{project} && cd #{project} && git init && touch README && git add README && git commit -m 'Init' && git remote add origin git@#{@vm.ip}:#{project}.git && git push -u origin master"

  end

  def teardown
    FileUtils.remove_dir @dir if @dir
  end

end