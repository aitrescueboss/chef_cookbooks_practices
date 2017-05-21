
default['idea']['version'] = '2017.1.3'
default['idea']['edition'] = 'C'

version = node['idea']['version']
edition = node['idea']['edition']

# IntelliJ IDEAのtar.gzアーカイブダウンロード元URL
#   = https://download-cf.jetbrains.com/idea/ideaI<edition>-<version>.tar.gz
#     ex) https://....../ideaIC-2017.1.3.tar.gz
default['idea']['url'] = "https://download-cf.jetbrains.com/idea/ideaI" + 
                         "#{edition}" +
                         "-" +
                         "#{version}" +
                         ".tar.gz"

Chef::Log::info("IntelliJ IDEA download url: #{default['idea']['url']}")

# インストール先ディレクトリの設定
# TODO ゲストOSごとに設定する (今はubuntu,debianのみ)
dest_dir_name = "intellij_idea_#{edition.downcase}e"
default['idea']['install_dir']['ubuntu'] = "/opt/#{dest_dir_name}"
default['idea']['install_dir']['debian'] = "/opt/#{dest_dir_name}"