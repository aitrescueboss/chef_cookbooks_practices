#
# Cookbook:: idea
# Recipe:: default
#
# Copyright:: 2017, The Authors, All Rights Reserved.
#

case node['platform']
when 'debian', 'ubuntu'
    # File download
    #   ChefDSLの "remote_file" でダウンロードを行う
    intellij_archive_file = remote_file File.join(
        Chef::Config[:file_cache_path],
        File.basename(node['idea']['url'])
    ) do
        source node['idea']['url']
        action :create_if_missing # ファイルが既にあるならダウンロードしない
    end

    install_dir = node['idea']['install_dir']['debian']

    # ChefDSLの "execute" によるコマンドの実行
    # 1つのexecuteでは1つのコマンドを実行するようにする
    # [出典] https://docs.chef.io/resource_execute.html#properties
    #       "Use the execute resource to run a single command. 
    #        Use multiple execute resource blocks to run multiple commands."
    #
    # インストール先ディレクトリを掘る
    execute "mkdir -p #{install_dir}" do
        action :run
    end

    # インストール先ディレクトリに，ダウンロードしたIntelliJの.tar.gzファイルを解凍する
    #   .tar.gzを解凍すると以下のようなディレクトリ構造が生成される:
    #      idea-IC-***.****.** /
    #        |- bin
    #        |- lib
    #        |- build.txt
    #        ...
    #   このとき，解凍された時にできたトップディレクトリ「idea-IC-***.****.**」をすっ飛ばして
    #   いきなり「bin」「lib」「build.txt」...をインストール先ディレクトリに持っていきたい.
    #   このような場合，tarコマンドの「--strip-components」オプションを使う
    execute "tar xzvf #{intellij_archive_file.path} -C #{install_dir} --strip-components=1" do
        action :run
    end

    # ダウンロードした.tar.gzファイルの削除
    execute "rm #{intellij_archive_file.path}" do
        action :run
    end

    # ユーザのホームディレクトリを絶対パスの文字列で得る.
    #   Mixlib::Shelloutを使って，ホストOSの環境に合わせたCLIでコマンドを実行した結果(標準出力)を得る.
    #   実行されるコマンド本体と，オプションとして実行するユーザを指定している.
    #   コマンドの実行結果として標準出力に出力された文字列は, .stdout で得られる.
    #   さらに，出力された文字列は末尾に改行文字を含んでいるため，string#chompにて改行コードを取り除く.
    user_name = "vagrant" # TODO ユーザ名指定ってどうやるの?
    user_home_dir = Mixlib::ShellOut.new("sudo -iu #{user_name} sh -c 'echo $HOME'").run_command.stdout.chomp
    # 以下は試行錯誤の跡. 
    # tricky way to load this Chef::Mixin::ShellOut utilities
    # [出典] http://stackoverflow.com/questions/29721575/how-to-get-a-linux-command-output-to-chef-attribute
    # FIXME (意味はよくわかっていない)
    # Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)
    # user_home_dir = Mixlib::ShellOut.new("echo ${HOME}", :user => "#{user_name}").run_command.stdout.chomp
    # user_home_dir = shell_out("echo $HOME", :user => "#{user_name}").stdout.chomp

    Chef::Log::info("user #{user_name} home directory = #{user_home_dir}")

    # ユーザのデスクトップディレクトリに, IntelliJ IDEAへのショートカットリンクを貼る.
    user_desktop_dir = "#{user_home_dir}/Desktop"
    #    ChefDSLの "file" を使ってショートカットファイルを生成する.
    file "#{user_desktop_dir}/IntelliJ_IDEA.desktop" do
        content <<-EOF
        [Desktop Entry]
        Version=1.0
        Exec=#{File.join(install_dir, "/bin/idea.sh")}
        Icon=#{File.join(install_dir, "/bin/idea.png")}
        Name=IntelliJ_IDEA
        GenericName=IntelliJ_IDEA
        Type=Application
        Categories=Application;Development;Java
        EOF
        mode '0755' # rwxr-xr-x
        owner "#{user_name}"
        group "#{user_name}"
    end
end