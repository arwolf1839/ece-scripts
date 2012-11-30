function install_widget_framework()
{
  print_and_log "Installing Widget Framework on $HOSTNAME ..."
  # TODO java.lang.NoClassDefFoundError:
  # Lcom/escenic/framework/captcha/ReCaptchaConfig;
  
  local wf_user=$(get_conf_value wf_user)
  local wf_password=$(get_conf_value wf_password)

  print_and_log "Creating a Maven settings file: $HOME/.m2/settings.xml ..."
  make_dir $HOME/.m2
  cat > $HOME/.m2/settings.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<settings xmlns="http://maven.apache.org/settings/1.0.0"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.0.0
                              http://maven.apache.org/xsd/settings-1.0.0.xsd">
  <servers>
    <server>
      <id>escenic-repo</id>
      <username>${wf_user}</username>
      <password>${wf_password}</password>
    </server>
  </servers>

  <profiles>
    <profile>
      <id>escenic-profile</id>
      <repositories>
        <repository>
          <id>escenic-repo</id>
          <name>Repository for EWF libraries</name>
          <url>http://repo.escenic.com/</url>
          <layout>default</layout>
        </repository>
      </repositories>
    </profile>
  </profiles>

  <activeProfiles>
    <activeProfile>escenic-profile</activeProfile>
  </activeProfiles>
$(get_proxy_conf_if_set)
</settings>
EOF

  install_wf_1_if_present
  install_wf_2_if_present
  
  set_up_wf_nursery_config

  add_next_step "Widget Framework has been installed into your " \
    " Maven repo"
}

## Will add Maven HTTP(s) proxy configuration if either of the
## http_proxy or https_proxy environment variables are set.
function get_proxy_conf_if_set() {

  ## We support setting either http or https proxy, or both, hence the
  ## extra complexity.
  if [[ -n "$http_proxy" || -n "$https_proxy" ]]; then
    cat <<EOF

  <proxies>
EOF
  fi
  
  if [ -n "$http_proxy" ]; then
    local proxy_host=$(echo $http_proxy | sed 's#http://##g' | cut -d':' -f1)
    local proxy_port=$(echo $http_proxy | sed 's#http://##g' | cut -d':' -f2)
    cat <<EOF
    <proxy>
      <active>true</active>
      <protocol>http</protocol>
      <host>$proxy_host</host>
      <port>$proxy_port</port>
    </proxy>
EOF
  fi
  
  if [ -n "$https_proxy" ]; then
    local proxy_host=$(echo $https_proxy | sed 's#https://##g' | cut -d':' -f1)
    local proxy_port=$(echo $https_proxy | sed 's#https://##g' | cut -d':' -f2)
    cat <<EOF
    <proxy>
      <active>true</active>
      <protocol>https</protocol>
      <host>$proxy_host</host>
      <port>$proxy_port</port>
    </proxy>
EOF
  fi
  
  if [[ -n "$http_proxy" || -n "$https_proxy" ]]; then
    cat <<EOF
  </proxies>

EOF
  fi
}


function set_up_wf_nursery_config() {
  for el in $wf_download_list; do
    local wf_dist_dir=$(basename $el .zip)
  done

  local wf_dist_conf_dir=$wf_dist_dir/misc/siteconfig
  if [ -d $wf_dist_conf_dir  ]; then
    run cp -r $wf_dist_conf_dir/* $common_nursery_dir/
  fi
  local file=$common_nursery_dir/com/escenic/classification/IndexerPlugin.properties
  run mkdir -p $(dirname $file)
  echo "enableFacets=true" > $file
}

function install_wf_1_if_present() {
  for el in $wf_download_list; do
    local wf_dist_dir=$(basename $el .zip)
    
    if [[ $wf_dist_dir != "widget-framework-[a-z]*-1.1*" ]]; then
      return
    fi
    
    install_packages_if_missing "maven2"
    assert_commands_available mvn
    export JAVA_HOME=$java_home
    
    print_and_log "Installing Widget Framework into your Maven repository ..."
    local wf_maven_dir=$escenic_root_dir/$wf_dist_dir/maven
    run cd $wf_maven_dir
    run mvn $maven_opts install
  done
}

function install_wf_2_if_present() {
  for el in $wf_download_list; do
    local wf_dist_dir=$(basename $el .zip)
    
    if [[ $wf_dist_dir == "widget-framework-[a-z]*-1.1*" ]]; then
      return
    fi

    if [ ! -d $escenic_root_dir/assemblytool/plugins ]; then
      return
    fi
        
    run cd $escenic_root_dir/assemblytool/plugins
    
    if [ ! -h $wf_dist_dir ]; then
      ln -s $escenic_root_dir/$wf_dist_dir
    fi
  done
}

