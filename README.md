# docker_nginx
## nginx-docker镜像

> 使用安装ngx_http_geoip2_module 的nginx 容器镜像，可以针对访问ip的国家和地区做针对性限制，可以屏蔽国外ip地址访问，禁止国外黑客端口扫描等。

### 使用

`docker-compose`方式：

```yaml
version: '3'

services:
  nginxwebui:
    image: xcallen/nginx:1.24.1
    container_name: nginx-fwd
    restart: unless-stopped
    privileged: true
    network_mode: host
    volumes:
      - /volume2/docker/nginx/nginx.conf:/usr/local/nginx/conf/nginx.conf
      - /volume2/docker/nginx/logs:/usr/local/nginx/logs
```

配置文件参考，针对`http`请求访问：

```nginx
http {
  include mime.types;
  default_type application/octet-stream;
  keepalive_timeout 75s;
  gzip on;
  gzip_min_length 4k;
  gzip_comp_level 4;
  client_max_body_size 1024m;
  client_header_buffer_size 32k;
  client_body_buffer_size 8m;
  server_names_hash_bucket_size 512;
  proxy_headers_hash_max_size 51200;
  proxy_headers_hash_bucket_size 6400;
  gzip_types application/javascript application/x-javascript text/javascript text/css application/json application/xml;
  error_log /usr/local/nginx/logs/error.log;
  access_log /usr/local/nginx/logs/access.log;
  geoip2 /usr/share/GeoIP/GeoLite2-Country.mmdb {
	  $geoip2_data_country_code country iso_code;
  }
  map $geoip2_data_country_code $allowed_country {
	   default yes;
	    CN no;
  }
  geo $witelist_ip {
	  default no;
	  192.0.0.0/8 yes;
  }
  server {
    server_name test.com.cn;
    listen 9090;
    location / {
	  if ($allowed_country = yes) {
		 return 403;
	  }
      proxy_pass http://192.168.0.12:8096;
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Host $http_host;
      proxy_set_header X-Forwarded-Port $server_port;
      proxy_set_header X-Forwarded-Proto $scheme;
    }
  }
}
```

配置文件参考，针对`stream`请求访问：

```nginx
stream {

  geoip2 /usr/share/GeoIP/GeoLite2-Country.mmdb {
	        $geoip2_data_country_code country iso_code;
  }
    map $geoip2_data_country_code $allowed_country {
		default 127.0.0.1:53;
		CN  192.168.0.1:22;
  }

  server {
		listen 9190;
		proxy_pass $allowed_country;
		proxy_connect_timeout 1h;
		proxy_timeout 1h;
        deny 172.104.131.136;
	  }
     log_format proxy '$remote_addr [$time_local] '
		                  '$protocol $status $bytes_sent $bytes_received '
						                   '$session_time "$upstream_addr" '
										                    '"$upstream_bytes_sent" "$upstream_bytes_received" "$upstream_connect_time"';
     access_log /usr/local/nginx/logs/stream_access.log proxy;
}
```

