# herokuにデプロイする用のイメージ
FROM heroku/heroku:18

# install php and some extensions
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y php php-mbstring php-mysql apache2 git mysql-client

# debug用のエディタ microコマンドで起動
# RUN cd /usr/bin && curl https://getmic.ro | bash

# ソースコードのインストール
RUN curl -o /tmp/cakephp.tar.gz https://codeload.github.com/cakephp/cakephp/tar.gz/2.10.19 
RUN curl -o /tmp/irohaboard.tar.gz https://codeload.github.com/irohasoft/irohaboard/tar.gz/v0.10.2 
RUN mkdir /var/www/cake
RUN tar xvzf /tmp/cakephp.tar.gz -C /var/www/cake --strip-components=1
RUN tar xvzf /tmp/irohaboard.tar.gz -C /var/www/html --strip-components=1
RUN rm -f /tmp/cakephp.tar.gz /tmp/irohaboard.tar.gz

# apache2とdatabaseの設定をコピーする
COPY apache2.conf /etc/apache2/apache2.conf
COPY database.php /var/www/html/Config/database.php
RUN chown -R www-data:www-data /var/www/html /var/www/cake
RUN a2enmod rewrite && a2enmod headers

# For heroku container debugging
# heroku上のコンテナにbashで入る為に必要
ADD ./.profile.d /app/.profile.d
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

# 起動しつづけるようにFOREGROUNDで実行する必要がある
# また、heroku環境だとポートが動的に割り振られるので、80番をハードコードすると「同じポートは開けないよ」というエラーがでる
CMD sed -i "s/80/$PORT/g" /etc/apache2/sites-enabled/000-default.conf /etc/apache2/ports.conf && apachectl -D FOREGROUND