FROM centos:centos7.9.2009
LABEL version="nginx v1.24.0"
RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

ENV NG_VERSION=nginx-1.24.0
RUN yum -y install epel-release
RUN yum -y install wget
RUN yum install -y gcc gcc-c++ glibc make autoconf openssl openssl-devel zlib zlib-devel \
 && yum install -y pcre-devel libxslt-devel gd-devel GeoIP GeoIP-devel GeoIP-data
RUN yum clean all 

RUN mkdir -p /opt/ngx

COPY nginx-1.24.0.tar.gz /opt/ngx
COPY ngx_http_geoip2_module-3.4.tar.gz /opt/ngx

WORKDIR /opt/ngx
RUN tar xzvf nginx-1.24.0.tar.gz \
  && tar xzvf ngx_http_geoip2_module-3.4.tar.gz

WORKDIR /opt/ngx/nginx-1.24.0

RUN ./configure --user=nginx \
--group=nginx --prefix=/usr/local/nginx --with-file-aio  --with-threads\
--with-http_ssl_module \
--with-http_realip_module \
--with-http_addition_module \ 
--with-http_xslt_module   \
--with-http_image_filter_module \
--with-http_geoip_module  \
--with-http_sub_module  \
--with-http_gunzip_module \ 
--with-http_gzip_static_module \ 
--with-http_auth_request_module \
--with-http_random_index_module \
--with-http_secure_link_module \
--with-http_degradation_module \
--with-http_stub_status_module \
--with-stream --with-stream_ssl_module --with-http_ssl_module --with-http_v2_module \
--add-dynamic-module==/opt/ngx/ngx_http_geoip2_module-3.4 \
&& make && make install

WORKDIR /opt/ngx
RUN rm -rf /opt/ngx/*

ENV PATH /usr/local/nginx/sbin:$PATH
ENTRYPOINT ["nginx"]
CMD ["-g","daemon off;"]