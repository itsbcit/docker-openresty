config_path=${CONFIG_PATH:-/config}
dest_path=${HTTPD_CONFIG_PATH:-/usr/local/openresty/nginx}

destfilename() {
    sourcefile=$1
    prefix=$2

    echo $(echo $(basename $sourcefile) | sed "s/^$prefix-//")
}

if [ -d $config_path ]; then
    for f in $(find -L ${config_path} -maxdepth 1 -type f -name "*.conf");do
        case $(basename $f) in
            conf.d-*.conf)
                [ -d $dest_path/conf.d ] || mkdir -pv $dest_path/conf.d
                cp -fv $f $dest_path/conf.d/$(destfilename $f "conf.d")
                ;;
            vhost.d-*.conf)
                [ -d $dest_path/vhost.d ] || mkdir -pv $dest_path/vhost.d
                cp -fv $f $dest_path/vhost.d/$(destfilename $f "vhost.d")
                ;;
            *)
                cp -fv $f ${dest_path}/conf
                ;;
        esac
    done
fi
